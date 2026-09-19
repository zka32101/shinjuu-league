import 'package:flutter_test/flutter_test.dart';
import 'package:shinjuu_league/services/analytics_filter_service.dart';

void main() {
  group('AnalyticsFilter', () {
    test('constructor creates filter with default values', () {
      const filter = AnalyticsFilter();

      expect(filter.operationType, isNull);
      expect(filter.userId, isNull);
      expect(filter.resourceType, isNull);
      expect(filter.searchKeyword, isNull);
      expect(filter.sortBy, equals(SortField.timestamp));
      expect(filter.sortOrder, equals(SortOrder.descending));
    });

    test('copyWith creates new instance with modified fields', () {
      const original = AnalyticsFilter();
      final modified = original.copyWith(
        operationType: 'CREATE',
        userId: 'user1',
      );

      expect(modified.operationType, equals('CREATE'));
      expect(modified.userId, equals('user1'));
      expect(modified.resourceType, isNull);
      expect(identical(original, modified), isFalse);
    });

    test('copyWith preserves unchanged fields', () {
      final original = AnalyticsFilter(
        operationType: 'UPDATE',
        userId: 'user1',
        resourceType: 'feature',
      );

      final modified = original.copyWith(operationType: 'DELETE');

      expect(modified.operationType, equals('DELETE'));
      expect(modified.userId, equals('user1'));
      expect(modified.resourceType, equals('feature'));
    });

    test('hasActiveFilters returns false when no filters', () {
      const filter = AnalyticsFilter();
      expect(filter.hasActiveFilters, isFalse);
    });

    test('hasActiveFilters returns true when operation type set', () {
      final filter = AnalyticsFilter(operationType: 'CREATE');
      expect(filter.hasActiveFilters, isTrue);
    });

    test('hasActiveFilters returns true when user id set', () {
      final filter = AnalyticsFilter(userId: 'user1');
      expect(filter.hasActiveFilters, isTrue);
    });

    test('hasActiveFilters returns true when resource type set', () {
      final filter = AnalyticsFilter(resourceType: 'feature');
      expect(filter.hasActiveFilters, isTrue);
    });

    test('hasActiveFilters returns true when search keyword set', () {
      final filter = AnalyticsFilter(searchKeyword: 'test');
      expect(filter.hasActiveFilters, isTrue);
    });

    test('clearAll returns filter with no active filters', () {
      final filter = AnalyticsFilter(
        operationType: 'CREATE',
        userId: 'user1',
        resourceType: 'feature',
        searchKeyword: 'test',
      );

      final cleared = filter.clearAll();

      expect(cleared.operationType, isNull);
      expect(cleared.userId, isNull);
      expect(cleared.resourceType, isNull);
      expect(cleared.searchKeyword, isNull);
      expect(cleared.hasActiveFilters, isFalse);
    });
  });

  group('AnalyticsFilterService', () {
    late List<Map<String, dynamic>> testLogs;

    setUp(() {
      testLogs = [
        {
          'logId': 'log1',
          'timestamp': '2026-09-01T10:00:00Z',
          'action': 'CREATE',
          'userId': 'user1',
          'resourceType': 'feature',
          'details': 'Created feature X',
        },
        {
          'logId': 'log2',
          'timestamp': '2026-09-01T11:00:00Z',
          'action': 'UPDATE',
          'userId': 'user1',
          'resourceType': 'feature',
          'details': 'Updated feature X',
        },
        {
          'logId': 'log3',
          'timestamp': '2026-09-01T12:00:00Z',
          'action': 'DELETE',
          'userId': 'user2',
          'resourceType': 'feature',
          'details': 'Deleted feature Y',
        },
        {
          'logId': 'log4',
          'timestamp': '2026-09-01T13:00:00Z',
          'action': 'CREATE',
          'userId': 'user2',
          'resourceType': 'difficulty',
          'details': 'Created difficulty multiplier',
        },
      ];
    });

    group('filterLogs', () {
      test('returns all logs when no filter applied', () {
        const filter = AnalyticsFilter();
        final result = AnalyticsFilterService.filterLogs(testLogs, filter);

        expect(result.length, equals(4));
      });

      test('filters by operation type', () {
        final filter = AnalyticsFilter(operationType: 'CREATE');
        final result = AnalyticsFilterService.filterLogs(testLogs, filter);

        expect(result.length, equals(2));
        expect(result.every((log) => log['action'] == 'CREATE'), isTrue);
      });

      test('filters by user id', () {
        final filter = AnalyticsFilter(userId: 'user1');
        final result = AnalyticsFilterService.filterLogs(testLogs, filter);

        expect(result.length, equals(2));
        expect(result.every((log) => log['userId'] == 'user1'), isTrue);
      });

      test('filters by resource type', () {
        final filter = AnalyticsFilter(resourceType: 'feature');
        final result = AnalyticsFilterService.filterLogs(testLogs, filter);

        expect(result.length, equals(3));
        expect(result.every((log) => log['resourceType'] == 'feature'), isTrue);
      });

      test('filters by keyword in action', () {
        final filter = AnalyticsFilter(searchKeyword: 'CREATE');
        final result = AnalyticsFilterService.filterLogs(testLogs, filter);

        expect(result.length, equals(2));
      });

      test('filters by keyword in details', () {
        final filter = AnalyticsFilter(searchKeyword: 'Deleted');
        final result = AnalyticsFilterService.filterLogs(testLogs, filter);

        expect(result.length, equals(1));
      });

      test('combines multiple filters with AND logic', () {
        final filter = AnalyticsFilter(
          operationType: 'CREATE',
          userId: 'user1',
        );
        final result = AnalyticsFilterService.filterLogs(testLogs, filter);

        expect(result.length, equals(1));
        expect(result[0]['action'], equals('CREATE'));
        expect(result[0]['userId'], equals('user1'));
      });

      test('sorts by timestamp descending', () {
        final filter = AnalyticsFilter(
          sortBy: SortField.timestamp,
          sortOrder: SortOrder.descending,
        );
        final result = AnalyticsFilterService.filterLogs(testLogs, filter);

        expect(result[0]['timestamp'], equals('2026-09-01T13:00:00Z'));
        expect(result[result.length - 1]['timestamp'], equals('2026-09-01T10:00:00Z'));
      });

      test('sorts by timestamp ascending', () {
        final filter = AnalyticsFilter(
          sortBy: SortField.timestamp,
          sortOrder: SortOrder.ascending,
        );
        final result = AnalyticsFilterService.filterLogs(testLogs, filter);

        expect(result[0]['timestamp'], equals('2026-09-01T10:00:00Z'));
        expect(result[result.length - 1]['timestamp'], equals('2026-09-01T13:00:00Z'));
      });

      test('sorts by operation type', () {
        final filter = AnalyticsFilter(
          sortBy: SortField.operationType,
          sortOrder: SortOrder.ascending,
        );
        final result = AnalyticsFilterService.filterLogs(testLogs, filter);

        expect(result[0]['action'], equals('CREATE'));
        expect(result[result.length - 1]['action'], equals('UPDATE'));
      });

      test('sorts by user id', () {
        final filter = AnalyticsFilter(
          sortBy: SortField.userId,
          sortOrder: SortOrder.ascending,
        );
        final result = AnalyticsFilterService.filterLogs(testLogs, filter);

        expect(result[0]['userId'], equals('user1'));
      });

      test('returns empty list when filter matches nothing', () {
        final filter = AnalyticsFilter(operationType: 'NONEXISTENT');
        final result = AnalyticsFilterService.filterLogs(testLogs, filter);

        expect(result, isEmpty);
      });

      test('handles missing fields gracefully', () {
        final logsWithMissing = [
          {'logId': 'log1'},
          {'action': 'CREATE'},
          {'action': 'UPDATE', 'userId': 'user1'},
        ];

        final filter = AnalyticsFilter(operationType: 'CREATE');
        final result = AnalyticsFilterService.filterLogs(logsWithMissing, filter);

        expect(result.length, equals(1));
      });
    });

    group('getAvailableOperationTypes', () {
      test('returns all unique operation types', () {
        final types = AnalyticsFilterService.getAvailableOperationTypes(testLogs);

        expect(types.length, equals(3));
        expect(types, containsAll(['CREATE', 'UPDATE', 'DELETE']));
      });

      test('excludes null and empty action values', () {
        final logsWithEmpty = testLogs + [
          {'action': null},
          {'action': ''},
        ];

        final types = AnalyticsFilterService.getAvailableOperationTypes(logsWithEmpty);

        expect(types.length, equals(3));
      });
    });

    group('getAvailableUserIds', () {
      test('returns all unique user ids', () {
        final userIds = AnalyticsFilterService.getAvailableUserIds(testLogs);

        expect(userIds.length, equals(2));
        expect(userIds, containsAll(['user1', 'user2']));
      });

      test('excludes null and empty user ids', () {
        final logsWithEmpty = testLogs + [
          {'userId': null},
          {'userId': ''},
        ];

        final userIds = AnalyticsFilterService.getAvailableUserIds(logsWithEmpty);

        expect(userIds.length, equals(2));
      });
    });

    group('getAvailableResourceTypes', () {
      test('returns all unique resource types', () {
        final types = AnalyticsFilterService.getAvailableResourceTypes(testLogs);

        expect(types.length, equals(2));
        expect(types, containsAll(['feature', 'difficulty']));
      });
    });

    group('calculateFilteredStats', () {
      test('calculates stats for all logs', () {
        final stats = AnalyticsFilterService.calculateFilteredStats(testLogs);

        expect(stats['totalOperations'], equals(4));
        expect(stats['uniqueUsers'], equals(2));
        expect(stats['operationTypes'], equals(3));
        expect(stats['resourceTypes'], equals(2));
      });

      test('calculates stats for filtered logs', () {
        final filtered = testLogs.where((log) => log['userId'] == 'user1').toList();
        final stats = AnalyticsFilterService.calculateFilteredStats(
          filtered as List<Map<String, dynamic>>,
        );

        expect(stats['totalOperations'], equals(2));
        expect(stats['uniqueUsers'], equals(1));
        expect(stats['operationTypes'], equals(2));
      });

      test('returns zeros for empty logs', () {
        final stats = AnalyticsFilterService.calculateFilteredStats([]);

        expect(stats['totalOperations'], equals(0));
        expect(stats['uniqueUsers'], equals(0));
        expect(stats['operationTypes'], equals(0));
        expect(stats['resourceTypes'], equals(0));
      });
    });

    group('filterBreakdown', () {
      test('returns full breakdown when no filter', () {
        final breakdown = {'feature': 10, 'difficulty': 5};
        final result = AnalyticsFilterService.filterBreakdown(breakdown, null);

        expect(result, equals(breakdown));
      });

      test('filters breakdown by key', () {
        final breakdown = {'feature': 10, 'difficulty': 5, 'experiment': 3};
        final result = AnalyticsFilterService.filterBreakdown(breakdown, 'feature');

        expect(result.length, equals(1));
        expect(result['feature'], equals(10));
      });

      test('filters breakdown case-insensitive', () {
        final breakdown = {'Feature': 10, 'difficulty': 5};
        final result = AnalyticsFilterService.filterBreakdown(breakdown, 'feature');

        expect(result.length, equals(1));
        expect(result['Feature'], equals(10));
      });

      test('returns empty breakdown when no matches', () {
        final breakdown = {'feature': 10, 'difficulty': 5};
        final result = AnalyticsFilterService.filterBreakdown(breakdown, 'nonexistent');

        expect(result, isEmpty);
      });
    });
  });
}
