import 'package:flutter_test/flutter_test.dart';
import 'package:shinjuu_league/data/models/admin_role.dart';
import 'package:shinjuu_league/services/admin_role_service.dart';
import 'package:shinjuu_league/services/firestore_service.dart';

void main() {
  group('AdminRoleService', () {
    late AdminRoleService roleService;
    late MockFirestoreService mockFirestoreService;

    setUp(() {
      mockFirestoreService = MockFirestoreService();
      roleService = AdminRoleService(firestoreService: mockFirestoreService);
    });

    test('loadAdminRoles should populate role cache', () async {
      // Arrange
      final testRoles = [
        {
          'userId': 'user1',
          'userName': 'Admin User',
          'userEmail': 'admin@test.com',
          'role': 'admin',
          'assignedAt': '2026-09-01T10:00:00.000Z',
          'assignedBy': 'system',
        },
        {
          'userId': 'user2',
          'userName': 'Operator User',
          'userEmail': 'operator@test.com',
          'role': 'operator',
          'assignedAt': '2026-09-02T10:00:00.000Z',
          'assignedBy': 'user1',
        },
      ];

      mockFirestoreService.setMockRoles(testRoles);

      // Act
      await roleService.loadAdminRoles();

      // Assert
      expect(roleService.isCacheLoaded, true);
      expect(roleService.cacheSize, 2);
      expect(roleService.getUserRole('user1')?.role, AdminRole.admin);
      expect(roleService.getUserRole('user2')?.role, AdminRole.operator);
    });

    test('getUserRole should return null for non-existent user', () async {
      // Arrange
      await roleService.loadAdminRoles();

      // Act
      final role = roleService.getUserRole('nonexistent');

      // Assert
      expect(role, null);
    });

    test('hasPermission should return true for admin with all permissions', () async {
      // Arrange
      final testRoles = [
        {
          'userId': 'admin1',
          'userName': 'Admin',
          'userEmail': 'admin@test.com',
          'role': 'admin',
          'assignedAt': '2026-09-01T10:00:00.000Z',
          'assignedBy': null,
        },
      ];
      mockFirestoreService.setMockRoles(testRoles);
      await roleService.loadAdminRoles();

      // Act & Assert
      expect(roleService.hasPermission('admin1', AdminPermission.editFeatureFlags), true);
      expect(roleService.hasPermission('admin1', AdminPermission.manageAdminRoles), true);
      expect(roleService.hasPermission('admin1', AdminPermission.viewAuditLog), true);
    });

    test('hasPermission should return false for operator without manageAdminRoles', () async {
      // Arrange
      final testRoles = [
        {
          'userId': 'operator1',
          'userName': 'Operator',
          'userEmail': 'operator@test.com',
          'role': 'operator',
          'assignedAt': '2026-09-01T10:00:00.000Z',
          'assignedBy': 'admin1',
        },
      ];
      mockFirestoreService.setMockRoles(testRoles);
      await roleService.loadAdminRoles();

      // Act & Assert
      expect(roleService.hasPermission('operator1', AdminPermission.editFeatureFlags), true);
      expect(roleService.hasPermission('operator1', AdminPermission.manageAdminRoles), false);
      expect(roleService.hasPermission('operator1', AdminPermission.toggleKillSwitch), false);
    });

    test('hasPermission should return false for viewer without edit permissions', () async {
      // Arrange
      final testRoles = [
        {
          'userId': 'viewer1',
          'userName': 'Viewer',
          'userEmail': 'viewer@test.com',
          'role': 'viewer',
          'assignedAt': '2026-09-01T10:00:00.000Z',
          'assignedBy': 'admin1',
        },
      ];
      mockFirestoreService.setMockRoles(testRoles);
      await roleService.loadAdminRoles();

      // Act & Assert
      expect(roleService.hasPermission('viewer1', AdminPermission.viewFeatureFlags), true);
      expect(roleService.hasPermission('viewer1', AdminPermission.editFeatureFlags), false);
      expect(roleService.hasPermission('viewer1', AdminPermission.manageAdminRoles), false);
    });

    test('hasAnyPermission should return true if user has any of the permissions', () async {
      // Arrange
      final testRoles = [
        {
          'userId': 'operator1',
          'userName': 'Operator',
          'userEmail': 'operator@test.com',
          'role': 'operator',
          'assignedAt': '2026-09-01T10:00:00.000Z',
          'assignedBy': 'admin1',
        },
      ];
      mockFirestoreService.setMockRoles(testRoles);
      await roleService.loadAdminRoles();

      // Act & Assert
      expect(
        roleService.hasAnyPermission(
          'operator1',
          [AdminPermission.manageAdminRoles, AdminPermission.editFeatureFlags],
        ),
        true, // Operator has editFeatureFlags
      );
      expect(
        roleService.hasAnyPermission(
          'operator1',
          [AdminPermission.manageAdminRoles, AdminPermission.toggleKillSwitch],
        ),
        false, // Operator has neither
      );
    });

    test('hasAllPermissions should return true only if user has all permissions', () async {
      // Arrange
      final testRoles = [
        {
          'userId': 'admin1',
          'userName': 'Admin',
          'userEmail': 'admin@test.com',
          'role': 'admin',
          'assignedAt': '2026-09-01T10:00:00.000Z',
          'assignedBy': null,
        },
      ];
      mockFirestoreService.setMockRoles(testRoles);
      await roleService.loadAdminRoles();

      // Act & Assert
      expect(
        roleService.hasAllPermissions(
          'admin1',
          [AdminPermission.editFeatureFlags, AdminPermission.manageAdminRoles],
        ),
        true, // Admin has both
      );
      expect(
        roleService.hasAllPermissions(
          'admin1',
          [AdminPermission.editFeatureFlags, AdminPermission.editDifficulty],
        ),
        true, // Admin has both
      );
    });

    test('getAllAdminUsers should return all roles', () async {
      // Arrange
      final testRoles = [
        {
          'userId': 'user1',
          'userName': 'Admin',
          'userEmail': 'admin@test.com',
          'role': 'admin',
          'assignedAt': '2026-09-01T10:00:00.000Z',
          'assignedBy': null,
        },
        {
          'userId': 'user2',
          'userName': 'Operator',
          'userEmail': 'operator@test.com',
          'role': 'operator',
          'assignedAt': '2026-09-02T10:00:00.000Z',
          'assignedBy': 'user1',
        },
      ];
      mockFirestoreService.setMockRoles(testRoles);
      await roleService.loadAdminRoles();

      // Act
      final allUsers = roleService.getAllAdminUsers();

      // Assert
      expect(allUsers.length, 2);
      expect(allUsers[0].userId, 'user1');
      expect(allUsers[1].userId, 'user2');
    });

    test('assignRoleToUser should add user to cache and Firestore', () async {
      // Arrange
      await roleService.loadAdminRoles();

      // Act
      final success = await roleService.assignRoleToUser(
        userId: 'newuser',
        userName: 'New User',
        userEmail: 'newuser@test.com',
        role: AdminRole.operator,
        assignedByUserId: 'admin1',
      );

      // Assert
      expect(success, true);
      expect(roleService.cacheSize, 1);
      expect(roleService.getUserRole('newuser')?.role, AdminRole.operator);
    });

    test('updateUserRole should update role in cache and Firestore', () async {
      // Arrange
      final testRoles = [
        {
          'userId': 'user1',
          'userName': 'User One',
          'userEmail': 'user1@test.com',
          'role': 'viewer',
          'assignedAt': '2026-09-01T10:00:00.000Z',
          'assignedBy': 'admin1',
        },
      ];
      mockFirestoreService.setMockRoles(testRoles);
      await roleService.loadAdminRoles();

      // Act
      final success = await roleService.updateUserRole(
        userId: 'user1',
        newRole: AdminRole.operator,
        updatedByUserId: 'admin1',
      );

      // Assert
      expect(success, true);
      expect(roleService.getUserRole('user1')?.role, AdminRole.operator);
    });

    test('updateUserRole should return false for non-existent user', () async {
      // Arrange
      await roleService.loadAdminRoles();

      // Act
      final success = await roleService.updateUserRole(
        userId: 'nonexistent',
        newRole: AdminRole.operator,
        updatedByUserId: 'admin1',
      );

      // Assert
      expect(success, false);
    });

    test('revokeAdminRole should remove user from cache and Firestore', () async {
      // Arrange
      final testRoles = [
        {
          'userId': 'user1',
          'userName': 'User One',
          'userEmail': 'user1@test.com',
          'role': 'admin',
          'assignedAt': '2026-09-01T10:00:00.000Z',
          'assignedBy': null,
        },
      ];
      mockFirestoreService.setMockRoles(testRoles);
      await roleService.loadAdminRoles();

      // Act
      final success = await roleService.revokeAdminRole(
        userId: 'user1',
        revokedByUserId: 'admin2',
      );

      // Assert
      expect(success, true);
      expect(roleService.cacheSize, 0);
      expect(roleService.getUserRole('user1'), null);
    });

    test('clearCache should reset cache state', () async {
      // Arrange
      final testRoles = [
        {
          'userId': 'user1',
          'userName': 'User One',
          'userEmail': 'user1@test.com',
          'role': 'admin',
          'assignedAt': '2026-09-01T10:00:00.000Z',
          'assignedBy': null,
        },
      ];
      mockFirestoreService.setMockRoles(testRoles);
      await roleService.loadAdminRoles();
      expect(roleService.isCacheLoaded, true);

      // Act
      roleService.clearCache();

      // Assert
      expect(roleService.isCacheLoaded, false);
      expect(roleService.cacheSize, 0);
    });

    test('getRoleHistory should return historical role changes', () async {
      // Arrange
      mockFirestoreService.setMockRoleHistory('user1', [
        {
          'userId': 'user1',
          'action': 'ROLE_ASSIGNED',
          'timestamp': '2026-09-01T10:00:00.000Z',
          'new_role': 'viewer',
          'assigned_by': 'admin1',
        },
        {
          'userId': 'user1',
          'action': 'ROLE_UPDATED',
          'timestamp': '2026-09-02T10:00:00.000Z',
          'old_role': 'viewer',
          'new_role': 'operator',
          'updated_by': 'admin1',
        },
      ]);

      // Act
      final history = await roleService.getRoleHistory('user1');

      // Assert
      expect(history.length, 2);
      expect(history[0]['action'], 'ROLE_ASSIGNED');
      expect(history[1]['action'], 'ROLE_UPDATED');
    });
  });
}

