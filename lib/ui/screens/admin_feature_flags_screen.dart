import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shinjuu_league/services/web_admin_dashboard_service.dart';
import 'package:shinjuu_league/ui/widgets/custom_button.dart';

/// Admin Feature Flags Screen (Phase 32 Part 3).
///
/// Comprehensive feature management UI:
/// - Toggle enable/disable per feature
/// - Adjust rollout percentage (canary → beta → GA)
/// - View variant distribution
/// - Kill switch status
/// - Real-time changes with success feedback
class AdminFeatureFlagsScreen extends ConsumerStatefulWidget {
  final WebAdminDashboardService dashboardService;

  const AdminFeatureFlagsScreen({
    Key? key,
    required this.dashboardService,
  }) : super(key: key);

  @override
  ConsumerState<AdminFeatureFlagsScreen> createState() =>
      _AdminFeatureFlagsScreenState();
}

class _AdminFeatureFlagsScreenState
    extends ConsumerState<AdminFeatureFlagsScreen> {
  List<FeatureOverview> _features = [];
  bool _isLoading = true;
  String? _error;
  Map<String, int> _pendingRollouts = {}; // Track pending rollout changes
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _loadFeatures();
  }

  Future<void> _loadFeatures() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final features = widget.dashboardService.getFeatures();
      setState(() {
        _features = features;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load features: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleFeature(String featureName, bool newValue) async {
    try {
      final result = await widget.dashboardService
          .setFeatureEnabled(featureName, newValue);
      if (result && mounted) {
        setState(() {
          _successMessage =
              'Feature ${newValue ? 'enabled' : 'disabled'}: $featureName';
        });
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() => _successMessage = null);
          }
        });
        _loadFeatures();
      }
    } catch (e) {
      setState(() => _error = 'Failed to toggle feature: $e');
    }
  }

  Future<void> _setRollout(String featureName, int percentage) async {
    try {
      final result = await widget.dashboardService
          .setFeatureRollout(featureName, percentage);
      if (result && mounted) {
        setState(() {
          _successMessage = 'Rollout set to $percentage% for $featureName';
          _pendingRollouts.remove(featureName);
        });
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() => _successMessage = null);
          }
        });
        _loadFeatures();
      }
    } catch (e) {
      setState(() => _error = 'Failed to set rollout: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feature Flags'),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : _buildContent(),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadFeatures,
        tooltip: 'Refresh',
        child: const Icon(Icons.refresh),
      ),
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
            onPressed: _loadFeatures,
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_features.isEmpty) {
      return const Center(
        child: Text(
          'No features found',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Success message
          if (_successMessage != null) _buildSuccessMessage(),
          if (_successMessage != null) const SizedBox(height: 16),

          // Feature list
          ..._features.map((feature) => Column(
                children: [
                  _buildFeatureCard(feature),
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

  Widget _buildFeatureCard(FeatureOverview feature) {
    final isEnabled = feature.enabled && !feature.killSwitch;
    final rollout = feature.rolloutPercentage;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with name and status
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        feature.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (feature.description.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            feature.description,
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
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isEnabled
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isEnabled ? 'ENABLED' : 'DISABLED',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isEnabled ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                    if (feature.killSwitch)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: const Text(
                            'KILL SWITCH',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Toggle button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _toggleFeature(feature.name, !isEnabled),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isEnabled
                      ? Colors.red.withOpacity(0.1)
                      : Colors.green.withOpacity(0.1),
                  foregroundColor: isEnabled ? Colors.red : Colors.green,
                  side: BorderSide(
                    color: isEnabled ? Colors.red : Colors.green,
                  ),
                ),
                child: Text(isEnabled ? 'Disable Feature' : 'Enable Feature'),
              ),
            ),
            const SizedBox(height: 16),

            // Rollout percentage section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                    setState(() {
                      _pendingRollouts[feature.name] = newValue.toInt();
                    });
                  },
                  onChangeEnd: (newValue) {
                    _setRollout(feature.name, newValue.toInt());
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildRolloutPresetButton(feature.name, 10, 'Canary'),
                    _buildRolloutPresetButton(feature.name, 25, 'Beta'),
                    _buildRolloutPresetButton(feature.name, 50, 'Mid'),
                    _buildRolloutPresetButton(feature.name, 100, 'GA'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Variants section
            if (feature.variants.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'A/B Test Variants',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: feature.variants
                        .map((variant) => Chip(
                              label: Text(variant),
                              visualDensity: VisualDensity.compact,
                            ))
                        .toList(),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRolloutPresetButton(
    String featureName,
    int percentage,
    String label,
  ) {
    return SizedBox(
      width: 70,
      child: OutlinedButton(
        onPressed: () => _setRollout(featureName, percentage),
        child: Text(
          label,
          style: const TextStyle(fontSize: 11),
        ),
      ),
    );
  }
}
