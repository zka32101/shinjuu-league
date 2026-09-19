import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shinjuu_league/services/admin_analytics_service.dart';
import 'package:shinjuu_league/services/analytics_filter_service.dart';

/// Analytics Filter State (Phase 37)
class FilteredAnalyticsState {
  final AnalyticsFilter currentFilter;
  final List<Map<String, dynamic>> filteredLogs;
  final Set<String> availableOperationTypes;
  final Set<String> availableUserIds;
  final Set<String> availableResourceTypes;
  final Map<String, dynamic> filteredStats;
  final bool isFiltering;

  const FilteredAnalyticsState({
    this.currentFilter = const AnalyticsFilter(),
    this.filteredLogs = const [],
    this.availableOperationTypes = const {},
    this.availableUserIds = const {},
    this.availableResourceTypes = const {},
    this.filteredStats = const {},
    this.isFiltering = false,
  });

  FilteredAnalyticsState copyWith({
    AnalyticsFilter? currentFilter,
    List<Map<String, dynamic>>? filteredLogs,
    Set<String>? availableOperationTypes,
    Set<String>? availableUserIds,
    Set<String>? availableResourceTypes,
    Map<String, dynamic>? filteredStats,
    bool? isFiltering,
  }) {
    return FilteredAnalyticsState(
      currentFilter: currentFilter ?? this.currentFilter,
      filteredLogs: filteredLogs ?? this.filteredLogs,
      availableOperationTypes: availableOperationTypes ?? this.availableOperationTypes,
      availableUserIds: availableUserIds ?? this.availableUserIds,
      availableResourceTypes: availableResourceTypes ?? this.availableResourceTypes,
      filteredStats: filteredStats ?? this.filteredStats,
      isFiltering: isFiltering ?? this.isFiltering,
    );
  }

  @override
  String toString() =>
      'FilteredAnalyticsState(filter=$currentFilter, logs=${filteredLogs.length}, isFiltering=$isFiltering)';
}

/// ViewModel for analytics filtering
class AnalyticsFilterViewModel extends StateNotifier<FilteredAnalyticsState> {
  final AdminAnalyticsService _analyticsService;
  List<Map<String, dynamic>> _allLogs = [];

  AnalyticsFilterViewModel({
    required AdminAnalyticsService analyticsService,
  })  : _analyticsService = analyticsService,
        super(const FilteredAnalyticsState());

  /// Load initial logs for filtering
  Future<void> loadLogsForFiltering({
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    try {
      state = state.copyWith(isFiltering: true);

      // Fetch all audit logs for the time period
      _allLogs = await _analyticsService.getAuditLog(
        startTime: startTime,
        endTime: endTime,
      ) as List<Map<String, dynamic>>;

      // Get available filter options
      final operationTypes = AnalyticsFilterService.getAvailableOperationTypes(_allLogs);
      final userIds = AnalyticsFilterService.getAvailableUserIds(_allLogs);
      final resourceTypes = AnalyticsFilterService.getAvailableResourceTypes(_allLogs);

      // Apply current filter
      final filteredLogs = AnalyticsFilterService.filterLogs(_allLogs, state.currentFilter);
      final stats = AnalyticsFilterService.calculateFilteredStats(filteredLogs);

      state = state.copyWith(
        filteredLogs: filteredLogs,
        availableOperationTypes: operationTypes,
        availableUserIds: userIds,
        availableResourceTypes: resourceTypes,
        filteredStats: stats,
        isFiltering: false,
      );
    } catch (e) {
      state = state.copyWith(isFiltering: false);
    }
  }

  /// Update operation type filter
  Future<void> filterByOperationType(String? operationType) async {
    final newFilter = state.currentFilter.copyWith(operationType: operationType);
    await _applyFilter(newFilter);
  }

  /// Update user ID filter
  Future<void> filterByUserId(String? userId) async {
    final newFilter = state.currentFilter.copyWith(userId: userId);
    await _applyFilter(newFilter);
  }

  /// Update resource type filter
  Future<void> filterByResourceType(String? resourceType) async {
    final newFilter = state.currentFilter.copyWith(resourceType: resourceType);
    await _applyFilter(newFilter);
  }

  /// Update search keyword
  Future<void> searchByKeyword(String? keyword) async {
    final newFilter = state.currentFilter.copyWith(searchKeyword: keyword);
    await _applyFilter(newFilter);
  }

  /// Update sort field
  Future<void> sortBy(SortField field) async {
    final newFilter = state.currentFilter.copyWith(sortBy: field);
    await _applyFilter(newFilter);
  }

  /// Toggle sort order
  Future<void> toggleSortOrder() async {
    final newOrder = state.currentFilter.sortOrder == SortOrder.ascending
        ? SortOrder.descending
        : SortOrder.ascending;
    final newFilter = state.currentFilter.copyWith(sortOrder: newOrder);
    await _applyFilter(newFilter);
  }

  /// Clear all filters
  Future<void> clearAllFilters() async {
    final newFilter = state.currentFilter.clearAll();
    await _applyFilter(newFilter);
  }

  /// Apply filter to logs
  Future<void> _applyFilter(AnalyticsFilter filter) async {
    try {
      state = state.copyWith(isFiltering: true, currentFilter: filter);

      final filteredLogs = AnalyticsFilterService.filterLogs(_allLogs, filter);
      final stats = AnalyticsFilterService.calculateFilteredStats(filteredLogs);

      state = state.copyWith(
        filteredLogs: filteredLogs,
        filteredStats: stats,
        isFiltering: false,
      );
    } catch (e) {
      state = state.copyWith(isFiltering: false);
    }
  }

  /// Get filter summary text
  String getFilterSummary() {
    final filter = state.currentFilter;
    final parts = <String>[];

    if (filter.operationType != null) {
      parts.add('Type: ${filter.operationType}');
    }
    if (filter.userId != null) {
      parts.add('User: ${filter.userId}');
    }
    if (filter.resourceType != null) {
      parts.add('Resource: ${filter.resourceType}');
    }
    if (filter.searchKeyword != null && filter.searchKeyword!.isNotEmpty) {
      parts.add('Search: "${filter.searchKeyword}"');
    }

    return parts.isEmpty ? 'No filters active' : parts.join(' • ');
  }

  /// Check if filters are active
  bool get hasActiveFilters => state.currentFilter.hasActiveFilters;

  /// Get filtered statistics
  int get filteredOperationCount =>
      (state.filteredStats['totalOperations'] as int?) ?? 0;

  int get filteredUniqueUsers =>
      (state.filteredStats['uniqueUsers'] as int?) ?? 0;

  int get filteredOperationTypes =>
      (state.filteredStats['operationTypes'] as int?) ?? 0;

  int get filteredResourceTypes =>
      (state.filteredStats['resourceTypes'] as int?) ?? 0;
}

/// Extension helper for AuditLoggerService compatibility
extension AuditLoggerServiceExtension on AdminAnalyticsService {
  /// Compatibility method for filter service
  Future<List<Map<String, dynamic>>> getAuditLog({
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    // This method would normally delegate to AuditLoggerService
    // For now, return empty list - implement based on actual service
    return [];
  }
}
