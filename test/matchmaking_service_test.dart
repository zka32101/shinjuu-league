import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shinjuu_league/config/app_config.dart';
import 'package:shinjuu_league/data/models/battle_model.dart';
import 'package:shinjuu_league/data/models/user_model.dart';
import 'package:shinjuu_league/services/matchmaking_service.dart';

User _testUser({required String uid, double eloRating = 1000}) {
  final now = DateTime.now();
  return User(
    uid: uid,
    name: 'user_$uid',
    rank: 0,
    level: 1,
    eloRating: eloRating,
    winRate: 0,
    gems: 0,
    gold: 0,
    createdAt: now,
    lastBattleAt: now,
  );
}

void main() {
  group('MatchmakingService', () {
    test('待機列が空の場合は両チームともBotで即座に埋まる（マッチング<30秒の保証）', () async {
      final service = MatchmakingService(
        firestore: FakeFirebaseFirestore(),
        pollTimeout: const Duration(milliseconds: 30),
        pollInterval: const Duration(milliseconds: 10),
      );
      final currentUser = _testUser(uid: 'self');

      final match = await service.findMatch(
        currentUser: currentUser,
        mode: BattleMode.quick,
      );

      expect(match.teamA.length, AppConfig.maxPlayersPerTeam);
      expect(match.teamB.length, AppConfig.maxPlayersPerTeam);
      expect(match.teamA.where((p) => !p.isBot).length, 1);
      expect(match.teamA.where((p) => !p.isBot).first.userId, 'self');
      expect(match.teamB.every((p) => p.isBot), isTrue);
    });

    test('レーンはチーム内で交互に自動割当される（ロール自動割当）', () async {
      final service = MatchmakingService(
        firestore: FakeFirebaseFirestore(),
        pollTimeout: const Duration(milliseconds: 30),
        pollInterval: const Duration(milliseconds: 10),
      );
      final currentUser = _testUser(uid: 'self');

      final match = await service.findMatch(
        currentUser: currentUser,
        mode: BattleMode.quick,
      );

      for (var i = 0; i < match.teamA.length; i++) {
        expect(match.teamA[i].lane, i % AppConfig.teamsCount);
      }
    });

    test('Botのeloは自分のeloの±50以内に収まる（拮抗した対戦にするため）', () async {
      final service = MatchmakingService(
        firestore: FakeFirebaseFirestore(),
        pollTimeout: const Duration(milliseconds: 30),
        pollInterval: const Duration(milliseconds: 10),
      );
      final currentUser = _testUser(uid: 'self', eloRating: 1200);

      final match = await service.findMatch(
        currentUser: currentUser,
        mode: BattleMode.ranked,
      );
      final bots = [...match.teamA, ...match.teamB].where((p) => p.isBot);

      for (final bot in bots) {
        expect(bot.eloRating, greaterThanOrEqualTo(1150));
        expect(bot.eloRating, lessThanOrEqualTo(1250));
      }
    });

    test('後から検索したプレイヤーが先に待機していたプレイヤーを実際にクレームする', () async {
      final firestore = FakeFirebaseFirestore();
      final serviceA = MatchmakingService(
        firestore: firestore,
        pollTimeout: const Duration(seconds: 2),
        pollInterval: const Duration(milliseconds: 20),
      );
      final serviceB = MatchmakingService(
        firestore: firestore,
        pollTimeout: const Duration(seconds: 2),
        pollInterval: const Duration(milliseconds: 20),
      );

      // Aを先に検索開始させ、キュー登録 + 1回目の待機ループに入るまで
      // 猶予を与えてからBを開始する。これにより「AとBが全く同時に相手を
      // クレームしようとする」トランザクション競合（Firestore側では
      // 衝突検出で片方が中断・再試行されるが、テスト用のfake実装は
      // その中断・再試行を再現しないため検証できない）を避けつつ、
      // 「先に待機していたプレイヤーを後から来たプレイヤーが実際に
      // クレームする」という本来の挙動を検証する。
      final matchAFuture = serviceA.findMatch(
        currentUser: _testUser(uid: 'playerA'),
        mode: BattleMode.quick,
      );
      await Future.delayed(const Duration(milliseconds: 60));
      final matchBFuture = serviceB.findMatch(
        currentUser: _testUser(uid: 'playerB'),
        mode: BattleMode.quick,
      );

      final matchA = await matchAFuture;
      final matchB = await matchBFuture;

      // 同じマッチに合流しているはず（片方が相手をクレームし、
      // matchmaking_matches ドキュメント経由でもう片方が発見する）
      expect(matchA.matchId, matchB.matchId);

      final realIdsA = matchA.allParticipants
          .where((p) => !p.isBot)
          .map((p) => p.userId)
          .toSet();
      final realIdsB = matchB.allParticipants
          .where((p) => !p.isBot)
          .map((p) => p.userId)
          .toSet();
      expect(realIdsA, {'playerA', 'playerB'});
      expect(realIdsB, {'playerA', 'playerB'});

      // どちらもキューから離脱済み
      final queueSnapshot = await firestore
          .collection('matchmaking_queue')
          .get();
      expect(queueSnapshot.docs, isEmpty);
    });

    test('モードが異なる待機プレイヤーとはマッチしない', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('matchmaking_queue').doc('rankedPlayer').set({
        'userId': 'rankedPlayer',
        'mode': 'ranked',
        'eloRating': 1000.0,
        'mechaId': 'mecha_east_flame',
        'joinedAt': DateTime.now().toIso8601String(),
      });

      final service = MatchmakingService(
        firestore: firestore,
        pollTimeout: const Duration(milliseconds: 30),
        pollInterval: const Duration(milliseconds: 10),
      );

      final match = await service.findMatch(
        currentUser: _testUser(uid: 'self'),
        mode: BattleMode.quick,
      );

      expect(match.teamB.every((p) => p.isBot), isTrue);
      // 別モードの待機者は無関係なのでクレームされず、キューに残ったまま
      final stillQueued = await firestore
          .collection('matchmaking_queue')
          .doc('rankedPlayer')
          .get();
      expect(stillQueued.exists, isTrue);
    });

    test('ELO差がeloRangeDifferenceを超える待機プレイヤーとはマッチしない', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('matchmaking_queue').doc('farAway').set({
        'userId': 'farAway',
        'mode': 'quick',
        'eloRating': 1000.0 + AppConfig.eloRangeDifference + 100,
        'mechaId': 'mecha_east_flame',
        'joinedAt': DateTime.now().toIso8601String(),
      });

      final service = MatchmakingService(
        firestore: firestore,
        pollTimeout: const Duration(milliseconds: 30),
        pollInterval: const Duration(milliseconds: 10),
      );

      final match = await service.findMatch(
        currentUser: _testUser(uid: 'self', eloRating: 1000),
        mode: BattleMode.quick,
      );

      expect(match.teamB.every((p) => p.isBot), isTrue);
    });

    test('タイムアウト後（Bot対戦フォールバック時）は自分のキューエントリが削除される', () async {
      final firestore = FakeFirebaseFirestore();
      final service = MatchmakingService(
        firestore: firestore,
        pollTimeout: const Duration(milliseconds: 30),
        pollInterval: const Duration(milliseconds: 10),
      );

      await service.findMatch(
        currentUser: _testUser(uid: 'self'),
        mode: BattleMode.quick,
      );

      final doc = await firestore
          .collection('matchmaking_queue')
          .doc('self')
          .get();
      expect(doc.exists, isFalse);
    });
  });
}
