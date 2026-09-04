import 'package:freezed_annotation/freezed_annotation.dart';
import 'season_model.dart';

part 'seasonal_progress.freezed.dart';
part 'seasonal_progress.g.dart';

/// UI model for displaying seasonal progression
///
/// Combines RankedSeason + UserSeasonData for efficient screen rendering
@freezed
class SeasonalProgress with _$SeasonalProgress {
  const factory SeasonalProgress({
    required RankedSeason season,
    required UserSeasonData userData,
    required String nextTierName,
    required int ratingToNextTier,
    required double progressPercentage, // 0.0 to 1.0
    required bool isPromotionReady, // rating >= next tier threshold
    required List<TierRewardPreview> earnedRewardPreviews,
  }) = _SeasonalProgress;

  factory SeasonalProgress.fromJson(Map<String, dynamic> json) =>
      _$SeasonalProgressFromJson(json);
}

/// Preview of earned rewards for display
@freezed
class TierRewardPreview with _$TierRewardPreview {
  const factory TierRewardPreview({
    required String rewardId,
    required String displayName,
    required String type, // 'cosmetic_skin', 'currency', 'badge'
    required String? iconUrl,
    required bool claimed,
  }) = _TierRewardPreview;

  factory TierRewardPreview.fromJson(Map<String, dynamic> json) =>
      _$TierRewardPreviewFromJson(json);
}

/// Tier promotion/demotion event (for animation triggers)
@freezed
class PromotionEvent with _$PromotionEvent {
  const factory PromotionEvent({
    required DateTime timestamp,
    required String fromTier,
    required String toTier,
    required int ratingAchieved,
    required bool isPromotion, // true=promotion, false=demotion
  }) = _PromotionEvent;

  factory PromotionEvent.fromJson(Map<String, dynamic> json) =>
      _$PromotionEventFromJson(json);
}

/// Season end summary (shown after season closes)
@freezed
class SeasonEndSummary with _$SeasonEndSummary {
  const factory SeasonEndSummary({
    required String seasonId,
    required String finalTier,
    required int finalRating,
    required int seasonalWins,
    required int seasonalLosses,
    required double winRate,
    required int promotionCount,
    required int demotionCount,
    required String highestTierReached,
    required int ratingGainedThisSeason,
    required List<String> earnedRewardIds,
    required DateTime seasonEndedAt,
  }) = _SeasonEndSummary;

  factory SeasonEndSummary.fromJson(Map<String, dynamic> json) =>
      _$SeasonEndSummaryFromJson(json);
}

/// Tier metadata (for UI display)
@freezed
class TierInfo with _$TierInfo {
  const factory TierInfo({
    required String name, // 'Bronze', 'Silver', 'Gold', 'Platinum', 'Legend'
    required int minRating,
    required int maxRating,
    required String emoji, // 🥉 🥈 🥇 👑 ⭐
    required int kFactor,
    required List<String> rewardIds, // Seasonal rewards for this tier
  }) = _TierInfo;

  factory TierInfo.fromJson(Map<String, dynamic> json) =>
      _$TierInfoFromJson(json);
}
