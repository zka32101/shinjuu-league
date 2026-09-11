import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shinjuu_league/services/web_admin_dashboard_service.dart';
import 'package:shinjuu_league/ui/widgets/custom_button.dart';

/// Admin Difficulty Tuning Screen (Phase 32 Part 3).
///
/// Allows real-time adjustment of difficulty multipliers with:
/// - Individual sliders for each multiplier
/// - Preset buttons (Easy/Normal/Hard)
/// - Live preview of resulting values
/// - Current vs preset comparison
/// - Reset to original capability
class AdminDifficultyTuningScreen extends ConsumerStatefulWidget {
  final WebAdminDashboardService dashboardService;

  const AdminDifficultyTuningScreen({
    Key? key,
    required this.dashboardService,
  }) : super(key: key);

  @override
  ConsumerState<AdminDifficultyTuningScreen> createState() =>
      _AdminDifficultyTuningScreenState();
}

class _AdminDifficultyTuningScreenState
    extends ConsumerState<AdminDifficultyTuningScreen> {
  late Map<String, dynamic> _currentSettings;
  late Map<String, double> _sliderValues;
  bool _isLoading = true;
  String? _error;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final settings = widget.dashboardService.getDifficultySettings();
      setState(() {
        _currentSettings = settings;
        _sliderValues = {
          'level': (settings['levelMultiplier'] as num?)?.toDouble() ?? 1.0,
          'cooldown':
              (settings['cooldownMultiplier'] as num?)?.toDouble() ?? 1.0,
          'damage': (settings['damageMultiplier'] as num?)?.toDouble() ?? 1.0,
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load difficulty settings: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _applyPreset(String preset) async {
    try {
      final presets =
          (_currentSettings['presets'] as Map<String, dynamic>?)?[preset]
              as Map<String, dynamic>?;
      if (presets == null) return;

      // Update sliders to match preset
      setState(() {
        _sliderValues = {
          'level': (presets['level'] as num?)?.toDouble() ?? 1.0,
          'cooldown': (presets['cooldown'] as num?)?.toDouble() ?? 1.0,
          'damage': (presets['damage'] as num?)?.toDouble() ?? 1.0,
        };
      });

      // Apply to backend
      await widget.dashboardService.applyDifficultyPreset(preset);

      if (mounted) {
        setState(() {
          _successMessage = 'Applied $preset preset';
        });
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() => _successMessage = null);
          }
        });
      }
    } catch (e) {
      setState(() => _error = 'Failed to apply preset: $e');
    }
  }

  Future<void> _applyMultiplier(String type, double value) async {
    try {
      final result =
          await widget.dashboardService.setDifficultyMultiplier(type, value);
      if (result && mounted) {
        setState(() {
          _successMessage = 'Updated $type multiplier';
        });
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() => _successMessage = null);
          }
        });
      }
    } catch (e) {
      setState(() => _error = 'Failed to update multiplier: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Difficulty Tuning'),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : _buildContent(),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadSettings,
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
            onPressed: _loadSettings,
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
          const SizedBox(height: 16),

          // Current values card
          _buildCurrentValuesCard(),
          const SizedBox(height: 24),

          // Sliders section
          _buildSlidersSection(),
          const SizedBox(height: 24),

          // Presets section
          _buildPresetsSection(),
          const SizedBox(height: 24),

          // Preset values reference
          _buildPresetValuesReference(),
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

  Widget _buildCurrentValuesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Current Multipliers',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildValueRow(
              'Level Difficulty',
              _sliderValues['level'] ?? 1.0,
              Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildValueRow(
              'Skill Cooldown',
              _sliderValues['cooldown'] ?? 1.0,
              Colors.orange,
            ),
            const SizedBox(height: 12),
            _buildValueRow(
              'Skill Damage',
              _sliderValues['damage'] ?? 1.0,
              Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValueRow(String label, double value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            value.toStringAsFixed(2),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSlidersSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Manual Adjustment',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildSlider(
              'Level Difficulty',
              'level',
              _sliderValues['level'] ?? 1.0,
              Colors.blue,
              'Affects base level requirements',
            ),
            const SizedBox(height: 24),
            _buildSlider(
              'Skill Cooldown',
              'cooldown',
              _sliderValues['cooldown'] ?? 1.0,
              Colors.orange,
              'Affects time between skill uses',
            ),
            const SizedBox(height: 24),
            _buildSlider(
              'Skill Damage',
              'damage',
              _sliderValues['damage'] ?? 1.0,
              Colors.red,
              'Affects skill damage output',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider(
    String label,
    String key,
    double value,
    Color color,
    String description,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            Text(
              value.toStringAsFixed(2),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: color,
            thumbColor: color,
          ),
          child: Slider(
            value: value,
            min: 0.1,
            max: 3.0,
            divisions: 29,
            onChanged: (newValue) {
              setState(() {
                _sliderValues[key] = newValue;
              });
            },
            onChangeEnd: (newValue) async {
              await _applyMultiplier(key, newValue);
            },
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildPresetsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Presets',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildPresetButton('Easy', 'easy', Colors.green),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPresetButton('Normal', 'normal', Colors.blue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPresetButton('Hard', 'hard', Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetButton(String label, String preset, Color color) {
    return ElevatedButton(
      onPressed: () => _applyPreset(preset),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        side: BorderSide(color: color),
      ),
      child: Text(label),
    );
  }

  Widget _buildPresetValuesReference() {
    final presets =
        (_currentSettings['presets'] as Map<String, dynamic>?) ?? {};

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Preset Values',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...(presets.entries.map((entry) {
              final presetName = entry.key as String;
              final values = entry.value as Map<String, dynamic>;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      presetName.toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildPresetRow(
                      'Level',
                      values['level']?.toString() ?? '—',
                    ),
                    const SizedBox(height: 4),
                    _buildPresetRow(
                      'Cooldown',
                      values['cooldown']?.toString() ?? '—',
                    ),
                    const SizedBox(height: 4),
                    _buildPresetRow(
                      'Damage',
                      values['damage']?.toString() ?? '—',
                    ),
                  ],
                ),
              );
            }).toList()),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
