import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

/**
 * One document per submitting player, not per battle: this is a 5v5 team
 * game (see lib/data/models/battle_model.dart's Battle.opponentIds), not
 * 1v1, so there is no single "opponent" to validate/update symmetrically.
 * Each human player's own client submits their own result after their own
 * battle ends; opponentUserIds lists only the real (non-bot) players on
 * the other team - bot IDs (prefixed 'bot_') are filtered out client-side
 * since bots have no Firestore user document. The Cloud Function updates
 * only battleResult.userId's own rating, using the average of
 * opponentUserIds' current ratings as the effective opponent rating -
 * mirroring lib/services/elo_service.dart's EloService.averageRating(),
 * this app's existing "team average" convention for both matchmaking and
 * Elo preview calculations.
 */
interface BattleResult {
  battleId: string;
  userId: string;
  opponentUserIds: string[];
  result: 'win' | 'loss' | 'draw';
  timestamp: admin.firestore.FieldValue;
}

/** Mirrors lib/data/models/user_model.dart's User - not a separate schema. */
interface User {
  uid: string;
  name: string;
  eloRating: number;
  totalWins: number;
  totalBattles: number;
  winRate: number;
}

/** lib/config/app_config.dart's AppConfig.baseElo - used when a battle had
 * no real (non-bot) opponents to average, so a rating can still be computed. */
const DEFAULT_OPPONENT_RATING = 1000;

export const DEFAULT_K_FACTOR = 32; // Standard K-factor for intermediate players
export const MIN_ELO = 400;
export const MAX_ELO = 3000;

/**
 * ELO tier thresholds for K-factor adjustment
 * - Bronze (400-1400): K=64 (new players, fast skill assessment)
 * - Silver (1400-1800): K=32 (standard, balanced)
 * - Gold (1800-2200): K=24 (advanced, slower changes)
 * - Platinum (2200+): K=16 (elite, very stable)
 */
interface EloTier {
  name: string;
  minRating: number;
  maxRating: number;
  kFactor: number;
}

export const ELO_TIERS: EloTier[] = [
  { name: 'Bronze', minRating: MIN_ELO, maxRating: 1400, kFactor: 64 },
  { name: 'Silver', minRating: 1400, maxRating: 1800, kFactor: 32 },
  { name: 'Gold', minRating: 1800, maxRating: 2200, kFactor: 24 },
  { name: 'Platinum', minRating: 2200, maxRating: MAX_ELO, kFactor: 16 },
];

/**
 * Determine K-factor based on player's current ELO rating
 * Higher tiers have lower K-factors for rating stability
 */
export function getKFactorForRating(rating: number): number {
  for (const tier of ELO_TIERS) {
    if (rating >= tier.minRating && rating < tier.maxRating) {
      return tier.kFactor;
    }
  }
  return DEFAULT_K_FACTOR; // Fallback
}

/**
 * Get ELO tier name from rating
 */
export function getTierName(rating: number): string {
  for (const tier of ELO_TIERS) {
    if (rating >= tier.minRating && rating < tier.maxRating) {
      return tier.name;
    }
  }
  return 'Unknown';
}

/**
 * Calculate expected win probability for player A against player B
 * Using standard ELO formula: EA = 1 / (1 + 10^((RB - RA) / 400))
 */
export function calculateExpectation(playerRating: number, opponentRating: number): number {
  const ratingDiff = opponentRating - playerRating;
  return 1 / (1 + Math.pow(10, ratingDiff / 400));
}

/**
 * Calculate new ELO rating after a match with tier-based K-factor
 * New Rating = Old Rating + K(tier) * (Result - Expected)
 * Result: 1 for win, 0.5 for draw, 0 for loss
 * K-factor varies by tier to ensure fair progression and stability
 */
export function calculateNewRating(
  currentRating: number,
  opponentRating: number,
  result: 'win' | 'loss' | 'draw'
): number {
  const expected = calculateExpectation(currentRating, opponentRating);
  const actualResult = result === 'win' ? 1 : result === 'draw' ? 0.5 : 0;
  const kFactor = getKFactorForRating(currentRating);
  const delta = kFactor * (actualResult - expected);
  const newRating = currentRating + delta;

  // Clamp to valid range
  return Math.max(MIN_ELO, Math.min(MAX_ELO, newRating));
}

