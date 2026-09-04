import 'package:freezed_annotation/freezed_annotation.dart';

part 'season_model.freezed.dart';
part 'season_model.g.dart';

/// Represents a ranked season
///
/// Seasons are time-bound competitive periods with:
/// - Tier placement snapshots (promotion/demotion)
/// - Seasonal rewards distribution
/// - Leaderboard snapshots for nostalgia
@freezed
class RankedSeason with _$RankedSeason {
  const factory RankedSeason({
    required String seasonId,
    required String name, // e.g., "Season 1", "Summer Championship"
    required DateTime startedAt,
    required DateTime endsAt,
    required bool isActive,

    /// Tier thresholds for this season (can vary by season)
    /// Maps tier name → minimum rating
    required Map<String, int> tierThresholds,

    /// Base seasonal rewards (can be customized per tier)
    /// Maps tier name → list of reward IDs
    required Map<String, List<String>> rewardsByTier,

    /// Season-specific rules/modifiers
    required SeasonRules rules,

    /// Timestamp for server-side verification
    @ServerTimestampConverter() required DateTime createdAt,
    @ServerTimestampConverter() required DateTime updatedAt,
  }) = _RankedSeason;

  factory RankedSeason.fromJson(Map<String, dynamic> json) =>
      _$RankedSeasonFromJson(json);
}

/// Rules/modifiers for a season (difficulty, progression speed, etc.)
@freezed
class SeasonRules with _$SeasonRules {
  const factory SeasonRules({
    /// K-factor multiplier (1.0 = standard, 1.2 = faster progression)
    @Default(1.0) double kFactorMultiplier,

    /// Minimum rating to enter ranked play for this season
    @Default(400) int minEntryRating,

    /// Display seasonal theme/name in UI
    @Default('Standard') String theme,
  }) = _SeasonRules;

  factory SeasonRules.fromJson(Map<String, dynamic> json) =>
      _$SeasonRulesFromJson(json);
}

/// Per-user seasonal data (stored in User document subcollection)
///
/// Path: users/{userId}/season_data/{seasonId}
@freezed
class UserSeasonData with _$UserSeasonData {
  const factory UserSeasonData({
    required String userId,
    required String seasonId,

    /// Rating when season started
    required int startingRating,

    /// Peak rating reached this season
    required int peakRating,

    /// Current rating (same as User.eloRating when active season)
    required int currentRating,

    /// Current tier at this snapshot
    required String currentTier,

    /// Previous tier (for demotion/promotion detection)
    required String previousTier,

    /// Highest tier reached this season
    required String peakTier,

    /// Promotion history (timestamps of tier changes)
    required List<TierTransition> tierTransitions,

    /// Seasonal stats
    required int seasonWins,
    required int seasonLosses,
    required int seasonDraws,

    /// Promotion/demotion count
    required int promotionCount,
    required int demotionCount,

    /// Longest win streak this season
    required int longestWinStreak,

    /// Current win streak (0 if lost recently)
    required int currentWinStreak,

    /// Rewards earned this season (reward IDs)
    required List<String> earnedRewards,

    /// Whether rewards have been claimed
    @Default(false) bool rewardsClaimed,

    /// Timestamp for verification
    @ServerTimestampConverter() required DateTime createdAt,
    @ServerTimestampConverter() required DateTime updatedAt,
  }) = _UserSeasonData;

  factory UserSeasonData.fromJson(Map<String, dynamic> json) =>
      _$UserSeasonDataFromJson(json);
}

/// Represents a tier transition (promotion or demotion)
@freezed
class TierTransition with _$TierTransition {
  const factory TierTransition({
    required DateTime timestamp,
    required String fromTier,
    required String toTier,
    required int ratingAtTransition,
    required String transitionType, // 'promotion' or 'demotion'
  }) = _TierTransition;

  factory TierTransition.fromJson(Map<String, dynamic> json) =>
      _$TierTransitionFromJson(json);
}

/// Seasonal rewards catalog
///
/// Stored in rewards/{rewardId}
@freezed
class SeasonalReward with _$SeasonalReward {
  const factory SeasonalReward({
    required String rewardId,
    required String seasonId,
    required String tier, // 'Bronze', 'Silver', 'Gold', 'Platinum', 'Legend'
    required String type, // 'cosmetic_skin', 'currency', 'badge', 'emote'
    required String displayName,
    required String description,
    required String? iconUrl, // nullable for currency rewards
    required int? currencyAmount, // if type is 'currency'
    required bool isLimited, // limited edition = prestige
    @ServerTimestampConverter() required DateTime createdAt,
  }) = _SeasonalReward;

  factory SeasonalReward.fromJson(Map<String, dynamic> json) =>
      _$SeasonalRewardFromJson(json);
}

/// Firestore converter for ServerTimestamp
class ServerTimestampConverter
    implements JsonConverter<DateTime, dynamic> {
  const ServerTimestampConverter();

  @override
  DateTime fromJson(dynamic json) {
    if (json is String) {
      return DateTime.parse(json);
    }
    if (json is int) {
      return DateTime.fromMillisecondsSinceEpoch(json * 1000);
    }
    // Fallback for Firestore Timestamp objects
    return DateTime.now();
  }

  @override
  dynamic toJson(DateTime object) => object.toIso8601String();
}
