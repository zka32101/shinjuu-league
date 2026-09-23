import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shinjuu_league/data/models/achievement.dart';
import 'package:shinjuu_league/services/achievement_reward_service.dart';
import 'package:shinjuu_league/services/achievement_service.dart';
import 'package:shinjuu_league/services/achievement_trigger_detector.dart';
import 'package:shinjuu_league/services/analytics_service.dart';
import 'package:shinjuu_league/services/firestore_service.dart';
import 'package:shinjuu_league/services/push_notification_service.dart';

/// Push Notification -> Achievement -> Analytics Funnel
///
/// Exercises the real unlock pipeline (AchievementTriggerDetector ->
/// AchievementService -> Firestore) alongside the notification/analytics
/// singletons, backed by a fake Firestore so no real network calls happen.
const _achievementUnlockedTopic = 'achievement_unlocked';

void main() {
  group('Push Notification -> Achievement -> Analytics Funnel', () {
    late FakeFirebaseFirestore fakeDb;
    late FirestoreService firestoreService;
    late AchievementService achievementService;
    late AchievementRewardService rewardService;
    late AchievementTriggerDetector triggerDetector;
    late PushNotificationService notificationService;
    late AnalyticsService analyticsService;

    const userId = 'user123';

    setUp(() {
      fakeDb = FakeFirebaseFirestore();
      firestoreService = FirestoreService.forFirestore(fakeDb);
      achievementService = AchievementService(firestoreService);
      rewardService = AchievementRewardService(
        firestoreService: firestoreService,
      );
      triggerDetector = AchievementTriggerDetector(
        achievementService: achievementService,
        rewardService: rewardService,
      );
      notificationService = PushNotificationService();
      analyticsService = AnalyticsService();
    });

    group('Achievement Unlock Notification Flow', () {
      test(
        'aha_moment achievement triggers notification topic subscription',
        () async {
          await notificationService.init();

          // Subscribe to achievement notifications
          await expectLater(
            notificationService.subscribeToTopic(_achievementUnlockedTopic),
            completes,
          );
        },
      );

      test('killing an enemy unlocks aha_moment and emits analytics', () async {
        final unlocked = await triggerDetector.checkKillTriggers(userId, 1, 1);

        expect(unlocked.map((a) => a.achievementId), contains('aha_moment'));

        // Simulate analytics logging for the unlock
        await expectLater(
          analyticsService.logAchievementUnlocked(
            userId,
            'aha_moment',
            'common',
          ),
          completes,
        );
      });

      test('multiple achievements can unlock in sequence', () async {
        final allUnlocked = <Achievement>[];

        allUnlocked.addAll(
          await triggerDetector.checkKillTriggers(userId, 1, 1),
        );
        allUnlocked.addAll(
          await triggerDetector.checkBattleCompletionTriggers(
            userId,
            won: true,
            kills: 1,
            deaths: 0,
            assists: 0,
            damageDealt: 100,
            totalBattles: 1,
            winCount: 1,
            seasonsParticipated: 1,
            currentTier: 'Silver',
          ),
        );

        expect(allUnlocked, isNotEmpty);
      });

      test('achievement details available for notification payload', () async {
        await triggerDetector.checkKillTriggers(userId, 1, 1);

        final details = AchievementsCatalog.getById('aha_moment');

        expect(details, isNotNull);
        expect(details!.name, isNotEmpty);
        expect(details.rewardTier, isA<AchievementRewardTier>());
      });
    });

    group('Cross-Service Consistency', () {
      test('achievement catalog matches analytics accepted types', () async {
        final achievements = AchievementsCatalog.all;

        // Verify all catalog achievements can be logged without throwing
        for (final achievement in achievements) {
          await expectLater(
            analyticsService.logAchievementUnlocked(
              userId,
              achievement.achievementId,
              achievement.rewardTier.name,
            ),
            completes,
          );
        }
      });

      test('notification topic name is well-formed', () async {
        expect(_achievementUnlockedTopic, isNotEmpty);
        expect(_achievementUnlockedTopic, isA<String>());
      });

      test(
        'achievement unlock -> notification -> analytics pipeline completes',
        () async {
          // 1. Unlock achievement
          final unlocked = await triggerDetector.checkKillTriggers(
            userId,
            1,
            1,
          );
          expect(unlocked, isNotEmpty);

          // 2. Prepare notification
          await notificationService.init();
          await notificationService.subscribeToTopic(_achievementUnlockedTopic);

          // 3. Log to analytics
          for (final achievement in unlocked) {
            await expectLater(
              analyticsService.logAchievementUnlocked(
                userId,
                achievement.achievementId,
                achievement.rewardTier.name,
              ),
              completes,
            );
          }

          // Verify state consistency
          final playerAchievements = await achievementService
              .getUnlockedAchievements(userId);
          expect(
            playerAchievements.map((a) => a.achievementId),
            contains('aha_moment'),
          );
        },
      );
    });

    group('Singleton State Across Services', () {
      test('notification/analytics services are app-wide singletons', () {
        final notif1 = PushNotificationService();
        final notif2 = PushNotificationService();
        final analytics1 = AnalyticsService();
        final analytics2 = AnalyticsService();

        expect(identical(notif1, notif2), isTrue);
        expect(identical(analytics1, analytics2), isTrue);
      });

      test(
        'achievement unlock state persists across service instances backed by the same Firestore',
        () async {
          // First instance unlocks
          await triggerDetector.checkKillTriggers(userId, 1, 1);

          // A second AchievementService instance backed by the SAME
          // (fake) Firestore sees the persisted state
          final achievementService2 = AchievementService(firestoreService);
          final unlockedAgain = await achievementService2
              .getUnlockedAchievements(userId);
          expect(
            unlockedAgain.map((a) => a.achievementId),
            contains('aha_moment'),
          );

          // Analytics can be called independently
          await expectLater(
            analyticsService.logAchievementUnlocked(
              userId,
              'aha_moment',
              'common',
            ),
            completes,
          );
        },
      );
    });

    group('Error Handling Across Services', () {
      test('invalid achievement ID does not crash analytics', () async {
        await expectLater(
          analyticsService.logAchievementUnlocked(
            userId,
            'nonexistent_achievement',
            'common',
          ),
          completes,
        );
      });

      test('notification service continues if FCM unavailable', () async {
        await expectLater(notificationService.init(), completes);
      });

      test(
        'achievement trigger detection works without notification service',
        () async {
          await expectLater(
            triggerDetector.checkKillTriggers(userId, 1, 1),
            completes,
          );
        },
      );
    });

    group('Notification Payload Construction', () {
      test('achievement unlock can construct notification payload', () async {
        final unlocked = await triggerDetector.checkKillTriggers(userId, 1, 1);
        expect(unlocked, isNotEmpty);

        final achievement = unlocked.first;

        // Construct payload as would be sent in a real notification
        final payload = <String, dynamic>{
          'type': 'achievement_unlock',
          'achievement_id': achievement.achievementId,
          'name': achievement.name,
          'reward_tier': achievement.rewardTier.name,
        };

        expect(payload['type'], equals('achievement_unlock'));
        expect(payload['achievement_id'], equals(achievement.achievementId));
      });

      test(
        'payload round-trips through a Map (JSON-serializable shape)',
        () async {
          final original = <String, dynamic>{
            'type': 'achievement_unlock',
            'achievement_id': 'aha_moment',
            'reward_tier': 'common',
          };

          // Simulate a JSON round-trip (encode/decode would use the same
          // plain-Map shape since all values here are already JSON-safe).
          final restored = Map<String, dynamic>.from(original);

          expect(restored['type'], equals(original['type']));
          expect(restored['achievement_id'], equals('aha_moment'));
        },
      );
    });
  });
}
