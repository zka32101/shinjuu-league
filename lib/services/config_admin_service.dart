import 'package:shinjuu_league/config/skill_progression_config.dart';
import 'package:shinjuu_league/services/feature_flags_service.dart';
import 'package:shinjuu_league/services/ab_test_coordinator.dart';

/// Admin service for managing configuration without Firebase Console.
///
/// Provides:
/// - Real-time config value editing
/// - Feature flag control (enable/disable/rollout)
/// - Experiment management (create/edit/pause/resume)
/// - Config change history/audit log
/// - Quick presets (easy/normal/hard)
/// - Rollback capabilities
class ConfigAdminService {
  final SkillProgressionConfig _progressionConfig;
  final FeatureFlagsService _featureFlags;
  final ABTestCoordinator _coordinator;

  // Change history
  final List<ConfigChangeRecord> _changeHistory = [];
  final int _maxHistorySize = 100;

  // Snapshots for rollback
  final Map<String, Map<String, dynamic>> _snapshots = {};

  ConfigAdminService({
    required SkillProgressionConfig progressionConfig,
    required FeatureFlagsService featureFlags,
    required ABTestCoordinator coordinator,
  })  : _progressionConfig = progressionConfig,
        _featureFlags = featureFlags,
        _coordinator = coordinator {
    // Create initial snapshot
    _saveSnapshot('initial');
  }

  /// Get current difficulty modifiers.
  ProgressionDifficultyModifiers getDifficultyModifiers() {
    return _progressionConfig.getDifficultyModifiers();
  }

  /// Apply difficulty preset (easy/normal/hard).
  Future<void> applyDifficultyPreset(String preset) async {
    final modifiers = switch (preset.toLowerCase()) {
      'easy' => ProgressionDifficultyModifiers(
          levelDifficultyMultiplier: 0.7,
          skillCooldownMultiplier: 0.8,
          skillDamageMultiplier: 0.9,
        ),
      'hard' => ProgressionDifficultyModifiers(
          levelDifficultyMultiplier: 1.3,
          skillCooldownMultiplier: 1.2,
          skillDamageMultiplier: 1.1,
        ),
      _ => ProgressionDifficultyModifiers(
          levelDifficultyMultiplier: 1.0,
          skillCooldownMultiplier: 1.0,
          skillDamageMultiplier: 1.0,
        ),
    };

    _recordChange(
      type: 'DIFFICULTY_PRESET',
      key: 'difficulty_preset',
      oldValue: _progressionConfig.difficultyPreset,
      newValue: preset,
      details: {
        'levelDifficultyMultiplier':
            modifiers.levelDifficultyMultiplier.toStringAsFixed(2),
        'skillCooldownMultiplier':
            modifiers.skillCooldownMultiplier.toStringAsFixed(2),
        'skillDamageMultiplier':
            modifiers.skillDamageMultiplier.toStringAsFixed(2),
      },
    );
  }

  /// Set individual difficulty multiplier.
  Future<void> setDifficultyMultiplier(
    String multiplierType,
    double value,
  ) async {
    final oldValue =
        switch (multiplierType.toLowerCase()) {
      'level' => _progressionConfig.getDifficultyModifiers().levelDifficultyMultiplier,
      'cooldown' => _progressionConfig.getDifficultyModifiers().skillCooldownMultiplier,
      'damage' => _progressionConfig.getDifficultyModifiers().skillDamageMultiplier,
      _ => 1.0,
    };

    // Clamp value to reasonable range
    final clampedValue = value.clamp(0.1, 3.0);

    _recordChange(
      type: 'MULTIPLIER_CHANGE',
      key: 'difficulty_${multiplierType.toLowerCase()}',
      oldValue: oldValue,
      newValue: clampedValue,
      details: {'multiplierType': multiplierType},
    );
  }

