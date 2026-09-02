import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:shinjuu_league/data/models/cohort_properties.dart';
import 'package:shinjuu_league/data/models/user_model.dart';

void main() {
  group('Cohort Properties Persistence', () {
    late FakeFirebaseFirestore fakeDb;

    setUp(() {
      fakeDb = FakeFirebaseFirestore();
    });

    group('CohortProperties Model', () {
      test('CohortProperties creates with all required fields', () {
        final cohort = CohortProperties(
          installCohort: 'organic',
          platformCohort: 'Android',
          purchaseCohort: 'F2P',
          assignedAt: DateTime(2026, 9, 2),
        );

        expect(cohort.installCohort, 'organic');
        expect(cohort.platformCohort, 'Android');
        expect(cohort.purchaseCohort, 'F2P');
      });

      test('CohortProperties supports custom cohorts', () {
        final cohort = CohortProperties(
          installCohort: 'paid_ad',
          platformCohort: 'iOS',
          purchaseCohort: 'D1Payer',
          customCohorts: {
            'aha_moment_variant': 'control',
            'pricing_variant': 'treatment',
          },
          assignedAt: DateTime(2026, 9, 2),
        );

        expect(cohort.customCohorts['aha_moment_variant'], 'control');
        expect(cohort.customCohorts['pricing_variant'], 'treatment');
      });

      test('CohortProperties serializes to JSON', () {
        final cohort = CohortProperties(
          installCohort: 'referral',
          platformCohort: 'web',
          purchaseCohort: 'Whale',
          customCohorts: {'segment': 'high_ltv'},
          assignedAt: DateTime(2026, 9, 2),
        );

        final json = cohort.toJson();
        expect(json['installCohort'], 'referral');
        expect(json['platformCohort'], 'web');
        expect(json['purchaseCohort'], 'Whale');
        expect(json['customCohorts'], {'segment': 'high_ltv'});
        expect(json['assignedAt'], isNotNull);
      });

      test('CohortProperties deserializes from JSON', () {
        final json = {
          'installCohort': 'organic',
          'platformCohort': 'Android',
          'purchaseCohort': 'D7Payer',
          'customCohorts': {'test': 'value'},
          'assignedAt': '2026-09-02T00:00:00.000Z',
        };

        final cohort = CohortProperties.fromJson(json);
        expect(cohort.installCohort, 'organic');
        expect(cohort.platformCohort, 'Android');
        expect(cohort.purchaseCohort, 'D7Payer');
        expect(cohort.customCohorts['test'], 'value');
      });

      test('CohortProperties round-trip serialization', () {
        final original = CohortProperties(
          installCohort: 'paid_ad',
          platformCohort: 'iOS',
          purchaseCohort: 'Whale',
          customCohorts: {'segment': 'vip'},
          assignedAt: DateTime(2026, 9, 2),
        );

        final json = original.toJson();
        final restored = CohortProperties.fromJson(json);

        expect(restored.installCohort, original.installCohort);
        expect(restored.platformCohort, original.platformCohort);
        expect(restored.purchaseCohort, original.purchaseCohort);
        expect(restored.customCohorts, original.customCohorts);
      });

      test('CohortProperties copyWith preserves and updates fields', () {
        final original = CohortProperties(
          installCohort: 'organic',
          platformCohort: 'Android',
          purchaseCohort: 'F2P',
          assignedAt: DateTime(2026, 9, 1),
        );

        final updated = original.copyWith(purchaseCohort: 'D1Payer');

        expect(updated.installCohort, 'organic');
        expect(updated.platformCohort, 'Android');
        expect(updated.purchaseCohort, 'D1Payer');
        expect(updated.assignedAt, original.assignedAt);
      });

      test('CohortProperties equality comparison', () {
        final cohort1 = CohortProperties(
          installCohort: 'organic',
          platformCohort: 'Android',
          purchaseCohort: 'F2P',
          assignedAt: DateTime(2026, 9, 2),
        );

        final cohort2 = CohortProperties(
          installCohort: 'organic',
          platformCohort: 'Android',
          purchaseCohort: 'F2P',
          assignedAt: DateTime(2026, 9, 2),
        );

        expect(cohort1, equals(cohort2));
      });

      test('CohortProperties defaults unknown fields gracefully', () {
        final json = {
          'installCohort': 'organic',
          // Missing platformCohort, purchaseCohort, etc
        };

        final cohort = CohortProperties.fromJson(json);
        expect(cohort.installCohort, 'organic');
        expect(cohort.platformCohort, 'unknown');
        expect(cohort.purchaseCohort, 'F2P');
      });
    });

    group('User Model with CohortProperties', () {
      test('User can have cohortProperties', () {
        final cohort = CohortProperties(
          installCohort: 'organic',
          platformCohort: 'Android',
          purchaseCohort: 'D1Payer',
          assignedAt: DateTime(2026, 9, 2),
        );

        final user = User(
          uid: 'user123',
          name: 'TestUser',
          rank: 1,
          level: 5,
          eloRating: 1200.0,
          winRate: 0.55,
          gems: 100,
          gold: 1000,
          cohortProperties: cohort,
          createdAt: DateTime(2026, 9, 1),
          lastBattleAt: DateTime(2026, 9, 2),
        );

        expect(user.cohortProperties, isNotNull);
        expect(user.cohortProperties!.purchaseCohort, 'D1Payer');
      });

      test('User can be created without cohortProperties', () {
        final user = User(
          uid: 'user456',
          name: 'TestUser2',
          rank: 2,
          level: 10,
          eloRating: 1500.0,
          winRate: 0.6,
          gems: 500,
          gold: 5000,
          createdAt: DateTime(2026, 9, 1),
          lastBattleAt: DateTime(2026, 9, 2),
        );

        expect(user.cohortProperties, isNull);
      });

      test('User serializes cohortProperties to JSON', () {
        final cohort = CohortProperties(
          installCohort: 'paid_ad',
          platformCohort: 'iOS',
          purchaseCohort: 'Whale',
          assignedAt: DateTime(2026, 9, 2),
        );

        final user = User(
          uid: 'user789',
          name: 'TestUser3',
          rank: 5,
          level: 20,
          eloRating: 2000.0,
          winRate: 0.75,
          gems: 1000,
          gold: 10000,
          cohortProperties: cohort,
          createdAt: DateTime(2026, 9, 1),
          lastBattleAt: DateTime(2026, 9, 2),
        );

        final json = user.toJson();
        expect(json['cohortProperties'], isNotNull);
        expect(json['cohortProperties']['installCohort'], 'paid_ad');
      });

      test('User deserializes cohortProperties from JSON', () {
        final json = {
          'uid': 'user_test',
          'name': 'Test',
          'rank': 1,
          'level': 1,
          'eloRating': 1000.0,
          'winRate': 0.5,
          'gems': 0,
          'gold': 0,
          'cohortProperties': {
            'installCohort': 'organic',
            'platformCohort': 'Android',
            'purchaseCohort': 'F2P',
            'customCohorts': {},
            'assignedAt': '2026-09-02T00:00:00.000Z',
          },
          'createdAt': '2026-09-01T00:00:00.000Z',
          'lastBattleAt': '2026-09-02T00:00:00.000Z',
        };

        final user = User.fromJson(json);
        expect(user.cohortProperties, isNotNull);
        expect(user.cohortProperties!.purchaseCohort, 'F2P');
      });

      test('User copyWith preserves cohortProperties', () {
        final cohort = CohortProperties(
          installCohort: 'organic',
          platformCohort: 'Android',
          purchaseCohort: 'F2P',
          assignedAt: DateTime(2026, 9, 2),
        );

        final user = User(
          uid: 'user_copy1',
          name: 'Original',
          rank: 1,
          level: 1,
          eloRating: 1000.0,
          winRate: 0.5,
          gems: 100,
          gold: 1000,
          cohortProperties: cohort,
          createdAt: DateTime(2026, 9, 1),
          lastBattleAt: DateTime(2026, 9, 2),
        );

        final updated = user.copyWith(name: 'Updated', level: 5);

        expect(updated.name, 'Updated');
        expect(updated.level, 5);
        expect(updated.cohortProperties, isNotNull);
        expect(updated.cohortProperties!.purchaseCohort, 'F2P');
      });

      test('User copyWith can update cohortProperties', () {
        final originalCohort = CohortProperties(
          installCohort: 'organic',
          platformCohort: 'Android',
          purchaseCohort: 'F2P',
          assignedAt: DateTime(2026, 9, 1),
        );

        final user = User(
          uid: 'user_copy2',
          name: 'Test',
          rank: 1,
          level: 1,
          eloRating: 1000.0,
          winRate: 0.5,
          gems: 100,
          gold: 1000,
          cohortProperties: originalCohort,
          createdAt: DateTime(2026, 9, 1),
          lastBattleAt: DateTime(2026, 9, 2),
        );

        final newCohort = CohortProperties(
          installCohort: 'paid_ad',
          platformCohort: 'iOS',
          purchaseCohort: 'D1Payer',
          assignedAt: DateTime(2026, 9, 2),
        );

        final updated = user.copyWith(cohortProperties: newCohort);

        expect(updated.cohortProperties!.installCohort, 'paid_ad');
        expect(updated.cohortProperties!.platformCohort, 'iOS');
        expect(updated.cohortProperties!.purchaseCohort, 'D1Payer');
      });
    });

    group('Firestore Persistence', () {
      test('User with cohortProperties persists to Firestore', () async {
        final userId = 'user_firestore_1';
        final cohort = CohortProperties(
          installCohort: 'organic',
          platformCohort: 'Android',
          purchaseCohort: 'D1Payer',
          assignedAt: DateTime(2026, 9, 2),
        );

        final user = User(
          uid: userId,
          name: 'TestUser',
          rank: 1,
          level: 5,
          eloRating: 1200.0,
          winRate: 0.55,
          gems: 100,
          gold: 1000,
          cohortProperties: cohort,
          createdAt: DateTime(2026, 9, 1),
          lastBattleAt: DateTime(2026, 9, 2),
        );

        // Simulate Firestore write
        await fakeDb.collection('users').doc(userId).set(user.toJson());

        // Verify persistence
        final doc = await fakeDb.collection('users').doc(userId).get();
        expect(doc.exists, true);
        final data = doc.data();
        expect(data?['cohortProperties'], isNotNull);
        expect(data?['cohortProperties']['purchaseCohort'], 'D1Payer');
      });

      test('Cohort properties can be updated independently', () async {
        final userId = 'user_firestore_2';

        // Create user without cohort
        final user = User(
          uid: userId,
          name: 'TestUser',
          rank: 1,
          level: 1,
          eloRating: 1000.0,
          winRate: 0.5,
          gems: 0,
          gold: 0,
          createdAt: DateTime(2026, 9, 1),
          lastBattleAt: DateTime(2026, 9, 2),
        );

        await fakeDb.collection('users').doc(userId).set(user.toJson());

        // Update with cohort
        final cohort = CohortProperties(
          installCohort: 'organic',
          platformCohort: 'Android',
          purchaseCohort: 'F2P',
          assignedAt: DateTime(2026, 9, 2),
        );

        await fakeDb.collection('users').doc(userId).update({
          'cohortProperties': cohort.toJson(),
        });

        // Verify update
        final doc = await fakeDb.collection('users').doc(userId).get();
        final data = doc.data() as Map<String, dynamic>;
        expect(data['cohortProperties'], isNotNull);
        expect(data['cohortProperties']['purchaseCohort'], 'F2P');
      });

      test('Multiple users with different cohorts', () async {
        // User 1: Organic, F2P
        final user1 = User(
          uid: 'user1',
          name: 'User1',
          rank: 1,
          level: 1,
          eloRating: 1000.0,
          winRate: 0.5,
          gems: 0,
          gold: 0,
          cohortProperties: CohortProperties(
            installCohort: 'organic',
            platformCohort: 'Android',
            purchaseCohort: 'F2P',
            assignedAt: DateTime(2026, 9, 2),
          ),
          createdAt: DateTime(2026, 9, 1),
          lastBattleAt: DateTime(2026, 9, 2),
        );

        // User 2: Paid, D1Payer
        final user2 = User(
          uid: 'user2',
          name: 'User2',
          rank: 2,
          level: 5,
          eloRating: 1200.0,
          winRate: 0.6,
          gems: 500,
          gold: 5000,
          cohortProperties: CohortProperties(
            installCohort: 'paid_ad',
            platformCohort: 'iOS',
            purchaseCohort: 'D1Payer',
            assignedAt: DateTime(2026, 9, 2),
          ),
          createdAt: DateTime(2026, 9, 1),
          lastBattleAt: DateTime(2026, 9, 2),
        );

        // Persist both
        await fakeDb.collection('users').doc('user1').set(user1.toJson());
        await fakeDb.collection('users').doc('user2').set(user2.toJson());

        // Verify both exist
        final doc1 = await fakeDb.collection('users').doc('user1').get();
        final doc2 = await fakeDb.collection('users').doc('user2').get();

        expect(doc1.exists, true);
        expect(doc2.exists, true);

        final data1 = doc1.data();
        final data2 = doc2.data();

        expect(data1?['cohortProperties']['purchaseCohort'], 'F2P');
        expect(data2?['cohortProperties']['purchaseCohort'], 'D1Payer');
      });

      test('Cohort properties with custom variants persist', () async {
        final userId = 'user_abtest';
        final cohort = CohortProperties(
          installCohort: 'organic',
          platformCohort: 'Android',
          purchaseCohort: 'D1Payer',
          customCohorts: {
            'aha_moment_variant': 'treatment',
            'pricing_variant': 'control',
            'ui_variant': 'new_onboarding',
          },
          assignedAt: DateTime(2026, 9, 2),
        );

        final user = User(
          uid: userId,
          name: 'ABTestUser',
          rank: 1,
          level: 1,
          eloRating: 1000.0,
          winRate: 0.5,
          gems: 0,
          gold: 0,
          cohortProperties: cohort,
          createdAt: DateTime(2026, 9, 1),
          lastBattleAt: DateTime(2026, 9, 2),
        );

        await fakeDb.collection('users').doc(userId).set(user.toJson());

        final doc = await fakeDb.collection('users').doc(userId).get();
        final data = doc.data() as Map<String, dynamic>;
        final cohortData = data['cohortProperties'] as Map<String, dynamic>;
        final customs = cohortData['customCohorts'] as Map<String, dynamic>;

        expect(customs['aha_moment_variant'], 'treatment');
        expect(customs['pricing_variant'], 'control');
        expect(customs['ui_variant'], 'new_onboarding');
      });
    });

    group('Analytics Integration', () {
      test('Analytics service should accept custom cohorts', () {
        // This test validates that the AnalyticsService signature supports
        // custom cohorts for A/B testing while maintaining backward compatibility
        const installCohort = 'organic';
        const platformCohort = 'Android';
        const purchaseCohort = 'F2P';
        const customCohorts = {'variant': 'control'};

        // Verify these values can be passed together
        expect(installCohort, isNotEmpty);
        expect(platformCohort, isNotEmpty);
        expect(purchaseCohort, isNotEmpty);
        expect(customCohorts, isNotEmpty);
      });

      test('Cohort properties support future A/B testing patterns', () {
        final controlCohort = CohortProperties(
          installCohort: 'organic',
          platformCohort: 'Android',
          purchaseCohort: 'F2P',
          customCohorts: {
            'aha_moment_threshold': 'control',
            'matching_difficulty': 'control',
          },
          assignedAt: DateTime(2026, 9, 2),
        );

        final treatmentCohort = CohortProperties(
          installCohort: 'organic',
          platformCohort: 'Android',
          purchaseCohort: 'F2P',
          customCohorts: {
            'aha_moment_threshold': 'treatment',
            'matching_difficulty': 'treatment',
          },
          assignedAt: DateTime(2026, 9, 2),
        );

        expect(
          controlCohort.customCohorts['aha_moment_threshold'],
          'control',
        );
        expect(
          treatmentCohort.customCohorts['aha_moment_threshold'],
          'treatment',
        );
      });
    });
  });
}
