import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shinjuu_league/services/achievement_service.dart';
import 'package:shinjuu_league/services/analytics_service.dart';

void main() {
  setUpAll(() async {
    // Initialize Firebase for integration tests
    await Firebase.initializeApp();
  });

  group('Onboarding → Aha Moment Full Funnel', () {
    late AnalyticsService analyticsService;
    late AchievementService achievementService;

    setUp(() {
      analyticsService = AnalyticsService();
      achievementService = AchievementService();
    });

    group('Complete User Journey', () {
      test('onboarding start logged', () async {
        expect(
          () async => await analyticsService.logOnboardingStart('user123'),
          returnsNormally,
        );
      });

      test('tutorial completion triggers achievement and analytics', () async {
        // Log tutorial start
        await analyticsService.logOnboardingStart('user123');

        // Complete tutorial
        final event = AchievementProgressEvent(
          type: AchievementEventType.tutorialComplete,
        );
        final unlocked = achievementService.updateProgress(event);

        expect(unlocked, contains('tutorial_complete'));

        // Log tutorial completion
        expect(
          () async => await analyticsService.logTutorialComplete('user123'),
          returnsNormally,
        );
      });

      test('first battle entry after tutorial', () async {
        // Setup: tutorial complete
        achievementService.updateProgress(
          AchievementProgressEvent(
            type: AchievementEventType.tutorialComplete,
          ),
        );

        // Log entry to battle
        expect(
          () async => await analyticsService.logFirstBattleEnter('user123'),
          returnsNormally,
        );
      });

      test('first kill = Aha Moment achievement + analytics', () async {
        // Setup: in-battle
        await analyticsService.logFirstBattleEnter('user123');

        // Achievement: first kill
        final event = AchievementProgressEvent(
          type: AchievementEventType.firstKill,
        );
        final unlocked = achievementService.updateProgress(event);

        expect(unlocked, contains('first_kill'));

        // Log Aha Moment (time to first kill in seconds)
        expect(
          () async => await analyticsService.logTimeToAhaMoment('user123', 45),
          returnsNormally,
        );

        // Log battle win
        expect(
          () async => await analyticsService.logFirstBattleWin('user123'),
          returnsNormally,
        );
      });

      test('full funnel: onboarding start → aha moment → analytics logging', () async {
        const userId = 'user123';

        // 1. Onboarding
        await analyticsService.logOnboardingStart(userId);

        // 2. Tutorial
        achievementService.updateProgress(
          AchievementProgressEvent(
            type: AchievementEventType.tutorialComplete,
          ),
        );
        await analyticsService.logTutorialComplete(userId);

        // 3. First Battle
        await analyticsService.logFirstBattleEnter(userId);

        // 4. Aha Moment (First Kill)
        achievementService.updateProgress(
          AchievementProgressEvent(type: AchievementEventType.firstKill),
        );

        expect(
          achievementService.unlockedAchievements,
          contains('first_kill'),
        );

        // Log time to Aha Moment
        await analyticsService.logTimeToAhaMoment(userId, 30);

        // 5. Battle Win
        await analyticsService.logFirstBattleWin(userId);

        // Verify achievements accumulated
        expect(
          achievementService.unlockedAchievements,
          containsAll(['tutorial_complete', 'first_kill']),
        );
      });
    });

    group('Analytics Funnel Event Sequencing', () {
      test('onboarding events can be logged in order', () async {
        const userId = 'user_sequence';

        expect(
          () async => await analyticsService.logOnboardingStart(userId),
          returnsNormally,
        );

        expect(
          () async => await analyticsService.logTutorialComplete(userId),
          returnsNormally,
        );

        expect(
          () async => await analyticsService.logFirstBattleEnter(userId),
          returnsNormally,
        );

        expect(
          () async => await analyticsService.logFirstBattleWin(userId),
          returnsNormally,
        );
      });

      test('multiple users can proceed through funnel independently', () async {
        final userIds = ['user_a', 'user_b', 'user_c'];

        for (final userId in userIds) {
          await analyticsService.logOnboardingStart(userId);
          await analyticsService.logTutorialComplete(userId);
          await analyticsService.logFirstBattleEnter(userId);
          await analyticsService.logTimeToAhaMoment(userId, 60);
          await analyticsService.logFirstBattleWin(userId);
        }

        // All should complete without error
        expect(true, isTrue);
      });

      test('time to Aha Moment accepts various values', () async {
        final times = [0, 5, 15, 30, 60, 120, 300];

        for (final time in times) {
          expect(
            () async => await analyticsService.logTimeToAhaMoment('user123', time),
            returnsNormally,
          );
        }
      });
    });

    group('Achievement and Analytics Synchronization', () {
      test('achievement unlock sequence matches analytics events', () async {
        const userId = 'sync_user';
        final unlockedAchievements = <String>[];

        // Progression 1: Tutorial
        await analyticsService.logOnboardingStart(userId);
        await analyticsService.logTutorialComplete(userId);

        final tutorialEvent = AchievementProgressEvent(
          type: AchievementEventType.tutorialComplete,
        );
        unlockedAchievements.addAll(achievementService.updateProgress(tutorialEvent));

        // Progression 2: First Battle
        await analyticsService.logFirstBattleEnter(userId);

        // Progression 3: Aha Moment
        final killEvent = AchievementProgressEvent(
          type: AchievementEventType.firstKill,
        );
        unlockedAchievements.addAll(achievementService.updateProgress(killEvent));

        await analyticsService.logTimeToAhaMoment(userId, 45);
        await analyticsService.logFirstBattleWin(userId);

        // Verify consistency
        expect(unlockedAchievements, contains('tutorial_complete'));
        expect(unlockedAchievements, contains('first_kill'));
        expect(
          achievementService.unlockedAchievements,
          containsAll(unlockedAchievements),
        );
      });

      test('achievements persist across analytics calls', () async {
        const userId = 'persist_user';

        // Unlock achievement
        final event = AchievementProgressEvent(
          type: AchievementEventType.tutorialComplete,
        );
        achievementService.updateProgress(event);

        // Make multiple analytics calls
        await analyticsService.logOnboardingStart(userId);
        await analyticsService.logTutorialComplete(userId);
        await analyticsService.logFirstBattleEnter(userId);

        // Achievement should still be present
        expect(
          achievementService.unlockedAchievements,
          contains('tutorial_complete'),
        );
      });
    });

    group('Retention Metrics in Funnel', () {
      test('Day 1 active tracking in context of Aha Moment', () async {
        const userId = 'day1_user';

        // Complete onboarding
        await analyticsService.logOnboardingStart(userId);
        await analyticsService.logTutorialComplete(userId);
        await analyticsService.logFirstBattleEnter(userId);

        // Trigger Aha Moment
        achievementService.updateProgress(
          AchievementProgressEvent(type: AchievementEventType.firstKill),
        );
        await analyticsService.logTimeToAhaMoment(userId, 30);

        // Log Day 1 active
        expect(
          () async => await analyticsService.logDay1Active(userId),
          returnsNormally,
        );
      });

      test('Day 7 and Day 30 retention events can follow onboarding', () async {
        const userId = 'retention_user';

        await analyticsService.logOnboardingStart(userId);
        await analyticsService.logDay1Active(userId);
        await analyticsService.logDay7Active(userId);
        await analyticsService.logDay30Active(userId);

        expect(true, isTrue);
      });
    });

    group('Cohort Assignment in Onboarding', () {
      test('user cohort properties set during onboarding', () async {
        const userId = 'cohort_user';

        // Onboarding
        await analyticsService.logOnboardingStart(userId);

        // Set cohort properties (simulating assignment)
        expect(
          () async => await analyticsService.setCohortProperties(
            userId,
            installCohort: '2026-09-02',
            platformCohort: 'android',
            purchaseCohort: 'F2P',
          ),
          returnsNormally,
        );

        // Continue funnel
        await analyticsService.logTutorialComplete(userId);
        await analyticsService.logFirstBattleEnter(userId);
      });

      test('different users assigned to different purchase cohorts', () async {
        await analyticsService.setCohortProperties(
          'user_d1payer',
          installCohort: '2026-09-01',
          platformCohort: 'ios',
          purchaseCohort: 'D1Payer',
        );

        await analyticsService.setCohortProperties(
          'user_f2p',
          installCohort: '2026-09-02',
          platformCohort: 'android',
          purchaseCohort: 'F2P',
        );

        await analyticsService.setCohortProperties(
          'user_whale',
          installCohort: '2026-08-15',
          platformCohort: 'ios',
          purchaseCohort: 'Whale',
        );

        expect(true, isTrue);
      });
    });
  });
}
