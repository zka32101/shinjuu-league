import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { MIN_ELO, MAX_ELO } from './elo-validator';

/**
 * Server-side season lifecycle: reward distribution, rating soft-reset on
 * season end, and inactivity rating decay during an active season.
 *
 * These previously existed only as client-callable Dart methods
 * (SeasonRewardService.distributeSeasonRewards, SeasonService.endSeason)
 * that nothing in the app actually invoked automatically — any
 * authenticated client could in principle call distributeSeasonRewards()
 * for an arbitrary userId/tier, and no rating reset ever happened between
 * seasons. Moving this here makes season transitions authoritative and
 * automatic, the same way elo-validator.ts made battle ELO authoritative.
 */

export interface RewardDef {
  rewardId: string;
  tier: string;
  rewardType: 'cosmetic_skin' | 'battle_pass_item' | 'currency';
  quantity: number;
  displayName: string;
  iconUrl: string;
}

/**
 * Mirrors lib/services/season_reward_service.dart's tierRewardMap exactly,
 * since that table (not RankedSeason.rewardsByTier, which nothing actually
 * reads) is what the existing claim UI (SeasonRewardService/
 * SeasonRewardDistribution) already expects reward IDs/shapes to match.
 */
export const TIER_REWARDS: Record<string, RewardDef[]> = {
  Bronze: [
    {
      rewardId: 'bronze_currency_100',
      tier: 'Bronze',
      rewardType: 'currency',
      quantity: 100,
      displayName: 'Bronze Reward',
      iconUrl: 'assets/icons/bronze_coins.png',
    },
  ],
  Silver: [
    {
      rewardId: 'silver_currency_250',
      tier: 'Silver',
      rewardType: 'currency',
      quantity: 250,
      displayName: 'Silver Reward',
      iconUrl: 'assets/icons/silver_coins.png',
    },
    {
      rewardId: 'silver_bp_item_1',
      tier: 'Silver',
      rewardType: 'battle_pass_item',
      quantity: 1,
      displayName: 'Silver Emote',
      iconUrl: 'assets/icons/emote_silver.png',
    },
  ],
  Gold: [
    {
      rewardId: 'gold_currency_500',
      tier: 'Gold',
      rewardType: 'currency',
      quantity: 500,
      displayName: 'Gold Reward',
      iconUrl: 'assets/icons/gold_coins.png',
    },
    {
      rewardId: 'gold_skin_1',
      tier: 'Gold',
      rewardType: 'cosmetic_skin',
      quantity: 1,
      displayName: 'Gold Skin',
      iconUrl: 'assets/icons/skin_gold.png',
    },
  ],
  Platinum: [
    {
      rewardId: 'platinum_currency_1000',
      tier: 'Platinum',
      rewardType: 'currency',
      quantity: 1000,
      displayName: 'Platinum Reward',
      iconUrl: 'assets/icons/platinum_coins.png',
    },
    {
      rewardId: 'platinum_skin_1',
      tier: 'Platinum',
      rewardType: 'cosmetic_skin',
      quantity: 1,
      displayName: 'Platinum Skin',
      iconUrl: 'assets/icons/skin_platinum.png',
    },
    {
      rewardId: 'platinum_bp_item_2',
      tier: 'Platinum',
      rewardType: 'battle_pass_item',
      quantity: 2,
      displayName: 'Platinum Bundle',
      iconUrl: 'assets/icons/bp_platinum.png',
    },
  ],
  Diamond: [
    {
      rewardId: 'diamond_currency_2000',
      tier: 'Diamond',
      rewardType: 'currency',
      quantity: 2000,
      displayName: 'Diamond Reward',
      iconUrl: 'assets/icons/diamond_coins.png',
    },
    {
      rewardId: 'diamond_skin_2',
      tier: 'Diamond',
      rewardType: 'cosmetic_skin',
      quantity: 2,
      displayName: 'Diamond Skin Bundle',
      iconUrl: 'assets/icons/skin_diamond.png',
    },
    {
      rewardId: 'diamond_bp_item_3',
      tier: 'Diamond',
      rewardType: 'battle_pass_item',
      quantity: 3,
      displayName: 'Diamond Premium Bundle',
      iconUrl: 'assets/icons/bp_diamond.png',
    },
  ],
};

