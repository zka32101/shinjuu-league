// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'achievement.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AchievementImpl _$$AchievementImplFromJson(Map<String, dynamic> json) =>
    _$AchievementImpl(
      achievementId: json['achievementId'] as String,
      category: $enumDecode(_$AchievementCategoryEnumMap, json['category']),
      name: json['name'] as String,
      description: json['description'] as String,
      iconUrl: json['iconUrl'] as String,
      rewardTier: $enumDecode(
        _$AchievementRewardTierEnumMap,
        json['rewardTier'],
      ),
      maxProgress: (json['maxProgress'] as num).toInt(),
      isProgressBased: json['isProgressBased'] as bool? ?? false,
      isHidden: json['isHidden'] as bool? ?? false,
      unlockedAfter: json['unlockedAfter'] == null
          ? null
          : DateTime.parse(json['unlockedAfter'] as String),
    );

Map<String, dynamic> _$$AchievementImplToJson(_$AchievementImpl instance) =>
    <String, dynamic>{
      'achievementId': instance.achievementId,
      'category': _$AchievementCategoryEnumMap[instance.category]!,
      'name': instance.name,
      'description': instance.description,
      'iconUrl': instance.iconUrl,
      'rewardTier': _$AchievementRewardTierEnumMap[instance.rewardTier]!,
      'maxProgress': instance.maxProgress,
      'isProgressBased': instance.isProgressBased,
      'isHidden': instance.isHidden,
      'unlockedAfter': instance.unlockedAfter?.toIso8601String(),
    };

const _$AchievementCategoryEnumMap = {
  AchievementCategory.progression: 'progression',
  AchievementCategory.milestone: 'milestone',
  AchievementCategory.skill: 'skill',
  AchievementCategory.seasonal: 'seasonal',
  AchievementCategory.special: 'special',
};

const _$AchievementRewardTierEnumMap = {
  AchievementRewardTier.bronze: 'bronze',
  AchievementRewardTier.silver: 'silver',
  AchievementRewardTier.gold: 'gold',
  AchievementRewardTier.platinum: 'platinum',
  AchievementRewardTier.common: 'common',
  AchievementRewardTier.uncommon: 'uncommon',
  AchievementRewardTier.rare: 'rare',
  AchievementRewardTier.epic: 'epic',
  AchievementRewardTier.legendary: 'legendary',
  AchievementRewardTier.mythic: 'mythic',
};

_$PlayerAchievementImpl _$$PlayerAchievementImplFromJson(
  Map<String, dynamic> json,
) => _$PlayerAchievementImpl(
  userId: json['userId'] as String,
  achievementId: json['achievementId'] as String,
  unlockedAt: DateTime.parse(json['unlockedAt'] as String),
  progress: json['progress'] == null
      ? null
      : AchievementProgress.fromJson(json['progress'] as Map<String, dynamic>),
  isHidden: json['isHidden'] as bool? ?? false,
);

Map<String, dynamic> _$$PlayerAchievementImplToJson(
  _$PlayerAchievementImpl instance,
) => <String, dynamic>{
  'userId': instance.userId,
  'achievementId': instance.achievementId,
  'unlockedAt': instance.unlockedAt.toIso8601String(),
  'progress': instance.progress?.toJson(),
  'isHidden': instance.isHidden,
};

_$AchievementProgressImpl _$$AchievementProgressImplFromJson(
  Map<String, dynamic> json,
) => _$AchievementProgressImpl(
  current: (json['current'] as num).toInt(),
  target: (json['target'] as num).toInt(),
);

Map<String, dynamic> _$$AchievementProgressImplToJson(
  _$AchievementProgressImpl instance,
) => <String, dynamic>{'current': instance.current, 'target': instance.target};

_$AchievementUnlockEventImpl _$$AchievementUnlockEventImplFromJson(
  Map<String, dynamic> json,
) => _$AchievementUnlockEventImpl(
  userId: json['userId'] as String,
  achievement: Achievement.fromJson(
    json['achievement'] as Map<String, dynamic>,
  ),
  unlockedAt: DateTime.parse(json['unlockedAt'] as String),
  isNewUnlock: json['isNewUnlock'] as bool? ?? true,
);

Map<String, dynamic> _$$AchievementUnlockEventImplToJson(
  _$AchievementUnlockEventImpl instance,
) => <String, dynamic>{
  'userId': instance.userId,
  'achievement': instance.achievement.toJson(),
  'unlockedAt': instance.unlockedAt.toIso8601String(),
  'isNewUnlock': instance.isNewUnlock,
};