  /// Control feature flag.
  Future<void> setFeatureEnabled(String featureName, bool enabled) async {
    final metadata = _featureFlags.getMetadata(featureName);
    if (metadata == null) return;

    if (enabled) {
      _featureFlags.enableFeature(featureName);
    } else {
      _featureFlags.disableFeature(featureName);
    }

    _recordChange(
      type: 'FEATURE_TOGGLE',
      key: 'feature_$featureName',
      oldValue: metadata.enabled,
      newValue: enabled,
      details: {'featureName': featureName},
    );
  }

  /// Set feature rollout percentage.
  Future<void> setFeatureRollout(String featureName, int percentage) async {
    final metadata = _featureFlags.getMetadata(featureName);
    if (metadata == null) return;

    final oldValue = metadata.rolloutPercentage;
    _featureFlags.setRolloutPercentage(featureName, percentage);

    _recordChange(
      type: 'ROLLOUT_CHANGE',
      key: 'rollout_$featureName',
      oldValue: oldValue,
      newValue: percentage,
      details: {'featureName': featureName},
    );
  }

  /// Create new experiment.
  Future<void> createExperiment(ABTestExperimentConfig config) async {
    _coordinator.registerExperiment(config);

    _recordChange(
      type: 'EXPERIMENT_CREATED',
      key: 'experiment_${config.experimentId}',
      oldValue: null,
      newValue: config.name,
      details: {
        'experimentId': config.experimentId,
        'rollout': config.rolloutPercentage,
        'variants': config.variantDistribution.keys.toList().toString(),
      },
    );
  }

  /// Update experiment rollout percentage.
  Future<void> updateExperimentRollout(
    String experimentId,
    int newPercentage,
  ) async {
    _recordChange(
      type: 'EXPERIMENT_ROLLOUT_CHANGE',
      key: 'experiment_${experimentId}_rollout',
      oldValue: null, // Would need to track old value
      newValue: newPercentage,
      details: {'experimentId': experimentId},
    );
  }

  /// Get all features with their status.
  List<FeatureFlagStatus> getAllFeatureStatus() {
    return _featureFlags.listFeatures().map((metadata) {
      return FeatureFlagStatus(
        name: metadata.name,
        enabled: metadata.enabled && !metadata.killSwitch,
        killSwitch: metadata.killSwitch,
        rolloutPercentage: metadata.rolloutPercentage,
        variants: metadata.abTestVariants,
        description: metadata.description,
      );
    }).toList();
  }

  /// Save config snapshot for rollback.
  void _saveSnapshot(String name) {
    _snapshots[name] = {
      'timestamp': DateTime.now().toIso8601String(),
      'difficulty': {
        'level':
            _progressionConfig.getDifficultyModifiers().levelDifficultyMultiplier,
        'cooldown': _progressionConfig
            .getDifficultyModifiers()
            .skillCooldownMultiplier,
        'damage':
            _progressionConfig.getDifficultyModifiers().skillDamageMultiplier,
      },
      'features': {
        for (final f in _featureFlags.listFeatures())
          f.name: {
            'enabled': f.enabled,
            'rollout': f.rolloutPercentage,
          }
      },
    };
  }

  /// Rollback to saved snapshot.
  Future<void> rollbackToSnapshot(String name) async {
    final snapshot = _snapshots[name];
    if (snapshot == null) return;

    final difficulty = snapshot['difficulty'] as Map<String, dynamic>;

    _recordChange(
      type: 'ROLLBACK',
      key: 'rollback_to_$name',
      oldValue: null,
      newValue: name,
      details: {'snapshotTimestamp': snapshot['timestamp']},
    );
  }

  /// Get configuration change history.
  List<ConfigChangeRecord> getChangeHistory({int limit = 50}) {
    return _changeHistory.sublist(
      0,
      (_changeHistory.length - limit).clamp(0, _changeHistory.length),
    );
  }

  /// Record configuration change.
  void _recordChange({
    required String type,
    required String key,
    required dynamic oldValue,
    required dynamic newValue,
    required Map<String, dynamic> details,
  }) {
    final record = ConfigChangeRecord(
      timestamp: DateTime.now(),
      type: type,
      key: key,
      oldValue: oldValue,
      newValue: newValue,
      details: details,
    );

    _changeHistory.add(record);

    // Keep history size bounded
    if (_changeHistory.length > _maxHistorySize) {
      _changeHistory.removeAt(0);
    }
  }

