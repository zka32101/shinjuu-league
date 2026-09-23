import 'package:flutter_test/flutter_test.dart';
import 'package:shinjuu_league/services/purchase_cohort_service.dart';

void main() {
  group('PurchaseCohortService.nextCohortAfterPurchase', () {
    final installDate = DateTime(2026, 1, 1);

    test('first purchase on install day -> D1Payer', () {
      final result = PurchaseCohortService.nextCohortAfterPurchase(
        currentCohort: PurchaseCohortService.f2p,
        installDate: installDate,
        now: DateTime(2026, 1, 1, 12),
      );
      expect(result, equals(PurchaseCohortService.d1Payer));
    });

    test('first purchase exactly 1 day after install -> D1Payer', () {
      final result = PurchaseCohortService.nextCohortAfterPurchase(
        currentCohort: PurchaseCohortService.f2p,
        installDate: installDate,
        now: DateTime(2026, 1, 2, 12),
      );
      expect(result, equals(PurchaseCohortService.d1Payer));
    });

    test('first purchase within a week -> D7Payer', () {
      final result = PurchaseCohortService.nextCohortAfterPurchase(
        currentCohort: PurchaseCohortService.f2p,
        installDate: installDate,
        now: DateTime(2026, 1, 5),
      );
      expect(result, equals(PurchaseCohortService.d7Payer));
    });

    test('first purchase beyond a week -> D30Payer', () {
      final result = PurchaseCohortService.nextCohortAfterPurchase(
        currentCohort: PurchaseCohortService.f2p,
        installDate: installDate,
        now: DateTime(2026, 1, 20),
      );
      expect(result, equals(PurchaseCohortService.d30Payer));
    });

    test('a second purchase from D1Payer escalates to Whale', () {
      final result = PurchaseCohortService.nextCohortAfterPurchase(
        currentCohort: PurchaseCohortService.d1Payer,
        installDate: installDate,
        now: DateTime(2026, 1, 3),
      );
      expect(result, equals(PurchaseCohortService.whale));
    });

    test('a purchase from an already-Whale user stays Whale', () {
      final result = PurchaseCohortService.nextCohortAfterPurchase(
        currentCohort: PurchaseCohortService.whale,
        installDate: installDate,
        now: DateTime(2026, 6, 1),
      );
      expect(result, equals(PurchaseCohortService.whale));
    });
  });
}
