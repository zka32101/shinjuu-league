import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shinjuu_league/services/audit_logger_service.dart';
import 'package:shinjuu_league/services/firestore_service.dart';
import 'package:shinjuu_league/services/admin_role_service.dart';
import 'package:shinjuu_league/data/models/admin_role.dart';

void main() {
  group('AuditLoggerService', () {
    late AuditLoggerService auditService;
    late MockFirestoreService mockFirestore;
    late MockAdminRoleService mockRoleService;

    setUp(() {
      mockFirestore = MockFirestoreService();
      mockRoleService = MockAdminRoleService();
      auditService = AuditLoggerService(
        firestoreService: mockFirestore,
        roleService: mockRoleService,
      );
    });

    test('logFeatureFlagChange should record feature flag modifications', () async {
      // Act
      await auditService.logFeatureFlagChange(
        userId: 'admin1',
        featureName: 'new_ranking_system',
        action: 'ENABLED',
        oldValue: false,
        newValue: true,
        reason: 'Enabling for beta testing',
      );

      // Assert
      expect(mockFirestore.auditLogs.length, 1);
      final log = mockFirestore.auditLogs[0];
      expect(log['action'], 'FEATURE_ENABLED');
      expect(log['resourceType'], 'FEATURE_FLAG');
      expect(log['resourceId'], 'new_ranking_system');
      expect(log['oldValue'], 'false');
      expect(log['newValue'], 'true');
      expect(log['reason'], 'Enabling for beta testing');
    });

    test('logDifficultyChange should record difficulty multiplier changes', () async {
      // Act
      await auditService.logDifficultyChange(
        userId: 'operator1',
        multiplierType: 'level',
        oldValue: 1.0,
        newValue: 1.2,
        reason: 'Increased difficulty for higher tiers',
      );

      // Assert
      expect(mockFirestore.auditLogs.length, 1);
      final log = mockFirestore.auditLogs[0];
      expect(log['action'], 'MULTIPLIER_UPDATED');
      expect(log['resourceType'], 'DIFFICULTY_MULTIPLIER');
      expect(log['multiplierType'], 'level');
      expect(log['oldValue'], '1.0');
      expect(log['newValue'], '1.2');
    });

    test('logExperimentChange should record experiment modifications', () async {
      // Act
      await auditService.logExperimentChange(
        userId: 'admin1',
        experimentId: 'exp_001',
        action: 'CREATED',
        oldValue: null,
        newValue: {'rollout': 10, 'variant_a': 50, 'variant_b': 50},
        reason: 'A/B test for new UI',
      );

      // Assert
      expect(mockFirestore.auditLogs.length, 1);
      final log = mockFirestore.auditLogs[0];
      expect(log['action'], 'EXPERIMENT_CREATED');
      expect(log['resourceType'], 'EXPERIMENT');
      expect(log['resourceId'], 'exp_001');
    });

    test('logSnapshotAction should record snapshot operations', () async {
      // Act
      await auditService.logSnapshotAction(
        userId: 'admin1',
        snapshotId: 'snap_001',
        action: 'CREATED',
        description: 'Backup before major changes',
      );

      // Assert
      expect(mockFirestore.auditLogs.length, 1);
      final log = mockFirestore.auditLogs[0];
      expect(log['action'], 'SNAPSHOT_CREATED');
      expect(log['resourceType'], 'SNAPSHOT');
      expect(log['snapshotId'], 'snap_001');
      expect(log['description'], 'Backup before major changes');
    });

    test('logChange should record generic changes', () async {
      // Act
      await auditService.logChange(
        userId: 'admin1',
        action: 'CUSTOM_ACTION',
        resourceType: 'CUSTOM_RESOURCE',
        resourceId: 'custom_001',
        details: {'custom_field': 'custom_value'},
      );

      // Assert
      expect(mockFirestore.auditLogs.length, 1);
      final log = mockFirestore.auditLogs[0];
      expect(log['action'], 'CUSTOM_ACTION');
      expect(log['resourceType'], 'CUSTOM_RESOURCE');
      expect(log['custom_field'], 'custom_value');
    });

    test('should include timestamp in all audit entries', () async {
      // Act
      await auditService.logFeatureFlagChange(
        userId: 'admin1',
        featureName: 'test_feature',
        action: 'ENABLED',
        oldValue: false,
        newValue: true,
      );

      // Assert
      expect(mockFirestore.auditLogs.length, 1);
      final log = mockFirestore.auditLogs[0];
      expect(log['timestamp'], isNotNull);
      expect(log.containsKey('timestamp'), true);
    });

    test('should include userId and userRole in audit entries', () async {
      // Arrange
      mockRoleService.setUserRole('admin1', AdminRole.admin);

      // Act
      await auditService.logFeatureFlagChange(
        userId: 'admin1',
        featureName: 'test_feature',
        action: 'ENABLED',
        oldValue: false,
        newValue: true,
      );

      // Assert
      expect(mockFirestore.auditLogs.length, 1);
      final log = mockFirestore.auditLogs[0];
      expect(log['userId'], 'admin1');
      expect(log['userRole'], 'admin');
    });

    test('getUserAuditLog should retrieve logs for specific user', () async {
      // Arrange
      await mockFirestore.setMockUserAuditLog('admin1', [
        {
          'timestamp': '2026-09-01T10:00:00.000Z',
          'userId': 'admin1',
          'action': 'FEATURE_ENABLED',
          'resourceType': 'FEATURE_FLAG',
          'resourceId': 'feature1',
        },
        {
          'timestamp': '2026-09-01T11:00:00.000Z',
          'userId': 'admin1',
          'action': 'MULTIPLIER_UPDATED',
          'resourceType': 'DIFFICULTY_MULTIPLIER',
          'resourceId': 'level',
        },
      ]);

      // Act
      final logs = await auditService.getUserAuditLog('admin1', limit: 50);

      // Assert
      expect(logs.length, 2);
      expect(logs[0]['userId'], 'admin1');
      expect(logs[1]['userId'], 'admin1');
    });

    test('getResourceAuditLog should retrieve logs for specific resource', () async {
      // Arrange
      await mockFirestore.setMockResourceAuditLog('FEATURE_FLAG', 'new_feature', [
        {
          'timestamp': '2026-09-01T10:00:00.000Z',
          'userId': 'admin1',
          'action': 'FEATURE_ENABLED',
          'resourceType': 'FEATURE_FLAG',
          'resourceId': 'new_feature',
        },
        {
          'timestamp': '2026-09-01T11:00:00.000Z',
          'userId': 'admin1',
          'action': 'FEATURE_DISABLED',
          'resourceType': 'FEATURE_FLAG',
          'resourceId': 'new_feature',
        },
      ]);

      // Act
      final logs = await auditService.getResourceAuditLog(
        'FEATURE_FLAG',
        'new_feature',
        limit: 50,
      );

      // Assert
      expect(logs.length, 2);
      expect(logs[0]['resourceId'], 'new_feature');
      expect(logs[1]['resourceId'], 'new_feature');
    });

    test('getAuditLog should retrieve all logs', () async {
      // Arrange
      await mockFirestore.setMockAuditLog([
        {
          'timestamp': '2026-09-01T10:00:00.000Z',
          'userId': 'admin1',
          'action': 'FEATURE_ENABLED',
        },
        {
          'timestamp': '2026-09-01T11:00:00.000Z',
          'userId': 'operator1',
          'action': 'MULTIPLIER_UPDATED',
        },
      ]);

      // Act
      final logs = await auditService.getAuditLog(limit: 50);

      // Assert
      expect(logs.length, 2);
    });

    test('exportAuditLogAsCSV should format logs as CSV', () {
      // Arrange
      final entries = [
        {
          'timestamp': '2026-09-01T10:00:00.000Z',
          'userId': 'admin1',
          'userRole': 'admin',
          'action': 'FEATURE_ENABLED',
          'resourceType': 'FEATURE_FLAG',
          'resourceId': 'new_feature',
          'oldValue': 'false',
          'newValue': 'true',
        },
      ];

      // Act
      final csv = auditService.exportAuditLogAsCSV(entries);

      // Assert
      expect(csv.contains('timestamp'), true);
      expect(csv.contains('userId'), true);
      expect(csv.contains('admin1'), true);
      expect(csv.contains('FEATURE_ENABLED'), true);
      expect(csv.contains('"false"'), true);
      expect(csv.contains('"true"'), true);
    });

    test('exportAuditLogAsCSV should handle empty entries', () {
      // Act
      final csv = auditService.exportAuditLogAsCSV([]);

      // Assert
      expect(csv.contains('timestamp'), true);
      expect(csv.contains('userId'), true);
    });

    test('getActivityStats should return statistics about admin activities', () async {
      // Arrange
      await mockFirestore.setMockActivityStats(
        totalChanges: 5,
        actionCounts: {
          'FEATURE_ENABLED': 2,
          'MULTIPLIER_UPDATED': 2,
          'SNAPSHOT_CREATED': 1,
        },
        userCounts: {
          'admin1': 3,
          'operator1': 2,
        },
      );

      // Act
      final stats = await auditService.getActivityStats();

      // Assert
      expect(stats['totalChanges'], 5);
      expect(stats['actionCounts']['FEATURE_ENABLED'], 2);
      expect(stats['userCounts']['admin1'], 3);
      expect(stats['topUser'], 'admin1');
    });

    test('getActivityStats should filter by period', () async {
      // Arrange
      await mockFirestore.setMockActivityStats(
        totalChanges: 2,
        actionCounts: {'FEATURE_ENABLED': 2},
        userCounts: {'admin1': 2},
      );

      // Act
      final stats = await auditService.getActivityStats(
        period: const Duration(days: 7),
      );

      // Assert
      expect(stats['totalChanges'], 2);
      expect(stats['period'], '7 days');
    });

    test('should not throw on audit logging failure', () async {
      // Arrange
      mockFirestore.failNextAddData = true;

      // Act & Assert - should not throw
      expect(
        () async => await auditService.logFeatureFlagChange(
          userId: 'admin1',
          featureName: 'test',
          action: 'ENABLED',
          oldValue: false,
          newValue: true,
        ),
        returnsNormally,
      );
    });
  });
}

