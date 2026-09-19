// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ab_test_variant.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ABTestVariantImpl _$$ABTestVariantImplFromJson(Map<String, dynamic> json) =>
    _$ABTestVariantImpl(
      featureName: json['featureName'] as String,
      variantName: json['variantName'] as String,
      userId: json['userId'] as String,
      assignedAt: DateTime.parse(json['assignedAt'] as String),
      cohortName: json['cohortName'] as String,
      isControl: json['isControl'] as bool? ?? false,
    );

Map<String, dynamic> _$$ABTestVariantImplToJson(_$ABTestVariantImpl instance) =>
    <String, dynamic>{
      'featureName': instance.featureName,
      'variantName': instance.variantName,
      'userId': instance.userId,
      'assignedAt': instance.assignedAt.toIso8601String(),
      'cohortName': instance.cohortName,
      'isControl': instance.isControl,
    };

_$ABTestExperimentImpl _$$ABTestExperimentImplFromJson(
  Map<String, dynamic> json,
) => _$ABTestExperimentImpl(
  experimentId: json['experimentId'] as String,
  name: json['name'] as String,
  description: json['description'] as String,
  startDate: DateTime.parse(json['startDate'] as String),
  endDate: json['endDate'] == null
      ? null
      : DateTime.parse(json['endDate'] as String),
  variants: (json['variants'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  controlVariant: json['controlVariant'] as String,
  rolloutPercentage: (json['rolloutPercentage'] as num).toInt(),
  variantDistribution: Map<String, int>.from(
    json['variantDistribution'] as Map,
  ),
  status:
      $enumDecodeNullable(_$ABTestStatusEnumMap, json['status']) ??
      ABTestStatus.active,
);

Map<String, dynamic> _$$ABTestExperimentImplToJson(
  _$ABTestExperimentImpl instance,
) => <String, dynamic>{
  'experimentId': instance.experimentId,
  'name': instance.name,
  'description': instance.description,
  'startDate': instance.startDate.toIso8601String(),
  'endDate': instance.endDate?.toIso8601String(),
  'variants': instance.variants,
  'controlVariant': instance.controlVariant,
  'rolloutPercentage': instance.rolloutPercentage,
  'variantDistribution': instance.variantDistribution,
  'status': _$ABTestStatusEnumMap[instance.status]!,
};

const _$ABTestStatusEnumMap = {
  ABTestStatus.planning: 'planning',
  ABTestStatus.active: 'active',
  ABTestStatus.paused: 'paused',
  ABTestStatus.completed: 'completed',
  ABTestStatus.archived: 'archived',
};

_$ABTestResultsImpl _$$ABTestResultsImplFromJson(Map<String, dynamic> json) =>
    _$ABTestResultsImpl(
      experimentId: json['experimentId'] as String,
      variantName: json['variantName'] as String,
      sampleSize: (json['sampleSize'] as num).toInt(),
      conversionRate: (json['conversionRate'] as num).toDouble(),
      engagementRate: (json['engagementRate'] as num).toDouble(),
      retentionRate: (json['retentionRate'] as num).toDouble(),
      statisticalSignificance: json['statisticalSignificance'] as String?,
    );

Map<String, dynamic> _$$ABTestResultsImplToJson(_$ABTestResultsImpl instance) =>
    <String, dynamic>{
      'experimentId': instance.experimentId,
      'variantName': instance.variantName,
      'sampleSize': instance.sampleSize,
      'conversionRate': instance.conversionRate,
      'engagementRate': instance.engagementRate,
      'retentionRate': instance.retentionRate,
      'statisticalSignificance': instance.statisticalSignificance,
    };

_$CohortAssignmentImpl _$$CohortAssignmentImplFromJson(
  Map<String, dynamic> json,
) => _$CohortAssignmentImpl(
  userId: json['userId'] as String,
  cohortName: json['cohortName'] as String,
  assignedAt: DateTime.parse(json['assignedAt'] as String),
  experimentVariants: Map<String, String>.from(
    json['experimentVariants'] as Map,
  ),
);

Map<String, dynamic> _$$CohortAssignmentImplToJson(
  _$CohortAssignmentImpl instance,
) => <String, dynamic>{
  'userId': instance.userId,
  'cohortName': instance.cohortName,
  'assignedAt': instance.assignedAt.toIso8601String(),
  'experimentVariants': instance.experimentVariants,
};
