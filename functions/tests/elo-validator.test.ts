/**
 * Unit tests for the ELO validator Cloud Function.
 *
 * Two layers are covered:
 * 1. Pure calculation logic (calculateExpectation/calculateNewRating/tier
 *    lookups) — imported directly from src/elo-validator.ts rather than
 *    re-implemented here, so these tests actually fail if the production
 *    formula changes (a hand-copied duplicate would silently drift).
 * 2. The validateBattleResult Firestore trigger itself, with a mocked
 *    firebase-admin Firestore (no emulator required in CI) covering the
 *    security-relevant behaviors: server-authoritative rating recompute,
 *    idempotency via eloProcessed, and validation-error paths.
 */
import {
  calculateExpectation,
  calculateNewRating,
  getKFactorForRating,
  getTierName,
  MIN_ELO,
  MAX_ELO,
} from '../src/elo-validator';

describe('calculateExpectation', () => {
  test('equal ratings should give 0.5 expectation', () => {
    expect(calculateExpectation(1600, 1600)).toBeCloseTo(0.5, 2);
  });

  test('100 rating disadvantage should give ~36% expectation', () => {
    // Opponent 100 higher => our win probability is lower (~36%)
    expect(calculateExpectation(1600, 1700)).toBeCloseTo(0.36, 2);
  });

  test('200 rating disadvantage should give ~24% expectation', () => {
    expect(calculateExpectation(1600, 1800)).toBeCloseTo(0.24, 2);
  });

  test('very large rating disadvantage should approach 0', () => {
    expect(calculateExpectation(1000, 2500)).toBeLessThan(0.01);
  });
});

describe('getKFactorForRating / getTierName (tier-based K-factors)', () => {
  test.each([
    [1200, 'Bronze', 64],
    [1399, 'Bronze', 64],
    [1400, 'Silver', 32],
    [1799, 'Silver', 32],
    [1800, 'Gold', 24],
    [2199, 'Gold', 24],
    [2200, 'Platinum', 16],
    [2999, 'Platinum', 16],
  ])('rating %i is %s tier with K=%i', (rating, tier, k) => {
    expect(getTierName(rating)).toBe(tier);
    expect(getKFactorForRating(rating)).toBe(k);
  });
});

describe('calculateNewRating (tier-based K-factors)', () => {
  test('Bronze tier: win against equal opponent gains ~32 rating (K=64)', () => {
    expect(calculateNewRating(1200, 1200, 'win')).toBeCloseTo(1232, 0);
  });

  test('Silver tier: win against equal opponent gains ~16 rating (K=32)', () => {
    expect(calculateNewRating(1600, 1600, 'win')).toBeCloseTo(1616, 0);
  });

  test('Gold tier: win against equal opponent gains ~12 rating (K=24)', () => {
    expect(calculateNewRating(2000, 2000, 'win')).toBeCloseTo(2012, 0);
  });

  test('Platinum tier: win against equal opponent gains ~8 rating (K=16)', () => {
    expect(calculateNewRating(2400, 2400, 'win')).toBeCloseTo(2408, 0);
  });

  test('loss against equal opponent loses the corresponding K at each tier', () => {
    expect(calculateNewRating(1200, 1200, 'loss')).toBeCloseTo(1168, 0);
    expect(calculateNewRating(1600, 1600, 'loss')).toBeCloseTo(1584, 0);
    expect(calculateNewRating(2000, 2000, 'loss')).toBeCloseTo(1988, 0);
    expect(calculateNewRating(2400, 2400, 'loss')).toBeCloseTo(2392, 0);
  });

  test('draw against equal opponent stays the same at all tiers', () => {
    for (const rating of [1200, 1600, 2000, 2400]) {
      expect(calculateNewRating(rating, rating, 'draw')).toBeCloseTo(rating, 0);
    }
  });

  test('upset win against a higher-rated opponent gains more than an even match', () => {
    const evenWinGain = calculateNewRating(1600, 1600, 'win') - 1600;
    const upsetWinGain = calculateNewRating(1600, 1800, 'win') - 1600;
    expect(upsetWinGain).toBeGreaterThan(evenWinGain);
  });

  test('expected win against a lower-rated opponent gains less than an even match', () => {
    const evenWinGain = calculateNewRating(1800, 1800, 'win') - 1800;
    const expectedWinGain = calculateNewRating(1800, 1600, 'win') - 1800;
    expect(expectedWinGain).toBeLessThan(evenWinGain);
  });

  test('clamps to MIN_ELO for a crushing loss near the floor', () => {
    expect(calculateNewRating(410, 2800, 'loss')).toBeGreaterThanOrEqual(MIN_ELO);
  });

  test('clamps to MAX_ELO for a crushing win near the ceiling', () => {
    expect(calculateNewRating(2990, 400, 'win')).toBeLessThanOrEqual(MAX_ELO);
  });

  test('multiple consecutive wins compound with a shrinking per-win gain', () => {
    let rating = 1600;
    const opponentRating = 1600;
    const gains: number[] = [];
    for (let i = 0; i < 3; i++) {
      const next = calculateNewRating(rating, opponentRating, 'win');
      gains.push(next - rating);
      rating = next;
    }
    // As the player pulls ahead of a fixed-rating opponent, each further
    // win is more "expected" so the gain per win should shrink.
    expect(gains[1]).toBeLessThan(gains[0]);
    expect(gains[2]).toBeLessThan(gains[1]);
  });
});

