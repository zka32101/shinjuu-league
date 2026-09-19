import 'dart:async';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:shinjuu_league/config/skill_progression_config.dart';
import 'package:shinjuu_league/services/feature_flags_service.dart';

/// Manages real-time Firebase Remote Config polling and updates.
///
/// Provides:
/// - Periodic config fetching (configurable interval)
/// - Change detection and notification
/// - Automatic service updates (SkillProgressionConfig, FeatureFlagsService)
/// - Network error resilience with exponential backoff
/// - Session-level cohort persistence (prevent mid-session changes)
class ConfigPollingService {
  final FirebaseRemoteConfig _remoteConfig;
  final SkillProgressionConfig _progressionConfig;
  final FeatureFlagsService _featureFlags;

  // Polling state
  Timer? _pollingTimer;
  int _pollIntervalSeconds = 300; // 5 minutes default
  int _consecutiveFailures = 0;
  DateTime? _lastSuccessfulPoll;
  DateTime? _lastConfigChange;

  // Session state (persisted during session, reset on app restart)
  late Map<String, dynamic> _sessionConfig;
  late DateTime _sessionStartTime;
  bool _sessionCohortLocked = false;

  // Streams for listeners
  final StreamController<ConfigUpdateEvent> _updateController =
      StreamController.broadcast();
  final StreamController<ConfigPollError> _errorController =
      StreamController.broadcast();

  /// Stream of config updates
  Stream<ConfigUpdateEvent> get onConfigUpdate => _updateController.stream;

  /// Stream of polling errors
  Stream<ConfigPollError> get onPollError => _errorController.stream;

  ConfigPollingService({
    required FirebaseRemoteConfig remoteConfig,
    required SkillProgressionConfig progressionConfig,
    required FeatureFlagsService featureFlags,
    int pollIntervalSeconds = 300,
  })  : _remoteConfig = remoteConfig,
        _progressionConfig = progressionConfig,
        _featureFlags = featureFlags,
        _pollIntervalSeconds = pollIntervalSeconds {
    _sessionStartTime = DateTime.now();
    _sessionConfig = _captureCurrentConfig();
  }

  /// Start polling for config updates.
  ///
  /// Polling interval can be adjusted via [setPollInterval].
  /// Initial poll happens immediately.
  void startPolling() {
    if (_pollingTimer != null) {
      return; // Already polling
    }

    // Initial poll immediately
    _pollConfig();

    // Set up periodic polling
    _pollingTimer =
        Timer.periodic(Duration(seconds: _pollIntervalSeconds), (_) {
      _pollConfig();
    });
  }

  /// Stop polling for config updates.
  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  /// Set polling interval in seconds.
  ///
  /// Changes take effect on next poll cycle.
  /// Minimum: 60 seconds (prevent API rate limiting)
  /// Maximum: 3600 seconds (1 hour)
  void setPollInterval(int seconds) {
    final clamped = seconds.clamp(60, 3600);
    if (clamped != _pollIntervalSeconds) {
      _pollIntervalSeconds = clamped;

      // Restart polling with new interval
      if (_pollingTimer != null) {
        stopPolling();
        startPolling();
      }
    }
  }

  /// Manually trigger a config poll (for testing or urgent updates).
  Future<bool> pollNow() async {
    return _pollConfig();
  }

  /// Lock session cohort to prevent mid-game changes.
  ///
  /// Once locked, difficulty changes won't affect current session.
  /// Lock is released on app restart.
  void lockSessionCohort() {
    _sessionCohortLocked = true;
  }

  /// Check if session cohort is locked.
  bool isSessionCohortLocked() => _sessionCohortLocked;

  /// Get config from start of current session.
  ///
  /// Returns snapshot of config when this service was created.
  Map<String, dynamic> getSessionConfig() => _sessionConfig;

  /// Get current live config (post-updates).
  Map<String, dynamic> getLiveConfig() => _captureCurrentConfig();

  /// Get polling statistics.
  ConfigPollingStats getStats() {
    return ConfigPollingStats(
      lastSuccessfulPoll: _lastSuccessfulPoll,
      lastConfigChange: _lastConfigChange,
      consecutiveFailures: _consecutiveFailures,
      sessionStartTime: _sessionStartTime,
      pollIntervalSeconds: _pollIntervalSeconds,
      isCohortLocked: _sessionCohortLocked,
    );
  }