export function getRewardsForTier(tier: string): RewardDef[] {
  return TIER_REWARDS[tier] ?? [];
}

const SEASON_RESET_BASELINE = 1200; // matches the app's starting rating
const SEASON_RESET_FACTOR = 0.5; // "soft reset": halve the distance from baseline

/**
 * Regresses a rating halfway back toward the baseline at season end, so a
 * strong season is still rewarded with a rating edge next season without
 * letting ratings drift unboundedly across many seasons. Clamped to the
 * same [MIN_ELO, MAX_ELO] range battle ELO uses.
 */
export function applySeasonSoftReset(oldRating: number): number {
  const reset =
    SEASON_RESET_BASELINE + (oldRating - SEASON_RESET_BASELINE) * SEASON_RESET_FACTOR;
  return Math.max(MIN_ELO, Math.min(MAX_ELO, Math.round(reset)));
}

const DECAY_GRACE_DAYS = 7; // no decay for the first week of inactivity
const DECAY_PER_DAY = 10;

/**
 * Ranked ratings should reflect current skill/activity, not a rating
 * earned months ago and never defended. After a grace period, an inactive
 * player's rating decays a fixed amount per day, floored at MIN_ELO (never
 * pushed below it, and never applied at all inside the grace period).
 */
export function computeDecayedRating(
  currentRating: number,
  daysInactive: number
): number {
  if (daysInactive <= DECAY_GRACE_DAYS) return currentRating;
  const decayDays = daysInactive - DECAY_GRACE_DAYS;
  return Math.max(MIN_ELO, Math.round(currentRating - decayDays * DECAY_PER_DAY));
}

function toIsoString(value: unknown, fallback: Date): string {
  if (value instanceof admin.firestore.Timestamp) return value.toDate().toISOString();
  if (value instanceof Date) return value.toISOString();
  if (typeof value === 'string') return value;
  return fallback.toISOString();
}

/**
 * Cloud Function: fires when a season document transitions isActive
 * true -> false (the exact write SeasonService.endSeason() already makes
 * client-side). Distributes tier rewards and soft-resets ratings for every
 * participant of that season, authoritatively and exactly once.
 */
