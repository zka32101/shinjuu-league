import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shinjuu_league/config/skill_progression_config.dart';
import 'package:shinjuu_league/services/ab_test_coordinator.dart';
import 'package:shinjuu_league/services/config_admin_service.dart';
import 'package:shinjuu_league/services/feature_flags_service.dart';

class MockSkillProgressionConfig extends Mock
    implements SkillProgressionConfig {}

class MockFeatureFlagsService extends Mock
    implements FeatureFlagsService {}

class MockABTestCoordinator extends Mock implements ABTestCoordinator {}

void main() {
  group('ConfigAdminService', () {
    late MockSkillProgressionConfig mockConfig;
    late MockFeatureFlagsService mockFlags;
    late MockABTestCoordinator mockCoordinator;
    late ConfigAdminService adminService;

    setUp(() {
      mockConfig = MockSkillProgressionConfig();
      mockFlags = MockFeatureFlagsService();
      mockCoordinator = MockABTestCoordinator();

      // Default mock behavior
      when(mockConfig.getDifficultyModifiers()).thenReturn(
        ProgressionDifficultyModifiers(
          levelDifficultyMultiplier: 1.0,
          skillCooldownMultiplier: 1.0,
          skillDamageMultiplier: 1.0,
        ),
      );

      when(mockConfig.difficultyPreset).thenReturn('normal');

      when(mockFlags.listFeatures()).thenReturn([
        FeatureFlagMetadata(
          name: 'test_feature',
          description: 'Test feature',
          enabled: true,
          rolloutPercentage: 100,
          abTestVariants: ['control', 'treatment'],
          defaultVariant: 'control',
          killSwitch: false,
        ),
      ]);

      adminService = ConfigAdminService(
        progressionConfig: mockConfig,
        featureFlags: mockFlags,
        coordinator: mockCoordinator,
      );
    });

    group('Difficulty Management', () {
      test('gets current difficulty modifiers', () {
        final modifiers = adminService.getDifficultyModifiers();

        expect(modifiers.levelDifficultyMultiplier, equals(1.0));
        expect(modifiers.skillCooldownMultiplier, equals(1.0));
        expect(modifiers.skillDamageMultiplier, equals(1.0));
      });

      test('applies easy difficulty preset', () async {
        await adminService.applyDifficultyPreset('easy');

        final history = adminService.getChangeHistory();
        expect(history, isNotEmpty);
        expect(history.last.type, equals('DIFFICULTY_PRESET'));
        expect(history.last.newValue, equals('easy'));
      });

      test('applies hard difficulty preset', () async {
        await adminService.applyDifficultyPreset('hard');

        final history = adminService.getChangeHistory();
        expect(history.last.newValue, equals('hard'));
      });

      test('applies normal difficulty preset', () async {
        await adminService.applyDifficultyPreset('normal');

        final history = adminService.getChangeHistory();
        expect(history.last.newValue, equals('normal'));
      });

      test('handles case-insensitive preset names', () async {
        await adminService.applyDifficultyPreset('EASY');
        await adminService.applyDifficultyPreset('HaRd');

        final history = adminService.getChangeHistory();
        expect(history.length, greaterThanOrEqualTo(2));
      });

      test('sets individual difficulty multiplier', () async {
        await adminService.setDifficultyMultiplier('level', 1.5);

        final history = adminService.getChangeHistory();
        expect(history.last.type, equals('MULTIPLIER_CHANGE'));
        expect(history.last.newValue, equals(1.5));
      });

      test('clamps multiplier values to valid range', () async {
        // Too high
        await adminService.setDifficultyMultiplier('cooldown', 5.0);
        var history = adminService.getChangeHistory();
        expect(history.last.newValue, equals(3.0)); // Clamped to max

        // Too low
        await adminService.setDifficultyMultiplier('damage', 0.05);
        history = adminService.getChangeHistory();
        expect(history.last.newValue, equals(0.1)); // Clamped to min
      });

      test('accepts reasonable multiplier values', () async {
        await adminService.setDifficultyMultiplier('level', 1.2);
        await adminService.setDifficultyMultiplier('cooldown', 0.8);
        await adminService.setDifficultyMultiplier('damage', 1.1);

        final history = adminService.getChangeHistory();
        expect(history.where((r) => r.type == 'MULTIPLIER_CHANGE').length,
            equals(3));
      });
    });

    group('Feature Flag Control', () {
      test('enables feature', () async {
        await adminService.setFeatureEnabled('test_feature', true);

        verify(mockFlags.enableFeature('test_feature')).called(1);
      });

      test('disables feature', () async {
        await adminService.setFeatureEnabled('test_feature', false);

        verify(mockFlags.disableFeature('test_feature')).called(1);
      });

      test('records feature toggle in history', () async {
        await adminService.setFeatureEnabled('test_feature', false);

        final history = adminService.getChangeHistory();
        expect(history.last.type, equals('FEATURE_TOGGLE'));
        expect(history.last.key, contains('test_feature'));
      });

      test('sets feature rollout percentage', () async {
        await adminService.setFeatureRollout('test_feature', 50);

        verify(mockFlags.setRolloutPercentage('test_feature', 50)).called(1);
      });

      test('records rollout change in history', () async {
        await adminService.setFeatureRollout('test_feature', 25);

        final history = adminService.getChangeHistory();
        expect(history.last.type, equals('ROLLOUT_CHANGE'));
        expect(history.last.newValue, equals(25));
      });

      test('handles multiple feature changes', () async {
        await adminService.setFeatureEnabled('test_feature', true);
        await adminService.setFeatureRollout('test_feature', 75);
        await adminService.setFeatureEnabled('test_feature', false);

        final history = adminService.getChangeHistory();
        expect(history.length, greaterThanOrEqualTo(3));
      });
    });

    group('Feature Status Retrieval', () {
      test('retrieves all feature status', () {
        final statuses = adminService.getAllFeatureStatus();

        expect(statuses, isNotEmpty);
        expect(statuses.first.name, equals('test_feature'));
      });

      test('feature status includes all required fields', () {
        final statuses = adminService.getAllFeatureStatus();
        final status = statuses.first;

        expect(status.name, isNotEmpty);
        expect(status.enabled, isA<bool>());
        expect(status.killSwitch, isA<bool>());
        expect(status.rolloutPercentage, isA<int>());
        expect(status.variants, isA<List>());
        expect(status.description, isNotEmpty);
      });

      test('reflects enabled state correctly', () {
        when(mockFlags.listFeatures()).thenReturn([
          FeatureFlagMetadata(
            name: 'enabled_feature',
            description: 'Enabled',
            enabled: true,
            rolloutPercentage: 100,
            abTestVariants: ['a'],
            defaultVariant: 'a',
            killSwitch: false,
          ),
          FeatureFlagMetadata(
            name: 'disabled_feature',
            description: 'Disabled',
            enabled: false,
            rolloutPercentage: 0,
            abTestVariants: ['a'],
            defaultVariant: 'a',
            killSwitch: true,
          ),
        ]);

        final statuses = adminService.getAllFeatureStatus();
        expect(statuses.where((s) => s.enabled).length, equals(1));
      });
    });

    group('Experiment Management', () {
      test('creates experiment', () async {
        final exp = ABTestExperimentConfig(
          experimentId: 'test_exp',
          name: 'Test Experiment',
          description: 'Testing',
          startDate: DateTime.now(),
          controlVariant: 'control',
          rolloutPercentage: 100,
          variantDistribution: {'control': 100},
        );

        await adminService.createExperiment(exp);

        verify(mockCoordinator.registerExperiment(exp)).called(1);
      });

      test('records experiment creation in history', () async {
        final exp = ABTestExperimentConfig(
          experimentId: 'test_exp_2',
          name: 'Test Experiment 2',
          description: 'Testing',
          startDate: DateTime.now(),
          controlVariant: 'control',
          rolloutPercentage: 50,
          variantDistribution: {'control': 50, 'treatment': 50},
        );

        await adminService.createExperiment(exp);

        final history = adminService.getChangeHistory();
        expect(history.last.type, equals('EXPERIMENT_CREATED'));
        expect(history.last.newValue, equals('Test Experiment 2'));
      });

      test('updates experiment rollout', () async {
        await adminService.updateExperimentRollout('exp_123', 75);

        final history = adminService.getChangeHistory();
        expect(history.last.type, equals('EXPERIMENT_ROLLOUT_CHANGE'));
        expect(history.last.newValue, equals(75));
      });
    });

    group('Change History', () {
      test('records configuration changes', () async {
        await adminService.applyDifficultyPreset('easy');
        await adminService.setFeatureEnabled('test_feature', false);

        final history = adminService.getChangeHistory();
        expect(history.length, greaterThanOrEqualTo(2));
      });

      test('returns limited change history', () async {
        // Make many changes
        for (int i = 0; i < 10; i++) {
          await adminService.applyDifficultyPreset('easy');
        }

        final history = adminService.getChangeHistory(limit: 5);
        expect(history.length, lessThanOrEqualTo(5));
      });

      test('change records include timestamp', () async {
        await adminService.applyDifficultyPreset('hard');

        final history = adminService.getChangeHistory();
        expect(history.last.timestamp, isNotNull);
      });

      test('change records include details', () async {
        await adminService.setFeatureRollout('test_feature', 33);

        final history = adminService.getChangeHistory();
        expect(history.last.details, isNotEmpty);
        expect(history.last.details['featureName'], equals('test_feature'));
      });

      test('bounds history size to prevent unbounded growth', () async {
        // Make many changes
        for (int i = 0; i < 150; i++) {
          await adminService.applyDifficultyPreset('normal');
        }

        final history = adminService.getChangeHistory(limit: 1000);
        expect(history.length, lessThanOrEqualTo(100)); // Max history size
      });
    });

    group('Snapshots and Rollback', () {
      test('saves initial snapshot on creation', () {
        // Initial snapshot is saved in constructor
        expect(adminService.getStats().snapshotCount, greaterThan(0));
      });

      test('rollback records change in history', () async {
        await adminService.rollbackToSnapshot('initial');

        final history = adminService.getChangeHistory();
        expect(history.last.type, equals('ROLLBACK'));
      });

      test('rollback to non-existent snapshot handles gracefully', () async {
        expect(
          () => adminService.rollbackToSnapshot('nonexistent'),
          returnsNormally,
        );
      });

      test('rollback includes snapshot timestamp in details', () async {
        await adminService.rollbackToSnapshot('initial');

        final history = adminService.getChangeHistory();
        expect(history.last.details['snapshotTimestamp'], isNotNull);
      });
    });

    group('Statistics', () {
      test('returns admin stats summary', () {
        final stats = adminService.getStats();

        expect(stats.totalFeatures, greaterThan(0));
        expect(stats.enabledFeatures, greaterThanOrEqualTo(0));
        expect(stats.averageRollout, isA<int>());
        expect(stats.changeHistorySize, isA<int>());
        expect(stats.snapshotCount, greaterThan(0));
      });

      test('stats reflect current state', () async {
        var stats = adminService.getStats();
        final initialHistorySize = stats.changeHistorySize;

        await adminService.applyDifficultyPreset('easy');

        stats = adminService.getStats();
        expect(stats.changeHistorySize, greaterThan(initialHistorySize));
      });

      test('calculates enabled feature percentage', () {
        when(mockFlags.listFeatures()).thenReturn([
          FeatureFlagMetadata(
            name: 'f1',
            description: '',
            enabled: true,
            rolloutPercentage: 100,
            abTestVariants: [],
            defaultVariant: '',
            killSwitch: false,
          ),
          FeatureFlagMetadata(
            name: 'f2',
            description: '',
            enabled: false,
            rolloutPercentage: 0,
            abTestVariants: [],
            defaultVariant: '',
            killSwitch: false,
          ),
        ]);

        final stats = adminService.getStats();
        expect(stats.enabledPercentage, equals(50.0));
      });

      test('calculates disabled feature count', () {
        final stats = adminService.getStats();
        expect(stats.disabledFeatures,
            equals(stats.totalFeatures - stats.enabledFeatures));
      });
    });

    group('Debug Output', () {
      test('generates debug dump', () {
        final dump = adminService.debugDump();

        expect(dump.contains('Config Admin Service Debug Dump'), isTrue);
        expect(dump.contains('Current Difficulty Modifiers'), isTrue);
        expect(dump.contains('Feature Status'), isTrue);
      });

      test('debug dump includes recent changes', () async {
        await adminService.applyDifficultyPreset('easy');

        final dump = adminService.debugDump();
        expect(dump.contains('Recent Changes'), isTrue);
        expect(dump.contains('DIFFICULTY_PRESET'), isTrue);
      });

      test('debug dump includes snapshots', () {
        final dump = adminService.debugDump();
        expect(dump.contains('Snapshots'), isTrue);
      });
    });

    group('Multiple Operations', () {
      test('handles complex admin workflow', () async {
        // 1. Apply preset
        await adminService.applyDifficultyPreset('easy');

        // 2. Adjust specific multiplier
        await adminService.setDifficultyMultiplier('cooldown', 0.7);

        // 3. Control features
        await adminService.setFeatureEnabled('test_feature', true);
        await adminService.setFeatureRollout('test_feature', 50);

        // 4. Create experiment
        final exp = ABTestExperimentConfig(
          experimentId: 'workflow_test',
          name: 'Workflow Test',
          description: 'Test',
          startDate: DateTime.now(),
          controlVariant: 'control',
          rolloutPercentage: 25,
          variantDistribution: {'control': 75, 'treatment': 25},
        );
        await adminService.createExperiment(exp);

        // 5. Check history
        final history = adminService.getChangeHistory();
        expect(history.length, greaterThanOrEqualTo(4));

        // 6. Check stats
        final stats = adminService.getStats();
        expect(stats.changeHistorySize, greaterThanOrEqualTo(4));
      });
    });

    group('Edge Cases', () {
      test('handles empty feature list', () {
        when(mockFlags.listFeatures()).thenReturn([]);

        final statuses = adminService.getAllFeatureStatus();
        expect(statuses, isEmpty);

        final stats = adminService.getStats();
        expect(stats.totalFeatures, equals(0));
        expect(stats.enabledPercentage, equals(0));
      });

      test('handles rapid consecutive changes', () async {
        for (int i = 0; i < 10; i++) {
          await adminService.applyDifficultyPreset(
              ['easy', 'normal', 'hard'][i % 3]);
        }

        final history = adminService.getChangeHistory();
        expect(history.length, equals(10));
      });

      test('handles very large multiplier clamp correctly', () async {
        await adminService.setDifficultyMultiplier('level', 1000.0);

        final history = adminService.getChangeHistory();
        expect(history.last.newValue, equals(3.0)); // Max clamped value
      });

      test('handles negative multiplier clamp correctly', () async {
        await adminService.setDifficultyMultiplier('damage', -5.0);

        final history = adminService.getChangeHistory();
        expect(history.last.newValue, equals(0.1)); // Min clamped value
      });

      test('handles rollback during active operations', () async {
        await adminService.applyDifficultyPreset('easy');
        await adminService.rollbackToSnapshot('initial');
        await adminService.setFeatureEnabled('test_feature', true);

        final history = adminService.getChangeHistory();
        expect(history.last.type, equals('FEATURE_TOGGLE'));
      });
    });
  });
}
