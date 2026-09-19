import 'package:flutter_test/flutter_test.dart';
import 'package:shinjuu_league/services/analytics_export_service.dart';

void main() {
  group('ExportOptions', () {
    test('constructor creates instance with default values', () {
      const options = ExportOptions();

      expect(options.format, equals(ExportFormat.csv));
      expect(options.selectedFields, equals([
        'timestamp',
        'userId',
        'action',
        'resourceType',
        'resourceId',
      ]));
      expect(options.includeMetadata, isTrue);
      expect(options.prettyPrint, isTrue);
      expect(options.customFileName, isNull);
    });

    test('constructor creates instance with custom values', () {
      const options = ExportOptions(
        format: ExportFormat.json,
        selectedFields: ['userId', 'action'],
        includeMetadata: false,
        prettyPrint: false,
        customFileName: 'custom-export',
      );

      expect(options.format, equals(ExportFormat.json));
      expect(options.selectedFields, equals(['userId', 'action']));
      expect(options.includeMetadata, isFalse);
      expect(options.prettyPrint, isFalse);
      expect(options.customFileName, equals('custom-export'));
    });

    test('copyWith creates new instance with modified fields', () {
      const original = ExportOptions(format: ExportFormat.csv);
      final modified = original.copyWith(
        format: ExportFormat.json,
        customFileName: 'new-name',
      );

      expect(modified.format, equals(ExportFormat.json));
      expect(modified.customFileName, equals('new-name'));
      expect(modified.selectedFields, equals(original.selectedFields));
      expect(identical(original, modified), isFalse);
    });

    test('copyWith preserves unchanged fields', () {
      final original = ExportOptions(
        format: ExportFormat.csv,
        selectedFields: ['userId', 'action'],
        includeMetadata: true,
      );

      final modified = original.copyWith(format: ExportFormat.json);

      expect(modified.selectedFields, equals(['userId', 'action']));
      expect(modified.includeMetadata, isTrue);
      expect(modified.format, equals(ExportFormat.json));
    });
  });

  group('AnalyticsExportService', () {
    late List<Map<String, dynamic>> testLogs;

    setUp(() {
      testLogs = [
        {
          'timestamp': '2026-09-01T10:00:00Z',
          'userId': 'user1',
          'action': 'CREATE',
          'resourceType': 'feature',
          'resourceId': 'feat_001',
          'details': 'Created feature X',
        },
        {
          'timestamp': '2026-09-01T11:00:00Z',
          'userId': 'user2',
          'action': 'UPDATE',
          'resourceType': 'feature',
          'resourceId': 'feat_002',
          'details': 'Updated feature Y',
        },
        {
          'timestamp': '2026-09-01T12:00:00Z',
          'userId': 'user1',
          'action': 'DELETE',
          'resourceType': 'difficulty',
          'resourceId': 'diff_001',
          'details': 'Deleted difficulty multiplier',
        },
      ];
    });

    group('exportToCSV', () {
      test('exports logs to CSV format with header and data rows', () {
        const options = ExportOptions();
        final result = AnalyticsExportService.exportToCSV(testLogs, options);

        expect(result, contains('timestamp,userId,action,resourceType,resourceId'));
        expect(result, contains('2026-09-01T10:00:00Z,user1,CREATE,feature,feat_001'));
        expect(result, contains('2026-09-01T11:00:00Z,user2,UPDATE,feature,feat_002'));
        expect(result, contains('2026-09-01T12:00:00Z,user1,DELETE,difficulty,diff_001'));
      });

      test('includes metadata when requested', () {
        const options = ExportOptions(includeMetadata: true);
        final result = AnalyticsExportService.exportToCSV(testLogs, options);

        expect(result, contains('# Export Metadata'));
        expect(result, contains('# Total Records: 3'));
        expect(result, contains('# Export Date:'));
        expect(result, contains('# Fields:'));
      });

      test('excludes metadata when not requested', () {
        const options = ExportOptions(includeMetadata: false);
        final result = AnalyticsExportService.exportToCSV(testLogs, options);

        expect(result, isNot(contains('# Export Metadata')));
        expect(result, isNot(contains('# Total Records')));
      });

      test('escapes CSV values containing commas', () {
        final logsWithComma = [
          {
            'action': 'CREATE,UPDATE',
            'userId': 'user1',
            'timestamp': '2026-09-01T10:00:00Z',
            'resourceType': 'feature',
            'resourceId': 'feat_001',
          },
        ];

        const options = ExportOptions();
        final result = AnalyticsExportService.exportToCSV(logsWithComma, options);

        expect(result, contains('"CREATE,UPDATE"'));
      });

      test('escapes CSV values containing quotes', () {
        final logsWithQuote = [
          {
            'action': 'CREATE',
            'userId': 'user1',
            'timestamp': '2026-09-01T10:00:00Z',
            'resourceType': 'feature"with"quotes',
            'resourceId': 'feat_001',
          },
        ];

        const options = ExportOptions();
        final result = AnalyticsExportService.exportToCSV(logsWithQuote, options);

        expect(result, contains('"feature""with""quotes"'));
      });

      test('handles null values as empty strings', () {
        final logsWithNull = [
          {
            'timestamp': '2026-09-01T10:00:00Z',
            'userId': null,
            'action': 'CREATE',
            'resourceType': 'feature',
            'resourceId': 'feat_001',
          },
        ];

        const options = ExportOptions();
        final result = AnalyticsExportService.exportToCSV(logsWithNull, options);

        expect(result, contains('2026-09-01T10:00:00Z,,CREATE,feature,feat_001'));
      });

      test('returns no data message for empty logs', () {
        const options = ExportOptions();
        final result = AnalyticsExportService.exportToCSV([], options);

        expect(result, equals('No data to export'));
      });

      test('exports selected fields only', () {
        final options = ExportOptions(
          selectedFields: ['userId', 'action'],
        );
        final result = AnalyticsExportService.exportToCSV(testLogs, options);

        expect(result, contains('userId,action'));
        expect(result, isNot(contains('timestamp')));
        expect(result, isNot(contains('resourceType')));
      });
    });

    group('exportToJSON', () {
      test('exports logs to JSON format', () {
        const options = ExportOptions(prettyPrint: false);
        final result = AnalyticsExportService.exportToJSON(testLogs, options);

        expect(result, contains('"timestamp"'));
        expect(result, contains('"userId"'));
        expect(result, contains('"action"'));
        expect(result, contains('"data"'));
      });

      test('includes metadata when requested', () {
        const options = ExportOptions(includeMetadata: true, prettyPrint: false);
        final result = AnalyticsExportService.exportToJSON(testLogs, options);

        expect(result, contains('"metadata"'));
        expect(result, contains('"exportDate"'));
        expect(result, contains('"totalRecords"'));
        expect(result, contains('"selectedFields"'));
      });

      test('excludes metadata when not requested', () {
        const options = ExportOptions(includeMetadata: false, prettyPrint: false);
        final result = AnalyticsExportService.exportToJSON(testLogs, options);

        expect(result, isNot(contains('"metadata"')));
      });

      test('pretty prints JSON when requested', () {
        const options = ExportOptions(prettyPrint: true);
        final result = AnalyticsExportService.exportToJSON(testLogs, options);

        expect(result, contains('  '));
      });

      test('exports selected fields only', () {
        final options = ExportOptions(
          selectedFields: ['userId', 'action'],
          prettyPrint: false,
        );
        final result = AnalyticsExportService.exportToJSON(testLogs, options);

        expect(result, contains('"userId"'));
        expect(result, contains('"action"'));
      });

      test('handles empty logs', () {
        const options = ExportOptions(prettyPrint: false);
        final result = AnalyticsExportService.exportToJSON([], options);

        expect(result, contains('"data"'));
        expect(result, contains('[]'));
      });
    });

    group('exportToText', () {
      test('exports logs to formatted text format', () {
        const options = ExportOptions();
        final result = AnalyticsExportService.exportToText(testLogs, options);

        expect(result, contains('ANALYTICS EXPORT REPORT'));
        expect(result, contains('Generated:'));
        expect(result, contains('Total Records: 3'));
        expect(result, contains('Record #1'));
        expect(result, contains('Record #2'));
      });

      test('formats records with field values', () {
        const options = ExportOptions();
        final result = AnalyticsExportService.exportToText(testLogs, options);

        expect(result, contains('userId: user1'));
        expect(result, contains('action: CREATE'));
        expect(result, contains('resourceType: feature'));
      });

      test('includes summary when metadata requested', () {
        const options = ExportOptions(includeMetadata: true);
        final result = AnalyticsExportService.exportToText(testLogs, options);

        expect(result, contains('SUMMARY'));
        expect(result, contains('Total Records Exported: 3'));
        expect(result, contains('Export Fields:'));
      });

      test('excludes summary when metadata not requested', () {
        const options = ExportOptions(includeMetadata: false);
        final result = AnalyticsExportService.exportToText(testLogs, options);

        expect(result, isNot(contains('SUMMARY')));
      });

      test('handles empty logs', () {
        const options = ExportOptions();
        final result = AnalyticsExportService.exportToText([], options);

        expect(result, contains('ANALYTICS EXPORT REPORT'));
        expect(result, contains('Total Records: 0'));
      });

      test('exports selected fields only', () {
        final options = ExportOptions(
          selectedFields: ['userId', 'action'],
        );
        final result = AnalyticsExportService.exportToText(testLogs, options);

        expect(result, contains('userId:'));
        expect(result, contains('action:'));
      });
    });

    group('export dispatcher', () {
      test('calls exportToCSV when format is CSV', () {
        const options = ExportOptions(format: ExportFormat.csv);
        final result = AnalyticsExportService.export(testLogs, options);

        expect(result, contains('timestamp,userId'));
      });

      test('calls exportToJSON when format is JSON', () {
        const options = ExportOptions(format: ExportFormat.json, prettyPrint: false);
        final result = AnalyticsExportService.export(testLogs, options);

        expect(result, contains('"data"'));
      });

      test('calls exportToText when format is TEXT', () {
        const options = ExportOptions(format: ExportFormat.text);
        final result = AnalyticsExportService.export(testLogs, options);

        expect(result, contains('ANALYTICS EXPORT REPORT'));
      });
    });

    group('generateFileName', () {
      test('generates filename with custom name and timestamp', () {
        const options = ExportOptions(customFileName: 'my-export');
        final fileName = AnalyticsExportService.generateFileName(options);

        expect(fileName, startsWith('my-export-'));
        expect(fileName, endsWith('.csv'));
      });

      test('generates filename with default name when not provided', () {
        const options = ExportOptions();
        final fileName = AnalyticsExportService.generateFileName(options);

        expect(fileName, startsWith('analytics-export-'));
        expect(fileName, endsWith('.csv'));
      });

      test('uses correct extension for CSV format', () {
        const options = ExportOptions(
          format: ExportFormat.csv,
          customFileName: 'test',
        );
        final fileName = AnalyticsExportService.generateFileName(options);

        expect(fileName, endsWith('.csv'));
      });

      test('uses correct extension for JSON format', () {
        const options = ExportOptions(
          format: ExportFormat.json,
          customFileName: 'test',
        );
        final fileName = AnalyticsExportService.generateFileName(options);

        expect(fileName, endsWith('.json'));
      });

      test('uses correct extension for TEXT format', () {
        const options = ExportOptions(
          format: ExportFormat.text,
          customFileName: 'test',
        );
        final fileName = AnalyticsExportService.generateFileName(options);

        expect(fileName, endsWith('.txt'));
      });

      test('uses provided timestamp', () {
        const options = ExportOptions(customFileName: 'test');
        final timestamp = DateTime(2026, 9, 1, 10, 30, 45);
        final fileName = AnalyticsExportService.generateFileName(
          options,
          timestamp: timestamp,
        );

        expect(fileName, contains('2026-09-01T10-30-45'));
      });
    });

    group('generateSummary', () {
      test('generates summary with all metrics', () {
        final summary = AnalyticsExportService.generateSummary(testLogs);

        expect(summary['totalRecords'], equals(3));
        expect(summary['uniqueUsers'], equals(2));
        expect(summary['operationTypes'], equals(3));
      });

      test('extracts unique users correctly', () {
        final summary = AnalyticsExportService.generateSummary(testLogs);

        expect(summary['uniqueUsers'], equals(2));
        expect(summary['topUsers'], containsAll(['user1', 'user2']));
      });

      test('calculates date range from timestamps', () {
        final summary = AnalyticsExportService.generateSummary(testLogs);

        expect(summary['dateRange'], contains('2026-09-01T10:00:00Z'));
        expect(summary['dateRange'], contains('2026-09-01T12:00:00Z'));
      });

      test('provides operation breakdown', () {
        final summary = AnalyticsExportService.generateSummary(testLogs);
        final breakdown = summary['operationBreakdown'] as Map<String, int>;

        expect(breakdown['CREATE'], equals(1));
        expect(breakdown['UPDATE'], equals(1));
        expect(breakdown['DELETE'], equals(1));
      });

      test('returns default values for empty logs', () {
        final summary = AnalyticsExportService.generateSummary([]);

        expect(summary['totalRecords'], equals(0));
        expect(summary['uniqueUsers'], equals(0));
        expect(summary['operationTypes'], equals(0));
        expect(summary['dateRange'], equals('N/A'));
      });

      test('limits top users to 5', () {
        final manyLogs = [
          for (int i = 1; i <= 10; i++)
            {
              'timestamp': '2026-09-01T10:00:00Z',
              'userId': 'user$i',
              'action': 'CREATE',
              'resourceType': 'feature',
              'resourceId': 'feat_00$i',
            }
        ];

        final summary = AnalyticsExportService.generateSummary(manyLogs);
        final topUsers = summary['topUsers'] as List;

        expect(topUsers.length, lessThanOrEqualTo(5));
      });

      test('handles missing fields gracefully', () {
        final logsWithMissing = [
          {
            'timestamp': '2026-09-01T10:00:00Z',
            'userId': 'user1',
            'action': 'CREATE',
          },
          {
            'timestamp': '2026-09-01T11:00:00Z',
            'resourceType': 'feature',
          },
        ];

        final summary = AnalyticsExportService.generateSummary(logsWithMissing);

        expect(summary['totalRecords'], equals(2));
        expect(summary['uniqueUsers'], equals(1));
      });
    });

    group('validateExportData', () {
      test('returns true for valid logs', () {
        final isValid = AnalyticsExportService.validateExportData(testLogs);

        expect(isValid, isTrue);
      });

      test('returns false for empty logs', () {
        final isValid = AnalyticsExportService.validateExportData([]);

        expect(isValid, isFalse);
      });

      test('returns false for logs without required fields', () {
        final logsWithoutRequired = [
          {'data': 'some data'},
        ];

        final isValid = AnalyticsExportService.validateExportData(logsWithoutRequired);

        expect(isValid, isFalse);
      });

      test('returns false for empty log objects', () {
        final emptyLogs = [<String, dynamic>{}];

        final isValid = AnalyticsExportService.validateExportData(emptyLogs);

        expect(isValid, isFalse);
      });

      test('returns true if log has logId field', () {
        final logsWithLogId = [
          {
            'logId': 'log_001',
            'data': 'some data',
          },
        ];

        final isValid = AnalyticsExportService.validateExportData(logsWithLogId);

        expect(isValid, isTrue);
      });

      test('returns true if log has timestamp field', () {
        final logsWithTimestamp = [
          {
            'timestamp': '2026-09-01T10:00:00Z',
            'data': 'some data',
          },
        ];

        final isValid = AnalyticsExportService.validateExportData(logsWithTimestamp);

        expect(isValid, isTrue);
      });
    });

    group('getAvailableFields', () {
      test('returns all unique fields from logs', () {
        final fields = AnalyticsExportService.getAvailableFields(testLogs);

        expect(fields, containsAll([
          'timestamp',
          'userId',
          'action',
          'resourceType',
          'resourceId',
          'details',
        ]));
        expect(fields.length, equals(6));
      });

      test('handles empty logs', () {
        final fields = AnalyticsExportService.getAvailableFields([]);

        expect(fields, isEmpty);
      });

      test('extracts fields from mixed log objects', () {
        final mixedLogs = [
          {'field1': 'value1', 'field2': 'value2'},
          {'field2': 'value2', 'field3': 'value3'},
          {'field1': 'value1', 'field3': 'value3'},
        ];

        final fields = AnalyticsExportService.getAvailableFields(mixedLogs);

        expect(fields, equals({'field1', 'field2', 'field3'}));
      });
    });

    group('estimateFileSize', () {
      test('returns 0 for empty logs', () {
        final size = AnalyticsExportService.estimateFileSize([], ExportFormat.csv);

        expect(size, equals(0));
      });

      test('estimates CSV size roughly', () {
        final size = AnalyticsExportService.estimateFileSize(testLogs, ExportFormat.csv);

        expect(size, greaterThan(0));
        expect(size, equals(testLogs.length * 200));
      });

      test('estimates JSON size larger than CSV', () {
        final csvSize = AnalyticsExportService.estimateFileSize(testLogs, ExportFormat.csv);
        final jsonSize = AnalyticsExportService.estimateFileSize(testLogs, ExportFormat.json);

        expect(jsonSize, greaterThan(csvSize));
        expect(jsonSize, equals(testLogs.length * 300));
      });

      test('estimates TEXT size larger than CSV', () {
        final csvSize = AnalyticsExportService.estimateFileSize(testLogs, ExportFormat.csv);
        final textSize = AnalyticsExportService.estimateFileSize(testLogs, ExportFormat.text);

        expect(textSize, greaterThan(csvSize));
        expect(textSize, equals(testLogs.length * 250));
      });

      test('scales linearly with log count', () {
        final size1 = AnalyticsExportService.estimateFileSize([testLogs[0]], ExportFormat.csv);
        final size3 = AnalyticsExportService.estimateFileSize(testLogs, ExportFormat.csv);

        expect(size3, equals(size1 * 3));
      });
    });
  });
}
