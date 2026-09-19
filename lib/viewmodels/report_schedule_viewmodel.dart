import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shinjuu_league/services/scheduled_report_service.dart';

/// State for report scheduling
class ReportScheduleState {
  final List<ScheduledReport> scheduledReports;
  final List<ReportExecutionRecord> executionHistory;
  final bool isLoading;
  final String? error;
  final String? selectedReportId;

  const ReportScheduleState({
    this.scheduledReports = const [],
    this.executionHistory = const [],
    this.isLoading = false,
    this.error,
    this.selectedReportId,
  });

  ReportScheduleState copyWith({
    List<ScheduledReport>? scheduledReports,
    List<ReportExecutionRecord>? executionHistory,
    bool? isLoading,
    String? error,
    String? selectedReportId,
  }) {
    return ReportScheduleState(
      scheduledReports: scheduledReports ?? this.scheduledReports,
      executionHistory: executionHistory ?? this.executionHistory,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedReportId: selectedReportId ?? this.selectedReportId,
    );
  }
}

/// ViewModel for report scheduling management
class ReportScheduleViewModel extends StateNotifier<ReportScheduleState> {
  final ScheduledReportService _reportService;
  String? _currentUserId;

  ReportScheduleViewModel({
    required ScheduledReportService reportService,
    String? userId,
  })  : _reportService = reportService,
        _currentUserId = userId,
        super(const ReportScheduleState());

  /// Load all scheduled reports for current user
  Future<void> loadScheduledReports(String userId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      _currentUserId = userId;

      final reports = await _reportService.getScheduledReports(userId);

      state = state.copyWith(
        scheduledReports: reports,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Create a new scheduled report
  Future<bool> createScheduledReport({
    required String name,
    required ReportExportFormat format,
    required List<String> selectedFields,
    required ReportFrequency frequency,
    required List<String> recipientEmails,
    bool includeMetadata = true,
  }) async {
    try {
      if (_currentUserId == null) {
        state = state.copyWith(error: 'User ID not set');
        return false;
      }

      state = state.copyWith(isLoading: true, error: null);

      final report = await _reportService.createScheduledReport(
        userId: _currentUserId!,
        name: name,
        format: format,
        selectedFields: selectedFields,
        frequency: frequency,
        recipientEmails: recipientEmails,
        includeMetadata: includeMetadata,
      );

      final updatedReports = [...state.scheduledReports, report];
      state = state.copyWith(
        scheduledReports: updatedReports,
        isLoading: false,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Update report frequency
  Future<bool> updateScheduleFrequency(
    String reportId,
    ReportFrequency newFrequency,
  ) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      await _reportService.updateScheduleFrequency(reportId, newFrequency);

      // Reload reports
      if (_currentUserId != null) {
        await loadScheduledReports(_currentUserId!);
      }

      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Update recipient emails
  Future<bool> updateRecipientEmails(
    String reportId,
    List<String> newEmails,
  ) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      await _reportService.updateRecipientEmails(reportId, newEmails);

      // Reload reports
      if (_currentUserId != null) {
        await loadScheduledReports(_currentUserId!);
      }

      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Delete a scheduled report
  Future<bool> deleteScheduledReport(String reportId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      await _reportService.deleteScheduledReport(reportId);

      final updatedReports =
          state.scheduledReports.where((r) => r.id != reportId).toList();
      state = state.copyWith(
        scheduledReports: updatedReports,
        selectedReportId:
            state.selectedReportId == reportId ? null : state.selectedReportId,
        isLoading: false,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Load execution history for a report
  Future<void> loadExecutionHistory(String reportId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final history = await _reportService.getReportHistory(reportId);

      state = state.copyWith(
        executionHistory: history,
        selectedReportId: reportId,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Execute report manually
  Future<bool> executeReportManually(
    String reportId,
    List<Map<String, dynamic>> data,
    int fileSizeBytes,
  ) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final record = await _reportService.executeReport(
        reportId,
        data: data,
        fileSizeBytes: fileSizeBytes,
      );

      final updatedHistory = [record, ...state.executionHistory];
      state = state.copyWith(
        executionHistory: updatedHistory,
        isLoading: false,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Get execution count for report
  int getExecutionCount(String reportId) {
    return state.executionHistory.where((r) => r.reportId == reportId).length;
  }

  /// Get success rate for report
  double getSuccessRate(String reportId) {
    final records =
        state.executionHistory.where((r) => r.reportId == reportId).toList();
    if (records.isEmpty) return 0.0;

    final successCount = records.where((r) => r.success).length;
    return successCount / records.length;
  }

  /// Get last execution time for report
  DateTime? getLastExecutionTime(String reportId) {
    final records =
        state.executionHistory.where((r) => r.reportId == reportId).toList();
    if (records.isEmpty) return null;

    records.sort((a, b) => b.executedAt.compareTo(a.executedAt));
    return records.first.executedAt;
  }

  /// Get total data exported for report
  int getTotalDataExported(String reportId) {
    final records =
        state.executionHistory.where((r) => r.reportId == reportId).toList();
    return records.fold<int>(0, (sum, r) => sum + r.recordCount);
  }

  /// Get average file size for report
  double getAverageFileSize(String reportId) {
    final records =
        state.executionHistory.where((r) => r.reportId == reportId).toList();
    if (records.isEmpty) return 0.0;

    final totalSize = records.fold<int>(0, (sum, r) => sum + r.fileSizeBytes);
    return totalSize / records.length;
  }

  /// Get next execution time for report
  DateTime? getNextExecutionTime(String reportId) {
    final report =
        state.scheduledReports.firstWhere((r) => r.id == reportId, orElse: () => null as dynamic);
    return (report as ScheduledReport?)?.nextExecutionAt;
  }

  /// Check if report is due for execution
  bool isReportDue(String reportId) {
    final nextExecution = getNextExecutionTime(reportId);
    if (nextExecution == null) return false;

    return DateTime.now().isAfter(nextExecution);
  }
}
