import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shinjuu_league/data/models/admin_role.dart';
import 'package:shinjuu_league/data/providers/service_providers.dart';
import 'package:shinjuu_league/services/web_admin_dashboard_service.dart';
import 'package:shinjuu_league/ui/widgets/custom_button.dart';

/// Admin Dashboard Screen (Phase 32 Part 2).
///
/// Main dashboard showing:
/// - Feature status overview (enabled/disabled counts)
/// - Statistics (total features, rollout %, changes)
/// - Recent changes (last 10)
/// - Quick actions (presets, kill switches)
class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  late WebAdminDashboardService _dashboardService;
  DashboardSnapshot? _currentSnapshot;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // TODO: Inject WebAdminDashboardService from Riverpod provider
    _dashboardService = WebAdminDashboardService(
      apiService: null as dynamic, // Placeholder
    );
    _loadDashboard();
    _dashboardService.startPolling();
  }

  @override
  void dispose() {
    _dashboardService.dispose();
    super.dispose();
  }

  Future<void> _loadDashboard() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final snapshot = _dashboardService.getDashboardState();
      setState(() {
        _currentSnapshot = snapshot;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load dashboard: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final adminAccessState = ref.watch(adminAccessViewModelProvider);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Admin Dashboard'),
            centerTitle: true,
            elevation: 0,
          ),
          body: adminAccessState.when(
            data: (state) {
              // Check if user has permission to view dashboard
              final canViewDashboard = ref
                  .read(adminAccessViewModelProvider.notifier)
                  .hasPermission(AdminPermission.viewFeatureFlags) &&
                  ref
                      .read(adminAccessViewModelProvider.notifier)
                      .hasPermission(AdminPermission.viewDifficulty);

              if (!canViewDashboard) {
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
                        'You do not have permission to access the admin dashboard.',
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
                      : _buildDashboard();
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
            onPressed: _loadDashboard,
            tooltip: 'Refresh',
            child: const Icon(Icons.refresh),
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
            onPressed: _loadDashboard,
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    if (_currentSnapshot == null) {
      return const Center(child: Text('No data available'));
    }

    final snapshot = _currentSnapshot!;
    final stats = snapshot.statistics;
    final difficulty = snapshot.difficulty;
    final features = snapshot.features;
    final changes = snapshot.recentChanges;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Statistics Section
          _buildStatisticsCard(stats),
          const SizedBox(height: 24),

          // Difficulty Settings Section
          _buildDifficultySection(difficulty),
          const SizedBox(height: 24),

          // Features Overview Section
          _buildFeaturesOverview(features),
          const SizedBox(height: 24),

          // Recent Changes Section
          _buildRecentChangesSection(changes),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildStatisticsCard(Map<String, dynamic> stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Statistics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildStatRow(
              'Total Features',
              stats['features']?['total']?.toString() ?? '0',
            ),
            const SizedBox(height: 8),
            _buildStatRow(
              'Enabled Features',
              '${stats['features']?['enabled']?.toString() ?? '0'} '
              '(${(stats['features']?['enabledPercentage'] as num?)?.toStringAsFixed(1) ?? '0'}%)',
            ),
            const SizedBox(height: 8),
            _buildStatRow(
              'Average Rollout',
              '${stats['rollout']?['average']?.toString() ?? '0'}%',
            ),
            const SizedBox(height: 8),
            _buildStatRow(
              'Change History Size',
              stats['history']?['size']?.toString() ?? '0',
            ),
            const SizedBox(height: 8),
            _buildStatRow(
              'Config Snapshots',
              stats['snapshots']?['count']?.toString() ?? '0',
            ),
            const SizedBox(height: 8),
            _buildStatRow(
              'Last Updated',
              _formatTime(_currentSnapshot!.timestamp),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14)),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildDifficultySection(Map<String, dynamic> difficulty) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Difficulty Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildMultiplierRow(
              'Level',
              difficulty['levelMultiplier']?.toString() ?? '1.0',
            ),
            const SizedBox(height: 12),
            _buildMultiplierRow(
              'Cooldown',
              difficulty['cooldownMultiplier']?.toString() ?? '1.0',
            ),
            const SizedBox(height: 12),
            _buildMultiplierRow(
              'Damage',
              difficulty['damageMultiplier']?.toString() ?? '1.0',
            ),
            const SizedBox(height: 20),
            const Text(
              'Presets',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPresetButton('Easy', 'easy'),
                _buildPresetButton('Normal', 'normal'),
                _buildPresetButton('Hard', 'hard'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMultiplierRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.blue,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPresetButton(String label, String preset) {
    return SizedBox(
      width: 80,
      child: CustomButton(
        label: label,
        onPressed: () => _applyPreset(preset),
        fontSize: 12,
      ),
    );
  }

  Widget _buildFeaturesOverview(List<Map<String, dynamic>> features) {
    final enabledCount = features.where((f) => f['enabled'] == true).length;
    final disabledCount = features.length - enabledCount;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Features Overview',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildFeatureStatusBox(
                    'Enabled',
                    enabledCount,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildFeatureStatusBox(
                    'Disabled',
                    disabledCount,
                    Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Feature List',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: ListView.separated(
                itemCount: features.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final feature = features[index];
                  return _buildFeatureItem(feature);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureStatusBox(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(Map<String, dynamic> feature) {
    final isEnabled = feature['enabled'] == true;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            isEnabled ? Icons.check_circle : Icons.cancel,
            color: isEnabled ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature['name']?.toString() ?? 'Unknown',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (feature['description'] != null)
                  Text(
                    feature['description'].toString(),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${feature['rolloutPercentage']?.toString() ?? '0'}%',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentChangesSection(List<Map<String, dynamic>> changes) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Changes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (changes.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'No changes yet',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              SizedBox(
                height: 300,
                child: ListView.separated(
                  itemCount: changes.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final change = changes[index];
                    return _buildChangeItem(change);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildChangeItem(Map<String, dynamic> change) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  change['type']?.toString() ?? 'UNKNOWN',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              Text(
                _formatTime(DateTime.parse(change['timestamp']?.toString() ?? DateTime.now().toIso8601String())),
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            change['key']?.toString() ?? '',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          if (change['oldValue'] != null && change['newValue'] != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${change['oldValue']} → ${change['newValue']}',
                style: const TextStyle(fontSize: 11),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _applyPreset(String preset) async {
    try {
      final result = await _dashboardService.applyDifficultyPreset(preset);
      if (result && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Applied $preset preset')),
        );
        _loadDashboard();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to apply preset: $e')),
        );
      }
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inSeconds < 60) {
      return 'just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }
}
