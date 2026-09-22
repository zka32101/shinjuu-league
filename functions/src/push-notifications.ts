import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

/**
 * Sends a push notification to every FCM token stored on a user's
 * /users/{userId} document (fcmTokens: string[], persisted by
 * lib/services/push_notification_service.dart on the client).
 *
 * Never throws for the "nothing to send to" case - a user with no
 * fcmTokens (push permission denied, or simply hasn't opened the app
 * since signing in) is a normal, expected state, not an error. Tokens FCM
 * reports as no-longer-registered (app uninstalled, stale install) are
 * pruned from fcmTokens so future sends stop retrying them.
 */
export async function sendPushToUser(
  db: admin.firestore.Firestore,
  userId: string,
  notification: { title: string; body: string },
  data?: Record<string, string>
): Promise<void> {
  const userRef = db.collection('users').doc(userId);
  const userSnap = await userRef.get();
  if (!userSnap.exists) {
    console.log(`[PushNotification] User ${userId} not found, skipping`);
    return;
  }

  const tokens = (userSnap.data()?.fcmTokens as string[] | undefined) ?? [];
  if (tokens.length === 0) {
    console.log(`[PushNotification] User ${userId} has no fcmTokens, skipping`);
    return;
  }

  const response = await admin.messaging().sendEachForMulticast({
    tokens,
    notification,
    data,
  });

  const staleTokens: string[] = [];
  response.responses.forEach((result, index) => {
    if (
      !result.success &&
      (result.error?.code === 'messaging/registration-token-not-registered' ||
        result.error?.code === 'messaging/invalid-registration-token')
    ) {
      staleTokens.push(tokens[index]);
    }
  });

  if (staleTokens.length > 0) {
    await userRef.update({
      fcmTokens: admin.firestore.FieldValue.arrayRemove(...staleTokens),
    });
  }

  console.log(
    `[PushNotification] Sent to ${userId}: ${response.successCount}/${tokens.length} succeeded` +
      (staleTokens.length > 0 ? `, pruned ${staleTokens.length} stale token(s)` : '')
  );
}

interface FriendRequestDoc {
  fromUserId: string;
  fromUserName: string;
  toUserId: string;
  status: string;
}

/**
 * Triggered when GuildViewModel/FriendViewModel's sendFriendRequest()
 * writes a new /friend_requests/{requestId} document (see
 * friends_screen.dart's "add friend" flow). Notifies the recipient.
 */
export const notifyFriendRequest = functions.firestore
  .document('friend_requests/{requestId}')
  .onCreate(async (snap) => {
    const db = admin.firestore();
    const request = snap.data() as FriendRequestDoc;

    try {
      await sendPushToUser(
        db,
        request.toUserId,
        {
          title: '友達申請が届きました',
          body: `${request.fromUserName}さんから友達申請が届いています`,
        },
        {
          type: 'friend_request',
          fromUserId: request.fromUserId,
        }
      );
    } catch (error) {
      console.error(`[PushNotification] Failed to notify friend request ${snap.id}: ${error}`);
    }
  });

interface GuildDoc {
  name: string;
  ownerId: string;
  memberIds: string[];
}

/**
 * Triggered on every /guilds/{guildId} update. Only reacts to a genuine
 * membership *growth* by exactly one uid - the shape the self-service
 * join rule in firestore.rules allows (see its comment there) - and
 * notifies the guild owner. A leave (memberIds shrinks) or an owner
 * settings change (memberIds unchanged) is not a "someone joined" event,
 * and is intentionally not notified here.
 */
export const notifyGuildJoin = functions.firestore
  .document('guilds/{guildId}')
  .onUpdate(async (change) => {
    const before = change.before.data() as GuildDoc;
    const after = change.after.data() as GuildDoc;

    if (after.memberIds.length <= before.memberIds.length) return;

    const joinedUserIds = after.memberIds.filter(
      (id) => !before.memberIds.includes(id)
    );
    if (joinedUserIds.length !== 1) return;
    const joinedUserId = joinedUserIds[0];

    // Never notify someone about their own action (defensive - the owner
    // is already a member from guild creation, so this shouldn't happen
    // in practice).
    if (joinedUserId === after.ownerId) return;

    const db = admin.firestore();
    try {
      const joinedUserSnap = await db.collection('users').doc(joinedUserId).get();
      const joinedUserName =
        (joinedUserSnap.data()?.name as string | undefined) ?? '新しいメンバー';

      await sendPushToUser(
        db,
        after.ownerId,
        {
          title: 'ギルドに新メンバーが加入しました',
          body: `${joinedUserName}さんが「${after.name}」に参加しました`,
        },
        {
          type: 'guild_join',
          guildId: change.after.id,
          joinedUserId,
        }
      );
    } catch (error) {
      console.error(
        `[PushNotification] Failed to notify guild join for ${change.after.id}: ${error}`
      );
    }
  });

interface AchievementUnlockDoc {
  achievementId: string;
  name?: string;
}

/**
 * Triggered when AchievementRewardService.processUnlock() -> markAchievementUnlocked()
 * creates /users/{userId}/achievements/{achievementId}. onCreate only fires
 * once per document (the client's .set(..., merge:true) call only creates
 * it the first time an achievement unlocks), so this fires exactly once
 * per unlock, never on a later merge of the same document.
 */
export const notifyAchievementUnlocked = functions.firestore
  .document('users/{userId}/achievements/{achievementId}')
  .onCreate(async (snap, context) => {
    const db = admin.firestore();
    const achievement = snap.data() as AchievementUnlockDoc;
    const userId = context.params.userId as string;
    const displayName = achievement.name ?? achievement.achievementId;

    try {
      await sendPushToUser(
        db,
        userId,
        {
          title: '実績を解除しました！',
          body: `「${displayName}」を達成しました`,
        },
        {
          type: 'achievement_unlocked',
          achievementId: achievement.achievementId,
        }
      );
    } catch (error) {
      console.error(
        `[PushNotification] Failed to notify achievement unlock for ${userId}/${snap.id}: ${error}`
      );
    }
  });