/**
 * Validate the submitting user and battle exist and haven't already
 * received Elo for this battle. opponentUserIds are validated separately
 * (and tolerantly - a since-deleted opponent account is skipped, not a
 * hard failure) when computing the opponent average rating.
 */
async function validateBattleParticipants(
  db: admin.firestore.Firestore,
  battleResult: BattleResult
): Promise<{ valid: boolean; error?: string }> {
  try {
    const userRef = db.collection('users').doc(battleResult.userId);
    const userSnap = await userRef.get();

    if (!userSnap.exists) {
      return { valid: false, error: `User ${battleResult.userId} not found` };
    }

    // Check if ELO for this battle has already been processed
    // (prevent double-application if Cloud Function fires twice)
    const battleRef = db.collection('battles').doc(battleResult.battleId);
    const battleSnap = await battleRef.get();

    if (!battleSnap.exists) {
      return { valid: false, error: `Battle ${battleResult.battleId} not found` };
    }

    const battle = battleSnap.data();
    if (battle?.eloProcessed === true) {
      return { valid: false, error: 'ELO already processed for this battle' };
    }

    return { valid: true };
  } catch (error) {
    return { valid: false, error: `Validation error: ${error}` };
  }
}

/**
 * Average current Elo rating across the real (non-bot) opponents on the
 * other team, fetched fresh from Firestore rather than trusted from the
 * client. Silently skips an opponent id that no longer resolves to a
 * user document (deleted account) instead of failing the whole battle.
 * Falls back to DEFAULT_OPPONENT_RATING when no opponent ratings could be
 * resolved at all (e.g. an all-bot opposing team).
 */
async function computeOpponentAverageRating(
  db: admin.firestore.Firestore,
  opponentUserIds: string[]
): Promise<number> {
  if (opponentUserIds.length === 0) return DEFAULT_OPPONENT_RATING;

  const snaps = await Promise.all(
    opponentUserIds.map((id) => db.collection('users').doc(id).get())
  );
  const ratings = snaps
    .filter((snap) => snap.exists)
    .map((snap) => (snap.data() as User).eloRating)
    .filter((rating) => typeof rating === 'number');

  if (ratings.length === 0) return DEFAULT_OPPONENT_RATING;
  return ratings.reduce((a, b) => a + b, 0) / ratings.length;
}

/**
 * Cloud Function: Triggered when a BattleResult is created in Firestore
 * Validates the battle and recalculates ELO server-side to prevent tampering
 */
