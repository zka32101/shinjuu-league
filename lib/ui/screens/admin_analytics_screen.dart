import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shinjuu_league/data/providers/service_providers.dart';
import 'package:shinjuu_league/ui/widgets/custom_button.dart';
import 'package:shinjuu_league/ui/widgets/loading_skeleton.dart';

/// Admin Analytics Dashboard Screen (Phase 36)
///
/// Displays real-time monitoring of admin operations:
/// - Operation metrics (total, by type, by user)
/// - Time-based trends (hourly, daily)
/// - Anomaly detection and risk indicators
/// - Audit trail integrity status
/// - Most active admins and top operations
class AdminAnalyticsScreen extends ConsumerStatefulWidget {
  const AdminAnalyticsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends ConsumerState<AdminAnalyticsScreen> {
  DateTime? _startTime;
  DateTime? _endTime;

  @override
  void initState() {
    super.initState();
    _endTime = DateTime.now();
    _startTime = _endTime!.subtract(const Duration(days: 7));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAnalytics();
    });
  }

  Future<void> _loadAnalytics() async {
    ref
        .read(adminAnalyticsViewModelProvider.notifier)
        .loadAnalytics(startTime: _startTime, endTime: _endTime);
  }

  Future<void> _onDateRangeChanged() async {
    final now = DateTime.now();
    final initialDateRange = DateTimeRange(
      start: _startTime ?? now.subtract(const Duration(days: 7)),
      end: _endTime ?? now,
    );

    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: initialDateRange,
    );

    if (result != null) {
      setState(() {
        _startTime = result.start;
        _endTime = result.end;
      });
      await _loadAnalytics();
    }
  }

  @override
  Widget build(BuildContext context) {
    final analyticsState = ref.watch(adminAnalyticsViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Analytics Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalytics,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date Range Filter
              _buildDateRangeFilter(),
              const SizedBox(height: 24),

              // Error State
              if (analyticsState.error != null) _buildErrorState(),

              // Loading State
              if (analyticsState.isLoading && analyticsState.dashboardSummary.isEmpty)
                _buildLoadingState()
              else if (analyticsState.dashboardSummary.isNotEmpty) ...[
                // Summary Cards
                _buildSummaryCards(analyticsState),
                const SizedBox(height: 24),

                // Most Active Admins
                _buildMostActiveAdmins(analyticsState),
                const SizedBox(height: 24),

                // Operation Breakdown
                _buildOperationBreakdown(analyticsState),
                const SizedBox(height: 24),

                // Resource Breakdown
                _buildResourceBreakdown(analyticsState),
                const SizedBox(height: 24),

                // Audit Trail Integrity
                _buildAuditIntegrity(analyticsState),
                const SizedBox(height: 24),

                // Anomalies Section
                _buildAnomaliesSection(analyticsState),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateRangeFilter() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Date Range',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_startTime?.toString().split(' ')[0]} — ${_endTime?.toString().split(' ')[0]}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            CustomButton(
              label: 'Change Range',
              onPressed: _onDateRangeChanged,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    final analyticsState = ref.watch(adminAnalyticsViewModelProvider);
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Error Loading Analytics',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
            ),
            const SizedBox(height: 8),
            Text(
              analyticsState.error ?? 'Unknown error',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 12),
            CustomButton(
              label: 'Retry',
              onPressed: _loadAnalytics,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      children: [
        LoadingSkeleton(height: 100, borderRadius: 8),
        const SizedBox(height: 16),
        LoadingSkeleton(height: 120, borderRadius: 8),
        const SizedBox(height: 16),
        LoadingSkeleton(height: 150, borderRadius: 8),
      ],
    );
  }

  Widget _buildSummaryCards(analyticsState) {
    final totalOps = analyticsState.getTotalOperationCount();
    final uniqueUsers = analyticsState.getUniqueUserCount();
    final avgOpsPerUser = analyticsState.getAverageOperationsPerUser();
    final operationTypes = analyticsState.getOperationTypeBreakdown().length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Summary Metrics',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.5,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _buildMetricCard('Total Operations', totalOps.toString(), Colors.blue),
            _buildMetricCard('Unique Users', uniqueUsers.toString(), Colors.green),
            _buildMetricCard('Avg Ops/User', avgOpsPerUser.toStringAsFixed(1), Colors.orange),
            _buildMetricCard('Operation Types', operationTypes.toString(), Colors.purple),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(String label, String value, Color color) {
    return Card(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.2), color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMostActiveAdmins(analyticsState) {
    final admins = analyticsState.getMostActiveAdmins();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Most Active Admins',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          child: admins.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No admin activity'),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: admins.length,
                  itemBuilder: (context, index) {
                    final admin = admins[index];
                    final userId = admin['userId'] as String?;
                    final opCount = admin['operationCount'] as int?;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userId ?? 'Unknown',
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              Text(
                                '#${index + 1}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              '$opCount ops',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildOperationBreakdown(analyticsState) {
    final breakdown = analyticsState.getOperationTypeBreakdown();
    final sortedEntries = breakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Operations by Type',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: breakdown.isEmpty
                ? const Text('No operations')
                : Column(
                    children: sortedEntries
                        .map((entry) {
                          final total = sortedEntries.fold<int>(
                              0, (sum, e) => sum + e.value);
                          final percentage = total > 0 ? (entry.value / total * 100) : 0.0;

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      entry.key,
                                      style: const TextStyle(fontWeight: FontWeight.w500),
                                    ),
                                    Text(
                                      '${entry.value} (${percentage.toStringAsFixed(1)}%)',
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: percentage / 100,
                                    minHeight: 6,
                                    backgroundColor: Colors.grey.shade200,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Color.lerp(
                                        Colors.green,
                                        Colors.orange,
                                        (percentage / 100).clamp(0, 1),
                                      )!,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        })
                        .toList()
                        .take(10)
                        .toList(),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildResourceBreakdown(analyticsState) {
    final resources = analyticsState.getTopResources();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Top Resources Modified',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: resources.isEmpty
                ? const Text('No resources modified')
                : Column(
                    children: resources.take(10).map((resource) {
                      final type = resource['resourceType'] as String?;
                      final count = resource['count'] as int?;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                type ?? 'Unknown',
                                style: const TextStyle(fontWeight: FontWeight.w500),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Chip(
                              label: Text('$count'),
                              backgroundColor: Colors.purple.shade100,
                              labelStyle: TextStyle(color: Colors.purple.shade700),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildAuditIntegrity(analyticsState) {
    final integrity = analyticsState.getAuditIntegrity();
    final status = integrity['status'] as String? ?? 'UNKNOWN';
    final percentage = analyticsState.getIntegrityPercentage();
    final isHealthy = analyticsState.isAuditTrailHealthy();

    final statusColor = isHealthy ? Colors.green : Colors.orange;
    final statusBgColor = isHealthy ? Colors.green.shade50 : Colors.orange.shade50;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Audit Trail Integrity',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          color: statusBgColor,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Status',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Chip(
                      label: Text(status),
                      backgroundColor: statusColor,
                      labelStyle: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Integrity Percentage'),
                    Text(
                      '${percentage.toStringAsFixed(2)}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnomaliesSection(analyticsState) {
    final hasAnomalies = analyticsState.hasAnomalies();
    final anomalies = analyticsState.getAnomalies();

    if (!hasAnomalies) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Anomalies',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Card(
            color: Colors.green.shade50,
            child: const Padding(
              padding: EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 12),
                  Text('No anomalies detected'),
                ],
              ),
            ),
          ),
        ],
      );
    }

    final affectedUsers = analyticsState.getAffectedUsers();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Detected Anomalies',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          color: Colors.red.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red.shade700),
                    const SizedBox(width: 12),
                    Text(
                      '${affectedUsers.length} user(s) with high-frequency operations',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (affectedUsers.isNotEmpty)
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: affectedUsers.length,
                    itemBuilder: (context, index) {
                      final user = affectedUsers[index];
                      final userId = user['userId'] as String?;
                      final opCount = user['operationCount'] as int?;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(userId ?? 'Unknown'),
                            Chip(
                              label: Text('$opCount ops'),
                              backgroundColor: Colors.red.shade200,
                              labelStyle: TextStyle(color: Colors.red.shade700),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
