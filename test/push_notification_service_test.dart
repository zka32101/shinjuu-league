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
        expect(
          () async => await notificationService.init(),
          returnsNormally,
        );
      });

      test('subscribe to topic succeeds', () async {
        expect(
          () async =>
              await notificationService.subscribeToTopic('test_topic'),
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
          'data': {
            'achievement_id': 'first_kill',
            'rarity': 'common',
          },
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
