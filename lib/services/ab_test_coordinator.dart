import 'package:shinjuu_league/services/analytics_service.dart';
import 'package:shinjuu_league/services/feature_flags_service.dart';
import 'package:shinjuu_league/services/skill_progression_analytics_service.dart';

/// Coordinates A/B testing: assigns cohorts, tracks variants, and logs events.
///
/// Bridges feature flags with analytics to measure experiment outcomes.
/// Ensures consistent variant assignment across sessions.
class ABTestCoordinator {
  final FeatureFlagsService _featureFlags;
  final SkillProgressionAnalyticsService _analytics;

  // Track user-experiment assignments: (userId, experimentId) -> variantName
  final Map<String, String> _userExperimentVariants = {};

  // Track active experiments
  final Map<String, ABTestExperimentConfig> _experiments = {};

  ABTestCoordinator({
    required FeatureFlagsService featureFlags,
    required SkillProgressionAnalyticsService analytics,
  })  : _featureFlags = featureFlags,
        _analytics = analytics;

  /// Register an A/B test experiment.
  void registerExperiment(ABTestExperimentConfig config) {
    _experiments[config.experimentId] = config;
  }

  /// Get variant for user in an experiment.
  ///
  /// If user not yet assigned, assigns based on rollout percentage.
  String getExperimentVariant(String userId, String experimentId) {
    final cacheKey = '$userId:$experimentId';

    // Check cache
    if (_userExperimentVariants.containsKey(cacheKey)) {
      return _userExperimentVariants[cacheKey]!;
    }

    final experiment = _experiments[experimentId];
    if (experiment == null) {
      return 'control';
    }

    // Check if experiment is active
    final now = DateTime.now();
    if (now.isBefore(experiment.startDate)) {
      return experiment.controlVariant;
    }
    if (experiment.endDate != null && now.isAfter(experiment.endDate!)) {
      return experiment.controlVariant;
    }

    // Check rollout percentage
    final rolloutHash = _hashForRollout(userId, experimentId);
    if (rolloutHash >= experiment.rolloutPercentage) {
      return experiment.controlVariant;
    }

    // Assign variant based on distribution
    final variantHash = _hashUserToVariant(userId, experimentId);
    final variant =
        _selectVariantByDistribution(variantHash, experiment.variantDistribution);

    _userExperimentVariants[cacheKey] = variant;

    // Log variant assignment
    _analytics.logABTestVariantAssignment(
      userId: userId,
      experimentId: experimentId,
      variantName: variant,
      isControl: variant == experiment.controlVariant,
    );

    return variant;
  }

  /// Log an event with experiment context.
  ///
  /// Automatically includes experiment variant and cohort information.
  void logEventWithExperiment(
    String userId,
    String eventName,
    Map<String, dynamic> parameters,
    String experimentId,
  ) {
    final variant = getExperimentVariant(userId, experimentId);
    final cohort = _featureFlags.getDifficultyCohort(userId);

    final enrichedParams = {
      ...parameters,
      'experiment_id': experimentId,
      'variant': variant,
      'cohort': cohort,
    };

    _analytics.logCustomEvent(userId, eventName, enrichedParams);
  }

  /// Log event with feature flag context.
  void logEventWithFeatureFlag(
    String userId,
    String eventName,
    Map<String, dynamic> parameters,
    String featureName,
  ) {
    final enabled = _featureFlags.isFeatureEnabled(userId, featureName);
    final variant = _featureFlags.getVariant(userId, featureName);

    final enrichedParams = {
      ...parameters,
      'feature_name': featureName,
      'feature_enabled': enabled,
      'feature_variant': variant,
    };

    _analytics.logCustomEvent(userId, eventName, enrichedParams);
  }

  /// Get all active experiments for a user.
  List<ABTestExperimentConfig> getActiveExperiments(String userId) {
    final now = DateTime.now();
    final active = <ABTestExperimentConfig>[];

    for (final exp in _experiments.values) {
      if (now.isBefore(exp.startDate)) continue;
      if (exp.endDate != null && now.isAfter(exp.endDate!)) continue;

      active.add(exp);
    }

    return active;
  }

  /// Get current variant assignments for a user across all experiments.
  Map<String, String> getUserVariants(String userId) {
    final variants = <String, String>{};

    for (final exp in _experiments.values) {
      variants[exp.experimentId] = getExperimentVariant(userId, exp.experimentId);
    }

    return variants;
  }

  /// Check if user is in treatment group for experiment.
  bool isInTreatmentGroup(String userId, String experimentId) {
    final variant = getExperimentVariant(userId, experimentId);
    final experiment = _experiments[experimentId];
    return experiment != null && variant != experiment.controlVariant;
  }

  /// Clear caches (for testing).
  void clearCache() {
    _userExperimentVariants.clear();
  }

  /// Simple hash function for rollout (returns 0-99).
  int _hashForRollout(String userId, String experimentId) {
    final combined = '$userId:$experimentId:rollout';
    return combined.hashCode.abs() % 100;
  }

  /// Hash function for variant selection.
  int _hashUserToVariant(String userId, String experimentId) {
    final combined = '$userId:$experimentId:variant';
    return combined.hashCode.abs();
  }

  /// Select variant based on distribution percentages.
  String _selectVariantByDistribution(
    int hash,
    Map<String, int> distribution,
  ) {
    int accumulated = 0;
    final normalized = hash % 100;

    for (final entry in distribution.entries) {
      accumulated += entry.value;
      if (normalized < accumulated) {
        return entry.key;
      }
    }

    // Fallback to first variant
    return distribution.keys.first;
  }

  /// Debug: dump experiment status for user.
  String debugDumpExperiments(String userId) {
    final buf = StringBuffer();
    buf.writeln('=== A/B Test Coordinator Debug Dump (userId: $userId) ===');
    buf.writeln('Active Experiments: ${getActiveExperiments(userId).length}');
    buf.writeln('');

    for (final exp in getActiveExperiments(userId)) {
      final variant = getExperimentVariant(userId, exp.experimentId);
      final isControl = variant == exp.controlVariant;
      buf.writeln('${exp.experimentId}:');
      buf.writeln('  Name: ${exp.name}');
      buf.writeln('  Variant: $variant${isControl ? ' (CONTROL)' : ' (TREATMENT)'}');
      buf.writeln('  Period: ${exp.startDate} to ${exp.endDate ?? "ongoing"}');
      buf.writeln('  Rollout: ${exp.rolloutPercentage}%');
    }

    return buf.toString();
  }
}

/// Configuration for an A/B test experiment.
class ABTestExperimentConfig {
  final String experimentId;
  final String name;
  final String description;
  final DateTime startDate;
  final DateTime? endDate;
  final String controlVariant;
  final int rolloutPercentage; // 0-100: % of users to include
  final Map<String, int> variantDistribution; // variantName -> percentage

  ABTestExperimentConfig({
    required this.experimentId,
    required this.name,
    required this.description,
    required this.startDate,
    this.endDate,
    required this.controlVariant,
    required this.rolloutPercentage,
    required this.variantDistribution,
  });

  @override
  String toString() => 'ABTestExperimentConfig($experimentId, $name)';
}
