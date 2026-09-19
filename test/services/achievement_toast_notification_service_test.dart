import 'package:flutter_test/flutter_test.dart';
import 'package:shinjuu_league/data/models/achievement.dart';
import 'package:shinjuu_league/services/achievement_toast_notification_service.dart';

void main() {
  group('AchievementToastNotificationService', () {
    late AchievementToastNotificationService service;

    final testAchievement = Achievement(
      achievementId: 'test_achievement',
      category: AchievementCategory.milestone,
      name: 'Test Achievement',
      description: 'Test description',
      iconUrl: 'assets/test.png',
      rewardTier: AchievementRewardTier.common,
      maxProgress: 1,
      isProgressBased: false,
    );

    final testAchievement2 = Achievement(
      achievementId: 'test_achievement_2',
      category: AchievementCategory.milestone,
      name: 'Test Achievement 2',
      description: 'Test description 2',
      iconUrl: 'assets/test2.png',
      rewardTier: AchievementRewardTier.rare,
      maxProgress: 1,
      isProgressBased: false,
    );

    setUp(() {
      service = AchievementToastNotificationService();
    });

    tearDown(() {
      service.dispose();
    });

    test('shows achievement toast notification', () async {
      final completer = Completer<AchievementToastNotification>();
      service.notifications.first.then((notification) {
        completer.complete(notification);
      });

      final id = await service.showAchievementToast(testAchievement);

      expect(id, isNotEmpty);
      final notification = await completer.future;
      expect(notification.achievement.achievementId, equals('test_achievement'));
      expect(notification.id, equals(id));
    });

    test('queues multiple notifications', () async {
      final notifications = <AchievementToastNotification>[];
      final subscription = service.notifications.listen(notifications.add);

      await service.showAchievementToast(testAchievement);
      await Future.delayed(const Duration(milliseconds: 50));
      await service.showAchievementToast(testAchievement2);
      await Future.delayed(const Duration(milliseconds: 50));

      await subscription.cancel();

      // Both should be in queue/displayed eventually
      expect(notifications.length, greaterThanOrEqualTo(1));
    });

    test('dismisses notification automatically after duration', () async {
      service = AchievementToastNotificationService(
        displayDuration: const Duration(milliseconds: 100),
      );

      final dismissals = <String>[];
      service.dismissals.listen(dismissals.add);

      final id = await service.showAchievementToast(testAchievement);

      // Wait for auto-dismiss
      await Future.delayed(const Duration(milliseconds: 200));

      expect(dismissals, contains(id));
    });

    test('manual dismissal removes notification', () async {
      final dismissals = <String>[];
      service.dismissals.listen(dismissals.add);

      final id = await service.showAchievementToast(testAchievement);
      await Future.delayed(const Duration(milliseconds: 50));

      service.dismiss(id);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(dismissals, contains(id));
    });

    test('respects max concurrent notifications', () async {
      service = AchievementToastNotificationService(
        maxConcurrentNotifications: 2,
      );

      final notifications = <AchievementToastNotification>[];
      service.notifications.listen(notifications.add);

      await service.showAchievementToast(testAchievement);
      await Future.delayed(const Duration(milliseconds: 50));
      await service.showAchievementToast(testAchievement2);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(service.displayedCount, lessThanOrEqualTo(2));
    });

    test('clears all notifications', () async {
      await service.showAchievementToast(testAchievement);
      await service.showAchievementToast(testAchievement2);

      expect(service.displayedCount + service.queueSize, greaterThan(0));

      service.clearAll();

      expect(service.displayedCount, equals(0));
      expect(service.queueSize, equals(0));
    });

    test('tracks displayed notifications', () async {
      final id = await service.showAchievementToast(testAchievement);

      expect(service.isDisplayed(id), isTrue);

      service.dismiss(id);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(service.isDisplayed(id), isFalse);
    });

    test('processes queue after dismissal', () async {
      service = AchievementToastNotificationService(
        displayDuration: const Duration(milliseconds: 500),
        maxConcurrentNotifications: 1,
      );

      final notifications = <AchievementToastNotification>[];
      service.notifications.listen(notifications.add);

      final id1 = await service.showAchievementToast(testAchievement);
      await Future.delayed(const Duration(milliseconds: 50));

      // Add second while first is displayed (should queue)
      final id2 = await service.showAchievementToast(testAchievement2);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(service.displayedCount, equals(1));
      expect(service.queueSize, equals(1));

      // Dismiss first
      service.dismiss(id1);
      await Future.delayed(const Duration(milliseconds: 50));

      // Second should now be displayed
      expect(service.displayedCount, equals(1));
      expect(service.queueSize, equals(0));
    });

    test('returns valid debug stats', () {
      final stats = service.debugGetStats();

      expect(stats, containsPair('displayed_count', 0));
      expect(stats, containsPair('queue_size', 0));
      expect(stats, containsPair('max_concurrent', 3));
      expect(stats, containsPair('display_duration_ms', 3000));
    });

    test('returns displayed notification IDs for debugging', () async {
      final id1 = await service.showAchievementToast(testAchievement);
      final id2 = await service.showAchievementToast(testAchievement2);

      final displayedIds = service.debugGetDisplayedIds();

      expect(displayedIds.length, greaterThanOrEqualTo(1));
      expect(displayedIds, contains(id1));
    });

    test('handles rapid successive notifications', () async {
      final notifications = <AchievementToastNotification>[];
      service.notifications.listen(notifications.add);

      for (int i = 0; i < 5; i++) {
        await service.showAchievementToast(testAchievement);
      }

      await Future.delayed(const Duration(milliseconds: 100));

      // All should be queued and processing
      expect(notifications.length, greaterThanOrEqualTo(1));
      expect(service.displayedCount + service.queueSize, equals(5));
    });

    test('notification stream emits correct data', () async {
      final notification = await service.notifications.first;
      await service.showAchievementToast(testAchievement);

      await expectLater(
        service.notifications,
        emits(
          isA<AchievementToastNotification>()
              .having(
                (n) => n.achievement.achievementId,
                'achievementId',
                'test_achievement',
              )
              .having((n) => n.id, 'id', isNotEmpty),
        ),
      );
    });

    test('dismissal stream emits notification IDs', () async {
      final id = await service.showAchievementToast(testAchievement);
      await Future.delayed(const Duration(milliseconds: 50));

      service.dismiss(id);

      await expectLater(
        service.dismissals,
        emits(id),
      );
    });

    test('notification has correct creation timestamp', () async {
      final before = DateTime.now();
      final id = await service.showAchievementToast(testAchievement);
      final after = DateTime.now();

      final notification = await service.notifications.first;

      expect(
        notification.createdAt.isAfter(before.subtract(const Duration(milliseconds: 100))),
        isTrue,
      );
      expect(
        notification.createdAt.isBefore(after.add(const Duration(milliseconds: 100))),
        isTrue,
      );
    });
  });
}
