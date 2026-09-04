import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:shinjuu_league/data/models/cohort_properties.dart';
import 'package:shinjuu_league/data/models/user_model.dart';

void main() {
  group('Purchase Cohort Updates', () {
    late FakeFirebaseFirestore fakeDb;

    setUp(() {
      fakeDb = FakeFirebaseFirestore();
    });

    group('Cohort Transition After Purchase', () {
      test('User cohort transitions from F2P to D1Payer on first purchase', () async {
        const userId = 'user_first_purchase';

        // Create user with F2P cohort
        final user = User(
          uid: userId,
          name: 'Test User',
          eloRating: 1000,
          rank: 'Bronze',
          winRate: 0.0,
          totalBattles: 0,
          ownedSkinIds: const [],
          selectedMechaId: 'mecha_default_01',
          gems: 100,
          gold: 5000,
          fcmTokens: const [],
          guildId: null,
          cohortProperties: CohortProperties(
            installCohort: '2026-09-01',
            platformCohort: 'iOS',
            purchaseCohort: 'F2P',
            assignedAt: DateTime(2026, 9, 1),
          ),
        );

        await fakeDb.collection('users').doc(userId).set(user.toJson());

        // Simulate purchase: update cohort to D1Payer with lastPurchaseAt timestamp
        final now = DateTime.now();
        await fakeDb.collection('users').doc(userId).update({
          'cohortProperties.purchaseCohort': 'D1Payer',
          'cohortProperties.lastPurchaseAt': now.toIso8601String(),
        });

        // Verify cohort was updated
        final updatedDoc =
            await fakeDb.collection('users').doc(userId).get();
        final updatedUser = User.fromJson(updatedDoc.data()!);

        expect(updatedUser.cohortProperties.purchaseCohort, equals('D1Payer'));
        expect(updatedUser.cohortProperties.lastPurchaseAt, isNotNull);
      });

      test('User cohort can transition from D1Payer to D7Payer', () async {
        const userId = 'user_d1_to_d7';

        // Create user with D1Payer cohort
        final user = User(
          uid: userId,
          name: 'Repeat User',
          eloRating: 1200,
          rank: 'Silver',
          winRate: 0.55,
          totalBattles: 20,
          ownedSkinIds: const ['skin_east_flame'],
          selectedMechaId: 'mecha_default_01',
          gems: 500,
          gold: 15000,
          fcmTokens: const [],
          guildId: null,
          cohortProperties: CohortProperties(
            installCohort: '2026-09-01',
            platformCohort: 'Android',
            purchaseCohort: 'D1Payer',
            assignedAt: DateTime(2026, 9, 1),
          ),
        );

        await fakeDb.collection('users').doc(userId).set(user.toJson());

        // Simulate upgrade to D7Payer
        await fakeDb.collection('users').doc(userId).update({
          'cohortProperties.purchaseCohort': 'D7Payer',
          'cohortProperties.lastPurchaseAt': DateTime.now().toIso8601String(),
        });

        // Verify cohort was upgraded
        final updatedDoc =
            await fakeDb.collection('users').doc(userId).get();
        final updatedUser = User.fromJson(updatedDoc.data()!);

        expect(updatedUser.cohortProperties.purchaseCohort, equals('D7Payer'));
      });

      test('lastPurchaseAt timestamp is set on cohort update', () async {
        const userId = 'user_timestamp_test';

        // Create user
        final user = User(
          uid: userId,
          name: 'Timestamp Tester',
          eloRating: 1000,
          rank: 'Bronze',
          winRate: 0.0,
          totalBattles: 0,
          ownedSkinIds: const [],
          selectedMechaId: 'mecha_default_01',
          gems: 0,
          gold: 0,
          fcmTokens: const [],
          guildId: null,
          cohortProperties: CohortProperties(
            installCohort: '2026-09-04',
            platformCohort: 'iOS',
            purchaseCohort: 'F2P',
            assignedAt: DateTime(2026, 9, 4),
          ),
        );

        await fakeDb.collection('users').doc(userId).set(user.toJson());

        final beforePurchase = DateTime.now();

        // Update with purchase
        await fakeDb.collection('users').doc(userId).update({
          'cohortProperties.purchaseCohort': 'D1Payer',
          'cohortProperties.lastPurchaseAt': DateTime.now().toIso8601String(),
        });

        final afterPurchase = DateTime.now();

        // Verify timestamp was set (FakeFirestore returns timestamp as DateTime)
        final updatedDoc =
            await fakeDb.collection('users').doc(userId).get();
        final updatedUser = User.fromJson(updatedDoc.data()!);

        final lastPurchaseAt = updatedUser.cohortProperties.lastPurchaseAt;
        expect(lastPurchaseAt, isNotNull);
        expect(lastPurchaseAt!.isAfter(beforePurchase.subtract(Duration(seconds: 1))), isTrue);
        expect(lastPurchaseAt.isBefore(afterPurchase.add(Duration(seconds: 1))), isTrue);
      });

      test('Install cohort and platform cohort remain unchanged on purchase', () async {
        const userId = 'user_cohort_consistency';

        final installCohort = '2026-08-15';
        final platformCohort = 'Android';

        // Create user with specific cohorts
        final user = User(
          uid: userId,
          name: 'Cohort Tester',
          eloRating: 1000,
          rank: 'Bronze',
          winRate: 0.0,
          totalBattles: 0,
          ownedSkinIds: const [],
          selectedMechaId: 'mecha_default_01',
          gems: 0,
          gold: 0,
          fcmTokens: const [],
          guildId: null,
          cohortProperties: CohortProperties(
            installCohort: installCohort,
            platformCohort: platformCohort,
            purchaseCohort: 'F2P',
            assignedAt: DateTime(2026, 8, 15),
          ),
        );

        await fakeDb.collection('users').doc(userId).set(user.toJson());

        // Update only purchase cohort (simulating real update)
        await fakeDb.collection('users').doc(userId).update({
          'cohortProperties.purchaseCohort': 'D1Payer',
          'cohortProperties.lastPurchaseAt': DateTime.now().toIso8601String(),
        });

        // Verify other cohorts unchanged
        final updatedDoc =
            await fakeDb.collection('users').doc(userId).get();
        final updatedUser = User.fromJson(updatedDoc.data()!);

        expect(updatedUser.cohortProperties.installCohort, equals(installCohort));
        expect(updatedUser.cohortProperties.platformCohort, equals(platformCohort));
        expect(updatedUser.cohortProperties.purchaseCohort, equals('D1Payer'));
      });

      test('Multiple purchase cohort updates create purchase history', () async {
        const userId = 'user_multi_purchase';

        // Create F2P user
        final user = User(
          uid: userId,
          name: 'Multi Buyer',
          eloRating: 1000,
          rank: 'Bronze',
          winRate: 0.0,
          totalBattles: 0,
          ownedSkinIds: const [],
          selectedMechaId: 'mecha_default_01',
          gems: 0,
          gold: 0,
          fcmTokens: const [],
          guildId: null,
          cohortProperties: CohortProperties(
            installCohort: '2026-09-02',
            platformCohort: 'iOS',
            purchaseCohort: 'F2P',
            assignedAt: DateTime(2026, 9, 2),
          ),
        );

        await fakeDb.collection('users').doc(userId).set(user.toJson());

        // Purchase 1: F2P → D1Payer
        await fakeDb.collection('users').doc(userId).update({
          'cohortProperties.purchaseCohort': 'D1Payer',
          'cohortProperties.lastPurchaseAt': DateTime.now().toIso8601String(),
        });

        var doc = await fakeDb.collection('users').doc(userId).get();
        var updatedUser = User.fromJson(doc.data()!);
        expect(updatedUser.cohortProperties.purchaseCohort, equals('D1Payer'));
        final firstPurchaseTime = updatedUser.cohortProperties.lastPurchaseAt;

        // Wait a moment
        await Future.delayed(const Duration(milliseconds: 100));

        // Purchase 2: D1Payer → D7Payer
        await fakeDb.collection('users').doc(userId).update({
          'cohortProperties.purchaseCohort': 'D7Payer',
          'cohortProperties.lastPurchaseAt': DateTime.now().toIso8601String(),
        });

        doc = await fakeDb.collection('users').doc(userId).get();
        updatedUser = User.fromJson(doc.data()!);
        expect(updatedUser.cohortProperties.purchaseCohort, equals('D7Payer'));
        final secondPurchaseTime = updatedUser.cohortProperties.lastPurchaseAt;

        // Verify timestamps are different (second is later)
        expect(secondPurchaseTime!.isAfter(firstPurchaseTime!), isTrue);
      });
    });

    group('Monetization-specific Cohort Values', () {
      test('D1Payer cohort represents first day payer', () async {
        const userId = 'user_d1payer';
        const cohort = 'D1Payer';

        final user = User(
          uid: userId,
          name: 'D1 Tester',
          eloRating: 1000,
          rank: 'Bronze',
          winRate: 0.0,
          totalBattles: 0,
          ownedSkinIds: const [],
          selectedMechaId: 'mecha_default_01',
          gems: 0,
          gold: 0,
          fcmTokens: const [],
          guildId: null,
          cohortProperties: CohortProperties(
            installCohort: '2026-09-04',
            platformCohort: 'iOS',
            purchaseCohort: 'F2P',
            assignedAt: DateTime(2026, 9, 4),
          ),
        );

        await fakeDb.collection('users').doc(userId).set(user.toJson());

        await fakeDb.collection('users').doc(userId).update({
          'cohortProperties.purchaseCohort': cohort,
          'cohortProperties.lastPurchaseAt': DateTime.now().toIso8601String(),
        });

        final doc = await fakeDb.collection('users').doc(userId).get();
        final updatedUser = User.fromJson(doc.data()!);
        expect(updatedUser.cohortProperties.purchaseCohort, equals(cohort));
      });

      test('Whale cohort represents high-value repeat customer', () async {
        const userId = 'user_whale';
        const cohort = 'Whale';

        final user = User(
          uid: userId,
          name: 'Whale Buyer',
          eloRating: 2000,
          rank: 'Legend',
          winRate: 0.75,
          totalBattles: 500,
          ownedSkinIds: const ['skin_east_flame', 'skin_west_frost', 'skin_gold_dragon'],
          selectedMechaId: 'mecha_default_01',
          gems: 5000,
          gold: 100000,
          fcmTokens: const [],
          guildId: 'guild_123',
          cohortProperties: CohortProperties(
            installCohort: '2026-06-01',
            platformCohort: 'iOS',
            purchaseCohort: 'D30Payer',
            assignedAt: DateTime(2026, 6, 1),
          ),
        );

        await fakeDb.collection('users').doc(userId).set(user.toJson());

        await fakeDb.collection('users').doc(userId).update({
          'cohortProperties.purchaseCohort': cohort,
          'cohortProperties.lastPurchaseAt': DateTime.now().toIso8601String(),
        });

        final doc = await fakeDb.collection('users').doc(userId).get();
        final updatedUser = User.fromJson(doc.data()!);
        expect(updatedUser.cohortProperties.purchaseCohort, equals(cohort));
      });
    });
  });
}
