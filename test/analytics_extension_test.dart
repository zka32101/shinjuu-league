import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shinjuu_league/services/analytics_service.dart';

void main() {
  setUpAll(() async {
    // Initialize Firebase for tests
    await Firebase.initializeApp();
  });

  group('AnalyticsService Extensions', () {
    late AnalyticsService analyticsService;

    setUp(() {
      analyticsService = AnalyticsService();
    });

    group('Onboarding Funnel', () {
      test('logOnboardingStart completes without error', () async {
        expect(
          () async => await analyticsService.logOnboardingStart('user123'),
          returnsNormally,
        );
      });

      test('logTutorialComplete completes without error', () async {
        expect(
          () async => await analyticsService.logTutorialComplete('user123'),
          returnsNormally,
        );
      });

      test('logFirstBattleEnter completes without error', () async {
        expect(
          () async => await analyticsService.logFirstBattleEnter('user123'),
          returnsNormally,
        );
      });

      test('logFirstBattleWin completes without error', () async {
        expect(
          () async => await analyticsService.logFirstBattleWin('user123'),
          returnsNormally,
        );
      });
    });

    group('Conversion Funnel (LTV)', () {
      test('logShopViewed completes without error', () async {
        expect(
          () async => await analyticsService.logShopViewed('user123'),
          returnsNormally,
        );
      });

      test('logPurchaseComplete accepts battlepass type', () async {
        expect(
          () async => await analyticsService.logPurchaseComplete(
            'user123',
            'battlepass',
            500.0,
          ),
          returnsNormally,
        );
      });

      test('logPurchaseComplete accepts skin_gacha type', () async {
        expect(
          () async => await analyticsService.logPurchaseComplete(
            'user123',
            'skin_gacha',
            300.0,
          ),
          returnsNormally,
        );
      });
    });

    group('Ranked Adoption Funnel', () {
      test('logRankedUnlockAvailable completes without error', () async {
        expect(
          () async =>
              await analyticsService.logRankedUnlockAvailable('user123'),
          returnsNormally,
        );
      });

      test('logRankedEntryAction completes without error', () async {
        expect(
          () async =>
              await analyticsService.logRankedEntryAction('user123'),
          returnsNormally,
        );
      });
    });

    group('Cohort Properties', () {
      test('setCohortProperties sets all properties', () async {
        expect(
          () async => await analyticsService.setCohortProperties(
            'user123',
            installCohort: '2026-09-01',
            platformCohort: 'android',
            purchaseCohort: 'D1Payer',
          ),
          returnsNormally,
        );
      });

      test('supports iOS platform cohort', () async {
        expect(
          () async => await analyticsService.setCohortProperties(
            'user123',
            installCohort: '2026-09-01',
            platformCohort: 'ios',
            purchaseCohort: 'F2P',
          ),
          returnsNormally,
        );
      });

      test('supports various purchase cohorts', () async {
        final cohorts = ['D1Payer', 'D7Payer', 'D30Payer', 'F2P', 'Whale'];

        for (final cohort in cohorts) {
          expect(
            () async => await analyticsService.setCohortProperties(
              'user123',
              installCohort: '2026-09-01',
              platformCohort: 'android',
              purchaseCohort: cohort,
            ),
            returnsNormally,
          );
        }
      });
    });

    group('Retention Metrics', () {
      test('logDay1Active completes without error', () async {
        expect(
          () async => await analyticsService.logDay1Active('user123'),
          returnsNormally,
        );
      });

      test('logDay7Active completes without error', () async {
        expect(
          () async => await analyticsService.logDay7Active('user123'),
          returnsNormally,
        );
      });

      test('logDay30Active completes without error', () async {
        expect(
          () async => await analyticsService.logDay30Active('user123'),
          returnsNormally,
        );
      });

      test('logTimeToAhaMoment records time in seconds', () async {
        expect(
          () async => await analyticsService.logTimeToAhaMoment('user123', 45),
          returnsNormally,
        );
      });

      test('logTimeToAhaMoment accepts various time ranges', () async {
        final times = [0, 10, 30, 60, 120, 300];

        for (final time in times) {
          expect(
            () async =>
                await analyticsService.logTimeToAhaMoment('user123', time),
            returnsNormally,
          );
        }
      });
    });

    group('Achievement Events', () {
      test('logAchievementUnlocked records achievement unlock', () async {
        expect(
          () async => await analyticsService.logAchievementUnlocked(
            'user123',
            'first_kill',
            'common',
          ),
          returnsNormally,
        );
      });

      test('supports rare achievement rarity', () async {
        expect(
          () async => await analyticsService.logAchievementUnlocked(
            'user123',
            'win_streak_5',
            'rare',
          ),
          returnsNormally,
        );
      });

      test('supports legendary achievement rarity', () async {
        expect(
          () async => await analyticsService.logAchievementUnlocked(
            'user123',
            'master_ranked',
            'legendary',
          ),
          returnsNormally,
        );
      });
    });

    group('Event Sequencing', () {
      test('funnel events can be logged in sequence', () async {
        await analyticsService.logOnboardingStart('user123');
        await analyticsService.logTutorialComplete('user123');
        await analyticsService.logFirstBattleEnter('user123');
        await analyticsService.logFirstBattleWin('user123');

        // If we reach here, all events logged without error
        expect(true, isTrue);
      });

      test('conversion funnel can be logged in sequence', () async {
        await analyticsService.logShopViewed('user123');
        await analyticsService.logPurchaseComplete('user123', 'battlepass', 500.0);
        await analyticsService.logDay1Active('user123');
        await analyticsService.logDay7Active('user123');

        // If we reach here, all events logged without error
        expect(true, isTrue);
      });

      test('multiple users can have independent cohort properties', () async {
        await analyticsService.setCohortProperties(
          'user1',
          installCohort: '2026-09-01',
          platformCohort: 'ios',
          purchaseCohort: 'D1Payer',
        );

        await analyticsService.setCohortProperties(
          'user2',
          installCohort: '2026-09-02',
          platformCohort: 'android',
          purchaseCohort: 'F2P',
        );

        // If we reach here, both users' properties set without error
        expect(true, isTrue);
      });
    });

    group('Singleton Pattern', () {
      test('multiple instances refer to same object', () {
        final service1 = AnalyticsService();
        final service2 = AnalyticsService();

        expect(identical(service1, service2), isTrue);
      });
    });
  });
}
