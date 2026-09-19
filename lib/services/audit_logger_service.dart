import 'package:shinjuu_league/data/models/admin_role.dart';
import 'package:shinjuu_league/services/firestore_service.dart';

/// Audit Logger Service (Phase 33 Part 1).
///
/// Tracks all admin changes with user attribution.
/// - Records who made each change
/// - Timestamps all operations
/// - Maintains audit trail for compliance
class AuditLoggerService {
  final FirestoreService _firestoreService;
  final AdminRoleService _roleService;

  AuditLoggerService({
    required FirestoreService firestoreService,
    required AdminRoleService roleService,
  })  : _firestoreService = firestoreService,
        _roleService = roleService;

  /// Log a feature flag change
  Future<void> logFeatureFlagChange({
    required String userId,
    required String featureName,
    required String action, // ENABLED, DISABLED, ROLLOUT_CHANGED
    required dynamic oldValue,
    required dynamic newValue,
    String? reason,
  }) async {
    await _logChange(
      userId: userId,
      action: 'FEATURE_$action',
      resourceType: 'FEATURE_FLAG',
      resourceId: featureName,
      oldValue: oldValue,
      newValue: newValue,
      details: {
        'featureName': featureName,
        if (reason != null) 'reason': reason,
      },
    );
  }

  /// Log a difficulty multiplier change
  Future<void> logDifficultyChange({
    required String userId,
    required String multiplierType, // level, cooldown, damage
    required double oldValue,
    required double newValue,
    String? reason,
  }) async {
    await _logChange(
      userId: userId,
      action: 'MULTIPLIER_UPDATED',
      resourceType: 'DIFFICULTY_MULTIPLIER',
      resourceId: multiplierType,
      oldValue: oldValue,
      newValue: newValue,
      details: {
        'multiplierType': multiplierType,
        if (reason != null) 'reason': reason,
      },
    );
  }

  /// Log an experiment change
  Future<void> logExperimentChange({
    required String userId,
    required String experimentId,
    required String action, // CREATED, ROLLOUT_UPDATED, COMPLETED
    required dynamic oldValue,
    required dynamic newValue,
    String? reason,
  }) async {
    await _logChange(
      userId: userId,
      action: 'EXPERIMENT_$action',
      resourceType: 'EXPERIMENT',
      resourceId: experimentId,
      oldValue: oldValue,
      newValue: newValue,
      details: {
        'experimentId': experimentId,
        if (reason != null) 'reason': reason,
      },
    );
  }

  /// Log a snapshot action
  Future<void> logSnapshotAction({
    required String userId,
    required String snapshotId,
    required String action, // CREATED, RESTORED
    String? description,
  }) async {
    await _logChange(
      userId: userId,
      action: 'SNAPSHOT_$action',
      resourceType: 'SNAPSHOT',
      resourceId: snapshotId,
      details: {
        'snapshotId': snapshotId,
        if (description != null) 'description': description,
      },
    );
  }

  /// Log a generic change with full details
  Future<void> logChange({
    required String userId,
    required String action,
    required String resourceType,
    required String resourceId,
    Map<String, dynamic>? details,
  }) async {
    await _logChange(
      userId: userId,
      action: action,
      resourceType: resourceType,
      resourceId: resourceId,
      details: details,
    );
  }

  /// Internal method to log change with timestamp and user info
  Future<void> _logChange({
    required String userId,
    required String action,
    required String resourceType,
    required String resourceId,
    dynamic oldValue,
    dynamic newValue,
    Map<String, dynamic>? details,
  }) async {
    try {
      // Get user role for audit trail
      final userRole = _roleService.getUserRole(userId);

      final auditEntry = {
        'timestamp': DateTime.now().toIso8601String(),
        'userId': userId,
        'userRole': userRole?.role.toString().split('.').last ?? 'unknown',
        'action': action,
        'resourceType': resourceType,
        'resourceId': resourceId,
        if (oldValue != null) 'oldValue': oldValue.toString(),
        if (newValue != null) 'newValue': newValue.toString(),
        if (details != null) ...details,
      };

      await _firestoreService.addData(
        path: 'audit_log',
        data: auditEntry,
      );
    } catch (e) {
      print('Error logging audit entry: $e');
      // Don't rethrow - audit logging failure shouldn't fail the main operation
    }
  }

  /// Get audit log for a specific user
  Future<List<Map<String, dynamic>>> getUserAuditLog(
    String userId, {
    int limit = 100,
  }) async {
    try {
      final snapshot = await _firestoreService
          .collection('audit_log')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print('Error fetching user audit log: $e');
      return [];
    }
  }

  /// Get audit log for a specific resource
  Future<List<Map<String, dynamic>>> getResourceAuditLog(
    String resourceType,
    String resourceId, {
    int limit = 100,
  }) async {
    try {
      final snapshot = await _firestoreService
          .collection('audit_log')
          .where('resourceType', isEqualTo: resourceType)
          .where('resourceId', isEqualTo: resourceId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print('Error fetching resource audit log: $e');
      return [];
    }
  }

  /// Get all audit log entries (with pagination)
  Future<List<Map<String, dynamic>>> getAuditLog({
    int limit = 100,
    String? startAfter,
  }) async {
    try {
      var query = _firestoreService
          .collection('audit_log')
          .orderBy('timestamp', descending: true)
          .limit(limit);

      final snapshot = await query.get();

      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print('Error fetching audit log: $e');
      return [];
    }
  }

  /// Export audit log as CSV format (for compliance/archival)
  String exportAuditLogAsCSV(List<Map<String, dynamic>> entries) {
    final headers = [
      'timestamp',
      'userId',
      'userRole',
      'action',
      'resourceType',
      'resourceId',
      'oldValue',
      'newValue',
    ];

    final rows = entries.map((entry) {
      return headers
          .map((header) => '"${(entry[header] ?? '').toString()}"')
          .join(',');
    });

    return '${headers.join(',')}\n${rows.join('\n')}';
  }

  /// Get statistics about admin activities
  Future<Map<String, dynamic>> getActivityStats({
    Duration? period,
  }) async {
    try {
      final cutoff = period != null
          ? DateTime.now().subtract(period)
          : DateTime.now().subtract(const Duration(days: 30));

      final snapshot = await _firestoreService
          .collection('audit_log')
          .where('timestamp', isGreaterThanOrEqualTo: cutoff.toIso8601String())
          .get();

      final entries = snapshot.docs;

      // Count by action
      final actionCounts = <String, int>{};
      final userCounts = <String, int>{};

      for (final doc in entries) {
        final data = doc.data() as Map<String, dynamic>;
        final action = data['action'] as String?;
        final userId = data['userId'] as String?;

        if (action != null) {
          actionCounts[action] = (actionCounts[action] ?? 0) + 1;
        }
        if (userId != null) {
          userCounts[userId] = (userCounts[userId] ?? 0) + 1;
        }
      }

      return {
        'totalChanges': entries.length,
        'period': period?.toString() ?? '30 days',
        'actionCounts': actionCounts,
        'userCounts': userCounts,
        'topUser': userCounts.entries.isNotEmpty
            ? userCounts.entries
                .reduce((a, b) => a.value > b.value ? a : b)
                .key
            : null,
      };
    } catch (e) {
      print('Error getting activity stats: $e');
      return {};
    }
  }
}
