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

class MockAuthService extends Mock implements AuthService {}

void main() {
  group('BattleViewModel - Skill Tree Integration', () {
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

    group('Skill Tree Modifier Loading', () {
      test('prepareBattle loads and applies skill tree modifiers', () async {
        // Create a mock skill tree with some allocations
        final skillTree = SkillTree.create();
        skillTree.trees[0].allocatedTiers = 2; // ATK 1.10x
        skillTree.trees[1].allocatedTiers = 1; // DEF 1.08x
        skillTree.trees[2].allocatedTiers = 0; // SPD 1.0x

        when(mockSkillTreeService.getSkillTree('player1'))
            .thenAnswer((_) async => skillTree);
        when(mockSkillTreeService.calculateStatModifiers(skillTree))
            .thenReturn({'atk': 1.10, 'def': 1.08, 'spd': 1.0});
        when(mockFirestoreService.createBattle(any))
            .thenAnswer((_) async => {});
        when(mockAnalyticsService.logBattleStart(any, any))
            .thenAnswer((_) async => {});

        final match = _createTestMatch('player1');

        await battleViewModel.prepareBattle(match, 'player1', 1200.0);

        // Verify that getSkillTree was called
        verify(mockSkillTreeService.getSkillTree('player1')).called(1);

        // Verify that modifiers were calculated
        verify(mockSkillTreeService.calculateStatModifiers(skillTree))
            .called(1);

        // Engine should have modifiers set on self participant
        final engine = battleViewModel.state.engine;
        expect(engine, isNotNull);

        final selfParticipant = engine!.participants
            .firstWhere((p) => p.userId == 'player1');
        expect(selfParticipant.skillTreeAtkMultiplier, equals(1.10));
        expect(selfParticipant.skillTreeDefMultiplier, equals(1.08));
        expect(selfParticipant.skillTreeSpdMultiplier, equals(1.0));
      });

      test('prepareBattle handles skill tree load failure gracefully', () async {
        when(mockSkillTreeService.getSkillTree('player1'))
            .thenThrow(Exception('Firebase not initialized'));
        when(mockFirestoreService.createBattle(any))
            .thenAnswer((_) async => {});
        when(mockAnalyticsService.logBattleStart(any, any))
            .thenAnswer((_) async => {});

        final match = _createTestMatch('player1');

        // Should not throw, should continue with default modifiers
        await battleViewModel.prepareBattle(match, 'player1', 1200.0);

        final engine = battleViewModel.state.engine;
        expect(engine, isNotNull);

        final selfParticipant = engine!.participants
            .firstWhere((p) => p.userId == 'player1');
        // Default modifiers should be 1.0
        expect(selfParticipant.skillTreeAtkMultiplier, equals(1.0));
        expect(selfParticipant.skillTreeDefMultiplier, equals(1.0));
        expect(selfParticipant.skillTreeSpdMultiplier, equals(1.0));
      });

      test('prepareBattle handles null skill tree gracefully', () async {
        when(mockSkillTreeService.getSkillTree('player1'))
            .thenAnswer((_) async => null);
        when(mockFirestoreService.createBattle(any))
            .thenAnswer((_) async => {});
        when(mockAnalyticsService.logBattleStart(any, any))
            .thenAnswer((_) async => {});

        final match = _createTestMatch('player1');

        await battleViewModel.prepareBattle(match, 'player1', 1200.0);

        final engine = battleViewModel.state.engine;
        expect(engine, isNotNull);

        final selfParticipant = engine!.participants
            .firstWhere((p) => p.userId == 'player1');
        expect(selfParticipant.skillTreeAtkMultiplier, equals(1.0));
        expect(selfParticipant.skillTreeDefMultiplier, equals(1.0));
        expect(selfParticipant.skillTreeSpdMultiplier, equals(1.0));
      });
    });

    group('Skill Tree Modifier Application', () {
      test('only self participant gets skill tree modifiers', () async {
        final skillTree = SkillTree.create();
        skillTree.trees[0].allocatedTiers = 3; // ATK 1.15x

        when(mockSkillTreeService.getSkillTree('player1'))
            .thenAnswer((_) async => skillTree);
        when(mockSkillTreeService.calculateStatModifiers(skillTree))
            .thenReturn({'atk': 1.15, 'def': 1.0, 'spd': 1.0});
        when(mockFirestoreService.createBattle(any))
            .thenAnswer((_) async => {});
        when(mockAnalyticsService.logBattleStart(any, any))
            .thenAnswer((_) async => {});

        final match = _createTestMatch('player1');

        await battleViewModel.prepareBattle(match, 'player1', 1200.0);

        final engine = battleViewModel.state.engine;
        expect(engine, isNotNull);

        // Self participant should have modifiers
        final selfParticipant = engine!.participants
            .firstWhere((p) => p.userId == 'player1');
        expect(selfParticipant.skillTreeAtkMultiplier, equals(1.15));

        // Enemy participants should have default modifiers
        final enemyParticipants =
            engine.participants.where((p) => p.userId != 'player1').toList();
        for (final enemy in enemyParticipants) {
          expect(enemy.skillTreeAtkMultiplier, equals(1.0));
          expect(enemy.skillTreeDefMultiplier, equals(1.0));
          expect(enemy.skillTreeSpdMultiplier, equals(1.0));
        }
      });

      test('all three stat modifiers are applied independently', () async {
        final skillTree = SkillTree.create();
        skillTree.trees[0].allocatedTiers = 4; // ATK 1.20x
        skillTree.trees[1].allocatedTiers = 3; // DEF 1.24x
        skillTree.trees[2].allocatedTiers = 2; // SPD 1.06x

        when(mockSkillTreeService.getSkillTree('player1'))
            .thenAnswer((_) async => skillTree);
        when(mockSkillTreeService.calculateStatModifiers(skillTree))
            .thenReturn({'atk': 1.20, 'def': 1.24, 'spd': 1.06});
        when(mockFirestoreService.createBattle(any))
            .thenAnswer((_) async => {});
        when(mockAnalyticsService.logBattleStart(any, any))
            .thenAnswer((_) async => {});

        final match = _createTestMatch('player1');

        await battleViewModel.prepareBattle(match, 'player1', 1200.0);

        final engine = battleViewModel.state.engine;
        expect(engine, isNotNull);

        final selfParticipant = engine!.participants
            .firstWhere((p) => p.userId == 'player1');
        expect(selfParticipant.skillTreeAtkMultiplier, closeTo(1.20, 0.001));
        expect(selfParticipant.skillTreeDefMultiplier, closeTo(1.24, 0.001));
        expect(selfParticipant.skillTreeSpdMultiplier, closeTo(1.06, 0.001));
      });

      test('modifiers affect stat calculations in damage formula', () async {
        final skillTree = SkillTree.create();
        skillTree.trees[0].allocatedTiers = 1; // ATK 1.05x

        when(mockSkillTreeService.getSkillTree('player1'))
            .thenAnswer((_) async => skillTree);
        when(mockSkillTreeService.calculateStatModifiers(skillTree))
            .thenReturn({'atk': 1.05, 'def': 1.0, 'spd': 1.0});
        when(mockFirestoreService.createBattle(any))
            .thenAnswer((_) async => {});
        when(mockAnalyticsService.logBattleStart(any, any))
            .thenAnswer((_) async => {});

        final match = _createTestMatch('player1');

        await battleViewModel.prepareBattle(match, 'player1', 1200.0);

        final engine = battleViewModel.state.engine;
        expect(engine, isNotNull);

        final selfParticipant = engine!.participants
            .firstWhere((p) => p.userId == 'player1');

        // Base ATK is 20 (from mecha catalog), with 1.05x multiplier should be 21
        final modifiedAtk = selfParticipant.effectiveAtk;
        expect(modifiedAtk, closeTo(21.0, 0.1));
      });
    });

    group('Maximum Tier Modifiers', () {
      test('maximum ATK tier (5) applies 1.25x modifier', () async {
        final skillTree = SkillTree.create();
        skillTree.trees[0].allocatedTiers = 5; // Max ATK

        when(mockSkillTreeService.getSkillTree('player1'))
            .thenAnswer((_) async => skillTree);
        when(mockSkillTreeService.calculateStatModifiers(skillTree))
            .thenReturn({'atk': 1.25, 'def': 1.0, 'spd': 1.0});
        when(mockFirestoreService.createBattle(any))
            .thenAnswer((_) async => {});
        when(mockAnalyticsService.logBattleStart(any, any))
            .thenAnswer((_) async => {});

        final match = _createTestMatch('player1');

        await battleViewModel.prepareBattle(match, 'player1', 1200.0);

        final engine = battleViewModel.state.engine;
        final selfParticipant = engine!.participants
            .firstWhere((p) => p.userId == 'player1');
        expect(selfParticipant.skillTreeAtkMultiplier, closeTo(1.25, 0.001));
      });

      test('maximum DEF tier (5) applies 1.40x modifier', () async {
        final skillTree = SkillTree.create();
        skillTree.trees[1].allocatedTiers = 5; // Max DEF

        when(mockSkillTreeService.getSkillTree('player1'))
            .thenAnswer((_) async => skillTree);
        when(mockSkillTreeService.calculateStatModifiers(skillTree))
            .thenReturn({'atk': 1.0, 'def': 1.40, 'spd': 1.0});
        when(mockFirestoreService.createBattle(any))
            .thenAnswer((_) async => {});
        when(mockAnalyticsService.logBattleStart(any, any))
            .thenAnswer((_) async => {});

        final match = _createTestMatch('player1');

        await battleViewModel.prepareBattle(match, 'player1', 1200.0);

        final engine = battleViewModel.state.engine;
        final selfParticipant = engine!.participants
            .firstWhere((p) => p.userId == 'player1');
        expect(selfParticipant.skillTreeDefMultiplier, closeTo(1.40, 0.001));
      });

      test('maximum SPD tier (5) applies 1.15x modifier', () async {
        final skillTree = SkillTree.create();
        skillTree.trees[2].allocatedTiers = 5; // Max SPD

        when(mockSkillTreeService.getSkillTree('player1'))
            .thenAnswer((_) async => skillTree);
        when(mockSkillTreeService.calculateStatModifiers(skillTree))
            .thenReturn({'atk': 1.0, 'def': 1.0, 'spd': 1.15});
        when(mockFirestoreService.createBattle(any))
            .thenAnswer((_) async => {});
        when(mockAnalyticsService.logBattleStart(any, any))
            .thenAnswer((_) async => {});

        final match = _createTestMatch('player1');

        await battleViewModel.prepareBattle(match, 'player1', 1200.0);

        final engine = battleViewModel.state.engine;
        final selfParticipant = engine!.participants
            .firstWhere((p) => p.userId == 'player1');
        expect(selfParticipant.skillTreeSpdMultiplier, closeTo(1.15, 0.001));
      });
    });

    group('Edge Cases', () {
      test('completely unallocated skill tree has all 1.0x modifiers', () async {
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

        final engine = battleViewModel.state.engine;
        final selfParticipant = engine!.participants
            .firstWhere((p) => p.userId == 'player1');
        expect(selfParticipant.skillTreeAtkMultiplier, equals(1.0));
        expect(selfParticipant.skillTreeDefMultiplier, equals(1.0));
        expect(selfParticipant.skillTreeSpdMultiplier, equals(1.0));
      });

      test('completely maxed skill tree has all maximum modifiers', () async {
        final skillTree = SkillTree.create();
        skillTree.trees[0].allocatedTiers = 5; // Max ATK: 1.25x
        skillTree.trees[1].allocatedTiers = 5; // Max DEF: 1.40x
        skillTree.trees[2].allocatedTiers = 5; // Max SPD: 1.15x

        when(mockSkillTreeService.getSkillTree('player1'))
            .thenAnswer((_) async => skillTree);
        when(mockSkillTreeService.calculateStatModifiers(skillTree))
            .thenReturn({'atk': 1.25, 'def': 1.40, 'spd': 1.15});
        when(mockFirestoreService.createBattle(any))
            .thenAnswer((_) async => {});
        when(mockAnalyticsService.logBattleStart(any, any))
            .thenAnswer((_) async => {});

        final match = _createTestMatch('player1');

        await battleViewModel.prepareBattle(match, 'player1', 1200.0);

        final engine = battleViewModel.state.engine;
        final selfParticipant = engine!.participants
            .firstWhere((p) => p.userId == 'player1');
        expect(selfParticipant.skillTreeAtkMultiplier, closeTo(1.25, 0.001));
        expect(selfParticipant.skillTreeDefMultiplier, closeTo(1.40, 0.001));
        expect(selfParticipant.skillTreeSpdMultiplier, closeTo(1.15, 0.001));
      });
    });

    tearDown(() {
      battleViewModel.dispose();
    });
  });
}

/// Helper function to create a test match result
MatchResult _createTestMatch(String selfUserId) {
  return MatchResult(
    matchId: 'test_match',
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

/// Helper function to create a match participant
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
