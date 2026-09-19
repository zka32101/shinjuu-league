import 'package:shinjuu_league/config/achievement_feature_flags.dart';
import 'package:shinjuu_league/data/models/achievement.dart';
import 'package:shinjuu_league/services/analytics_service.dart';
import 'package:shinjuu_league/services/push_notification_service.dart';

/// Service to handle push notifications for near-completion achievements
/// Emits notifications when achievement progress reaches configured threshold (default 75%)
class AchievementPushNotificationService {
  final PushNotificationService _pushNotificationService;
  final AnalyticsService _analyticsService;
  final AchievementFeatureFlags _featureFlags;

  // Track sent notifications to prevent duplicates
  final Map<String, Set<String>> _sentNotifications = {}; // userId -> {achievementId}

  AchievementPushNotificationService({
    required PushNotificationService pushNotificationService,
    required AnalyticsService analyticsService,
    required AchievementFeatureFlags featureFlags,
  })  : _pushNotificationService = pushNotificationService,
        _analyticsService = analyticsService,
        _featureFlags = featureFlags;

  /// Check if achievement is near completion and send notification if eligible
  /// Returns true if notification was sent, false otherwise
  Future<bool> checkAndSendNearCompletionNotification(
    String userId,
    Achievement achievement,
    PlayerAchievement? playerAchievement,
  ) async {
    try {
      // Check if push notifications are enabled
      if (!_featureFlags.isPushNotificationEnabled()) {
        return false;
      }

      // Only for progress-based achievements
      if (!achievement.isProgressBased || playerAchievement?.progress == null) {
        return false;
      }

      // Already unlocked
      if (playerAchievement?.isUnlocked ?? false) {
        return false;
      }

      // Calculate progress percentage
      final progress = playerAchievement!.progress!;
      final progressPercentage = (progress.current / progress.target * 100).toInt();

      // Check if we've already sent notification for this achievement
      final userNotifications = _sentNotifications.putIfAbsent(userId, () => {});
      if (userNotifications.contains(achievement.achievementId)) {
        return false;
      }

      // Get the configured threshold (default 75%)
      final threshold = _featureFlags.getPushNotificationThresholdPercent();

      // Send notification if progress >= threshold
      if (progressPercentage >= threshold) {
        await _sendNotification(userId, achievement, progressPercentage);
        userNotifications.add(achievement.achievementId);

        // Track analytics event
        await _analyticsService.logAchievementNotificationSent(
          userId,
          achievement.achievementId,
          progressPercentage,
        );

        return true;
      }

      return false;
    } catch (e) {
      // Log error and continue (non-blocking)
      _analyticsService.recordError(
        e,
        StackTrace.current,
        reason: 'Failed to check/send achievement near-completion notification',
        information: [userId, achievement.achievementId],
      );
      return false;
    }
  }

  /// Send local push notification for near-completion achievement
  Future<void> _sendNotification(
    String userId,
    Achievement achievement,
    int progressPercentage,
  ) async {
    try {
      final title = '${achievement.name}があと少し！';
      final body = '$progressPercentage%達成！残りわずかで報酬をゲット！';

      await _pushNotificationService.showNotification(
        title: title,
        body: body,
        payload: {
          'type': 'achievement_near_completion',
          'achievement_id': achievement.achievementId,
          'progress_percentage': progressPercentage.toString(),
        },
      );
    } catch (e) {
      // Log error (notification failure is non-critical)
      _analyticsService.recordError(
        e,
        StackTrace.current,
        reason: 'Failed to show achievement near-completion notification',
        information: [achievement.achievementId],
      );
    }
  }

  /// Reset notification tracking for a user (called on app restart or season reset)
  void resetNotificationTracking(String userId) {
    _sentNotifications.remove(userId);
  }

  /// Reset all notification tracking
  void resetAllNotificationTracking() {
    _sentNotifications.clear();
  }

  /// Check if notification was already sent for an achievement
  bool wasNotificationSent(String userId, String achievementId) {
    return _sentNotifications[userId]?.contains(achievementId) ?? false;
  }

  /// Debug: get notification stats
  Map<String, dynamic> debugGetNotificationStats() {
    return {
      'total_users': _sentNotifications.length,
      'total_notifications_sent': _sentNotifications.values
          .fold<int>(0, (sum, set) => sum + set.length),
      'notifications_by_user': {
        for (final entry in _sentNotifications.entries)
          entry.key: entry.value.length,
      },
    };
  }
}
