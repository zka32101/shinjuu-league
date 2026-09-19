import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shinjuu_league/services/admin_analytics_service.dart';

/// Admin Analytics ViewModel (Phase 35)
///
/// Manages analytics dashboard state with Riverpod StateNotifier.
/// Provides reactive access to admin operation metrics and trends.

// Analytics state container
class AnalyticsState {
  final Map<String, dynamic> dashboardSummary;
  final Map<int, int> hourlyTrend;
  final Map<String, int> dailyTrend;
  final Map<String, int> operationsByType;
  final Map<String, int> operationsByUser;
  final Map<String, dynamic> anomalies;
  final Map<String, dynamic> auditIntegrity;
  final bool isLoading;
  final String? error;

  AnalyticsState({
    this.dashboardSummary = const {},
    this.hourlyTrend = const {},
    this.dailyTrend = const {},
    this.operationsByType = const {},
    this.operationsByUser = const {},
    this.anomalies = const {},
    this.auditIntegrity = const {},
    this.isLoading = false,
    this.error,
  });

  AnalyticsState copyWith({
    Map<String, dynamic>? dashboardSummary,
    Map<int, int>? hourlyTrend,
    Map<String, int>? dailyTrend,
    Map<String, int>? operationsByType,
    Map<String, int>? operationsByUser,
    Map<String, dynamic>? anomalies,
    Map<String, dynamic>? auditIntegrity,
    bool? isLoading,
    String? error,
  }) {
    return AnalyticsState(
      dashboardSummary: dashboardSummary ?? this.dashboardSummary,
      hourlyTrend: hourlyTrend ?? this.hourlyTrend,
      dailyTrend: dailyTrend ?? this.dailyTrend,
      operationsByType: operationsByType ?? this.operationsByType,
      operationsByUser: operationsByUser ?? this.operationsByUser,
      anomalies: anomalies ?? this.anomalies,
      auditIntegrity: auditIntegrity ?? this.auditIntegrity,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  @override
  String toString() =>
      'AnalyticsState(ops=${dashboardSummary['summary']?['totalOperations']}, users=${dashboardSummary['summary']?['uniqueUsers']})';
}

/// StateNotifier for analytics state management
class AdminAnalyticsViewModel extends StateNotifier<AnalyticsState> {
  final AdminAnalyticsService _analyticsService;

  AdminAnalyticsViewModel({required AdminAnalyticsService analyticsService})
      : _analyticsService = analyticsService,
        super(AnalyticsState());

  /// Load all analytics data
  Future<void> loadAnalytics({
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Load dashboard summary
      final summary = await _analyticsService.getDashboardSummary(
        startTime: startTime,
        endTime: endTime,
      );

      // Load trends
      final hourlyTrend = await _analyticsService.getHourlyOperationTrend();
      final dailyTrend = await _analyticsService.getDailyOperationTrend();

      // Load operation breakdowns
      final operationsByType = await _analyticsService.getOperationsByType(
        startTime: startTime,
        endTime: endTime,
      );
      final operationsByUser = await _analyticsService.getOperationsByUser(
        startTime: startTime,
        endTime: endTime,
      );

      // Load anomalies
      final anomalies =
          await _analyticsService.detectHighFrequencyOperations();

      // Load audit integrity
      final auditIntegrity = await _analyticsService.getAuditTrailIntegrity(
        startTime: startTime,
        endTime: endTime,
      );

      state = state.copyWith(
        dashboardSummary: summary,
        hourlyTrend: hourlyTrend,
        dailyTrend: dailyTrend,
        operationsByType: operationsByType,
        operationsByUser: operationsByUser,
        anomalies: anomalies,
        auditIntegrity: auditIntegrity,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load analytics: $e',
      );
    }
  }

  /// Refresh analytics data
  Future<void> refresh({
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    await loadAnalytics(startTime: startTime, endTime: endTime);
  }

  /// Get total operation count
  int getTotalOperationCount() {
    return state.dashboardSummary['summary']?['totalOperations'] ?? 0;
  }

  /// Get unique user count
  int getUniqueUserCount() {
    return state.dashboardSummary['summary']?['uniqueUsers'] ?? 0;
  }

  /// Get operation type breakdown
  Map<String, int> getOperationTypeBreakdown() {
    return state.operationsByType;
  }

  /// Get operation user breakdown
  Map<String, int> getOperationUserBreakdown() {
    return state.operationsByUser;
  }

  /// Get hourly trend data
  Map<int, int> getHourlyTrend() {
    return state.hourlyTrend;
  }

  /// Get daily trend data
  Map<String, int> getDailyTrend() {
    return state.dailyTrend;
  }

  /// Get detected anomalies
  Map<String, dynamic> getAnomalies() {
    return state.anomalies;
  }

  /// Check if anomalies detected
  bool hasAnomalies() {
    return (state.anomalies['detectedAnomalies'] as bool?) ?? false;
  }

  /// Get affected users (if anomalies detected)
  List<Map<String, dynamic>> getAffectedUsers() {
    final affected = state.anomalies['affectedUsers'];
    if (affected is List) {
      return affected.cast<Map<String, dynamic>>();
    }
    return [];
  }

  /// Get audit trail integrity status
  Map<String, dynamic> getAuditIntegrity() {
    return state.auditIntegrity;
  }

  /// Check if audit trail is healthy
  bool isAuditTrailHealthy() {
    final status = state.auditIntegrity['status'] as String?;
    return status == 'HEALTHY';
  }

  /// Get audit integrity percentage
  double getIntegrityPercentage() {
    return (state.auditIntegrity['integrityPercentage'] as num?)?.toDouble() ??
        0.0;
  }

  /// Get most active admins
  List<Map<String, dynamic>> getMostActiveAdmins() {
    final mostActive = state.dashboardSummary['mostActiveAdmins'];
    if (mostActive is List) {
      return mostActive.cast<Map<String, dynamic>>();
    }
    return [];
  }

  /// Get top operations
  List<Map<String, dynamic>> getTopOperations() {
    final topOps = state.dashboardSummary['topOperations'];
    if (topOps is List) {
      return topOps.cast<Map<String, dynamic>>();
    }
    return [];
  }

  /// Get top resources
  List<Map<String, dynamic>> getTopResources() {
    final topRes = state.dashboardSummary['topResources'];
    if (topRes is List) {
      return topRes.cast<Map<String, dynamic>>();
    }
    return [];
  }

  /// Get operations per user (average)
  double getAverageOperationsPerUser() {
    final total = getTotalOperationCount();
    final users = getUniqueUserCount();
    if (users == 0) return 0.0;
    return total / users;
  }

  /// Get most common operation type
  String? getMostCommonOperationType() {
    if (state.operationsByType.isEmpty) return null;
    final entries = state.operationsByType.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries.first.key;
  }

  /// Get peak hour (hour with most operations)
  int? getPeakHour() {
    if (state.hourlyTrend.isEmpty) return null;
    final entries = state.hourlyTrend.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries.first.key;
  }

  /// Check if loading
  bool isLoading() {
    return state.isLoading;
  }

  /// Get error message
  String? getError() {
    return state.error;
  }
}
