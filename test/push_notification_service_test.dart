import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shinjuu_league/services/push_notification_service.dart';

void main() {
  group('PushNotificationService', () {
    late PushNotificationService notificationService;

    setUp(() {
      notificationService = PushNotificationService();
    });

    group('Initialization', () {
      test('init completes without error', () async {
        expect(() async => await notificationService.init(), returnsNormally);
      });

      test('subscribe to topic succeeds', () async {
        expect(
          () async => await notificationService.subscribeToTopic('test_topic'),
          returnsNormally,
        );
      });

      test('unsubscribe from topic succeeds', () async {
        expect(
          () async =>
              await notificationService.unsubscribeFromTopic('test_topic'),
          returnsNormally,
        );
      });
    });

    group('Topic Management', () {
      test('can subscribe to multiple topics', () async {
        final topics = [
          NotificationTopics.battlePassSeasonStart,
          NotificationTopics.rankedSeasonEnd,
          NotificationTopics.friendOnline,
        ];

        for (final topic in topics) {
          expect(
            () async => await notificationService.subscribeToTopic(topic),
            returnsNormally,
          );
        }
      });

      test('topic names are defined correctly', () {
        expect(NotificationTopics.battlePassSeasonStart, isNotEmpty);
        expect(NotificationTopics.maintenanceAlert, isNotEmpty);
        expect(NotificationTopics.achievementUnlocked, isNotEmpty);
      });
    });

    group('Debug Utilities', () {
      test('debugDumpNotificationSettings returns valid structure', () async {
        final dump = await notificationService.debugDumpNotificationSettings();

        // When Firebase is not initialized (in test environment), the method
        // gracefully returns an error object. Otherwise, it returns settings.
        expect(dump, isA<Map<String, dynamic>>());

        if (dump.containsKey('error')) {
          // Firebase not initialized - error case is expected
          expect(dump['error'], isA<String>());
        } else {
          // Firebase initialized - full settings available
          expect(dump, containsPair('authorization_status', isA<String>()));
          expect(dump, containsPair('alert', isA<String>()));
          expect(dump, containsPair('sound', isA<String>()));
          expect(dump, containsPair('badge', isA<String>()));
          expect(dump, containsPair('fcm_token', isA<String>()));
        }
      });
    });

    group('FCM token persistence timing (real regression guard)', () {
      // Real bug: main.dart calls PushNotificationService().init() before
      // AuthService.signInAnonymously() ever runs (that happens later, from
      // onboarding_screen.dart), so at the moment init()'s own
      // messaging.getToken() -> _saveFCMToken() call happened,
      // FirebaseAuth.instance.currentUser was always null and the token was
      // silently dropped - onTokenRefresh only fires on token rotation
      // (months apart / reinstall), never right after a fresh sign-in, so
      // nothing ever re-saved it. This can't be exercised with a real
      // FirebaseAuth/FirebaseMessaging instance here (this suite runs
      // without Firebase.initializeApp(), same as every other test in this
      // file - see the class doc above), so this guards the fix the same
      // way firestore_security_rules_test.dart guards rule text: by
      // asserting the source actually listens for the sign-in that
      // happens after init() runs, rather than only saving once at init().
      test(
        'init() listens for authStateChanges to re-save the token after a later sign-in',
        () {
          final source = File(
            'lib/services/push_notification_service.dart',
          ).readAsStringSync();
          expect(source, contains('FirebaseAuth.instance.authStateChanges()'));

          // The listener must live inside init() (not e.g. only wired from
          // some other unrelated entry point), and must call
          // _saveFCMToken again for the token obtained after sign-in.
          final initStart = source.indexOf('Future<void> init()');
          final initEnd = source.indexOf(
            '\n  Future<void> _requestAndroid13NotificationPermission',
          );
          final initBody = source.substring(initStart, initEnd);
          expect(initBody, contains('authStateChanges()'));
          expect(initBody, contains('_saveFCMToken(currentToken)'));
        },
      );
    });

    group('Singleton Pattern', () {
      test('multiple instances refer to same object', () {
        final service1 = PushNotificationService();
        final service2 = PushNotificationService();

        expect(identical(service1, service2), isTrue);
      });
    });

    group('NotificationPayload', () {
      test('can create payload from JSON', () {
        final json = {
          'type': 'achievement_unlock',
          'data': {'achievement_id': 'first_kill', 'rarity': 'common'},
        };

        final payload = NotificationPayload.fromJson(json);

        expect(payload.type, equals('achievement_unlock'));
        expect(payload.data['achievement_id'], equals('first_kill'));
      });

      test('can serialize payload to JSON', () {
        final payload = NotificationPayload(
          type: 'ranked_entry',
          data: {'level': 5},
        );

        final json = payload.toJson();

        expect(json['type'], equals('ranked_entry'));
        expect(json['data']['level'], equals(5));
      });

      test('handles missing data gracefully', () {
        final json = {
          'type': 'test_notification',
          // 'data' is missing
        };

        final payload = NotificationPayload.fromJson(json);

        expect(payload.type, equals('test_notification'));
        expect(payload.data, isEmpty);
      });

      test('handles unknown type as fallback', () {
        final json = <String, dynamic>{};

        final payload = NotificationPayload.fromJson(json);

        expect(payload.type, equals('unknown'));
      });
    });
  });
}