// Mock FirestoreService for testing
class MockFirestoreService implements FirestoreService {
  Map<String, dynamic> _mockRoles = {};
  Map<String, List<Map<String, dynamic>>> _roleHistory = {};

  void setMockRoles(List<Map<String, dynamic>> roles) {
    _mockRoles.clear();
    for (var role in roles) {
      _mockRoles[role['userId']] = role;
    }
  }

  void setMockRoleHistory(String userId, List<Map<String, dynamic>> history) {
    _roleHistory[userId] = history;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<void> setData({required String path, required Map<String, dynamic> data}) async {
    if (path.startsWith('admin_users/')) {
      final userId = path.split('/')[1];
      _mockRoles[userId] = data;
    }
  }

  @override
  Future<void> deleteData({required String path}) async {
    if (path.startsWith('admin_users/')) {
      final userId = path.split('/')[1];
      _mockRoles.remove(userId);
    }
  }

  @override
  Future<void> addData({required String path, required Map<String, dynamic> data}) async {
    if (path == 'admin_role_audit_log') {
      // Mock implementation
    }
  }

  @override
  dynamic collection(String path) {
    if (path == 'admin_users') {
      return _MockQuery(_mockRoles);
    } else if (path == 'admin_role_audit_log') {
      return _MockQuery({});
    }
    throw UnimplementedError();
  }
}

class _MockQuery {
  final Map<String, dynamic> _data;

  _MockQuery(this._data);

  Future<dynamic> get() async {
    return _MockSnapshot(_data);
  }
}

class _MockSnapshot {
  final Map<String, dynamic> _data;

  _MockSnapshot(this._data);

  List<dynamic> get docs {
    return _data.entries.map((e) => _MockDoc(e.value as Map<String, dynamic>)).toList();
  }
}

class _MockDoc {
  final Map<String, dynamic> _data;

  _MockDoc(this._data);

  Map<String, dynamic> data() => _data;
}
