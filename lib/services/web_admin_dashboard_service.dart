import 'dart:async';
import 'package:shinjuu_league/services/admin_api_service.dart';
import 'package:shinjuu_league/services/config_admin_service.dart';
import 'package:shinjuu_league/services/audit_logger_service.dart';
import 'package:shinjuu_league/services/auth_service.dart';

/// Real-time web dashboard service.
///
/// Provides reactive dashboard state with periodic polling of AdminApiService.
/// Designed to feed Flutter web UI with live updates.
/// Includes comprehensive audit logging of all admin operations.
class WebAdminDashboardService {
  final AdminApiService _apiService;
  final int _pollIntervalMs;
  final AuditLoggerService? _auditLogger;
  final AuthService? _authService;

  // State streams
  late final StreamController<DashboardSnapshot> _dashboardController =
      StreamController<DashboardSnapshot>.broadcast();
  late final StreamController<Map<String, dynamic>> _statsController =
      StreamController<Map<String, dynamic>>.broadcast();
  late final StreamController<List<Map<String, dynamic>>>
      _changeHistoryController =
      StreamController<List<Map<String, dynamic>>>.broadcast();
  late final StreamController<DashboardError> _errorController =
      StreamController<DashboardError>.broadcast();

  Timer? _pollTimer;
  bool _isPolling = false;

  WebAdminDashboardService({
    required AdminApiService apiService,
    int pollIntervalMs = 5000, // 5 second default
    AuditLoggerService? auditLogger,
    AuthService? authService,
  })  : _apiService = apiService,
        _pollIntervalMs = pollIntervalMs,
        _auditLogger = auditLogger,
        _authService = authService;

  // Public streams
  Stream<DashboardSnapshot> get onDashboardUpdate =>
      _dashboardController.stream;
  Stream<Map<String, dynamic>> get onStatsUpdate => _statsController.stream;
  Stream<List<Map<String, dynamic>>> get onChangeHistoryUpdate =>
      _changeHistoryController.stream;
  Stream<DashboardError> get onError => _errorController.stream;

  bool get isPolling => _isPolling;

  /// Start periodic dashboard polling.
  void startPolling() {
    if (_isPolling) return;

    _isPolling = true;
    _pollOnce(); // Poll immediately
    _pollTimer = Timer.periodic(Duration(milliseconds: _pollIntervalMs), (_) {
      _pollOnce();
    });
  }

