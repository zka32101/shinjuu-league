import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shinjuu_league/data/models/evolution_model.dart';
import 'package:shinjuu_league/data/models/skill_catalog.dart';
import 'package:shinjuu_league/services/analytics_service.dart';
import 'package:shinjuu_league/services/skill_progression_analytics_service.dart';

// Mock AnalyticsService
class MockAnalyticsService extends Mock implements AnalyticsService {}

void main() {
  group('SkillProgressionAnalyticsService', () {
    late SkillProgressionAnalyticsService analyticsService;
    late MockAnalyticsService mockAnalytics;

    setUp(() {
      mockAnalytics = MockAnalyticsService();
      analyticsService = SkillProgressionAnalyticsService(
        analyticsService: mockAnalytics,
      );
    });

    group('logLevelUp', () {
      test('logs level up event with correct parameters', () async {
        await analyticsService.logLevelUp(
          'player1',
          5,
          false,
        );

        verify(mockAnalytics.logEvent(
          'skill_progression_level_up',
          parameters: argThat(
            isA<Map<String, Object>>()
                .having((m) => m['user_id'], 'user_id', 'player1')
                .having((m) => m['new_level'], 'new_level', 5)
                .having((m) => m['is_evolution_required'], 'is_evolution_required',
                    false),
            named: 'parameters',
          ),
        )).called(1);
      });

      test('handles evolution required flag', () async {
        await analyticsService.logLevelUp(
          'player1',
          3,
          true,
        );

        verify(mockAnalytics.logEvent(
          'skill_progression_level_up',
          parameters: argThat(
            isA<Map<String, Object>>()
                .having((m) => m['is_evolution_required'], 'is_evolution_required',
                    true),
            named: 'parameters',
          ),
        )).called(1);
      });

      test('includes timestamp', () async {
        await analyticsService.logLevelUp('player1', 2, false);

        verify(mockAnalytics.logEvent(
          'skill_progression_level_up',
          parameters: argThat(
            isA<Map<String, Object>>()
                .having((m) => m.containsKey('timestamp'), 'has timestamp', true),
            named: 'parameters',
          ),
        )).called(1);
      });

      test('silently handles exceptions', () async {
        when(mockAnalytics.logEvent(any, parameters: anyNamed('parameters')))
            .thenThrow(Exception('Test exception'));

        // Should not throw
        await analyticsService.logLevelUp('player1', 3, false);
      });
    });

    group('logEvolutionConfirmed', () {
      test('logs evolution confirmed event with correct parameters', () async {
        await analyticsService.logEvolutionConfirmed(
          'player1',
          3,
          EvolutionType.offensive,
          5000,
          false,
        );

        verify(mockAnalytics.logEvent(
          'skill_progression_evolution_confirmed',
          parameters: argThat(
            isA<Map<String, Object>>()
                .having((m) => m['user_id'], 'user_id', 'player1')
                .having((m) => m['level'], 'level', 3)
                .having((m) => m['selection_time_ms'], 'selection_time_ms',
                    5000)
                .having((m) => m['is_auto_selected'], 'is_auto_selected',
                    false),
            named: 'parameters',
          ),
        )).called(1);
      });

      test('differentiates first evolution at level 3', () async {
        await analyticsService.logEvolutionConfirmed(
          'player1',
          3,
          EvolutionType.offensive,
          2000,
          false,
        );

        verify(mockAnalytics.logEvent(
          'skill_progression_evolution_confirmed',
          parameters: argThat(
            isA<Map<String, Object>>()
                .having((m) => m['selection_type'], 'selection_type',
                    'first_evolution'),
            named: 'parameters',
          ),
        )).called(1);
      });

      test('differentiates second evolution at level 6', () async {
        await analyticsService.logEvolutionConfirmed(
          'player1',
          6,
          EvolutionType.defensive,
          3000,
          false,
        );

        verify(mockAnalytics.logEvent(
          'skill_progression_evolution_confirmed',
          parameters: argThat(
            isA<Map<String, Object>>()
                .having((m) => m['selection_type'], 'selection_type',
                    'second_evolution'),
            named: 'parameters',
          ),
        )).called(1);
      });

      test('tracks auto-selected evolution', () async {
        await analyticsService.logEvolutionConfirmed(
          'player1',
          3,
          EvolutionType.offensive,
          10000,
          true,
        );

        verify(mockAnalytics.logEvent(
          'skill_progression_evolution_confirmed',
          parameters: argThat(
            isA<Map<String, Object>>()
                .having((m) => m['is_auto_selected'], 'is_auto_selected', true),
            named: 'parameters',
          ),
        )).called(1);
      });

      test('includes evolution choice as string', () async {
        await analyticsService.logEvolutionConfirmed(
          'player1',
          3,
          EvolutionType.support,
          2500,
          false,
        );

        verify(mockAnalytics.logEvent(
          'skill_progression_evolution_confirmed',
          parameters: argThat(
            isA<Map<String, Object>>()
                .having((m) => m['evolution_choice'], 'evolution_choice',
                    'support'),
            named: 'parameters',
          ),
        )).called(1);
      });
    });

    group('logEvolutionSwitched', () {
      test('logs evolution switched event with correct parameters', () async {
        await analyticsService.logEvolutionSwitched(
          'player1',
          EvolutionType.offensive,
          EvolutionType.defensive,
          2,
        );

        verify(mockAnalytics.logEvent(
          'skill_progression_evolution_switched',
          parameters: argThat(
            isA<Map<String, Object>>()
                .having((m) => m['user_id'], 'user_id', 'player1')
                .having((m) => m['previous_evolution'], 'previous_evolution',
                    'offensive')
                .having((m) => m['new_evolution'], 'new_evolution', 'defensive')
                .having((m) => m['switch_count'], 'switch_count', 2),
            named: 'parameters',
          ),
        )).called(1);
      });

      test('tracks switch count progression', () async {
        await analyticsService.logEvolutionSwitched(
          'player1',
          EvolutionType.defensive,
          EvolutionType.support,
          5,
        );

        verify(mockAnalytics.logEvent(
          'skill_progression_evolution_switched',
          parameters: argThat(
            isA<Map<String, Object>>()
                .having((m) => m['switch_count'], 'switch_count', 5),
            named: 'parameters',
          ),
        )).called(1);
      });
    });

    group('logSkillUsed', () {
      test('logs skill used event with correct parameters', () async {
        await analyticsService.logSkillUsed(
          'player1',
          SkillSlot.q,
          5,
          250,
          true,
          false,
        );

        verify(mockAnalytics.logEvent(
          'skill_progression_skill_used',
          parameters: argThat(
            isA<Map<String, Object>>()
                .having((m) => m['user_id'], 'user_id', 'player1')
                .having((m) => m['skill_slot'], 'skill_slot', 'q')
                .having((m) => m['current_level'], 'current_level', 5)
                .having((m) => m['damage_dealt'], 'damage_dealt', 250)
                .having((m) => m['has_evolution_bonus'], 'has_evolution_bonus',
                    true)
                .having((m) => m['is_critical'], 'is_critical', false),
            named: 'parameters',
          ),
        )).called(1);
      });

      test('tracks critical hits', () async {
        await analyticsService.logSkillUsed(
          'player1',
          SkillSlot.r,
          3,
          180,
          false,
          true,
        );

        verify(mockAnalytics.logEvent(
          'skill_progression_skill_used',
          parameters: argThat(
            isA<Map<String, Object>>()
                .having((m) => m['is_critical'], 'is_critical', true),
            named: 'parameters',
          ),
        )).called(1);
      });

      test('tracks all skill slots', () async {
        for (final slot in [SkillSlot.q, SkillSlot.r, SkillSlot.e, SkillSlot.ult]) {
          await analyticsService.logSkillUsed(
            'player1',
            slot,
            4,
            200,
            false,
            false,
          );
        }

        expect(verify(mockAnalytics.logEvent(any, parameters: anyNamed('parameters'))).callCount, 4);
      });

      test('tracks evolution bonus presence', () async {
        await analyticsService.logSkillUsed(
          'player1',
          SkillSlot.e,
          6,
          150,
          true,
          false,
        );

        verify(mockAnalytics.logEvent(
          'skill_progression_skill_used',
          parameters: argThat(
            isA<Map<String, Object>>()
                .having((m) => m['has_evolution_bonus'], 'has_evolution_bonus',
                    true),
            named: 'parameters',
          ),
        )).called(1);
      });
    });

    group('logUltUnlocked', () {
      test('logs ULT unlocked event', () async {
        await analyticsService.logUltUnlocked('player1');

        verify(mockAnalytics.logEvent(
          'skill_progression_ult_unlocked',
          parameters: argThat(
            isA<Map<String, Object>>()
                .having((m) => m['user_id'], 'user_id', 'player1')
                .having((m) => m['level'], 'level', 7),
            named: 'parameters',
          ),
        )).called(1);
      });

      test('includes timestamp', () async {
        await analyticsService.logUltUnlocked('player1');

        verify(mockAnalytics.logEvent(
          'skill_progression_ult_unlocked',
          parameters: argThat(
            isA<Map<String, Object>>()
                .having((m) => m.containsKey('timestamp'), 'has timestamp', true),
            named: 'parameters',
          ),
        )).called(1);
      });
    });

    group('logUltActivated', () {
      test('logs ULT activated event with correct parameters', () async {
        await analyticsService.logUltActivated(
          'player1',
          500,
          3,
        );

        verify(mockAnalytics.logEvent(
          'skill_progression_ult_activated',
          parameters: argThat(
            isA<Map<String, Object>>()
                .having((m) => m['user_id'], 'user_id', 'player1')
                .having((m) => m['damage_dealt'], 'damage_dealt', 500)
                .having((m) => m['targets_hit'], 'targets_hit', 3),
            named: 'parameters',
          ),
        )).called(1);
      });

      test('tracks multiple targets hit', () async {
        await analyticsService.logUltActivated('player1', 600, 5);

        verify(mockAnalytics.logEvent(
          'skill_progression_ult_activated',
          parameters: argThat(
            isA<Map<String, Object>>()
                .having((m) => m['targets_hit'], 'targets_hit', 5),
            named: 'parameters',
          ),
        )).called(1);
      });
    });

    group('logMaxLevelReached', () {
      test('logs max level reached event with correct parameters', () async {
        await analyticsService.logMaxLevelReached(
          'player1',
          300,
          EvolutionType.offensive,
          5,
        );

        verify(mockAnalytics.logEvent(
          'skill_progression_max_level_reached',
          parameters: argThat(
            isA<Map<String, Object>>()
                .having((m) => m['user_id'], 'user_id', 'player1')
                .having((m) => m['level'], 'level', 8)
                .having((m) => m['time_to_max_level_seconds'], 'time_to_max_level_seconds',
                    300)
                .having((m) => m['total_kills'], 'total_kills', 5),
            named: 'parameters',
          ),
        )).called(1);
      });

      test('records final evolution type', () async {
        await analyticsService.logMaxLevelReached(
          'player1',
          250,
          EvolutionType.support,
          3,
        );

        verify(mockAnalytics.logEvent(
          'skill_progression_max_level_reached',
          parameters: argThat(
            isA<Map<String, Object>>()
                .having((m) => m['final_evolution'], 'final_evolution', 'support'),
            named: 'parameters',
          ),
        )).called(1);
      });
    });

    group('logBattleSkillProgressionSummary', () {
      test('logs complete battle summary with correct parameters', () async {
        await analyticsService.logBattleSkillProgressionSummary(
          userId: 'player1',
          finalLevel: 6,
          totalSkillsUsed: 25,
          totalDamageDealt: 2500,
          battleDurationSeconds: 300,
          won: true,
          finalEvolution: EvolutionType.offensive,
        );

        verify(mockAnalytics.logEvent(
          'skill_progression_battle_summary',
          parameters: argThat(
            isA<Map<String, Object>>()
                .having((m) => m['user_id'], 'user_id', 'player1')
                .having((m) => m['final_level'], 'final_level', 6)
                .having((m) => m['total_skills_used'], 'total_skills_used', 25)
                .having((m) => m['total_damage_dealt'], 'total_damage_dealt', 2500)
                .having((m) => m['battle_duration_seconds'], 'battle_duration_seconds',
                    300)
                .having((m) => m['won'], 'won', true)
                .having((m) => m['final_evolution'], 'final_evolution', 'offensive'),
            named: 'parameters',
          ),
        )).called(1);
      });

      test('calculates skills per minute', () async {
        await analyticsService.logBattleSkillProgressionSummary(
          userId: 'player1',
          finalLevel: 5,
          totalSkillsUsed: 30,
          totalDamageDealt: 2000,
          battleDurationSeconds: 120,
          won: false,
          finalEvolution: EvolutionType.defensive,
        );

        verify(mockAnalytics.logEvent(
          'skill_progression_battle_summary',
          parameters: argThat(
            isA<Map<String, Object>>()
                .having((m) => m['skills_per_minute'], 'skills_per_minute', '15.00'),
            named: 'parameters',
          ),
        )).called(1);
      });

      test('handles null final evolution', () async {
        await analyticsService.logBattleSkillProgressionSummary(
          userId: 'player1',
          finalLevel: 2,
          totalSkillsUsed: 5,
          totalDamageDealt: 300,
          battleDurationSeconds: 60,
          won: false,
          finalEvolution: null,
        );

        verify(mockAnalytics.logEvent(
          'skill_progression_battle_summary',
          parameters: argThat(
            isA<Map<String, Object>>()
                .having((m) => m['final_evolution'], 'final_evolution', null),
            named: 'parameters',
          ),
        )).called(1);
      });

      test('tracks both wins and losses', () async {
        await analyticsService.logBattleSkillProgressionSummary(
          userId: 'player1',
          finalLevel: 4,
          totalSkillsUsed: 15,
          totalDamageDealt: 1500,
          battleDurationSeconds: 200,
          won: false,
          finalEvolution: EvolutionType.support,
        );

        verify(mockAnalytics.logEvent(
          'skill_progression_battle_summary',
          parameters: argThat(
            isA<Map<String, Object>>()
                .having((m) => m['won'], 'won', false),
            named: 'parameters',
          ),
        )).called(1);
      });
    });

    group('logEvolutionBonusEffectiveness', () {
      test('logs evolution bonus effectiveness with correct parameters', () async {
        await analyticsService.logEvolutionBonusEffectiveness(
          'player1',
          EvolutionType.offensive,
          0.60,
          65.5,
        );

        verify(mockAnalytics.logEvent(
          'skill_progression_evolution_bonus_effectiveness',
          parameters: argThat(
            isA<Map<String, Object>>()
                .having((m) => m['user_id'], 'user_id', 'player1')
                .having((m) => m['evolution_type'], 'evolution_type', 'offensive')
                .having((m) => m['bonus_percentage'], 'bonus_percentage', '60.0')
                .having((m) => m['damage_increase_percent'], 'damage_increase_percent',
                    '65.5'),
            named: 'parameters',
          ),
        )).called(1);
      });

      test('calculates bonus efficiency ratio', () async {
        await analyticsService.logEvolutionBonusEffectiveness(
          'player1',
          EvolutionType.defensive,
          0.40,
          44.0,
        );

        verify(mockAnalytics.logEvent(
          'skill_progression_evolution_bonus_effectiveness',
          parameters: argThat(
            isA<Map<String, Object>>()
                .having((m) => m['bonus_efficiency'], 'bonus_efficiency', '2.75'),
            named: 'parameters',
          ),
        )).called(1);
      });

      test('tracks all evolution types', () async {
        for (final type in [EvolutionType.offensive, EvolutionType.defensive, EvolutionType.support]) {
          await analyticsService.logEvolutionBonusEffectiveness(
            'player1',
            type,
            0.50,
            50.0,
          );
        }

        expect(verify(mockAnalytics.logEvent(any, parameters: anyNamed('parameters'))).callCount, 3);
      });
    });

    group('logSkillUsagePattern', () {
      test('logs skill usage pattern with correct parameters', () async {
        await analyticsService.logSkillUsagePattern(
          'player1',
          {
            SkillSlot.q: 10,
            SkillSlot.r: 8,
            SkillSlot.e: 7,
            SkillSlot.ult: 2,
          },
          {
            SkillSlot.q: 2000,
            SkillSlot.r: 1800,
            SkillSlot.e: 1400,
            SkillSlot.ult: 600,
          },
        );

        verify(mockAnalytics.logEvent(
          'skill_progression_usage_pattern',
          parameters: argThat(
            isA<Map<String, Object>>()
                .having((m) => m['user_id'], 'user_id', 'player1')
                .having((m) => m['q_usage_count'], 'q_usage_count', 10)
                .having((m) => m['r_usage_count'], 'r_usage_count', 8)
                .having((m) => m['e_usage_count'], 'e_usage_count', 7)
                .having((m) => m['ult_usage_count'], 'ult_usage_count', 2),
            named: 'parameters',
          ),
        )).called(1);
      });

      test('handles missing slots with zero defaults', () async {
        await analyticsService.logSkillUsagePattern(
          'player1',
          {SkillSlot.q: 5},
          {SkillSlot.q: 1000},
        );

        verify(mockAnalytics.logEvent(
          'skill_progression_usage_pattern',
          parameters: argThat(
            isA<Map<String, Object>>()
                .having((m) => m['r_usage_count'], 'r_usage_count', 0)
                .having((m) => m['e_usage_count'], 'e_usage_count', 0)
                .having((m) => m['ult_usage_count'], 'ult_usage_count', 0),
            named: 'parameters',
          ),
        )).called(1);
      });

      test('calculates total skill uses', () async {
        await analyticsService.logSkillUsagePattern(
          'player1',
          {
            SkillSlot.q: 12,
            SkillSlot.r: 9,
            SkillSlot.e: 6,
            SkillSlot.ult: 3,
          },
          {},
        );

        verify(mockAnalytics.logEvent(
          'skill_progression_usage_pattern',
          parameters: argThat(
            isA<Map<String, Object>>()
                .having((m) => m['total_skill_uses'], 'total_skill_uses', '30'),
            named: 'parameters',
          ),
        )).called(1);
      });
    });

    group('logEvolutionPreference', () {
      test('logs evolution preference with correct parameters', () async {
        await analyticsService.logEvolutionPreference(
          'player1',
          offensiveCount: 8,
          defensiveCount: 4,
          supportCount: 2,
          autoSelectCount: 1,
        );

        verify(mockAnalytics.logEvent(
          'skill_progression_evolution_preference',
          parameters: argThat(
            isA<Map<String, Object>>()
                .having((m) => m['user_id'], 'user_id', 'player1')
                .having((m) => m['offensive_count'], 'offensive_count', 8)
                .having((m) => m['defensive_count'], 'defensive_count', 4)
                .having((m) => m['support_count'], 'support_count', 2)
                .having((m) => m['auto_select_count'], 'auto_select_count', 1),
            named: 'parameters',
          ),
        )).called(1);
      });

      test('calculates preference percentages', () async {
        await analyticsService.logEvolutionPreference(
          'player1',
          offensiveCount: 50,
          defensiveCount: 30,
          supportCount: 20,
          autoSelectCount: 0,
        );

        verify(mockAnalytics.logEvent(
          'skill_progression_evolution_preference',
          parameters: argThat(
            isA<Map<String, Object>>()
                .having((m) => m['offensive_percentage'], 'offensive_percentage',
                    '50.0')
                .having((m) => m['defensive_percentage'], 'defensive_percentage',
                    '30.0')
                .having((m) => m['support_percentage'], 'support_percentage', '20.0'),
            named: 'parameters',
          ),
        )).called(1);
      });

      test('identifies most preferred evolution', () async {
        await analyticsService.logEvolutionPreference(
          'player1',
          offensiveCount: 15,
          defensiveCount: 5,
          supportCount: 5,
          autoSelectCount: 0,
        );

        verify(mockAnalytics.logEvent(
          'skill_progression_evolution_preference',
          parameters: argThat(
            isA<Map<String, Object>>()
                .having((m) => m['most_preferred'], 'most_preferred', 'offensive'),
            named: 'parameters',
          ),
        )).called(1);
      });

      test('returns null when total count is zero', () async {
        // Should skip logging when total is 0
        await analyticsService.logEvolutionPreference(
          'player1',
          offensiveCount: 0,
          defensiveCount: 0,
          supportCount: 0,
          autoSelectCount: 0,
        );

        verifyNever(mockAnalytics.logEvent(any, parameters: anyNamed('parameters')));
      });

      test('handles tie between evolution types', () async {
        await analyticsService.logEvolutionPreference(
          'player1',
          offensiveCount: 10,
          defensiveCount: 10,
          supportCount: 10,
          autoSelectCount: 0,
        );

        verify(mockAnalytics.logEvent(
          'skill_progression_evolution_preference',
          parameters: argThat(
            isA<Map<String, Object>>()
                .having((m) => m.containsKey('most_preferred'), 'has most_preferred',
                    true),
            named: 'parameters',
          ),
        )).called(1);
      });
    });

    group('logSkillProgressionError', () {
      test('logs skill progression error with correct parameters', () async {
        await analyticsService.logSkillProgressionError(
          'player1',
          'invalid_evolution',
          'Player attempted evolution at level 5',
        );

        verify(mockAnalytics.recordError(
          any,
          any,
          reason: 'Skill progression error',
          information: argThat(
            contains('player1') &
            contains('invalid_evolution') &
            contains('Player attempted evolution at level 5'),
          ),
        )).called(1);
      });

      test('includes error type and detail', () async {
        await analyticsService.logSkillProgressionError(
          'player1',
          'duplicate_level_up',
          'Level up event triggered twice in same tick',
        );

        verify(mockAnalytics.recordError(
          any,
          any,
          reason: argThat(contains('Skill progression error')),
          information: argThat(
            contains('duplicate_level_up'),
          ),
        )).called(1);
      });

      test('silently handles exceptions', () async {
        when(mockAnalytics.recordError(
          any,
          any,
          reason: anyNamed('reason'),
          information: anyNamed('information'),
        )).thenThrow(Exception('Crashlytics error'));

        // Should not throw
        await analyticsService.logSkillProgressionError(
          'player1',
          'test_error',
          'Test detail',
        );
      });
    });

    group('Integration patterns', () {
      test('supports multiple players in sequence', () async {
        await analyticsService.logLevelUp('player1', 3, true);
        await analyticsService.logLevelUp('player2', 3, true);
        await analyticsService.logLevelUp('player1', 4, false);

        expect(
          verify(mockAnalytics.logEvent(any, parameters: anyNamed('parameters')))
              .callCount,
          3,
        );
      });

      test('handles rapid fire events without blocking', () async {
        final futures = <Future<void>>[];
        for (int i = 0; i < 10; i++) {
          futures.add(
            analyticsService.logSkillUsed(
              'player1',
              SkillSlot.q,
              i + 1,
              100 * (i + 1),
              false,
              false,
            ),
          );
        }

        await Future.wait(futures);

        expect(
          verify(mockAnalytics.logEvent(any, parameters: anyNamed('parameters')))
              .callCount,
          10,
        );
      });

      test('all methods are async and await-able', () async {
        expect(
          analyticsService.logLevelUp('player1', 2, false),
          isA<Future<void>>(),
        );
        expect(
          analyticsService.logEvolutionConfirmed(
              'player1', 3, EvolutionType.offensive, 1000, false),
          isA<Future<void>>(),
        );
        expect(
          analyticsService.logSkillUsed(
              'player1', SkillSlot.q, 2, 100, false, false),
          isA<Future<void>>(),
        );
      });
    });
  });
}
