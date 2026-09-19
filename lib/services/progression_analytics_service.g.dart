// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'progression_analytics_service.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SeasonComparisonImpl _$$SeasonComparisonImplFromJson(
  Map<String, dynamic> json,
) => _$SeasonComparisonImpl(
  season1: SeasonStats.fromJson(json['season1'] as Map<String, dynamic>),
  season2: SeasonStats.fromJson(json['season2'] as Map<String, dynamic>),
  tierChange: json['tierChange'] as String,
  pointsChangePerTree: Map<String, int>.from(
    json['pointsChangePerTree'] as Map,
  ),
);

Map<String, dynamic> _$$SeasonComparisonImplToJson(
  _$SeasonComparisonImpl instance,
) => <String, dynamic>{
  'season1': instance.season1,
  'season2': instance.season2,
  'tierChange': instance.tierChange,
  'pointsChangePerTree': instance.pointsChangePerTree,
};

_$TierPredictionImpl _$$TierPredictionImplFromJson(Map<String, dynamic> json) =>
    _$TierPredictionImpl(
      currentTier: json['currentTier'] as String,
      predictedTier: json['predictedTier'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      daysToReach: (json['daysToReach'] as num).toInt(),
    );

Map<String, dynamic> _$$TierPredictionImplToJson(
  _$TierPredictionImpl instance,
) => <String, dynamic>{
  'currentTier': instance.currentTier,
  'predictedTier': instance.predictedTier,
  'confidence': instance.confidence,
  'daysToReach': instance.daysToReach,
};
