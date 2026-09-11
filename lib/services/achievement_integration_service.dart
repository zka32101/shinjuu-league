import 'dart:async';
import 'package:shinjuu_league/data/models/achievement.dart';
import 'package:shinjuu_league/services/achievement_detector_service.dart';
import 'package:shinjuu_league/services/achievement_reward_service.dart';
import 'package:shinjuu_league/services/achievement_toast_notification_service.dart';
import 'package:shinjuu_league/services/analytics_service.dart';

/// Coordinates achievement detection, notification, and reward distribution
/// Provides a unified interface for the full achievement lifecycle
class AchievementIntegrationService {
  final AchievementDetectorService _detector;
  final AchievementRewardService _rewardService;
  final AchievementToastNotificationService _toastService;
  final AnalyticsService _analyticsService;

  late StreamSubscription<AchievementUnlockEvent> _unlockSubscription;

  // Track rewards granted in current session
  final Map<String, int> _sessionRewards = {
    'currency': 0,
    'badges': 0,
  };

  // Track achievements unlocked this session
  final List<Achievement> _unlockedThisSession = [];

  AchievementIntegrationService({
    required AchievementDetectorService detector,
    required AchievementRewardService rewardService,
    required AchievementToastNotificationService toastService,
    required AnalyticsService analyticsService,
  })  : _detector = detector,
        _rewardService = rewardService,
        _toastService = toastService,
        _analyticsService = analyticsService;

  /// Start integrated achievement processing for a battle
  /// Listens for unlocks, shows toasts, distributes rewards
  Future<void> startBattleAchievements(String userId) async {
    _resetSessionState();
    _detector.startDetecting(userId);

    // Listen to unlock events and process each one
    _unlockSubscription = _detector.unlockEvents.listen((event) async {
      await _processUnlockEvent(userId, event);
    });
  }

  /// Stop achievement processing and return final rewards summary
  Future<Map<String, dynamic>> stopBattleAchievements() async {
    await _unlockSubscription.cancel();
    _detector.stopDetecting();

    final summary = {
      'unlockedCount': _unlockedThisSession.length,
      'totalCurrency': _sessionRewards['currency'] ?? 0,
      'totalBadges': _sessionRewards['badges'] ?? 0,
      'achievements': _unlockedThisSession.map((a) => a.achievementId).toList(),
    };

    return summary;
  }

  /// Process a single achievement unlock: toast + reward + analytics
  Future<void> _processUnlockEvent(
    String userId,
    AchievementUnlockEvent event,
  ) async {
    try {
      // 1. Show notification toast immediately
      _toastService.showAchievementToast(event.achievement);

      // 2. Distribute rewards
      final rewards = await _rewardService.processUnlock(userId, event.achievement);

      // 3. Track session rewards
      _sessionRewards['currency'] = (_sessionRewards['currency'] ?? 0) + (rewards['currency'] as int? ?? 0);
      _sessionRewards['badges'] = (_sessionRewards['badges'] ?? 0) + (rewards['badges'] as int? ?? 0);
      _unlockedThisSession.add(event.achievement);

      // 4. Emit analytics event
      await _analyticsService.logAchievementUnlocked(
        userId,
        event.achievement.achievementId,
        event.achievement.name,
      );

      // 5. Log additional context
      _logUnlockContext(userId, event, rewards);
    } catch (e) {
      // Log error but don't crash the battle
      await _analyticsService.recordError(
        e,
        null,
        reason: 'Achievement unlock processing failed',
        information: 'achievementId: ${event.achievement.achievementId}, userId: $userId',
      );
    }
  }

  /// Log detailed achievement unlock context for analytics/debugging
  void _logUnlockContext(
    String userId,
    AchievementUnlockEvent event,
    Map<String, dynamic> rewards,
  ) {
    final currency = rewards['currency'] as int? ?? 0;
    final badges = rewards['badges'] as int? ?? 0;

    print(
      '🏆 Achievement Unlocked: ${event.achievement.name} '
      '(Tier: ${event.achievement.rewardTier.name}) '
      '(+$currency currency, +$badges badges)',
    );
  }

  /// Get summary of achievements unlocked this session
  Map<String, dynamic> getSessionSummary() {
    return {
      'unlockedCount': _unlockedThisSession.length,
      'totalCurrency': _sessionRewards['currency'] ?? 0,
      'totalBadges': _sessionRewards['badges'] ?? 0,
      'achievements': _unlockedThisSession.map((a) => {
        'id': a.achievementId,
        'name': a.name,
        'tier': a.rewardTier.name,
      }).toList(),
    };
  }

  /// Get list of achievements unlocked this session
  List<Achievement> getUnlockedAchievements() {
    return List.unmodifiable(_unlockedThisSession);
  }

  /// Clear session state (called when starting new battle)
  void _resetSessionState() {
    _sessionRewards.clear();
    _sessionRewards['currency'] = 0;
    _sessionRewards['badges'] = 0;
    _unlockedThisSession.clear();
  }

  /// Debug info about integration state
  Map<String, dynamic> debugGetIntegrationStats() {
    return {
      'detector_stats': _detector.debugGetStats(),
      'session_rewards': _sessionRewards,
      'unlocked_count': _unlockedThisSession.length,
      'achievements': _unlockedThisSession.map((a) => a.achievementId).toList(),
    };
  }

  void dispose() {
    _unlockSubscription.cancel();
    _detector.dispose();
  }
}
