import 'package:shinjuu_league/config/skill_progression_config.dart';
import 'package:shinjuu_league/services/config_admin_service.dart';
import 'package:shinjuu_league/services/feature_flags_service.dart';
import 'package:shinjuu_league/services/ab_test_coordinator.dart';

/// API service for web admin dashboard.
///
/// Provides JSON-serializable endpoints for web UI to:
/// - Query config state
/// - Trigger admin actions
/// - Stream real-time updates
/// - Retrieve analytics
class AdminApiService {
  final ConfigAdminService _adminService;

  AdminApiService({required ConfigAdminService adminService})
      : _adminService = adminService;

  /// Get current dashboard state (JSON).
  Map<String, dynamic> getDashboardState() {
    final stats = _adminService.getStats();
    final modifiers = _adminService.getDifficultyModifiers();
    final features = _adminService.getAllFeatureStatus();

    return {
      'timestamp': DateTime.now().toIso8601String(),
      'statistics': {
        'totalFeatures': stats.totalFeatures,
        'enabledFeatures': stats.enabledFeatures,
        'enabledPercentage': stats.enabledPercentage,
        'disabledFeatures': stats.disabledFeatures,
        'averageRollout': stats.averageRollout,
        'changeHistorySize': stats.changeHistorySize,
        'snapshotCount': stats.snapshotCount,
      },
      'difficulty': {
        'levelMultiplier': modifiers.levelDifficultyMultiplier,
        'cooldownMultiplier': modifiers.skillCooldownMultiplier,
        'damageMultiplier': modifiers.skillDamageMultiplier,
      },
      'features': features.map((f) => {
            'name': f.name,
            'enabled': f.enabled,
            'killSwitch': f.killSwitch,
            'rolloutPercentage': f.rolloutPercentage,
            'variants': f.variants,
            'description': f.description,
          }).toList(),
      'recentChanges': _adminService
          .getChangeHistory(limit: 10)
          .map((r) => _changeRecordToJson(r))
          .toList(),
    };
  }

  /// Get difficulty settings (JSON).
  Map<String, dynamic> getDifficultySettings() {
    final modifiers = _adminService.getDifficultyModifiers();

    return {
      'levelMultiplier': modifiers.levelDifficultyMultiplier,
      'cooldownMultiplier': modifiers.skillCooldownMultiplier,
      'damageMultiplier': modifiers.skillDamageMultiplier,
      'presets': {
        'easy': {
          'level': 0.7,
          'cooldown': 0.8,
          'damage': 0.9,
        },
        'normal': {
          'level': 1.0,
          'cooldown': 1.0,
          'damage': 1.0,
        },
        'hard': {
          'level': 1.3,
          'cooldown': 1.2,
          'damage': 1.1,
        },
      },
    };
  }

  /// Get all features (JSON).
  List<Map<String, dynamic>> getFeatures() {
    return _adminService.getAllFeatureStatus().map((f) => {
          'name': f.name,
          'enabled': f.enabled,
          'killSwitch': f.killSwitch,
          'rolloutPercentage': f.rolloutPercentage,
          'variants': f.variants,
          'description': f.description,
        }).toList();
  }

  /// Get feature details (JSON).
  Map<String, dynamic>? getFeature(String name) {
    final features = _adminService.getAllFeatureStatus();
    final feature = features.cast<FeatureFlagStatus?>().firstWhere(
      (f) => f?.name == name,
      orElse: () => null,
    );

    if (feature == null) return null;

    return {
      'name': feature.name,
      'enabled': feature.enabled,
      'killSwitch': feature.killSwitch,
      'rolloutPercentage': feature.rolloutPercentage,
      'variants': feature.variants,
      'description': feature.description,
    };
  }

  /// Get change history (JSON).
  List<Map<String, dynamic>> getChangeHistory({int limit = 50}) {
    return _adminService
        .getChangeHistory(limit: limit)
        .map((r) => _changeRecordToJson(r))
        .toList();
  }

  /// Get change history filtered by type (JSON).
  List<Map<String, dynamic>> getChangeHistoryByType(String type, {int limit = 50}) {
    return _adminService
        .getChangeHistory(limit: limit)
        .where((r) => r.type == type)
        .map((r) => _changeRecordToJson(r))
        .toList();
  }

