// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'skill_tree_reset.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SkillTreeSnapshotImpl _$$SkillTreeSnapshotImplFromJson(
  Map<String, dynamic> json,
) => _$SkillTreeSnapshotImpl(
  seasonId: json['seasonId'] as String,
  snapshotAt: DateTime.parse(json['snapshotAt'] as String),
  treeState: SkillTree.fromJson(json['treeState'] as Map<String, dynamic>),
  finalTier: json['finalTier'] as String,
  totalPointsAllocated: (json['totalPointsAllocated'] as num).toInt(),
  treePointsBreakdown: Map<String, int>.from(
    json['treePointsBreakdown'] as Map,
  ),
);

Map<String, dynamic> _$$SkillTreeSnapshotImplToJson(
  _$SkillTreeSnapshotImpl instance,
) => <String, dynamic>{
  'seasonId': instance.seasonId,
  'snapshotAt': instance.snapshotAt.toIso8601String(),
  'treeState': instance.treeState.toJson(),
  'finalTier': instance.finalTier,
  'totalPointsAllocated': instance.totalPointsAllocated,
  'treePointsBreakdown': instance.treePointsBreakdown,
};

_$SkillTreeResetImpl _$$SkillTreeResetImplFromJson(Map<String, dynamic> json) =>
    _$SkillTreeResetImpl(
      seasonId: json['seasonId'] as String,
      nextSeasonId: json['nextSeasonId'] as String,
      userId: json['userId'] as String,
      previousTree: SkillTree.fromJson(
        json['previousTree'] as Map<String, dynamic>,
      ),
      currentTree: SkillTree.fromJson(
        json['currentTree'] as Map<String, dynamic>,
      ),
      resetAt: DateTime.parse(json['resetAt'] as String),
      carryoverMode: $enumDecode(_$CarryoverModeEnumMap, json['carryoverMode']),
      pointsCarriedOver: (json['pointsCarriedOver'] as num).toInt(),
    );

Map<String, dynamic> _$$SkillTreeResetImplToJson(
  _$SkillTreeResetImpl instance,
) => <String, dynamic>{
  'seasonId': instance.seasonId,
  'nextSeasonId': instance.nextSeasonId,
  'userId': instance.userId,
  'previousTree': instance.previousTree.toJson(),
  'currentTree': instance.currentTree.toJson(),
  'resetAt': instance.resetAt.toIso8601String(),
  'carryoverMode': _$CarryoverModeEnumMap[instance.carryoverMode]!,
  'pointsCarriedOver': instance.pointsCarriedOver,
};

const _$CarryoverModeEnumMap = {
  CarryoverMode.none: 'none',
  CarryoverMode.partial: 'partial',
  CarryoverMode.full: 'full',
};

_$ProgressDeltaImpl _$$ProgressDeltaImplFromJson(Map<String, dynamic> json) =>
    _$ProgressDeltaImpl(
      fromSeasonId: json['fromSeasonId'] as String,
      toSeasonId: json['toSeasonId'] as String,
      pointsGained: (json['pointsGained'] as num).toInt(),
      pointsLost: (json['pointsLost'] as num).toInt(),
      carryoverPercentage: (json['carryoverPercentage'] as num).toDouble(),
      treeDeltas: Map<String, int>.from(json['treeDeltas'] as Map),
      fromTier: json['fromTier'] as String,
      toTier: json['toTier'] as String,
      isPromotion: json['isPromotion'] as bool,
    );

Map<String, dynamic> _$$ProgressDeltaImplToJson(_$ProgressDeltaImpl instance) =>
    <String, dynamic>{
      'fromSeasonId': instance.fromSeasonId,
      'toSeasonId': instance.toSeasonId,
      'pointsGained': instance.pointsGained,
      'pointsLost': instance.pointsLost,
      'carryoverPercentage': instance.carryoverPercentage,
      'treeDeltas': instance.treeDeltas,
      'fromTier': instance.fromTier,
      'toTier': instance.toTier,
      'isPromotion': instance.isPromotion,
    };

_$SeasonResetConfigImpl _$$SeasonResetConfigImplFromJson(
  Map<String, dynamic> json,
) => _$SeasonResetConfigImpl(
  seasonId: json['seasonId'] as String,
  nextSeasonId: json['nextSeasonId'] as String,
  endDate: DateTime.parse(json['endDate'] as String),
  resetDate: DateTime.parse(json['resetDate'] as String),
  defaultCarryoverMode: $enumDecode(
    _$CarryoverModeEnumMap,
    json['defaultCarryoverMode'],
  ),
  allowManualReset: json['allowManualReset'] as bool,
);

Map<String, dynamic> _$$SeasonResetConfigImplToJson(
  _$SeasonResetConfigImpl instance,
) => <String, dynamic>{
  'seasonId': instance.seasonId,
  'nextSeasonId': instance.nextSeasonId,
  'endDate': instance.endDate.toIso8601String(),
  'resetDate': instance.resetDate.toIso8601String(),
  'defaultCarryoverMode':
      _$CarryoverModeEnumMap[instance.defaultCarryoverMode]!,
  'allowManualReset': instance.allowManualReset,
};
