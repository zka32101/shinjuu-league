/**
 * Unit tests for the push notification Cloud Functions.
 *
 * Mocked firebase-admin Firestore + Messaging (no emulator required in
 * CI) - same pattern as item-purchase-validator.test.ts - covering the
 * shared sendPushToUser helper (missing user, no tokens, stale-token
 * pruning) and each trigger's event-shape logic (who gets notified, and
 * when a trigger must stay silent).
 */
describe('push-notifications (mocked Firestore + Messaging)', () => {
  type FakeDoc = Record<string, unknown> | undefined;

  function makeMockDb(fixtures: { users?: Record<string, FakeDoc> }) {
    const users = fixtures.users ?? {};
    const updateSpies: Record<string, jest.Mock> = {};

    const makeUserDocRef = (userId: string) => {
      const updateSpy = jest.fn().mockResolvedValue(undefined);
      updateSpies[userId] = updateSpy;
      return {
        id: userId,
        get: jest.fn().mockImplementation(async () => {
          const data = users[userId];
          return { exists: data !== undefined, data: () => data };
        }),
        update: updateSpy,
      };
    };

    const collection = jest.fn((name: string) => {
      if (name !== 'users') {
        throw new Error(`Unexpected top-level collection: ${name}`);
      }
      return { doc: jest.fn((id: string) => makeUserDocRef(id)) };
    });

    return { db: { collection }, updateSpies };
  }

  let admin: typeof import('firebase-admin');
  let sendEachForMulticast: jest.Mock;
  let push: typeof import('../src/push-notifications');

  beforeEach(() => {
    jest.resetModules();
    sendEachForMulticast = jest.fn().mockResolvedValue({
      successCount: 1,
      failureCount: 0,
      responses: [{ success: true }],
    });
    jest.doMock('firebase-admin', () => {
      const FieldValue = {
        arrayRemove: jest.fn((...tokens: string[]) => ({ __arrayRemove: tokens })),
      };
      const firestoreFn: any = jest.fn();
      firestoreFn.FieldValue = FieldValue;
      return {
        firestore: firestoreFn,
        messaging: jest.fn(() => ({ sendEachForMulticast })),
      };
    });
    admin = require('firebase-admin');
    push = require('../src/push-notifications');
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('sendPushToUser', () => {
    test('does nothing when the user document does not exist', async () => {
      const { db } = makeMockDb({ users: {} });

      await push.sendPushToUser(db as any, 'ghost', { title: 't', body: 'b' });

      expect(sendEachForMulticast).not.toHaveBeenCalled();
    });

    test('does nothing when the user has no fcmTokens', async () => {
      const { db } = makeMockDb({ users: { u1: { fcmTokens: [] } } });

      await push.sendPushToUser(db as any, 'u1', { title: 't', body: 'b' });

      expect(sendEachForMulticast).not.toHaveBeenCalled();
    });

    test('sends to every stored token with the given notification and data', async () => {
      const { db } = makeMockDb({
        users: { u1: { fcmTokens: ['tokenA', 'tokenB'] } },
      });
      sendEachForMulticast.mockResolvedValue({
        successCount: 2,
        failureCount: 0,
        responses: [{ success: true }, { success: true }],
      });

      await push.sendPushToUser(
        db as any,
        'u1',
        { title: 'hello', body: 'world' },
        { type: 'test' }
      );

      expect(sendEachForMulticast).toHaveBeenCalledWith({
        tokens: ['tokenA', 'tokenB'],
        notification: { title: 'hello', body: 'world' },
        data: { type: 'test' },
      });
    });

    test('prunes tokens FCM reports as no-longer-registered', async () => {
      const { db, updateSpies } = makeMockDb({
        users: { u1: { fcmTokens: ['stale', 'fresh'] } },
      });
      sendEachForMulticast.mockResolvedValue({
        successCount: 1,
        failureCount: 1,
        responses: [
          {
            success: false,
            error: { code: 'messaging/registration-token-not-registered' },
          },
          { success: true },
        ],
      });

      await push.sendPushToUser(db as any, 'u1', { title: 't', body: 'b' });

      expect(updateSpies['u1']).toHaveBeenCalledWith({
        fcmTokens: { __arrayRemove: ['stale'] },
      });
    });

    test('does not prune a token that failed for a transient reason', async () => {
      const { db, updateSpies } = makeMockDb({
        users: { u1: { fcmTokens: ['tokenA'] } },
      });
      sendEachForMulticast.mockResolvedValue({
        successCount: 0,
        failureCount: 1,
        responses: [{ success: false, error: { code: 'messaging/internal-error' } }],
      });

      await push.sendPushToUser(db as any, 'u1', { title: 't', body: 'b' });

      expect(updateSpies['u1']).not.toHaveBeenCalled();
    });
  });

  describe('notifyFriendRequest', () => {
    function makeSnap(data: Record<string, unknown>, id = 'req-1') {
      return { id, data: () => data } as unknown as FirebaseFirestore.QueryDocumentSnapshot;
    }

    test('notifies the recipient, naming the sender', async () => {
      const { db } = makeMockDb({ users: { recipient: { fcmTokens: ['token1'] } } });
      (admin.firestore as unknown as jest.Mock).mockReturnValue(db);

      await push.notifyFriendRequest.run(
        makeSnap({
          fromUserId: 'sender',
          fromUserName: 'アリス',
          toUserId: 'recipient',
          status: 'pending',
        }),
        {} as any
      );

      expect(sendEachForMulticast).toHaveBeenCalledWith(
        expect.objectContaining({
          tokens: ['token1'],
          notification: expect.objectContaining({
            body: expect.stringContaining('アリス'),
          }),
        })
      );
    });

    test('does not throw when the recipient has no tokens to send to', async () => {
      const { db } = makeMockDb({ users: { recipient: {} } });
      (admin.firestore as unknown as jest.Mock).mockReturnValue(db);

      await expect(
        push.notifyFriendRequest.run(
          makeSnap({
            fromUserId: 'sender',
            fromUserName: 'アリス',
            toUserId: 'recipient',
            status: 'pending',
          }),
          {} as any
        )
      ).resolves.not.toThrow();
      expect(sendEachForMulticast).not.toHaveBeenCalled();
    });
  });

  describe('notifyGuildJoin', () => {
    function makeChange(
      before: Record<string, unknown>,
      after: Record<string, unknown>,
      id = 'guild-1'
    ) {
      return {
        before: { data: () => before },
        after: { data: () => after, id },
      } as any;
    }

    test('notifies the owner when memberIds grows by exactly one (self-join)', async () => {
      const { db } = makeMockDb({
        users: {
          owner: { fcmTokens: ['ownerToken'] },
          newbie: { name: 'ニュービー' },
        },
      });
      (admin.firestore as unknown as jest.Mock).mockReturnValue(db);

      await push.notifyGuildJoin.run(
        makeChange(
          { name: 'テストギルド', ownerId: 'owner', memberIds: ['owner'] },
          { name: 'テストギルド', ownerId: 'owner', memberIds: ['owner', 'newbie'] }
        ),
        {} as any
      );

      expect(sendEachForMulticast).toHaveBeenCalledWith(
        expect.objectContaining({
          tokens: ['ownerToken'],
          notification: expect.objectContaining({
            body: expect.stringContaining('ニュービー'),
          }),
        })
      );
    });

    test('does not notify on a leave (memberIds shrinks)', async () => {
      const { db } = makeMockDb({ users: { owner: { fcmTokens: ['t'] } } });
      (admin.firestore as unknown as jest.Mock).mockReturnValue(db);

      await push.notifyGuildJoin.run(
        makeChange(
          { name: 'g', ownerId: 'owner', memberIds: ['owner', 'leaver'] },
          { name: 'g', ownerId: 'owner', memberIds: ['owner'] }
        ),
        {} as any
      );

      expect(sendEachForMulticast).not.toHaveBeenCalled();
    });

    test('does not notify when memberIds is unchanged (an owner settings update)', async () => {
      const { db } = makeMockDb({ users: { owner: { fcmTokens: ['t'] } } });
      (admin.firestore as unknown as jest.Mock).mockReturnValue(db);

      await push.notifyGuildJoin.run(
        makeChange(
          { name: 'old name', ownerId: 'owner', memberIds: ['owner'] },
          { name: 'new name', ownerId: 'owner', memberIds: ['owner'] }
        ),
        {} as any
      );

      expect(sendEachForMulticast).not.toHaveBeenCalled();
    });

    test('does not notify when more than one member appears at once (defensive)', async () => {
      const { db } = makeMockDb({ users: { owner: { fcmTokens: ['t'] } } });
      (admin.firestore as unknown as jest.Mock).mockReturnValue(db);

      await push.notifyGuildJoin.run(
        makeChange(
          { name: 'g', ownerId: 'owner', memberIds: ['owner'] },
          { name: 'g', ownerId: 'owner', memberIds: ['owner', 'a', 'b'] }
        ),
        {} as any
      );

      expect(sendEachForMulticast).not.toHaveBeenCalled();
    });
  });

  describe('notifyAchievementUnlocked', () => {
    function makeSnap(data: Record<string, unknown>, id = 'first_blood') {
      return { id, data: () => data } as unknown as FirebaseFirestore.QueryDocumentSnapshot;
    }
    function makeContext(userId: string, achievementId: string): any {
      return { params: { userId, achievementId } };
    }

    test('notifies the user, naming the achievement', async () => {
      const { db } = makeMockDb({ users: { u1: { fcmTokens: ['token1'] } } });
      (admin.firestore as unknown as jest.Mock).mockReturnValue(db);

      await push.notifyAchievementUnlocked.run(
        makeSnap({ achievementId: 'first_blood', name: 'ファーストブラッド' }),
        makeContext('u1', 'first_blood')
      );

      expect(sendEachForMulticast).toHaveBeenCalledWith(
        expect.objectContaining({
          tokens: ['token1'],
          notification: expect.objectContaining({
            body: expect.stringContaining('ファーストブラッド'),
          }),
        })
      );
    });

    test('falls back to the raw achievementId when name is missing (older doc shape)', async () => {
      const { db } = makeMockDb({ users: { u1: { fcmTokens: ['token1'] } } });
      (admin.firestore as unknown as jest.Mock).mockReturnValue(db);

      await push.notifyAchievementUnlocked.run(
        makeSnap({ achievementId: 'first_blood' }),
        makeContext('u1', 'first_blood')
      );

      expect(sendEachForMulticast).toHaveBeenCalledWith(
        expect.objectContaining({
          notification: expect.objectContaining({
            body: expect.stringContaining('first_blood'),
          }),
        })
      );
    });
  });
});