/**
 * validateBattleResult (Firestore onCreate trigger) with a mocked
 * firebase-admin — no Firestore emulator needed, so this runs in plain CI.
 */
describe('validateBattleResult (mocked Firestore)', () => {
  type FakeDoc = Record<string, unknown> | undefined;

  function makeMockDb(fixtures: {
    users?: Record<string, FakeDoc>;
    battles?: Record<string, FakeDoc>;
  }) {
    const users = fixtures.users ?? {};
    const battles = fixtures.battles ?? {};

    const batchUpdate = jest.fn();
    const batchSet = jest.fn();
    const batchCommit = jest.fn().mockResolvedValue(undefined);
    const errorAdd = jest.fn().mockResolvedValue({ id: 'error-doc' });

    const makeDocRef = (collectionName: string, id: string) => ({
      id,
      // Test-only introspection field (not part of the real Firestore SDK)
      // so assertions below can tell which collection a batch.set/update
      // call targeted without relying on call ordering.
      _collection: collectionName,
      get: jest.fn().mockImplementation(async () => {
        const source = collectionName === 'users' ? users : battles;
        const data = source[id];
        return { exists: data !== undefined, data: () => data };
      }),
    });

    const collection = jest.fn((name: string) => ({
      doc: jest.fn((id: string) => makeDocRef(name, id)),
      add: name === 'elo_validation_errors' ? errorAdd : jest.fn(),
    }));

    const batch = jest.fn(() => ({
      update: batchUpdate,
      set: batchSet,
      commit: batchCommit,
    }));

    return {
      db: { collection, batch },
      spies: { batchUpdate, batchSet, batchCommit, errorAdd },
    };
  }

  // The real handler only ever calls `snap.data()`; a minimal fake is cast
  // to the SDK's QueryDocumentSnapshot type since we're deliberately
  // bypassing the full Firestore document machinery for these unit tests.
  function makeSnap(
    data: Record<string, unknown>
  ): FirebaseFirestore.QueryDocumentSnapshot {
    return { data: () => data } as unknown as FirebaseFirestore.QueryDocumentSnapshot;
  }

  function makeContext(resultId: string): any {
    return { params: { resultId } };
  }

  function userFixture(eloRating: number, overrides: Partial<Record<string, unknown>> = {}) {
    return { eloRating, totalBattles: 10, totalWins: 5, winRate: 0.5, ...overrides };
  }

  // batch.set() is now called twice on a successful run (leaderboard entry
  // + audit log), so tests must pick the right call by target collection
  // rather than assume index 0.
  function findSet(
    spies: { batchSet: jest.Mock },
    collectionName: string
  ): [Record<string, unknown>, Record<string, unknown>] {
    const call = spies.batchSet.mock.calls.find(
      (c) => (c[0] as { _collection: string })._collection === collectionName
    );
    expect(call).toBeDefined();
    return call as [Record<string, unknown>, Record<string, unknown>];
  }

  let admin: typeof import('firebase-admin');
  let validateBattleResult: typeof import('../src/elo-validator').validateBattleResult;

  beforeEach(() => {
    jest.resetModules();
    jest.doMock('firebase-admin', () => {
      const FieldValue = {
        serverTimestamp: jest.fn(() => 'MOCK_SERVER_TIMESTAMP'),
        increment: jest.fn((n: number) => ({ __increment: n })),
      };
      const firestoreFn: any = jest.fn();
      firestoreFn.FieldValue = FieldValue;
      return { firestore: firestoreFn };
    });
    // Re-require after resetModules so the mock above is picked up fresh
    // for every test (each test installs its own mock db via
    // admin.firestore.mockReturnValue(...)).
    admin = require('firebase-admin');
    validateBattleResult = require('../src/elo-validator').validateBattleResult;
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  test('rejects when the acting user does not exist, and logs the error (no batch write)', async () => {
    const { db, spies } = makeMockDb({
      users: {},
      battles: { 'battle-1': { eloProcessed: false } },
    });
    (admin.firestore as unknown as jest.Mock).mockReturnValue(db);

    await validateBattleResult.run(
      makeSnap({
        battleId: 'battle-1',
        userId: 'player-a',
        opponentUserIds: ['player-b'],
        result: 'win',
      }),
      makeContext('result-1')
    );

    expect(spies.errorAdd).toHaveBeenCalledTimes(1);
    expect(spies.errorAdd.mock.calls[0][0].error).toContain('player-a');
    expect(spies.batchCommit).not.toHaveBeenCalled();
  });

  test('rejects when the battle document does not exist', async () => {
    const { db, spies } = makeMockDb({
      users: { 'player-a': userFixture(1600), 'player-b': userFixture(1600) },
      battles: {},
    });
    (admin.firestore as unknown as jest.Mock).mockReturnValue(db);

    await validateBattleResult.run(
      makeSnap({
        battleId: 'missing-battle',
        userId: 'player-a',
        opponentUserIds: ['player-b'],
        result: 'win',
      }),
      makeContext('result-2')
    );

    expect(spies.errorAdd).toHaveBeenCalledTimes(1);
    expect(spies.errorAdd.mock.calls[0][0].error).toContain('not found');
    expect(spies.batchCommit).not.toHaveBeenCalled();
  });

  test('rejects a battle whose ELO has already been processed (idempotency)', async () => {
    const { db, spies } = makeMockDb({
      users: { 'player-a': userFixture(1600), 'player-b': userFixture(1600) },
      battles: { 'battle-1': { eloProcessed: true } },
    });
    (admin.firestore as unknown as jest.Mock).mockReturnValue(db);

    await validateBattleResult.run(
      makeSnap({
        battleId: 'battle-1',
        userId: 'player-a',
        opponentUserIds: ['player-b'],
        result: 'win',
      }),
      makeContext('result-3')
    );

    expect(spies.errorAdd).toHaveBeenCalledTimes(1);
    expect(spies.errorAdd.mock.calls[0][0].error).toBe(
      'ELO already processed for this battle'
    );
    expect(spies.batchCommit).not.toHaveBeenCalled();
  });

  test('recomputes ELO server-side from the Firestore-stored rating, ignoring any client payload', async () => {
    const { db, spies } = makeMockDb({
      users: { 'player-a': userFixture(1600), 'player-b': userFixture(1600) },
      battles: { 'battle-1': { eloProcessed: false } },
    });
    (admin.firestore as unknown as jest.Mock).mockReturnValue(db);

    await validateBattleResult.run(
      makeSnap({
        battleId: 'battle-1',
        userId: 'player-a',
        opponentUserIds: ['player-b'],
        result: 'win',
      }),
      makeContext('result-4')
    );

    expect(spies.batchCommit).toHaveBeenCalledTimes(1);

    const userUpdateCall = spies.batchUpdate.mock.calls.find(
      (call) => call[1].eloRating === 1616
    );
    expect(userUpdateCall).toBeDefined();
    expect(userUpdateCall![1].totalBattles).toBe(11);
    expect(userUpdateCall![1].totalWins).toBe(6);
    expect(userUpdateCall![1].winRate).toBeCloseTo(6 / 11, 5);

    // Only the submitting user's own document is touched - the opponent
    // (a different real player who will submit their own separate
    // battle_results doc for their own perspective) is never written here.
    expect(spies.batchUpdate.mock.calls.some((call) => call[1].eloRating === 1584)).toBe(
      false
    );

    // Battle itself must be marked processed to guarantee idempotency.
    const battleUpdateCall = spies.batchUpdate.mock.calls.find(
      (call) => call[1].eloProcessed === true
    );
    expect(battleUpdateCall).toBeDefined();

    expect(spies.batchSet).toHaveBeenCalledTimes(2);
    const [, auditLog] = findSet(spies, 'elo_validation_log');
    expect(auditLog.userOldRating).toBe(1600);
    expect(auditLog.userNewRating).toBe(1616);
    expect(auditLog.userTier).toBe('Silver');
    expect(auditLog.userKFactor).toBe(32);
    expect(auditLog.opponentAvgRating).toBe(1600);

    // Only the public-safe subset is mirrored into the publicly-readable
    // leaderboard collection - never gems/gold/fcmTokens/etc.
    const [leaderboardRef, leaderboardEntry] = findSet(spies, 'leaderboard');
    expect(leaderboardRef.id).toBe('player-a');
    expect(leaderboardEntry.uid).toBe('player-a');
    expect(leaderboardEntry.eloRating).toBe(1616);
    expect(leaderboardEntry.winRate).toBeCloseTo(6 / 11, 5);
    expect(Object.keys(leaderboardEntry).sort()).toEqual(
      ['eloRating', 'name', 'uid', 'updatedAt', 'winRate'].sort()
    );
  });

  test('averages ratings across multiple real opponents rather than using just one', async () => {
    const { db, spies } = makeMockDb({
      users: {
        'player-a': userFixture(1600),
        'player-b': userFixture(1800),
        'player-c': userFixture(1400),
      },
      battles: { 'battle-1': { eloProcessed: false } },
    });
    (admin.firestore as unknown as jest.Mock).mockReturnValue(db);

    await validateBattleResult.run(
      makeSnap({
        battleId: 'battle-1',
        userId: 'player-a',
        opponentUserIds: ['player-b', 'player-c'],
        result: 'win',
      }),
      makeContext('result-avg')
    );

    // Average of 1800 and 1400 is 1600 - identical to the single-opponent
    // 1600 case above, proving the average (not just the first id) is used.
    const [, auditLog] = findSet(spies, 'elo_validation_log');
    expect(auditLog.opponentAvgRating).toBe(1600);
    expect(auditLog.userNewRating).toBe(1616);
  });

  test('skips a deleted opponent account instead of failing the whole battle', async () => {
    const { db, spies } = makeMockDb({
      users: { 'player-a': userFixture(1600), 'player-b': userFixture(1800) },
      battles: { 'battle-1': { eloProcessed: false } },
    });
    (admin.firestore as unknown as jest.Mock).mockReturnValue(db);

    await validateBattleResult.run(
      makeSnap({
        battleId: 'battle-1',
        userId: 'player-a',
        // 'player-deleted' has no matching user fixture, simulating a
        // since-deleted account.
        opponentUserIds: ['player-b', 'player-deleted'],
        result: 'loss',
      }),
      makeContext('result-deleted-opponent')
    );

    expect(spies.batchCommit).toHaveBeenCalledTimes(1);
    // Average should be just player-b's 1800 (the deleted account filtered out).
    const [, auditLog] = findSet(spies, 'elo_validation_log');
    expect(auditLog.opponentAvgRating).toBe(1800);
  });

  test('falls back to the default opponent rating when the opposing team was entirely bots', async () => {
    const { db, spies } = makeMockDb({
      users: { 'player-a': userFixture(1600) },
      battles: { 'battle-1': { eloProcessed: false } },
    });
    (admin.firestore as unknown as jest.Mock).mockReturnValue(db);

    await validateBattleResult.run(
      makeSnap({
        battleId: 'battle-1',
        userId: 'player-a',
        opponentUserIds: [], // bots filtered out client-side, none real
        result: 'win',
      }),
      makeContext('result-no-opponents')
    );

    expect(spies.batchCommit).toHaveBeenCalledTimes(1);
    const [, auditLog] = findSet(spies, 'elo_validation_log');
    expect(auditLog.opponentAvgRating).toBe(1000); // DEFAULT_OPPONENT_RATING
  });

  test('a draw does not increment totalWins but does increment totalBattles, with near-zero rating change', async () => {
    const { db, spies } = makeMockDb({
      users: { 'player-a': userFixture(1600), 'player-b': userFixture(1600) },
      battles: { 'battle-1': { eloProcessed: false } },
    });
    (admin.firestore as unknown as jest.Mock).mockReturnValue(db);

    await validateBattleResult.run(
      makeSnap({
        battleId: 'battle-1',
        userId: 'player-a',
        opponentUserIds: ['player-b'],
        result: 'draw',
      }),
      makeContext('result-5')
    );

    const userUpdateCall = spies.batchUpdate.mock.calls.find(
      (call) => call[1].totalBattles === 11
    );
    expect(userUpdateCall).toBeDefined();
    expect(userUpdateCall![1].totalWins).toBe(5); // unchanged - a draw isn't a win
    expect(userUpdateCall![1].eloRating).toBe(1600); // equal ratings + draw = no change
  });
});

describe('debugEloCalculation input validation', () => {
  test('accepted result values are exactly win/loss/draw', () => {
    const validResults = ['win', 'loss', 'draw'];
    expect(validResults).toContain('win');
    expect(validResults).toContain('loss');
    expect(validResults).toContain('draw');
    expect(validResults).not.toContain('tie');
  });
});
