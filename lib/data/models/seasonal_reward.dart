import 'package:freezed_annotation/freezed_annotation.dart';

part 'seasonal_reward.freezed.dart';
part 'seasonal_reward.g.dart';

/// Type of reward that can be distributed
enum RewardType {
  cosmetic_skin,      // Character or mecha skin
  battle_pass_item,   // Battle pass cosmetics/emotes
  currency,           // In-game currency (gems/coins)
}

/// Seasonal reward offered for reaching a specific tier
@freezed
class SeasonalReward with _$SeasonalReward {
  const factory SeasonalReward({
    required String rewardId,
    required String tier,              // Bronze/Silver/Gold/Platinum/Diamond
    required RewardType rewardType,
    required int quantity,             // Amount of currency or count of items
    required String displayName,
    required String iconUrl,
  }) = _SeasonalReward;

  factory SeasonalReward.fromJson(Map<String, dynamic> json) =>
      _$SeasonalRewardFromJson(json);
}

/// Distribution of seasonal rewards to a player
///
/// This class has a nested `List<SeasonalReward>` field. See the note on
/// Quest in quest_model.dart: this relies on build.yaml's project-wide
/// `explicit_to_json: true`, not a per-class `@JsonSerializable(...)`
/// annotation stacked on `@freezed` (which collides with freezed's own
/// generated dispatcher of the same name).
@freezed
class SeasonRewardDistribution with _$SeasonRewardDistribution {
  const SeasonRewardDistribution._();

  const factory SeasonRewardDistribution({
    required String seasonId,
    required String userId,
    required String finalTier,         // Tier achieved by season end
    required List<SeasonalReward> rewards,
    required DateTime distributedAt,
    DateTime? claimedAt,               // When player claimed rewards (null = unclaimed)
    required DateTime expiresAt,       // Claim deadline
  }) = _SeasonRewardDistribution;

  factory SeasonRewardDistribution.fromJson(Map<String, dynamic> json) =>
      _$SeasonRewardDistributionFromJson(json);

  /// Check if rewards have been claimed
  bool get isClaimed => claimedAt != null;

  /// Check if claim window is still open
  bool get isClaimableWindow {
    final now = DateTime.now();
    return now.isBefore(expiresAt) && !isClaimed;
  }

  /// Check if claim window has expired
  bool get isExpired {
    return DateTime.now().isAfter(expiresAt);
  }

  /// Get total value (for currency rewards only)
  int getTotalCurrencyValue() {
    return rewards
        .where((r) => r.rewardType == RewardType.currency)
        .fold(0, (sum, r) => sum + r.quantity);
  }

  /// Filter rewards by type
  List<SeasonalReward> getRewardsByType(RewardType type) {
    return rewards.where((r) => r.rewardType == type).toList();
  }
}
