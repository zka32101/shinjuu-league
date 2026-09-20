/**
 * Unit tests for season lifecycle Cloud Functions: reward distribution,
 * rating soft-reset on season end, and inactivity decay.
 */
import {
  getRewardsForTier,
  applySeasonSoftReset,
  computeDecayedRating,
  TIER_REWARDS,
} from '../src/season-lifecycle';
import { MIN_ELO, MAX_ELO } from '../src/elo-validator';

describe('getRewardsForTier', () => {
  test('returns the configured rewards for each known tier', () => {
    for (const tier of ['Bronze', 'Silver', 'Gold', 'Platinum', 'Diamond']) {
      expect(getRewardsForTier(tier)).toBe(TIER_REWARDS[tier]);
      expect(getRewardsForTier(tier).length).toBeGreaterThan(0);
    }
  });

  test('returns an empty list for an unknown tier rather than throwing', () => {
    expect(getRewardsForTier('Unobtainium')).toEqual([]);
  });

  test('higher tiers grant strictly more currency than lower tiers', () => {
    const currencyOf = (tier: string) =>
      getRewardsForTier(tier)
        .filter((r) => r.rewardType === 'currency')
        .reduce((sum, r) => sum + r.quantity, 0);

    expect(currencyOf('Silver')).toBeGreaterThan(currencyOf('Bronze'));
    expect(currencyOf('Gold')).toBeGreaterThan(currencyOf('Silver'));
    expect(currencyOf('Platinum')).toBeGreaterThan(currencyOf('Gold'));
    expect(currencyOf('Diamond')).toBeGreaterThan(currencyOf('Platinum'));
  });
});

describe('applySeasonSoftReset', () => {
  test('a rating already at baseline (1200) stays at baseline', () => {
    expect(applySeasonSoftReset(1200)).toBe(1200);
  });

  test('halves the distance above baseline for a high rating', () => {
    // 2000 is 800 above baseline -> reset to 1200 + 400 = 1600
    expect(applySeasonSoftReset(2000)).toBe(1600);
  });

  test('halves the distance below baseline for a low rating', () => {
    // 800 is 400 below baseline -> reset to 1200 - 200 = 1000
    expect(applySeasonSoftReset(800)).toBe(1000);
  });

  test('never resets below MIN_ELO', () => {
    expect(applySeasonSoftReset(MIN_ELO)).toBeGreaterThanOrEqual(MIN_ELO);
  });

  test('never resets above MAX_ELO', () => {
    expect(applySeasonSoftReset(MAX_ELO)).toBeLessThanOrEqual(MAX_ELO);
  });

  test('a strong season still keeps a rating edge over an average one next season', () => {
    const strongSeasonReset = applySeasonSoftReset(2400);
    const averageSeasonReset = applySeasonSoftReset(1200);
    expect(strongSeasonReset).toBeGreaterThan(averageSeasonReset);
  });
});

describe('computeDecayedRating', () => {
  test('no decay within the grace period', () => {
    expect(computeDecayedRating(1600, 0)).toBe(1600);
    expect(computeDecayedRating(1600, 7)).toBe(1600);
  });

  test('decays by a fixed amount per day once past the grace period', () => {
    // 10 days inactive = 3 days past the 7-day grace period => -30
    expect(computeDecayedRating(1600, 10)).toBe(1570);
  });

  test('decay compounds with more days inactive', () => {
    const after10Days = computeDecayedRating(1600, 10);
    const after20Days = computeDecayedRating(1600, 20);
    expect(after20Days).toBeLessThan(after10Days);
  });

  test('never decays below MIN_ELO', () => {
    expect(computeDecayedRating(MIN_ELO + 5, 365)).toBeGreaterThanOrEqual(MIN_ELO);
  });
});

