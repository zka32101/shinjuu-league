import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shinjuu_league/services/firestore_service.dart';
import 'package:shinjuu_league/services/item_service.dart';

/// ItemService.purchaseItem() no longer writes the item directly - it
/// submits an item_purchases request and waits for the (mocked here)
/// item-purchase-validator Cloud Function to mark it processed. These
/// tests simulate that server-side processing manually, the same way a
/// real Cloud Function would react to the client's write.
Future<void> _simulateServerProcessing(
  FakeFirebaseFirestore firestore, {
  required bool success,
  String? reason,
}) async {
  for (var attempt = 0; attempt < 50; attempt++) {
    final snapshot = await firestore.collection('item_purchases').get();
    if (snapshot.docs.isNotEmpty) {
      await snapshot.docs.first.reference.update({
        'processed': true,
        'success': success,
        if (reason != null) 'reason': reason,
      });
      return;
    }
    await Future.delayed(const Duration(milliseconds: 10));
  }
  fail('item_purchases document was never created');
}

void main() {
  group('ItemService.purchaseItem', () {
    test(
      'returns invalidItem immediately without writing to Firestore',
      () async {
        final firestore = FakeFirebaseFirestore();
        final service = ItemService.forFirestore(
          FirestoreService.forFirestore(firestore),
        );

        final result = await service.purchaseItem('u1', 'not_a_real_item');

        expect(result, ItemPurchaseResult.invalidItem);
        final purchases = await firestore.collection('item_purchases').get();
        expect(purchases.docs, isEmpty);
      },
    );

    test(
      'submits a request with only catalogItemId (no client-supplied price) and resolves success',
      () async {
        final firestore = FakeFirebaseFirestore();
        final service = ItemService.forFirestore(
          FirestoreService.forFirestore(firestore),
        );

        final resultFuture = service.purchaseItem('u1', 'weapon_iron_sword');
        await _simulateServerProcessing(firestore, success: true);
        final result = await resultFuture;

        expect(result, ItemPurchaseResult.success);

        final purchases = await firestore.collection('item_purchases').get();
        expect(purchases.docs, hasLength(1));
        final data = purchases.docs.first.data();
        expect(data['userId'], 'u1');
        expect(data['catalogItemId'], 'weapon_iron_sword');
        expect(data.containsKey('purchasePrice'), isFalse);
        expect(data.containsKey('goldCost'), isFalse);
      },
    );

    test(
      'returns insufficientGold when the server rejects for that reason',
      () async {
        final firestore = FakeFirebaseFirestore();
        final service = ItemService.forFirestore(
          FirestoreService.forFirestore(firestore),
        );

        final resultFuture = service.purchaseItem('u1', 'weapon_dragon_slayer');
        await _simulateServerProcessing(
          firestore,
          success: false,
          reason: 'insufficient_gold',
        );
        final result = await resultFuture;

        expect(result, ItemPurchaseResult.insufficientGold);
      },
    );

    test('returns error for any other server rejection reason', () async {
      final firestore = FakeFirebaseFirestore();
      final service = ItemService.forFirestore(
        FirestoreService.forFirestore(firestore),
      );

      final resultFuture = service.purchaseItem('u1', 'weapon_iron_sword');
      await _simulateServerProcessing(
        firestore,
        success: false,
        reason: 'user_not_found',
      );
      final result = await resultFuture;

      expect(result, ItemPurchaseResult.error);
    });

    test(
      'returns timeout when the server never marks the request processed',
      () async {
        final firestore = FakeFirebaseFirestore();
        final service = ItemService.forFirestore(
          FirestoreService.forFirestore(firestore),
        );

        final result = await service.purchaseItem(
          'u1',
          'weapon_iron_sword',
          timeout: const Duration(milliseconds: 50),
        );

        expect(result, ItemPurchaseResult.timeout);
      },
    );
  });
}
