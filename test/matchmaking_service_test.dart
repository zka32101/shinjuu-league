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
      final service = MatchmakingService(firestore: FakeFirebaseFirestore());
      final currentUser = _testUser(uid: 'self');

      final match = await service.findMatch(currentUser: currentUser, mode: BattleMode.quick);

      expect(match.teamA.length, AppConfig.maxPlayersPerTeam);
      expect(match.teamB.length, AppConfig.maxPlayersPerTeam);
      expect(match.teamA.where((p) => !p.isBot).length, 1);
      expect(match.teamA.where((p) => !p.isBot).first.userId, 'self');
      expect(match.teamB.every((p) => p.isBot), isTrue);
    });

    test('レーンはチーム内で交互に自動割当される（ロール自動割当）', () async {
      final service = MatchmakingService(firestore: FakeFirebaseFirestore());
      final currentUser = _testUser(uid: 'self');

      final match = await service.findMatch(currentUser: currentUser, mode: BattleMode.quick);

      for (var i = 0; i < match.teamA.length; i++) {
        expect(match.teamA[i].lane, i % AppConfig.teamsCount);
      }
    });

    test('Botのeloは自分のeloの±50以内に収まる（拮抗した対戦にするため）', () async {
      final service = MatchmakingService(firestore: FakeFirebaseFirestore());
      final currentUser = _testUser(uid: 'self', eloRating: 1200);

      final match = await service.findMatch(currentUser: currentUser, mode: BattleMode.ranked);
      final bots = [...match.teamA, ...match.teamB].where((p) => p.isBot);

      for (final bot in bots) {
        expect(bot.eloRating, greaterThanOrEqualTo(1150));
        expect(bot.eloRating, lessThanOrEqualTo(1250));
      }
    });
  });
}
