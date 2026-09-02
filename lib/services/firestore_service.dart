import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shinjuu_league/data/models/user_model.dart';
import 'package:shinjuu_league/data/models/battle_model.dart';
import 'package:shinjuu_league/data/models/battlepass_model.dart';
import 'package:shinjuu_league/data/models/friend_model.dart';
import 'package:shinjuu_league/data/models/guild_model.dart';
import 'package:shinjuu_league/data/models/mecha_model.dart';
import 'package:shinjuu_league/data/models/replay_model.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();

  factory FirestoreService() {
    return _instance;
  }

  FirestoreService._internal();

  final _db = FirebaseFirestore.instance;

  // ============ User Methods ============
  Future<User?> getUserById(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        return User.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw 'Failed to fetch user: $e';
    }
  }

  Future<void> createUser(User user) async {
    try {
      await _db.collection('users').doc(user.uid).set(user.toJson());
    } catch (e) {
      throw 'Failed to create user: $e';
    }
  }

  Future<void> updateUser(User user) async {
    try {
      await _db.collection('users').doc(user.uid).update(user.toJson());
    } catch (e) {
      throw 'Failed to update user: $e';
    }
  }

  Stream<User?> watchUser(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((snapshot) {
          if (snapshot.exists) {
            return User.fromJson(snapshot.data() as Map<String, dynamic>);
          }
          return null;
        })
        .handleError((e) {
          throw 'Failed to watch user: $e';
        });
  }

  Future<List<User>> searchUsersByName(String query) async {
    if (query.isEmpty) return [];
    try {
      final snapshot = await _db
          .collection('users')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThan: '$query')
          .limit(20)
          .get();
      return snapshot.docs.map((doc) => User.fromJson(doc.data())).toList();
    } catch (e) {
      throw 'Failed to search users: $e';
    }
  }

  Future<void> updateUserGuildId(String userId, String? guildId) async {
    try {
      await _db.collection('users').doc(userId).update({'guildId': guildId});
    } catch (e) {
      throw 'Failed to update guild membership: $e';
    }
  }

  /// FCM トークンを Firestore に永続化
  /// トークンをユーザードキュメントの fcmTokens 配列に追加（重複排除）
  Future<void> persistFcmToken(String userId, String token) async {
    try {
      await _db.collection('users').doc(userId).update({
        'fcmTokens': FieldValue.arrayUnion([token]),
      });
    } catch (e) {
      throw 'Failed to persist FCM token: $e';
    }
  }

  /// ユーザーのコホートプロパティを Firestore に更新
  /// アナリティクスの分析と、サーバー側のユーザー検索/ターゲティングに使用
  Future<void> updateUserCohortProperties(
    String userId,
    dynamic cohortProperties,
  ) async {
    try {
      // cohortProperties can be either CohortProperties object or Map
      final cohortData = cohortProperties is Map
          ? cohortProperties
          : (cohortProperties as dynamic).toJson() as Map<String, dynamic>;

      await _db.collection('users').doc(userId).update({
        'cohortProperties': cohortData,
      });
    } catch (e) {
      throw 'Failed to update cohort properties: $e';
    }
  }

  // ============ Mecha Methods ============
  Future<List<Mecha>> getAllMechas() async {
    try {
      final snapshot = await _db.collection('mechas').get();
      return snapshot.docs.map((doc) => Mecha.fromJson(doc.data())).toList();
    } catch (e) {
      throw 'Failed to fetch mechas: $e';
    }
  }

  Future<Mecha?> getMechaById(String mechaId) async {
    try {
      final doc = await _db.collection('mechas').doc(mechaId).get();
      if (doc.exists) {
        return Mecha.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw 'Failed to fetch mecha: $e';
    }
  }

  // ============ Battle Methods ============
  Future<void> createBattle(Battle battle) async {
    try {
      await _db.collection('battles').doc(battle.battleId).set(battle.toJson());
    } catch (e) {
      throw 'Failed to create battle: $e';
    }
  }

  Future<void> updateBattle(Battle battle) async {
    try {
      await _db
          .collection('battles')
          .doc(battle.battleId)
          .update(battle.toJson());
    } catch (e) {
      throw 'Failed to update battle: $e';
    }
  }

  Future<Battle?> getBattleById(String battleId) async {
    try {
      final doc = await _db.collection('battles').doc(battleId).get();
      if (doc.exists) {
        return Battle.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw 'Failed to fetch battle: $e';
    }
  }

  Stream<List<Battle>> watchUserBattles(String userId) {
    return _db
        .collection('battles')
        .where('userId', isEqualTo: userId)
        .orderBy('startedAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Battle.fromJson(doc.data()))
              .toList();
        })
        .handleError((e) {
          throw 'Failed to watch user battles: $e';
        });
  }

  // ============ Leaderboard Methods ============
  Future<List<User>> getTopRankedUsers({int limit = 100}) async {
    try {
      final snapshot = await _db
          .collection('users')
          .orderBy('eloRating', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => User.fromJson(doc.data())).toList();
    } catch (e) {
      throw 'Failed to fetch leaderboard: $e';
    }
  }

  // ============ BattlePass Methods ============
  String _battlePassDocId(String userId, String seasonId) =>
      '${userId}_$seasonId';

  Future<BattlePass?> getBattlePass(String userId, String seasonId) async {
    try {
      final doc = await _db
          .collection('battlepasses')
          .doc(_battlePassDocId(userId, seasonId))
          .get();
      if (doc.exists) {
        return BattlePass.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw 'Failed to fetch battle pass: $e';
    }
  }

  Future<void> saveBattlePass(BattlePass battlePass) async {
    try {
      await _db
          .collection('battlepasses')
          .doc(_battlePassDocId(battlePass.userId, battlePass.seasonId))
          .set(battlePass.toJson());
    } catch (e) {
      throw 'Failed to save battle pass: $e';
    }
  }

  // ============ Friend Methods ============
  Future<void> sendFriendRequest({
    required String fromUserId,
    required String fromUserName,
    required String toUserId,
  }) async {
    try {
      final requestId = '${fromUserId}_$toUserId';
      final request = FriendRequest(
        requestId: requestId,
        fromUserId: fromUserId,
        fromUserName: fromUserName,
        toUserId: toUserId,
        status: FriendRequestStatus.pending,
        createdAt: DateTime.now(),
      );
      await _db
          .collection('friend_requests')
          .doc(requestId)
          .set(request.toJson());
    } catch (e) {
      throw 'Failed to send friend request: $e';
    }
  }

  Future<void> respondToFriendRequest(String requestId, bool accept) async {
    try {
      await _db.collection('friend_requests').doc(requestId).update({
        'status': accept
            ? FriendRequestStatus.accepted.name
            : FriendRequestStatus.rejected.name,
      });
    } catch (e) {
      throw 'Failed to respond to friend request: $e';
    }
  }

  Stream<List<FriendRequest>> watchIncomingRequests(String userId) {
    return _db
        .collection('friend_requests')
        .where('toUserId', isEqualTo: userId)
        .where('status', isEqualTo: FriendRequestStatus.pending.name)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => FriendRequest.fromJson(doc.data()))
              .toList(),
        )
        .handleError((e) {
          throw 'Failed to watch friend requests: $e';
        });
  }

  Stream<List<FriendRequest>> watchFriendships(String userId) {
    return _db
        .collection('friend_requests')
        .where(
          Filter.and(
            Filter.or(
              Filter('fromUserId', isEqualTo: userId),
              Filter('toUserId', isEqualTo: userId),
            ),
            Filter('status', isEqualTo: FriendRequestStatus.accepted.name),
          ),
        )
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => FriendRequest.fromJson(doc.data()))
              .toList(),
        )
        .handleError((e) {
          throw 'Failed to watch friendships: $e';
        });
  }

  // ============ Guild Methods ============
  Future<String> createGuild({
    required String name,
    required String ownerId,
    required int maxMembers,
  }) async {
    try {
      final guildId = _db.collection('guilds').doc().id;
      final guild = Guild(
        guildId: guildId,
        name: name,
        ownerId: ownerId,
        memberIds: [ownerId],
        maxMembers: maxMembers,
        createdAt: DateTime.now(),
      );
      await _db.collection('guilds').doc(guildId).set(guild.toJson());
      return guildId;
    } catch (e) {
      throw 'Failed to create guild: $e';
    }
  }

  Stream<Guild?> watchGuild(String guildId) {
    return _db
        .collection('guilds')
        .doc(guildId)
        .snapshots()
        .map((snapshot) {
          if (snapshot.exists) {
            return Guild.fromJson(snapshot.data() as Map<String, dynamic>);
          }
          return null;
        })
        .handleError((e) {
          throw 'Failed to watch guild: $e';
        });
  }

  Future<void> joinGuild(String guildId, String userId) async {
    try {
      await _db.collection('guilds').doc(guildId).update({
        'memberIds': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      throw 'Failed to join guild: $e';
    }
  }

  Future<void> leaveGuild(String guildId, String userId) async {
    try {
      await _db.collection('guilds').doc(guildId).update({
        'memberIds': FieldValue.arrayRemove([userId]),
      });
    } catch (e) {
      throw 'Failed to leave guild: $e';
    }
  }

  Future<void> postToGuildBoard(String guildId, GuildPost post) async {
    try {
      await _db
          .collection('guilds')
          .doc(guildId)
          .collection('posts')
          .doc(post.postId)
          .set(post.toJson());
    } catch (e) {
      throw 'Failed to post to guild board: $e';
    }
  }

  Stream<List<GuildPost>> watchGuildPosts(String guildId) {
    return _db
        .collection('guilds')
        .doc(guildId)
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => GuildPost.fromJson(doc.data()))
              .toList(),
        )
        .handleError((e) {
          throw 'Failed to watch guild posts: $e';
        });
  }

  // ============ Replay Methods ============
  Future<void> createReplay(Replay replay) async {
    try {
      await _db.collection('replays').doc(replay.replayId).set(replay.toJson());
    } catch (e) {
      throw 'Failed to create replay: $e';
    }
  }

  Future<Replay?> getReplayById(String replayId) async {
    try {
      final doc = await _db.collection('replays').doc(replayId).get();
      if (doc.exists) {
        return Replay.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw 'Failed to fetch replay: $e';
    }
  }

  // ============ Analytics/Event Methods ============
  Future<void> logEvent(String eventName, {Map<String, dynamic>? data}) async {
    try {
      await _db.collection('analytics').add({
        'event': eventName,
        'timestamp': FieldValue.serverTimestamp(),
        'data': data ?? {},
      });
    } catch (e) {
      throw 'Failed to log event: $e';
    }
  }
}
