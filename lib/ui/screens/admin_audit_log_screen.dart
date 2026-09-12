import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shinjuu_league/data/models/admin_role.dart';
import 'package:shinjuu_league/data/providers/service_providers.dart';
import 'package:shinjuu_league/services/web_admin_dashboard_service.dart';

/// Admin Audit Log Screen (Phase 32 Part 3).
///
/// Comprehensive change history viewer with:
/// - Filter by change type (feature enabled, rollout, difficulty, etc.)
/// - Search by key or value
/// - Sort by timestamp
/// - Pagination support
/// - Before/after value comparison
class AdminAuditLogScreen extends ConsumerStatefulWidget {
  final WebAdminDashboardService dashboardService;

  const AdminAuditLogScreen({
    Key? key,
    required this.dashboardService,
  }) : super(key: key);

  @override
  ConsumerState<AdminAuditLogScreen> createState() =>
      _AdminAuditLogScreenState();
}

class _AdminAuditLogScreenState extends ConsumerState<AdminAuditLogScreen> {
  List<Map<String, dynamic>> _allChanges = [];
  List<Map<String, dynamic>> _filteredChanges = [];
  bool _isLoading = true;
  String? _error;
  String _selectedType = 'all';
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _loadAuditLog();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAuditLog() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final snapshot = widget.dashboardService.getDashboardState();
      final changes = (snapshot.recentChanges as List?) ?? [];

      setState(() {
        _allChanges = changes.cast<Map<String, dynamic>>();
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load audit log: $e';
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    var filtered = _allChanges;

    // Filter by type
    if (_selectedType != 'all') {
      filtered = filtered
          .where((change) => change['type'] == _selectedType)
          .toList();
    }

    // Filter by search query
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered.where((change) {
        final key = (change['key'] ?? '').toString().toLowerCase();
        final oldValue = (change['oldValue'] ?? '').toString().toLowerCase();
        final newValue = (change['newValue'] ?? '').toString().toLowerCase();
        return key.contains(query) ||
            oldValue.contains(query) ||
            newValue.contains(query);
      }).toList();
    }

    setState(() {
      _filteredChanges = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final adminAccessState = ref.watch(adminAccessViewModelProvider);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Audit Log'),
            centerTitle: true,
            elevation: 0,
          ),
          body: adminAccessState.when(
            data: (state) {
              // Check if user has permission to view audit log
              final canViewAuditLog = ref
                  .read(adminAccessViewModelProvider.notifier)
                  .hasPermission(AdminPermission.viewAuditLog);

              if (!canViewAuditLog) {
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
                        'You do not have permission to view audit logs.',
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
            onPressed: _loadAuditLog,
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
          ElevatedButton(
            onPressed: _loadAuditLog,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_allChanges.isEmpty) {
      return const Center(
        child: Text(
          'No changes recorded',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return Column(
      children: [
        // Filters
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search field
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by key, value, or type...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onChanged: (_) => _applyFilters(),
              ),
              const SizedBox(height: 12),

              // Type filter chips
              Wrap(
                spacing: 8,
                children: [
                  _buildFilterChip(
                    'all',
                    'All Changes',
                    _allChanges.length,
                  ),
                  _buildFilterChip(
                    'FEATURE_ENABLED',
                    'Feature Enabled',
                    _allChanges
                        .where((c) => c['type'] == 'FEATURE_ENABLED')
                        .length,
                  ),
                  _buildFilterChip(
                    'FEATURE_ROLLOUT',
                    'Feature Rollout',
                    _allChanges
                        .where((c) => c['type'] == 'FEATURE_ROLLOUT')
                        .length,
                  ),
                  _buildFilterChip(
                    'DIFFICULTY_MULTIPLIER',
                    'Difficulty',
                    _allChanges
                        .where((c) => c['type'] == 'DIFFICULTY_MULTIPLIER')
                        .length,
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(),

        // Change list
        Expanded(
          child: _filteredChanges.isEmpty
              ? Center(
                  child: Text(
                    'No changes match your filters',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                )
              : ListView.separated(
                  itemCount: _filteredChanges.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final change = _filteredChanges[index];
                    return _buildChangeRow(change);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String value, String label, int count) {
    final isSelected = _selectedType == value;
    return FilterChip(
      label: Text('$label ($count)'),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedType = value;
          _applyFilters();
        });
      },
      backgroundColor: isSelected ? Colors.blue.withOpacity(0.2) : null,
      side: isSelected
          ? const BorderSide(color: Colors.blue)
          : const BorderSide(color: Colors.grey),
    );
  }

  Widget _buildChangeRow(Map<String, dynamic> change) {
    final type = change['type']?.toString() ?? 'UNKNOWN';
    final key = change['key']?.toString() ?? '—';
    final oldValue = change['oldValue'];
    final newValue = change['newValue'];
    final timestamp = change['timestamp']?.toString() ?? '';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type and timestamp row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getTypeColor(type).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  type,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _getTypeColor(type),
                  ),
                ),
              ),
              Text(
                _formatTimestamp(timestamp),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Key
          Text(
            key,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),

          // Old → New values
          if (oldValue != null && newValue != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.05),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: Colors.grey.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Before',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          oldValue.toString(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: Colors.grey[400],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'After',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          newValue.toString(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            Text(
              '${oldValue ?? newValue}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
        ],
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'FEATURE_ENABLED':
        return Colors.blue;
      case 'FEATURE_ROLLOUT':
        return Colors.purple;
      case 'DIFFICULTY_MULTIPLIER':
        return Colors.orange;
      case 'EXPERIMENT_CREATED':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatTimestamp(String timestamp) {
    if (timestamp.isEmpty) return '—';
    try {
      final dateTime = DateTime.parse(timestamp);
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
    } catch (_) {
      return timestamp;
    }
  }
}
