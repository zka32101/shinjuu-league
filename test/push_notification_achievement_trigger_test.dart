import 'dart:io';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shinjuu_league/services/firestore_service.dart';

void main() {
  group(
    'FirestoreService.markAchievementUnlocked (push notification trigger input)',
    () {
      // functions/src/push-notifications.ts's notifyAchievementUnlocked Cloud
      // Function reads the 'name' field off this document to build the push
      // notification's body text (falling back to the raw achievementId when
      // it's missing). These tests guard the client side of that contract:
      // the field must actually be written when a display name is supplied.
      test('writes the achievement display name alongside the ID', () async {
        final firestore = FakeFirebaseFirestore();
        final service = FirestoreService.forFirestore(firestore);

        await service.markAchievementUnlocked(
          'user1',
          'first_blood',
          achievementName: 'ファーストブラッド',
        );

        final doc = await firestore
            .collection('users')
            .doc('user1')
            .collection('achievements')
            .doc('first_blood')
            .get();

        expect(doc.data()!['achievementId'], 'first_blood');
        expect(doc.data()!['name'], 'ファーストブラッド');
        expect(doc.data()!['isHidden'], isFalse);
      });

      test('omits the name field entirely when none is supplied', () async {
        final firestore = FakeFirebaseFirestore();
        final service = FirestoreService.forFirestore(firestore);

        await service.markAchievementUnlocked('user1', 'first_blood');

        final doc = await firestore
            .collection('users')
            .doc('user1')
            .collection('achievements')
            .doc('first_blood')
            .get();

        expect(doc.data()!.containsKey('name'), isFalse);
      });
    },
  );

  group('firestore.rules dead-code cleanup (real regression guard)', () {
    // hasOnlyAllowedUserFields() was defined but never called anywhere in
    // firestore.rules (the active /users/{userId} update rule uses
    // diff(resource.data).affectedKeys() instead - see the comment there).
    // It was also broken in isolation: updatingFields.hasAll(allowedFields)
    // requires ALL 5 allowed fields present in the same write (so a
    // single-field fcmTokens update would fail it), while the
    // .size() == allowedFields.size() fallback would wrongly accept any 5
    // arbitrary keys, allowed or not. A landmine left in the rules file
    // that would break real writes (like FirestoreService.persistFcmToken's
    // single-field arrayUnion) if anyone ever wired it back in.
    test('the broken, unused hasOnlyAllowedUserFields() helper is gone', () {
      final rulesSource = File('firestore.rules').readAsStringSync();
      expect(rulesSource, isNot(contains('hasOnlyAllowedUserFields')));
    });
  });
}