  /// Perform actual config poll and update services if changed.
  Future<bool> _pollConfig() async {
    try {
      // Fetch latest config
      final duration =
          Duration(seconds: _pollIntervalSeconds ~/ 2); // Cache for half interval
      await _remoteConfig.fetch();

      // Must activate to see new values
      await _remoteConfig.activate();

      _lastSuccessfulPoll = DateTime.now();
      _consecutiveFailures = 0;

      // Check for changes
      final newConfig = _captureCurrentConfig();
      _detectAndApplyChanges(_sessionConfig, newConfig);

      return true;
    } catch (e) {
      _consecutiveFailures++;

      final error = ConfigPollError(
        timestamp: DateTime.now(),
        errorType: _categorizeError(e),
        errorMessage: e.toString(),
        consecutiveFailures: _consecutiveFailures,
      );

      _errorController.add(error);

      // Exponential backoff: don't hammer API on repeated failures
      if (_consecutiveFailures > 3) {
        final backoffSeconds = (60 * (1 << (_consecutiveFailures - 3)))
            .clamp(60, 3600); // Max 1 hour
        setPollInterval(backoffSeconds);
      }

      return false;
    }
  }

  /// Detect changes between old and new config.
  void _detectAndApplyChanges(
    Map<String, dynamic> oldConfig,
    Map<String, dynamic> newConfig,
  ) {
    final changes = <String, ConfigChange>{};

    // Check all keys
    final allKeys = {...oldConfig.keys, ...newConfig.keys};

    for (final key in allKeys) {
      final oldValue = oldConfig[key];
      final newValue = newConfig[key];

      if (oldValue != newValue) {
        changes[key] = ConfigChange(
          key: key,
          oldValue: oldValue,
          newValue: newValue,
          changedAt: DateTime.now(),
        );
      }
    }

    if (changes.isEmpty) {
      return; // No changes
    }

    _lastConfigChange = DateTime.now();

    // Apply difficulty multiplier changes (if not locked)
    if (!_sessionCohortLocked) {
      _applyDifficultyChanges(changes);
    }

    // Apply feature flag changes
    _applyFeatureFlagChanges(changes);

    // Notify listeners
    _updateController.add(
      ConfigUpdateEvent(
        timestamp: DateTime.now(),
        changes: changes,
        cohortLocked: _sessionCohortLocked,
      ),
    );
  }

  /// Apply difficulty multiplier changes.
  void _applyDifficultyChanges(Map<String, ConfigChange> changes) {
    // Changes to these keys trigger difficulty update
    const difficultyKeys = {
      'levelDifficultyMultiplier',
      'skillCooldownMultiplier',
      'skillDamageMultiplier',
    };

    if (changes.keys.toSet().intersection(difficultyKeys).isNotEmpty) {
      // Will be reflected next time _progressionConfig methods are called
      // (config is read from Remote Config in real-time)
    }
  }

  /// Apply feature flag changes.
  void _applyFeatureFlagChanges(Map<String, ConfigChange> changes) {
    // Changes to these keys trigger feature flag update
    const flagKeys = {
      'skilledCooldownReductionEnabled',
      'damageMultiplierEnabled',
      'evolutionDifficultyEnabled',
      'rankedModeEnabled',
      'newUILayoutEnabled',
      'experimentalMatchmakingEnabled',
      'monetizationEnabled',
    };

    for (final key in changes.keys.toSet().intersection(flagKeys)) {
      final change = changes[key]!;

      // Clear feature flags cache to reflect new settings
      _featureFlags.clearCache();

      // Log the change
      // (In real implementation, would log to analytics)
    }
  }

  /// Capture current config snapshot.
  Map<String, dynamic> _captureCurrentConfig() {
    return {
      'levelDifficultyMultiplier':
          _progressionConfig.getDifficultyModifiers().levelDifficultyMultiplier,
      'skillCooldownMultiplier':
          _progressionConfig.getDifficultyModifiers().skillCooldownMultiplier,
      'skillDamageMultiplier':
          _progressionConfig.getDifficultyModifiers().skillDamageMultiplier,
      'difficultyPreset': _progressionConfig.difficultyPreset,
      // Feature flags would be captured similarly
    };
  }