describe('onSeasonEnded (mocked Firestore)', () => {
  function makeChange(before: Record<string, unknown>, after: Record<string, unknown>) {
    const updateAfter = jest.fn().mockResolvedValue(undefined);
    return {
      change: {
        before: { data: () => before },
        after: {
          data: () => after,
          ref: { update: updateAfter },
        },
      },
      spies: { updateAfter },
    };
  }

  function makeContext(seasonId: string): any {
    return { params: { seasonId } };
  }

  function makeMockDb(fixtures: {
    seasonParticipants: Array<Record<string, unknown>>;
    users: Record<string, Record<string, unknown>>;
  }) {
    const batchSet = jest.fn();
    const batchUpdate = jest.fn();
    const batchCommit = jest.fn().mockResolvedValue(undefined);
    const errorAdd = jest.fn().mockResolvedValue({ id: 'error-doc' });

    const collectionGroup = jest.fn(() => ({
      where: jest.fn().mockReturnThis(),
      get: jest.fn().mockResolvedValue({
        docs: fixtures.seasonParticipants.map((data) => ({
          data: () => data,
          ref: {
            parent: { parent: { id: data.userId as string } },
            collection: jest.fn((name: string) => ({
              doc: jest.fn((id: string) => ({ __path: `${data.userId}/${name}/${id}` })),
            })),
          },
        })),
      }),
    }));

    const collection = jest.fn((name: string) => ({
      doc: jest.fn((id: string) => ({
        id,
        collection: jest.fn((sub: string) => ({
          doc: jest.fn((subId: string) => ({ __path: `${id}/${sub}/${subId}` })),
        })),
        get: jest.fn().mockResolvedValue({
          exists: fixtures.users[id] !== undefined,
          data: () => fixtures.users[id],
        }),
      })),
      add: name === 'season_lifecycle_errors' ? errorAdd : jest.fn(),
    }));

    const batch = jest.fn(() => ({
      set: batchSet,
      update: batchUpdate,
      commit: batchCommit,
    }));

    return {
      db: { collectionGroup, collection, batch },
      spies: { batchSet, batchUpdate, batchCommit, errorAdd },
    };
  }

  let admin: typeof import('firebase-admin');
  let onSeasonEnded: typeof import('../src/season-lifecycle').onSeasonEnded;

  beforeEach(() => {
    jest.resetModules();
    jest.doMock('firebase-admin', () => {
      const FieldValue = {
        serverTimestamp: jest.fn(() => 'MOCK_SERVER_TIMESTAMP'),
        increment: jest.fn((n: number) => ({ __increment: n })),
      };
      const firestoreFn: any = jest.fn();
      firestoreFn.FieldValue = FieldValue;
      firestoreFn.Timestamp = class {};
      return { firestore: firestoreFn };
    });
    admin = require('firebase-admin');
    onSeasonEnded = require('../src/season-lifecycle').onSeasonEnded;
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  test('does nothing when isActive did not transition true -> false', async () => {
    const { db, spies } = makeMockDb({ seasonParticipants: [], users: {} });
    (admin.firestore as unknown as jest.Mock).mockReturnValue(db);

    const { change } = makeChange({ isActive: true }, { isActive: true });
    await onSeasonEnded.run(change as any, makeContext('season-1'));

    expect(spies.batchCommit).not.toHaveBeenCalled();
  });

  test('does nothing when rewards were already distributed (idempotency)', async () => {
    const { db, spies } = makeMockDb({ seasonParticipants: [], users: {} });
    (admin.firestore as unknown as jest.Mock).mockReturnValue(db);

    const { change } = makeChange(
      { isActive: true },
      { isActive: false, rewardsDistributed: true }
    );
    await onSeasonEnded.run(change as any, makeContext('season-1'));

    expect(spies.batchCommit).not.toHaveBeenCalled();
  });

  test('distributes tier rewards and soft-resets rating for every participant', async () => {
    const { db, spies } = makeMockDb({
      seasonParticipants: [
        { userId: 'player-a', seasonId: 'season-1', peakTier: 'Gold' },
        { userId: 'player-b', seasonId: 'season-1', peakTier: 'Bronze' },
      ],
      users: {
        'player-a': { eloRating: 2000 },
        'player-b': { eloRating: 1200 },
      },
    });
    (admin.firestore as unknown as jest.Mock).mockReturnValue(db);

    const { change, spies: changeSpies } = makeChange(
      { isActive: true },
      { isActive: false }
    );
    await onSeasonEnded.run(change as any, makeContext('season-1'));

    expect(spies.batchCommit).toHaveBeenCalledTimes(1);

    // Reward distribution docs
    const rewardSetCall = spies.batchSet.mock.calls.find(
      (call) => call[1].userId === 'player-a'
    );
    expect(rewardSetCall).toBeDefined();
    expect(rewardSetCall![1].finalTier).toBe('Gold');
    expect(rewardSetCall![1].rewards.length).toBeGreaterThan(0);
    expect(rewardSetCall![1].claimedAt).toBeNull();

    // Rating soft-reset: 2000 -> 1600 (halfway back to 1200 baseline)
    const ratingUpdateCall = spies.batchUpdate.mock.calls.find(
      (call) => call[1].eloRating === 1600
    );
    expect(ratingUpdateCall).toBeDefined();

    // Season doc marked as processed, exactly once
    expect(changeSpies.updateAfter).toHaveBeenCalledTimes(1);
    expect(changeSpies.updateAfter.mock.calls[0][0].rewardsDistributed).toBe(true);
  });

  test('a participant with no recorded peakTier falls back to Bronze rather than throwing', async () => {
    const { db, spies } = makeMockDb({
      seasonParticipants: [{ userId: 'player-c', seasonId: 'season-1' }],
      users: { 'player-c': { eloRating: 1200 } },
    });
    (admin.firestore as unknown as jest.Mock).mockReturnValue(db);

    const { change } = makeChange({ isActive: true }, { isActive: false });
    await expect(
      onSeasonEnded.run(change as any, makeContext('season-1'))
    ).resolves.not.toThrow();

    const rewardSetCall = spies.batchSet.mock.calls.find(
      (call) => call[1].userId === 'player-c'
    );
    expect(rewardSetCall![1].finalTier).toBe('Bronze');
  });
});

describe('applyInactivityDecay (mocked Firestore)', () => {
  function isoDaysAgo(days: number): string {
    return new Date(Date.now() - days * 24 * 60 * 60 * 1000).toISOString();
  }

  function makeMockDb(fixtures: {
    activeSeasonId: string | null;
    seasonParticipants: Array<Record<string, unknown>>;
  }) {
    const batchUpdate = jest.fn();
    const batchCommit = jest.fn().mockResolvedValue(undefined);

    const collection = jest.fn((name: string) => {
      if (name === 'seasons') {
        return {
          where: jest.fn().mockReturnThis(),
          limit: jest.fn().mockReturnThis(),
          get: jest.fn().mockResolvedValue({
            empty: fixtures.activeSeasonId === null,
            docs:
              fixtures.activeSeasonId === null
                ? []
                : [{ id: fixtures.activeSeasonId }],
          }),
        };
      }
      // 'users'
      return {
        doc: jest.fn((id: string) => ({ id })),
      };
    });

    const collectionGroup = jest.fn(() => ({
      where: jest.fn().mockReturnThis(),
      get: jest.fn().mockResolvedValue({
        docs: fixtures.seasonParticipants.map((data) => ({
          data: () => data,
          ref: { parent: { parent: { id: data.userId as string } } },
        })),
      }),
    }));

    const batch = jest.fn(() => ({
      update: batchUpdate,
      commit: batchCommit,
    }));

    return {
      db: { collection, collectionGroup, batch },
      spies: { batchUpdate, batchCommit },
    };
  }

  let admin: typeof import('firebase-admin');
  let applyInactivityDecay: typeof import('../src/season-lifecycle').applyInactivityDecay;

  beforeEach(() => {
    jest.resetModules();
    jest.doMock('firebase-admin', () => {
      const firestoreFn: any = jest.fn();
      firestoreFn.FieldValue = {
        serverTimestamp: jest.fn(() => 'MOCK_SERVER_TIMESTAMP'),
      };
      firestoreFn.Timestamp = class {};
      return { firestore: firestoreFn };
    });
    admin = require('firebase-admin');
    applyInactivityDecay = require('../src/season-lifecycle').applyInactivityDecay;
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  test('does nothing when no season is active', async () => {
    const { db, spies } = makeMockDb({ activeSeasonId: null, seasonParticipants: [] });
    (admin.firestore as unknown as jest.Mock).mockReturnValue(db);

    await applyInactivityDecay.run({} as any, {} as any);

    expect(spies.batchCommit).not.toHaveBeenCalled();
  });

  test('decays a participant inactive well past the grace period', async () => {
    const { db, spies } = makeMockDb({
      activeSeasonId: 'season-1',
      seasonParticipants: [
        {
          userId: 'player-a',
          seasonId: 'season-1',
          currentRating: 1600,
          updatedAt: isoDaysAgo(10),
        },
      ],
    });
    (admin.firestore as unknown as jest.Mock).mockReturnValue(db);

    await applyInactivityDecay.run({} as any, {} as any);

    expect(spies.batchCommit).toHaveBeenCalledTimes(1);
    // 10 days inactive - 7 grace days = 3 decay days * 10/day = -30
    const seasonDataUpdate = spies.batchUpdate.mock.calls.find(
      (call) => call[1].currentRating === 1570
    );
    expect(seasonDataUpdate).toBeDefined();
    const userUpdate = spies.batchUpdate.mock.calls.find(
      (call) => call[1].eloRating === 1570
    );
    expect(userUpdate).toBeDefined();
  });

  test('does not touch a participant still within the grace period', async () => {
    const { db, spies } = makeMockDb({
      activeSeasonId: 'season-1',
      seasonParticipants: [
        {
          userId: 'player-b',
          seasonId: 'season-1',
          currentRating: 1600,
          updatedAt: isoDaysAgo(2),
        },
      ],
    });
    (admin.firestore as unknown as jest.Mock).mockReturnValue(db);

    await applyInactivityDecay.run({} as any, {} as any);

    expect(spies.batchCommit).not.toHaveBeenCalled();
  });

  test('skips a participant with no updatedAt yet (never battled this season)', async () => {
    const { db, spies } = makeMockDb({
      activeSeasonId: 'season-1',
      seasonParticipants: [
        { userId: 'player-c', seasonId: 'season-1', currentRating: 1200 },
      ],
    });
    (admin.firestore as unknown as jest.Mock).mockReturnValue(db);

    await applyInactivityDecay.run({} as any, {} as any);

    expect(spies.batchCommit).not.toHaveBeenCalled();
  });
});
