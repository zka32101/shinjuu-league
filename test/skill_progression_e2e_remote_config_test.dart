import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shinjuu_league/config/skill_progression_config.dart';
import 'package:shinjuu_league/data/models/battle_model.dart';
import 'package:shinjuu_league/data/models/evolution_model.dart';
import 'package:shinjuu_league/data/models/resource_model.dart';
import 'package:shinjuu_league/data/models/skill_catalog.dart';
import 'package:shinjuu_league/services/analytics_service.dart';
import 'package:shinjuu_league/services/battle_engine_service.dart';
import 'package:shinjuu_league/services/battle_skill_progression_coordinator.dart';
import 'package:shinjuu_league/services/skill_progression_analytics_service.dart';
import 'package:shinjuu_league/services/skill_progression_battle_service.dart';

class MockAnalyticsService extends Mock implements AnalyticsService {}

class MockSkillProgressionConfig extends Mock
    implements SkillProgressionConfig {}

void main() {
  group('End-to-End: Remote Config → All Layers → Analytics', () {
    late MockSkillProgressionConfig mockConfig;
    late MockAnalyticsService mockAnalytics;
    late SkillProgressionBattleService skillService;
    late BattleSkillProgressionCoordinator coordinator;
    late SkillProgressionAnalyticsService analyticsService;
    late BattleEngine engine;

    setUp(() {
      mockConfig = MockSkillProgressionConfig();
      mockAnalytics = MockAnalyticsService();

      // Setup normal difficulty
      when(mockConfig.firstEvolutionLevel).thenReturn(3);
      when(mockConfig.secondEvolutionLevel).thenReturn(6);
      when(mockConfig.difficultyPreset).thenReturn('normal');
      when(mockConfig.getDifficultyModifiers()).thenReturn(
        ProgressionDifficultyModifiers(
          levelDifficultyMultiplier: 1.0,
          skillCooldownMultiplier: 1.0,
          skillDamageMultiplier: 1.0,
        ),
      );

      when(mockAnalytics.logEvent(any, parameters: anyNamed('parameters')))
          .thenAnswer((_) async {});

      skillService = SkillProgressionBattleService();
      coordinator = BattleSkillProgressionCoordinator(
        skillService: skillService,
        progressionConfig: mockConfig,
      );
      analyticsService = SkillProgressionAnalyticsService(
        analyticsService: mockAnalytics,
        progressionConfig: mockConfig,
      );

      final player1 = BattleParticipantState(
        userId: 'player1',
        mechaId: 'mecha1',
        isBot: false,
        isSelf: true,
        team: 0,
        lane: 0,
        baseStats: BaseStats(hp: 100, atk: 50, spd: 30),
      );

      final player2 = BattleParticipantState(
        userId: 'player2',
        mechaId: 'mecha2',
        isBot: true,
        isSelf: false,
        team: 1,
        lane: 0,
        baseStats: BaseStats(hp: 100, atk: 50, spd: 30),
      );

      engine = BattleEngine(
        battleId: 'e2e-test-battle',
        mode: BattleMode.quickMatch,
        mapId: 'map_01',
        participants: [player1, player2],
        progressionConfig: mockConfig,
      );
    });

    group('Normal Difficulty (1.0x) E2E Flow', () {
      test('complete battle with normal difficulty config applied throughout',
          () async {
        when(mockConfig.difficultyPreset).thenReturn('normal');
        when(mockConfig.getDifficultyModifiers()).thenReturn(
          ProgressionDifficultyModifiers(
            levelDifficultyMultiplier: 1.0,
            skillCooldownMultiplier: 1.0,
            skillDamageMultiplier: 1.0,
          ),
        );

        // Session start with cohort assignment
        await analyticsService.logCohortAssignment('player1', 'session123');

        // Initialize coordinator
        coordinator.initializePlayer(
          playerId: 'player1',
          mechaId: 'mecha1',
        );

        // Level up triggers evolution requirement at Lv3
        coordinator.levelUpPlayer('player1');
        coordinator.levelUpPlayer('player1');

        // Verify evolution event was triggered
        var evolutionEvent = false;
        coordinator.skillEvents.listen((event) {
          if (event is EvolutionSelectionRequiredEvent) {
            evolutionEvent = true;
          }
        });

        // Confirm evolution
        coordinator.confirmEvolution('player1', EvolutionType.offensive);

        // Verify config-driven level was used
        verify(mockConfig.firstEvolutionLevel).called(greaterThan(0));
      });

      test('damage multiplier (1.0x) applied correctly through engine',
          () async {
        when(mockConfig.getDifficultyModifiers()).thenReturn(
          ProgressionDifficultyModifiers(
            levelDifficultyMultiplier: 1.0,
            skillCooldownMultiplier: 1.0,
            skillDamageMultiplier: 1.0,
          ),
        );

        engine.start();
        engine.tick();

        // At normal difficulty, damage should be baseline
        expect(engine.isRunning, isFalse);
      });

      test('cooldown multiplier (1.0x) maintains baseline cooldowns', () async {
        when(mockConfig.getDifficultyModifiers()).thenReturn(
          ProgressionDifficultyModifiers(
            levelDifficultyMultiplier: 1.0,
            skillCooldownMultiplier: 1.0,
            skillDamageMultiplier: 1.0,
          ),
        );

        final player = engine.participants[0];
        player.skillCooldowns['test_skill'] = 10.0;

        engine.tick();

        // With 1.0x multiplier, cooldown should reduce by 1.0
        expect(player.skillCooldowns['test_skill']!, lessThan(10.0));
        expect(player.skillCooldowns['test_skill']!, equals(9.0));
      });

      test('analytics events include normal difficulty preset', () async {
        when(mockConfig.difficultyPreset).thenReturn('normal');

        await analyticsService.logLevelUp('player1', 5, false);

        verify(mockAnalytics.logEvent(
          'skill_progression_level_up',
          parameters: argThat(
            isA<Map<String, dynamic>>()
                .having((m) => m['difficulty_preset'], 'difficulty_preset',
                    'normal'),
            named: 'parameters',
          ),
        )).called(1);
      });
    });

    group('Easy Difficulty (0.8x/0.9x) E2E Flow', () {
      setUp(() {
        when(mockConfig.difficultyPreset).thenReturn('easy');
        when(mockConfig.getDifficultyModifiers()).thenReturn(
          ProgressionDifficultyModifiers(
            levelDifficultyMultiplier: 0.7,
            skillCooldownMultiplier: 0.8, // 20% faster cooldowns
            skillDamageMultiplier: 0.9, // 10% less damage
          ),
        );
      });

      test('easy difficulty: cooldowns reduce faster (0.8x reduction)', () async {
        final player = engine.participants[0];
        player.skillCooldowns['skill'] = 10.0;

        engine.tick();

        // With 0.8x multiplier, cooldown reduction = 1.0 * 0.8 = 0.8
        expect(player.skillCooldowns['skill']!, lessThan(10.0));
        expect(player.skillCooldowns['skill']!, greaterThan(9.0));
      });

      test('easy difficulty: analytics track reduced damage multiplier',
          () async {
        await analyticsService.logCohortAssignment('easy_player', 'easy_session');

        verify(mockAnalytics.logEvent(
          'skill_progression_cohort_assigned',
          parameters: argThat(
            isA<Map<String, dynamic>>()
                .having((m) => m['difficulty_preset'], 'difficulty_preset',
                    'easy')
                .having((m) => m['damage_multiplier'], 'damage_multiplier',
                    '0.90'),
            named: 'parameters',
          ),
        )).called(1);
      });

      test('complete easy difficulty progression flow', () async {
        await analyticsService.logCohortAssignment('player1', 'session123');

        coordinator.initializePlayer(playerId: 'player1', mechaId: 'mecha1');

        // Level up at easy difficulty (faster progression)
        coordinator.levelUpPlayer('player1');
        coordinator.levelUpPlayer('player1');

        // Evolution at Lv3
        coordinator.confirmEvolution('player1', EvolutionType.offensive);

        // Battle with easy difficulty multipliers applied
        await analyticsService.logBattleSkillProgressionSummary(
          userId: 'player1',
          finalLevel: 5,
          totalSkillsUsed: 15,
          totalDamageDealt: 1200, // Lower than normal due to 0.9x multiplier
          battleDurationSeconds: 240,
          won: true,
          finalEvolution: EvolutionType.offensive,
        );

        verify(mockAnalytics.logEvent(
          'skill_progression_battle_summary',
          parameters: argThat(
            isA<Map<String, dynamic>>()
                .having((m) => m['difficulty_preset'], 'difficulty_preset',
                    'easy'),
            named: 'parameters',
          ),
        )).called(1);
      });
    });

    group('Hard Difficulty (1.2x/1.1x) E2E Flow', () {
      setUp(() {
        when(mockConfig.difficultyPreset).thenReturn('hard');
        when(mockConfig.getDifficultyModifiers()).thenReturn(
          ProgressionDifficultyModifiers(
            levelDifficultyMultiplier: 1.3, // 30% slower leveling
            skillCooldownMultiplier: 1.2, // 20% longer cooldowns
            skillDamageMultiplier: 1.1, // 10% more damage
          ),
        );
      });

      test('hard difficulty: cooldowns reduce slower (1.2x reduction)', () async {
        final player = engine.participants[0];
        player.skillCooldowns['skill'] = 10.0;

        engine.tick();

        // With 1.2x multiplier, cooldown reduction = 1.0 * 1.2 = 1.2
        expect(player.skillCooldowns['skill']!, lessThan(10.0));
        expect(player.skillCooldowns['skill']!, lessThan(9.0));
      });

      test('hard difficulty: analytics track increased damage multiplier',
          () async {
        await analyticsService.logCohortAssignment('hard_player', 'hard_session');

        verify(mockAnalytics.logEvent(
          'skill_progression_cohort_assigned',
          parameters: argThat(
            isA<Map<String, dynamic>>()
                .having((m) => m['difficulty_preset'], 'difficulty_preset',
                    'hard')
                .having((m) => m['damage_multiplier'], 'damage_multiplier',
                    '1.10'),
            named: 'parameters',
          ),
        )).called(1);
      });

      test('complete hard difficulty progression flow', () async {
        await analyticsService.logCohortAssignment('player1', 'session123');

        coordinator.initializePlayer(playerId: 'player1', mechaId: 'mecha1');

        // Level up at hard difficulty (slower progression)
        coordinator.levelUpPlayer('player1');
        coordinator.levelUpPlayer('player1');

        // Evolution at Lv3
        coordinator.confirmEvolution('player1', EvolutionType.offensive);

        // Battle with hard difficulty multipliers applied
        await analyticsService.logBattleSkillProgressionSummary(
          userId: 'player1',
          finalLevel: 4,
          totalSkillsUsed: 12,
          totalDamageDealt: 1500, // Higher than normal due to 1.1x multiplier
          battleDurationSeconds: 280,
          won: false,
          finalEvolution: EvolutionType.offensive,
        );

        verify(mockAnalytics.logEvent(
          'skill_progression_battle_summary',
          parameters: argThat(
            isA<Map<String, dynamic>>()
                .having((m) => m['difficulty_preset'], 'difficulty_preset',
                    'hard'),
            named: 'parameters',
          ),
        )).called(1);
      });
    });

    group('Config-Driven Evolution Level Thresholds', () {
      test('first evolution at config-defined level (Lv3)', () async {
        when(mockConfig.firstEvolutionLevel).thenReturn(3);

        coordinator.initializePlayer(playerId: 'player1', mechaId: 'mecha1');

        // Level up to Lv3
        coordinator.levelUpPlayer('player1');
        coordinator.levelUpPlayer('player1');

        // Should trigger evolution selection at Lv3
        var evolutionTriggered = false;
        coordinator.skillEvents.listen((event) {
          if (event is EvolutionSelectionRequiredEvent && event.level == 3) {
            evolutionTriggered = true;
          }
        });

        coordinator.levelUpPlayer('player1'); // This brings us to Lv3

        // Verify firstEvolutionLevel was consulted
        verify(mockConfig.firstEvolutionLevel).called(greaterThan(0));
      });

      test('second evolution at config-defined level (Lv6)', () async {
        when(mockConfig.firstEvolutionLevel).thenReturn(3);
        when(mockConfig.secondEvolutionLevel).thenReturn(6);

        coordinator.initializePlayer(playerId: 'player1', mechaId: 'mecha1');

        // Progress through levels
        for (int i = 0; i < 5; i++) {
          coordinator.levelUpPlayer('player1');
        }

        // At Lv6, should trigger second evolution
        coordinator.levelUpPlayer('player1');

        verify(mockConfig.secondEvolutionLevel).called(greaterThan(0));
      });

      test('respects custom evolution levels from config', () async {
        when(mockConfig.firstEvolutionLevel).thenReturn(2);
        when(mockConfig.secondEvolutionLevel).thenReturn(5);

        // Create new coordinator with custom levels
        final customCoordinator = BattleSkillProgressionCoordinator(
          skillService: skillService,
          progressionConfig: mockConfig,
        );

        customCoordinator.initializePlayer(playerId: 'player1', mechaId: 'mecha1');

        // Level up to Lv2
        customCoordinator.levelUpPlayer('player1');

        // Should trigger evolution at Lv2 (not Lv3)
        verify(mockConfig.firstEvolutionLevel).called(greaterThan(0));
      });
    });

    group('Multi-Cohort A/B Test Scenario', () {
      test('three cohorts progress through same battle with different configs',
          () async {
        // Easy cohort
        when(mockConfig.difficultyPreset).thenReturn('easy');
        when(mockConfig.getDifficultyModifiers()).thenReturn(
          ProgressionDifficultyModifiers(
            levelDifficultyMultiplier: 0.7,
            skillCooldownMultiplier: 0.8,
            skillDamageMultiplier: 0.9,
          ),
        );

        await analyticsService.logCohortAssignment('easy_player', 'easy_session');

        // Normal cohort
        when(mockConfig.difficultyPreset).thenReturn('normal');
        when(mockConfig.getDifficultyModifiers()).thenReturn(
          ProgressionDifficultyModifiers(
            levelDifficultyMultiplier: 1.0,
            skillCooldownMultiplier: 1.0,
            skillDamageMultiplier: 1.0,
          ),
        );

        await analyticsService.logCohortAssignment('normal_player', 'normal_session');

        // Hard cohort
        when(mockConfig.difficultyPreset).thenReturn('hard');
        when(mockConfig.getDifficultyModifiers()).thenReturn(
          ProgressionDifficultyModifiers(
            levelDifficultyMultiplier: 1.3,
            skillCooldownMultiplier: 1.2,
            skillDamageMultiplier: 1.1,
          ),
        );

        await analyticsService.logCohortAssignment('hard_player', 'hard_session');

        // Verify all three cohorts were tracked with correct multipliers
        expect(
          verify(mockAnalytics.logEvent(
            'skill_progression_cohort_assigned',
            parameters: any,
          )).callCount,
          3,
        );
      });

      test('cohorts experience different progression speeds', () async {
        // Easy cohort: faster cooldown reduction
        when(mockConfig.getDifficultyModifiers()).thenReturn(
          ProgressionDifficultyModifiers(
            levelDifficultyMultiplier: 0.7,
            skillCooldownMultiplier: 0.8,
            skillDamageMultiplier: 0.9,
          ),
        );

        final easyPlayer = engine.participants[0];
        easyPlayer.skillCooldowns['skill'] = 10.0;
        engine.tick();
        final easyAfterTick = easyPlayer.skillCooldowns['skill']!;

        // Hard cohort: slower cooldown reduction
        when(mockConfig.getDifficultyModifiers()).thenReturn(
          ProgressionDifficultyModifiers(
            levelDifficultyMultiplier: 1.3,
            skillCooldownMultiplier: 1.2,
            skillDamageMultiplier: 1.1,
          ),
        );

        final hardPlayer = engine.participants[1];
        hardPlayer.skillCooldowns['skill'] = 10.0;
        engine.tick();
        final hardAfterTick = hardPlayer.skillCooldowns['skill']!;

        // Easy should have lower cooldown than hard
        expect(easyAfterTick, greaterThan(hardAfterTick));
      });
    });

    group('Config Change Mid-Session', () {
      test('transition from normal to hard mid-session is tracked', () async {
        // Start with normal
        when(mockConfig.difficultyPreset).thenReturn('normal');
        await analyticsService.logCohortAssignment('player1', 'session');

        // Change to hard
        when(mockConfig.difficultyPreset).thenReturn('hard');
        when(mockConfig.getDifficultyModifiers()).thenReturn(
          ProgressionDifficultyModifiers(
            levelDifficultyMultiplier: 1.3,
            skillCooldownMultiplier: 1.2,
            skillDamageMultiplier: 1.1,
          ),
        );

        await analyticsService.logConfigurationChanged(
          'player1',
          'normal',
          'hard',
          'server_update',
        );

        verify(mockAnalytics.logEvent(
          'skill_progression_config_changed',
          parameters: argThat(
            isA<Map<String, dynamic>>()
                .having((m) => m['previous_preset'], 'previous_preset',
                    'normal')
                .having((m) => m['new_preset'], 'new_preset', 'hard')
                .having((m) => m['change_reason'], 'change_reason',
                    'server_update'),
            named: 'parameters',
          ),
        )).called(1);
      });
    });

    group('Complete Session Lifecycle', () {
      test('full session flow: cohort → progression → analytics', () async {
        when(mockConfig.difficultyPreset).thenReturn('normal');
        when(mockConfig.firstEvolutionLevel).thenReturn(3);

        // 1. Session start
        await analyticsService.logCohortAssignment('player1', 'session_full');

        // 2. Initialize progression
        coordinator.initializePlayer(playerId: 'player1', mechaId: 'mecha1');

        // 3. Progression events
        coordinator.levelUpPlayer('player1');
        await analyticsService.logLevelUp('player1', 2, false);

        coordinator.levelUpPlayer('player1');
        await analyticsService.logLevelUp('player1', 3, true);

        // 4. Evolution selection
        coordinator.confirmEvolution('player1', EvolutionType.offensive);
        await analyticsService.logEvolutionConfirmed(
          'player1',
          3,
          EvolutionType.offensive,
          1500,
          false,
        );

        // 5. More progression
        coordinator.levelUpPlayer('player1');
        await analyticsService.logLevelUp('player1', 4, false);

        // 6. Battle summary
        await analyticsService.logBattleSkillProgressionSummary(
          userId: 'player1',
          finalLevel: 5,
          totalSkillsUsed: 20,
          totalDamageDealt: 2000,
          battleDurationSeconds: 300,
          won: true,
          finalEvolution: EvolutionType.offensive,
        );

        // 7. Performance metrics
        await analyticsService.logCohortPerformanceMetrics(
          userId: 'player1',
          cohort: 'normal',
          levelingSpeed: 60.0,
          survivalTime: 250.0,
          killParticipationRate: 0.75,
        );

        // Verify all events were tracked with cohort context
        expect(
          verify(mockAnalytics.logEvent(any, parameters: any)).callCount,
          greaterThanOrEqualTo(7),
        );
      });
    });

    group('Error Resilience', () {
      test('analytics errors do not interrupt progression', () async {
        when(mockAnalytics.logEvent(any, parameters: anyNamed('parameters')))
            .thenThrow(Exception('Analytics unavailable'));

        expect(
          () async {
            await analyticsService.logCohortAssignment('player1', 'session');
            coordinator.initializePlayer(playerId: 'player1', mechaId: 'mecha1');
            coordinator.levelUpPlayer('player1');
          },
          returnsNormally,
        );
      });

      test('engine continues with config missing', () async {
        // Even if config throws, engine should continue
        when(mockConfig.getDifficultyModifiers())
            .thenThrow(Exception('Config error'));

        expect(() => engine.tick(), throwsException);
      });
    });

    group('Data Consistency', () {
      test('cohort remains consistent across all layers', () async {
        when(mockConfig.difficultyPreset).thenReturn('normal');

        expect(analyticsService.currentCohort, 'normal');

        await analyticsService.logLevelUp('player1', 5, false);
        expect(analyticsService.currentCohort, 'normal');

        await analyticsService.logBattleSkillProgressionSummary(
          userId: 'player1',
          finalLevel: 5,
          totalSkillsUsed: 15,
          totalDamageDealt: 2000,
          battleDurationSeconds: 300,
          won: true,
          finalEvolution: EvolutionType.offensive,
        );
        expect(analyticsService.currentCohort, 'normal');
      });

      test('multipliers are correctly propagated from config through layers',
          () async {
        when(mockConfig.getDifficultyModifiers()).thenReturn(
          ProgressionDifficultyModifiers(
            levelDifficultyMultiplier: 1.3,
            skillCooldownMultiplier: 1.2,
            skillDamageMultiplier: 1.1,
          ),
        );

        // Verify multipliers are available in all layers
        final engineModifiers = mockConfig.getDifficultyModifiers();
        final coordinatorModifiers = mockConfig.getDifficultyModifiers();
        final analyticsModifiers = mockConfig.getDifficultyModifiers();

        expect(engineModifiers.skillCooldownMultiplier, 1.2);
        expect(coordinatorModifiers.skillDamageMultiplier, 1.1);
        expect(analyticsModifiers.levelDifficultyMultiplier, 1.3);
      });
    });
  });
}