export const onSeasonEnded = functions.firestore
  .document('seasons/{seasonId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const seasonId = context.params.seasonId;

    const justEnded = before?.isActive === true && after?.isActive === false;
    if (!justEnded || after?.rewardsDistributed === true) {
      return;
    }

    const db = admin.firestore();
    console.log(`[SeasonLifecycle] Season ${seasonId} ended, distributing rewards`);

    try {
      const participantsSnap = await db
        .collectionGroup('season_data')
        .where('seasonId', '==', seasonId)
        .get();

      const now = new Date();
      const expiresAt = new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000);
      let processed = 0;

      // Chunked so a large roster never risks exceeding Firestore's
      // 500-write-per-batch limit (each participant costs up to 3 writes:
      // reward distribution doc, user rating update, audit log entry).
      const docs = participantsSnap.docs;
      const CHUNK_SIZE = 150;
      for (let i = 0; i < docs.length; i += CHUNK_SIZE) {
        const chunk = docs.slice(i, i + CHUNK_SIZE);
        const batch = db.batch();

        for (const doc of chunk) {
          const data = doc.data();
          const userId = (data.userId as string | undefined) ?? doc.ref.parent.parent?.id;
          if (!userId) continue;

          const finalTier = (data.peakTier as string | undefined) ?? 'Bronze';
          const rewards = getRewardsForTier(finalTier);

          const userRef = db.collection('users').doc(userId);
          const userSnap = await userRef.get();
          const currentRating = (userSnap.data()?.eloRating as number | undefined) ?? 1200;
          const newRating = applySeasonSoftReset(currentRating);

          batch.set(userRef.collection('season_rewards').doc(seasonId), {
            seasonId,
            userId,
            finalTier,
            rewards,
            distributedAt: now.toISOString(),
            claimedAt: null,
            expiresAt: expiresAt.toISOString(),
          });

          batch.update(userRef, {
            eloRating: newRating,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });

          batch.set(db.collection('season_lifecycle_log').doc(), {
            seasonId,
            userId,
            finalTier,
            rewardIds: rewards.map((r) => r.rewardId),
            ratingBeforeReset: currentRating,
            ratingAfterReset: newRating,
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
          });

          processed++;
        }

        await batch.commit();
      }

      await change.after.ref.update({
        rewardsDistributed: true,
        rewardsDistributedAt: admin.firestore.FieldValue.serverTimestamp(),
        rewardsDistributedCount: processed,
      });

      console.log(
        `[SeasonLifecycle] Season ${seasonId}: distributed rewards to ${processed} participants`
      );
    } catch (error) {
      console.error(`[SeasonLifecycle] Error ending season ${seasonId}: ${error}`);
      await db.collection('season_lifecycle_errors').add({
        seasonId,
        error: String(error),
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });
      throw new functions.https.HttpsError(
        'internal',
        `Season end processing failed: ${error}`
      );
    }
  });

/**
 * Scheduled Cloud Function: applies inactivity rating decay to every
 * participant of the currently active season once a day. Skipped entirely
 * when no season is active, and skipped per-user when a participant has no
 * updatedAt timestamp yet (brand-new season data, not "inactive").
 */
export const applyInactivityDecay = functions.pubsub
  .schedule('every 24 hours')
  .onRun(async () => {
    const db = admin.firestore();

    const activeSeasonSnap = await db
      .collection('seasons')
      .where('isActive', '==', true)
      .limit(1)
      .get();

    if (activeSeasonSnap.empty) {
      console.log('[SeasonLifecycle] No active season, skipping inactivity decay');
      return;
    }

    const seasonDoc = activeSeasonSnap.docs[0];
    const seasonId = seasonDoc.id;
    const now = new Date();

    const participantsSnap = await db
      .collectionGroup('season_data')
      .where('seasonId', '==', seasonId)
      .get();

    let decayedCount = 0;
    const CHUNK_SIZE = 200;
    const docs = participantsSnap.docs;

    for (let i = 0; i < docs.length; i += CHUNK_SIZE) {
      const chunk = docs.slice(i, i + CHUNK_SIZE);
      const batch = db.batch();
      let chunkHasWrites = false;

      for (const doc of chunk) {
        const data = doc.data();
        const updatedAt = data.updatedAt;
        if (!updatedAt) continue; // never battled yet this season

        const lastActive = toIsoString(updatedAt, now);
        const daysInactive =
          (now.getTime() - new Date(lastActive).getTime()) / (1000 * 60 * 60 * 24);
        if (daysInactive <= DECAY_GRACE_DAYS) continue;

        const currentRating = (data.currentRating as number | undefined) ?? 1200;
        const decayedRating = computeDecayedRating(currentRating, daysInactive);
        if (decayedRating === currentRating) continue;

        const userId = (data.userId as string | undefined) ?? doc.ref.parent.parent?.id;
        batch.update(doc.ref, { currentRating: decayedRating });
        if (userId) {
          batch.update(db.collection('users').doc(userId), { eloRating: decayedRating });
        }
        chunkHasWrites = true;
        decayedCount++;
      }

      if (chunkHasWrites) {
        await batch.commit();
      }
    }

    console.log(
      `[SeasonLifecycle] Inactivity decay applied to ${decayedCount} participants of season ${seasonId}`
    );
  });
