import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shinjuu_league/services/admin_analytics_service.dart';
import 'package:shinjuu_league/services/audit_logger_service.dart';
import 'package:shinjuu_league/services/firestore_service.dart';

class MockAuditLoggerService extends Mock implements AuditLoggerService {}

class MockFirestoreService extends Mock implements FirestoreService {}

void main() {
  group('AdminAnalyticsService', () {
    late MockAuditLoggerService mockAuditLoggerService;
    late MockFirestoreService mockFirestoreService;
    late AdminAnalyticsService analyticsService;

    setUp(() {
      mockAuditLoggerService = MockAuditLoggerService();
      mockFirestoreService = MockFirestoreService();
      analyticsService = AdminAnalyticsService(
        firestoreService: mockFirestoreService,
        auditLoggerService: mockAuditLoggerService,
      );
    });

    group('Operation Metrics', () {
      test('getTotalOperationCount returns correct count', () async {
        final logs = [
          {'logId': 'log1', 'action': 'CREATE_FEATURE'},
          {'logId': 'log2', 'action': 'UPDATE_FEATURE'},
          {'logId': 'log3', 'action': 'DISABLE_FEATURE'},
        ];
        when(mockAuditLoggerService.getAuditLog()).thenAnswer((_) async => logs);

        final count = await analyticsService.getTotalOperationCount();

        expect(count, equals(3));
      });

      test('getTotalOperationCount returns 0 on empty logs', () async {
        when(mockAuditLoggerService.getAuditLog()).thenAnswer((_) async => []);

        final count = await analyticsService.getTotalOperationCount();

        expect(count, equals(0));
      });

      test('getTotalOperationCount returns 0 on exception', () async {
        when(mockAuditLoggerService.getAuditLog()).thenThrow(Exception('Test error'));

        final count = await analyticsService.getTotalOperationCount();

        expect(count, equals(0));
      });

      test('getOperationsByType groups operations correctly', () async {
        final logs = [
          {'action': 'CREATE_FEATURE'},
          {'action': 'CREATE_FEATURE'},
          {'action': 'UPDATE_FEATURE'},
          {'action': 'DELETE_FEATURE'},
        ];
        when(mockAuditLoggerService.getAuditLog()).thenAnswer((_) async => logs);

        final breakdown = await analyticsService.getOperationsByType();

        expect(breakdown['CREATE_FEATURE'], equals(2));
        expect(breakdown['UPDATE_FEATURE'], equals(1));
        expect(breakdown['DELETE_FEATURE'], equals(1));
      });

      test('getOperationsByType handles missing action field', () async {
        final logs = [
          {'action': 'CREATE_FEATURE'},
          {'logId': 'log2'}, // missing action
          {'action': 'UPDATE_FEATURE'},
        ];
        when(mockAuditLoggerService.getAuditLog()).thenAnswer((_) async => logs);

        final breakdown = await analyticsService.getOperationsByType();

        expect(breakdown['CREATE_FEATURE'], equals(1));
        expect(breakdown['UNKNOWN'], equals(1));
        expect(breakdown['UPDATE_FEATURE'], equals(1));
      });

      test('getOperationsByUser groups operations by userId', () async {
        final logs = [
          {'userId': 'user1'},
          {'userId': 'user1'},
          {'userId': 'user2'},
        ];
        when(mockAuditLoggerService.getAuditLog()).thenAnswer((_) async => logs);

        final breakdown = await analyticsService.getOperationsByUser();

        expect(breakdown['user1'], equals(2));
        expect(breakdown['user2'], equals(1));
      });

      test('getOperationsByResourceType groups by resource type', () async {
        final logs = [
          {'resourceType': 'feature_flag'},
          {'resourceType': 'feature_flag'},
          {'resourceType': 'difficulty'},
        ];
        when(mockAuditLoggerService.getAuditLog()).thenAnswer((_) async => logs);

        final breakdown = await analyticsService.getOperationsByResourceType();

        expect(breakdown['feature_flag'], equals(2));
        expect(breakdown['difficulty'], equals(1));
      });
    });

    group('Time-Based Trends', () {
      test('getHourlyOperationTrend returns 24-hour map', () async {
        final now = DateTime.now();
        final logs = [
          {
            'timestamp': now.toIso8601String(),
            'userId': 'user1',
          },
          {
            'timestamp': now.subtract(Duration(hours: 1)).toIso8601String(),
            'userId': 'user2',
          },
        ];
        when(mockAuditLoggerService.getAuditLog()).thenAnswer((_) async => logs);

        final trend = await analyticsService.getHourlyOperationTrend();

        expect(trend.length, equals(24));
        expect(trend.containsKey(now.hour), isTrue);
      });

      test('getHourlyOperationTrend returns empty on exception', () async {
        when(mockAuditLoggerService.getAuditLog()).thenThrow(Exception('Test error'));

        final trend = await analyticsService.getHourlyOperationTrend();

        expect(trend, isEmpty);
      });

      test('getDailyOperationTrend returns daily map', () async {
        final now = DateTime.now();
        final logs = [
          {
            'timestamp': now.toIso8601String(),
            'userId': 'user1',
          },
          {
            'timestamp': now.subtract(Duration(days: 1)).toIso8601String(),
            'userId': 'user2',
          },
        ];
        when(mockAuditLoggerService.getAuditLog()).thenAnswer((_) async => logs);

        final trend = await analyticsService.getDailyOperationTrend();

        expect(trend.isNotEmpty, isTrue);
        expect(trend.keys.first, matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
      });

      test('getDailyOperationTrend handles invalid timestamps', () async {
        final logs = [
          {'timestamp': 'invalid-timestamp', 'userId': 'user1'},
          {'timestamp': DateTime.now().toIso8601String(), 'userId': 'user2'},
        ];
        when(mockAuditLoggerService.getAuditLog()).thenAnswer((_) async => logs);

        final trend = await analyticsService.getDailyOperationTrend();

        expect(trend.isNotEmpty, isTrue);
      });
    });

    group('User Activity Tracking', () {
      test('getUserActivity returns matching logs', () async {
        final logs = [
          {'userId': 'user1', 'action': 'CREATE_FEATURE'},
          {'userId': 'user2', 'action': 'UPDATE_FEATURE'},
          {'userId': 'user1', 'action': 'DELETE_FEATURE'},
        ];
        when(mockAuditLoggerService.getAuditLog()).thenAnswer((_) async => logs);

        final activity = await analyticsService.getUserActivity('user1');

        expect(activity.length, equals(2));
        expect(activity.every((log) => log['userId'] == 'user1'), isTrue);
      });

      test('getUserActivity returns empty when no match', () async {
        final logs = [
          {'userId': 'user2', 'action': 'CREATE_FEATURE'},
        ];
        when(mockAuditLoggerService.getAuditLog()).thenAnswer((_) async => logs);

        final activity = await analyticsService.getUserActivity('user1');

        expect(activity, isEmpty);
      });

      test('getMostActiveAdmins returns top users', () async {
        final logs = [
          {'userId': 'user1'},
          {'userId': 'user1'},
          {'userId': 'user1'},
          {'userId': 'user2'},
          {'userId': 'user2'},
          {'userId': 'user3'},
        ];
        when(mockAuditLoggerService.getAuditLog()).thenAnswer((_) async => logs);

        final mostActive = await analyticsService.getMostActiveAdmins(limit: 2);

        expect(mostActive.length, equals(2));
        expect(mostActive[0]['userId'], equals('user1'));
        expect(mostActive[0]['operationCount'], equals(3));
        expect(mostActive[1]['userId'], equals('user2'));
        expect(mostActive[1]['operationCount'], equals(2));
      });

      test('getMostActiveAdmins respects limit parameter', () async {
        final logs = List.generate(
          10,
          (i) => {'userId': 'user${i % 5}'},
        );
        when(mockAuditLoggerService.getAuditLog()).thenAnswer((_) async => logs);

        final mostActive = await analyticsService.getMostActiveAdmins(limit: 3);

        expect(mostActive.length, equals(3));
      });
    });

    group('Risk Indicators & Anomalies', () {
      test('detectHighFrequencyOperations identifies abusive patterns', () async {
        final now = DateTime.now();
        final logs = [
          {'userId': 'user1', 'timestamp': now.toIso8601String()},
          {'userId': 'user1', 'timestamp': now.add(Duration(seconds: 10)).toIso8601String()},
          {'userId': 'user1', 'timestamp': now.add(Duration(seconds: 20)).toIso8601String()},
          {'userId': 'user1', 'timestamp': now.add(Duration(seconds: 30)).toIso8601String()},
          {'userId': 'user2', 'timestamp': now.toIso8601String()},
        ];
        when(mockAuditLoggerService.getAuditLog()).thenAnswer((_) async => logs);

        final anomalies = await analyticsService.detectHighFrequencyOperations(
          timeWindow: Duration(minutes: 5),
          threshold: 3,
        );

        expect(anomalies['detectedAnomalies'], isTrue);
        expect((anomalies['affectedUsers'] as List).length, greaterThan(0));
      });

      test('detectHighFrequencyOperations returns false when no abuse', () async {
        final logs = [
          {'userId': 'user1'},
          {'userId': 'user2'},
          {'userId': 'user3'},
        ];
        when(mockAuditLoggerService.getAuditLog()).thenAnswer((_) async => logs);

        final anomalies = await analyticsService.detectHighFrequencyOperations(
          threshold: 10,
        );

        expect(anomalies['detectedAnomalies'], isFalse);
      });

      test('getUnusualOperations identifies sensitive operations', () async {
        final logs = [
          {'resourceType': 'admin_user', 'action': 'DELETE_USER'},
          {'resourceType': 'feature_flag', 'action': 'UPDATE_FEATURE'},
          {'resourceType': 'admin_role', 'action': 'UPDATE_ROLE'},
          {'resourceType': 'feature_flag', 'action': 'REVOKE_ROLE'},
        ];
        when(mockAuditLoggerService.getAuditLog()).thenAnswer((_) async => logs);

        final unusual = await analyticsService.getUnusualOperations();

        expect(unusual.length, greaterThan(0));
        expect(
          unusual.any((log) =>
              log['resourceType'] == 'admin_user' ||
              log['resourceType'] == 'admin_role'),
          isTrue,
        );
      });
    });

    group('Compliance Metrics', () {
      test('getAuditTrailIntegrity validates required fields', () async {
        final logs = [
          {
            'logId': 'log1',
            'timestamp': DateTime.now().toIso8601String(),
            'userId': 'user1',
            'action': 'CREATE',
            'resourceType': 'feature',
          },
          {
            'logId': 'log2',
            'timestamp': DateTime.now().toIso8601String(),
            'userId': 'user2',
            'action': 'UPDATE',
            // missing resourceType
          },
        ];
        when(mockAuditLoggerService.getAuditLog()).thenAnswer((_) async => logs);

        final integrity = await analyticsService.getAuditTrailIntegrity();

        expect(integrity['totalEntries'], equals(2));
        expect(integrity['validEntries'], equals(1));
        expect(integrity['missingFields'], equals(1));
        expect(integrity['status'], equals('DEGRADED'));
      });

      test('getAuditTrailIntegrity returns HEALTHY when all valid', () async {
        final logs = [
          {
            'logId': 'log1',
            'timestamp': DateTime.now().toIso8601String(),
            'userId': 'user1',
            'action': 'CREATE',
            'resourceType': 'feature',
          },
        ];
        when(mockAuditLoggerService.getAuditLog()).thenAnswer((_) async => logs);

        final integrity = await analyticsService.getAuditTrailIntegrity();

        expect(integrity['status'], equals('HEALTHY'));
        expect(integrity['missingFields'], equals(0));
      });

      test('getAuditRetentionStats returns retention info', () async {
        final logs = List.generate(100, (i) => {'logId': 'log$i'});
        when(mockAuditLoggerService.getAuditLog()).thenAnswer((_) async => logs);

        final stats = await analyticsService.getAuditRetentionStats();

        expect(stats['totalEntries'], isNotNull);
        expect(stats['retentionStatus'], equals('ACTIVE'));
      });
    });

    group('Dashboard Summary', () {
      test('getDashboardSummary aggregates all metrics', () async {
        final logs = [
          {
            'userId': 'user1',
            'action': 'CREATE_FEATURE',
            'resourceType': 'feature',
            'timestamp': DateTime.now().toIso8601String(),
            'logId': 'log1',
          },
          {
            'userId': 'user2',
            'action': 'UPDATE_FEATURE',
            'resourceType': 'feature',
            'timestamp': DateTime.now().toIso8601String(),
            'logId': 'log2',
          },
        ];
        when(mockAuditLoggerService.getAuditLog()).thenAnswer((_) async => logs);

        final summary = await analyticsService.getDashboardSummary();

        expect(summary['summary']['totalOperations'], equals(2));
        expect(summary['summary']['uniqueUsers'], equals(2));
        expect(summary['topOperations'], isNotNull);
        expect(summary['topResources'], isNotNull);
        expect(summary['mostActiveAdmins'], isNotNull);
        expect(summary['auditIntegrity'], isNotNull);
      });

      test('getDashboardSummary includes time range', () async {
        final startTime = DateTime.now().subtract(Duration(days: 1));
        final endTime = DateTime.now();
        final logs = [
          {
            'userId': 'user1',
            'action': 'CREATE_FEATURE',
            'resourceType': 'feature',
            'timestamp': DateTime.now().toIso8601String(),
            'logId': 'log1',
          },
        ];
        when(mockAuditLoggerService.getAuditLog()).thenAnswer((_) async => logs);

        final summary =
            await analyticsService.getDashboardSummary(startTime: startTime, endTime: endTime);

        expect(summary['timeRange']['startTime'], isNotNull);
        expect(summary['timeRange']['endTime'], isNotNull);
      });

      test('getDashboardSummary handles errors gracefully', () async {
        when(mockAuditLoggerService.getAuditLog()).thenThrow(Exception('Test error'));

        final summary = await analyticsService.getDashboardSummary();

        expect(summary['error'], isNotNull);
        expect(summary['summary']['totalOperations'], equals(0));
        expect(summary['summary']['uniqueUsers'], equals(0));
      });
    });
  });
}
