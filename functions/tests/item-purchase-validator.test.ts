/**
 * Unit tests for the item purchase validator Cloud Function.
 *
 * Mocked firebase-admin Firestore (no emulator required in CI) - same
 * pattern as elo-validator.test.ts - covering the security-relevant
 * behaviors: server-authoritative price lookup and gold deduction,
 * insufficient-gold rejection, invalid item rejection, and atomicity.
 */
describe('validateItemPurchase (mocked Firestore)', () => {
  type FakeDoc = Record<string, unknown> | undefined;

  function makeMockDb(fixtures: { users?: Record<string, FakeDoc> }) {
    const users = fixtures.users ?? {};

    const batchUpdate = jest.fn();
    const batchSet = jest.fn();
    const batchCommit = jest.fn().mockResolvedValue(undefined);
    const purchaseUpdate = jest.fn().mockResolvedValue(undefined);

    let itemDocCounter = 0;

    const makeUserDocRef = (userId: string) => ({
      id: userId,
      get: jest.fn().mockImplementation(async () => {
        const data = users[userId];
        return { exists: data !== undefined, data: () => data };
      }),
      collection: jest.fn((subName: string) => {
        if (subName !== 'items') {
          throw new Error(`Unexpected subcollection: ${subName}`);
        }
        return {
          doc: jest.fn((id?: string) => {
            const generatedId = id ?? `generated-item-${++itemDocCounter}`;
            return { id: generatedId, _collection: 'items', _userId: userId };
          }),
        };
      }),
    });

    const collection = jest.fn((name: string) => {
      if (name !== 'users') {
        throw new Error(`Unexpected top-level collection: ${name}`);
      }
      return { doc: jest.fn((id: string) => makeUserDocRef(id)) };
    });

    const batch = jest.fn(() => ({
      update: batchUpdate,
      set: batchSet,
      commit: batchCommit,
    }));

    return {
      db: { collection, batch },
      spies: { batchUpdate, batchSet, batchCommit, purchaseUpdate },
    };
  }

  function makeSnap(
    data: Record<string, unknown>,
    spies: { purchaseUpdate: jest.Mock }
  ): FirebaseFirestore.QueryDocumentSnapshot {
    return {
      data: () => data,
      ref: { update: spies.purchaseUpdate },
    } as unknown as FirebaseFirestore.QueryDocumentSnapshot;
  }

  function makeContext(purchaseId: string): any {
    return { params: { purchaseId } };
  }

  let admin: typeof import('firebase-admin');
  let validateItemPurchase: typeof import('../src/item-purchase-validator').validateItemPurchase;

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
    admin = require('firebase-admin');
    validateItemPurchase = require('../src/item-purchase-validator').validateItemPurchase;
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  test('rejects and marks failed when the catalog item id does not exist', async () => {
    const { db, spies } = makeMockDb({ users: { 'player-a': { gold: 99999 } } });
    (admin.firestore as unknown as jest.Mock).mockReturnValue(db);

    await validateItemPurchase.run(
      makeSnap(
        { userId: 'player-a', catalogItemId: 'nonexistent_item' },
        spies
      ),
      makeContext('purchase-1')
    );

    expect(spies.purchaseUpdate).toHaveBeenCalledWith(
      expect.objectContaining({ processed: true, success: false, reason: 'invalid_item' })
    );
    expect(spies.batchCommit).not.toHaveBeenCalled();
  });

  test('rejects and marks failed when the user does not exist', async () => {
    const { db, spies } = makeMockDb({ users: {} });
    (admin.firestore as unknown as jest.Mock).mockReturnValue(db);

    await validateItemPurchase.run(
      makeSnap(
        { userId: 'ghost-player', catalogItemId: 'weapon_iron_sword' },
        spies
      ),
      makeContext('purchase-2')
    );

    expect(spies.purchaseUpdate).toHaveBeenCalledWith(
      expect.objectContaining({ processed: true, success: false, reason: 'user_not_found' })
    );
    expect(spies.batchCommit).not.toHaveBeenCalled();
  });

  test('rejects insufficient gold without deducting anything or granting the item', async () => {
    const { db, spies } = makeMockDb({ users: { 'player-a': { gold: 50 } } });
    (admin.firestore as unknown as jest.Mock).mockReturnValue(db);

    // weapon_iron_sword costs 100 - player only has 50.
    await validateItemPurchase.run(
      makeSnap(
        { userId: 'player-a', catalogItemId: 'weapon_iron_sword' },
        spies
      ),
      makeContext('purchase-3')
    );

    expect(spies.purchaseUpdate).toHaveBeenCalledWith(
      expect.objectContaining({
        processed: true,
        success: false,
        reason: 'insufficient_gold',
      })
    );
    expect(spies.batchCommit).not.toHaveBeenCalled();
    expect(spies.batchUpdate).not.toHaveBeenCalled();
    expect(spies.batchSet).not.toHaveBeenCalled();
  });

  test('deducts the server-side catalog price and grants the item on success', async () => {
    const { db, spies } = makeMockDb({ users: { 'player-a': { gold: 500 } } });
    (admin.firestore as unknown as jest.Mock).mockReturnValue(db);

    await validateItemPurchase.run(
      makeSnap(
        { userId: 'player-a', catalogItemId: 'weapon_steel_sword' },
        spies
      ),
      makeContext('purchase-4')
    );

    expect(spies.batchCommit).toHaveBeenCalledTimes(1);

    // weapon_steel_sword costs 300 - server price, never trusting any
    // client-submitted amount (the request payload doesn't even include one).
    const goldUpdateCall = spies.batchUpdate.mock.calls.find(
      (call) => (call[1] as { gold?: { __increment: number } }).gold !== undefined
    );
    expect(goldUpdateCall).toBeDefined();
    expect(goldUpdateCall![1].gold).toEqual({ __increment: -300 });

    expect(spies.batchSet).toHaveBeenCalledTimes(1);
    const itemData = spies.batchSet.mock.calls[0][1];
    expect(itemData.name).toBe('スチールソード');
    expect(itemData.type).toBe('weapon');
    expect(itemData.rarity).toBe('rare');
    expect(itemData.bonus).toEqual({ attackBonus: 20.0 });
    expect(itemData.purchasePrice).toBe(300);
    expect(itemData.isEquipped).toBe(false);
    // acquiredAt must be a plain ISO string - the Dart Item model parses it
    // with DateTime.parse(), which cannot handle a Firestore Timestamp.
    expect(typeof itemData.acquiredAt).toBe('string');
    expect(() => new Date(itemData.acquiredAt as string)).not.toThrow();

    // The success flag is written as part of the same atomic batch as the
    // gold deduction and item grant (batch.update), not a standalone
    // purchaseRef.update() call - that direct-update path is only used on
    // the early-exit failure branches above.
    const purchaseMarkedCall = spies.batchUpdate.mock.calls.find(
      (call) => (call[1] as { processed?: boolean }).processed === true
    );
    expect(purchaseMarkedCall).toBeDefined();
    expect(purchaseMarkedCall![1].success).toBe(true);
    expect(spies.purchaseUpdate).not.toHaveBeenCalled();
  });

  test('a purchase exactly matching the user\'s gold succeeds (boundary check)', async () => {
    const { db, spies } = makeMockDb({ users: { 'player-a': { gold: 100 } } });
    (admin.firestore as unknown as jest.Mock).mockReturnValue(db);

    await validateItemPurchase.run(
      makeSnap(
        { userId: 'player-a', catalogItemId: 'weapon_iron_sword' },
        spies
      ),
      makeContext('purchase-5')
    );

    expect(spies.batchCommit).toHaveBeenCalledTimes(1);
    const purchaseMarkedCall = spies.batchUpdate.mock.calls.find(
      (call) => (call[1] as { processed?: boolean }).processed === true
    );
    expect(purchaseMarkedCall![1].success).toBe(true);
  });

});
