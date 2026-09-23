import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shinjuu_league/services/achievement_reward_service.dart';
import 'package:shinjuu_league/services/achievement_service.dart';
import 'package:shinjuu_league/services/achievement_trigger_detector.dart';
import 'package:shinjuu_league/services/analytics_service.dart';
import 'package:shinjuu_league/services/firestore_service.dart';

/// Onboarding -> Aha Moment full funnel.
///
/// Exercises the real unlock pipeline (AchievementTriggerDetector ->
/// AchievementService -> Firestore) backed by a fake Firestore, alongside
/// the real AnalyticsService singleton (all calls are fire-and-forget and
/// safe without Firebase initialization).
void main() {
  group('Onboarding → Aha Moment Full Funnel', () {
    late FakeFirebaseFirestore fakeDb;
    late FirestoreService firestoreService;
    late AnalyticsService analyticsService;
    late AchievementService achievementService;
    late AchievementRewardService rewardService;
    late AchievementTriggerDetector triggerDetector;

    setUp(() {
      fakeDb = FakeFirebaseFirestore();
      firestoreService = FirestoreService.forFirestore(fakeDb);
      analyticsService = AnalyticsService();
      achievementService = AchievementService(firestoreService);
      rewardService = AchievementRewardService(
        firestoreService: firestoreService,
      );
      triggerDetector = AchievementTriggerDetector(
        achievementService: achievementService,
        rewardService: rewardService,
      );
    });

    group('Complete User Journey', () {
      test('onboarding start logged', () async {
        await expectLater(
          analyticsService.logOnboardingStart('user123'),
          completes,
        );
      });

      test('tutorial completion logged', () async {
        // Log tutorial start
        await analyticsService.logOnboardingStart('user123');

        // Log tutorial completion
        await expectLater(
          analyticsService.logTutorialComplete('user123'),
          completes,
        );
      });

      test('first battle entry after tutorial', () async {
        // Setup: tutorial complete
        await analyticsService.logTutorialComplete('user123');

        // Log entry to battle
        await expectLater(
          analyticsService.logFirstBattleEnter('user123'),
          completes,
        );
      });

      test('first kill = Aha Moment achievement + analytics', () async {
        const userId = 'user123';

        // Setup: in-battle
        await analyticsService.logFirstBattleEnter(userId);

        // Achievement: first kill unlocks the real Aha Moment achievement
        final unlocked = await triggerDetector.checkKillTriggers(userId, 1, 1);

        expect(unlocked.map((a) => a.achievementId), contains('aha_moment'));

        // Log Aha Moment (time to first kill in seconds)
        await expectLater(
          analyticsService.logTimeToAhaMoment(userId, 45),
          completes,
        );

        // Log battle win
        await expectLater(
          analyticsService.logFirstBattleWin(userId),
          completes,
        );
      });

      test(
        'full funnel: onboarding start → aha moment → analytics logging',
        () async {
          const userId = 'user123';

          // 1. Onboarding
          await analyticsService.logOnboardingStart(userId);

          // 2. Tutorial
          await analyticsService.logTutorialComplete(userId);

          // 3. First Battle
          await analyticsService.logFirstBattleEnter(userId);

          // 4. Aha Moment (First Kill)
          final unlocked = await triggerDetector.checkKillTriggers(
            userId,
            1,
            1,
          );
          expect(unlocked.map((a) => a.achievementId), contains('aha_moment'));

          // Log time to Aha Moment
          await analyticsService.logTimeToAhaMoment(userId, 30);

          // 5. Battle Win unlocks Rising Star (within the first 5 seasons at
          // Silver tier or better - the fixed condition).
          final battleWinUnlocked = await triggerDetector
              .checkBattleCompletionTriggers(
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
              );
          await analyticsService.logFirstBattleWin(userId);

          // Verify achievements accumulated
          final allUnlockedIds = <String>{
            ...unlocked.map((a) => a.achievementId),
            ...battleWinUnlocked.map((a) => a.achievementId),
          };
          expect(allUnlockedIds, containsAll(['aha_moment', 'rising_star']));

          final persisted = await achievementService.getUnlockedAchievements(
            userId,
          );
          expect(
            persisted.map((a) => a.achievementId),
            containsAll(['aha_moment', 'rising_star']),
          );
        },
      );
    });

    group('Analytics Funnel Event Sequencing', () {
      test('onboarding events can be logged in order', () async {
        const userId = 'user_sequence';

        await expectLater(
          analyticsService.logOnboardingStart(userId),
          completes,
        );
        await expectLater(
          analyticsService.logTutorialComplete(userId),
          completes,
        );
        await expectLater(
          analyticsService.logFirstBattleEnter(userId),
          completes,
        );
        await expectLater(
          analyticsService.logFirstBattleWin(userId),
          completes,
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
          await expectLater(
            analyticsService.logTimeToAhaMoment('user123', time),
            completes,
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

        // Progression 2: First Battle
        await analyticsService.logFirstBattleEnter(userId);

        // Progression 3: Aha Moment
        final killUnlocks = await triggerDetector.checkKillTriggers(
          userId,
          1,
          1,
        );
        unlockedAchievements.addAll(killUnlocks.map((a) => a.achievementId));

        await analyticsService.logTimeToAhaMoment(userId, 45);
        await analyticsService.logFirstBattleWin(userId);

        // Verify consistency
        expect(unlockedAchievements, contains('aha_moment'));
        final persisted = await achievementService.getUnlockedAchievements(
          userId,
        );
        expect(
          persisted.map((a) => a.achievementId),
          containsAll(unlockedAchievements),
        );
      });

      test('achievements persist across analytics calls', () async {
        const userId = 'persist_user';

        // Unlock achievement
        await triggerDetector.checkKillTriggers(userId, 1, 1);

        // Make multiple analytics calls
        await analyticsService.logOnboardingStart(userId);
        await analyticsService.logTutorialComplete(userId);
        await analyticsService.logFirstBattleEnter(userId);

        // Achievement should still be present
        final persisted = await achievementService.getUnlockedAchievements(
          userId,
        );
        expect(persisted.map((a) => a.achievementId), contains('aha_moment'));
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
        await triggerDetector.checkKillTriggers(userId, 1, 1);
        await analyticsService.logTimeToAhaMoment(userId, 30);

        // Log Day 1 active
        await expectLater(analyticsService.logDay1Active(userId), completes);
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
        await expectLater(
          analyticsService.setCohortProperties(
            userId,
            installCohort: '2026-09-02',
            platformCohort: 'android',
            purchaseCohort: 'F2P',
          ),
          completes,
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
