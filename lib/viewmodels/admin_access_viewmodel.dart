import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shinjuu_league/data/models/admin_role.dart';
import 'package:shinjuu_league/services/admin_role_service.dart';
import 'package:shinjuu_league/services/auth_service.dart';

/// Admin Access Control ViewModel (Phase 33 Part 1).
///
/// Provides reactive state for:
/// - Current user's role and permissions
/// - Permission checks for UI rendering
/// - Admin user list management
class AdminAccessViewModel
    extends StateNotifier<AsyncValue<AdminAccessState>> {
  final AdminRoleService _roleService;
  final AuthService _authService;

  AdminAccessViewModel({
    required AdminRoleService roleService,
    required AuthService authService,
  })  : _roleService = roleService,
        _authService = authService,
        super(const AsyncValue.loading()) {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // Load all admin roles
      await _roleService.loadAdminRoles();

      // Get current user
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        state = AsyncValue.data(
          AdminAccessState(
            currentUserId: null,
            currentUserRole: null,
            isAdmin: false,
            allAdminUsers: [],
          ),
        );
        return;
      }

      // Get current user's role
      final userRole = _roleService.getUserRole(currentUser.uid);

      state = AsyncValue.data(
        AdminAccessState(
          currentUserId: currentUser.uid,
          currentUserRole: userRole,
          isAdmin: userRole?.role == AdminRole.admin,
          allAdminUsers: _roleService.getAllAdminUsers(),
        ),
      );
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  /// Check if current user has a specific permission
  bool hasPermission(AdminPermission permission) {
    final asyncState = state;
    if (asyncState is! AsyncData) return false;

    final data = asyncState.value;
    if (data.currentUserId == null || data.currentUserRole == null) {
      return false;
    }

    return _roleService.hasPermission(data.currentUserId!, permission);
  }

  /// Check if current user has any of the given permissions
  bool hasAnyPermission(List<AdminPermission> permissions) {
    final asyncState = state;
    if (asyncState is! AsyncData) return false;

    final data = asyncState.value;
    if (data.currentUserId == null) return false;

    return _roleService.hasAnyPermission(data.currentUserId!, permissions);
  }

  /// Check if current user has all of the given permissions
  bool hasAllPermissions(List<AdminPermission> permissions) {
    final asyncState = state;
    if (asyncState is! AsyncData) return false;

    final data = asyncState.value;
    if (data.currentUserId == null) return false;

    return _roleService.hasAllPermissions(data.currentUserId!, permissions);
  }

  /// Check if current user is an admin
  bool get isAdmin {
    final asyncState = state;
    if (asyncState is! AsyncData) return false;
    return asyncState.value.isAdmin;
  }

  /// Get current user's role
  UserAdminRole? get currentUserRole {
    final asyncState = state;
    if (asyncState is! AsyncData) return null;
    return asyncState.value.currentUserRole;
  }

  /// Get all admin users
  List<UserAdminRole> get allAdminUsers {
    final asyncState = state;
    if (asyncState is! AsyncData) return [];
    return asyncState.value.allAdminUsers;
  }

  /// Assign role to a user (admin only)
  Future<bool> assignRoleToUser({
    required String userId,
    required String userName,
    required String userEmail,
    required AdminRole role,
  }) async {
    if (!isAdmin) {
      print('Only admins can assign roles');
      return false;
    }

    try {
      final currentUserId = _authService.currentUser?.uid;
      if (currentUserId == null) return false;

      final success = await _roleService.assignRoleToUser(
        userId: userId,
        userName: userName,
        userEmail: userEmail,
        role: role,
        assignedByUserId: currentUserId,
      );

      if (success) {
        // Refresh state
        await _initialize();
      }

      return success;
    } catch (e) {
      print('Error assigning role: $e');
      return false;
    }
  }

  /// Update user's role (admin only)
  Future<bool> updateUserRole({
    required String userId,
    required AdminRole newRole,
  }) async {
    if (!isAdmin) {
      print('Only admins can update roles');
      return false;
    }

    try {
      final currentUserId = _authService.currentUser?.uid;
      if (currentUserId == null) return false;

      final success = await _roleService.updateUserRole(
        userId: userId,
        newRole: newRole,
        updatedByUserId: currentUserId,
      );

      if (success) {
        // Refresh state
        await _initialize();
      }

      return success;
    } catch (e) {
      print('Error updating role: $e');
      return false;
    }
  }

  /// Revoke admin access (admin only)
  Future<bool> revokeAdminRole({required String userId}) async {
    if (!isAdmin) {
      print('Only admins can revoke roles');
      return false;
    }

    try {
      final currentUserId = _authService.currentUser?.uid;
      if (currentUserId == null) return false;

      final success = await _roleService.revokeAdminRole(
        userId: userId,
        revokedByUserId: currentUserId,
      );

      if (success) {
        // Refresh state
        await _initialize();
      }

      return success;
    } catch (e) {
      print('Error revoking role: $e');
      return false;
    }
  }

  /// Refresh admin roles
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    await _initialize();
  }
}

/// State class for admin access
class AdminAccessState {
  final String? currentUserId;
  final UserAdminRole? currentUserRole;
  final bool isAdmin;
  final List<UserAdminRole> allAdminUsers;

  const AdminAccessState({
    required this.currentUserId,
    required this.currentUserRole,
    required this.isAdmin,
    required this.allAdminUsers,
  });

  /// Get current user's role display name
  String get roleDisplayName => currentUserRole?.role.displayName ?? 'No Role';

  /// Get current user's role description
  String get roleDescription =>
      currentUserRole?.role.description ?? 'Not an admin user';

  /// Count of admin users by role
  Map<AdminRole, int> get adminUsersByRole {
    final counts = <AdminRole, int>{};
    for (final role in AdminRole.values) {
      counts[role] = allAdminUsers
          .where((user) => user.role == role)
          .length;
    }
    return counts;
  }

  @override
  String toString() =>
      'AdminAccessState(currentUserId: $currentUserId, role: ${currentUserRole?.role.displayName}, isAdmin: $isAdmin, adminCount: ${allAdminUsers.length})';
}
