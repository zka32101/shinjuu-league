import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shinjuu_league/services/admin_analytics_service.dart';
import 'package:shinjuu_league/services/analytics_filter_service.dart';
import 'package:shinjuu_league/viewmodels/analytics_filter_viewmodel.dart';

class MockAdminAnalyticsService extends Mock implements AdminAnalyticsService {}

void main() {
  group('FilteredAnalyticsState', () {
    test('initial state has default values', () {
      const state = FilteredAnalyticsState();

      expect(state.currentFilter.operationType, isNull);
      expect(state.filteredLogs, isEmpty);
      expect(state.availableOperationTypes, isEmpty);
      expect(state.isFiltering, isFalse);
    });

    test('copyWith creates new instance with modified fields', () {
      const original = FilteredAnalyticsState();
      final filter = AnalyticsFilter(operationType: 'CREATE');

      final modified = original.copyWith(
        currentFilter: filter,
        isFiltering: true,
      );

      expect(modified.currentFilter.operationType, equals('CREATE'));
      expect(modified.isFiltering, isTrue);
      expect(identical(original, modified), isFalse);
    });

    test('copyWith preserves unchanged fields', () {
      final logs = [{'action': 'CREATE'}];
      final original = FilteredAnalyticsState(
        filteredLogs: logs,
        isFiltering: false,
      );

      final modified = original.copyWith(isFiltering: true);

      expect(modified.filteredLogs, equals(logs));
      expect(modified.isFiltering, isTrue);
    });
  });

  group('AnalyticsFilterViewModel', () {
    late MockAdminAnalyticsService mockAnalyticsService;
    late AnalyticsFilterViewModel viewModel;
    late List<Map<String, dynamic>> testLogs;

    setUp(() {
      mockAnalyticsService = MockAdminAnalyticsService();
      viewModel = AnalyticsFilterViewModel(
        analyticsService: mockAnalyticsService,
      );

      testLogs = [
        {
          'action': 'CREATE',
          'userId': 'user1',
          'resourceType': 'feature',
          'timestamp': '2026-09-01T10:00:00Z',
        },
        {
          'action': 'UPDATE',
          'userId': 'user1',
          'resourceType': 'feature',
          'timestamp': '2026-09-01T11:00:00Z',
        },
        {
          'action': 'DELETE',
          'userId': 'user2',
          'resourceType': 'feature',
          'timestamp': '2026-09-01T12:00:00Z',
        },
        {
          'action': 'CREATE',
          'userId': 'user2',
          'resourceType': 'difficulty',
          'timestamp': '2026-09-01T13:00:00Z',
        },
      ];
    });

    group('loadLogsForFiltering', () {
      test('loads logs and extracts available filters', () async {
        when(mockAnalyticsService.getAuditLog())
            .thenAnswer((_) async => testLogs);

        await viewModel.loadLogsForFiltering();

        expect(viewModel.state.availableOperationTypes,
            containsAll(['CREATE', 'UPDATE', 'DELETE']));
        expect(viewModel.state.availableUserIds, containsAll(['user1', 'user2']));
        expect(viewModel.state.availableResourceTypes, containsAll(['feature', 'difficulty']));
      });

      test('calculates initial statistics', () async {
        when(mockAnalyticsService.getAuditLog())
            .thenAnswer((_) async => testLogs);

        await viewModel.loadLogsForFiltering();

        expect(viewModel.filteredOperationCount, equals(4));
        expect(viewModel.filteredUniqueUsers, equals(2));
      });

      test('sets isFiltering to true during load', () async {
        when(mockAnalyticsService.getAuditLog())
            .thenAnswer((_) => Future.delayed(
                  Duration(milliseconds: 100),
                  () => testLogs,
                ));

        final future = viewModel.loadLogsForFiltering();
        expect(viewModel.state.isFiltering, isTrue);

        await future;
      });

      test('handles load errors gracefully', () async {
        when(mockAnalyticsService.getAuditLog())
            .thenThrow(Exception('Load failed'));

        await viewModel.loadLogsForFiltering();

        expect(viewModel.state.isFiltering, isFalse);
      });
    });

    group('filterByOperationType', () {
      setUp(() async {
        when(mockAnalyticsService.getAuditLog())
            .thenAnswer((_) async => testLogs);
        await viewModel.loadLogsForFiltering();
      });

      test('filters logs by operation type', () async {
        await viewModel.filterByOperationType('CREATE');

        expect(viewModel.state.filteredLogs.length, equals(2));
        expect(viewModel.state.filteredLogs.every((log) => log['action'] == 'CREATE'),
            isTrue);
      });

      test('updates filter state', () async {
        await viewModel.filterByOperationType('UPDATE');

        expect(viewModel.state.currentFilter.operationType, equals('UPDATE'));
      });

      test('clears filter when passed null', () async {
        await viewModel.filterByOperationType('CREATE');
        expect(viewModel.state.filteredLogs.length, equals(2));

        await viewModel.filterByOperationType(null);

        expect(viewModel.state.filteredLogs.length, equals(4));
      });
    });

    group('filterByUserId', () {
      setUp(() async {
        when(mockAnalyticsService.getAuditLog())
            .thenAnswer((_) async => testLogs);
        await viewModel.loadLogsForFiltering();
      });

      test('filters logs by user id', () async {
        await viewModel.filterByUserId('user1');

        expect(viewModel.state.filteredLogs.length, equals(2));
        expect(viewModel.state.filteredLogs.every((log) => log['userId'] == 'user1'),
            isTrue);
      });

      test('updates user id filter state', () async {
        await viewModel.filterByUserId('user2');

        expect(viewModel.state.currentFilter.userId, equals('user2'));
      });
    });

    group('filterByResourceType', () {
      setUp(() async {
        when(mockAnalyticsService.getAuditLog())
            .thenAnswer((_) async => testLogs);
        await viewModel.loadLogsForFiltering();
      });

      test('filters logs by resource type', () async {
        await viewModel.filterByResourceType('feature');

        expect(viewModel.state.filteredLogs.length, equals(3));
        expect(viewModel.state.filteredLogs.every((log) => log['resourceType'] == 'feature'),
            isTrue);
      });
    });

    group('searchByKeyword', () {
      setUp(() async {
        when(mockAnalyticsService.getAuditLog())
            .thenAnswer((_) async => testLogs);
        await viewModel.loadLogsForFiltering();
      });

      test('searches by keyword in action', () async {
        await viewModel.searchByKeyword('CREATE');

        expect(viewModel.state.filteredLogs.length, equals(2));
      });

      test('updates search keyword in filter', () async {
        await viewModel.searchByKeyword('test');

        expect(viewModel.state.currentFilter.searchKeyword, equals('test'));
      });
    });

    group('sortBy', () {
      setUp(() async {
        when(mockAnalyticsService.getAuditLog())
            .thenAnswer((_) async => testLogs);
        await viewModel.loadLogsForFiltering();
      });

      test('sorts by operation type', () async {
        await viewModel.sortBy(SortField.operationType);

        expect(viewModel.state.currentFilter.sortBy, equals(SortField.operationType));
      });

      test('sorts by user id', () async {
        await viewModel.sortBy(SortField.userId);

        expect(viewModel.state.currentFilter.sortBy, equals(SortField.userId));
      });
    });

    group('toggleSortOrder', () {
      setUp(() async {
        when(mockAnalyticsService.getAuditLog())
            .thenAnswer((_) async => testLogs);
        await viewModel.loadLogsForFiltering();
      });

      test('toggles sort order from descending to ascending', () async {
        expect(viewModel.state.currentFilter.sortOrder, equals(SortOrder.descending));

        await viewModel.toggleSortOrder();

        expect(viewModel.state.currentFilter.sortOrder, equals(SortOrder.ascending));
      });

      test('toggles sort order from ascending to descending', () async {
        final filterWithAsc =
            AnalyticsFilter(sortOrder: SortOrder.ascending);
        viewModel.state = viewModel.state.copyWith(currentFilter: filterWithAsc);

        await viewModel.toggleSortOrder();

        expect(viewModel.state.currentFilter.sortOrder, equals(SortOrder.descending));
      });
    });

    group('clearAllFilters', () {
      setUp(() async {
        when(mockAnalyticsService.getAuditLog())
            .thenAnswer((_) async => testLogs);
        await viewModel.loadLogsForFiltering();
      });

      test('clears all active filters', () async {
        await viewModel.filterByOperationType('CREATE');
        await viewModel.filterByUserId('user1');

        expect(viewModel.state.currentFilter.hasActiveFilters, isTrue);

        await viewModel.clearAllFilters();

        expect(viewModel.state.currentFilter.hasActiveFilters, isFalse);
        expect(viewModel.state.filteredLogs.length, equals(4));
      });
    });

    group('getFilterSummary', () {
      setUp(() async {
        when(mockAnalyticsService.getAuditLog())
            .thenAnswer((_) async => testLogs);
        await viewModel.loadLogsForFiltering();
      });

      test('returns "No filters active" when no filters', () {
        final summary = viewModel.getFilterSummary();

        expect(summary, equals('No filters active'));
      });

      test('includes operation type in summary', () async {
        await viewModel.filterByOperationType('CREATE');

        final summary = viewModel.getFilterSummary();

        expect(summary, contains('Type: CREATE'));
      });

      test('includes user id in summary', () async {
        await viewModel.filterByUserId('user1');

        final summary = viewModel.getFilterSummary();

        expect(summary, contains('User: user1'));
      });

      test('includes multiple filters in summary', () async {
        await viewModel.filterByOperationType('CREATE');
        await viewModel.filterByUserId('user1');

        final summary = viewModel.getFilterSummary();

        expect(summary, contains('Type: CREATE'));
        expect(summary, contains('User: user1'));
      });
    });

    group('hasActiveFilters', () {
      test('returns false when no filters active', () {
        expect(viewModel.hasActiveFilters, isFalse);
      });

      test('returns true when filter active', () async {
        when(mockAnalyticsService.getAuditLog())
            .thenAnswer((_) async => testLogs);
        await viewModel.loadLogsForFiltering();
        await viewModel.filterByOperationType('CREATE');

        expect(viewModel.hasActiveFilters, isTrue);
      });
    });

    group('filtered statistics', () {
      setUp(() async {
        when(mockAnalyticsService.getAuditLog())
            .thenAnswer((_) async => testLogs);
        await viewModel.loadLogsForFiltering();
      });

      test('returns correct operation count', () async {
        await viewModel.filterByOperationType('CREATE');

        expect(viewModel.filteredOperationCount, equals(2));
      });

      test('returns correct unique users count', () async {
        await viewModel.filterByUserId('user1');

        expect(viewModel.filteredUniqueUsers, equals(1));
      });

      test('returns correct operation types count', () async {
        await viewModel.filterByResourceType('feature');

        expect(viewModel.filteredOperationTypes, greaterThan(0));
      });
    });

    group('combining filters', () {
      setUp(() async {
        when(mockAnalyticsService.getAuditLog())
            .thenAnswer((_) async => testLogs);
        await viewModel.loadLogsForFiltering();
      });

      test('combines operation type and user id filters', () async {
        await viewModel.filterByOperationType('CREATE');
        await viewModel.filterByUserId('user1');

        expect(viewModel.state.filteredLogs.length, equals(1));
        expect(viewModel.state.filteredLogs[0]['action'], equals('CREATE'));
        expect(viewModel.state.filteredLogs[0]['userId'], equals('user1'));
      });

      test('combines all filter types', () async {
        await viewModel.filterByOperationType('CREATE');
        await viewModel.filterByUserId('user1');
        await viewModel.filterByResourceType('feature');

        expect(viewModel.state.filteredLogs.length, equals(1));
      });
    });

    group('state management', () {
      test('initial state is not filtering', () {
        expect(viewModel.state.isFiltering, isFalse);
      });

      test('state includes all filter options', () async {
        when(mockAnalyticsService.getAuditLog())
            .thenAnswer((_) async => testLogs);

        await viewModel.loadLogsForFiltering();

        expect(viewModel.state.availableOperationTypes.isNotEmpty, isTrue);
        expect(viewModel.state.availableUserIds.isNotEmpty, isTrue);
        expect(viewModel.state.availableResourceTypes.isNotEmpty, isTrue);
      });
    });
  });
}