export const validateBattleResult = functions.firestore
  .document('battle_results/{resultId}')
  .onCreate(async (snap, context) => {
    const db = admin.firestore();
    const battleResult = snap.data() as BattleResult;
    const resultId = context.params.resultId;

    console.log(
      `[ELO Validator] Processing battle result: ${resultId} for user ${battleResult.userId}, ${battleResult.opponentUserIds?.length ?? 0} opponent(s), result: ${battleResult.result}`
    );

    try {
      // Step 1: Validate the submitting user and battle exist, and this
      // battle hasn't already had Elo applied.
      const validation = await validateBattleParticipants(db, battleResult);
      if (!validation.valid) {
        console.error(`[ELO Validator] Validation failed: ${validation.error}`);
        // Log to audit collection for monitoring
        await db.collection('elo_validation_errors').add({
          resultId,
          battleId: battleResult.battleId,
          error: validation.error,
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
          battleResult: battleResult,
        });
        return;
      }

      // Step 2: Fetch the submitting user's current (authoritative) rating
      // and stats from Firestore, and the real opponents' current ratings
      // to average - never the client-submitted values, which prevents a
      // client from tampering with either its own prior rating or its
      // opponents' ratings.
      const userRef = db.collection('users').doc(battleResult.userId);
      const [userSnap, opponentAvgRating] = await Promise.all([
        userRef.get(),
        computeOpponentAverageRating(db, battleResult.opponentUserIds ?? []),
      ]);

      const user = userSnap.data() as User;
      if (!user) {
        throw new Error('User data missing');
      }

      // Step 3: Recalculate this user's new Elo server-side against the
      // real opponent-team average rating.
      const userResult = battleResult.result;
      const userNewRating = calculateNewRating(user.eloRating, opponentAvgRating, userResult);
      const eloChange = userNewRating - user.eloRating;

      const userTier = getTierName(user.eloRating);
      const userKFactor = getKFactorForRating(user.eloRating);

      const priorTotalBattles = user.totalBattles ?? 0;
      const priorTotalWins = user.totalWins ?? 0;
      const isWin = userResult === 'win';
      const newTotalBattles = priorTotalBattles + 1;
      const newTotalWins = priorTotalWins + (isWin ? 1 : 0);
      const newWinRate = newTotalWins / newTotalBattles;

      console.log(
        `[ELO Validator] ELO Update: User ${battleResult.userId} (${userTier}, K=${userKFactor}) ${user.eloRating} → ${userNewRating} (${eloChange > 0 ? '+' : ''}${eloChange.toFixed(1)}) vs opponent avg ${opponentAvgRating.toFixed(0)}`
      );

      // Step 4: Perform atomic batch write to update the user and mark the
      // battle as processed.
      const batch = db.batch();

      batch.update(userRef, {
        eloRating: Math.round(userNewRating),
        totalBattles: newTotalBattles,
        totalWins: newTotalWins,
        winRate: newWinRate,
        lastBattleAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Mark battle as ELO-processed to prevent double-application
      batch.update(db.collection('battles').doc(battleResult.battleId), {
        eloProcessed: true,
        eloProcessedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Log successful validation with tier information
      batch.set(db.collection('elo_validation_log').doc(), {
        resultId,
        battleId: battleResult.battleId,
        userId: battleResult.userId,
        opponentUserIds: battleResult.opponentUserIds ?? [],
        opponentAvgRating,
        userOldRating: user.eloRating,
        userNewRating: Math.round(userNewRating),
        userEloChange: eloChange,
        userTier: userTier,
        userKFactor: userKFactor,
        clientSubmittedResult: battleResult.result,
        serverValidatedResult: userResult,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Step 5: Commit all changes atomically
      await batch.commit();

      console.log(`[ELO Validator] Successfully processed battle result: ${resultId}`);
    } catch (error) {
      console.error(`[ELO Validator] Error processing battle result: ${error}`);

      // Log error for monitoring
      try {
        await db.collection('elo_validation_errors').add({
          resultId,
          battleId: battleResult.battleId,
          error: String(error),
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
          battleResult: battleResult,
        });
      } catch (logError) {
        console.error(`[ELO Validator] Failed to log error: ${logError}`);
      }

      // Rethrow to Firebase Functions for retry policy
      throw new functions.https.HttpsError('internal', `ELO validation failed: ${error}`);
    }
  });

/**
 * HTTP endpoint to debug/inspect ELO calculation
 * Usage: POST https://region-projectId.cloudfunctions.net/debugEloCalculation
 * Body: { playerRating: number, opponentRating: number, result: 'win'|'loss'|'draw' }
 */
export const debugEloCalculation = functions.https.onCall(async (data) => {
  const { playerRating, opponentRating, result } = data;

  if (
    typeof playerRating !== 'number' ||
    typeof opponentRating !== 'number' ||
    !['win', 'loss', 'draw'].includes(result)
  ) {
    throw new functions.https.HttpsError('invalid-argument', 'Invalid input parameters');
  }

  const expectation = calculateExpectation(playerRating, opponentRating);
  const newRating = calculateNewRating(playerRating, opponentRating, result);
  const eloChange = newRating - playerRating;

  return {
    playerRating,
    opponentRating,
    result,
    expectation: expectation.toFixed(3),
    newRating: Math.round(newRating),
    eloChange: eloChange.toFixed(1),
  };
});
