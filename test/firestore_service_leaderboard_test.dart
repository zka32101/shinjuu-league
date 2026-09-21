import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shinjuu_league/services/firestore_service.dart';

void main() {
  group('FirestoreService.getTopRankedUsers', () {
    test(
      'reads the public leaderboard collection, not users directly',
      () async {
        // Regression guard: /users/{userId}'s Firestore rule only allows a
        // user to read their own document, so a cross-user orderBy query
        // against 'users' can never work in production - only against the
        // publicly-readable 'leaderboard' collection that elo-validator.ts
        // mirrors public-safe fields into.
        final firestore = FakeFirebaseFirestore();

        // A full user document that must NOT show up via this method - it
        // has no matching 'leaderboard' entry.
        await firestore.collection('users').doc('u_full_profile_only').set({
          'uid': 'u_full_profile_only',
          'name': 'Not On Leaderboard',
          'eloRating': 9999.0,
        });

        // Leaderboard entries only ever carry the public-safe subset.
        await firestore.collection('leaderboard').doc('u1').set({
          'uid': 'u1',
          'name': 'Top Player',
          'eloRating': 1800.0,
          'winRate': 0.75,
        });
        await firestore.collection('leaderboard').doc('u2').set({
          'uid': 'u2',
          'name': 'Second Player',
          'eloRating': 1600.0,
          'winRate': 0.5,
        });

        final service = FirestoreService.forFirestore(firestore);
        final ranked = await service.getTopRankedUsers();

        expect(ranked, hasLength(2));
        expect(
          ranked.map((u) => u.uid),
          isNot(contains('u_full_profile_only')),
        );
        expect(ranked[0].uid, 'u1');
        expect(ranked[0].eloRating, 1800.0);
        expect(ranked[1].uid, 'u2');

        // Fields the leaderboard entry never carries fall back to
        // User.fromJson()'s safe defaults instead of throwing.
        expect(ranked[0].gems, 0);
        expect(ranked[0].gold, 0);
        expect(ranked[0].fcmTokens, isEmpty);
      },
    );

    test('orders by eloRating descending and respects limit', () async {
      final firestore = FakeFirebaseFirestore();
      for (final entry in [
        ('u_low', 1000.0),
        ('u_mid', 1500.0),
        ('u_high', 2000.0),
      ]) {
        await firestore.collection('leaderboard').doc(entry.$1).set({
          'uid': entry.$1,
          'name': entry.$1,
          'eloRating': entry.$2,
          'winRate': 0.5,
        });
      }

      final service = FirestoreService.forFirestore(firestore);
      final top2 = await service.getTopRankedUsers(limit: 2);

      expect(top2.map((u) => u.uid), ['u_high', 'u_mid']);
    });
  });
}
