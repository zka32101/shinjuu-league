import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shinjuu_league/services/config_polling_service.dart';

/// Riverpod state notifier for config updates.
///
/// Listens to ConfigPollingService and notifies consumers of changes.
/// Can trigger UI rebuilds or game logic updates based on config changes.
class ConfigUpdateNotifier extends StateNotifier<ConfigUpdateState> {
  final ConfigPollingService _pollingService;

  ConfigUpdateNotifier(this._pollingService)
      : super(ConfigUpdateState.initial()) {
    _setupListeners();
  }

  /// Setup listeners for config changes and errors.
  void _setupListeners() {
    _pollingService.onConfigUpdate.listen((event) {
      state = ConfigUpdateState.updated(
        event: event,
        timestamp: DateTime.now(),
      );
    });

    _pollingService.onPollError.listen((error) {
      state = ConfigUpdateState.error(
        error: error,
        timestamp: DateTime.now(),
      );
    });
  }

  /// Start polling for config updates.
  void startPolling() {
    _pollingService.startPolling();
    state = state.copyWith(isPolling: true);
  }

  /// Stop polling for config updates.
  void stopPolling() {
    _pollingService.stopPolling();
    state = state.copyWith(isPolling: false);
  }

  /// Set polling interval.
  void setPollInterval(int seconds) {
    _pollingService.setPollInterval(seconds);
    state = state.copyWith(pollIntervalSeconds: seconds);
  }

  /// Lock session cohort.
  void lockSessionCohort() {
    _pollingService.lockSessionCohort();
    state = state.copyWith(sessionCohortLocked: true);
  }

  /// Manually trigger a poll.
  Future<void> pollNow() async {
    final success = await _pollingService.pollNow();
    if (success) {
      state = state.copyWith(lastManualPollSucceeded: true);
    } else {
      state = state.copyWith(lastManualPollSucceeded: false);
    }
  }
}

/// State of config updates and polling.
class ConfigUpdateState {
  final bool isPolling;
  final bool sessionCohortLocked;
  final int pollIntervalSeconds;
  final ConfigUpdateEvent? lastUpdateEvent;
  final ConfigPollError? lastError;
  final DateTime? lastUpdateTime;
  final DateTime? lastErrorTime;
  final bool lastManualPollSucceeded;

  ConfigUpdateState({
    required this.isPolling,
    required this.sessionCohortLocked,
    required this.pollIntervalSeconds,
    this.lastUpdateEvent,
    this.lastError,
    this.lastUpdateTime,
    this.lastErrorTime,
    this.lastManualPollSucceeded = false,
  });

  /// Initial state (not polling, no events).
  factory ConfigUpdateState.initial() {
    return ConfigUpdateState(
      isPolling: false,
      sessionCohortLocked: false,
      pollIntervalSeconds: 300,
    );
  }

  /// State after successful update.
  factory ConfigUpdateState.updated({
    required ConfigUpdateEvent event,
    required DateTime timestamp,
  }) {
    return ConfigUpdateState(
      isPolling: true,
      sessionCohortLocked: false,
      pollIntervalSeconds: 300,
      lastUpdateEvent: event,
      lastUpdateTime: timestamp,
    );
  }

  /// State after error.
  factory ConfigUpdateState.error({
    required ConfigPollError error,
    required DateTime timestamp,
  }) {
    return ConfigUpdateState(
      isPolling: true,
      sessionCohortLocked: false,
      pollIntervalSeconds: 300,
      lastError: error,
      lastErrorTime: timestamp,
    );
  }

  /// Copy with modifications.
  ConfigUpdateState copyWith({
    bool? isPolling,
    bool? sessionCohortLocked,
    int? pollIntervalSeconds,
    ConfigUpdateEvent? lastUpdateEvent,
    ConfigPollError? lastError,
    DateTime? lastUpdateTime,
    DateTime? lastErrorTime,
    bool? lastManualPollSucceeded,
  }) {
    return ConfigUpdateState(
      isPolling: isPolling ?? this.isPolling,
      sessionCohortLocked: sessionCohortLocked ?? this.sessionCohortLocked,
      pollIntervalSeconds: pollIntervalSeconds ?? this.pollIntervalSeconds,
      lastUpdateEvent: lastUpdateEvent ?? this.lastUpdateEvent,
      lastError: lastError ?? this.lastError,
      lastUpdateTime: lastUpdateTime ?? this.lastUpdateTime,
      lastErrorTime: lastErrorTime ?? this.lastErrorTime,
      lastManualPollSucceeded:
          lastManualPollSucceeded ?? this.lastManualPollSucceeded,
    );
  }

  /// Check if there are pending updates.
  bool get hasPendingUpdates => lastUpdateEvent != null && !sessionCohortLocked;

  /// Check if polling is healthy (no recent errors).
  bool get isHealthy {
    if (lastError == null) return true;
    if (lastErrorTime == null) return true;

    final timeSinceError = DateTime.now().difference(lastErrorTime!);
    return timeSinceError.inSeconds > 300; // 5 minutes grace period
  }

  /// Get status message for UI display.
  String getStatusMessage() {
    if (!isPolling) return 'Config polling stopped';
    if (isHealthy) return 'Config synced';
    if (lastError != null) return 'Config sync error: ${lastError!.errorType}';
    return 'Polling for config updates...';
  }

  @override
  String toString() =>
      'ConfigUpdateState(polling=$isPolling, cohortLocked=$sessionCohortLocked, '
      'healthy=$isHealthy)';
}
