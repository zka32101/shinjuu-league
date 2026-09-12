import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shinjuu_league/config/skill_progression_config.dart';
import 'package:shinjuu_league/services/feature_flags_service.dart';

class MockSkillProgressionConfig extends Mock
    implements SkillProgressionConfig {}

void main() {
  group('FeatureFlagsService', () {
    late MockSkillProgressionConfig mockConfig;
    late FeatureFlagsService featureFlags;

    setUp(() {
      mockConfig = MockSkillProgressionConfig();

      // Default: normal difficulty
      when(mockConfig.getDifficultyModifiers()).thenReturn(
        ProgressionDifficultyModifiers(
          levelDifficultyMultiplier: 1.0,
          skillCooldownMultiplier: 1.0,
          skillDamageMultiplier: 1.0,
        ),
      );

      featureFlags = FeatureFlagsService(config: mockConfig);
    });

    group('Feature Gate Evaluation', () {
      test('returns true for enabled feature at 100% rollout', () {
        final userId = 'user_123';
        expect(featureFlags.isFeatureEnabled(userId, 'skill_cooldown_reduction'),
            isTrue);
      });

      test('returns false for disabled feature via kill switch', () {
        featureFlags.disableFeature('skill_cooldown_reduction');
        expect(featureFlags.isFeatureEnabled('user_123', 'skill_cooldown_reduction'),
            isFalse);
      });

      test('returns false for non-existent feature', () {
        expect(featureFlags.isFeatureEnabled('user_123', 'nonexistent_feature'),
            isFalse);
      });

      test('respects rollout percentage for feature', () {
        featureFlags.setRolloutPercentage('ranked_mode', 10);

        // Collect multiple users to check distribution
        int enabledCount = 0;
        for (int i = 0; i < 100; i++) {
          if (featureFlags.isFeatureEnabled('user_$i', 'ranked_mode')) {
            enabledCount++;
          }
        }

        // With 10% rollout, expect roughly 10% enabled (±5% margin for hash variance)
        expect(enabledCount, lessThan(20)); // less than 20%
        expect(enabledCount, greaterThan(0)); // at least some
      });

      test('caches feature gate results', () {
        final userId = 'user_cache_test';
        final result1 = featureFlags.isFeatureEnabled(userId, 'skill_cooldown_reduction');

        // Disable and check if cache returns same result
        featureFlags.disableFeature('skill_cooldown_reduction');
        final result2 = featureFlags.isFeatureEnabled(userId, 'skill_cooldown_reduction');

        expect(result1, result2); // should be consistent due to cache
      });

      test('clearCache invalidates all caches', () {
        final userId = 'user_cache_clear';
        featureFlags.isFeatureEnabled(userId, 'skill_cooldown_reduction');

        featureFlags.clearCache();
        featureFlags.disableFeature('skill_cooldown_reduction');

        final result = featureFlags.isFeatureEnabled(userId, 'skill_cooldown_reduction');
        expect(result, isFalse);
      });
    });

    group('Variant Assignment', () {
      test('returns same variant for same user across calls', () {
        const userId = 'user_stable_variant';
        const featureName = 'skill_cooldown_reduction';

        final variant1 = featureFlags.getVariant(userId, featureName);
        final variant2 = featureFlags.getVariant(userId, featureName);

        expect(variant1, equals(variant2));
      });

      test('returns different variants for different users', () {
        const featureName = 'skill_cooldown_reduction';

        final variants = <String>{};
        for (int i = 0; i < 50; i++) {
          variants.add(featureFlags.getVariant('user_$i', featureName));
        }

        // Should have multiple variants
        expect(variants.length, greaterThan(1));
      });

      test('returns control variant for disabled feature', () {
        featureFlags.disableFeature('skill_cooldown_reduction');

        final variant = featureFlags.getVariant('user_123', 'skill_cooldown_reduction');
        expect(variant, equals('control'));
      });

      test('returns default variant for non-existent feature', () {
        final variant = featureFlags.getVariant('user_123', 'nonexistent_feature');
        expect(variant, equals('control'));
      });

      test('distributes variants across all available options', () {
        const featureName = 'skill_cooldown_reduction';
        const featureMetadata = {
          'baseline': 0,
          'reduced_0.8x': 0,
          'reduced_0.6x': 0,
        };

        final counts = <String, int>{};
        for (final v in featureMetadata.keys) {
          counts[v] = 0;
        }

        // Sample 100 users
        for (int i = 0; i < 100; i++) {
          final variant = featureFlags.getVariant('user_$i', featureName);
          if (counts.containsKey(variant)) {
            counts[variant] = counts[variant]! + 1;
          }
        }

        // All variants should be represented
        expect(counts['baseline'], greaterThan(0));
        expect(counts['reduced_0.8x'], greaterThan(0));
        expect(counts['reduced_0.6x'], greaterThan(0));
      });

      test('caches variant assignments', () {
        const userId = 'user_variant_cache';
        final variant1 = featureFlags.getVariant(userId, 'skill_cooldown_reduction');

        featureFlags.disableFeature('skill_cooldown_reduction');
        final variant2 = featureFlags.getVariant(userId, 'skill_cooldown_reduction');

        expect(variant1, equals(variant2)); // cached
      });
    });

    group('Difficulty Cohort Assignment', () {
      test('returns easy cohort when difficulty multiplier < 1.0', () {
        when(mockConfig.getDifficultyModifiers()).thenReturn(
          ProgressionDifficultyModifiers(
            levelDifficultyMultiplier: 0.7,
            skillCooldownMultiplier: 0.8,
            skillDamageMultiplier: 0.9,
          ),
        );

        featureFlags = FeatureFlagsService(config: mockConfig);
        expect(featureFlags.getDifficultyCohort('user_123'), equals('easy'));
      });

      test('returns hard cohort when difficulty multiplier > 1.0', () {
        when(mockConfig.getDifficultyModifiers()).thenReturn(
          ProgressionDifficultyModifiers(
            levelDifficultyMultiplier: 1.3,
            skillCooldownMultiplier: 1.2,
            skillDamageMultiplier: 1.1,
          ),
        );

        featureFlags = FeatureFlagsService(config: mockConfig);
        expect(featureFlags.getDifficultyCohort('user_123'), equals('hard'));
      });

      test('returns normal cohort when difficulty multiplier = 1.0', () {
        when(mockConfig.getDifficultyModifiers()).thenReturn(
          ProgressionDifficultyModifiers(
            levelDifficultyMultiplier: 1.0,
            skillCooldownMultiplier: 1.0,
            skillDamageMultiplier: 1.0,
          ),
        );

        featureFlags = FeatureFlagsService(config: mockConfig);
        expect(featureFlags.getDifficultyCohort('user_123'), equals('normal'));
      });
    });

    group('Feature Metadata', () {
      test('retrieves metadata for known feature', () {
        final metadata = featureFlags.getMetadata('skill_cooldown_reduction');
        expect(metadata, isNotNull);
        expect(metadata!.name, equals('skill_cooldown_reduction'));
        expect(metadata.enabled, isTrue);
      });

      test('returns null for unknown feature', () {
        final metadata = featureFlags.getMetadata('unknown_feature');
        expect(metadata, isNull);
      });

      test('lists all features', () {
        final features = featureFlags.listFeatures();
        expect(features.length, greaterThan(0));
        expect(features.every((f) => f.name.isNotEmpty), isTrue);
      });
    });

    group('Kill Switch Control', () {
      test('disables feature via kill switch', () {
        expect(featureFlags.isFeatureEnabled('user_123', 'ranked_mode'), isTrue);

        featureFlags.disableFeature('ranked_mode');
        expect(featureFlags.isFeatureEnabled('user_123', 'ranked_mode'), isFalse);

        featureFlags.enableFeature('ranked_mode');
        expect(featureFlags.isFeatureEnabled('user_123', 'ranked_mode'), isTrue);
      });

      test('kill switch applies to all users', () {
        featureFlags.disableFeature('ranked_mode');

        for (int i = 0; i < 10; i++) {
          expect(featureFlags.isFeatureEnabled('user_$i', 'ranked_mode'), isFalse);
        }
      });
    });

    group('Rollout Percentage Control', () {
      test('sets rollout percentage', () {
        featureFlags.setRolloutPercentage('new_ui_layout', 50);
        final metadata = featureFlags.getMetadata('new_ui_layout');
        expect(metadata!.rolloutPercentage, equals(50));
      });

      test('rejects invalid rollout percentages', () {
        final metadata = featureFlags.getMetadata('new_ui_layout');
        final originalRollout = metadata!.rolloutPercentage;

        featureFlags.setRolloutPercentage('new_ui_layout', 150);
        expect(featureFlags.getMetadata('new_ui_layout')!.rolloutPercentage,
            equals(originalRollout));

        featureFlags.setRolloutPercentage('new_ui_layout', -10);
        expect(featureFlags.getMetadata('new_ui_layout')!.rolloutPercentage,
            equals(originalRollout));
      });

      test('clears cache when rollout percentage changes', () {
        const userId = 'user_rollout_cache';
        const featureName = 'new_ui_layout';

        final result1 = featureFlags.isFeatureEnabled(userId, featureName);

        featureFlags.setRolloutPercentage(featureName, 0);
        final result2 = featureFlags.isFeatureEnabled(userId, featureName);

        expect(result1, isNotEmpty); // may be true or false
        expect(result2, isFalse); // 0% rollout = always false
      });
    });

    group('Debug Output', () {
      test('generates debug dump for user', () {
        final dump = featureFlags.debugDump('test_user');
        expect(dump.contains('Feature Flags Debug Dump'), isTrue);
        expect(dump.contains('test_user'), isTrue);
        expect(dump.contains('Enabled:'), isTrue);
        expect(dump.contains('Variant:'), isTrue);
      });

      test('debug dump includes all features', () {
        final dump = featureFlags.debugDump('user_123');
        final features = featureFlags.listFeatures();

        for (final feature in features) {
          expect(dump.contains(feature.name), isTrue);
        }
      });
    });

    group('Edge Cases', () {
      test('handles empty userId gracefully', () {
        expect(() => featureFlags.isFeatureEnabled('', 'ranked_mode'), returnsNormally);
        expect(() => featureFlags.getVariant('', 'ranked_mode'), returnsNormally);
      });

      test('handles empty feature name gracefully', () {
        expect(() => featureFlags.isFeatureEnabled('user_123', ''), returnsNormally);
        expect(featureFlags.isFeatureEnabled('user_123', ''), isFalse);
      });

      test('handles very long userId', () {
        final longId = 'u' * 1000;
        expect(() => featureFlags.isFeatureEnabled(longId, 'ranked_mode'), returnsNormally);
      });

      test('multiple rollout percentage changes maintain consistency', () {
        const userId = 'user_consistency';
        const featureName = 'ranked_mode';

        // Set to low percentage, check consistent result
        featureFlags.setRolloutPercentage(featureName, 5);
        final result1 = featureFlags.isFeatureEnabled(userId, featureName);

        // Clear cache and check again
        featureFlags.clearCache();
        final result2 = featureFlags.isFeatureEnabled(userId, featureName);

        expect(result1, equals(result2));
      });
    });

    group('Cohort Consistency', () {
      test('same user returns same cohort across calls', () {
        const userId = 'user_cohort_stable';

        final cohort1 = featureFlags.getDifficultyCohort(userId);
        final cohort2 = featureFlags.getDifficultyCohort(userId);

        expect(cohort1, equals(cohort2));
      });

      test('cohort determined by config multiplier only', () {
        // Easy multiplier
        when(mockConfig.getDifficultyModifiers()).thenReturn(
          ProgressionDifficultyModifiers(
            levelDifficultyMultiplier: 0.7,
            skillCooldownMultiplier: 0.8,
            skillDamageMultiplier: 0.9,
          ),
        );
        var tempFlags = FeatureFlagsService(config: mockConfig);
        expect(tempFlags.getDifficultyCohort('user_1'), equals('easy'));

        // Hard multiplier
        when(mockConfig.getDifficultyModifiers()).thenReturn(
          ProgressionDifficultyModifiers(
            levelDifficultyMultiplier: 1.5,
            skillCooldownMultiplier: 1.2,
            skillDamageMultiplier: 1.1,
          ),
        );
        tempFlags = FeatureFlagsService(config: mockConfig);
        expect(tempFlags.getDifficultyCohort('user_1'), equals('hard'));
      });
    });
  });
}
