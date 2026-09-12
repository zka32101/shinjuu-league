import 'package:shinjuu_league/data/models/achievement.dart';
import 'package:shinjuu_league/services/achievement_service.dart';
import 'package:shinjuu_league/services/analytics_service.dart';

/// Integration layer for Achievement + Analytics
/// Emits analytics events when achievements are unlocked or progressed
class AchievementAnalyticsIntegration {
  final AchievementService _achievementService;
  final AnalyticsService _analyticsService;

  AchievementAnalyticsIntegration({
    required AchievementService achievementService,
    required AnalyticsService analyticsService,
  })  : _achievementService = achievementService,
        _analyticsService = analyticsService;

  /// Track achievement unlock and emit analytics event
  Future<void> trackAchievementUnlock(
    String userId,
    Achievement achievement,
    PlayerAchievement playerAchievement,
  ) async {
    try {
      // Determine rarity based on reward tier
      final rarity = _getRarityFromTier(achievement.rewardTier);

      // Log achievement unlock
      await _analyticsService.logAchievementUnlocked(
        userId,
        achievement.achievementId,
        rarity,
      );

      // If reward is claimed immediately (instant unlock), also log reward claim
      if (!achievement.isProgressBased) {
        await _analyticsService.logAchievementRewardClaimed(
          userId,
          achievement.achievementId,
          achievement.rewardTier.toString().split('.').last,
          achievement.getRewardCurrency(),
          achievement.getRewardBadges(),
        );
      }
    } catch (e) {
      // Log analytics errors silently
      _analyticsService.recordError(
        e,
        StackTrace.current,
        reason: 'Failed to track achievement unlock analytics',
        information: [userId, achievement.achievementId],
      );
    }
  }

  /// Track achievement progress and emit analytics event
  Future<void> trackAchievementProgress(
    String userId,
    Achievement achievement,
    PlayerAchievement? playerAchievement,
  ) async {
    if (!achievement.isProgressBased || playerAchievement?.progress == null) {
      return;
    }

    try {
      final progress = playerAchievement!.progress!;
      await _analyticsService.logAchievementProgress(
        userId,
        achievement.achievementId,
        progress.current,
        progress.target,
      );
    } catch (e) {
      _analyticsService.recordError(
        e,
        StackTrace.current,
        reason: 'Failed to track achievement progress analytics',
        information: [userId, achievement.achievementId],
      );
    }
  }

  /// Track overall achievement completion and emit analytics event
  Future<void> trackCompletionStats(String userId) async {
    try {
      final completion = await _achievementService.getCompletionPercentage(userId);
      final unlockCount = await _achievementService.getUnlockCount(userId);

      await _analyticsService.logAchievementCompletion(
        userId,
        completion,
        unlockCount,
      );
    } catch (e) {
      _analyticsService.recordError(
        e,
        StackTrace.current,
        reason: 'Failed to track achievement completion analytics',
        information: [userId],
      );
    }
  }

  /// Track category-specific achievement progress
  Future<void> trackCategoryProgress(
    String userId,
    AchievementCategory category,
  ) async {
    try {
      final achievements = await _achievementService.getAchievementsByCategory(
        userId,
        category,
      );

      if (achievements.isEmpty) return;

      final unlockedCount = achievements.where((a) => a.isUnlocked).length;

      await _analyticsService.logAchievementCategoryProgress(
        userId,
        category.toString().split('.').last,
        unlockedCount,
        achievements.length,
      );
    } catch (e) {
      _analyticsService.recordError(
        e,
        StackTrace.current,
        reason: 'Failed to track category progress analytics',
        information: [userId, category.toString()],
      );
    }
  }

  /// Track all categories' progress (for comprehensive snapshot)
  Future<void> trackAllCategoriesProgress(String userId) async {
    try {
      for (final category in AchievementCategory.values) {
        await trackCategoryProgress(userId, category);
      }
    } catch (e) {
      _analyticsService.recordError(
        e,
        StackTrace.current,
        reason: 'Failed to track all categories progress analytics',
        information: [userId],
      );
    }
  }

  /// Track reward claim event
  Future<void> trackRewardClaim(
    String userId,
    Achievement achievement,
  ) async {
    try {
      await _analyticsService.logAchievementRewardClaimed(
        userId,
        achievement.achievementId,
        achievement.rewardTier.toString().split('.').last,
        achievement.getRewardCurrency(),
        achievement.getRewardBadges(),
      );
    } catch (e) {
      _analyticsService.recordError(
        e,
        StackTrace.current,
        reason: 'Failed to track reward claim analytics',
        information: [userId, achievement.achievementId],
      );
    }
  }

  /// Map reward tier to rarity for analytics
  String _getRarityFromTier(AchievementRewardTier tier) {
    switch (tier) {
      case AchievementRewardTier.bronze:
        return 'common';
      case AchievementRewardTier.silver:
        return 'uncommon';
      case AchievementRewardTier.gold:
        return 'rare';
      case AchievementRewardTier.platinum:
        return 'legendary';
    }
  }
}