  /// Stop polling.
  void stopPolling() {
    if (!_isPolling) return;

    _isPolling = false;
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  /// Helper method to log admin operations.
  Future<void> _logOperation({
    required String action,
    required String resourceType,
    required String resourceId,
    dynamic oldValue,
    dynamic newValue,
    String? reason,
  }) async {
    if (_auditLogger == null || _authService == null) {
      return; // Audit logging not configured
    }

    try {
      final userId = _authService!.currentUser?.uid ?? 'unknown';
      await _auditLogger!.logChange(
        userId: userId,
        action: action,
        resourceType: resourceType,
        resourceId: resourceId,
        details: {
          if (oldValue != null) 'oldValue': oldValue.toString(),
          if (newValue != null) 'newValue': newValue.toString(),
          if (reason != null) 'reason': reason,
        },
      );
    } catch (e) {
      // Log error but don't fail the operation
      print('Error logging admin operation: $e');
    }
  }

  /// Poll dashboard state once.
  Future<void> _pollOnce() async {
    try {
      // Get dashboard state
      final dashboardState = _apiService.getDashboardState();
      final snapshot = DashboardSnapshot(
        timestamp: DateTime.now(),
        statistics: dashboardState['statistics'] as Map<String, dynamic>? ?? {},
        difficulty:
            dashboardState['difficulty'] as Map<String, dynamic>? ?? {},
        features:
            (dashboardState['features'] as List?)?.cast<Map<String, dynamic>>() ??
                [],
        recentChanges: (dashboardState['recentChanges'] as List?)
                ?.cast<Map<String, dynamic>>() ??
            [],
      );
      _dashboardController.add(snapshot);

      // Get statistics
      final stats = _apiService.getStatistics();
      _statsController.add(stats);

      // Get change history
      final history = _apiService.getChangeHistory(limit: 50);
      _changeHistoryController.add(history);
    } catch (e) {
      _errorController.add(DashboardError(
        timestamp: DateTime.now(),
        message: 'Failed to poll dashboard: $e',
        stackTrace: e.toString(),
      ));
    }
  }

  /// Get current dashboard state (non-streaming).
  DashboardSnapshot getDashboardState() {
    final dashboardState = _apiService.getDashboardState();
    return DashboardSnapshot(
      timestamp: DateTime.now(),
      statistics: dashboardState['statistics'] as Map<String, dynamic>? ?? {},
      difficulty: dashboardState['difficulty'] as Map<String, dynamic>? ?? {},
      features:
          (dashboardState['features'] as List?)?.cast<Map<String, dynamic>>() ??
              [],
      recentChanges: (dashboardState['recentChanges'] as List?)
              ?.cast<Map<String, dynamic>>() ??
          [],
    );
  }

  /// Get all features.
  List<FeatureOverview> getFeatures() {
    final features = _apiService.getFeatures();
    return features
        .map((f) => FeatureOverview(
              name: f['name'] as String? ?? '',
              enabled: f['enabled'] as bool? ?? false,
              killSwitch: f['killSwitch'] as bool? ?? false,
              rolloutPercentage: f['rolloutPercentage'] as int? ?? 0,
              variants: (f['variants'] as List?)?.cast<String>() ?? [],
              description: f['description'] as String? ?? '',
            ))
        .toList();
  }

  /// Get difficulty settings.
  Map<String, dynamic> getDifficultySettings() {
    return _apiService.getDifficultySettings();
  }

  /// Apply difficulty preset.
  Future<bool> applyDifficultyPreset(String preset) async {
    try {
      final result = await _apiService.applyDifficultyPreset(preset);
      if (result) {
        await _logOperation(
          action: 'APPLY_PRESET',
          resourceType: 'difficulty_preset',
          resourceId: preset,
          reason: 'Admin applied difficulty preset',
        );
        await _pollOnce(); // Refresh dashboard
      }
      return result;
    } catch (e) {
      _errorController.add(DashboardError(
        timestamp: DateTime.now(),
        message: 'Failed to apply difficulty preset: $e',
        stackTrace: e.toString(),
      ));
      return false;
    }
  }

  /// Set difficulty multiplier.
  Future<bool> setDifficultyMultiplier(String type, double value) async {
    try {
      final result =
          await _apiService.setDifficultyMultiplier(type, value);
      if (result) {
        await _logOperation(
          action: 'SET_MULTIPLIER',
          resourceType: 'difficulty_multiplier',
          resourceId: type,
          newValue: value,
          reason: 'Admin updated difficulty multiplier',
        );
        await _pollOnce(); // Refresh dashboard
      }
      return result;
    } catch (e) {
      _errorController.add(DashboardError(
        timestamp: DateTime.now(),
        message: 'Failed to set difficulty multiplier: $e',
        stackTrace: e.toString(),
      ));
      return false;
    }
  }

  /// Set feature enabled.
  Future<bool> setFeatureEnabled(String featureName, bool enabled) async {
    try {
      final result = await _apiService.setFeatureEnabled(featureName, enabled);
      if (result) {
        await _logOperation(
          action: 'SET_ENABLED',
          resourceType: 'feature',
          resourceId: featureName,
          newValue: enabled,
          reason: 'Admin toggled feature enabled status',
        );
        await _pollOnce(); // Refresh dashboard
      }
      return result;
    } catch (e) {
      _errorController.add(DashboardError(
        timestamp: DateTime.now(),
        message: 'Failed to set feature enabled: $e',
        stackTrace: e.toString(),
      ));
      return false;
    }
  }

  /// Set feature rollout.
  Future<bool> setFeatureRollout(String featureName, int percentage) async {
    try {
      final result =
          await _apiService.setFeatureRollout(featureName, percentage);
      if (result) {
        await _logOperation(
          action: 'SET_ROLLOUT',
          resourceType: 'feature_rollout',
          resourceId: featureName,
          newValue: percentage,
          reason: 'Admin adjusted feature rollout percentage',
        );
        await _pollOnce(); // Refresh dashboard
      }
      return result;
    } catch (e) {
      _errorController.add(DashboardError(
        timestamp: DateTime.now(),
        message: 'Failed to set feature rollout: $e',
        stackTrace: e.toString(),
      ));
      return false;
    }
  }

  /// Create experiment.
  Future<bool> createExperiment(Map<String, dynamic> config) async {
    try {
      final result = await _apiService.createExperiment(config);
      if (result) {
        final experimentId = config['experimentId']?.toString() ?? 'unknown';
        await _logOperation(
          action: 'CREATE_EXPERIMENT',
          resourceType: 'experiment',
          resourceId: experimentId,
          newValue: config,
          reason: 'Admin created new A/B experiment',
        );
        await _pollOnce(); // Refresh dashboard
      }
      return result;
    } catch (e) {
      _errorController.add(DashboardError(
        timestamp: DateTime.now(),
        message: 'Failed to create experiment: $e',
        stackTrace: e.toString(),
      ));
      return false;
    }
  }

  /// Update experiment rollout.
  Future<bool> updateExperimentRollout(
    String experimentId,
    int percentage,
  ) async {
    try {
      final result =
          await _apiService.updateExperimentRollout(experimentId, percentage);
      if (result) {
        await _logOperation(
          action: 'UPDATE_ROLLOUT',
          resourceType: 'experiment_rollout',
          resourceId: experimentId,
          newValue: percentage,
          reason: 'Admin adjusted experiment rollout percentage',
        );
        await _pollOnce(); // Refresh dashboard
      }
      return result;
    } catch (e) {
      _errorController.add(DashboardError(
        timestamp: DateTime.now(),
        message: 'Failed to update experiment rollout: $e',
        stackTrace: e.toString(),
      ));
      return false;
    }
  }

  /// Rollback to snapshot.
  Future<bool> rollbackToSnapshot(String name) async {
    try {
      final result = await _apiService.rollbackToSnapshot(name);
      if (result) {
        await _logOperation(
          action: 'ROLLBACK_SNAPSHOT',
          resourceType: 'snapshot',
          resourceId: name,
          reason: 'Admin restored configuration from snapshot',
        );
        await _pollOnce(); // Refresh dashboard
      }
      return result;
    } catch (e) {
      _errorController.add(DashboardError(
        timestamp: DateTime.now(),
        message: 'Failed to rollback to snapshot: $e',
        stackTrace: e.toString(),
      ));
      return false;
    }
  }

  /// Get health check.
  Map<String, dynamic> getHealthCheck() {
    return _apiService.getHealthCheck();
  }

  /// Cleanup resources.
  void dispose() {
    stopPolling();
    _dashboardController.close();
    _statsController.close();
    _changeHistoryController.close();
    _errorController.close();
  }
}

/// Dashboard snapshot (immutable data).
class DashboardSnapshot {
  final DateTime timestamp;
  final Map<String, dynamic> statistics;
  final Map<String, dynamic> difficulty;
  final List<Map<String, dynamic>> features;
  final List<Map<String, dynamic>> recentChanges;

  DashboardSnapshot({
    required this.timestamp,
    required this.statistics,
    required this.difficulty,
    required this.features,
    required this.recentChanges,
  });

  @override
  String toString() =>
      'DashboardSnapshot(features=${features.length}, changes=${recentChanges.length})';
}

/// Feature overview for dashboard.
class FeatureOverview {
  final String name;
  final bool enabled;
  final bool killSwitch;
  final int rolloutPercentage;
  final List<String> variants;
  final String description;

  FeatureOverview({
    required this.name,
    required this.enabled,
    required this.killSwitch,
    required this.rolloutPercentage,
    required this.variants,
    required this.description,
  });

  @override
  String toString() => 'FeatureOverview($name, enabled=$enabled, '
      'rollout=$rolloutPercentage%)';
}

/// Dashboard error event.
class DashboardError {
  final DateTime timestamp;
  final String message;
  final String stackTrace;

  DashboardError({
    required this.timestamp,
    required this.message,
    required this.stackTrace,
  });

  @override
  String toString() => 'DashboardError: $message';
}
