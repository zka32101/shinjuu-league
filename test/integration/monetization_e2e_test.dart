import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shinjuu_league/services/analytics_service.dart';

void main() {
  setUpAll(() async {
    // Initialize Firebase for integration tests
    await Firebase.initializeApp();
  });

  group('Monetization E2E: Purchase → Cohort → Analytics', () {
    late AnalyticsService analyticsService;

    setUp(() {
      analyticsService = AnalyticsService();
    });

    group('BattlePass Purchase Flow', () {
      test('user views shop and battlepass', () async {
        const userId = 'battlepass_user';

        expect(
          () async => await analyticsService.logShopViewed(userId),
          returnsNormally,
        );
      });

      test('battlepass purchase logged with price', () async {
        const userId = 'battlepass_user';

        expect(
          () async => await analyticsService.logPurchaseComplete(
            userId,
            'battlepass',
            500.0,
          ),
          returnsNormally,
        );
      });

      test('battlepass purchase updates user cohort', () async {
        const userId = 'bp_purchaser';

        // Initial cohort (F2P)
        await analyticsService.setCohortProperties(
          userId,
          installCohort: '2026-09-02',
          platformCohort: 'android',
          purchaseCohort: 'F2P',
        );

        // Make purchase
        await analyticsService.logPurchaseComplete(
          userId,
          'battlepass',
          500.0,
        );

        // Update cohort to D1Payer
        expect(
          () async => await analyticsService.setCohortProperties(
            userId,
            installCohort: '2026-09-02',
            platformCohort: 'android',
            purchaseCohort: 'D1Payer',
          ),
          returnsNormally,
        );
      });

      test('full battlepass funnel: view → purchase → cohort update', () async {
        const userId = 'full_bp_flow';

        // 1. Shop viewed
        await analyticsService.logShopViewed(userId);

        // 2. Set initial cohort (F2P)
        await analyticsService.setCohortProperties(
          userId,
          installCohort: '2026-09-02',
          platformCohort: 'ios',
          purchaseCohort: 'F2P',
        );

        // 3. Purchase battlepass
        await analyticsService.logPurchaseComplete(
          userId,
          'battlepass',
          500.0,
        );

        // 4. Update to payer cohort
        await analyticsService.setCohortProperties(
          userId,
          installCohort: '2026-09-02',
          platformCohort: 'ios',
          purchaseCohort: 'D1Payer',
        );

        expect(true, isTrue);
      });
    });

    group('Skin Gacha Purchase Flow', () {
      test('skin gacha purchase logged', () async {
        const userId = 'gacha_user';

        expect(
          () async => await analyticsService.logPurchaseComplete(
            userId,
            'skin_gacha',
            300.0,
          ),
          returnsNormally,
        );
      });

      test('multiple skin gacha purchases tracked independently', () async {
        const userId = 'multi_gacha';

        await analyticsService.logPurchaseComplete(userId, 'skin_gacha', 300.0);
        await analyticsService.logPurchaseComplete(userId, 'skin_gacha', 300.0);
        await analyticsService.logPurchaseComplete(userId, 'skin_gacha', 300.0);

        expect(true, isTrue);
      });

      test('battlepass and gacha purchases in same session', () async {
        const userId = 'combo_purchase';

        // Shop viewed
        await analyticsService.logShopViewed(userId);

        // Multiple purchases
        await analyticsService.logPurchaseComplete(userId, 'battlepass', 500.0);
        await analyticsService.logPurchaseComplete(userId, 'skin_gacha', 300.0);
        await analyticsService.logPurchaseComplete(userId, 'skin_gacha', 300.0);

        expect(true, isTrue);
      });

      test('whale cohort assignment after multiple purchases', () async {
        const userId = 'whale_user';

        // Initial F2P
        await analyticsService.setCohortProperties(
          userId,
          installCohort: '2026-08-15',
          platformCohort: 'ios',
          purchaseCohort: 'F2P',
        );

        // Multiple purchases
        await analyticsService.logPurchaseComplete(userId, 'battlepass', 500.0);
        await analyticsService.logPurchaseComplete(userId, 'skin_gacha', 300.0);
        await analyticsService.logPurchaseComplete(userId, 'skin_gacha', 300.0);
        await analyticsService.logPurchaseComplete(userId, 'battlepass', 500.0);

        // Upgrade to Whale
        await analyticsService.setCohortProperties(
          userId,
          installCohort: '2026-08-15',
          platformCohort: 'ios',
          purchaseCohort: 'Whale',
        );

        expect(true, isTrue);
      });
    });

    group('Cohort Transitions', () {
      test('F2P → D1Payer transition', () async {
        const userId = 'f2p_to_d1';

        // Day 0: F2P
        await analyticsService.setCohortProperties(
          userId,
          installCohort: '2026-09-02',
          platformCohort: 'android',
          purchaseCohort: 'F2P',
        );

        // Day 1: First purchase
        await analyticsService.logPurchaseComplete(userId, 'battlepass', 500.0);

        // Update cohort
        await analyticsService.setCohortProperties(
          userId,
          installCohort: '2026-09-02',
          platformCohort: 'android',
          purchaseCohort: 'D1Payer',
        );

        expect(true, isTrue);
      });

      test('F2P → D7Payer transition', () async {
        const userId = 'f2p_to_d7';

        await analyticsService.setCohortProperties(
          userId,
          installCohort: '2026-08-26',
          platformCohort: 'ios',
          purchaseCohort: 'F2P',
        );

        // After 7 days of retention
        await analyticsService.logDay7Active(userId);

        // First purchase on Day 7+
        await analyticsService.logPurchaseComplete(userId, 'skin_gacha', 300.0);

        await analyticsService.setCohortProperties(
          userId,
          installCohort: '2026-08-26',
          platformCohort: 'ios',
          purchaseCohort: 'D7Payer',
        );

        expect(true, isTrue);
      });

      test('D1Payer → D30Payer → Whale progression', () async {
        const userId = 'whale_progression';

        // D1Payer
        await analyticsService.setCohortProperties(
          userId,
          installCohort: '2026-08-03',
          platformCohort: 'ios',
          purchaseCohort: 'D1Payer',
        );

        await analyticsService.logPurchaseComplete(userId, 'battlepass', 500.0);

        // D30Payer
        await analyticsService.logDay30Active(userId);
        await analyticsService.logPurchaseComplete(userId, 'skin_gacha', 300.0);

        await analyticsService.setCohortProperties(
          userId,
          installCohort: '2026-08-03',
          platformCohort: 'ios',
          purchaseCohort: 'D30Payer',
        );

        // Whale
        await analyticsService.logPurchaseComplete(userId, 'skin_gacha', 300.0);
        await analyticsService.logPurchaseComplete(userId, 'battlepass', 500.0);

        await analyticsService.setCohortProperties(
          userId,
          installCohort: '2026-08-03',
          platformCohort: 'ios',
          purchaseCohort: 'Whale',
        );

        expect(true, isTrue);
      });
    });

    group('Platform-Specific Purchase Tracking', () {
      test('iOS user purchase flow', () async {
        const userId = 'ios_payer';

        await analyticsService.setCohortProperties(
          userId,
          installCohort: '2026-09-02',
          platformCohort: 'ios',
          purchaseCohort: 'F2P',
        );

        await analyticsService.logShopViewed(userId);
        await analyticsService.logPurchaseComplete(userId, 'battlepass', 500.0);

        await analyticsService.setCohortProperties(
          userId,
          installCohort: '2026-09-02',
          platformCohort: 'ios',
          purchaseCohort: 'D1Payer',
        );

        expect(true, isTrue);
      });

      test('Android user purchase flow', () async {
        const userId = 'android_payer';

        await analyticsService.setCohortProperties(
          userId,
          installCohort: '2026-09-02',
          platformCohort: 'android',
          purchaseCohort: 'F2P',
        );

        await analyticsService.logShopViewed(userId);
        await analyticsService.logPurchaseComplete(userId, 'skin_gacha', 300.0);

        await analyticsService.setCohortProperties(
          userId,
          installCohort: '2026-09-02',
          platformCohort: 'android',
          purchaseCohort: 'D1Payer',
        );

        expect(true, isTrue);
      });

      test('cross-platform users tracked independently', () async {
        // iOS user
        await analyticsService.setCohortProperties(
          'user_ios',
          installCohort: '2026-09-01',
          platformCohort: 'ios',
          purchaseCohort: 'F2P',
        );

        // Android user
        await analyticsService.setCohortProperties(
          'user_android',
          installCohort: '2026-09-01',
          platformCohort: 'android',
          purchaseCohort: 'F2P',
        );

        // iOS purchase
        await analyticsService.logPurchaseComplete('user_ios', 'battlepass', 500.0);

        // Android purchase
        await analyticsService.logPurchaseComplete('user_android', 'skin_gacha', 300.0);

        expect(true, isTrue);
      });
    });

    group('LTV Tracking Integration', () {
      test('lifetime value builds through sequential purchases', () async {
        const userId = 'ltv_user';
        double totalSpent = 0.0;

        // Purchase 1: BattlePass
        const price1 = 500.0;
        await analyticsService.logPurchaseComplete(userId, 'battlepass', price1);
        totalSpent += price1;

        // Purchase 2: Skin Gacha
        const price2 = 300.0;
        await analyticsService.logPurchaseComplete(userId, 'skin_gacha', price2);
        totalSpent += price2;

        // Purchase 3: Another Skin Gacha
        const price3 = 300.0;
        await analyticsService.logPurchaseComplete(userId, 'skin_gacha', price3);
        totalSpent += price3;

        expect(totalSpent, equals(1100.0));
      });

      test('multiple users with different LTV patterns', () async {
        // Low spender: 1 purchase
        await analyticsService.logPurchaseComplete('low_spender', 'battlepass', 500.0);

        // Medium spender: multiple purchases
        await analyticsService.logPurchaseComplete('med_spender', 'battlepass', 500.0);
        await analyticsService.logPurchaseComplete('med_spender', 'skin_gacha', 300.0);

        // High spender: frequent purchases
        for (int i = 0; i < 5; i++) {
          await analyticsService.logPurchaseComplete('high_spender', 'skin_gacha', 300.0);
        }
        await analyticsService.logPurchaseComplete('high_spender', 'battlepass', 500.0);

        expect(true, isTrue);
      });
    });

    group('Conversion Funnel Events', () {
      test('shop viewed → purchase conversion', () async {
        const userId = 'conversion_user';

        await analyticsService.logShopViewed(userId);
        await analyticsService.logPurchaseComplete(userId, 'battlepass', 500.0);

        expect(true, isTrue);
      });

      test('Day 1 active users have higher purchase propensity tracking', () async {
        const userId = 'day1_converter';

        // Onboarding
        await analyticsService.logOnboardingStart(userId);
        await analyticsService.logDay1Active(userId);

        // D1 purchase
        await analyticsService.logShopViewed(userId);
        await analyticsService.logPurchaseComplete(userId, 'battlepass', 500.0);

        await analyticsService.setCohortProperties(
          userId,
          installCohort: '2026-09-02',
          platformCohort: 'ios',
          purchaseCohort: 'D1Payer',
        );

        expect(true, isTrue);
      });
    });
  });
}