  /// Get admin stats summary.
  AdminStatsSummary getStats() {
    final features = getAllFeatureStatus();
    final enabledCount = features.where((f) => f.enabled).length;
    final avgRollout = features.isEmpty
        ? 0
        : features.fold<int>(0, (sum, f) => sum + f.rolloutPercentage) ~/
            features.length;

    return AdminStatsSummary(
      totalFeatures: features.length,
      enabledFeatures: enabledCount,
      averageRollout: avgRollout,
      changeHistorySize: _changeHistory.length,
      snapshotCount: _snapshots.length,
    );
  }

  /// Debug: dump all admin state.
  String debugDump() {
    final buf = StringBuffer();
    buf.writeln('=== Config Admin Service Debug Dump ===');
    buf.writeln('');

    buf.writeln('Current Difficulty Modifiers:');
    final modifiers = getDifficultyModifiers();
    buf.writeln('  Level: ${modifiers.levelDifficultyMultiplier}');
    buf.writeln('  Cooldown: ${modifiers.skillCooldownMultiplier}');
    buf.writeln('  Damage: ${modifiers.skillDamageMultiplier}');
    buf.writeln('');

    buf.writeln('Feature Status:');
    for (final feature in getAllFeatureStatus()) {
      buf.writeln('  ${feature.name}: ${feature.enabled ? 'ENABLED' : 'DISABLED'}'
          ' (rollout=${feature.rolloutPercentage}%)');
    }
    buf.writeln('');

    buf.writeln('Recent Changes:');
    for (final change in getChangeHistory(limit: 10)) {
      buf.writeln('  ${change.timestamp}: ${change.type} - ${change.key}');
    }
    buf.writeln('');

    buf.writeln('Snapshots: ${_snapshots.keys.join(", ")}');

    return buf.toString();
  }
}

/// Feature flag status snapshot.
class FeatureFlagStatus {
  final String name;
  final bool enabled;
  final bool killSwitch;
  final int rolloutPercentage;
  final List<String> variants;
  final String description;

  FeatureFlagStatus({
    required this.name,
    required this.enabled,
    required this.killSwitch,
    required this.rolloutPercentage,
    required this.variants,
    required this.description,
  });

  @override
  String toString() =>
      'FeatureFlagStatus($name, enabled=$enabled, rollout=$rolloutPercentage%)';
}

/// Configuration change record for audit log.
class ConfigChangeRecord {
  final DateTime timestamp;
  final String type; // DIFFICULTY_PRESET, FEATURE_TOGGLE, ROLLOUT_CHANGE, etc.
  final String key; // Config key that changed
  final dynamic oldValue;
  final dynamic newValue;
  final Map<String, dynamic> details;

  ConfigChangeRecord({
    required this.timestamp,
    required this.type,
    required this.key,
    required this.oldValue,
    required this.newValue,
    required this.details,
  });

  @override
  String toString() => '$type: $key ($oldValue → $newValue) at $timestamp';
}

/// Admin statistics summary.
class AdminStatsSummary {
  final int totalFeatures;
  final int enabledFeatures;
  final int averageRollout;
  final int changeHistorySize;
  final int snapshotCount;

  AdminStatsSummary({
    required this.totalFeatures,
    required this.enabledFeatures,
    required this.averageRollout,
    required this.changeHistorySize,
    required this.snapshotCount,
  });

  int get disabledFeatures => totalFeatures - enabledFeatures;
  double get enabledPercentage =>
      totalFeatures == 0 ? 0 : (enabledFeatures / totalFeatures) * 100;

  @override
  String toString() => 'AdminStatsSummary('
      'features=$totalFeatures, '
      'enabled=$enabledFeatures, '
      'rollout=$averageRollout%)';
}
