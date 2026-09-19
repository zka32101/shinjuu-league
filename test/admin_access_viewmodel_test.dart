import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shinjuu_league/viewmodels/admin_access_viewmodel.dart';
import 'package:shinjuu_league/services/admin_role_service.dart';
import 'package:shinjuu_league/services/auth_service.dart';
import 'package:shinjuu_league/data/models/admin_role.dart';
import 'package:shinjuu_league/data/models/user_model.dart';

void main() {
  group('AdminAccessViewModel', () {
    late AdminAccessViewModel viewModel;
    late MockAdminRoleService mockRoleService;
    late MockAuthService mockAuthService;

    setUp(() {
      mockRoleService = MockAdminRoleService();
      mockAuthService = MockAuthService();
      viewModel = AdminAccessViewModel(
        roleService: mockRoleService,
        authService: mockAuthService,
      );
    });

    test('should initialize loading state', () {
      // Assert
      expect(viewModel.state, isA<AsyncLoading>());
    });

    test('should load admin roles and current user on initialization', () async {
      // Arrange
      mockAuthService.currentUser = User(
        uid: 'admin1',
        email: 'admin@test.com',
        displayName: 'Admin User',
        photoURL: null,
      );
      mockRoleService.setAdminUsers([
        UserAdminRole(
          userId: 'admin1',
          userName: 'Admin User',
          userEmail: 'admin@test.com',
          role: AdminRole.admin,
          assignedAt: DateTime.now(),
          assignedBy: null,
        ),
      ]);

      // Act
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert
      final state = viewModel.state;
      expect(state, isA<AsyncData>());
      if (state is AsyncData) {
        expect(state.value.currentUserId, 'admin1');
        expect(state.value.isAdmin, true);
        expect(state.value.currentUserRole?.role, AdminRole.admin);
      }
    });

    test('should handle case when user is not logged in', () async {
      // Arrange
      mockAuthService.currentUser = null;

      // Act
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert
      final state = viewModel.state;
      expect(state, isA<AsyncData>());
      if (state is AsyncData) {
        expect(state.value.currentUserId, null);
        expect(state.value.isAdmin, false);
      }
    });

    test('should return true for hasPermission when user has permission', () async {
      // Arrange
      mockAuthService.currentUser = User(
        uid: 'admin1',
        email: 'admin@test.com',
        displayName: 'Admin User',
        photoURL: null,
      );
      mockRoleService.setAdminUsers([
        UserAdminRole(
          userId: 'admin1',
          userName: 'Admin User',
          userEmail: 'admin@test.com',
          role: AdminRole.admin,
          assignedAt: DateTime.now(),
          assignedBy: null,
        ),
      ]);
      await Future.delayed(const Duration(milliseconds: 100));

      // Act
      final hasPermission = viewModel.hasPermission(AdminPermission.editFeatureFlags);

      // Assert
      expect(hasPermission, true);
    });

    test('should return false for hasPermission when user lacks permission', () async {
      // Arrange
      mockAuthService.currentUser = User(
        uid: 'viewer1',
        email: 'viewer@test.com',
        displayName: 'Viewer User',
        photoURL: null,
      );
      mockRoleService.setAdminUsers([
        UserAdminRole(
          userId: 'viewer1',
          userName: 'Viewer User',
          userEmail: 'viewer@test.com',
          role: AdminRole.viewer,
          assignedAt: DateTime.now(),
          assignedBy: null,
        ),
      ]);
      await Future.delayed(const Duration(milliseconds: 100));

      // Act
      final hasPermission = viewModel.hasPermission(AdminPermission.editFeatureFlags);

      // Assert
      expect(hasPermission, false);
    });

    test('should return false for hasPermission when state is loading', () {
      // Act
      final hasPermission = viewModel.hasPermission(AdminPermission.editFeatureFlags);

      // Assert
      expect(hasPermission, false);
    });

    test('should check hasAnyPermission correctly', () async {
      // Arrange
      mockAuthService.currentUser = User(
        uid: 'operator1',
        email: 'operator@test.com',
        displayName: 'Operator',
        photoURL: null,
      );
      mockRoleService.setAdminUsers([
        UserAdminRole(
          userId: 'operator1',
          userName: 'Operator',
          userEmail: 'operator@test.com',
          role: AdminRole.operator,
          assignedAt: DateTime.now(),
          assignedBy: null,
        ),
      ]);
      await Future.delayed(const Duration(milliseconds: 100));

      // Act
      final hasAnyPermission = viewModel.hasAnyPermission([
        AdminPermission.manageAdminRoles,
        AdminPermission.editFeatureFlags,
      ]);

      // Assert - Operator has editFeatureFlags but not manageAdminRoles
      expect(hasAnyPermission, true);
    });

    test('should check hasAllPermissions correctly', () async {
      // Arrange
      mockAuthService.currentUser = User(
        uid: 'admin1',
        email: 'admin@test.com',
        displayName: 'Admin',
        photoURL: null,
      );
      mockRoleService.setAdminUsers([
        UserAdminRole(
          userId: 'admin1',
          userName: 'Admin',
          userEmail: 'admin@test.com',
          role: AdminRole.admin,
          assignedAt: DateTime.now(),
          assignedBy: null,
        ),
      ]);
      await Future.delayed(const Duration(milliseconds: 100));

      // Act
      final hasAllPermissions = viewModel.hasAllPermissions([
        AdminPermission.editFeatureFlags,
        AdminPermission.manageAdminRoles,
      ]);

      // Assert - Admin has both permissions
      expect(hasAllPermissions, true);
    });

    test('should return isAdmin getter correctly', () async {
      // Arrange
      mockAuthService.currentUser = User(
        uid: 'admin1',
        email: 'admin@test.com',
        displayName: 'Admin',
        photoURL: null,
      );
      mockRoleService.setAdminUsers([
        UserAdminRole(
          userId: 'admin1',
          userName: 'Admin',
          userEmail: 'admin@test.com',
          role: AdminRole.admin,
          assignedAt: DateTime.now(),
          assignedBy: null,
        ),
      ]);
      await Future.delayed(const Duration(milliseconds: 100));

      // Act
      final isAdmin = viewModel.isAdmin;

      // Assert
      expect(isAdmin, true);
    });

    test('should return currentUserRole getter correctly', () async {
      // Arrange
      mockAuthService.currentUser = User(
        uid: 'operator1',
        email: 'operator@test.com',
        displayName: 'Operator',
        photoURL: null,
      );
      mockRoleService.setAdminUsers([
        UserAdminRole(
          userId: 'operator1',
          userName: 'Operator',
          userEmail: 'operator@test.com',
          role: AdminRole.operator,
          assignedAt: DateTime.now(),
          assignedBy: null,
        ),
      ]);
      await Future.delayed(const Duration(milliseconds: 100));

      // Act
      final currentRole = viewModel.currentUserRole;

      // Assert
      expect(currentRole?.role, AdminRole.operator);
    });

    test('should return allAdminUsers getter correctly', () async {
      // Arrange
      mockAuthService.currentUser = User(
        uid: 'admin1',
        email: 'admin@test.com',
        displayName: 'Admin',
        photoURL: null,
      );
      final testUsers = [
        UserAdminRole(
          userId: 'admin1',
          userName: 'Admin',
          userEmail: 'admin@test.com',
          role: AdminRole.admin,
          assignedAt: DateTime.now(),
          assignedBy: null,
        ),
        UserAdminRole(
          userId: 'operator1',
          userName: 'Operator',
          userEmail: 'operator@test.com',
          role: AdminRole.operator,
          assignedAt: DateTime.now(),
          assignedBy: 'admin1',
        ),
      ];
      mockRoleService.setAdminUsers(testUsers);
      await Future.delayed(const Duration(milliseconds: 100));

      // Act
      final allUsers = viewModel.allAdminUsers;

      // Assert
      expect(allUsers.length, 2);
      expect(allUsers[0].role, AdminRole.admin);
      expect(allUsers[1].role, AdminRole.operator);
    });

    test('should assign role to new user', () async {
      // Arrange
      mockAuthService.currentUser = User(
        uid: 'admin1',
        email: 'admin@test.com',
        displayName: 'Admin',
        photoURL: null,
      );
      mockRoleService.setAdminUsers([
        UserAdminRole(
          userId: 'admin1',
          userName: 'Admin',
          userEmail: 'admin@test.com',
          role: AdminRole.admin,
          assignedAt: DateTime.now(),
          assignedBy: null,
        ),
      ]);
      await Future.delayed(const Duration(milliseconds: 100));

      // Act
      final success = await viewModel.assignRoleToUser(
        userId: 'newuser',
        userName: 'New User',
        userEmail: 'newuser@test.com',
        role: AdminRole.operator,
      );

      // Assert
      expect(success, true);
    });

    test('should not assign role if not admin', () async {
      // Arrange
      mockAuthService.currentUser = User(
        uid: 'operator1',
        email: 'operator@test.com',
        displayName: 'Operator',
        photoURL: null,
      );
      mockRoleService.setAdminUsers([
        UserAdminRole(
          userId: 'operator1',
          userName: 'Operator',
          userEmail: 'operator@test.com',
          role: AdminRole.operator,
          assignedAt: DateTime.now(),
          assignedBy: null,
        ),
      ]);
      await Future.delayed(const Duration(milliseconds: 100));

      // Act
      final success = await viewModel.assignRoleToUser(
        userId: 'newuser',
        userName: 'New User',
        userEmail: 'newuser@test.com',
        role: AdminRole.operator,
      );

      // Assert
      expect(success, false);
    });

    test('should update user role', () async {
      // Arrange
      mockAuthService.currentUser = User(
        uid: 'admin1',
        email: 'admin@test.com',
        displayName: 'Admin',
        photoURL: null,
      );
      mockRoleService.setAdminUsers([
        UserAdminRole(
          userId: 'admin1',
          userName: 'Admin',
          userEmail: 'admin@test.com',
          role: AdminRole.admin,
          assignedAt: DateTime.now(),
          assignedBy: null,
        ),
        UserAdminRole(
          userId: 'operator1',
          userName: 'Operator',
          userEmail: 'operator@test.com',
          role: AdminRole.operator,
          assignedAt: DateTime.now(),
          assignedBy: 'admin1',
        ),
      ]);
      await Future.delayed(const Duration(milliseconds: 100));

      // Act
      final success = await viewModel.updateUserRole(
        userId: 'operator1',
        newRole: AdminRole.admin,
      );

      // Assert
      expect(success, true);
    });

    test('should revoke admin role', () async {
      // Arrange
      mockAuthService.currentUser = User(
        uid: 'admin1',
        email: 'admin@test.com',
        displayName: 'Admin',
        photoURL: null,
      );
      mockRoleService.setAdminUsers([
        UserAdminRole(
          userId: 'admin1',
          userName: 'Admin',
          userEmail: 'admin@test.com',
          role: AdminRole.admin,
          assignedAt: DateTime.now(),
          assignedBy: null,
        ),
        UserAdminRole(
          userId: 'operator1',
          userName: 'Operator',
          userEmail: 'operator@test.com',
          role: AdminRole.operator,
          assignedAt: DateTime.now(),
          assignedBy: 'admin1',
        ),
      ]);
      await Future.delayed(const Duration(milliseconds: 100));

      // Act
      final success = await viewModel.revokeAdminRole(userId: 'operator1');

      // Assert
      expect(success, true);
    });

    test('should refresh state', () async {
      // Arrange
      mockAuthService.currentUser = User(
        uid: 'admin1',
        email: 'admin@test.com',
        displayName: 'Admin',
        photoURL: null,
      );
      mockRoleService.setAdminUsers([
        UserAdminRole(
          userId: 'admin1',
          userName: 'Admin',
          userEmail: 'admin@test.com',
          role: AdminRole.admin,
          assignedAt: DateTime.now(),
          assignedBy: null,
        ),
      ]);
      await Future.delayed(const Duration(milliseconds: 100));

      // Act
      await viewModel.refresh();
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert
      final state = viewModel.state;
      expect(state, isA<AsyncData>());
    });
  });
}

