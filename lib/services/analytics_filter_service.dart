/// Analytics Filter Service (Phase 37)
///
/// Provides filtering and searching capabilities for admin analytics data:
/// - Filter by operation type (CREATE, UPDATE, DELETE, etc.)
/// - Filter by user ID or email
/// - Filter by resource type
/// - Search by keyword in action/details
/// - Combine multiple filters (AND logic)
/// - Sort results by various fields

class AnalyticsFilter {
  final String? operationType;
  final String? userId;
  final String? resourceType;
  final String? searchKeyword;
  final SortField sortBy;
  final SortOrder sortOrder;

  const AnalyticsFilter({
    this.operationType,
    this.userId,
    this.resourceType,
    this.searchKeyword,
    this.sortBy = SortField.timestamp,
    this.sortOrder = SortOrder.descending,
  });

  /// Create a copy with modified fields
  AnalyticsFilter copyWith({
    String? operationType,
    String? userId,
    String? resourceType,
    String? searchKeyword,
    SortField? sortBy,
    SortOrder? sortOrder,
  }) {
    return AnalyticsFilter(
      operationType: operationType ?? this.operationType,
      userId: userId ?? this.userId,
      resourceType: resourceType ?? this.resourceType,
      searchKeyword: searchKeyword ?? this.searchKeyword,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  /// Check if any filters are active
  bool get hasActiveFilters =>
      operationType != null ||
      userId != null ||
      resourceType != null ||
      searchKeyword != null;

  /// Clear all filters
  AnalyticsFilter clearAll() {
    return const AnalyticsFilter();
  }

  @override
  String toString() =>
      'AnalyticsFilter(type=$operationType, user=$userId, resource=$resourceType, search=$searchKeyword, sort=$sortBy-$sortOrder)';
}

enum SortField {
  timestamp,
  operationType,
  userId,
  resourceType,
  operationCount,
}

enum SortOrder {
  ascending,
  descending,
}

class AnalyticsFilterService {
  /// Filter a list of audit logs by criteria
  static List<Map<String, dynamic>> filterLogs(
    List<Map<String, dynamic>> logs,
    AnalyticsFilter filter,
  ) {
    var filtered = logs;

    // Apply operation type filter
    if (filter.operationType != null) {
      filtered = filtered
          .where((log) => log['action'] == filter.operationType)
          .toList();
    }

    // Apply user ID filter
    if (filter.userId != null) {
      filtered = filtered
          .where((log) => log['userId'] == filter.userId)
          .toList();
    }

    // Apply resource type filter
    if (filter.resourceType != null) {
      filtered = filtered
          .where((log) => log['resourceType'] == filter.resourceType)
          .toList();
    }

    // Apply keyword search
    if (filter.searchKeyword != null && filter.searchKeyword!.isNotEmpty) {
      final keyword = filter.searchKeyword!.toLowerCase();
      filtered = filtered.where((log) {
        final action = (log['action'] as String?)?.toLowerCase() ?? '';
        final userId = (log['userId'] as String?)?.toLowerCase() ?? '';
        final resourceType = (log['resourceType'] as String?)?.toLowerCase() ?? '';
        final details = (log['details'] as String?)?.toLowerCase() ?? '';

        return action.contains(keyword) ||
            userId.contains(keyword) ||
            resourceType.contains(keyword) ||
            details.contains(keyword);
      }).toList();
    }

    // Apply sorting
    filtered.sort((a, b) {
      int comparison = 0;

      switch (filter.sortBy) {
        case SortField.timestamp:
          final aTime = a['timestamp'] as String?;
          final bTime = b['timestamp'] as String?;
          comparison = (aTime ?? '').compareTo(bTime ?? '');

        case SortField.operationType:
          final aType = a['action'] as String?;
          final bType = b['action'] as String?;
          comparison = (aType ?? '').compareTo(bType ?? '');

        case SortField.userId:
          final aUser = a['userId'] as String?;
          final bUser = b['userId'] as String?;
          comparison = (aUser ?? '').compareTo(bUser ?? '');

        case SortField.resourceType:
          final aResource = a['resourceType'] as String?;
          final bResource = b['resourceType'] as String?;
          comparison = (aResource ?? '').compareTo(bResource ?? '');

        case SortField.operationCount:
          // Not applicable for log filtering, skip
          comparison = 0;
      }

      return filter.sortOrder == SortOrder.ascending ? comparison : -comparison;
    });

    return filtered;
  }

  /// Filter breakdown maps (e.g., operations by type)
  static Map<String, int> filterBreakdown(
    Map<String, int> breakdown,
    String? filterValue,
  ) {
    if (filterValue == null || filterValue.isEmpty) {
      return breakdown;
    }

    final filtered = <String, int>{};
    for (final entry in breakdown.entries) {
      if (entry.key.toLowerCase().contains(filterValue.toLowerCase())) {
        filtered[entry.key] = entry.value;
      }
    }
    return filtered;
  }

  /// Get available operation types from logs
  static Set<String> getAvailableOperationTypes(List<Map<String, dynamic>> logs) {
    return logs
        .map((log) => log['action'] as String?)
        .where((action) => action != null && action.isNotEmpty)
        .cast<String>()
        .toSet();
  }

  /// Get available user IDs from logs
  static Set<String> getAvailableUserIds(List<Map<String, dynamic>> logs) {
    return logs
        .map((log) => log['userId'] as String?)
        .where((userId) => userId != null && userId.isNotEmpty)
        .cast<String>()
        .toSet();
  }

  /// Get available resource types from logs
  static Set<String> getAvailableResourceTypes(List<Map<String, dynamic>> logs) {
    return logs
        .map((log) => log['resourceType'] as String?)
        .where((resourceType) => resourceType != null && resourceType.isNotEmpty)
        .cast<String>()
        .toSet();
  }

  /// Calculate statistics for filtered data
  static Map<String, dynamic> calculateFilteredStats(
    List<Map<String, dynamic>> logs,
  ) {
    if (logs.isEmpty) {
      return {
        'totalOperations': 0,
        'uniqueUsers': 0,
        'operationTypes': 0,
        'resourceTypes': 0,
      };
    }

    final userIds = <String>{};
    final operationTypes = <String>{};
    final resourceTypes = <String>{};

    for (final log in logs) {
      userIds.add(log['userId'] as String? ?? 'unknown');
      operationTypes.add(log['action'] as String? ?? 'unknown');
      resourceTypes.add(log['resourceType'] as String? ?? 'unknown');
    }

    return {
      'totalOperations': logs.length,
      'uniqueUsers': userIds.length,
      'operationTypes': operationTypes.length,
      'resourceTypes': resourceTypes.length,
    };
  }
}
