import 'package:shinjuu_league/services/audit_logger_service.dart';
import 'package:shinjuu_league/services/firestore_service.dart';

/// Admin Analytics Service (Phase 35)
///
/// Provides analytics and monitoring data for admin operations:
/// - Operation metrics (total ops, ops by type, ops by user)
/// - User activity tracking (who did what and when)
/// - Time-based trends (hourly, daily, weekly breakdowns)
/// - Risk indicators (suspicious patterns, rate limits)
/// - Compliance metrics (audit trail integrity, retention)
///
/// Data is derived from the audit_log collection (read-only analysis).
class AdminAnalyticsService {
  final FirestoreService _firestoreService;
  final AuditLoggerService _auditLoggerService;

  AdminAnalyticsService({
    required FirestoreService firestoreService,
    required AuditLoggerService auditLoggerService,
  })  : _firestoreService = firestoreService,
        _auditLoggerService = auditLoggerService;

  // ============================================================================
  // OPERATION METRICS
  // ============================================================================

  /// Get total number of operations in time period
  Future<int> getTotalOperationCount({
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    try {
      final logs = await _auditLoggerService.getAuditLog(
        startTime: startTime,
        endTime: endTime,
      );
      return logs.length;
    } catch (e) {
      return 0;
    }
  }

  /// Get breakdown of operations by type
  Future<Map<String, int>> getOperationsByType({
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    try {
      final logs = await _auditLoggerService.getAuditLog(
        startTime: startTime,
        endTime: endTime,
      );

      final breakdown = <String, int>{};
      for (final log in logs) {
        final action = log['action'] as String? ?? 'UNKNOWN';
        breakdown[action] = (breakdown[action] ?? 0) + 1;
      }
      return breakdown;
    } catch (e) {
      return {};
    }
  }

  /// Get breakdown of operations by user
  Future<Map<String, int>> getOperationsByUser({
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    try {
      final logs = await _auditLoggerService.getAuditLog(
        startTime: startTime,
        endTime: endTime,
      );

      final breakdown = <String, int>{};
      for (final log in logs) {
        final userId = log['userId'] as String? ?? 'unknown';
        breakdown[userId] = (breakdown[userId] ?? 0) + 1;
      }
      return breakdown;
    } catch (e) {
      return {};
    }
  }

  /// Get breakdown of operations by resource type
  Future<Map<String, int>> getOperationsByResourceType({
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    try {
      final logs = await _auditLoggerService.getAuditLog(
        startTime: startTime,
        endTime: endTime,
      );

      final breakdown = <String, int>{};
      for (final log in logs) {
        final resourceType = log['resourceType'] as String? ?? 'unknown';
        breakdown[resourceType] = (breakdown[resourceType] ?? 0) + 1;
      }
      return breakdown;
    } catch (e) {
      return {};
    }
  }

  // ============================================================================
  // TIME-BASED TRENDS
  // ============================================================================

  /// Get hourly operation counts for last 24 hours
  Future<Map<int, int>> getHourlyOperationTrend() async {
    try {
      final now = DateTime.now();
      final startTime = now.subtract(Duration(days: 1));

      final logs = await _auditLoggerService.getAuditLog(
        startTime: startTime,
        endTime: now,
      );

      final hourlyBreakdown = <int, int>{};
      for (int i = 0; i < 24; i++) {
        hourlyBreakdown[i] = 0;
      }

      for (final log in logs) {
        final timestampStr = log['timestamp'] as String?;
        if (timestampStr != null) {
          try {
            final timestamp = DateTime.parse(timestampStr);
            final hour = timestamp.hour;
            hourlyBreakdown[hour] = (hourlyBreakdown[hour] ?? 0) + 1;
          } catch (_) {
            // Skip entries with invalid timestamps
          }
        }
      }

      return hourlyBreakdown;
    } catch (e) {
      return {};
    }
  }

  /// Get daily operation counts for last 30 days
  Future<Map<String, int>> getDailyOperationTrend() async {
    try {
      final now = DateTime.now();
      final startTime = now.subtract(Duration(days: 30));

      final logs = await _auditLoggerService.getAuditLog(
        startTime: startTime,
        endTime: now,
      );

      final dailyBreakdown = <String, int>{};

      for (final log in logs) {
        final timestampStr = log['timestamp'] as String?;
        if (timestampStr != null) {
          try {
            final timestamp = DateTime.parse(timestampStr);
            final dateKey =
                '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}';
            dailyBreakdown[dateKey] = (dailyBreakdown[dateKey] ?? 0) + 1;
          } catch (_) {
            // Skip entries with invalid timestamps
          }
        }
      }

      return dailyBreakdown;
    } catch (e) {
      return {};
    }
  }

  // ============================================================================
  // USER ACTIVITY TRACKING
  // ============================================================================

  /// Get detailed activity for specific user
  Future<List<Map<String, dynamic>>> getUserActivity(
    String userId, {
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    try {
      final logs = await _auditLoggerService.getAuditLog(
        startTime: startTime,
        endTime: endTime,
      );

      return logs
          .where((log) => log['userId'] == userId)
          .toList()
          .cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  /// Get most active admins in time period
  Future<List<Map<String, dynamic>>> getMostActiveAdmins({
    DateTime? startTime,
    DateTime? endTime,
    int limit = 10,
  }) async {
    try {
      final operationsByUser = await getOperationsByUser(
        startTime: startTime,
        endTime: endTime,
      );

      final entries = operationsByUser.entries.toList();
      entries.sort((a, b) => b.value.compareTo(a.value));

      return entries.take(limit).map((entry) {
        return {
          'userId': entry.key,
          'operationCount': entry.value,
        };
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // ============================================================================
  // RISK INDICATORS & ANOMALIES
  // ============================================================================

  /// Detect high-frequency operations (potential abuse)
  Future<Map<String, dynamic>> detectHighFrequencyOperations({
    Duration timeWindow = const Duration(minutes: 5),
    int threshold = 10,
  }) async {
    try {
      final now = DateTime.now();
      final startTime = now.subtract(timeWindow);

      final logs = await _auditLoggerService.getAuditLog(
        startTime: startTime,
        endTime: now,
      );

      final userOperationCounts = <String, int>{};
      for (final log in logs) {
        final userId = log['userId'] as String? ?? 'unknown';
        userOperationCounts[userId] = (userOperationCounts[userId] ?? 0) + 1;
      }

      final highFrequencyUsers = userOperationCounts.entries
          .where((entry) => entry.value > threshold)
          .map((entry) => {
                'userId': entry.key,
                'operationCount': entry.value,
                'timeWindowMinutes': timeWindow.inMinutes,
              })
          .toList();

      return {
        'detectedAnomalies': highFrequencyUsers.length > 0,
        'affectedUsers': highFrequencyUsers,
        'threshold': threshold,
        'timeWindowMinutes': timeWindow.inMinutes,
      };
    } catch (e) {
      return {
        'detectedAnomalies': false,
        'affectedUsers': [],
        'error': e.toString(),
      };
    }
  }

  /// Get operations with unusual patterns
  Future<List<Map<String, dynamic>>> getUnusualOperations({
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    try {
      final logs = await _auditLoggerService.getAuditLog(
        startTime: startTime,
        endTime: endTime,
      );

      final unusual = <Map<String, dynamic>>[];

      // Operations on sensitive resources (admin roles, audit logs)
      for (final log in logs) {
        final resourceType = log['resourceType'] as String?;
        final action = log['action'] as String?;

        if (resourceType == 'admin_user' ||
            resourceType == 'admin_role' ||
            action == 'REVOKE_ROLE') {
          unusual.add(log as Map<String, dynamic>);
        }
      }

      return unusual;
    } catch (e) {
      return [];
    }
  }

  // ============================================================================
  // COMPLIANCE METRICS
  // ============================================================================

  /// Check audit trail integrity (all required fields present)
  Future<Map<String, dynamic>> getAuditTrailIntegrity({
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    try {
      final logs = await _auditLoggerService.getAuditLog(
        startTime: startTime,
        endTime: endTime,
      );

      final requiredFields = [
        'logId',
        'timestamp',
        'userId',
        'action',
        'resourceType',
      ];

      int validEntries = 0;
      int missingFields = 0;

      for (final log in logs) {
        bool hasAllRequired = true;
        for (final field in requiredFields) {
          if (!log.containsKey(field) || log[field] == null) {
            hasAllRequired = false;
            break;
          }
        }

        if (hasAllRequired) {
          validEntries++;
        } else {
          missingFields++;
        }
      }

      final total = logs.length;
      final integrityPercentage =
          total > 0 ? (validEntries / total * 100).toStringAsFixed(2) : '100.00';

      return {
        'totalEntries': total,
        'validEntries': validEntries,
        'missingFields': missingFields,
        'integrityPercentage': double.parse(integrityPercentage),
        'status': missingFields == 0 ? 'HEALTHY' : 'DEGRADED',
      };
    } catch (e) {
      return {
        'status': 'ERROR',
        'error': e.toString(),
      };
    }
  }

  /// Get audit log retention statistics
  Future<Map<String, dynamic>> getAuditRetentionStats() async {
    try {
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(Duration(days: 30));
      const ninetyDaysAgo = Duration(days: 90);
      const oneYearAgo = Duration(days: 365);

      final logsAll = await _auditLoggerService.getAuditLog();
      final logs30Days =
          await _auditLoggerService.getAuditLog(startTime: thirtyDaysAgo);
      final logs90Days = await _auditLoggerService.getAuditLog(
        startTime: now.subtract(ninetyDaysAgo),
      );
      final logs365Days = await _auditLoggerService.getAuditLog(
        startTime: now.subtract(oneYearAgo),
      );

      return {
        'totalEntries': logsAll.length,
        'entries30Days': logs30Days.length,
        'entries90Days': logs90Days.length,
        'entries365Days': logs365Days.length,
        'retentionStatus': 'ACTIVE',
      };
    } catch (e) {
      return {
        'retentionStatus': 'ERROR',
        'error': e.toString(),
      };
    }
  }

  // ============================================================================
  // SUMMARY DASHBOARD STATS
  // ============================================================================

  /// Get comprehensive dashboard summary
  Future<Map<String, dynamic>> getDashboardSummary({
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    try {
      final operationsByType = await getOperationsByType(
        startTime: startTime,
        endTime: endTime,
      );
      final operationsByUser = await getOperationsByUser(
        startTime: startTime,
        endTime: endTime,
      );
      final operationsByResource = await getOperationsByResourceType(
        startTime: startTime,
        endTime: endTime,
      );
      final mostActive = await getMostActiveAdmins(
        startTime: startTime,
        endTime: endTime,
        limit: 5,
      );
      final integrity = await getAuditTrailIntegrity(
        startTime: startTime,
        endTime: endTime,
      );

      final totalOps = operationsByUser.values
          .fold<int>(0, (sum, count) => sum + count);

      return {
        'timeRange': {
          'startTime': startTime?.toIso8601String(),
          'endTime': endTime?.toIso8601String(),
        },
        'summary': {
          'totalOperations': totalOps,
          'uniqueUsers': operationsByUser.length,
          'operationTypes': operationsByType.length,
          'resourceTypes': operationsByResource.length,
        },
        'topOperations': operationsByType.entries
            .toList()
            .map((e) => {'action': e.key, 'count': e.value})
            .toList(),
        'topResources': operationsByResource.entries
            .toList()
            .map((e) => {'resourceType': e.key, 'count': e.value})
            .toList(),
        'mostActiveAdmins': mostActive,
        'auditIntegrity': integrity,
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'summary': {
          'totalOperations': 0,
          'uniqueUsers': 0,
        },
      };
    }
  }
}
