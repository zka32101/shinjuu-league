/// Admin Role Model (Phase 33 Part 1).
///
/// Role-based access control for admin dashboard.
/// Three tiers: Admin (full access), Operator (edit features/difficulty),
/// Viewer (read-only access).

enum AdminRole {
  admin,      // Full access to all admin features + user management
  operator,   // Can edit features, difficulty, experiments, create snapshots
  viewer,     // Read-only access to all screens
}

enum AdminPermission {
  // Feature Flags
  viewFeatureFlags,
  editFeatureFlags,
  toggleKillSwitch,

  // Difficulty Settings
  viewDifficulty,
  editDifficulty,
  applyDifficultyPreset,

  // Experiments
  viewExperiments,
  createExperiment,
  updateExperimentRollout,

  // Audit Log
  viewAuditLog,
  exportAuditLog,

  // Snapshots
  viewSnapshots,
  createSnapshot,
  rollbackSnapshot,

  // User Management
  viewAdminUsers,
  manageAdminRoles,
  viewUserAttribution,
}

/// Extension to map roles to their permissions
extension AdminRolePermissions on AdminRole {
  Set<AdminPermission> get permissions {
    switch (this) {
      case AdminRole.admin:
        return {
          // All permissions
          AdminPermission.viewFeatureFlags,
          AdminPermission.editFeatureFlags,
          AdminPermission.toggleKillSwitch,
          AdminPermission.viewDifficulty,
          AdminPermission.editDifficulty,
          AdminPermission.applyDifficultyPreset,
          AdminPermission.viewExperiments,
          AdminPermission.createExperiment,
          AdminPermission.updateExperimentRollout,
          AdminPermission.viewAuditLog,
          AdminPermission.exportAuditLog,
          AdminPermission.viewSnapshots,
          AdminPermission.createSnapshot,
          AdminPermission.rollbackSnapshot,
          AdminPermission.viewAdminUsers,
          AdminPermission.manageAdminRoles,
          AdminPermission.viewUserAttribution,
        };

      case AdminRole.operator:
        return {
          // View + Edit permissions, but no user management
          AdminPermission.viewFeatureFlags,
          AdminPermission.editFeatureFlags,
          AdminPermission.viewDifficulty,
          AdminPermission.editDifficulty,
          AdminPermission.applyDifficultyPreset,
          AdminPermission.viewExperiments,
          AdminPermission.createExperiment,
          AdminPermission.updateExperimentRollout,
          AdminPermission.viewAuditLog,
          AdminPermission.viewSnapshots,
          AdminPermission.createSnapshot,
          AdminPermission.viewUserAttribution,
        };

      case AdminRole.viewer:
        return {
          // Read-only permissions only
          AdminPermission.viewFeatureFlags,
          AdminPermission.viewDifficulty,
          AdminPermission.viewExperiments,
          AdminPermission.viewAuditLog,
          AdminPermission.viewSnapshots,
          AdminPermission.viewUserAttribution,
        };
    }
  }

  /// Human-readable display name
  String get displayName {
    switch (this) {
      case AdminRole.admin:
        return 'Admin';
      case AdminRole.operator:
        return 'Operator';
      case AdminRole.viewer:
        return 'Viewer';
    }
  }

  /// Color for role badge display
  int get badgeColor {
    switch (this) {
      case AdminRole.admin:
        return 0xFFD32F2F; // Red
      case AdminRole.operator:
        return 0xFFF57C00; // Orange
      case AdminRole.viewer:
        return 0xFF1976D2; // Blue
    }
  }

  /// Description of what role can do
  String get description {
    switch (this) {
      case AdminRole.admin:
        return 'Full access to all admin features and user management';
      case AdminRole.operator:
        return 'Can edit features, difficulty, and experiments';
      case AdminRole.viewer:
        return 'Read-only access to dashboard and audit logs';
    }
  }
}

/// Admin user role assignment model
class UserAdminRole {
  final String userId;
  final String userName;
  final String userEmail;
  final AdminRole role;
  final DateTime assignedAt;
  final String? assignedBy; // User ID of who assigned this role

  const UserAdminRole({
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.role,
    required this.assignedAt,
    this.assignedBy,
  });

  /// Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'role': role.toString().split('.').last,
      'assignedAt': assignedAt.toIso8601String(),
      'assignedBy': assignedBy,
    };
  }

  /// Create from JSON
  factory UserAdminRole.fromJson(Map<String, dynamic> json) {
    final roleStr = json['role']?.toString() ?? 'viewer';
    final role = AdminRole.values.firstWhere(
      (r) => r.toString().split('.').last == roleStr,
      orElse: () => AdminRole.viewer,
    );

    return UserAdminRole(
      userId: json['userId']?.toString() ?? '',
      userName: json['userName']?.toString() ?? '',
      userEmail: json['userEmail']?.toString() ?? '',
      role: role,
      assignedAt: json['assignedAt'] != null
          ? DateTime.parse(json['assignedAt'].toString())
          : DateTime.now(),
      assignedBy: json['assignedBy']?.toString(),
    );
  }

  /// Create a copy with modified fields
  UserAdminRole copyWith({
    String? userId,
    String? userName,
    String? userEmail,
    AdminRole? role,
    DateTime? assignedAt,
    String? assignedBy,
  }) {
    return UserAdminRole(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      role: role ?? this.role,
      assignedAt: assignedAt ?? this.assignedAt,
      assignedBy: assignedBy ?? this.assignedBy,
    );
  }

  @override
  String toString() =>
      'UserAdminRole(userId: $userId, role: ${role.displayName}, assignedAt: $assignedAt)';
}
