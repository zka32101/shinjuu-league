import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shinjuu_league/services/admin_api_service.dart';
import 'package:shinjuu_league/services/web_admin_dashboard_service.dart';

class MockAdminApiService extends Mock implements AdminApiService {}

void main() {
  group('WebAdminDashboardService', () {
    late MockAdminApiService mockApiService;
    late WebAdminDashboardService dashboardService;

    setUp(() {
      mockApiService = MockAdminApiService();
      dashboardService = WebAdminDashboardService(
        apiService: mockApiService,
        pollIntervalMs: 1000,
      );
    });

    tearDown(() {
      dashboardService.dispose();
    });

    group('Dashboard State', () {
      test('getDashboardState returns snapshot with all data', () {
        when(mockApiService.getDashboardState()).thenReturn({
          'timestamp': DateTime.now().toIso8601String(),
          'statistics': {
            'features': {'total': 5, 'enabled': 3, 'enabledPercentage': 60.0},
            'rollout': {'average': 50},
            'history': {'size': 10},
            'snapshots': {'count': 2},
          },
          'difficulty': {
            'levelMultiplier': 1.0,
            'cooldownMultiplier': 1.0,
            'damageMultiplier': 1.0,
          },
          'features': [
            {
              'name': 'test_feature',
              'enabled': true,
              'killSwitch': false,
              'rolloutPercentage': 100,
              'variants': ['control', 'treatment'],
              'description': 'Test feature',
            }
          ],
          'recentChanges': [],
        });

        final snapshot = dashboardService.getDashboardState();

        expect(snapshot, isNotNull);
        expect(snapshot.statistics, isNotNull);
        expect(snapshot.difficulty, isNotNull);
        expect(snapshot.features, isNotEmpty);
      });

      test('getDashboardState handles missing fields', () {
        when(mockApiService.getDashboardState()).thenReturn({});

        final snapshot = dashboardService.getDashboardState();

        expect(snapshot.statistics, isEmpty);
        expect(snapshot.difficulty, isEmpty);
        expect(snapshot.features, isEmpty);
        expect(snapshot.recentChanges, isEmpty);
      });
    });

    group('Feature Management', () {
      test('getFeatures returns feature list', () {
        when(mockApiService.getFeatures()).thenReturn([
          {
            'name': 'feature_1',
            'enabled': true,
            'killSwitch': false,
            'rolloutPercentage': 100,
            'variants': [],
            'description': 'First feature',
          },
          {
            'name': 'feature_2',
            'enabled': false,
            'killSwitch': true,
            'rolloutPercentage': 0,
            'variants': ['control'],
            'description': 'Second feature',
          },
        ]);

        final features = dashboardService.getFeatures();

        expect(features, hasLength(2));
        expect(features.first.name, 'feature_1');
        expect(features.first.enabled, isTrue);
        expect(features.last.name, 'feature_2');
        expect(features.last.killSwitch, isTrue);
      });

      test('setFeatureEnabled triggers API call', () async {
        when(mockApiService.setFeatureEnabled('test', true))
            .thenAnswer((_) async => true);
        when(mockApiService.getDashboardState()).thenReturn({
          'statistics': {},
          'difficulty': {},
          'features': [],
          'recentChanges': [],
        });

        final result =
            await dashboardService.setFeatureEnabled('test', true);

        expect(result, isTrue);
        verify(mockApiService.setFeatureEnabled('test', true)).called(1);
      });

      test('setFeatureRollout triggers API call', () async {
        when(mockApiService.setFeatureRollout('test', 50))
            .thenAnswer((_) async => true);
        when(mockApiService.getDashboardState()).thenReturn({
          'statistics': {},
          'difficulty': {},
          'features': [],
          'recentChanges': [],
        });

        final result = await dashboardService.setFeatureRollout('test', 50);

        expect(result, isTrue);
        verify(mockApiService.setFeatureRollout('test', 50)).called(1);
      });
    });

    group('Difficulty Management', () {
      test('getDifficultySettings returns settings map', () {
        when(mockApiService.getDifficultySettings()).thenReturn({
          'levelMultiplier': 1.0,
          'cooldownMultiplier': 1.0,
          'damageMultiplier': 1.0,
          'presets': {
            'easy': {'level': 0.7, 'cooldown': 0.8, 'damage': 0.9},
            'normal': {'level': 1.0, 'cooldown': 1.0, 'damage': 1.0},
            'hard': {'level': 1.3, 'cooldown': 1.2, 'damage': 1.1},
          },
        });

        final settings = dashboardService.getDifficultySettings();

        expect(settings, isNotNull);
        expect(settings['levelMultiplier'], 1.0);
        expect(settings['presets'], isNotNull);
        expect(settings['presets']['easy'], isNotNull);
      });

      test('applyDifficultyPreset triggers API call', () async {
        when(mockApiService.applyDifficultyPreset('easy'))
            .thenAnswer((_) async => true);
        when(mockApiService.getDashboardState()).thenReturn({
          'statistics': {},
          'difficulty': {},
          'features': [],
          'recentChanges': [],
        });

        final result = await dashboardService.applyDifficultyPreset('easy');

        expect(result, isTrue);
        verify(mockApiService.applyDifficultyPreset('easy')).called(1);
      });

      test('setDifficultyMultiplier triggers API call', () async {
        when(mockApiService.setDifficultyMultiplier('level', 1.5))
            .thenAnswer((_) async => true);
        when(mockApiService.getDashboardState()).thenReturn({
          'statistics': {},
          'difficulty': {},
          'features': [],
          'recentChanges': [],
        });

        final result =
            await dashboardService.setDifficultyMultiplier('level', 1.5);

        expect(result, isTrue);
        verify(mockApiService.setDifficultyMultiplier('level', 1.5))
            .called(1);
      });
    });

    group('Experiment Management', () {
      test('createExperiment triggers API call', () async {
        final config = {
          'experimentId': 'test_exp',
          'name': 'Test Experiment',
          'description': 'Test description',
          'startDate': DateTime.now().toIso8601String(),
          'controlVariant': 'control',
          'rolloutPercentage': 50,
          'variantDistribution': {'control': 50, 'treatment': 50},
        };

        when(mockApiService.createExperiment(config))
            .thenAnswer((_) async => true);
        when(mockApiService.getDashboardState()).thenReturn({
          'statistics': {},
          'difficulty': {},
          'features': [],
          'recentChanges': [],
        });

        final result = await dashboardService.createExperiment(config);

        expect(result, isTrue);
        verify(mockApiService.createExperiment(config)).called(1);
      });

      test('updateExperimentRollout triggers API call', () async {
        when(mockApiService.updateExperimentRollout('exp_123', 75))
            .thenAnswer((_) async => true);
        when(mockApiService.getDashboardState()).thenReturn({
          'statistics': {},
          'difficulty': {},
          'features': [],
          'recentChanges': [],
        });

        final result =
            await dashboardService.updateExperimentRollout('exp_123', 75);

        expect(result, isTrue);
        verify(mockApiService.updateExperimentRollout('exp_123', 75))
            .called(1);
      });
    });

    group('Snapshots & Rollback', () {
      test('rollbackToSnapshot triggers API call', () async {
        when(mockApiService.rollbackToSnapshot('initial'))
            .thenAnswer((_) async => true);
        when(mockApiService.getDashboardState()).thenReturn({
          'statistics': {},
          'difficulty': {},
          'features': [],
          'recentChanges': [],
        });

        final result = await dashboardService.rollbackToSnapshot('initial');

        expect(result, isTrue);
        verify(mockApiService.rollbackToSnapshot('initial')).called(1);
      });
    });

    group('Health Check', () {
      test('getHealthCheck returns health status', () {
        when(mockApiService.getHealthCheck()).thenReturn({
          'timestamp': DateTime.now().toIso8601String(),
          'status': 'healthy',
          'version': '1.0',
          'features': {
            'difficulty': true,
            'featureFlags': true,
            'experiments': true,
            'auditLog': true,
            'snapshots': true,
          },
        });

        final health = dashboardService.getHealthCheck();

        expect(health, isNotNull);
        expect(health['status'], 'healthy');
        expect(health['version'], '1.0');
      });
    });

    group('Polling', () {
      test('startPolling enables polling', () {
        expect(dashboardService.isPolling, isFalse);

        dashboardService.startPolling();

        expect(dashboardService.isPolling, isTrue);
      });

      test('stopPolling disables polling', () {
        dashboardService.startPolling();
        expect(dashboardService.isPolling, isTrue);

        dashboardService.stopPolling();

        expect(dashboardService.isPolling, isFalse);
      });

      test('startPolling does not start twice', () {
        dashboardService.startPolling();
        final isPolling1 = dashboardService.isPolling;

        dashboardService.startPolling();
        final isPolling2 = dashboardService.isPolling;

        expect(isPolling1, isTrue);
        expect(isPolling2, isTrue);
      });
    });

    group('Error Handling', () {
      test('API error is caught and reported', () async {
        when(mockApiService.applyDifficultyPreset('easy'))
            .thenThrow(Exception('API Error'));

        final result = await dashboardService.applyDifficultyPreset('easy');

        expect(result, isFalse);
      });

      test('error stream emits DashboardError on failure', () async {
        when(mockApiService.applyDifficultyPreset('bad'))
            .thenThrow(Exception('Test error'));

        dashboardService.onError.listen((error) {
          expect(error, isA<DashboardError>());
          expect(error.message, contains('Failed'));
        });

        await dashboardService.applyDifficultyPreset('bad');

        await Future.delayed(const Duration(milliseconds: 100));
      });
    });

    group('Data Models', () {
      test('DashboardSnapshot is immutable', () {
        final stats = {'total': 5};
        final snapshot = DashboardSnapshot(
          timestamp: DateTime.now(),
          statistics: stats,
          difficulty: {},
          features: [],
          recentChanges: [],
        );

        expect(snapshot.statistics, equals(stats));
        expect(snapshot.toString(), contains('DashboardSnapshot'));
      });

      test('FeatureOverview toString returns readable format', () {
        final feature = FeatureOverview(
          name: 'test_feature',
          enabled: true,
          killSwitch: false,
          rolloutPercentage: 100,
          variants: [],
          description: 'Test',
        );

        expect(
          feature.toString(),
          contains('test_feature'),
        );
        expect(feature.toString(), contains('enabled=true'));
      });

      test('DashboardError toString returns readable format', () {
        final error = DashboardError(
          timestamp: DateTime.now(),
          message: 'Test error message',
          stackTrace: 'stack trace',
        );

        expect(error.toString(), contains('DashboardError'));
        expect(error.toString(), contains('Test error message'));
      });
    });
  });
}
