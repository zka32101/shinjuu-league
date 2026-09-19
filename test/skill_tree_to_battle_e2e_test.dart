import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shinjuu_league/data/models/battle_model.dart';
import 'package:shinjuu_league/data/models/evolution_model.dart';
import 'package:shinjuu_league/data/models/match_result_model.dart';
import 'package:shinjuu_league/data/models/mecha_model.dart';
import 'package:shinjuu_league/data/models/skill_model.dart';
import 'package:shinjuu_league/services/analytics_service.dart';
import 'package:shinjuu_league/services/firestore_service.dart';
import 'package:shinjuu_league/services/skill_tree_service.dart';
import 'package:shinjuu_league/viewmodels/battle_viewmodel.dart';

class MockFirestoreService extends Mock implements FirestoreService {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

class MockSkillTreeService extends Mock implements SkillTreeService {}

void main() {
  group('E2E: Skill Tree Progression → Battle Integration', () {
    late BattleViewModel battleViewModel;
    late MockFirestoreService mockFirestoreService;
    late MockAnalyticsService mockAnalyticsService;
    late MockSkillTreeService mockSkillTreeService;

    setUp(() {
      mockFirestoreService = MockFirestoreService();
      mockAnalyticsService = MockAnalyticsService();
      mockSkillTreeService = MockSkillTreeService();

      battleViewModel = BattleViewModel(
        firestoreService: mockFirestoreService,
        analyticsService: mockAnalyticsService,
        skillTreeService: mockSkillTreeService,
      );
    });

    group('Complete Flow: Allocate Skills → Enter Battle → Verify Stats', () {
      test(
          'player with ATK tree investment deals more damage than unallocated player',
          () async {
        // SETUP: Player 1 has allocated 3 tiers in ATK tree (1.15x multiplier)
        final player1SkillTree = SkillTree.create();
        player1SkillTree.trees[0].allocatedTiers = 3; // ATK: 1.15x

        when(mockSkillTreeService.getSkillTree('player1'))
            .thenAnswer((_) async => player1SkillTree);
        when(mockSkillTreeService.calculateStatModifiers(player1SkillTree))
            .thenReturn({'atk': 1.15, 'def': 1.0, 'spd': 1.0});

        when(mockFirestoreService.createBattle(any))
            .thenAnswer((_) async => {});
        when(mockAnalyticsService.logBattleStart(any, any))
            .thenAnswer((_) async => {});

        final match = _createTestMatch('player1');

        // ACT: Start battle with skill tree modifiers
        await battleViewModel.prepareBattle(match, 'player1', 1200.0);

        // VERIFY: Player 1 has boosted ATK, enemies don't
        final engine = battleViewModel.state.engine!;
        final player1 = engine.participants.firstWhere((p) => p.userId == 'player1');
        final enemy1 = engine.participants.firstWhere((p) => p.userId == 'enemy1');

        // Base ATK is 20 (from mecha catalog)
        expect(player1.effectiveAtk, closeTo(23.0, 0.1)); // 20 × 1.15
        expect(enemy1.effectiveAtk, equals(20.0)); // No multiplier
      });

      test('player with DEF tree investment survives longer', () async {
        // SETUP: Player with DEF tree investment (1.24x = +24% HP)
        final skillTree = SkillTree.create();
        skillTree.trees[1].allocatedTiers = 3; // DEF: 1.24x

        when(mockSkillTreeService.getSkillTree('player1'))
            .thenAnswer((_) async => skillTree);
        when(mockSkillTreeService.calculateStatModifiers(skillTree))
            .thenReturn({'atk': 1.0, 'def': 1.24, 'spd': 1.0});

        when(mockFirestoreService.createBattle(any))
            .thenAnswer((_) async => {});
        when(mockAnalyticsService.logBattleStart(any, any))
            .thenAnswer((_) async => {});

        final match = _createTestMatch('player1');

        await battleViewModel.prepareBattle(match, 'player1', 1200.0);

        final engine = battleViewModel.state.engine!;
        final player1 = engine.participants.firstWhere((p) => p.userId == 'player1');
        final enemy1 = engine.participants.firstWhere((p) => p.userId == 'enemy1');

        // Base HP is 100 (from mecha catalog)
        expect(player1.effectiveHp, closeTo(124.0, 0.1)); // 100 × 1.24
        expect(enemy1.effectiveHp, equals(100.0)); // No multiplier

        // Player survives 24% more hits
        final survivalDifference = player1.effectiveHp - enemy1.effectiveHp;
        expect(survivalDifference, closeTo(24.0, 0.1));
      });

      test('player with SPD tree investment acts first', () async {
        // SETUP: Player with SPD tree investment (1.09x = +9% speed)
        final skillTree = SkillTree.create();
        skillTree.trees[2].allocatedTiers = 3; // SPD: 1.09x

        when(mockSkillTreeService.getSkillTree('player1'))
            .thenAnswer((_) async => skillTree);
        when(mockSkillTreeService.calculateStatModifiers(skillTree))
            .thenReturn({'atk': 1.0, 'def': 1.0, 'spd': 1.09});

        when(mockFirestoreService.createBattle(any))
            .thenAnswer((_) async => {});
        when(mockAnalyticsService.logBattleStart(any, any))
            .thenAnswer((_) async => {});

        final match = _createTestMatch('player1');

        await battleViewModel.prepareBattle(match, 'player1', 1200.0);

        final engine = battleViewModel.state.engine!;
        final player1 = engine.participants.firstWhere((p) => p.userId == 'player1');
        final enemy1 = engine.participants.firstWhere((p) => p.userId == 'enemy1');

        // Base SPD is 15 (from mecha catalog)
        expect(player1.effectiveSpd, closeTo(16.35, 0.1)); // 15 × 1.09
        expect(enemy1.effectiveSpd, equals(15.0)); // No multiplier

        // Player is faster
        expect(player1.effectiveSpd, greaterThan(enemy1.effectiveSpd));
      });

      test('player with balanced tree investment has well-rounded stats', () async {
        // SETUP: Player with 2 tiers each tree
        final skillTree = SkillTree.create();
        skillTree.trees[0].allocatedTiers = 2; // ATK: 1.10x
        skillTree.trees[1].allocatedTiers = 2; // DEF: 1.16x
        skillTree.trees[2].allocatedTiers = 2; // SPD: 1.06x

        when(mockSkillTreeService.getSkillTree('player1'))
            .thenAnswer((_) async => skillTree);
        when(mockSkillTreeService.calculateStatModifiers(skillTree))
            .thenReturn({'atk': 1.10, 'def': 1.16, 'spd': 1.06});

        when(mockFirestoreService.createBattle(any))
            .thenAnswer((_) async => {});
        when(mockAnalyticsService.logBattleStart(any, any))
            .thenAnswer((_) async => {});

        final match = _createTestMatch('player1');

        await battleViewModel.prepareBattle(match, 'player1', 1200.0);

        final engine = battleViewModel.state.engine!;
        final player1 = engine.participants.firstWhere((p) => p.userId == 'player1');

        // All stats boosted proportionally
        expect(player1.effectiveAtk, closeTo(22.0, 0.1)); // 20 × 1.10
        expect(player1.effectiveHp, closeTo(116.0, 0.1)); // 100 × 1.16
        expect(player1.effectiveSpd, closeTo(15.9, 0.1)); // 15 × 1.06

        // Verify all modifiers are independent
        expect(player1.skillTreeAtkMultiplier, closeTo(1.10, 0.001));
        expect(player1.skillTreeDefMultiplier, closeTo(1.16, 0.001));
        expect(player1.skillTreeSpdMultiplier, closeTo(1.06, 0.001));
      });

      test('unallocated player has default 1.0x multipliers', () async {
        // SETUP: Fresh player with no skill tree allocations
        final skillTree = SkillTree.create();
        // No allocations - all trees at 0

        when(mockSkillTreeService.getSkillTree('player1'))
            .thenAnswer((_) async => skillTree);
        when(mockSkillTreeService.calculateStatModifiers(skillTree))
            .thenReturn({'atk': 1.0, 'def': 1.0, 'spd': 1.0});

        when(mockFirestoreService.createBattle(any))
            .thenAnswer((_) async => {});
        when(mockAnalyticsService.logBattleStart(any, any))
            .thenAnswer((_) async => {});

        final match = _createTestMatch('player1');

        await battleViewModel.prepareBattle(match, 'player1', 1200.0);

        final engine = battleViewModel.state.engine!;
        final player1 = engine.participants.firstWhere((p) => p.userId == 'player1');

        // Base stats unchanged
        expect(player1.effectiveAtk, equals(20.0));
        expect(player1.effectiveHp, equals(100.0));
        expect(player1.effectiveSpd, equals(15.0));
      });
    });

    group('Stat Progression Impact on Damage Formula', () {
      test('ATK multiplier directly increases damage output', () async {
        // SCENARIO: Two players with same base stats but different ATK trees
        // Player A: 2 tiers ATK (1.10x) vs Player B: 0 tiers (1.0x)
        // Damage difference should be proportional to ATK ratio

        final playerASkillTree = SkillTree.create();
        playerASkillTree.trees[0].allocatedTiers = 2; // 1.10x ATK

        when(mockSkillTreeService.getSkillTree('playerA'))
            .thenAnswer((_) async => playerASkillTree);
        when(mockSkillTreeService.calculateStatModifiers(playerASkillTree))
            .thenReturn({'atk': 1.10, 'def': 1.0, 'spd': 1.0});

        when(mockFirestoreService.createBattle(any))
            .thenAnswer((_) async => {});
        when(mockAnalyticsService.logBattleStart(any, any))
            .thenAnswer((_) async => {});

        final match = _createTestMatch('playerA');

        await battleViewModel.prepareBattle(match, 'playerA', 1200.0);

        final engine = battleViewModel.state.engine!;
        final playerA = engine.participants.firstWhere((p) => p.userId == 'playerA');
        final playerB = engine.participants.firstWhere((p) => p.userId == 'enemy1');

        // Damage calculation respects ATK multiplier
        final damageRatio = playerA.effectiveAtk / playerB.effectiveAtk;
        expect(damageRatio, closeTo(1.10, 0.001));

        // Player A deals 10% more damage per hit
        expect(playerA.effectiveAtk, greaterThan(playerB.effectiveAtk));
      });

      test('DEF multiplier extends battle duration', () async {
        // SCENARIO: DEF multiplier reduces effective damage taken
        // With 1.20x DEF multiplier, player survives longer

        final skillTree = SkillTree.create();
        skillTree.trees[1].allocatedTiers = 1; // DEF: 1.08x
        skillTree.trees[1].allocatedTiers = 2; // Actually: 1.16x

        when(mockSkillTreeService.getSkillTree('player1'))
            .thenAnswer((_) async => skillTree);
        when(mockSkillTreeService.calculateStatModifiers(skillTree))
            .thenReturn({'atk': 1.0, 'def': 1.16, 'spd': 1.0});

        when(mockFirestoreService.createBattle(any))
            .thenAnswer((_) async => {});
        when(mockAnalyticsService.logBattleStart(any, any))
            .thenAnswer((_) async => {});

        final match = _createTestMatch('player1');

        await battleViewModel.prepareBattle(match, 'player1', 1200.0);

        final engine = battleViewModel.state.engine!;
        final player1 = engine.participants.firstWhere((p) => p.userId == 'player1');
        final enemy1 = engine.participants.firstWhere((p) => p.userId == 'enemy1');

        // Player with DEF investment survives more hits
        final hitsToKill1 = player1.effectiveHp / enemy1.effectiveAtk;
        final hitsToKill2 = enemy1.effectiveHp / player1.effectiveAtk;

        // Difference in survivability is significant
        expect(hitsToKill1, greaterThan(hitsToKill2));
      });

      test('SPD multiplier determines action order in turn-based combat', () async {
        // SCENARIO: Speed tier determines who acts first each round
        // Higher SPD = earlier turn order = more actions overall

        final skillTree = SkillTree.create();
        skillTree.trees[2].allocatedTiers = 2; // SPD: 1.06x

        when(mockSkillTreeService.getSkillTree('player1'))
            .thenAnswer((_) async => skillTree);
        when(mockSkillTreeService.calculateStatModifiers(skillTree))
            .thenReturn({'atk': 1.0, 'def': 1.0, 'spd': 1.06});

        when(mockFirestoreService.createBattle(any))
            .thenAnswer((_) async => {});
        when(mockAnalyticsService.logBattleStart(any, any))
            .thenAnswer((_) async => {});

        final match = _createTestMatch('player1');

        await battleViewModel.prepareBattle(match, 'player1', 1200.0);

        final engine = battleViewModel.state.engine!;
        final player1 = engine.participants.firstWhere((p) => p.userId == 'player1');
        final enemy1 = engine.participants.firstWhere((p) => p.userId == 'enemy1');

        // Faster player has SPD advantage
        final speedDifference = player1.effectiveSpd - enemy1.effectiveSpd;
        expect(speedDifference, greaterThan(0.0));

        // With 6% SPD advantage, first to act in combat loops
        expect(player1.effectiveSpd, closeTo(15.9, 0.1));
        expect(enemy1.effectiveSpd, equals(15.0));
      });
    });

    group('Optimization: Maximum Tier Investment', () {
      test('fully invested player (all 5 tiers x3 trees) has all maximum multipliers',
          () async {
        // SETUP: Maximum skill tree investment
        final maxSkillTree = SkillTree.create();
        maxSkillTree.trees[0].allocatedTiers = 5; // Max ATK: 1.25x
        maxSkillTree.trees[1].allocatedTiers = 5; // Max DEF: 1.40x
        maxSkillTree.trees[2].allocatedTiers = 5; // Max SPD: 1.15x

        when(mockSkillTreeService.getSkillTree('player1'))
            .thenAnswer((_) async => maxSkillTree);
        when(mockSkillTreeService.calculateStatModifiers(maxSkillTree))
            .thenReturn({'atk': 1.25, 'def': 1.40, 'spd': 1.15});

        when(mockFirestoreService.createBattle(any))
            .thenAnswer((_) async => {});
        when(mockAnalyticsService.logBattleStart(any, any))
            .thenAnswer((_) async => {});

        final match = _createTestMatch('player1');

        await battleViewModel.prepareBattle(match, 'player1', 1200.0);

        final engine = battleViewModel.state.engine!;
        final player1 = engine.participants.firstWhere((p) => p.userId == 'player1');
        final unallocatedEnemy =
            engine.participants.firstWhere((p) => p.userId == 'enemy1');

        // Fully optimized player has massive stat advantage
        expect(player1.effectiveAtk, closeTo(25.0, 0.1)); // 20 × 1.25
        expect(player1.effectiveHp, closeTo(140.0, 0.1)); // 100 × 1.40
        expect(player1.effectiveSpd, closeTo(17.25, 0.1)); // 15 × 1.15

        // Stat ratios show progression advantage
        expect(player1.effectiveAtk / unallocatedEnemy.effectiveAtk,
            closeTo(1.25, 0.001));
        expect(player1.effectiveHp / unallocatedEnemy.effectiveHp,
            closeTo(1.40, 0.001));
        expect(player1.effectiveSpd / unallocatedEnemy.effectiveSpd,
            closeTo(1.15, 0.001));
      });

      test('stat advantage is multiplicative not additive', () async {
        // Ensure modifiers don't stack additively (which would be broken)
        final skillTree = SkillTree.create();
        skillTree.trees[0].allocatedTiers = 3; // 1.15x
        skillTree.trees[1].allocatedTiers = 3; // 1.24x
        skillTree.trees[2].allocatedTiers = 3; // 1.09x

        when(mockSkillTreeService.getSkillTree('player1'))
            .thenAnswer((_) async => skillTree);
        when(mockSkillTreeService.calculateStatModifiers(skillTree))
            .thenReturn({'atk': 1.15, 'def': 1.24, 'spd': 1.09});

        when(mockFirestoreService.createBattle(any))
            .thenAnswer((_) async => {});
        when(mockAnalyticsService.logBattleStart(any, any))
            .thenAnswer((_) async => {});

        final match = _createTestMatch('player1');

        await battleViewModel.prepareBattle(match, 'player1', 1200.0);

        final engine = battleViewModel.state.engine!;
        final player1 = engine.participants.firstWhere((p) => p.userId == 'player1');

        // Verify MULTIPLICATIVE stacking
        // NOT additive: (1.15 + 1.24 + 1.09 - 3) * 20 = 4 ATK (wrong)
        // Correct: 20 * 1.15 = 23 ATK (each multiplier independent)

        expect(player1.effectiveAtk, closeTo(23.0, 0.1)); // 20 × 1.15
        expect(player1.effectiveHp, closeTo(124.0, 0.1)); // 100 × 1.24
        expect(player1.effectiveSpd, closeTo(16.35, 0.1)); // 15 × 1.09

        // Ensure no cross-tree contamination
        expect(player1.skillTreeAtkMultiplier, closeTo(1.15, 0.001));
        expect(player1.skillTreeDefMultiplier, closeTo(1.24, 0.001));
        expect(player1.skillTreeSpdMultiplier, closeTo(1.09, 0.001));
      });
    });

    tearDown(() {
      battleViewModel.dispose();
    });
  });
}

/// Helper: Create test match
MatchResult _createTestMatch(String selfUserId) {
  return MatchResult(
    matchId: 'test_match_e2e',
    mode: BattleMode.quick,
    mapId: 'map_1',
    teamA: [
      _createMatchParticipant(selfUserId, 'mecha_1', 0, 0, 1200.0, false),
    ],
    teamB: [
      _createMatchParticipant('enemy1', 'mecha_1', 1, 0, 1200.0, true),
      _createMatchParticipant('enemy2', 'mecha_1', 1, 1, 1200.0, true),
    ],
  );
}

/// Helper: Create match participant
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
