import 'package:freezed_annotation/freezed_annotation.dart';

part 'ab_test_variant.freezed.dart';
part 'ab_test_variant.g.dart';

/// A/B test variant assignment for a user.
@freezed
class ABTestVariant with _$ABTestVariant {
  const factory ABTestVariant({
    required String featureName,
    required String variantName,
    required String userId,
    required DateTime assignedAt,
    required String cohortName,
    @Default(false) bool isControl,
  }) = _ABTestVariant;

  factory ABTestVariant.fromJson(Map<String, dynamic> json) =>
      _$ABTestVariantFromJson(json);
}

/// A/B test experiment configuration.
@freezed
class ABTestExperiment with _$ABTestExperiment {
  const factory ABTestExperiment({
    required String experimentId,
    required String name,
    required String description,
    required DateTime startDate,
    required DateTime? endDate,
    required List<String> variants,
    required String controlVariant,
    required int rolloutPercentage,
    required Map<String, int> variantDistribution, // variantName -> percentage
    @Default(ABTestStatus.active) ABTestStatus status,
  }) = _ABTestExperiment;

  factory ABTestExperiment.fromJson(Map<String, dynamic> json) =>
      _$ABTestExperimentFromJson(json);
}

/// Status of an A/B test experiment.
enum ABTestStatus {
  planning,
  active,
  paused,
  completed,
  archived,
}

/// A/B test results and metrics.
@freezed
class ABTestResults with _$ABTestResults {
  const factory ABTestResults({
    required String experimentId,
    required String variantName,
    required int sampleSize,
    required double conversionRate,
    required double engagementRate,
    required double retentionRate,
    required String? statisticalSignificance,
  }) = _ABTestResults;

  factory ABTestResults.fromJson(Map<String, dynamic> json) =>
      _$ABTestResultsFromJson(json);
}

/// Cohort assignment for analytics and testing.
@freezed
class CohortAssignment with _$CohortAssignment {
  const factory CohortAssignment({
    required String userId,
    required String cohortName,
    required DateTime assignedAt,
    required Map<String, String> experimentVariants, // experimentId -> variantName
  }) = _CohortAssignment;

  factory CohortAssignment.fromJson(Map<String, dynamic> json) =>
      _$CohortAssignmentFromJson(json);
}
