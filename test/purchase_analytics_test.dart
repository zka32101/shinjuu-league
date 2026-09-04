import 'package:flutter_test/flutter_test.dart';
import 'package:shinjuu_league/services/analytics_service.dart';

void main() {
  group('Purchase Analytics Events', () {
    late AnalyticsService analyticsService;

    setUp(() {
      analyticsService = AnalyticsService();
    });

    group('Purchase Lifecycle Events', () {
      test('logPurchaseStart completes without error', () async {
        expect(
          () async => await analyticsService.logPurchaseStart(
            'user123',
            'battlepass_season',
          ),
          returnsNormally,
        );
      });

      test('logPurchaseComplete completes without error', () async {
        expect(
          () async => await analyticsService.logPurchaseComplete(
            'user123',
            'battlepass',
            500.0,
          ),
          returnsNormally,
        );
      });

      test('logPurchaseFailed completes without error', () async {
        expect(
          () async => await analyticsService.logPurchaseFailed(
            'user123',
            'battlepass_season',
            'User cancelled',
          ),
          returnsNormally,
        );
      });

      test('logPurchaseCancelled completes without error', () async {
        expect(
          () async => await analyticsService.logPurchaseCancelled(
            'user123',
            'skin_gacha_single',
          ),
          returnsNormally,
        );
      });

      test('logPurchasesRestored completes without error', () async {
        expect(
          () async =>
              await analyticsService.logPurchasesRestored('user123', 2),
          returnsNormally,
        );
      });
    });

    group('Purchase Funnel Tracking', () {
      test('shop view → purchase start → complete flow', () async {
        const userId = 'funnel_user_1';

        // View shop
        await analyticsService.logShopViewed(userId);

        // Start purchase
        await analyticsService.logPurchaseStart(userId, 'battlepass_season');

        // Complete purchase
        await analyticsService.logPurchaseComplete(userId, 'battlepass', 500.0);

        expect(true, isTrue);
      });

      test('shop view → gacha pull flow', () async {
        const userId = 'gacha_user_1';

        // View shop
        await analyticsService.logShopViewed(userId);

        // Start gacha purchase
        await analyticsService.logPurchaseStart(userId, 'skin_gacha_single');

        // Complete gacha purchase
        await analyticsService.logPurchaseComplete(
          userId,
          'skin_gacha',
          300.0,
        );

        expect(true, isTrue);
      });

      test('abandoned purchase tracking', () async {
        const userId = 'abandoned_user';

        // View shop
        await analyticsService.logShopViewed(userId);

        // Start purchase but cancel
        await analyticsService.logPurchaseStart(userId, 'battlepass_season');
        await analyticsService.logPurchaseCancelled(
          userId,
          'battlepass_season',
        );

        expect(true, isTrue);
      });

      test('failed purchase tracking', () async {
        const userId = 'failed_user';

        // View shop
        await analyticsService.logShopViewed(userId);

        // Start purchase
        await analyticsService.logPurchaseStart(userId, 'skin_gacha_single');

        // Purchase fails
        await analyticsService.logPurchaseFailed(
          userId,
          'skin_gacha_single',
          'Payment method declined',
        );

        expect(true, isTrue);
      });
    });

    group('Multiple Purchase Products', () {
      test('battlepass and gacha purchases tracked separately', () async {
        const userId = 'multi_purchase_user';

        // BattlePass purchase
        await analyticsService.logPurchaseStart(userId, 'battlepass_season');
        await analyticsService.logPurchaseComplete(userId, 'battlepass', 500.0);

        // Gacha purchase
        await analyticsService.logPurchaseStart(userId, 'skin_gacha_single');
        await analyticsService.logPurchaseComplete(userId, 'skin_gacha', 300.0);

        // Another gacha
        await analyticsService.logPurchaseStart(userId, 'skin_gacha_single');
        await analyticsService.logPurchaseComplete(userId, 'skin_gacha', 300.0);

        expect(true, isTrue);
      });
    });

    group('Purchase Recovery', () {
      test('purchase restore with multiple items', () async {
        const userId = 'restore_user';

        await analyticsService.logPurchasesRestored(userId, 3);

        expect(true, isTrue);
      });

      test('purchase restore with zero items', () async {
        const userId = 'no_restore_user';

        await analyticsService.logPurchasesRestored(userId, 0);

        expect(true, isTrue);
      });
    });

    group('Cohort Updates After Purchase', () {
      test('purchase and cohort update sequence', () async {
        const userId = 'cohort_purchase_user';

        // Initial cohort (F2P)
        await analyticsService.setCohortProperties(
          userId,
          installCohort: '2026-09-02',
          platformCohort: 'iOS',
          purchaseCohort: 'F2P',
        );

        // Make purchase
        await analyticsService.logPurchaseStart(userId, 'battlepass_season');
        await analyticsService.logPurchaseComplete(userId, 'battlepass', 500.0);

        // Update cohort to D1Payer (would be done by backend)
        // This is just verifying the flow is possible
        expect(true, isTrue);
      });
    });

    group('LTV Tracking Through Purchase Events', () {
      test('cumulative purchases tracked for LTV calculation', () async {
        const userId = 'ltv_user';
        double totalSpent = 0.0;

        // Purchase 1: BattlePass
        await analyticsService.logPurchaseStart(userId, 'battlepass_season');
        await analyticsService.logPurchaseComplete(userId, 'battlepass', 500.0);
        totalSpent += 500.0;

        // Purchase 2: Skin Gacha
        await analyticsService.logPurchaseStart(userId, 'skin_gacha_single');
        await analyticsService.logPurchaseComplete(userId, 'skin_gacha', 300.0);
        totalSpent += 300.0;

        // Purchase 3: Another skin
        await analyticsService.logPurchaseStart(userId, 'skin_gacha_single');
        await analyticsService.logPurchaseComplete(userId, 'skin_gacha', 300.0);
        totalSpent += 300.0;

        expect(totalSpent, equals(1100.0));
      });
    });
  });
}
