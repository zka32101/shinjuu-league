import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shinjuu_league/data/models/user_model.dart';
import 'package:shinjuu_league/data/models/battle_model.dart';
import 'package:shinjuu_league/data/models/battlepass_model.dart';
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

  // ============ Mecha Methods ============
  Future<List<Mecha>> getAllMechas() async {
    try {
      final snapshot = await _db.collection('mechas').get();
      return snapshot.docs
          .map((doc) => Mecha.fromJson(doc.data()))
          .toList();
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
      await _db.collection('battles').doc(battle.battleId).update(battle.toJson());
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

      return snapshot.docs
          .map((doc) => User.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw 'Failed to fetch leaderboard: $e';
    }
  }

  // ============ BattlePass Methods ============
  String _battlePassDocId(String userId, String seasonId) => '${userId}_$seasonId';

  Future<BattlePass?> getBattlePass(String userId, String seasonId) async {
    try {
      final doc = await _db.collection('battlepasses').doc(_battlePassDocId(userId, seasonId)).get();
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