// Mock implementations for testing
// Backed by a real (fake) Firestore so the .where()/.orderBy()/.limit()
// query chain used throughout AuditLoggerService behaves like the genuine
// SDK instead of a hand-rolled stub that ignored filters entirely.
class MockFirestoreService implements FirestoreService {
  final FakeFirebaseFirestore _fake = FakeFirebaseFirestore();
  List<Map<String, dynamic>> auditLogs = [];
  bool failNextAddData = false;

  Future<void> setMockUserAuditLog(
    String userId,
    List<Map<String, dynamic>> logs,
  ) async {
    for (final log in logs) {
      await _fake.collection('audit_log').add(log);
    }
  }

  Future<void> setMockResourceAuditLog(
    String resourceType,
    String resourceId,
    List<Map<String, dynamic>> logs,
  ) async {
    for (final log in logs) {
      await _fake.collection('audit_log').add(log);
    }
  }

  Future<void> setMockAuditLog(List<Map<String, dynamic>> logs) async {
    for (final log in logs) {
      await _fake.collection('audit_log').add(log);
    }
  }

  Future<void> setMockActivityStats({
    required int totalChanges,
    required Map<String, int> actionCounts,
    required Map<String, int> userCounts,
  }) async {
    final actionQueue = <String>[
      for (final entry in actionCounts.entries)
        for (var i = 0; i < entry.value; i++) entry.key,
    ];
    final userQueue = <String>[
      for (final entry in userCounts.entries)
        for (var i = 0; i < entry.value; i++) entry.key,
    ];
    final count =
        totalChanges > actionQueue.length ? totalChanges : actionQueue.length;
    for (var i = 0; i < count; i++) {
      await _fake.collection('audit_log').add({
        'timestamp': DateTime.now().toIso8601String(),
        'userId': i < userQueue.length ? userQueue[i] : 'unknown',
        'action': i < actionQueue.length ? actionQueue[i] : 'UNKNOWN',
      });
    }
  }

  @override
  Future<void> addData({required String path, required Map<String, dynamic> data}) async {
    if (failNextAddData) {
      failNextAddData = false;
      throw Exception('Mock failure');
    }
    if (path == 'audit_log') {
      auditLogs.add(data);
    }
    await _fake.collection(path).add(data);
  }

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      _fake.collection(path);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockAdminRoleService implements AdminRoleService {
  Map<String, AdminRole> userRoles = {};

  void setUserRole(String userId, AdminRole role) {
    userRoles[userId] = role;
  }

  @override
  UserAdminRole? getUserRole(String userId) {
    final role = userRoles[userId];
    if (role == null) return null;
    return UserAdminRole(
      userId: userId,
      userName: 'Test User',
      userEmail: 'test@test.com',
      role: role,
      assignedAt: DateTime.now(),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