// Mock implementations
class MockAuthService implements AuthService {
  User? currentUser;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockAdminRoleService implements AdminRoleService {
  List<UserAdminRole> _adminUsers = [];

  void setAdminUsers(List<UserAdminRole> users) {
    _adminUsers = users;
  }

  @override
  Future<void> loadAdminRoles() async {
    // Mock implementation
  }

  @override
  UserAdminRole? getUserRole(String userId) {
    try {
      return _adminUsers.firstWhere((u) => u.userId == userId);
    } catch (e) {
      return null;
    }
  }

  @override
  List<UserAdminRole> getAllAdminUsers() {
    return _adminUsers;
  }

  @override
  bool hasPermission(String userId, AdminPermission permission) {
    final user = getUserRole(userId);
    if (user == null) return false;
    return user.role.permissions.contains(permission);
  }

  @override
  bool hasAnyPermission(String userId, List<AdminPermission> permissions) {
    final user = getUserRole(userId);
    if (user == null) return false;
    return permissions.any((p) => user.role.permissions.contains(p));
  }

  @override
  bool hasAllPermissions(String userId, List<AdminPermission> permissions) {
    final user = getUserRole(userId);
    if (user == null) return false;
    return permissions.every((p) => user.role.permissions.contains(p));
  }

  @override
  Future<bool> assignRoleToUser({
    required String userId,
    required String userName,
    required String userEmail,
    required AdminRole role,
    required String assignedByUserId,
  }) async {
    _adminUsers.add(UserAdminRole(
      userId: userId,
      userName: userName,
      userEmail: userEmail,
      role: role,
      assignedAt: DateTime.now(),
      assignedBy: assignedByUserId,
    ));
    return true;
  }

  @override
  Future<bool> updateUserRole({
    required String userId,
    required AdminRole newRole,
    required String updatedByUserId,
  }) async {
    final index = _adminUsers.indexWhere((u) => u.userId == userId);
    if (index == -1) return false;
    _adminUsers[index] = _adminUsers[index].copyWith(role: newRole);
    return true;
  }

  @override
  Future<bool> revokeAdminRole({
    required String userId,
    required String revokedByUserId,
  }) async {
    _adminUsers.removeWhere((u) => u.userId == userId);
    return true;
  }

  @override
  Future<List<Map<String, dynamic>>> getRoleHistory(String userId) async {
    return [];
  }

  @override
  void clearCache() {}

  @override
  int get cacheSize => _adminUsers.length;

  @override
  bool get isCacheLoaded => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
