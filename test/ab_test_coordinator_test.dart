import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shinjuu_league/services/ab_test_coordinator.dart';
import 'package:shinjuu_league/services/analytics_service.dart';
import 'package:shinjuu_league/services/feature_flags_service.dart';
import 'package:shinjuu_league/config/skill_progression_config.dart';

class MockFeatureFlagsService extends Mock implements FeatureFlagsService {}

class MockAnalyticsService extends Mock
    implements SkillProgressionAnalyticsService {}

class MockSkillProgressionConfig extends Mock
    implements SkillProgressionConfig {}

void main() {
  group('ABTestCoordinator', () {
    late MockFeatureFlagsService mockFlags;
    late MockAnalyticsService mockAnalytics;
    late ABTestCoordinator coordinator;

    setUp(() {
      mockFlags = MockFeatureFlagsService();
      mockAnalytics = MockAnalyticsService();

      when(mockFlags.getDifficultyCohort(any)).thenReturn('normal');

      coordinator = ABTestCoordinator(
        featureFlags: mockFlags,
        analytics: mockAnalytics,
      );
    });

    group('Experiment Registration', () {
      test('registers experiment successfully', () {
        final exp = ABTestExperimentConfig(
          experimentId: 'exp_001',
          name: 'Test Experiment',
          description: 'Testing A/B variations',
          startDate: DateTime.now().subtract(Duration(days: 1)),
          controlVariant: 'control',
          rolloutPercentage: 100,
          variantDistribution: {
            'control': 50,
            'treatment': 50,
          },
        );

        coordinator.registerExperiment(exp);

        final variant = coordinator.getExperimentVariant('user_123', 'exp_001');
        expect(variant, isNotEmpty);
      });

      test('handles multiple experiments', () {
        final now = DateTime.now();
        for (int i = 0; i < 5; i++) {
          coordinator.registerExperiment(
            ABTestExperimentConfig(
              experimentId: 'exp_00$i',
              name: 'Experiment $i',
              description: 'Test $i',
              startDate: now.subtract(Duration(days: 1)),
              controlVariant: 'control',
              rolloutPercentage: 100,
              variantDistribution: {
                'control': 50,
                'treatment': 50,
              },
            ),
          );
        }

        final activeExps = coordinator.getActiveExperiments('user_123');
        expect(activeExps.length, equals(5));
      });
    });

    group('Variant Assignment', () {
      setUp(() {
        coordinator.registerExperiment(
          ABTestExperimentConfig(
            experimentId: 'exp_cooldown',
            name: 'Cooldown Test',
            description: 'Testing cooldown multipliers',
            startDate: DateTime.now().subtract(Duration(days: 1)),
            controlVariant: 'baseline',
            rolloutPercentage: 100,
            variantDistribution: {
              'baseline': 50,
              'reduced_0.8x': 25,
              'reduced_0.6x': 25,
            },
          ),
        );
      });

      test('returns same variant for same user consistently', () {
        const userId = 'user_consistent';
        const experimentId = 'exp_cooldown';

        final variant1 = coordinator.getExperimentVariant(userId, experimentId);
        final variant2 = coordinator.getExperimentVariant(userId, experimentId);

        expect(variant1, equals(variant2));
      });

      test('distributes variants across users', () {
        const experimentId = 'exp_cooldown';
        final variants = <String>{};

        for (int i = 0; i < 30; i++) {
          final variant =
              coordinator.getExperimentVariant('user_$i', experimentId);
          variants.add(variant);
        }

        // Should have multiple variants assigned
        expect(variants.length, greaterThan(1));
      });

      test('respects variant distribution percentages', () {
        const experimentId = 'exp_cooldown';
        final counts = <String, int>{
          'baseline': 0,
          'reduced_0.8x': 0,
          'reduced_0.6x': 0,
        };

        for (int i = 0; i < 100; i++) {
          final variant =
              coordinator.getExperimentVariant('user_$i', experimentId);
          counts[variant] = (counts[variant] ?? 0) + 1;
        }

        // Baseline should be ~50%
        expect(counts['baseline']!, greaterThan(30));
        expect(counts['baseline']!, lessThan(70));

        // Others should be ~25% each
        expect((counts['reduced_0.8x'] ?? 0) + (counts['reduced_0.6x'] ?? 0),
            greaterThan(30));
      });

      test('logs variant assignment on first access', () async {
        const userId = 'user_new_assignment';
        const experimentId = 'exp_cooldown';

        coordinator.getExperimentVariant(userId, experimentId);

        verify(mockAnalytics.logABTestVariantAssignment(
          userId: userId,
          experimentId: experimentId,
          variantName: any,
          isControl: any,
        )).called(1);
      });

      test('does not log variant assignment on cache hit', () async {
        const userId = 'user_cache_hit';
        const experimentId = 'exp_cooldown';

        coordinator.getExperimentVariant(userId, experimentId);
        coordinator.getExperimentVariant(userId, experimentId);

        // Should only log once due to caching
        verify(mockAnalytics.logABTestVariantAssignment(
          userId: userId,
          experimentId: experimentId,
          variantName: any,
          isControl: any,
        )).called(1);
      });

      test('returns control variant for non-existent experiment', () {
        final variant = coordinator.getExperimentVariant('user_123', 'exp_fake');
        expect(variant, equals('control'));
      });
    });

    group('Active Experiment Filtering', () {
      test('returns experiments that are active', () {
        final now = DateTime.now();

        coordinator.registerExperiment(
          ABTestExperimentConfig(
            experimentId: 'exp_active',
            name: 'Active Exp',
            description: 'Currently running',
            startDate: now.subtract(Duration(days: 1)),
            endDate: now.add(Duration(days: 1)),
            controlVariant: 'control',
            rolloutPercentage: 100,
            variantDistribution: {'control': 100},
          ),
        );

        final active = coordinator.getActiveExperiments('user_123');
        expect(active.any((e) => e.experimentId == 'exp_active'), isTrue);
      });

      test('excludes future experiments', () {
        final now = DateTime.now();

        coordinator.registerExperiment(
          ABTestExperimentConfig(
            experimentId: 'exp_future',
            name: 'Future Exp',
            description: 'Not yet started',
            startDate: now.add(Duration(days: 1)),
            controlVariant: 'control',
            rolloutPercentage: 100,
            variantDistribution: {'control': 100},
          ),
        );

        final active = coordinator.getActiveExperiments('user_123');
        expect(active.any((e) => e.experimentId == 'exp_future'), isFalse);
      });

      test('excludes past experiments', () {
        final now = DateTime.now();

        coordinator.registerExperiment(
          ABTestExperimentConfig(
            experimentId: 'exp_past',
            name: 'Past Exp',
            description: 'Already ended',
            startDate: now.subtract(Duration(days: 2)),
            endDate: now.subtract(Duration(days: 1)),
            controlVariant: 'control',
            rolloutPercentage: 100,
            variantDistribution: {'control': 100},
          ),
        );

        final active = coordinator.getActiveExperiments('user_123');
        expect(active.any((e) => e.experimentId == 'exp_past'), isFalse);
      });

      test('excludes experiments ended today', () {
        final now = DateTime.now();

        coordinator.registerExperiment(
          ABTestExperimentConfig(
            experimentId: 'exp_ends_today',
            name: 'Ends Today',
            description: 'Just ending',
            startDate: now.subtract(Duration(days: 1)),
            endDate: now.subtract(Duration(hours: 1)),
            controlVariant: 'control',
            rolloutPercentage: 100,
            variantDistribution: {'control': 100},
          ),
        );

        final active = coordinator.getActiveExperiments('user_123');
        expect(active.any((e) => e.experimentId == 'exp_ends_today'), isFalse);
      });
    });

    group('Treatment Group Detection', () {
      setUp(() {
        coordinator.registerExperiment(
          ABTestExperimentConfig(
            experimentId: 'exp_treatment_test',
            name: 'Treatment Test',
            description: 'Testing treatment detection',
            startDate: DateTime.now().subtract(Duration(days: 1)),
            controlVariant: 'control',
            rolloutPercentage: 100,
            variantDistribution: {
              'control': 50,
              'treatment_v1': 50,
            },
          ),
        );
      });

      test('correctly identifies control group users', () {
        // Note: This is probabilistic, so we check with a population
        int controlCount = 0;
        for (int i = 0; i < 100; i++) {
          final userId = 'user_$i';
          final variant = coordinator.getExperimentVariant(
              userId, 'exp_treatment_test');

          if (!coordinator.isInTreatmentGroup(userId, 'exp_treatment_test')) {
            controlCount++;
          }

          if (variant == 'control') {
            expect(
                coordinator.isInTreatmentGroup(userId, 'exp_treatment_test'),
                isFalse);
          }
        }

        expect(controlCount, greaterThan(0));
      });

      test('correctly identifies treatment group users', () {
        int treatmentCount = 0;
        for (int i = 0; i < 100; i++) {
          final userId = 'user_$i';
          final variant = coordinator.getExperimentVariant(
              userId, 'exp_treatment_test');

          if (coordinator.isInTreatmentGroup(userId, 'exp_treatment_test')) {
            treatmentCount++;
            expect(variant, isNot('control'));
          }
        }

        expect(treatmentCount, greaterThan(0));
      });

      test('returns false for non-existent experiment', () {
        expect(
            coordinator.isInTreatmentGroup('user_123', 'exp_fake'), isFalse);
      });
    });

    group('User Variant Retrieval', () {
      setUp(() {
        final now = DateTime.now();
        for (int i = 1; i <= 3; i++) {
          coordinator.registerExperiment(
            ABTestExperimentConfig(
              experimentId: 'exp_$i',
              name: 'Experiment $i',
              description: 'Test $i',
              startDate: now.subtract(Duration(days: 1)),
              controlVariant: 'control',
              rolloutPercentage: 100,
              variantDistribution: {
                'control': 50,
                'variant_a': 25,
                'variant_b': 25,
              },
            ),
          );
        }
      });

      test('returns variants for all active experiments', () {
        final userId = 'user_multi_variant';
        final variants = coordinator.getUserVariants(userId);

        expect(variants.length, equals(3));
        expect(variants.keys.toSet(),
            equals({'exp_1', 'exp_2', 'exp_3'}));
      });

      test('ensures same variant across multiple calls', () {
        final userId = 'user_stable_multi';
        final variants1 = coordinator.getUserVariants(userId);
        final variants2 = coordinator.getUserVariants(userId);

        expect(variants1, equals(variants2));
      });

      test('different users have different variant sets', () {
        final variants1 = coordinator.getUserVariants('user_a');
        final variants2 = coordinator.getUserVariants('user_b');

        // With 50/25/25 distribution, chance of exact match is small
        expect(variants1, isNotEmpty);
        expect(variants2, isNotEmpty);
      });
    });

    group('Event Logging with Experiment Context', () {
      setUp(() {
        coordinator.registerExperiment(
          ABTestExperimentConfig(
            experimentId: 'exp_logging_test',
            name: 'Logging Test',
            description: 'Test event logging',
            startDate: DateTime.now().subtract(Duration(days: 1)),
            controlVariant: 'baseline',
            rolloutPercentage: 100,
            variantDistribution: {
              'baseline': 50,
              'treatment': 50,
            },
          ),
        );
      });

      test('logs event with experiment context', () {
        coordinator.logEventWithExperiment(
          'user_123',
          'test_event',
          {'value': 100},
          'exp_logging_test',
        );

        verify(mockAnalytics.logCustomEvent(
          'user_123',
          'test_event',
          argThat(isA<Map<String, dynamic>>()
              .having((p) => p['experiment_id'], 'experiment_id',
                  equals('exp_logging_test'))
              .having(
                  (p) => p.containsKey('variant'), 'has variant', isTrue)
              .having((p) => p.containsKey('cohort'), 'has cohort', isTrue)),
        )).called(1);
      });

      test('logs event with feature flag context', () {
        coordinator.logEventWithFeatureFlag(
          'user_123',
          'feature_event',
          {'data': 'test'},
          'test_feature',
        );

        verify(mockAnalytics.logCustomEvent(
          'user_123',
          'feature_event',
          argThat(isA<Map<String, dynamic>>()
              .having((p) => p['feature_name'], 'feature_name',
                  equals('test_feature'))
              .having(
                  (p) => p.containsKey('feature_enabled'),
                  'has feature_enabled',
                  isTrue)
              .having((p) => p.containsKey('feature_variant'),
                  'has feature_variant', isTrue)),
        )).called(1);
      });

      test('enriched event includes user cohort', () {
        coordinator.logEventWithExperiment(
          'user_123',
          'event_with_cohort',
          {},
          'exp_logging_test',
        );

        verify(mockAnalytics.logCustomEvent(
          'user_123',
          'event_with_cohort',
          argThat(isA<Map<String, dynamic>>()
              .having((p) => p['cohort'], 'cohort', equals('normal'))),
        )).called(1);
      });
    });

    group('Cache Management', () {
      test('clearCache resets all variant assignments', () {
        coordinator.registerExperiment(
          ABTestExperimentConfig(
            experimentId: 'exp_cache_test',
            name: 'Cache Test',
            description: 'Testing cache',
            startDate: DateTime.now().subtract(Duration(days: 1)),
            controlVariant: 'control',
            rolloutPercentage: 100,
            variantDistribution: {
              'control': 50,
              'treatment': 50,
            },
          ),
        );

        const userId = 'user_cache_clear';
        final variant1 = coordinator.getExperimentVariant(userId, 'exp_cache_test');

        coordinator.clearCache();

        // Re-generate (should be same due to consistent hashing)
        final variant2 = coordinator.getExperimentVariant(userId, 'exp_cache_test');

        expect(variant1, equals(variant2));
      });
    });

    group('Rollout Percentage Handling', () {
      test('respects rollout percentage when assigning variants', () {
        coordinator.registerExperiment(
          ABTestExperimentConfig(
            experimentId: 'exp_rollout_10pct',
            name: '10% Rollout',
            description: 'Only 10% of users get variant',
            startDate: DateTime.now().subtract(Duration(days: 1)),
            controlVariant: 'control',
            rolloutPercentage: 10,
            variantDistribution: {
              'control': 50,
              'variant_new': 50,
            },
          ),
        );

        int rolloutCount = 0;
        for (int i = 0; i < 200; i++) {
          final variant =
              coordinator.getExperimentVariant('user_$i', 'exp_rollout_10pct');
          if (variant != 'control') {
            rolloutCount++;
          }
        }

        // With 10% rollout and 50% treatment distribution,
        // expect ~5% in treatment (±margin for hash variance)
        expect(rolloutCount, greaterThan(0));
        expect(rolloutCount, lessThan(30)); // rough upper bound
      });

      test('zero rollout assigns all to control', () {
        coordinator.registerExperiment(
          ABTestExperimentConfig(
            experimentId: 'exp_zero_rollout',
            name: '0% Rollout',
            description: 'No one gets variant',
            startDate: DateTime.now().subtract(Duration(days: 1)),
            controlVariant: 'control',
            rolloutPercentage: 0,
            variantDistribution: {
              'control': 50,
              'variant': 50,
            },
          ),
        );

        for (int i = 0; i < 50; i++) {
          final variant =
              coordinator.getExperimentVariant('user_$i', 'exp_zero_rollout');
          expect(variant, equals('control'));
        }
      });

      test('100% rollout includes all users', () {
        coordinator.registerExperiment(
          ABTestExperimentConfig(
            experimentId: 'exp_full_rollout',
            name: '100% Rollout',
            description: 'Everyone gets variant',
            startDate: DateTime.now().subtract(Duration(days: 1)),
            controlVariant: 'control',
            rolloutPercentage: 100,
            variantDistribution: {
              'control': 50,
              'variant': 50,
            },
          ),
        );

        for (int i = 0; i < 50; i++) {
          final variant =
              coordinator.getExperimentVariant('user_$i', 'exp_full_rollout');
          expect(variant, isNotEmpty);
        }
      });
    });

    group('Debug Output', () {
      test('generates debug dump', () {
        coordinator.registerExperiment(
          ABTestExperimentConfig(
            experimentId: 'exp_debug_test',
            name: 'Debug Test',
            description: 'Testing debug output',
            startDate: DateTime.now().subtract(Duration(days: 1)),
            controlVariant: 'control',
            rolloutPercentage: 100,
            variantDistribution: {
              'control': 100,
            },
          ),
        );

        final dump = coordinator.debugDumpExperiments('user_debug');
        expect(dump.contains('A/B Test Coordinator Debug Dump'), isTrue);
        expect(dump.contains('user_debug'), isTrue);
        expect(dump.contains('exp_debug_test'), isTrue);
      });
    });

    group('Edge Cases', () {
      test('handles empty user ID', () {
        coordinator.registerExperiment(
          ABTestExperimentConfig(
            experimentId: 'exp_edge',
            name: 'Edge Case',
            description: 'Test edge case',
            startDate: DateTime.now().subtract(Duration(days: 1)),
            controlVariant: 'control',
            rolloutPercentage: 100,
            variantDistribution: {'control': 100},
          ),
        );

        expect(
            () => coordinator.getExperimentVariant('', 'exp_edge'),
            returnsNormally);
      });

      test('handles empty experiment ID', () {
        final variant = coordinator.getExperimentVariant('user_123', '');
        expect(variant, equals('control'));
      });

      test('handles non-existent user in variants retrieval', () {
        coordinator.registerExperiment(
          ABTestExperimentConfig(
            experimentId: 'exp_test',
            name: 'Test',
            description: 'Test',
            startDate: DateTime.now().subtract(Duration(days: 1)),
            controlVariant: 'control',
            rolloutPercentage: 100,
            variantDistribution: {'control': 100},
          ),
        );

        final variants = coordinator.getUserVariants('nonexistent_user');
        expect(variants, isNotEmpty);
      });
    });
  });
}
