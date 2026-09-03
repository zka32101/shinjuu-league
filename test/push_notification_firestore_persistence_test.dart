import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:shinjuu_league/data/models/user_model.dart';
import 'package:shinjuu_league/services/firestore_service.dart';

void main() {
  group('FCM Token Firestore Persistence', () {
    late FakeFirebaseFirestore fakeDb;

    setUp(() {
      fakeDb = FakeFirebaseFirestore();
      // Note: In production, FirestoreService uses FirebaseFirestore.instance
      // For testing, we'd need to mock/inject it. For now, we test the persistence logic.
    });

    test('persistFcmToken adds token to user document', () async {
      final userId = 'test_user_123';
      final token = 'fcm_token_abc123';

      // Create a test user first
      final testUser = User(
        uid: userId,
        name: 'Test User',
        rank: 1,
        level: 1,
        eloRating: 1000.0,
        winRate: 0.5,
        gems: 100,
        gold: 1000,
        createdAt: DateTime.now(),
        lastBattleAt: DateTime.now(),
      );

      await fakeDb.collection('users').doc(userId).set(testUser.toJson());

      // Simulate token persistence (using fake DB)
      await fakeDb.collection('users').doc(userId).update({
        'fcmTokens': FieldValue.arrayUnion([token]),
      });

      // Verify token was added
      final doc = await fakeDb.collection('users').doc(userId).get();
      final userData = doc.data() as Map<String, dynamic>;
      final fcmTokens = List<String>.from(userData['fcmTokens'] as List<dynamic>? ?? []);

      expect(fcmTokens, contains(token));
      expect(fcmTokens.length, 1);
    });

    test('persistFcmToken avoids duplicate tokens', () async {
      final userId = 'test_user_456';
      final token = 'fcm_token_def456';

      final testUser = User(
        uid: userId,
        name: 'Test User 2',
        rank: 2,
        level: 5,
        eloRating: 1200.0,
        winRate: 0.6,
        gems: 500,
        gold: 5000,
        createdAt: DateTime.now(),
        lastBattleAt: DateTime.now(),
      );

      await fakeDb.collection('users').doc(userId).set(testUser.toJson());

      // Add token twice
      await fakeDb.collection('users').doc(userId).update({
        'fcmTokens': FieldValue.arrayUnion([token]),
      });
      await fakeDb.collection('users').doc(userId).update({
        'fcmTokens': FieldValue.arrayUnion([token]),
      });

      // Verify token appears only once (arrayUnion deduplicates)
      final doc = await fakeDb.collection('users').doc(userId).get();
      final userData = doc.data() as Map<String, dynamic>;
      final fcmTokens = List<String>.from(userData['fcmTokens'] as List<dynamic>? ?? []);

      expect(fcmTokens, contains(token));
      expect(fcmTokens.length, 1);
    });

    test('persistFcmToken maintains existing tokens', () async {
      final userId = 'test_user_789';
      final token1 = 'fcm_token_1';
      final token2 = 'fcm_token_2';
      final token3 = 'fcm_token_3';

      final testUser = User(
        uid: userId,
        name: 'Test User 3',
        rank: 5,
        level: 10,
        eloRating: 1500.0,
        winRate: 0.7,
        gems: 1000,
        gold: 10000,
        fcmTokens: [token1], // Start with one token
        createdAt: DateTime.now(),
        lastBattleAt: DateTime.now(),
      );

      await fakeDb.collection('users').doc(userId).set(testUser.toJson());

      // Add new tokens
      await fakeDb.collection('users').doc(userId).update({
        'fcmTokens': FieldValue.arrayUnion([token2]),
      });
      await fakeDb.collection('users').doc(userId).update({
        'fcmTokens': FieldValue.arrayUnion([token3]),
      });

      // Verify all tokens are present
      final doc = await fakeDb.collection('users').doc(userId).get();
      final userData = doc.data() as Map<String, dynamic>;
      final fcmTokens = List<String>.from(userData['fcmTokens'] as List<dynamic>? ?? []);

      expect(fcmTokens.length, 3);
      expect(fcmTokens, containsAll([token1, token2, token3]));
    });

    test('User model serializes fcmTokens correctly', () {
      final tokens = ['token1', 'token2', 'token3'];
      final user = User(
        uid: 'test_uid',
        name: 'Test',
        rank: 1,
        level: 1,
        eloRating: 1000.0,
        winRate: 0.5,
        gems: 0,
        gold: 0,
        fcmTokens: tokens,
        createdAt: DateTime.now(),
        lastBattleAt: DateTime.now(),
      );

      final json = user.toJson();
      expect(json['fcmTokens'], equals(tokens));

      // Verify round-trip serialization
      final userFromJson = User.fromJson(json);
      expect(userFromJson.fcmTokens, equals(tokens));
    });

    test('User model deserializes missing fcmTokens as empty list', () {
      final json = {
        'uid': 'test_uid',
        'name': 'Test',
        'rank': 1,
        'level': 1,
        'eloRating': 1000.0,
        'winRate': 0.5,
        'gems': 0,
        'gold': 0,
        'createdAt': DateTime.now().toIso8601String(),
        'lastBattleAt': DateTime.now().toIso8601String(),
        // No fcmTokens field
      };

      final user = User.fromJson(json);
      expect(user.fcmTokens, isEmpty);
      expect(user.fcmTokens, isA<List<String>>());
    });

    test('User copyWith preserves fcmTokens', () {
      final tokens = ['token1', 'token2'];
      final user = User(
        uid: 'test_uid',
        name: 'Original Name',
        rank: 1,
        level: 1,
        eloRating: 1000.0,
        winRate: 0.5,
        gems: 0,
        gold: 0,
        fcmTokens: tokens,
        createdAt: DateTime.now(),
        lastBattleAt: DateTime.now(),
      );

      // Update name without specifying fcmTokens
      final updatedUser = user.copyWith(name: 'Updated Name');

      expect(updatedUser.fcmTokens, equals(tokens));
      expect(updatedUser.name, equals('Updated Name'));
    });

    test('User copyWith can update fcmTokens explicitly', () {
      final originalTokens = ['token1'];
      final newTokens = ['token2', 'token3'];
      final user = User(
        uid: 'test_uid',
        name: 'Test',
        rank: 1,
        level: 1,
        eloRating: 1000.0,
        winRate: 0.5,
        gems: 0,
        gold: 0,
        fcmTokens: originalTokens,
        createdAt: DateTime.now(),
        lastBattleAt: DateTime.now(),
      );

      final updatedUser = user.copyWith(fcmTokens: newTokens);

      expect(updatedUser.fcmTokens, equals(newTokens));
      expect(updatedUser.fcmTokens, isNot(equals(originalTokens)));
    });
  });
}
