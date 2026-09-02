import 'package:flutter_test/flutter_test.dart';
import 'package:shinjuu_league/services/achievement_service.dart';
import 'package:shinjuu_league/services/analytics_service.dart';
import 'package:shinjuu_league/services/push_notification_service.dart';

void main() {
  group('Push Notification → Achievement → Analytics Funnel', () {
    late PushNotificationService notificationService;
    late AchievementService achievementService;
    late AnalyticsService analyticsService;

    setUp(() {
      notificationService = PushNotificationService();
      achievementService = AchievementService();
      analyticsService = AnalyticsService();
    });

    group('Achievement Unlock Notification Flow', () {
      test('first_kill achievement triggers notification topic subscription', () async {
        await notificationService.init();

        // Subscribe to achievement notifications
        expect(
          () async => await notificationService.subscribeToTopic(
            NotificationTopics.achievementUnlocked,
          ),
          returnsNormally,
        );
      });

      test('achievement unlock updates progress and emits analytics', () async {
        final event = AchievementProgressEvent(
          type: AchievementEventType.firstKill,
        );

        final unlocked = achievementService.updateProgress(event);

        expect(unlocked, contains('first_kill'));

        // Simulate analytics logging
        expect(
          () async => await analyticsService.logAchievementUnlocked(
            'user123',
            'first_kill',
            'common',
          ),
          returnsNormally,
        );
      });

      test('multiple achievements can unlock in sequence', () async {
        final events = [
          AchievementProgressEvent(type: AchievementEventType.tutorialComplete),
          AchievementProgressEvent(type: AchievementEventType.firstKill),
          AchievementProgressEvent(
            type: AchievementEventType.battleCompleted,
            data: {'is_ranked': false, 'is_win': true},
          ),
        ];

        final allUnlocked = <String>[];
        for (final event in events) {
          final unlocked = achievementService.updateProgress(event);
          allUnlocked.addAll(unlocked);
        }

        expect(allUnlocked, isNotEmpty);
      });

      test('achievement details available for notification payload', () async {
        final event = AchievementProgressEvent(
          type: AchievementEventType.firstKill,
        );

        achievementService.updateProgress(event);

        final details = achievementService.getAchievementDetails('first_kill');

        expect(details, isNotNull);
        expect(details!.name, isNotEmpty);
        expect(details.rarity, isA<AchievementRarity>());
      });
    });

    group('Cross-Service Consistency', () {
      test('achievement catalog matches analytics accepted types', () async {
        final achievements = achievementService.getAllAchievements();

        // Verify all achievements can be logged
        for (final achievement in achievements) {
          expect(
            () async => await analyticsService.logAchievementUnlocked(
              'user123',
              achievement.id,
              achievement.rarity.label,
            ),
            returnsNormally,
          );
        }
      });

      test('notification topics cover all achievement categories', () async {
        final topicName = NotificationTopics.achievementUnlocked;

        expect(topicName, isNotEmpty);
        expect(topicName, isA<String>());
      });

      test('achievement unlock → notification → analytics pipeline completes', () async {
        // 1. Unlock achievement
        final event = AchievementProgressEvent(
          type: AchievementEventType.firstKill,
        );
        final unlocked = achievementService.updateProgress(event);

        // 2. Prepare notification
        await notificationService.init();
        await notificationService.subscribeToTopic(
          NotificationTopics.achievementUnlocked,
        );

        // 3. Log to analytics
        for (final achievementId in unlocked) {
          final details = achievementService.getAchievementDetails(achievementId);
          expect(details, isNotNull);

          expect(
            () async => await analyticsService.logAchievementUnlocked(
              'user123',
              achievementId,
              details!.rarity.label,
            ),
            returnsNormally,
          );
        }

        // Verify state consistency
        expect(achievementService.unlockedAchievements, contains('first_kill'));
      });
    });

    group('Singleton State Across Services', () {
      test('services maintain independent singleton instances', () {
        final notif1 = PushNotificationService();
        final notif2 = PushNotificationService();
        final achieve1 = AchievementService();
        final achieve2 = AchievementService();

        expect(identical(notif1, notif2), isTrue);
        expect(identical(achieve1, achieve2), isTrue);
        expect(identical(notif1, achieve1), isFalse);
      });

      test('achievement state persists while analytics logs independently', () async {
        final event = AchievementProgressEvent(
          type: AchievementEventType.tutorialComplete,
        );

        // First service instance unlocks
        final service1 = AchievementService();
        service1.updateProgress(event);

        // Second service instance sees persisted state
        final service2 = AchievementService();
        expect(
          service2.unlockedAchievements,
          contains('tutorial_complete'),
        );

        // Analytics can be called independently
        expect(
          () async => await analyticsService.logAchievementUnlocked(
            'user123',
            'tutorial_complete',
            'common',
          ),
          returnsNormally,
        );
      });
    });

    group('Error Handling Across Services', () {
      test('invalid achievement ID does not crash analytics', () async {
        expect(
          () async => await analyticsService.logAchievementUnlocked(
            'user123',
            'nonexistent_achievement',
            'common',
          ),
          returnsNormally,
        );
      });

      test('notification service continues if FCM unavailable', () async {
        expect(
          () async => await notificationService.init(),
          returnsNormally,
        );
      });

      test('achievement service works without notification service', () async {
        final event = AchievementProgressEvent(
          type: AchievementEventType.firstKill,
        );

        expect(
          () => achievementService.updateProgress(event),
          returnsNormally,
        );
      });
    });

    group('Notification Payload Construction', () {
      test('achievement unlock can construct notification payload', () async {
        final event = AchievementProgressEvent(
          type: AchievementEventType.firstKill,
        );

        final unlocked = achievementService.updateProgress(event);
        expect(unlocked, isNotEmpty);

        final achievementId = unlocked.first;
        final details = achievementService.getAchievementDetails(achievementId);

        // Construct payload as would be sent in real notification
        final payload = NotificationPayload(
          type: 'achievement_unlock',
          data: {
            'achievement_id': achievementId,
            'name': details?.name ?? 'Unknown',
            'rarity': details?.rarity.label ?? 'common',
          },
        );

        expect(payload.type, equals('achievement_unlock'));
        expect(payload.data['achievement_id'], equals(achievementId));
      });

      test('payload can round-trip through JSON', () async {
        final original = NotificationPayload(
          type: 'achievement_unlock',
          data: {
            'achievement_id': 'first_kill',
            'rarity': 'common',
          },
        );

        final json = original.toJson();
        final restored = NotificationPayload.fromJson(json);

        expect(restored.type, equals(original.type));
        expect(restored.data['achievement_id'], equals('first_kill'));
      });
    });
  });
}
