import 'package:shinjuu_league/config/skill_progression_config.dart';
import 'package:shinjuu_league/data/models/ab_test_variant.dart';

/// Cohort-aware feature flags service for A/B testing and gradual rollout.
///
/// Provides:
/// - Feature gate evaluation (is feature enabled for user?)
/// - Cohort-based feature assignment (A/B test variant selection)
/// - Gradual rollout (% of users)
/// - Kill switches (emergency disable)
/// - Feature metadata & variant tracking
class FeatureFlagsService {
  final SkillProgressionConfig _config;

  // Feature gate cache: featureName -> enabled
  final Map<String, bool> _gateCache = {};

  // Cohort cache: (userId, featureName) -> variant
  final Map<String, String> _cohortCache = {};

  // Feature metadata
  final Map<String, FeatureFlagMetadata> _metadata = {
    'skill_cooldown_reduction': FeatureFlagMetadata(
      name: 'skill_cooldown_reduction',
      description: 'Cooldown reduction mechanics',
      enabled: true,
      rolloutPercentage: 100,
      abTestVariants: ['baseline', 'reduced_0.8x', 'reduced_0.6x'],
      defaultVariant: 'baseline',
      killSwitch: false,
    ),
    'damage_multiplier': FeatureFlagMetadata(
      name: 'damage_multiplier',
      description: 'Difficulty-based damage multiplier',
      enabled: true,
      rolloutPercentage: 100,
      abTestVariants: ['baseline', 'increased_1.1x', 'increased_1.3x'],
      defaultVariant: 'baseline',
      killSwitch: false,
    ),
    'evolution_difficulty': FeatureFlagMetadata(
      name: 'evolution_difficulty',
      description: 'Evolution difficulty modifiers',
      enabled: true,
      rolloutPercentage: 100,
      abTestVariants: ['easy', 'normal', 'hard'],
      defaultVariant: 'normal',
      killSwitch: false,
    ),
    'ranked_mode': FeatureFlagMetadata(
      name: 'ranked_mode',
      description: 'Ranked competitive mode',
      enabled: true,
      rolloutPercentage: 95,
      abTestVariants: ['control', 'treatment'],
      defaultVariant: 'control',
      killSwitch: false,
    ),
    'new_ui_layout': FeatureFlagMetadata(
      name: 'new_ui_layout',
      description: 'New dashboard UI layout',
      enabled: true,
      rolloutPercentage: 10,
      abTestVariants: ['old', 'new'],
      defaultVariant: 'old',
      killSwitch: false,
    ),
    'experimental_matchmaking': FeatureFlagMetadata(
      name: 'experimental_matchmaking',
      description: 'Improved matchmaking algorithm',
      enabled: true,
      rolloutPercentage: 25,
      abTestVariants: ['v1', 'v2'],
      defaultVariant: 'v1',
      killSwitch: false,
    ),
  };

  FeatureFlagsService({SkillProgressionConfig? config})
      : _config = config ?? SkillProgressionConfig.instance;

  /// Check if a feature is enabled for a user.
  ///
  /// Evaluation order:
  /// 1. Kill switch: if true, feature is disabled
  /// 2. Rollout percentage: hash(userId) % 100 < rolloutPercentage
  /// 3. Feature enabled flag
  bool isFeatureEnabled(String userId, String featureName) {
    final cacheKey = '$userId:$featureName:enabled';
    if (_gateCache.containsKey(cacheKey)) {
      return _gateCache[cacheKey]!;
    }

    final metadata = _metadata[featureName];
    if (metadata == null) {
      return false;
    }

    // Kill switch check
    if (metadata.killSwitch) {
      _gateCache[cacheKey] = false;
      return false;
    }

    // Feature enabled check
    if (!metadata.enabled) {
      _gateCache[cacheKey] = false;
      return false;
    }

    // Rollout percentage check
    final rolloutHash = _hashForRollout(userId, featureName);
    final enabled = rolloutHash < metadata.rolloutPercentage;

    _gateCache[cacheKey] = enabled;
    return enabled;
  }

