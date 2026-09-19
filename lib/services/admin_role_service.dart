import 'package:shinjuu_league/data/models/admin_role.dart';
import 'package:shinjuu_league/services/firestore_service.dart';

/// Admin Role Service (Phase 33 Part 1).
///
/// Manages admin user roles and permissions.
/// - Assign/revoke roles to admin users
/// - Check permissions for current user
/// - Track role assignments with audit trail
class AdminRoleService {
  final FirestoreService _firestoreService;

  // Cache of admin users and their roles (userId -> UserAdminRole)
  final Map<String, UserAdminRole> _roleCache = {};
  bool _cacheLoaded = false;

  AdminRoleService({required FirestoreService firestoreService})
      : _firestoreService = firestoreService;

  /// Load all admin user roles from Firestore
  Future<void> loadAdminRoles() async {
    try {
      final snapshot = await _firestoreService.collection('admin_users').get();
      _roleCache.clear();

      for (final doc in snapshot.docs) {
        final roleData = doc.data() as Map<String, dynamic>;
        final userAdminRole = UserAdminRole.fromJson(roleData);
        _roleCache[userAdminRole.userId] = userAdminRole;
      }

      _cacheLoaded = true;
    } catch (e) {
      print('Error loading admin roles: $e');
      rethrow;
    }
  }

  /// Get role for a specific user
  UserAdminRole? getUserRole(String userId) {
    if (!_cacheLoaded) {
      throw StateError('Admin roles not loaded. Call loadAdminRoles() first.');
    }
    return _roleCache[userId];
  }

  /// Get all admin users and their roles
  List<UserAdminRole> getAllAdminUsers() {
    if (!_cacheLoaded) {
      throw StateError('Admin roles not loaded. Call loadAdminRoles() first.');
    }
    return _roleCache.values.toList();
  }

  /// Check if user has a specific permission
  bool hasPermission(String userId, AdminPermission permission) {
    final role = getUserRole(userId);
    if (role == null) return false; // Not an admin user

    return role.role.permissions.contains(permission);
  }

  /// Check if user has any of the given permissions
  bool hasAnyPermission(String userId, List<AdminPermission> permissions) {
    final role = getUserRole(userId);
    if (role == null) return false;

    final userPermissions = role.role.permissions;
    return permissions.any((p) => userPermissions.contains(p));
  }

  /// Check if user has all of the given permissions
  bool hasAllPermissions(String userId, List<AdminPermission> permissions) {
    final role = getUserRole(userId);
    if (role == null) return false;

    final userPermissions = role.role.permissions;
    return permissions.every((p) => userPermissions.contains(p));
  }

  /// Assign role to a user (Admin only)
  Future<bool> assignRoleToUser({
    required String userId,
    required String userName,
    required String userEmail,
    required AdminRole role,
    required String assignedByUserId,
  }) async {
    try {
      final userAdminRole = UserAdminRole(
        userId: userId,
        userName: userName,
        userEmail: userEmail,
        role: role,
        assignedAt: DateTime.now(),
        assignedBy: assignedByUserId,
      );

      await _firestoreService.setData(
        path: 'admin_users/$userId',
        data: userAdminRole.toJson(),
      );

      // Update cache
      _roleCache[userId] = userAdminRole;

      // Log to audit trail
      await _logRoleChange(
        userId: userId,
        action: 'ROLE_ASSIGNED',
        details: {
          'new_role': role.toString().split('.').last,
          'assigned_by': assignedByUserId,
        },
      );

      return true;
    } catch (e) {
      print('Error assigning role: $e');
      return false;
    }
  }

  /// Update user's role (Admin only)
  Future<bool> updateUserRole({
    required String userId,
    required AdminRole newRole,
    required String updatedByUserId,
  }) async {
    try {
      final currentRole = getUserRole(userId);
      if (currentRole == null) {
        print('User $userId not found in admin roles');
        return false;
      }

      final updatedRole = currentRole.copyWith(
        role: newRole,
        assignedAt: DateTime.now(),
        assignedBy: updatedByUserId,
      );

      await _firestoreService.setData(
        path: 'admin_users/$userId',
        data: updatedRole.toJson(),
      );

      // Update cache
      _roleCache[userId] = updatedRole;

      // Log to audit trail
      await _logRoleChange(
        userId: userId,
        action: 'ROLE_UPDATED',
        details: {
          'old_role': currentRole.role.toString().split('.').last,
          'new_role': newRole.toString().split('.').last,
          'updated_by': updatedByUserId,
        },
      );

      return true;
    } catch (e) {
      print('Error updating user role: $e');
      return false;
    }
  }

  /// Revoke admin access from user (Admin only)
  Future<bool> revokeAdminRole({
    required String userId,
    required String revokedByUserId,
  }) async {
    try {
      final currentRole = getUserRole(userId);
      if (currentRole == null) {
        print('User $userId not found in admin roles');
        return false;
      }

      await _firestoreService.deleteData(
        path: 'admin_users/$userId',
      );

      // Update cache
      _roleCache.remove(userId);

      // Log to audit trail
      await _logRoleChange(
        userId: userId,
        action: 'ROLE_REVOKED',
        details: {
          'revoked_role': currentRole.role.toString().split('.').last,
          'revoked_by': revokedByUserId,
        },
      );

      return true;
    } catch (e) {
      print('Error revoking admin role: $e');
      return false;
    }
  }

  /// Get role assignment history for a user
  Future<List<Map<String, dynamic>>> getRoleHistory(String userId) async {
    try {
      final snapshot = await _firestoreService
          .collection('admin_role_audit_log')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print('Error fetching role history: $e');
      return [];
    }
  }

  /// Log role change to audit trail
  Future<void> _logRoleChange({
    required String userId,
    required String action,
    required Map<String, dynamic> details,
  }) async {
    try {
      final logEntry = {
        'userId': userId,
        'action': action,
        'timestamp': DateTime.now().toIso8601String(),
        ...details,
      };

      await _firestoreService.addData(
        path: 'admin_role_audit_log',
        data: logEntry,
      );
    } catch (e) {
      print('Error logging role change: $e');
      // Don't rethrow - audit logging failure shouldn't fail the main operation
    }
  }

  /// Clear cache (for testing or when admin roles are updated externally)
  void clearCache() {
    _roleCache.clear();
    _cacheLoaded = false;
  }

  /// Get cache size (for debugging)
  int get cacheSize => _roleCache.length;

  /// Check if cache is loaded
  bool get isCacheLoaded => _cacheLoaded;
}
