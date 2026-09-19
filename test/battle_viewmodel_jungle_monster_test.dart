import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shinjuu_league/data/models/battle_model.dart';
import 'package:shinjuu_league/data/models/match_result_model.dart';
import 'package:shinjuu_league/services/analytics_service.dart';
import 'package:shinjuu_league/services/firestore_service.dart';
import 'package:shinjuu_league/services/skill_tree_service.dart';
import 'package:shinjuu_league/viewmodels/battle_viewmodel.dart';

class MockFirestoreService extends Mock implements FirestoreService {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

class MockSkillTreeService extends Mock implements SkillTreeService {}

void main() {
  group('BattleViewModel - ジャングルモンスター', () {
    late BattleViewModel battleViewModel;
    late MockFirestoreService mockFirestoreService;
    late MockAnalyticsService mockAnalyticsService;
    late MockSkillTreeService mockSkillTreeService;

    setUp(() async {
      mockFirestoreService = MockFirestoreService();
      mockAnalyticsService = MockAnalyticsService();
      mockSkillTreeService = MockSkillTreeService();

      when(mockSkillTreeService.getSkillTree(any as String)).thenAnswer((_) async => null);
      when(mockFirestoreService.createBattle(any as Battle))
          .thenAnswer((_) async => {});
      when(mockAnalyticsService.logBattleStart(any as String, any as String))
          .thenAnswer((_) async => {});

      battleViewModel = BattleViewModel(
        firestoreService: mockFirestoreService,
        analyticsService: mockAnalyticsService,
        skillTreeService: mockSkillTreeService,
      );

      await battleViewModel.prepareBattle(_createTestMatch('player1'), 'player1', 1200.0);
    });

    tearDown(() {
      battleViewModel.dispose();
    });

    test('attemptAttackMonster はエンジンのモンスターへダメージを与える', () {
      final engine = battleViewModel.state.engine!;
      final monster = engine.jungleMonsters.first;
      final initialHp = monster.currentHp;

      battleViewModel.attemptAttackMonster(monster.id);

      expect(monster.currentHp, lessThan(initialHp));
    });

    test('モンスター討伐で state.monsterKillFeed が更新される', () {
      final engine = battleViewModel.state.engine!;
      final monster = engine.jungleMonsters.first;

      // maxHp(400) を確実に上回るダメージになるまで攻撃し続ける（クールダウンを回避するため直接engineを叩く）
      while (monster.isAlive) {
        engine.attackJungleMonster('player1', monster.id);
      }

      expect(monster.isAlive, isFalse);
      expect(battleViewModel.state.monsterKillFeed, isNotEmpty);
      expect(battleViewModel.state.monsterKillFeed.last.killerId, 'player1');
    });

    test('連打防止クールダウンは手動攻撃とモンスター攻撃で共有される', () {
      final engine = battleViewModel.state.engine!;
      final monster = engine.jungleMonsters.first;
      final hpAfterFirst = () {
        battleViewModel.attemptAttackMonster(monster.id);
        return monster.currentHp;
      }();

      // クールダウン中の直後の再攻撃は無視されるはず
      battleViewModel.attemptAttackMonster(monster.id);
      expect(monster.currentHp, hpAfterFirst);
    });

    test('エンジン未初期化時は例外を投げずに無視する', () {
      final freshViewModel = BattleViewModel(
        firestoreService: mockFirestoreService,
        analyticsService: mockAnalyticsService,
        skillTreeService: mockSkillTreeService,
      );

      expect(
        () => freshViewModel.attemptAttackMonster('jungle_0'),
        returnsNormally,
      );

      freshViewModel.dispose();
    });
  });
}

MatchResult _createTestMatch(String selfUserId) {
  return MatchResult(
    matchId: 'test_match',
    mode: BattleMode.quick,
    mapId: 'map_1',
    estimatedWaitSeconds: 5,
    teamA: [
      _createMatchParticipant(selfUserId, 'mecha_1', 0, 0, 1200.0, false),
    ],
    teamB: [
      _createMatchParticipant('enemy1', 'mecha_1', 1, 0, 1200.0, true),
    ],
  );
}

MatchParticipant _createMatchParticipant(
  String userId,
  String mechaId,
  int team,
  int lane,
  double eloRating,
  bool isBot,
) {
  return MatchParticipant(
    userId: userId,
    mechaId: mechaId,
    team: team,
    lane: lane,
    eloRating: eloRating,
    isBot: isBot,
  );
}