  /// Get A/B test variant for a user.
  ///
  /// Uses consistent hashing to ensure same variant across sessions.
  /// Returns defaultVariant if feature not enabled for user.
  String getVariant(String userId, String featureName) {
    final cacheKey = '$userId:$featureName:variant';
    if (_cohortCache.containsKey(cacheKey)) {
      return _cohortCache[cacheKey]!;
    }

    final metadata = _metadata[featureName];
    if (metadata == null || !isFeatureEnabled(userId, featureName)) {
      return 'control';
    }

    // Hash user to one of the variants
    final variantHash = _hashUserToVariant(userId, featureName);
    final variantIndex = variantHash % metadata.abTestVariants.length;
    final variant = metadata.abTestVariants[variantIndex];

    _cohortCache[cacheKey] = variant;
    return variant;
  }

  /// Get difficulty cohort variant for user.
  ///
  /// Maps difficulty preset to A/B test variant name.
  String getDifficultyCohort(String userId) {
    final difficultyModifiers = _config.getDifficultyModifiers();

    // Determine cohort from multiplier values
    if (difficultyModifiers.levelDifficultyMultiplier < 1.0) {
      return 'easy';
    } else if (difficultyModifiers.levelDifficultyMultiplier > 1.0) {
      return 'hard';
    } else {
      return 'normal';
    }
  }

  /// Enable feature for all users (remove kill switch).
  void enableFeature(String featureName) {
    final metadata = _metadata[featureName];
    if (metadata != null) {
      metadata.killSwitch = false;
      _gateCache.clear();
    }
  }

  /// Disable feature for all users (emergency kill switch).
  void disableFeature(String featureName) {
    final metadata = _metadata[featureName];
    if (metadata != null) {
      metadata.killSwitch = true;
      _gateCache.clear();
    }
  }

  /// Set rollout percentage for a feature.
  void setRolloutPercentage(String featureName, int percentage) {
    final metadata = _metadata[featureName];
    if (metadata != null && percentage >= 0 && percentage <= 100) {
      metadata.rolloutPercentage = percentage;
      _gateCache.clear();
    }
  }

  /// Get feature metadata.
  FeatureFlagMetadata? getMetadata(String featureName) {
    return _metadata[featureName];
  }

  /// List all features with their status.
  List<FeatureFlagMetadata> listFeatures() {
    return _metadata.values.toList();
  }

  /// Clear all caches (useful for testing).
  void clearCache() {
    _gateCache.clear();
    _cohortCache.clear();
  }

  /// Simple hash function for rollout (returns 0-99).
  int _hashForRollout(String userId, String featureName) {
    final combined = '$userId:$featureName:rollout';
    return combined.hashCode.abs() % 100;
  }

  /// Hash function for variant selection.
  int _hashUserToVariant(String userId, String featureName) {
    final combined = '$userId:$featureName:variant';
    return combined.hashCode.abs();
  }

  /// Debug: dump all flags and their status for a user.
  String debugDump(String userId) {
    final buf = StringBuffer();
    buf.writeln('=== Feature Flags Debug Dump (userId: $userId) ===');
    buf.writeln('Difficulty Cohort: ${getDifficultyCohort(userId)}');
    buf.writeln('');

    for (final metadata in _metadata.values) {
      final enabled = isFeatureEnabled(userId, metadata.name);
      final variant = getVariant(userId, metadata.name);
      buf.writeln('${metadata.name}:');
      buf.writeln('  Enabled: $enabled (killSwitch=${metadata.killSwitch}, '
          'rollout=${metadata.rolloutPercentage}%)');
      buf.writeln('  Variant: $variant');
      buf.writeln('  Description: ${metadata.description}');
    }

    return buf.toString();
  }
}

/// Metadata for a feature flag.
class FeatureFlagMetadata {
  final String name;
  final String description;
  bool enabled;
  int rolloutPercentage; // 0-100
  final List<String> abTestVariants;
  final String defaultVariant;
  bool killSwitch; // True = force disable

  FeatureFlagMetadata({
    required this.name,
    required this.description,
    required this.enabled,
    required this.rolloutPercentage,
    required this.abTestVariants,
    required this.defaultVariant,
    required this.killSwitch,
  });

  @override
  String toString() => 'FeatureFlagMetadata($name, enabled=$enabled, '
      'rollout=$rolloutPercentage%, variants=${abTestVariants.length})';
}
