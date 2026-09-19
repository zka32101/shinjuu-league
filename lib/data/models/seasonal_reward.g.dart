// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'seasonal_reward.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SeasonalRewardImpl _$$SeasonalRewardImplFromJson(Map<String, dynamic> json) =>
    _$SeasonalRewardImpl(
      rewardId: json['rewardId'] as String,
      tier: json['tier'] as String,
      rewardType: $enumDecode(_$RewardTypeEnumMap, json['rewardType']),
      quantity: (json['quantity'] as num).toInt(),
      displayName: json['displayName'] as String,
      iconUrl: json['iconUrl'] as String,
    );

Map<String, dynamic> _$$SeasonalRewardImplToJson(
  _$SeasonalRewardImpl instance,
) => <String, dynamic>{
  'rewardId': instance.rewardId,
  'tier': instance.tier,
  'rewardType': _$RewardTypeEnumMap[instance.rewardType]!,
  'quantity': instance.quantity,
  'displayName': instance.displayName,
  'iconUrl': instance.iconUrl,
};

const _$RewardTypeEnumMap = {
  RewardType.cosmetic_skin: 'cosmetic_skin',
  RewardType.battle_pass_item: 'battle_pass_item',
  RewardType.currency: 'currency',
};

_$SeasonRewardDistributionImpl _$$SeasonRewardDistributionImplFromJson(
  Map<String, dynamic> json,
) => _$SeasonRewardDistributionImpl(
  seasonId: json['seasonId'] as String,
  userId: json['userId'] as String,
  finalTier: json['finalTier'] as String,
  rewards: (json['rewards'] as List<dynamic>)
      .map((e) => SeasonalReward.fromJson(e as Map<String, dynamic>))
      .toList(),
  distributedAt: DateTime.parse(json['distributedAt'] as String),
  claimedAt: json['claimedAt'] == null
      ? null
      : DateTime.parse(json['claimedAt'] as String),
  expiresAt: DateTime.parse(json['expiresAt'] as String),
);

Map<String, dynamic> _$$SeasonRewardDistributionImplToJson(
  _$SeasonRewardDistributionImpl instance,
) => <String, dynamic>{
  'seasonId': instance.seasonId,
  'userId': instance.userId,
  'finalTier': instance.finalTier,
  'rewards': instance.rewards,
  'distributedAt': instance.distributedAt.toIso8601String(),
  'claimedAt': instance.claimedAt?.toIso8601String(),
  'expiresAt': instance.expiresAt.toIso8601String(),
};