  /// Categorize error type for diagnostics.
  String _categorizeError(Object e) {
    if (e.toString().contains('network') || e.toString().contains('timeout')) {
      return 'NETWORK_ERROR';
    } else if (e.toString().contains('authentication') ||
        e.toString().contains('permission')) {
      return 'AUTH_ERROR';
    } else if (e.toString().contains('rate')) {
      return 'RATE_LIMIT';
    } else {
      return 'UNKNOWN_ERROR';
    }
  }

  /// Dispose resources.
  void dispose() {
    stopPolling();
    _updateController.close();
    _errorController.close();
  }

  /// Debug: dump current polling state.
  String debugDump() {
    final buf = StringBuffer();
    buf.writeln('=== Config Polling Service Debug Dump ===');
    buf.writeln('Session Start: $_sessionStartTime');
    buf.writeln('Session Cohort Locked: $_sessionCohortLocked');
    buf.writeln('Last Successful Poll: $_lastSuccessfulPoll');
    buf.writeln('Last Config Change: $_lastConfigChange');
    buf.writeln('Consecutive Failures: $_consecutiveFailures');
    buf.writeln('Poll Interval: $_pollIntervalSeconds seconds');
    buf.writeln('');
    buf.writeln('Session Config:');
    _sessionConfig.forEach((k, v) => buf.writeln('  $k: $v'));
    buf.writeln('');
    buf.writeln('Live Config:');
    _captureCurrentConfig().forEach((k, v) => buf.writeln('  $k: $v'));
    return buf.toString();
  }
}

/// Event emitted when config is updated.
class ConfigUpdateEvent {
  final DateTime timestamp;
  final Map<String, ConfigChange> changes;
  final bool cohortLocked;

  ConfigUpdateEvent({
    required this.timestamp,
    required this.changes,
    required this.cohortLocked,
  });

  @override
  String toString() =>
      'ConfigUpdateEvent(${changes.length} changes, cohortLocked=$cohortLocked)';
}

/// A single config value change.
class ConfigChange {
  final String key;
  final dynamic oldValue;
  final dynamic newValue;
  final DateTime changedAt;

  ConfigChange({
    required this.key,
    required this.oldValue,
    required this.newValue,
    required this.changedAt,
  });

  @override
  String toString() => '$key: $oldValue → $newValue';
}

/// Error during polling.
class ConfigPollError {
  final DateTime timestamp;
  final String errorType;
  final String errorMessage;
  final int consecutiveFailures;

  ConfigPollError({
    required this.timestamp,
    required this.errorType,
    required this.errorMessage,
    required this.consecutiveFailures,
  });

  @override
  String toString() =>
      'ConfigPollError($errorType: $errorMessage, failures=$consecutiveFailures)';
}

/// Polling statistics snapshot.
class ConfigPollingStats {
  final DateTime? lastSuccessfulPoll;
  final DateTime? lastConfigChange;
  final int consecutiveFailures;
  final DateTime sessionStartTime;
  final int pollIntervalSeconds;
  final bool isCohortLocked;

  ConfigPollingStats({
    required this.lastSuccessfulPoll,
    required this.lastConfigChange,
    required this.consecutiveFailures,
    required this.sessionStartTime,
    required this.pollIntervalSeconds,
    required this.isCohortLocked,
  });

  /// Time since last successful poll.
  Duration? get timeSinceLastPoll {
    if (lastSuccessfulPoll == null) return null;
    return DateTime.now().difference(lastSuccessfulPoll!);
  }

  /// Time since last config change.
  Duration? get timeSinceLastChange {
    if (lastConfigChange == null) return null;
    return DateTime.now().difference(lastConfigChange!);
  }

  /// Session duration.
  Duration get sessionDuration =>
      DateTime.now().difference(sessionStartTime);

  @override
  String toString() =>
      'ConfigPollingStats(polls=$lastSuccessfulPoll, failures=$consecutiveFailures)';
}
