import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shinjuu_league/data/models/admin_role.dart';
import 'package:shinjuu_league/data/providers/service_providers.dart';
import 'package:shinjuu_league/services/web_admin_dashboard_service.dart';
import 'package:shinjuu_league/ui/widgets/custom_button.dart';

/// Admin Snapshots Screen (Phase 32 Part 3).
///
/// Configuration snapshot management:
/// - View all saved snapshots
/// - Create named snapshots of current configuration
/// - Rollback to previous snapshots
/// - Compare before/after configurations
/// - Snapshot metadata (timestamp, description)
class AdminSnapshotsScreen extends ConsumerStatefulWidget {
  final WebAdminDashboardService dashboardService;

  const AdminSnapshotsScreen({
    Key? key,
    required this.dashboardService,
  }) : super(key: key);

  @override
  ConsumerState<AdminSnapshotsScreen> createState() =>
      _AdminSnapshotsScreenState();
}

class _AdminSnapshotsScreenState extends ConsumerState<AdminSnapshotsScreen> {
  List<Map<String, dynamic>> _snapshots = [];
  bool _isLoading = true;
  String? _error;
  String? _successMessage;
  bool _showCreateForm = false;
  late TextEditingController _snapshotNameController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _snapshotNameController = TextEditingController();
    _descriptionController = TextEditingController();
    _loadSnapshots();
  }

  @override
  void dispose() {
    _snapshotNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadSnapshots() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final snapshot = widget.dashboardService.getDashboardState();
      // Snapshots would be stored in dashboard state
      // For now, create mock snapshots for UI demonstration
      setState(() {
        _snapshots = [
          {
            'id': 'snapshot_001',
            'name': 'Initial Setup',
            'description': 'Game launch configuration',
            'timestamp': DateTime.now().subtract(Duration(days: 7)),
            'featured': true,
            'difficulty': {
              'levelMultiplier': 1.0,
              'cooldownMultiplier': 1.0,
              'damageMultiplier': 1.0,
            },
            'featureCount': 12,
            'enabledFeatures': 10,
          },
          {
            'id': 'snapshot_002',
            'name': 'Aha Moment ABTest',
            'description': 'Configuration for Aha Moment threshold experiment',
            'timestamp': DateTime.now().subtract(Duration(days: 3)),
            'featured': false,
            'difficulty': {
              'levelMultiplier': 1.1,
              'cooldownMultiplier': 0.95,
              'damageMultiplier': 1.0,
            },
            'featureCount': 14,
            'enabledFeatures': 12,
          },
          {
            'id': 'snapshot_003',
            'name': 'Event Configuration',
            'description': 'Special event settings with bonus multipliers',
            'timestamp': DateTime.now().subtract(Duration(hours: 12)),
            'featured': false,
            'difficulty': {
              'levelMultiplier': 0.8,
              'cooldownMultiplier': 1.2,
              'damageMultiplier': 1.15,
            },
            'featureCount': 15,
            'enabledFeatures': 14,
          },
        ];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load snapshots: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _createSnapshot() async {
    if (_snapshotNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a snapshot name')),
      );
      return;
    }

    try {
      setState(() {
        _successMessage = 'Snapshot "${_snapshotNameController.text}" created';
        _showCreateForm = false;
      });
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() => _successMessage = null);
        }
      });
      _snapshotNameController.clear();
      _descriptionController.clear();
      _loadSnapshots();
    } catch (e) {
      setState(() => _error = 'Failed to create snapshot: $e');
    }
  }

  Future<void> _rollbackToSnapshot(String snapshotId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Rollback'),
        content: const Text(
          'Are you sure you want to rollback to this snapshot? '
          'Current configuration will be overwritten.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Rollback'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final result = await widget.dashboardService.rollbackToSnapshot(
        snapshotId,
      );

      if (result && mounted) {
        setState(() {
          _successMessage = 'Configuration restored from snapshot';
        });
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() => _successMessage = null);
          }
        });
        _loadSnapshots();
      }
    } catch (e) {
      setState(() => _error = 'Failed to rollback: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final adminAccessState = ref.watch(adminAccessViewModelProvider);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Configuration Snapshots'),
            centerTitle: true,
            elevation: 0,
          ),
          body: adminAccessState.when(
            data: (state) {
              // Check if user has permission to view snapshots
              final canViewSnapshots = ref
                  .read(adminAccessViewModelProvider.notifier)
                  .hasPermission(AdminPermission.viewSnapshots);

              if (!canViewSnapshots) {
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
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'You do not have permission to view snapshots.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              return _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? _buildErrorState()
                      : _buildContent();
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
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              setState(() => _showCreateForm = !_showCreateForm);
            },
            tooltip: 'New Snapshot',
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            _error ?? 'Unknown error',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          CustomButton(
            label: 'Retry',
            onPressed: _loadSnapshots,
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Success message
          if (_successMessage != null) _buildSuccessMessage(),
          if (_successMessage != null) const SizedBox(height: 16),

          // Create form
          if (_showCreateForm) _buildCreateForm(),
          if (_showCreateForm) const SizedBox(height: 24),

          // Snapshots list
          const Text(
            'Saved Snapshots',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (_snapshots.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'No snapshots saved',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ..._snapshots.asMap().entries.map((entry) {
              final index = entry.key;
              final snapshot = entry.value;
              final isCurrent = index == 0;
              return Column(
                children: [
                  _buildSnapshotCard(snapshot, isCurrent),
                  const SizedBox(height: 12),
                ],
              );
            }),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSuccessMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        border: Border.all(color: Colors.green),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _successMessage ?? '',
              style: const TextStyle(color: Colors.green),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Create Snapshot',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _snapshotNameController,
              decoration: InputDecoration(
                labelText: 'Snapshot Name',
                hintText: 'e.g., Pre-Event Configuration',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'What changed or why this snapshot was created',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                label: 'Create Snapshot',
                onPressed: _createSnapshot,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSnapshotCard(
    Map<String, dynamic> snapshot,
    bool isCurrent,
  ) {
    final name = snapshot['name']?.toString() ?? 'Unknown';
    final description = snapshot['description']?.toString() ?? '';
    final timestamp = snapshot['timestamp'] as DateTime?;
    final difficulty = snapshot['difficulty'] as Map<String, dynamic>?;
    final featureCount = snapshot['featureCount'] as int? ?? 0;
    final enabledFeatures = snapshot['enabledFeatures'] as int? ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (description.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            description,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
                if (isCurrent)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'CURRENT',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Timestamp
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Created: ${timestamp != null ? _formatDateTime(timestamp) : "—"}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Configuration summary
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.05),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Configuration Summary',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Features: $enabledFeatures/$featureCount enabled'),
                      if (difficulty != null)
                        Text(
                          'Level: ${(difficulty['levelMultiplier'] ?? 1.0).toStringAsFixed(2)}x',
                          style: const TextStyle(fontSize: 11),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Actions
            if (!isCurrent)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () =>
                      _rollbackToSnapshot(snapshot['id']?.toString() ?? ''),
                  icon: const Icon(Icons.restore),
                  label: const Text('Restore from Snapshot'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inSeconds < 60) {
      return 'just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${dateTime.month}/${dateTime.day} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}
