import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shinjuu_league/data/models/admin_role.dart';
import 'package:shinjuu_league/data/providers/service_providers.dart';
import 'package:shinjuu_league/ui/widgets/custom_button.dart';

/// Admin Roles Management Screen (Phase 33 Part 2).
///
/// Allows authorized admins to:
/// - View all current admin users and their roles
/// - Assign new admin roles to users
/// - Update existing admin role assignments
/// - Revoke admin access
/// - View role history for audit purposes
class AdminRolesScreen extends ConsumerStatefulWidget {
  const AdminRolesScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AdminRolesScreen> createState() => _AdminRolesScreenState();
}

class _AdminRolesScreenState extends ConsumerState<AdminRolesScreen> {
  bool _showAssignForm = false;
  String? _selectedNewRole;
  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _userEmailController = TextEditingController();

  @override
  void dispose() {
    _userIdController.dispose();
    _userNameController.dispose();
    _userEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adminAccessState = ref.watch(adminAccessViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Roles Management'),
        centerTitle: true,
        elevation: 0,
      ),
      body: adminAccessState.when(
        data: (state) {
          // Check if current user has permission to manage roles
          final canManageRoles = ref.read(adminAccessViewModelProvider.notifier).hasPermission(
            AdminPermission.manageAdminRoles,
          );

          if (!canManageRoles) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.lock_outline,
                    size: 48,
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Insufficient Permissions',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your role (${state.currentUserRole?.role.displayName}) does not have permission to manage admin roles.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Current User Info Card
                _buildCurrentUserCard(state),
                const SizedBox(height: 24),

                // Admin Users List
                _buildAdminUsersList(state),
                const SizedBox(height: 24),

                // Assign New Admin Button
                SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    label: _showAssignForm ? 'Cancel' : 'Assign New Admin',
                    onPressed: () {
                      setState(() {
                        _showAssignForm = !_showAssignForm;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Assign Form
                if (_showAssignForm) ...[
                  _buildAssignForm(context),
                  const SizedBox(height: 24),
                ],

                // Role Reference Card
                _buildRoleReferenceCard(),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Error: $error',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentUserCard(AdminAccessState state) {
    final currentRole = state.currentUserRole;
    if (currentRole == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No role assigned'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Role',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Color(currentRole.role.badgeColor),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentRole.role.displayName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        currentRole.role.description,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminUsersList(AdminAccessState state) {
    if (state.allAdminUsers.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Text(
              'No admin users assigned yet',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Admin Users (${state.adminUsersByRole.values.fold(0, (a, b) => a + b)})',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...state.allAdminUsers.map((user) => _buildAdminUserCard(user)),
      ],
    );
  }

  Widget _buildAdminUserCard(UserAdminRole user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.userName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        user.userEmail,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Assigned: ${user.assignedAt.toString().split('.')[0]}',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Color(user.role.badgeColor).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Color(user.role.badgeColor),
                    ),
                  ),
                  child: Text(
                    user.role.displayName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(user.role.badgeColor),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    label: 'Update Role',
                    onPressed: () => _showRoleUpdateDialog(user),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CustomButton(
                    label: 'Revoke',
                    onPressed: () => _showRevokeConfirmation(user),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignForm(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Assign New Admin',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _userIdController,
              decoration: const InputDecoration(
                labelText: 'User ID',
                hintText: 'Enter Firebase UID',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _userNameController,
              decoration: const InputDecoration(
                labelText: 'User Name',
                hintText: 'Enter display name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _userEmailController,
              decoration: const InputDecoration(
                labelText: 'User Email',
                hintText: 'Enter email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedNewRole,
              decoration: const InputDecoration(
                labelText: 'Role',
                border: OutlineInputBorder(),
              ),
              items: AdminRole.values.map((role) {
                return DropdownMenuItem(
                  value: role.toString().split('.').last,
                  child: Text(role.displayName),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedNewRole = value;
                });
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                label: 'Assign',
                onPressed: () => _assignNewAdmin(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleReferenceCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Role Reference',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...AdminRole.values.map((role) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Color(role.badgeColor),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          role.displayName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 18, top: 4),
                      child: Text(
                        role.description,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Future<void> _showRoleUpdateDialog(UserAdminRole user) async {
    String? newRole = user.role.toString().split('.').last;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Role for ${user.userName}'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: newRole,
                decoration: const InputDecoration(
                  labelText: 'New Role',
                  border: OutlineInputBorder(),
                ),
                items: AdminRole.values.map((role) {
                  return DropdownMenuItem(
                    value: role.toString().split('.').last,
                    child: Text(role.displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    newRole = value;
                  });
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (newRole != null) {
                _updateUserRole(user.userId, newRole!);
                Navigator.pop(context);
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _showRevokeConfirmation(UserAdminRole user) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revoke Admin Access'),
        content: Text(
          'Are you sure you want to revoke admin access for ${user.userName}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () {
              _revokeAdminRole(user.userId);
              Navigator.pop(context);
            },
            child: const Text('Revoke'),
          ),
        ],
      ),
    );
  }

  Future<void> _assignNewAdmin() async {
    if (_userIdController.text.isEmpty ||
        _userNameController.text.isEmpty ||
        _userEmailController.text.isEmpty ||
        _selectedNewRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    final viewModel = ref.read(adminAccessViewModelProvider.notifier);
    final roleEnum = AdminRole.values.firstWhere(
      (r) => r.toString().split('.').last == _selectedNewRole,
    );

    final success = await viewModel.assignRoleToUser(
      userId: _userIdController.text.trim(),
      userName: _userNameController.text.trim(),
      userEmail: _userEmailController.text.trim(),
      role: roleEnum,
    );

    if (success) {
      _userIdController.clear();
      _userNameController.clear();
      _userEmailController.clear();
      setState(() {
        _showAssignForm = false;
        _selectedNewRole = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Admin role assigned successfully')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to assign admin role')),
        );
      }
    }
  }

  Future<void> _updateUserRole(String userId, String newRoleStr) async {
    final roleEnum = AdminRole.values.firstWhere(
      (r) => r.toString().split('.').last == newRoleStr,
    );

    final viewModel = ref.read(adminAccessViewModelProvider.notifier);
    final success = await viewModel.updateUserRole(
      userId: userId,
      newRole: roleEnum,
    );

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User role updated successfully')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update user role')),
        );
      }
    }
  }

  Future<void> _revokeAdminRole(String userId) async {
    final viewModel = ref.read(adminAccessViewModelProvider.notifier);
    final success = await viewModel.revokeAdminRole(userId: userId);

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Admin role revoked successfully')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to revoke admin role')),
        );
      }
    }
  }
}