  /// Get statistics summary (JSON).
  Map<String, dynamic> getStatistics() {
    final stats = _adminService.getStats();

    return {
      'timestamp': DateTime.now().toIso8601String(),
      'features': {
        'total': stats.totalFeatures,
        'enabled': stats.enabledFeatures,
        'disabled': stats.disabledFeatures,
        'enabledPercentage': stats.enabledPercentage,
      },
      'rollout': {
        'average': stats.averageRollout,
      },
      'history': {
        'size': stats.changeHistorySize,
      },
      'snapshots': {
        'count': stats.snapshotCount,
      },
    };
  }

  /// Get change type distribution (JSON) for charts.
  Map<String, int> getChangeTypeDistribution() {
    final history = _adminService.getChangeHistory(limit: 1000);
    final distribution = <String, int>{};

    for (final record in history) {
      distribution[record.type] = (distribution[record.type] ?? 0) + 1;
    }

    return distribution;
  }

  /// Get feature status timeline (JSON) for charts.
  List<Map<String, dynamic>> getFeatureStatusTimeline() {
    final history = _adminService.getChangeHistory(limit: 500);
    final timeline = <Map<String, dynamic>>[];

    // Group by hour
    final byHour = <String, List<ConfigChangeRecord>>{};
    for (final record in history) {
      final hour = record.timestamp.toIso8601String().substring(0, 13);
      (byHour[hour] ??= []).add(record);
    }

    // Build timeline
    for (final entry in byHour.entries) {
      timeline.add({
        'timestamp': '${entry.key}:00:00Z',
        'changes': entry.value.length,
        'byType': {
          for (final record in entry.value)
            record.type: (byHour[entry.key]
                    ?.where((r) => r.type == record.type)
                    .length ??
                0),
        },
      });
    }

    return timeline;
  }

  /// Apply difficulty preset (API endpoint).
  Future<bool> applyDifficultyPreset(String preset) async {
    try {
      await _adminService.applyDifficultyPreset(preset);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Set difficulty multiplier (API endpoint).
  Future<bool> setDifficultyMultiplier(String type, double value) async {
    try {
      await _adminService.setDifficultyMultiplier(type, value);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Set feature enabled state (API endpoint).
  Future<bool> setFeatureEnabled(String featureName, bool enabled) async {
    try {
      await _adminService.setFeatureEnabled(featureName, enabled);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Set feature rollout (API endpoint).
  Future<bool> setFeatureRollout(String featureName, int percentage) async {
    try {
      await _adminService.setFeatureRollout(featureName, percentage);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Create experiment (API endpoint).
  Future<bool> createExperiment(Map<String, dynamic> config) async {
    try {
      final exp = ABTestExperimentConfig(
        experimentId: config['experimentId'] as String,
        name: config['name'] as String,
        description: config['description'] as String,
        startDate: DateTime.parse(config['startDate'] as String),
        endDate: config['endDate'] != null
            ? DateTime.parse(config['endDate'] as String)
            : null,
        controlVariant: config['controlVariant'] as String,
        rolloutPercentage: config['rolloutPercentage'] as int,
        variantDistribution:
            Map<String, int>.from(config['variantDistribution'] as Map),
      );

      await _adminService.createExperiment(exp);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Update experiment rollout (API endpoint).
  Future<bool> updateExperimentRollout(
    String experimentId,
    int percentage,
  ) async {
    try {
      await _adminService.updateExperimentRollout(experimentId, percentage);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Rollback to snapshot (API endpoint).
  Future<bool> rollbackToSnapshot(String name) async {
    try {
      await _adminService.rollbackToSnapshot(name);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Health check (JSON).
  Map<String, dynamic> getHealthCheck() {
    return {
      'timestamp': DateTime.now().toIso8601String(),
      'status': 'healthy',
      'version': '1.0',
      'features': {
        'difficulty': true,
        'featureFlags': true,
        'experiments': true,
        'auditLog': true,
        'snapshots': true,
      },
    };
  }

  /// Convert ConfigChangeRecord to JSON.
  static Map<String, dynamic> _changeRecordToJson(ConfigChangeRecord record) {
    return {
      'timestamp': record.timestamp.toIso8601String(),
      'type': record.type,
      'key': record.key,
      'oldValue': record.oldValue?.toString(),
      'newValue': record.newValue?.toString(),
      'details': record.details,
    };
  }
}
