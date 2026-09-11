import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shinjuu_league/config/skill_progression_config.dart';
import 'package:shinjuu_league/data/models/evolution_model.dart';
import 'package:shinjuu_league/data/models/skill_catalog.dart';
import 'package:shinjuu_league/services/analytics_service.dart';
import 'package:shinjuu_league/services/skill_progression_analytics_service.dart';

class MockAnalyticsService extends Mock implements AnalyticsService {}

class MockSkillProgressionConfig extends Mock
    implements SkillProgressionConfig {}

void main() {
  group('SkillProgressionAnalyticsService with Cohort Tracking', () {
    late MockAnalyticsService mockAnalytics;
    late MockSkillProgressionConfig mockConfig;
    late SkillProgressionAnalyticsService analyticsService;

    setUp(() {
      mockAnalytics = MockAnalyticsService();
      mockConfig = MockSkillProgressionConfig();

      // Default mock behavior: normal difficulty
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

      analyticsService = SkillProgressionAnalyticsService(
        analyticsService: mockAnalytics,
        progressionConfig: mockConfig,
      );
    });

    group('Cohort Initialization', () {
      test('currentCohort reflects difficulty preset on initialization', () {
        when(mockConfig.difficultyPreset).thenReturn('normal');

        final service = SkillProgressionAnalyticsService(
          analyticsService: mockAnalytics,
          progressionConfig: mockConfig,
        );

        expect(service.currentCohort, 'normal');
      });

      test('uses default SkillProgressionConfig when not provided', () {
        final service = SkillProgressionAnalyticsService(
          analyticsService: mockAnalytics,
        );

        expect(service, isNotNull);
      });
    });

    group('Cohort Assignment Tracking', () {
      test('logCohortAssignment records preset and multipliers', () async {
        when(mockConfig.difficultyPreset).thenReturn('easy');
        when(mockConfig.getDifficultyModifiers()).thenReturn(
          ProgressionDifficultyModifiers(
            levelDifficultyMultiplier: 0.7,
            skillCooldownMultiplier: 0.8,
            skillDamageMultiplier: 0.9,
          ),
        );

        analyticsService = SkillProgressionAnalyticsService(
          analyticsService: mockAnalytics,
          progressionConfig: mockConfig,
        );

        await analyticsService.logCohortAssignment('user123', 'session456');

        verify(mockAnalytics.logEvent(
          'skill_progression_cohort_assigned',
          parameters: argThat(
            isA<Map<String, dynamic>>()
                .having((m) => m['user_id'], 'user_id', 'user123')
                .having((m) => m['session_id'], 'session_id', 'session456')
                .having((m) => m['difficulty_preset'], 'difficulty_preset',
                    'easy')
                .having((m) => m['cooldown_multiplier'], 'cooldown_multiplier',
                    '0.80')
                .having((m) => m['damage_multiplier'], 'damage_multiplier',
                    '0.90'),
            named: 'parameters',
          ),
        )).called(1);
      });

      test('normal difficulty preset tracked correctly', () async {
        when(mockConfig.difficultyPreset).thenReturn('normal');
        when(mockConfig.getDifficultyModifiers()).thenReturn(
          ProgressionDifficultyModifiers(
            levelDifficultyMultiplier: 1.0,
            skillCooldownMultiplier: 1.0,
            skillDamageMultiplier: 1.0,
          ),
        );

        await analyticsService.logCohortAssignment('player1', 'session1');

        verify(mockAnalytics.logEvent(
          'skill_progression_cohort_assigned',
          parameters: argThat(
            isA<Map<String, dynamic>>()
                .having((m) => m['difficulty_preset'], 'difficulty_preset',
                    'normal'),
            named: 'parameters',
          ),
        )).called(1);
      });

      test('hard difficulty preset tracked correctly', () async {
        when(mockConfig.difficultyPreset).thenReturn('hard');
        when(mockConfig.getDifficultyModifiers()).thenReturn(
          ProgressionDifficultyModifiers(
            levelDifficultyMultiplier: 1.3,
            skillCooldownMultiplier: 1.2,
            skillDamageMultiplier: 1.1,
          ),
        );

        analyticsService = SkillProgressionAnalyticsService(
          analyticsService: mockAnalytics,
          progressionConfig: mockConfig,
        );

        await analyticsService.logCohortAssignment('player2', 'session2');

        verify(mockAnalytics.logEvent(
          'skill_progression_cohort_assigned',
          parameters: argThat(
            isA<Map<String, dynamic>>()
                .having((m) => m['difficulty_preset'], 'difficulty_preset',
                    'hard')
                .having((m) => m['cooldown_multiplier'], 'cooldown_multiplier',
                    '1.20')
                .having((m) => m['damage_multiplier'], 'damage_multiplier',
                    '1.10'),
            named: 'parameters',
          ),
        )).called(1);
      });
    });

    group('Configuration Change Tracking', () {
      test('logConfigurationChanged records preset transition', () async {
        await analyticsService.logConfigurationChanged(
          'player1',
          'normal',
          'hard',
          'config_refresh',
        );

        verify(mockAnalytics.logEvent(
          'skill_progression_config_changed',
          parameters: argThat(
            isA<Map<String, dynamic>>()
                .having((m) => m['user_id'], 'user_id', 'player1')
                .having((m) => m['previous_preset'], 'previous_preset', 'normal')
                .having((m) => m['new_preset'], 'new_preset', 'hard')
                .having((m) => m['change_reason'], 'change_reason',
                    'config_refresh'),
            named: 'parameters',
          ),
        )).called(1);
      });

      test('updatesCohort when config changes', () async {
        when(mockConfig.difficultyPreset).thenReturn('easy');

        await analyticsService.logConfigurationChanged(
          'player1',
          'normal',
          'easy',
          'server_update',
        );

        expect(analyticsService.currentCohort, 'easy');
      });
    });

    group('Cohort Parameters in Events', () {
      test('logLevelUp includes difficulty_preset parameter', () async {
        when(mockConfig.difficultyPreset).thenReturn('hard');

        await analyticsService.logLevelUp('player1', 5, true);

        verify(mockAnalytics.logEvent(
          'skill_progression_level_up',
          parameters: argThat(
            isA<Map<String, dynamic>>()
                .having((m) => m['new_level'], 'new_level', 5)
                .having((m) => m['difficulty_preset'], 'difficulty_preset',
                    'hard'),
            named: 'parameters',
          ),
        )).called(1);
      });

      test('logEvolutionConfirmed includes difficulty_preset parameter',
          () async {
        when(mockConfig.difficultyPreset).thenReturn('easy');

        await analyticsService.logEvolutionConfirmed(
          'player1',
          3,
          EvolutionType.offensive,
          500,
          false,
        );

        verify(mockAnalytics.logEvent(
          'skill_progression_evolution_confirmed',
          parameters: argThat(
            isA<Map<String, dynamic>>()
                .having((m) => m['level'], 'level', 3)
                .having((m) => m['evolution_choice'], 'evolution_choice',
                    'offensive')
                .having((m) => m['difficulty_preset'], 'difficulty_preset',
                    'easy'),
            named: 'parameters',
          ),
        )).called(1);
      });

      test('logBattleSkillProgressionSummary includes difficulty_preset',
          () async {
        when(mockConfig.difficultyPreset).thenReturn('normal');

        await analyticsService.logBattleSkillProgressionSummary(
          userId: 'player1',
          finalLevel: 6,
          totalSkillsUsed: 15,
          totalDamageDealt: 1250,
          battleDurationSeconds: 300,
          won: true,
          finalEvolution: EvolutionType.offensive,
        );

        verify(mockAnalytics.logEvent(
          'skill_progression_battle_summary',
          parameters: argThat(
            isA<Map<String, dynamic>>()
                .having((m) => m['final_level'], 'final_level', 6)
                .having((m) => m['won'], 'won', true)
                .having((m) => m['difficulty_preset'], 'difficulty_preset',
                    'normal'),
            named: 'parameters',
          ),
        )).called(1);
      });

      test('logSkillUsagePattern includes difficulty_preset', () async {
        when(mockConfig.difficultyPreset).thenReturn('hard');

        await analyticsService.logSkillUsagePattern(
          'player1',
          {
            SkillSlot.q: 10,
            SkillSlot.r: 8,
            SkillSlot.e: 12,
            SkillSlot.ult: 2,
          },
          {
            SkillSlot.q: 150,
            SkillSlot.r: 120,
            SkillSlot.e: 180,
            SkillSlot.ult: 300,
          },
        );

        verify(mockAnalytics.logEvent(
          'skill_progression_usage_pattern',
          parameters: argThat(
            isA<Map<String, dynamic>>()
                .having((m) => m['q_usage_count'], 'q_usage_count', 10)
                .having((m) => m['difficulty_preset'], 'difficulty_preset',
                    'hard'),
            named: 'parameters',
          ),
        )).called(1);
      });
    });

    group('Cohort Performance Metrics', () {
      test('logCohortPerformanceMetrics records leveling speed and survival',
          () async {
        await analyticsService.logCohortPerformanceMetrics(
          userId: 'player1',
          cohort: 'easy',
          levelingSpeed: 30.5,
          survivalTime: 180.0,
          killParticipationRate: 0.65,
        );

        verify(mockAnalytics.logEvent(
          'skill_progression_cohort_performance',
          parameters: argThat(
            isA<Map<String, dynamic>>()
                .having((m) => m['user_id'], 'user_id', 'player1')
                .having((m) => m['cohort'], 'cohort', 'easy')
                .having((m) => m['leveling_speed_seconds_per_level'],
                    'leveling_speed_seconds_per_level', '30.50')
                .having((m) => m['survival_time_seconds'],
                    'survival_time_seconds', '180.00')
                .having((m) => m['kill_participation_rate'],
                    'kill_participation_rate', '65.0'),
            named: 'parameters',
          ),
        )).called(1);
      });

      test('tracks different cohort performance profiles', () async {
        // Easy cohort: faster leveling, higher survival
        await analyticsService.logCohortPerformanceMetrics(
          userId: 'easy_player',
          cohort: 'easy',
          levelingSpeed: 25.0,
          survivalTime: 200.0,
          killParticipationRate: 0.45,
        );

        // Hard cohort: slower leveling, lower survival
        await analyticsService.logCohortPerformanceMetrics(
          userId: 'hard_player',
          cohort: 'hard',
          levelingSpeed: 40.0,
          survivalTime: 140.0,
          killParticipationRate: 0.75,
        );

        expect(
          verify(mockAnalytics.logEvent(
            'skill_progression_cohort_performance',
            parameters: any,
          )).callCount,
          2,
        );
      });
    });

    group('Cohort Evolution Impact', () {
      test('logCohortEvolutionImpact records evolution effectiveness', () async {
        await analyticsService.logCohortEvolutionImpact(
          userId: 'player1',
          cohort: 'normal',
          evolutionChoice: EvolutionType.offensive,
          damageMultiplierApplied: 1.0,
          finalDamageOutput: 1500,
        );

        verify(mockAnalytics.logEvent(
          'skill_progression_cohort_evolution_impact',
          parameters: argThat(
            isA<Map<String, dynamic>>()
                .having((m) => m['cohort'], 'cohort', 'normal')
                .having((m) => m['evolution_choice'], 'evolution_choice',
                    'offensive')
                .having((m) => m['damage_multiplier_applied'],
                    'damage_multiplier_applied', '1.00')
                .having((m) => m['final_damage_output'], 'final_damage_output',
                    1500),
            named: 'parameters',
          ),
        )).called(1);
      });

      test('compares evolution impact across cohorts', () async {
        // Easy cohort: lower damage multiplier
        await analyticsService.logCohortEvolutionImpact(
          userId: 'easy_player',
          cohort: 'easy',
          evolutionChoice: EvolutionType.offensive,
          damageMultiplierApplied: 0.9,
          finalDamageOutput: 1350,
        );

        // Hard cohort: higher damage multiplier
        await analyticsService.logCohortEvolutionImpact(
          userId: 'hard_player',
          cohort: 'hard',
          evolutionChoice: EvolutionType.offensive,
          damageMultiplierApplied: 1.1,
          finalDamageOutput: 1650,
        );

        expect(
          verify(mockAnalytics.logEvent(
            'skill_progression_cohort_evolution_impact',
            parameters: any,
          )).callCount,
          2,
        );
      });
    });

    group('Error Handling', () {
      test('logCohortAssignment handles errors gracefully', () async {
        when(mockAnalytics.logEvent(any, parameters: anyNamed('parameters')))
            .thenThrow(Exception('Analytics error'));

        expect(
          () => analyticsService.logCohortAssignment('user1', 'session1'),
          returnsNormally,
        );
      });

      test('logConfigurationChanged handles errors gracefully', () async {
        when(mockAnalytics.logEvent(any, parameters: anyNamed('parameters')))
            .thenThrow(Exception('Analytics error'));

        expect(
          () => analyticsService.logConfigurationChanged(
            'user1',
            'normal',
            'easy',
            'test',
          ),
          returnsNormally,
        );
      });
    });

    group('Integration Scenarios', () {
      test('complete session flow with cohort tracking', () async {
        when(mockConfig.difficultyPreset).thenReturn('normal');

        // Session start
        await analyticsService.logCohortAssignment('player1', 'session1');

        // Level up
        await analyticsService.logLevelUp('player1', 3, true);

        // Evolution confirmed
        await analyticsService.logEvolutionConfirmed(
          'player1',
          3,
          EvolutionType.offensive,
          1000,
          false,
        );

        // Battle summary
        await analyticsService.logBattleSkillProgressionSummary(
          userId: 'player1',
          finalLevel: 5,
          totalSkillsUsed: 20,
          totalDamageDealt: 2000,
          battleDurationSeconds: 300,
          won: true,
          finalEvolution: EvolutionType.offensive,
        );

        expect(
          verify(mockAnalytics.logEvent(any, parameters: any))
              .callCount,
          greaterThanOrEqualTo(4),
        );
      });

      test('A/B test scenario: easy vs hard cohort comparison', () async {
        // Easy cohort player
        when(mockConfig.difficultyPreset).thenReturn('easy');
        final easyService = SkillProgressionAnalyticsService(
          analyticsService: mockAnalytics,
          progressionConfig: mockConfig,
        );

        await easyService.logCohortAssignment('easy_player', 'session_easy');

        // Hard cohort player
        when(mockConfig.difficultyPreset).thenReturn('hard');
        final hardService = SkillProgressionAnalyticsService(
          analyticsService: mockAnalytics,
          progressionConfig: mockConfig,
        );

        await hardService.logCohortAssignment('hard_player', 'session_hard');

        // Verify both cohorts were tracked
        final easyCall = verify(mockAnalytics.logEvent(
          'skill_progression_cohort_assigned',
          parameters: argThat(
            isA<Map<String, dynamic>>()
                .having((m) => m['difficulty_preset'], 'difficulty_preset',
                    'easy'),
            named: 'parameters',
          ),
        ));

        final hardCall = verify(mockAnalytics.logEvent(
          'skill_progression_cohort_assigned',
          parameters: argThat(
            isA<Map<String, dynamic>>()
                .having((m) => m['difficulty_preset'], 'difficulty_preset',
                    'hard'),
            named: 'parameters',
          ),
        ));

        expect(easyCall.callCount, 1);
        expect(hardCall.callCount, 1);
      });
    });

    group('Cohort Data Consistency', () {
      test('currentCohort remains stable across events', () async {
        when(mockConfig.difficultyPreset).thenReturn('normal');

        expect(analyticsService.currentCohort, 'normal');

        await analyticsService.logLevelUp('player1', 5, false);
        expect(analyticsService.currentCohort, 'normal');

        await analyticsService.logEvolutionConfirmed(
          'player1',
          3,
          EvolutionType.offensive,
          500,
          false,
        );
        expect(analyticsService.currentCohort, 'normal');
      });

      test('currentCohort updates when config changes', () async {
        when(mockConfig.difficultyPreset).thenReturn('normal');
        expect(analyticsService.currentCohort, 'normal');

        when(mockConfig.difficultyPreset).thenReturn('hard');
        await analyticsService.logConfigurationChanged(
          'player1',
          'normal',
          'hard',
          'test',
        );
        expect(analyticsService.currentCohort, 'hard');
      });
    });
  });
}
