import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shinjuu_league/config/achievement_feature_flags.dart';
import 'package:shinjuu_league/data/models/achievement.dart';
import 'package:shinjuu_league/services/achievement_push_notification_service.dart';
import 'package:shinjuu_league/services/analytics_service.dart';
import 'package:shinjuu_league/services/push_notification_service.dart';

class MockPushNotificationService extends Mock implements PushNotificationService {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

class MockAchievementFeatureFlags extends Mock implements AchievementFeatureFlags {}

void main() {
  group('AchievementPushNotificationService', () {
    late AchievementPushNotificationService service;
    late MockPushNotificationService mockPushNotification;
    late MockAnalyticsService mockAnalytics;
    late MockAchievementFeatureFlags mockFeatureFlags;

    const String userId = 'user_123';

    final testAchievement = Achievement(
      achievementId: 'stat_master',
      category: AchievementCategory.skill,
      name: 'ステータスマスター',
      description: 'Test',
      iconUrl: 'test.png',
      rewardTier: AchievementRewardTier.silver,
      maxProgress: 50,
      isProgressBased: true,
    );

    setUp(() {
      mockPushNotification = MockPushNotificationService();
      mockAnalytics = MockAnalyticsService();
      mockFeatureFlags = MockAchievementFeatureFlags();

      // Default behavior
      when(mockFeatureFlags.isPushNotificationEnabled()).thenReturn(true);
      when(mockFeatureFlags.getPushNotificationThresholdPercent()).thenReturn(75);

      service = AchievementPushNotificationService(
        pushNotificationService: mockPushNotification,
        analyticsService: mockAnalytics,
        featureFlags: mockFeatureFlags,
      );
    });

    group('checkAndSendNearCompletionNotification', () {
      test('sends notification when progress >= threshold', () async {
        final playerAchievement = PlayerAchievement(
          userId: userId,
          achievementId: 'stat_master',
          progress: AchievementProgress(current: 38, target: 50),
        );

        final result = await service.checkAndSendNearCompletionNotification(
          userId,
          testAchievement,
          playerAchievement,
        );

        expect(result, isTrue);
        verify(mockPushNotification.showNotification(
          title: any,
          body: any,
          payload: any,
        )).called(1);
      });

      test('sends notification with correct parameters', () async {
        final playerAchievement = PlayerAchievement(
          userId: userId,
          achievementId: 'stat_master',
          progress: AchievementProgress(current: 40, target: 50),
        );

        await service.checkAndSendNearCompletionNotification(
          userId,
          testAchievement,
          playerAchievement,
        );

        verify(mockAnalytics.logAchievementNotificationSent(
          userId,
          'stat_master',
          80, // 40/50 * 100
        )).called(1);
      });

      test('does not send notification when progress < threshold', () async {
        final playerAchievement = PlayerAchievement(
          userId: userId,
          achievementId: 'stat_master',
          progress: AchievementProgress(current: 30, target: 50),
        );

        final result = await service.checkAndSendNearCompletionNotification(
          userId,
          testAchievement,
          playerAchievement,
        );

        expect(result, isFalse);
        verifyNever(mockPushNotification.showNotification(
          title: any,
          body: any,
          payload: any,
        ));
      });

      test('skips non-progress-based achievements', () async {
        final instantAchievement = testAchievement.copyWith(
          isProgressBased: false,
          maxProgress: 1,
        );

        final playerAchievement = PlayerAchievement(
          userId: userId,
          achievementId: 'instant_achievement',
        );

        final result = await service.checkAndSendNearCompletionNotification(
          userId,
          instantAchievement,
          playerAchievement,
        );

        expect(result, isFalse);
        verifyNever(mockPushNotification.showNotification(
          title: any,
          body: any,
          payload: any,
        ));
      });

      test('skips when playerAchievement is null', () async {
        final result = await service.checkAndSendNearCompletionNotification(
          userId,
          testAchievement,
          null,
        );

        expect(result, isFalse);
        verifyNever(mockPushNotification.showNotification(
          title: any,
          body: any,
          payload: any,
        ));
      });

      test('skips when achievement is already unlocked', () async {
        final playerAchievement = PlayerAchievement(
          userId: userId,
          achievementId: 'stat_master',
          unlockedAt: DateTime.now(),
          progress: AchievementProgress(current: 50, target: 50),
        );

        final result = await service.checkAndSendNearCompletionNotification(
          userId,
          testAchievement,
          playerAchievement,
        );

        expect(result, isFalse);
        verifyNever(mockPushNotification.showNotification(
          title: any,
          body: any,
          payload: any,
        ));
      });

      test('respects push notification enabled flag', () async {
        when(mockFeatureFlags.isPushNotificationEnabled()).thenReturn(false);

        final playerAchievement = PlayerAchievement(
          userId: userId,
          achievementId: 'stat_master',
          progress: AchievementProgress(current: 40, target: 50),
        );

        final result = await service.checkAndSendNearCompletionNotification(
          userId,
          testAchievement,
          playerAchievement,
        );

        expect(result, isFalse);
        verifyNever(mockPushNotification.showNotification(
          title: any,
          body: any,
          payload: any,
        ));
      });

      test('respects configurable threshold percentage', () async {
        when(mockFeatureFlags.getPushNotificationThresholdPercent())
            .thenReturn(90);

        final playerAchievement = PlayerAchievement(
          userId: userId,
          achievementId: 'stat_master',
          progress: AchievementProgress(current: 40, target: 50),
        );

        final result = await service.checkAndSendNearCompletionNotification(
          userId,
          testAchievement,
          playerAchievement,
        );

        expect(result, isFalse); // 40/50 = 80%, but threshold is 90%
      });

      test('prevents duplicate notifications for same achievement', () async {
        final playerAchievement = PlayerAchievement(
          userId: userId,
          achievementId: 'stat_master',
          progress: AchievementProgress(current: 40, target: 50),
        );

        // First call should send
        final result1 = await service.checkAndSendNearCompletionNotification(
          userId,
          testAchievement,
          playerAchievement,
        );
        expect(result1, isTrue);

        // Second call should not send
        final result2 = await service.checkAndSendNearCompletionNotification(
          userId,
          testAchievement,
          playerAchievement,
        );
        expect(result2, isFalse);

        verify(mockPushNotification.showNotification(
          title: any,
          body: any,
          payload: any,
        )).called(1); // Only called once
      });

      test('allows notifications for different achievements of same user', () async {
        final achievement1 = testAchievement.copyWith(achievementId: 'ach_1');
        final achievement2 = testAchievement.copyWith(achievementId: 'ach_2');

        final playerAch1 = PlayerAchievement(
          userId: userId,
          achievementId: 'ach_1',
          progress: AchievementProgress(current: 40, target: 50),
        );

        final playerAch2 = PlayerAchievement(
          userId: userId,
          achievementId: 'ach_2',
          progress: AchievementProgress(current: 40, target: 50),
        );

        final result1 = await service.checkAndSendNearCompletionNotification(
          userId,
          achievement1,
          playerAch1,
        );
        final result2 = await service.checkAndSendNearCompletionNotification(
          userId,
          achievement2,
          playerAch2,
        );

        expect(result1, isTrue);
        expect(result2, isTrue);
        verify(mockPushNotification.showNotification(
          title: any,
          body: any,
          payload: any,
        )).called(2); // Called twice
      });

      test('handles exceptions gracefully', () async {
        when(mockPushNotification.showNotification(
          title: any,
          body: any,
          payload: any,
        )).thenThrow(Exception('Push notification error'));

        final playerAchievement = PlayerAchievement(
          userId: userId,
          achievementId: 'stat_master',
          progress: AchievementProgress(current: 40, target: 50),
        );

        final result = await service.checkAndSendNearCompletionNotification(
          userId,
          testAchievement,
          playerAchievement,
        );

        // Should not throw, just log error
        expect(result, isFalse);
        verify(mockAnalytics.recordError(
          any,
          any,
          reason: anyNamed('reason'),
          information: anyNamed('information'),
        )).called(1);
      });

      test('calculates progress percentage correctly', () async {
        final playerAchievement = PlayerAchievement(
          userId: userId,
          achievementId: 'stat_master',
          progress: AchievementProgress(current: 25, target: 100),
        );

        when(mockFeatureFlags.getPushNotificationThresholdPercent())
            .thenReturn(25);

        await service.checkAndSendNearCompletionNotification(
          userId,
          testAchievement,
          playerAchievement,
        );

        verify(mockAnalytics.logAchievementNotificationSent(
          userId,
          'stat_master',
          25, // 25/100 * 100
        )).called(1);
      });
    });

    group('resetNotificationTracking', () {
      test('clears notifications for specific user', () async {
        final playerAchievement = PlayerAchievement(
          userId: userId,
          achievementId: 'stat_master',
          progress: AchievementProgress(current: 40, target: 50),
        );

        // Send notification
        await service.checkAndSendNearCompletionNotification(
          userId,
          testAchievement,
          playerAchievement,
        );
        expect(service.wasNotificationSent(userId, 'stat_master'), isTrue);

        // Reset
        service.resetNotificationTracking(userId);
        expect(service.wasNotificationSent(userId, 'stat_master'), isFalse);
      });

      test('allows re-sending after reset', () async {
        final playerAchievement = PlayerAchievement(
          userId: userId,
          achievementId: 'stat_master',
          progress: AchievementProgress(current: 40, target: 50),
        );

        // Send notification
        await service.checkAndSendNearCompletionNotification(
          userId,
          testAchievement,
          playerAchievement,
        );

        // Reset
        service.resetNotificationTracking(userId);

        // Send again
        final result = await service.checkAndSendNearCompletionNotification(
          userId,
          testAchievement,
          playerAchievement,
        );

        expect(result, isTrue);
        verify(mockPushNotification.showNotification(
          title: any,
          body: any,
          payload: any,
        )).called(2); // Called twice
      });
    });

    group('resetAllNotificationTracking', () {
      test('clears all user notifications', () async {
        final playerAch = PlayerAchievement(
          userId: userId,
          achievementId: 'stat_master',
          progress: AchievementProgress(current: 40, target: 50),
        );

        await service.checkAndSendNearCompletionNotification(
          userId,
          testAchievement,
          playerAch,
        );

        service.resetAllNotificationTracking();
        expect(service.wasNotificationSent(userId, 'stat_master'), isFalse);
      });
    });

    group('wasNotificationSent', () {
      test('returns true for sent notifications', () async {
        final playerAchievement = PlayerAchievement(
          userId: userId,
          achievementId: 'stat_master',
          progress: AchievementProgress(current: 40, target: 50),
        );

        await service.checkAndSendNearCompletionNotification(
          userId,
          testAchievement,
          playerAchievement,
        );

        expect(service.wasNotificationSent(userId, 'stat_master'), isTrue);
      });

      test('returns false for unsent notifications', () async {
        expect(service.wasNotificationSent(userId, 'stat_master'), isFalse);
      });

      test('returns false for different achievement', () async {
        final playerAchievement = PlayerAchievement(
          userId: userId,
          achievementId: 'stat_master',
          progress: AchievementProgress(current: 40, target: 50),
        );

        await service.checkAndSendNearCompletionNotification(
          userId,
          testAchievement,
          playerAchievement,
        );

        expect(service.wasNotificationSent(userId, 'different_id'), isFalse);
      });
    });

    group('debugGetNotificationStats', () {
      test('returns empty stats initially', () {
        final stats = service.debugGetNotificationStats();

        expect(stats['total_users'], equals(0));
        expect(stats['total_notifications_sent'], equals(0));
      });

      test('tracks notification count correctly', () async {
        final playerAch1 = PlayerAchievement(
          userId: userId,
          achievementId: 'ach_1',
          progress: AchievementProgress(current: 40, target: 50),
        );

        final playerAch2 = PlayerAchievement(
          userId: userId,
          achievementId: 'ach_2',
          progress: AchievementProgress(current: 40, target: 50),
        );

        final ach1 = testAchievement.copyWith(achievementId: 'ach_1');
        final ach2 = testAchievement.copyWith(achievementId: 'ach_2');

        await service.checkAndSendNearCompletionNotification(
          userId,
          ach1,
          playerAch1,
        );
        await service.checkAndSendNearCompletionNotification(
          userId,
          ach2,
          playerAch2,
        );

        final stats = service.debugGetNotificationStats();
        expect(stats['total_users'], equals(1));
        expect(stats['total_notifications_sent'], equals(2));
      });

      test('tracks per-user notification counts', () async {
        final user1 = 'user_1';
        final user2 = 'user_2';

        final playerAch1 = PlayerAchievement(
          userId: user1,
          achievementId: 'stat_master',
          progress: AchievementProgress(current: 40, target: 50),
        );

        final playerAch2 = PlayerAchievement(
          userId: user2,
          achievementId: 'stat_master',
          progress: AchievementProgress(current: 40, target: 50),
        );

        await service.checkAndSendNearCompletionNotification(
          user1,
          testAchievement,
          playerAch1,
        );
        await service.checkAndSendNearCompletionNotification(
          user2,
          testAchievement,
          playerAch2,
        );

        final stats = service.debugGetNotificationStats();
        expect(stats['total_users'], equals(2));
        expect(stats['notifications_by_user'][user1], equals(1));
        expect(stats['notifications_by_user'][user2], equals(1));
      });
    });
  });
}
