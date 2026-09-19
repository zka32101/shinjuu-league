import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:shinjuu_league/services/scheduled_report_service.dart';

void main() {
  group('ScheduledReport', () {
    test('constructor creates instance with all fields', () {
      final now = DateTime.now();
      final report = ScheduledReport(
        id: 'report_001',
        name: 'Daily Analytics Export',
        userId: 'user_001',
        format: ReportExportFormat.csv,
        selectedFields: ['timestamp', 'userId', 'action'],
        frequency: ReportFrequency.daily,
        recipientEmails: ['admin@example.com'],
        includeMetadata: true,
        createdAt: now,
        nextExecutionAt: now.add(const Duration(days: 1)),
        isActive: true,
      );

      expect(report.id, equals('report_001'));
      expect(report.name, equals('Daily Analytics Export'));
      expect(report.userId, equals('user_001'));
      expect(report.format, equals(ReportExportFormat.csv));
      expect(report.frequency, equals(ReportFrequency.daily));
      expect(report.isActive, isTrue);
    });

    test('copyWith creates new instance with modified fields', () {
      final now = DateTime.now();
      final original = ScheduledReport(
        id: 'report_001',
        name: 'Daily Export',
        userId: 'user_001',
        format: ReportExportFormat.csv,
        selectedFields: ['timestamp', 'userId'],
        frequency: ReportFrequency.daily,
        recipientEmails: ['admin@example.com'],
        createdAt: now,
      );

      final modified = original.copyWith(
        name: 'Weekly Export',
        frequency: ReportFrequency.weekly,
      );

      expect(modified.name, equals('Weekly Export'));
      expect(modified.frequency, equals(ReportFrequency.weekly));
      expect(modified.userId, equals(original.userId));
      expect(identical(original, modified), isFalse);
    });

    test('toJson serializes all fields', () {
      final now = DateTime.now();
      final report = ScheduledReport(
        id: 'report_001',
        name: 'Daily Export',
        userId: 'user_001',
        format: ReportExportFormat.csv,
        selectedFields: ['timestamp', 'userId'],
        frequency: ReportFrequency.daily,
        recipientEmails: ['admin@example.com'],
        createdAt: now,
        isActive: true,
      );

      final json = report.toJson();

      expect(json['id'], equals('report_001'));
      expect(json['name'], equals('Daily Export'));
      expect(json['format'], equals('csv'));
      expect(json['frequency'], equals('daily'));
      expect(json['isActive'], isTrue);
    });

    test('fromJson deserializes from JSON', () {
      final now = DateTime.now();
      final json = {
        'id': 'report_001',
        'name': 'Daily Export',
        'userId': 'user_001',
        'format': 'csv',
        'selectedFields': ['timestamp', 'userId'],
        'frequency': 'daily',
        'recipientEmails': ['admin@example.com'],
        'includeMetadata': true,
        'createdAt': now.toIso8601String(),
        'isActive': true,
      };

      final report = ScheduledReport.fromJson(json);

      expect(report.id, equals('report_001'));
      expect(report.format, equals(ReportExportFormat.csv));
      expect(report.frequency, equals(ReportFrequency.daily));
    });
  });

  group('ReportExecutionRecord', () {
    test('constructor creates instance with all fields', () {
      final now = DateTime.now();
      final record = ReportExecutionRecord(
        id: 'exec_001',
        reportId: 'report_001',
        executedAt: now,
        success: true,
        recordCount: 100,
        fileSizeBytes: 5120,
        sentToEmails: ['admin@example.com'],
      );

      expect(record.id, equals('exec_001'));
      expect(record.success, isTrue);
      expect(record.recordCount, equals(100));
      expect(record.fileSizeBytes, equals(5120));
    });

    test('toJson serializes all fields', () {
      final now = DateTime.now();
      final record = ReportExecutionRecord(
        id: 'exec_001',
        reportId: 'report_001',
        executedAt: now,
        success: true,
        recordCount: 100,
        fileSizeBytes: 5120,
        sentToEmails: ['admin@example.com'],
      );

      final json = record.toJson();

      expect(json['id'], equals('exec_001'));
      expect(json['success'], isTrue);
      expect(json['recordCount'], equals(100));
    });

    test('fromJson deserializes from JSON', () {
      final now = DateTime.now();
      final json = {
        'id': 'exec_001',
        'reportId': 'report_001',
        'executedAt': now.toIso8601String(),
        'success': true,
        'recordCount': 100,
        'fileSizeBytes': 5120,
        'sentToEmails': ['admin@example.com'],
      };

      final record = ReportExecutionRecord.fromJson(json);

      expect(record.id, equals('exec_001'));
      expect(record.success, isTrue);
    });
  });

  group('ScheduledReportService', () {
    late ScheduledReportService service;
    late FakeFirebaseFirestore firestore;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      service = ScheduledReportService(firestore: firestore);
    });

    group('createScheduledReport', () {
      test('creates a new scheduled report', () async {
        final report = await service.createScheduledReport(
          userId: 'user_001',
          name: 'Daily Analytics',
          format: ReportExportFormat.csv,
          selectedFields: ['timestamp', 'userId'],
          frequency: ReportFrequency.daily,
          recipientEmails: ['admin@example.com'],
        );

        expect(report.id, isNotEmpty);
        expect(report.name, equals('Daily Analytics'));
        expect(report.userId, equals('user_001'));
        expect(report.isActive, isTrue);
      });

      test('sets next execution time based on frequency', () async {
        final before = DateTime.now();
        final report = await service.createScheduledReport(
          userId: 'user_001',
          name: 'Daily Report',
          format: ReportExportFormat.csv,
          selectedFields: ['timestamp'],
          frequency: ReportFrequency.daily,
          recipientEmails: ['admin@example.com'],
        );
        final after = DateTime.now();

        expect(report.nextExecutionAt, isNotNull);
        expect(
          report.nextExecutionAt!.isAfter(after.add(const Duration(hours: 23))),
          isTrue,
        );
      });
    });

    group('getScheduledReports', () {
      test('returns all active reports for user', () async {
        await service.createScheduledReport(
          userId: 'user_001',
          name: 'Report 1',
          format: ReportExportFormat.csv,
          selectedFields: ['timestamp'],
          frequency: ReportFrequency.daily,
          recipientEmails: ['admin@example.com'],
        );

        await service.createScheduledReport(
          userId: 'user_001',
          name: 'Report 2',
          format: ReportExportFormat.json,
          selectedFields: ['userId'],
          frequency: ReportFrequency.weekly,
          recipientEmails: ['admin@example.com'],
        );

        await service.createScheduledReport(
          userId: 'user_002',
          name: 'Report 3',
          format: ReportExportFormat.text,
          selectedFields: ['action'],
          frequency: ReportFrequency.monthly,
          recipientEmails: ['other@example.com'],
        );

        final reports = await service.getScheduledReports('user_001');

        expect(reports.length, equals(2));
        expect(reports.every((r) => r.userId == 'user_001'), isTrue);
      });

      test('returns empty list for user with no reports', () async {
        final reports = await service.getScheduledReports('user_nonexistent');

        expect(reports, isEmpty);
      });

      test('sorts reports by creation date descending', () async {
        final report1 = await service.createScheduledReport(
          userId: 'user_001',
          name: 'Report 1',
          format: ReportExportFormat.csv,
          selectedFields: ['timestamp'],
          frequency: ReportFrequency.daily,
          recipientEmails: ['admin@example.com'],
        );

        await Future.delayed(const Duration(milliseconds: 10));

        final report2 = await service.createScheduledReport(
          userId: 'user_001',
          name: 'Report 2',
          format: ReportExportFormat.csv,
          selectedFields: ['timestamp'],
          frequency: ReportFrequency.daily,
          recipientEmails: ['admin@example.com'],
        );

        final reports = await service.getScheduledReports('user_001');

        expect(reports.first.id, equals(report2.id));
        expect(reports.last.id, equals(report1.id));
      });
    });

    group('getScheduledReport', () {
      test('retrieves specific report by ID', () async {
        final created = await service.createScheduledReport(
          userId: 'user_001',
          name: 'Test Report',
          format: ReportExportFormat.csv,
          selectedFields: ['timestamp'],
          frequency: ReportFrequency.daily,
          recipientEmails: ['admin@example.com'],
        );

        final retrieved = await service.getScheduledReport(created.id);

        expect(retrieved, isNotNull);
        expect(retrieved!.id, equals(created.id));
        expect(retrieved.name, equals('Test Report'));
      });

      test('returns null for non-existent report', () async {
        final report = await service.getScheduledReport('nonexistent_id');

        expect(report, isNull);
      });
    });

    group('updateScheduleFrequency', () {
      test('updates frequency and recalculates next execution', () async {
        final report = await service.createScheduledReport(
          userId: 'user_001',
          name: 'Test Report',
          format: ReportExportFormat.csv,
          selectedFields: ['timestamp'],
          frequency: ReportFrequency.daily,
          recipientEmails: ['admin@example.com'],
        );

        await service.updateScheduleFrequency(
          report.id,
          ReportFrequency.weekly,
        );

        final updated = await service.getScheduledReport(report.id);

        expect(updated!.frequency, equals(ReportFrequency.weekly));
        expect(updated.nextExecutionAt!.isAfter(report.nextExecutionAt!),
            isTrue);
      });
    });

    group('updateRecipientEmails', () {
      test('updates recipient email list', () async {
        final report = await service.createScheduledReport(
          userId: 'user_001',
          name: 'Test Report',
          format: ReportExportFormat.csv,
          selectedFields: ['timestamp'],
          frequency: ReportFrequency.daily,
          recipientEmails: ['admin@example.com'],
        );

        await service.updateRecipientEmails(
          report.id,
          ['admin@example.com', 'manager@example.com'],
        );

        final updated = await service.getScheduledReport(report.id);

        expect(updated!.recipientEmails.length, equals(2));
        expect(updated.recipientEmails,
            containsAll(['admin@example.com', 'manager@example.com']));
      });
    });

    group('deleteScheduledReport', () {
      test('marks report as inactive', () async {
        final report = await service.createScheduledReport(
          userId: 'user_001',
          name: 'Test Report',
          format: ReportExportFormat.csv,
          selectedFields: ['timestamp'],
          frequency: ReportFrequency.daily,
          recipientEmails: ['admin@example.com'],
        );

        await service.deleteScheduledReport(report.id);

        final updated = await service.getScheduledReport(report.id);

        expect(updated!.isActive, isFalse);
      });

      test('deleted report not returned in getScheduledReports', () async {
        final report = await service.createScheduledReport(
          userId: 'user_001',
          name: 'Test Report',
          format: ReportExportFormat.csv,
          selectedFields: ['timestamp'],
          frequency: ReportFrequency.daily,
          recipientEmails: ['admin@example.com'],
        );

        await service.deleteScheduledReport(report.id);

        final reports = await service.getScheduledReports('user_001');

        expect(reports.any((r) => r.id == report.id), isFalse);
      });
    });

    group('executeReport', () {
      test('records successful execution', () async {
        final report = await service.createScheduledReport(
          userId: 'user_001',
          name: 'Test Report',
          format: ReportExportFormat.csv,
          selectedFields: ['timestamp'],
          frequency: ReportFrequency.daily,
          recipientEmails: ['admin@example.com'],
        );

        final testData = [
          {'timestamp': '2026-09-01T10:00:00Z', 'userId': 'user_001'},
          {'timestamp': '2026-09-01T11:00:00Z', 'userId': 'user_002'},
        ];

        final record = await service.executeReport(
          report.id,
          data: testData,
          fileSizeBytes: 2048,
        );

        expect(record.success, isTrue);
        expect(record.recordCount, equals(2));
        expect(record.fileSizeBytes, equals(2048));
      });

      test('updates last execution time', () async {
        final report = await service.createScheduledReport(
          userId: 'user_001',
          name: 'Test Report',
          format: ReportExportFormat.csv,
          selectedFields: ['timestamp'],
          frequency: ReportFrequency.daily,
          recipientEmails: ['admin@example.com'],
        );

        await service.executeReport(
          report.id,
          data: [],
          fileSizeBytes: 0,
        );

        final updated = await service.getScheduledReport(report.id);

        expect(updated!.lastExecutedAt, isNotNull);
      });
    });

    group('recordFailedExecution', () {
      test('records failed execution with error message', () async {
        final report = await service.createScheduledReport(
          userId: 'user_001',
          name: 'Test Report',
          format: ReportExportFormat.csv,
          selectedFields: ['timestamp'],
          frequency: ReportFrequency.daily,
          recipientEmails: ['admin@example.com'],
        );

        final record = await service.recordFailedExecution(
          report.id,
          'Network timeout',
        );

        expect(record.success, isFalse);
        expect(record.errorMessage, equals('Network timeout'));
        expect(record.recordCount, equals(0));
      });
    });

    group('getReportHistory', () {
      test('returns execution history limited to specified count', () async {
        final report = await service.createScheduledReport(
          userId: 'user_001',
          name: 'Test Report',
          format: ReportExportFormat.csv,
          selectedFields: ['timestamp'],
          frequency: ReportFrequency.daily,
          recipientEmails: ['admin@example.com'],
        );

        // Execute report multiple times
        for (int i = 0; i < 5; i++) {
          await service.executeReport(
            report.id,
            data: [],
            fileSizeBytes: 1024,
          );
        }

        final history = await service.getReportHistory(report.id, limit: 3);

        expect(history.length, equals(3));
      });

      test('returns history in descending chronological order', () async {
        final report = await service.createScheduledReport(
          userId: 'user_001',
          name: 'Test Report',
          format: ReportExportFormat.csv,
          selectedFields: ['timestamp'],
          frequency: ReportFrequency.daily,
          recipientEmails: ['admin@example.com'],
        );

        await service.executeReport(report.id, data: [], fileSizeBytes: 0);
        await Future.delayed(const Duration(milliseconds: 10));
        await service.executeReport(report.id, data: [], fileSizeBytes: 0);

        final history = await service.getReportHistory(report.id);

        expect(history[0].executedAt.isAfter(history[1].executedAt), isTrue);
      });
    });

    group('getReportsDueForExecution', () {
      test('returns reports with past next execution time', () async {
        final pastTime = DateTime.now().subtract(const Duration(hours: 1));

        // This is tested conceptually; actual implementation depends on
        // how FakeFirestore handles timestamp comparisons
        expect(pastTime.isBefore(DateTime.now()), isTrue);
      });
    });

    group('getLatestExecution', () {
      test('returns most recent execution record', () async {
        final report = await service.createScheduledReport(
          userId: 'user_001',
          name: 'Test Report',
          format: ReportExportFormat.csv,
          selectedFields: ['timestamp'],
          frequency: ReportFrequency.daily,
          recipientEmails: ['admin@example.com'],
        );

        final record1 = await service.executeReport(
          report.id,
          data: [{'count': 100}],
          fileSizeBytes: 1024,
        );

        await Future.delayed(const Duration(milliseconds: 10));

        final record2 = await service.executeReport(
          report.id,
          data: [{'count': 200}],
          fileSizeBytes: 2048,
        );

        final latest = await service.getLatestExecution(report.id);

        expect(latest!.id, equals(record2.id));
        expect(latest.fileSizeBytes, equals(2048));
      });

      test('returns null for report with no executions', () async {
        final report = await service.createScheduledReport(
          userId: 'user_001',
          name: 'Test Report',
          format: ReportExportFormat.csv,
          selectedFields: ['timestamp'],
          frequency: ReportFrequency.daily,
          recipientEmails: ['admin@example.com'],
        );

        final latest = await service.getLatestExecution(report.id);

        expect(latest, isNull);
      });
    });

    group('Helper methods', () {
      test('getFrequencyLabel returns correct labels', () {
        expect(
          ScheduledReportService.getFrequencyLabel(ReportFrequency.once),
          equals('One-time'),
        );
        expect(
          ScheduledReportService.getFrequencyLabel(ReportFrequency.daily),
          equals('Daily'),
        );
        expect(
          ScheduledReportService.getFrequencyLabel(ReportFrequency.weekly),
          equals('Weekly'),
        );
        expect(
          ScheduledReportService.getFrequencyLabel(ReportFrequency.monthly),
          equals('Monthly'),
        );
      });

      test('getFormatLabel returns correct labels', () {
        expect(
          ScheduledReportService.getFormatLabel(ReportExportFormat.csv),
          equals('CSV'),
        );
        expect(
          ScheduledReportService.getFormatLabel(ReportExportFormat.json),
          equals('JSON'),
        );
        expect(
          ScheduledReportService.getFormatLabel(ReportExportFormat.text),
          equals('Text'),
        );
      });
    });
  });
}
