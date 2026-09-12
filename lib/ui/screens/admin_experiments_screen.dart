import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shinjuu_league/data/models/admin_role.dart';
import 'package:shinjuu_league/data/providers/service_providers.dart';
import 'package:shinjuu_league/services/web_admin_dashboard_service.dart';
import 'package:shinjuu_league/ui/widgets/custom_button.dart';

/// Admin Experiments Screen (Phase 32 Part 3).
///
/// A/B experiment lifecycle management:
/// - View active and past experiments
/// - Create new experiments with variant distribution
/// - Adjust rollout percentages during experiment
/// - View variant performance metrics
/// - End experiments and review results
class AdminExperimentsScreen extends ConsumerStatefulWidget {
  final WebAdminDashboardService dashboardService;

  const AdminExperimentsScreen({
    Key? key,
    required this.dashboardService,
  }) : super(key: key);

  @override
  ConsumerState<AdminExperimentsScreen> createState() =>
      _AdminExperimentsScreenState();
}

class _AdminExperimentsScreenState extends ConsumerState<AdminExperimentsScreen> {
  List<Map<String, dynamic>> _experiments = [];
  bool _isLoading = true;
  String? _error;
  String? _successMessage;
  bool _showCreateForm = false;

  // Form fields for creating new experiment
  late TextEditingController _experimentIdController;
  late TextEditingController _experimentNameController;
  late TextEditingController _descriptionController;
  String _selectedControlVariant = 'control';
  int _rolloutPercentage = 50;

  @override
  void initState() {
    super.initState();
    _experimentIdController = TextEditingController();
    _experimentNameController = TextEditingController();
    _descriptionController = TextEditingController();
    _loadExperiments();
  }

  @override
  void dispose() {
    _experimentIdController.dispose();
    _experimentNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadExperiments() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final snapshot = widget.dashboardService.getDashboardState();
      // Get experiments from dashboard state - empty for now as not yet defined
      setState(() {
        _experiments = [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load experiments: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _createExperiment() async {
    if (_experimentIdController.text.isEmpty ||
        _experimentNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    try {
      final config = {
        'experimentId': _experimentIdController.text,
        'name': _experimentNameController.text,
        'description': _descriptionController.text,
        'startDate': DateTime.now().toIso8601String(),
        'controlVariant': _selectedControlVariant,
        'rolloutPercentage': _rolloutPercentage,
        'variantDistribution': {
          _selectedControlVariant: 50,
          'treatment': 50,
        },
      };

      final result = await widget.dashboardService.createExperiment(config);
      if (result && mounted) {
        setState(() {
          _successMessage =
              'Experiment "${_experimentNameController.text}" created';
          _showCreateForm = false;
        });
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() => _successMessage = null);
          }
        });
        _experimentIdController.clear();
        _experimentNameController.clear();
        _descriptionController.clear();
        _selectedControlVariant = 'control';
        _rolloutPercentage = 50;
        _loadExperiments();
      }
    } catch (e) {
      setState(() => _error = 'Failed to create experiment: $e');
    }
  }

  Future<void> _updateRollout(String experimentId, int percentage) async {
    try {
      final result =
          await widget.dashboardService.updateExperimentRollout(
        experimentId,
        percentage,
      );
      if (result && mounted) {
        setState(() {
          _successMessage = 'Rollout updated to $percentage%';
        });
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() => _successMessage = null);
          }
        });
        _loadExperiments();
      }
    } catch (e) {
      setState(() => _error = 'Failed to update rollout: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final adminAccessState = ref.watch(adminAccessViewModelProvider);

        return Scaffold(
          appBar: AppBar(
            title: const Text('A/B Experiments'),
            centerTitle: true,
            elevation: 0,
          ),
          body: adminAccessState.when(
            data: (state) {
              // Check if user has permission to view experiments
              final canViewExperiments = ref
                  .read(adminAccessViewModelProvider.notifier)
                  .hasPermission(AdminPermission.viewExperiments);

              if (!canViewExperiments) {
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
                        'You do not have permission to view experiments.',
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
            tooltip: 'New Experiment',
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
            onPressed: _loadExperiments,
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

          // Active experiments
          const Text(
            'Active Experiments',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (_experiments.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'No active experiments',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ..._experiments.map((exp) => Column(
                  children: [
                    _buildExperimentCard(exp),
                    const SizedBox(height: 12),
                  ],
                )),
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
              'Create New Experiment',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _experimentIdController,
              decoration: InputDecoration(
                labelText: 'Experiment ID',
                hintText: 'e.g., exp_aha_moment_threshold',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _experimentNameController,
              decoration: InputDecoration(
                labelText: 'Experiment Name',
                hintText: 'e.g., Aha Moment Threshold Test',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                hintText: 'Experiment purpose and expected outcome',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Initial Rollout',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  '$_rolloutPercentage%',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            Slider(
              value: _rolloutPercentage.toDouble(),
              min: 0,
              max: 100,
              divisions: 20,
              onChanged: (newValue) {
                setState(() {
                  _rolloutPercentage = newValue.toInt();
                });
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                label: 'Create Experiment',
                onPressed: _createExperiment,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExperimentCard(Map<String, dynamic> experiment) {
    final experimentId = experiment['experimentId']?.toString() ?? 'Unknown';
    final name = experiment['name']?.toString() ?? 'Unnamed';
    final rollout = experiment['rolloutPercentage'] as int? ?? 0;
    final variants =
        (experiment['variantDistribution'] as Map<String, dynamic>?) ?? {};

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
                      Text(
                        experimentId,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'ACTIVE',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Rollout percentage
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Rollout Percentage',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  '$rollout%',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Slider(
              value: rollout.toDouble(),
              min: 0,
              max: 100,
              divisions: 20,
              onChanged: (newValue) {
                _updateRollout(experimentId, newValue.toInt());
              },
            ),
            const SizedBox(height: 16),

            // Variant distribution
            const Text(
              'Variant Distribution',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: variants.entries.map((entry) {
                return Chip(
                  label: Text('${entry.key}: ${entry.value}%'),
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
