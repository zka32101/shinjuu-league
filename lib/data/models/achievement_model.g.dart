// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'achievement_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Achievement _$AchievementFromJson(Map<String, dynamic> json) => Achievement(
  achievementId: json['achievementId'] as String,
  name: json['name'] as String,
  description: json['description'] as String,
  type: $enumDecode(_$AchievementTypeEnumMap, json['type']),
  difficulty: $enumDecode(_$AchievementDifficultyEnumMap, json['difficulty']),
  targetCount: (json['targetCount'] as num?)?.toInt(),
  rewardPoints: (json['rewardPoints'] as num).toInt(),
  rewardIcon: json['rewardIcon'] as String?,
);

Map<String, dynamic> _$AchievementToJson(Achievement instance) =>
    <String, dynamic>{
      'achievementId': instance.achievementId,
      'name': instance.name,
      'description': instance.description,
      'type': _$AchievementTypeEnumMap[instance.type]!,
      'difficulty': _$AchievementDifficultyEnumMap[instance.difficulty]!,
      'targetCount': instance.targetCount,
      'rewardPoints': instance.rewardPoints,
      'rewardIcon': instance.rewardIcon,
    };

const _$AchievementTypeEnumMap = {
  AchievementType.milestone: 'milestone',
  AchievementType.progress: 'progress',
  AchievementType.challenge: 'challenge',
};

const _$AchievementDifficultyEnumMap = {
  AchievementDifficulty.easy: 'easy',
  AchievementDifficulty.normal: 'normal',
  AchievementDifficulty.hard: 'hard',
  AchievementDifficulty.legendary: 'legendary',
};

AchievementProgress _$AchievementProgressFromJson(Map<String, dynamic> json) =>
    AchievementProgress(
      achievementId: json['achievementId'] as String,
      isUnlocked: json['isUnlocked'] as bool,
      currentProgress: (json['currentProgress'] as num?)?.toInt() ?? 0,
      unlockedAt: json['unlockedAt'] == null
          ? null
          : DateTime.parse(json['unlockedAt'] as String),
      lastUpdatedAt: DateTime.parse(json['lastUpdatedAt'] as String),
    );

Map<String, dynamic> _$AchievementProgressToJson(
  AchievementProgress instance,
) => <String, dynamic>{
  'achievementId': instance.achievementId,
  'isUnlocked': instance.isUnlocked,
  'currentProgress': instance.currentProgress,
  'unlockedAt': instance.unlockedAt?.toIso8601String(),
  'lastUpdatedAt': instance.lastUpdatedAt.toIso8601String(),
};
