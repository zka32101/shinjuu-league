// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quest_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************



const _$QuestTypeEnumMap = {
  QuestType.combat: 'combat',
  QuestType.achievement: 'achievement',
  QuestType.progression: 'progression',
  QuestType.social: 'social',
  QuestType.daily: 'daily',
};

const _$QuestFrequencyEnumMap = {
  QuestFrequency.daily: 'daily',
  QuestFrequency.weekly: 'weekly',
  QuestFrequency.seasonal: 'seasonal',
  QuestFrequency.oneTime: 'oneTime',
};

const _$QuestDifficultyEnumMap = {
  QuestDifficulty.easy: 'easy',
  QuestDifficulty.normal: 'normal',
  QuestDifficulty.hard: 'hard',
  QuestDifficulty.extreme: 'extreme',
};

_$QuestConditionImpl _$$QuestConditionImplFromJson(Map<String, dynamic> json) =>
    _$QuestConditionImpl(
      type: $enumDecode(_$QuestConditionTypeEnumMap, json['type']),
      target: (json['target'] as num).toInt(),
      current: (json['current'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$QuestConditionImplToJson(
  _$QuestConditionImpl instance,
) => <String, dynamic>{
  'type': _$QuestConditionTypeEnumMap[instance.type]!,
  'target': instance.target,
  'current': instance.current,
};

const _$QuestConditionTypeEnumMap = {
  QuestConditionType.battleCount: 'battleCount',
  QuestConditionType.damageDealt: 'damageDealt',
  QuestConditionType.killCount: 'killCount',
  QuestConditionType.achievementUnlock: 'achievementUnlock',
  QuestConditionType.tierReach: 'tierReach',
  QuestConditionType.playtime: 'playtime',
  QuestConditionType.consecutiveWins: 'consecutiveWins',
  QuestConditionType.levelUp: 'levelUp',
};

_$QuestRewardImpl _$$QuestRewardImplFromJson(Map<String, dynamic> json) =>
    _$QuestRewardImpl(
      currency: (json['currency'] as num).toInt(),
      experiencePoints: (json['experiencePoints'] as num?)?.toInt() ?? 0,
      achievementBadges: (json['achievementBadges'] as num?)?.toInt() ?? 0,
      cosmetics:
          (json['cosmetics'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$QuestRewardImplToJson(_$QuestRewardImpl instance) =>
    <String, dynamic>{
      'currency': instance.currency,
      'experiencePoints': instance.experiencePoints,
      'achievementBadges': instance.achievementBadges,
      'cosmetics': instance.cosmetics,
    };

_$QuestImpl _$$QuestImplFromJson(Map<String, dynamic> json) => _$QuestImpl(
  questId: json['questId'] as String,
  title: json['title'] as String,
  description: json['description'] as String,
  type: $enumDecode(_$QuestTypeEnumMap, json['type']),
  frequency: $enumDecode(_$QuestFrequencyEnumMap, json['frequency']),
  difficulty: $enumDecode(_$QuestDifficultyEnumMap, json['difficulty']),
  conditions: (json['conditions'] as List<dynamic>)
      .map((e) => QuestCondition.fromJson(e as Map<String, dynamic>))
      .toList(),
  reward: QuestReward.fromJson(json['reward'] as Map<String, dynamic>),
  availableFrom: json['availableFrom'] == null
      ? null
      : DateTime.parse(json['availableFrom'] as String),
  availableUntil: json['availableUntil'] == null
      ? null
      : DateTime.parse(json['availableUntil'] as String),
  displayOrder: (json['displayOrder'] as num?)?.toInt(),
);

Map<String, dynamic> _$$QuestImplToJson(_$QuestImpl instance) =>
    <String, dynamic>{
      'questId': instance.questId,
      'title': instance.title,
      'description': instance.description,
      'type': _$QuestTypeEnumMap[instance.type]!,
      'frequency': _$QuestFrequencyEnumMap[instance.frequency]!,
      'difficulty': _$QuestDifficultyEnumMap[instance.difficulty]!,
      'conditions': instance.conditions.map((e) => e.toJson()).toList(),
      'reward': instance.reward.toJson(),
      'availableFrom': instance.availableFrom?.toIso8601String(),
      'availableUntil': instance.availableUntil?.toIso8601String(),
      'displayOrder': instance.displayOrder,
    };

_$PlayerQuestImpl _$$PlayerQuestImplFromJson(Map<String, dynamic> json) =>
    _$PlayerQuestImpl(
      userId: json['userId'] as String,
      questId: json['questId'] as String,
      conditions: (json['conditions'] as List<dynamic>)
          .map((e) => QuestCondition.fromJson(e as Map<String, dynamic>))
          .toList(),
      isCompleted: json['isCompleted'] as bool,
      isRewarded: json['isRewarded'] as bool,
      startedAt: json['startedAt'] == null
          ? null
          : DateTime.parse(json['startedAt'] as String),
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
      claimedRewardAt: json['claimedRewardAt'] == null
          ? null
          : DateTime.parse(json['claimedRewardAt'] as String),
    );

Map<String, dynamic> _$$PlayerQuestImplToJson(_$PlayerQuestImpl instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'questId': instance.questId,
      'conditions': instance.conditions.map((e) => e.toJson()).toList(),
      'isCompleted': instance.isCompleted,
      'isRewarded': instance.isRewarded,
      'startedAt': instance.startedAt?.toIso8601String(),
      'completedAt': instance.completedAt?.toIso8601String(),
      'claimedRewardAt': instance.claimedRewardAt?.toIso8601String(),
    };
