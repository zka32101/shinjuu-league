import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shinjuu_league/data/providers/service_providers.dart';
import 'package:shinjuu_league/services/scheduled_report_service.dart';
import 'package:shinjuu_league/ui/screens/scheduled_reports_screen.dart';

/// ScheduledReportsScreen used to be entirely disconnected from
/// ReportScheduleViewModel - initState()'s load call and the create
/// dialog's submit handler were both left as commented-out TODOs, so the
/// body always showed a static "No scheduled reports" placeholder no
/// matter what. These tests exercise the real, Riverpod-backed state via
/// a fake ScheduledReportService and the userIdOverride test seam (real
/// userId resolution goes through AuthService()/FirebaseAuth, which needs
/// Firebase.initializeApp()).
class _FakeScheduledReportService extends Mock
    implements ScheduledReportService {
  List<ScheduledReport> allReports = [];
  bool shouldThrow = false;

  @override
  Future<List<ScheduledReport>> getScheduledReports(String? userId) async {
    if (shouldThrow) throw Exception('boom');
    return allReports;
  }

  @override
  Future<ScheduledReport> createScheduledReport({
    String? userId,
    String? name,
    ReportExportFormat? format,
    List<String>? selectedFields,
    ReportFrequency? frequency,
    List<String>? recipientEmails,
    bool? includeMetadata,
  }) async {
    final report = ScheduledReport(
      id: 'new-report',
      name: name!,
      userId: userId!,
      format: format!,
      selectedFields: selectedFields!,
      frequency: frequency!,
      recipientEmails: recipientEmails!,
      createdAt: DateTime.now(),
    );
    allReports = [...allReports, report];
    return report;
  }

  @override
  Future<void> deleteScheduledReport(String? reportId) async {
    allReports = allReports.where((r) => r.id != reportId).toList();
  }
}

ScheduledReport _createReport(String id, {String name = 'Audit log report'}) {
  return ScheduledReport(
    id: id,
    name: name,
    userId: 'test_user',
    format: ReportExportFormat.csv,
    selectedFields: const ['timestamp', 'userId', 'action'],
    frequency: ReportFrequency.daily,
    recipientEmails: const ['admin@example.com'],
    createdAt: DateTime.now(),
  );
}

ProviderContainer _containerWith(_FakeScheduledReportService service) {
  return ProviderContainer(
    overrides: [scheduledReportServiceProvider.overrideWithValue(service)],
  );
}

void main() {
  group('ScheduledReportsScreen', () {
    testWidgets('shows a login prompt with no resolvable user', (
      WidgetTester tester,
    ) async {
      // No userIdOverride, and AuthService()/FirebaseAuth throws without
      // Firebase.initializeApp() (not run in this test) - the screen must
      // degrade to this message rather than crash.
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            scheduledReportServiceProvider.overrideWithValue(
              ScheduledReportService(firestore: FakeFirebaseFirestore()),
            ),
          ],
          child: const MaterialApp(home: ScheduledReportsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ログインが必要です'), findsOneWidget);
    });

    testWidgets('shows empty state when no reports exist', (
      WidgetTester tester,
    ) async {
      final container = _containerWith(_FakeScheduledReportService());

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: ScheduledReportsScreen(userIdOverride: 'test_user'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No scheduled reports'), findsOneWidget);
    });

    testWidgets('loads and displays existing scheduled reports', (
      WidgetTester tester,
    ) async {
      final service = _FakeScheduledReportService()
        ..allReports = [_createReport('r1', name: 'Weekly audit')];
      final container = _containerWith(service);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: ScheduledReportsScreen(userIdOverride: 'test_user'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Weekly audit'), findsOneWidget);
      expect(find.byType(ScheduledReportCard), findsOneWidget);
    });

    testWidgets('shows error view with retry when load fails', (
      WidgetTester tester,
    ) async {
      final service = _FakeScheduledReportService()..shouldThrow = true;
      final container = _containerWith(service);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: ScheduledReportsScreen(userIdOverride: 'test_user'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('エラー'), findsOneWidget);
      expect(find.text('再試行'), findsOneWidget);
    });

    testWidgets('create dialog submits a new report to the real service', (
      WidgetTester tester,
    ) async {
      final service = _FakeScheduledReportService();
      final container = _containerWith(service);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: ScheduledReportsScreen(userIdOverride: 'test_user'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add).first);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Report Name'),
        'My Report',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Recipient Emails'),
        'a@example.com',
      );
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      expect(service.allReports, hasLength(1));
      expect(service.allReports.first.name, equals('My Report'));
      // The screen re-reads the ViewModel's own state (which the create
      // call above updated directly), not a fresh getScheduledReports()
      // call, so the new report shows up immediately without a reload.
      expect(find.text('レポートを作成しました'), findsOneWidget);
    });

    testWidgets('delete removes a report via the real service', (
      WidgetTester tester,
    ) async {
      final service = _FakeScheduledReportService()
        ..allReports = [_createReport('r1')];
      final container = _containerWith(service);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: ScheduledReportsScreen(userIdOverride: 'test_user'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(service.allReports, isEmpty);
      expect(find.text('No scheduled reports'), findsOneWidget);
    });
  });
}
