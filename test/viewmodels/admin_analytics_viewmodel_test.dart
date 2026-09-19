import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shinjuu_league/services/admin_analytics_service.dart';
import 'package:shinjuu_league/viewmodels/admin_analytics_viewmodel.dart';

class MockAdminAnalyticsService extends Mock implements AdminAnalyticsService {}

void main() {
  group('AdminAnalyticsViewModel', () {
    late MockAdminAnalyticsService mockAnalyticsService;
    late AdminAnalyticsViewModel viewModel;

    setUp(() {
      mockAnalyticsService = MockAdminAnalyticsService();
      viewModel = AdminAnalyticsViewModel(analyticsService: mockAnalyticsService);
    });

    group('State Management', () {
      test('initial state is empty analytics', () {
        expect(viewModel.state.isLoading, isFalse);
        expect(viewModel.state.error, isNull);
        expect(viewModel.state.dashboardSummary, isEmpty);
      });

      test('copyWith preserves existing fields', () {
        final state = AnalyticsState(
          dashboardSummary: {'key': 'value'},
          isLoading: true,
        );
        final updated = state.copyWith(error: 'Test error');

        expect(updated.dashboardSummary, equals({'key': 'value'}));
        expect(updated.isLoading, isTrue);
        expect(updated.error, equals('Test error'));
      });

      test('copyWith creates new instance', () {
        final state1 = AnalyticsState();
        final state2 = state1.copyWith(isLoading: true);

        expect(identical(state1, state2), isFalse);
      });
    });

    group('loadAnalytics', () {
      test('loads all analytics data successfully', () async {
        final summary = {'summary': {'totalOperations': 100, 'uniqueUsers': 25}};
        final hourlyTrend = {0: 5, 1: 10, 2: 8};
        final dailyTrend = {'2026-09-01': 50, '2026-09-02': 60};
        final operationsByType = {'CREATE': 40, 'UPDATE': 35, 'DELETE': 25};
        final operationsByUser = {'user1': 50, 'user2': 30, 'user3': 20};
        final anomalies = {'detectedAnomalies': false, 'affectedUsers': []};
        final auditIntegrity = {'status': 'HEALTHY', 'integrityPercentage': 100.0};

        when(mockAnalyticsService.getDashboardSummary()).thenAnswer((_) async => summary);
        when(mockAnalyticsService.getHourlyOperationTrend()).thenAnswer((_) async => hourlyTrend);
        when(mockAnalyticsService.getDailyOperationTrend()).thenAnswer((_) async => dailyTrend);
        when(mockAnalyticsService.getOperationsByType())
            .thenAnswer((_) async => operationsByType);
        when(mockAnalyticsService.getOperationsByUser())
            .thenAnswer((_) async => operationsByUser);
        when(mockAnalyticsService.detectHighFrequencyOperations())
            .thenAnswer((_) async => anomalies);
        when(mockAnalyticsService.getAuditTrailIntegrity())
            .thenAnswer((_) async => auditIntegrity);

        await viewModel.loadAnalytics();

        expect(viewModel.state.isLoading, isFalse);
        expect(viewModel.state.error, isNull);
        expect(viewModel.state.dashboardSummary, equals(summary));
        expect(viewModel.state.hourlyTrend, equals(hourlyTrend));
      });

      test('sets loading state during load', () async {
        when(mockAnalyticsService.getDashboardSummary())
            .thenAnswer((_) => Future.delayed(Duration(milliseconds: 100), () => {}));
        when(mockAnalyticsService.getHourlyOperationTrend()).thenAnswer((_) async => {});
        when(mockAnalyticsService.getDailyOperationTrend()).thenAnswer((_) async => {});
        when(mockAnalyticsService.getOperationsByType()).thenAnswer((_) async => {});
        when(mockAnalyticsService.getOperationsByUser()).thenAnswer((_) async => {});
        when(mockAnalyticsService.detectHighFrequencyOperations()).thenAnswer((_) async => {});
        when(mockAnalyticsService.getAuditTrailIntegrity()).thenAnswer((_) async => {});

        final future = viewModel.loadAnalytics();
        expect(viewModel.state.isLoading, isTrue);
        await future;
      });

      test('handles loading errors gracefully', () async {
        when(mockAnalyticsService.getDashboardSummary())
            .thenThrow(Exception('Load failed'));
        when(mockAnalyticsService.getHourlyOperationTrend())
            .thenThrow(Exception('Load failed'));
        when(mockAnalyticsService.getDailyOperationTrend())
            .thenThrow(Exception('Load failed'));
        when(mockAnalyticsService.getOperationsByType()).thenThrow(Exception('Load failed'));
        when(mockAnalyticsService.getOperationsByUser()).thenThrow(Exception('Load failed'));
        when(mockAnalyticsService.detectHighFrequencyOperations())
            .thenThrow(Exception('Load failed'));
        when(mockAnalyticsService.getAuditTrailIntegrity())
            .thenThrow(Exception('Load failed'));

        await viewModel.loadAnalytics();

        expect(viewModel.state.isLoading, isFalse);
        expect(viewModel.state.error, isNotNull);
      });

      test('passes time parameters to service', () async {
        final startTime = DateTime(2026, 9, 1);
        final endTime = DateTime(2026, 9, 15);

        when(mockAnalyticsService.getDashboardSummary(startTime: startTime, endTime: endTime))
            .thenAnswer((_) async => {});
        when(mockAnalyticsService.getOperationsByType(startTime: startTime, endTime: endTime))
            .thenAnswer((_) async => {});
        when(mockAnalyticsService.getOperationsByUser(startTime: startTime, endTime: endTime))
            .thenAnswer((_) async => {});
        when(mockAnalyticsService.getAuditTrailIntegrity(
                startTime: startTime, endTime: endTime))
            .thenAnswer((_) async => {});
        when(mockAnalyticsService.getHourlyOperationTrend()).thenAnswer((_) async => {});
        when(mockAnalyticsService.getDailyOperationTrend()).thenAnswer((_) async => {});
        when(mockAnalyticsService.detectHighFrequencyOperations()).thenAnswer((_) async => {});

        await viewModel.loadAnalytics(startTime: startTime, endTime: endTime);

        verify(mockAnalyticsService.getDashboardSummary(startTime: startTime, endTime: endTime))
            .called(1);
      });
    });

    group('Getter Methods', () {
      setUp(() {
        viewModel.state = AnalyticsState(
          dashboardSummary: {
            'summary': {
              'totalOperations': 100,
              'uniqueUsers': 25,
            },
            'mostActiveAdmins': [
              {'userId': 'user1', 'operationCount': 50},
            ],
            'topOperations': [
              {'action': 'CREATE', 'count': 40},
            ],
            'topResources': [
              {'resourceType': 'feature', 'count': 60},
            ],
          },
          hourlyTrend: {0: 5, 1: 10, 2: 8, 12: 15},
          dailyTrend: {'2026-09-01': 50, '2026-09-02': 60},
          operationsByType: {'CREATE': 40, 'UPDATE': 35, 'DELETE': 25},
          operationsByUser: {'user1': 50, 'user2': 30, 'user3': 20},
          anomalies: {
            'detectedAnomalies': true,
            'affectedUsers': [
              {'userId': 'user1', 'operationCount': 100},
            ],
          },
          auditIntegrity: {
            'status': 'HEALTHY',
            'integrityPercentage': 100.0,
          },
          isLoading: false,
        );
      });

      test('getTotalOperationCount returns correct value', () {
        expect(viewModel.getTotalOperationCount(), equals(100));
      });

      test('getTotalOperationCount returns 0 on missing data', () {
        viewModel.state = AnalyticsState();
        expect(viewModel.getTotalOperationCount(), equals(0));
      });

      test('getUniqueUserCount returns correct value', () {
        expect(viewModel.getUniqueUserCount(), equals(25));
      });

      test('getOperationTypeBreakdown returns map', () {
        final breakdown = viewModel.getOperationTypeBreakdown();
        expect(breakdown['CREATE'], equals(40));
      });

      test('getOperationUserBreakdown returns map', () {
        final breakdown = viewModel.getOperationUserBreakdown();
        expect(breakdown['user1'], equals(50));
      });

      test('getHourlyTrend returns hourly data', () {
        final trend = viewModel.getHourlyTrend();
        expect(trend[1], equals(10));
      });

      test('getDailyTrend returns daily data', () {
        final trend = viewModel.getDailyTrend();
        expect(trend['2026-09-02'], equals(60));
      });

      test('getAnomalies returns anomaly data', () {
        final anomalies = viewModel.getAnomalies();
        expect(anomalies['detectedAnomalies'], isTrue);
      });

      test('hasAnomalies returns true when anomalies detected', () {
        expect(viewModel.hasAnomalies(), isTrue);
      });

      test('hasAnomalies returns false when no anomalies', () {
        viewModel.state = viewModel.state.copyWith(anomalies: {'detectedAnomalies': false});
        expect(viewModel.hasAnomalies(), isFalse);
      });

      test('getAffectedUsers returns list of affected users', () {
        final users = viewModel.getAffectedUsers();
        expect(users.length, greaterThan(0));
        expect(users[0]['userId'], equals('user1'));
      });

      test('getAuditIntegrity returns integrity data', () {
        final integrity = viewModel.getAuditIntegrity();
        expect(integrity['status'], equals('HEALTHY'));
      });

      test('isAuditTrailHealthy returns true for HEALTHY status', () {
        expect(viewModel.isAuditTrailHealthy(), isTrue);
      });

      test('isAuditTrailHealthy returns false for DEGRADED status', () {
        viewModel.state = viewModel.state
            .copyWith(auditIntegrity: {'status': 'DEGRADED', 'integrityPercentage': 95.0});
        expect(viewModel.isAuditTrailHealthy(), isFalse);
      });

      test('getIntegrityPercentage returns percentage value', () {
        expect(viewModel.getIntegrityPercentage(), equals(100.0));
      });

      test('getMostActiveAdmins returns list', () {
        final admins = viewModel.getMostActiveAdmins();
        expect(admins.isNotEmpty, isTrue);
      });

      test('getTopOperations returns list', () {
        final ops = viewModel.getTopOperations();
        expect(ops.isNotEmpty, isTrue);
      });

      test('getTopResources returns list', () {
        final resources = viewModel.getTopResources();
        expect(resources.isNotEmpty, isTrue);
      });
    });

    group('Computed Properties', () {
      setUp(() {
        viewModel.state = AnalyticsState(
          dashboardSummary: {
            'summary': {
              'totalOperations': 100,
              'uniqueUsers': 25,
            },
          },
          operationsByType: {'CREATE': 50, 'UPDATE': 40, 'DELETE': 10},
          hourlyTrend: {0: 5, 1: 10, 2: 8, 12: 15, 15: 12},
        );
      });

      test('getAverageOperationsPerUser calculates correctly', () {
        final average = viewModel.getAverageOperationsPerUser();
        expect(average, equals(4.0)); // 100 / 25
      });

      test('getAverageOperationsPerUser returns 0 when no users', () {
        viewModel.state = AnalyticsState(
          dashboardSummary: {
            'summary': {
              'totalOperations': 100,
              'uniqueUsers': 0,
            },
          },
        );
        expect(viewModel.getAverageOperationsPerUser(), equals(0.0));
      });

      test('getMostCommonOperationType returns correct operation', () {
        expect(viewModel.getMostCommonOperationType(), equals('CREATE'));
      });

      test('getMostCommonOperationType returns null when empty', () {
        viewModel.state = viewModel.state.copyWith(operationsByType: {});
        expect(viewModel.getMostCommonOperationType(), isNull);
      });

      test('getPeakHour returns hour with most operations', () {
        expect(viewModel.getPeakHour(), equals(12)); // 15 operations
      });

      test('getPeakHour returns null when empty', () {
        viewModel.state = viewModel.state.copyWith(hourlyTrend: {});
        expect(viewModel.getPeakHour(), isNull);
      });
    });

    group('Status Methods', () {
      test('isLoading returns loading state', () {
        viewModel.state = viewModel.state.copyWith(isLoading: true);
        expect(viewModel.isLoading(), isTrue);

        viewModel.state = viewModel.state.copyWith(isLoading: false);
        expect(viewModel.isLoading(), isFalse);
      });

      test('getError returns error message', () {
        viewModel.state = viewModel.state.copyWith(error: 'Test error');
        expect(viewModel.getError(), equals('Test error'));
      });

      test('getError returns null when no error', () {
        viewModel.state = viewModel.state.copyWith(error: null);
        expect(viewModel.getError(), isNull);
      });
    });

    group('Refresh', () {
      test('refresh calls loadAnalytics', () async {
        when(mockAnalyticsService.getDashboardSummary()).thenAnswer((_) async => {});
        when(mockAnalyticsService.getHourlyOperationTrend()).thenAnswer((_) async => {});
        when(mockAnalyticsService.getDailyOperationTrend()).thenAnswer((_) async => {});
        when(mockAnalyticsService.getOperationsByType()).thenAnswer((_) async => {});
        when(mockAnalyticsService.getOperationsByUser()).thenAnswer((_) async => {});
        when(mockAnalyticsService.detectHighFrequencyOperations()).thenAnswer((_) async => {});
        when(mockAnalyticsService.getAuditTrailIntegrity()).thenAnswer((_) async => {});

        await viewModel.refresh();

        verify(mockAnalyticsService.getDashboardSummary()).called(1);
      });
    });

    group('toString', () {
      test('returns formatted string representation', () {
        viewModel.state = AnalyticsState(
          dashboardSummary: {
            'summary': {
              'totalOperations': 100,
              'uniqueUsers': 25,
            },
          },
        );
        final str = viewModel.state.toString();
        expect(str, contains('100'));
        expect(str, contains('25'));
      });
    });
  });
}
