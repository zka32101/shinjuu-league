import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:shinjuu_league/services/scheduled_report_service.dart';
import 'package:shinjuu_league/viewmodels/report_schedule_viewmodel.dart';

class MockScheduledReportService extends Mock
    implements ScheduledReportService {}

void main() {
  group('ReportScheduleState', () {
    test('constructor creates instance with default values', () {
      const state = ReportScheduleState();

      expect(state.scheduledReports, isEmpty);
      expect(state.executionHistory, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      expect(state.selectedReportId, isNull);
    });

    test('copyWith creates new instance with modified fields', () {
      const original = ReportScheduleState(isLoading: true);
      final report = ScheduledReport(
        id: 'report_001',
        name: 'Test Report',
        userId: 'user_001',
        format: ReportExportFormat.csv,
        selectedFields: ['timestamp'],
        frequency: ReportFrequency.daily,
        recipientEmails: ['admin@example.com'],
        createdAt: DateTime.now(),
      );

      final modified = original.copyWith(
        scheduledReports: [report],
        isLoading: false,
      );

      expect(modified.scheduledReports.length, equals(1));
      expect(modified.isLoading, isFalse);
      expect(modified.error, isNull);
      expect(identical(original, modified), isFalse);
    });

    test('copyWith preserves unchanged fields', () {
      final original = ReportScheduleState(
        isLoading: false,
        error: 'Some error',
        selectedReportId: 'report_001',
      );

      final modified = original.copyWith(isLoading: true);

      expect(modified.error, equals('Some error'));
      expect(modified.selectedReportId, equals('report_001'));
      expect(modified.isLoading, isTrue);
    });
  });

  group('ReportScheduleViewModel', () {
    late MockScheduledReportService mockService;
    late ReportScheduleViewModel viewModel;

    setUp(() {
      mockService = MockScheduledReportService();
      viewModel = ReportScheduleViewModel(
        reportService: mockService,
        userId: 'user_001',
      );
    });

    group('loadScheduledReports', () {
      test('loads reports and updates state', () async {
        final testReports = [
          ScheduledReport(
            id: 'report_001',
            name: 'Daily Report',
            userId: 'user_001',
            format: ReportExportFormat.csv,
            selectedFields: ['timestamp', 'userId'],
            frequency: ReportFrequency.daily,
            recipientEmails: ['admin@example.com'],
            createdAt: DateTime.now(),
          ),
          ScheduledReport(
            id: 'report_002',
            name: 'Weekly Report',
            userId: 'user_001',
            format: ReportExportFormat.json,
            selectedFields: ['userId', 'action'],
            frequency: ReportFrequency.weekly,
            recipientEmails: ['admin@example.com'],
            createdAt: DateTime.now(),
          ),
        ];

        when(mockService.getScheduledReports('user_001'))
            .thenAnswer((_) async => testReports);

        await viewModel.loadScheduledReports('user_001');

        expect(viewModel.state.scheduledReports.length, equals(2));
        expect(viewModel.state.isLoading, isFalse);
        expect(viewModel.state.error, isNull);
      });

      test('handles load errors gracefully', () async {
        when(mockService.getScheduledReports('user_001'))
            .thenThrow(Exception('Load failed'));

        await viewModel.loadScheduledReports('user_001');

        expect(viewModel.state.scheduledReports, isEmpty);
        expect(viewModel.state.isLoading, isFalse);
        expect(viewModel.state.error, isNotNull);
      });

      test('sets isLoading to true during load', () async {
        when(mockService.getScheduledReports('user_001'))
            .thenAnswer((_) => Future.delayed(
                  const Duration(milliseconds: 100),
                  () => [],
                ));

        final loadFuture = viewModel.loadScheduledReports('user_001');
        expect(viewModel.state.isLoading, isTrue);

        await loadFuture;
        expect(viewModel.state.isLoading, isFalse);
      });
    });

    group('createScheduledReport', () {
      test('creates report and updates state', () async {
        final newReport = ScheduledReport(
          id: 'report_001',
          name: 'New Report',
          userId: 'user_001',
          format: ReportExportFormat.csv,
          selectedFields: ['timestamp'],
          frequency: ReportFrequency.daily,
          recipientEmails: ['admin@example.com'],
          createdAt: DateTime.now(),
        );

        when(mockService.createScheduledReport(
          userId: 'user_001',
          name: 'New Report',
          format: ReportExportFormat.csv,
          selectedFields: ['timestamp'],
          frequency: ReportFrequency.daily,
          recipientEmails: ['admin@example.com'],
          includeMetadata: true,
        )).thenAnswer((_) async => newReport);

        final result = await viewModel.createScheduledReport(
          name: 'New Report',
          format: ReportExportFormat.csv,
          selectedFields: ['timestamp'],
          frequency: ReportFrequency.daily,
          recipientEmails: ['admin@example.com'],
        );

        expect(result, isTrue);
        expect(viewModel.state.scheduledReports.length, equals(1));
      });

      test('returns false when userId is not set', () async {
        final viewModelNoUser = ReportScheduleViewModel(
          reportService: mockService,
        );

        final result = await viewModelNoUser.createScheduledReport(
          name: 'New Report',
          format: ReportExportFormat.csv,
          selectedFields: ['timestamp'],
          frequency: ReportFrequency.daily,
          recipientEmails: ['admin@example.com'],
        );

        expect(result, isFalse);
        expect(viewModelNoUser.state.error, isNotNull);
      });

      test('handles creation errors', () async {
        when(mockService.createScheduledReport(
          userId: anyNamed('userId') as String,
          name: anyNamed('name') as String,
          format: anyNamed('format') as ReportExportFormat,
          selectedFields: anyNamed('selectedFields') as List<String>,
          frequency: anyNamed('frequency') as ReportFrequency,
          recipientEmails: anyNamed('recipientEmails') as List<String>,
          includeMetadata: anyNamed('includeMetadata') as bool,
        )).thenThrow(Exception('Creation failed'));

        final result = await viewModel.createScheduledReport(
          name: 'New Report',
          format: ReportExportFormat.csv,
          selectedFields: ['timestamp'],
          frequency: ReportFrequency.daily,
          recipientEmails: ['admin@example.com'],
        );

        expect(result, isFalse);
        expect(viewModel.state.error, isNotNull);
      });
    });

    group('updateScheduleFrequency', () {
      test('updates frequency successfully', () async {
        final report = ScheduledReport(
          id: 'report_001',
          name: 'Test Report',
          userId: 'user_001',
          format: ReportExportFormat.csv,
          selectedFields: ['timestamp'],
          frequency: ReportFrequency.daily,
          recipientEmails: ['admin@example.com'],
          createdAt: DateTime.now(),
          nextExecutionAt: DateTime.now().add(const Duration(days: 1)),
        );

        // Set initial state
        viewModel.state = ReportScheduleState(
          scheduledReports: [report],
        );

        when(mockService.updateScheduleFrequency(
          'report_001',
          ReportFrequency.weekly,
        )).thenAnswer((_) async => {});

        when(mockService.getScheduledReports('user_001'))
            .thenAnswer((_) async => [
              report.copyWith(frequency: ReportFrequency.weekly),
            ]);

        final result = await viewModel.updateScheduleFrequency(
          'report_001',
          ReportFrequency.weekly,
        );

        expect(result, isTrue);
      });
    });

    group('deleteScheduledReport', () {
      test('deletes report and updates state', () async {
        final report = ScheduledReport(
          id: 'report_001',
          name: 'Test Report',
          userId: 'user_001',
          format: ReportExportFormat.csv,
          selectedFields: ['timestamp'],
          frequency: ReportFrequency.daily,
          recipientEmails: ['admin@example.com'],
          createdAt: DateTime.now(),
        );

        viewModel.state = ReportScheduleState(
          scheduledReports: [report],
          selectedReportId: 'report_001',
        );

        when(mockService.deleteScheduledReport('report_001'))
            .thenAnswer((_) async => {});

        final result = await viewModel.deleteScheduledReport('report_001');

        expect(result, isTrue);
        expect(viewModel.state.scheduledReports, isEmpty);
        expect(viewModel.state.selectedReportId, isNull);
      });
    });

    group('loadExecutionHistory', () {
      test('loads execution history for report', () async {
        final testRecords = [
          ReportExecutionRecord(
            id: 'exec_001',
            reportId: 'report_001',
            executedAt: DateTime.now(),
            success: true,
            recordCount: 100,
            fileSizeBytes: 5120,
            sentToEmails: ['admin@example.com'],
          ),
          ReportExecutionRecord(
            id: 'exec_002',
            reportId: 'report_001',
            executedAt: DateTime.now().subtract(const Duration(days: 1)),
            success: true,
            recordCount: 95,
            fileSizeBytes: 4096,
            sentToEmails: ['admin@example.com'],
          ),
        ];

        when(mockService.getReportHistory('report_001'))
            .thenAnswer((_) async => testRecords);

        await viewModel.loadExecutionHistory('report_001');

        expect(viewModel.state.executionHistory.length, equals(2));
        expect(viewModel.state.selectedReportId, equals('report_001'));
      });
    });

    group('executeReportManually', () {
      test('executes report and records result', () async {
        final testData = [
          {'timestamp': '2026-09-01T10:00:00Z', 'userId': 'user_001'},
        ];

        final testRecord = ReportExecutionRecord(
          id: 'exec_001',
          reportId: 'report_001',
          executedAt: DateTime.now(),
          success: true,
          recordCount: 1,
          fileSizeBytes: 1024,
          sentToEmails: ['admin@example.com'],
        );

        when(mockService.executeReport(
          'report_001',
          data: testData,
          fileSizeBytes: 1024,
        )).thenAnswer((_) async => testRecord);

        final result = await viewModel.executeReportManually(
          'report_001',
          testData,
          1024,
        );

        expect(result, isTrue);
        expect(viewModel.state.executionHistory.length, equals(1));
      });
    });

    group('Statistics getters', () {
      test('getExecutionCount returns correct count', () {
        final records = [
          ReportExecutionRecord(
            id: 'exec_001',
            reportId: 'report_001',
            executedAt: DateTime.now(),
            success: true,
            recordCount: 100,
            fileSizeBytes: 5120,
            sentToEmails: [],
          ),
          ReportExecutionRecord(
            id: 'exec_002',
            reportId: 'report_001',
            executedAt: DateTime.now(),
            success: true,
            recordCount: 100,
            fileSizeBytes: 5120,
            sentToEmails: [],
          ),
          ReportExecutionRecord(
            id: 'exec_003',
            reportId: 'report_002',
            executedAt: DateTime.now(),
            success: true,
            recordCount: 100,
            fileSizeBytes: 5120,
            sentToEmails: [],
          ),
        ];

        viewModel.state = ReportScheduleState(executionHistory: records);

        expect(viewModel.getExecutionCount('report_001'), equals(2));
        expect(viewModel.getExecutionCount('report_002'), equals(1));
      });

      test('getSuccessRate calculates correctly', () {
        final records = [
          ReportExecutionRecord(
            id: 'exec_001',
            reportId: 'report_001',
            executedAt: DateTime.now(),
            success: true,
            recordCount: 100,
            fileSizeBytes: 5120,
            sentToEmails: [],
          ),
          ReportExecutionRecord(
            id: 'exec_002',
            reportId: 'report_001',
            executedAt: DateTime.now(),
            success: false,
            recordCount: 0,
            fileSizeBytes: 0,
            sentToEmails: [],
          ),
          ReportExecutionRecord(
            id: 'exec_003',
            reportId: 'report_001',
            executedAt: DateTime.now(),
            success: true,
            recordCount: 100,
            fileSizeBytes: 5120,
            sentToEmails: [],
          ),
        ];

        viewModel.state = ReportScheduleState(executionHistory: records);

        expect(viewModel.getSuccessRate('report_001'),
            closeTo(2 / 3, 0.01)); // ~66.67%
      });

      test('getTotalDataExported sums record counts', () {
        final records = [
          ReportExecutionRecord(
            id: 'exec_001',
            reportId: 'report_001',
            executedAt: DateTime.now(),
            success: true,
            recordCount: 100,
            fileSizeBytes: 5120,
            sentToEmails: [],
          ),
          ReportExecutionRecord(
            id: 'exec_002',
            reportId: 'report_001',
            executedAt: DateTime.now(),
            success: true,
            recordCount: 150,
            fileSizeBytes: 7680,
            sentToEmails: [],
          ),
        ];

        viewModel.state = ReportScheduleState(executionHistory: records);

        expect(viewModel.getTotalDataExported('report_001'), equals(250));
      });

      test('getAverageFileSize calculates correctly', () {
        final records = [
          ReportExecutionRecord(
            id: 'exec_001',
            reportId: 'report_001',
            executedAt: DateTime.now(),
            success: true,
            recordCount: 100,
            fileSizeBytes: 1000,
            sentToEmails: [],
          ),
          ReportExecutionRecord(
            id: 'exec_002',
            reportId: 'report_001',
            executedAt: DateTime.now(),
            success: true,
            recordCount: 100,
            fileSizeBytes: 2000,
            sentToEmails: [],
          ),
        ];

        viewModel.state = ReportScheduleState(executionHistory: records);

        expect(viewModel.getAverageFileSize('report_001'), equals(1500.0));
      });
    });

    group('clearError', () {
      test('clears error message', () {
        viewModel.state = const ReportScheduleState(error: 'Some error');

        viewModel.clearError();

        expect(viewModel.state.error, isNull);
      });
    });
  });
}
