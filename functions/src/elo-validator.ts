import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

interface BattleResult {
  battleId: string;
  userId: string;
  opponentUserId: string;
  result: 'win' | 'loss' | 'draw';
  participant: {
    userId: string;
    lane: number;
    baseStats: {
      atk: number;
      def: number;
      spd: number;
    };
    eloRating: number;
  };
  opponent: {
    userId: string;
    lane: number;
    baseStats: {
      atk: number;
      def: number;
      spd: number;
    };
    eloRating: number;
  };
  timestamp: admin.firestore.FieldValue;
}

interface User {
  uid: string;
  name: string;
  eloRating: number;
  level: number;
  wins: number;
  losses: number;
  draws: number;
  updateAt: admin.firestore.FieldValue;
}

const DEFAULT_K_FACTOR = 32; // Standard K-factor for intermediate players
const MIN_ELO = 400;
const MAX_ELO = 3000;

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

const ELO_TIERS: EloTier[] = [
  { name: 'Bronze', minRating: MIN_ELO, maxRating: 1400, kFactor: 64 },
  { name: 'Silver', minRating: 1400, maxRating: 1800, kFactor: 32 },
  { name: 'Gold', minRating: 1800, maxRating: 2200, kFactor: 24 },
  { name: 'Platinum', minRating: 2200, maxRating: MAX_ELO, kFactor: 16 },
];

/**
 * Determine K-factor based on player's current ELO rating
 * Higher tiers have lower K-factors for rating stability
 */
function getKFactorForRating(rating: number): number {
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
function getTierName(rating: number): string {
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
function calculateExpectation(playerRating: number, opponentRating: number): number {
  const ratingDiff = opponentRating - playerRating;
  return 1 / (1 + Math.pow(10, ratingDiff / 400));
}

/**
 * Calculate new ELO rating after a match with tier-based K-factor
 * New Rating = Old Rating + K(tier) * (Result - Expected)
 * Result: 1 for win, 0.5 for draw, 0 for loss
 * K-factor varies by tier to ensure fair progression and stability
 */
function calculateNewRating(
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
 * Validate that both participants exist and haven't already received Elo for this battle
 */
async function validateBattleParticipants(
  db: admin.firestore.Firestore,
  battleResult: BattleResult
): Promise<{ valid: boolean; error?: string }> {
  try {
    const userRef = db.collection('users').doc(battleResult.userId);
    const opponentRef = db.collection('users').doc(battleResult.opponentUserId);

    const [userSnap, opponentSnap] = await Promise.all([
      userRef.get(),
      opponentRef.get(),
    ]);

    if (!userSnap.exists) {
      return { valid: false, error: `User ${battleResult.userId} not found` };
    }

    if (!opponentSnap.exists) {
      return { valid: false, error: `Opponent ${battleResult.opponentUserId} not found` };
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
 * Cloud Function: Triggered when a BattleResult is created in Firestore
 * Validates the battle and recalculates ELO server-side to prevent tampering
 */
export const validateBattleResult = functions.firestore
  .document('battle_results/{resultId}')
  .onCreate(async (snap, context) => {
    const db = admin.firestore();
    const battleResult = snap.data() as BattleResult;
    const resultId = context.params.resultId;

    console.log(`[ELO Validator] Processing battle result: ${resultId}`);
    console.log(`User: ${battleResult.userId}, Opponent: ${battleResult.opponentUserId}, Result: ${battleResult.result}`);

    try {
      // Step 1: Validate participants exist
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

      // Step 2: Fetch current user ELO ratings from Firestore
      const userRef = db.collection('users').doc(battleResult.userId);
      const opponentRef = db.collection('users').doc(battleResult.opponentUserId);

      const [userSnap, opponentSnap] = await Promise.all([
        userRef.get(),
        opponentRef.get(),
      ]);

      const user = userSnap.data() as User;
      const opponent = opponentSnap.data() as User;

      if (!user || !opponent) {
        throw new Error('User or opponent data missing');
      }

      // Step 3: Recalculate ELO server-side
      // Note: We use the current Firestore ELO, not the client-submitted values
      // This prevents clients from tampering with their previous rating
      let userNewRating = user.eloRating;
      let opponentNewRating = opponent.eloRating;

      // Determine the actual result from the user's perspective
      const userResult = battleResult.result as 'win' | 'loss' | 'draw';
      const opponentResult =
        userResult === 'win' ? 'loss' : userResult === 'loss' ? 'win' : 'draw';

      // Calculate new ratings
      userNewRating = calculateNewRating(user.eloRating, opponent.eloRating, userResult);
      opponentNewRating = calculateNewRating(
        opponent.eloRating,
        user.eloRating,
        opponentResult
      );

      const eloChange = userNewRating - user.eloRating;
      const opponentEloChange = opponentNewRating - opponent.eloRating;

      const userTier = getTierName(user.eloRating);
      const opponentTier = getTierName(opponent.eloRating);
      const userKFactor = getKFactorForRating(user.eloRating);
      const opponentKFactor = getKFactorForRating(opponent.eloRating);

      console.log(
        `[ELO Validator] ELO Update: User ${battleResult.userId} (${userTier}, K=${userKFactor}) ${user.eloRating} → ${userNewRating} (${eloChange > 0 ? '+' : ''}${eloChange.toFixed(1)})`
      );
      console.log(
        `[ELO Validator] ELO Update: Opponent ${battleResult.opponentUserId} (${opponentTier}, K=${opponentKFactor}) ${opponent.eloRating} → ${opponentNewRating} (${opponentEloChange > 0 ? '+' : ''}${opponentEloChange.toFixed(1)})`
      );

      // Step 4: Perform atomic batch write to update both users and mark battle as processed
      const batch = db.batch();

      // Update user ELO and stats
      batch.update(userRef, {
        eloRating: Math.round(userNewRating),
        [`${userResult === 'win' ? 'wins' : userResult === 'loss' ? 'losses' : 'draws'}`]:
          admin.firestore.FieldValue.increment(1),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Update opponent ELO and stats
      batch.update(opponentRef, {
        eloRating: Math.round(opponentNewRating),
        [`${opponentResult === 'win' ? 'wins' : opponentResult === 'loss' ? 'losses' : 'draws'}`]:
          admin.firestore.FieldValue.increment(1),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
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
        opponentUserId: battleResult.opponentUserId,
        userOldRating: user.eloRating,
        userNewRating: Math.round(userNewRating),
        userEloChange: eloChange,
        userTier: userTier,
        userKFactor: userKFactor,
        opponentOldRating: opponent.eloRating,
        opponentNewRating: Math.round(opponentNewRating),
        opponentEloChange: opponentEloChange,
        opponentTier: opponentTier,
        opponentKFactor: opponentKFactor,
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
