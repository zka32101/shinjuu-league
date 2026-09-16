import 'package:cloud_firestore/cloud_firestore.dart';

/// Report frequency options
enum ReportFrequency {
  once,
  daily,
  weekly,
  monthly,
}

/// Report export format
enum ReportExportFormat {
  csv,
  json,
  text,
}

/// Scheduled report model
class ScheduledReport {
  final String id;
  final String name;
  final String userId;
  final ReportExportFormat format;
  final List<String> selectedFields;
  final ReportFrequency frequency;
  final List<String> recipientEmails;
  final bool includeMetadata;
  final DateTime createdAt;
  final DateTime? lastExecutedAt;
  final DateTime? nextExecutionAt;
  final bool isActive;

  const ScheduledReport({
    required this.id,
    required this.name,
    required this.userId,
    required this.format,
    required this.selectedFields,
    required this.frequency,
    required this.recipientEmails,
    this.includeMetadata = true,
    required this.createdAt,
    this.lastExecutedAt,
    this.nextExecutionAt,
    this.isActive = true,
  });

  ScheduledReport copyWith({
    String? id,
    String? name,
    String? userId,
    ReportExportFormat? format,
    List<String>? selectedFields,
    ReportFrequency? frequency,
    List<String>? recipientEmails,
    bool? includeMetadata,
    DateTime? createdAt,
    DateTime? lastExecutedAt,
    DateTime? nextExecutionAt,
    bool? isActive,
  }) {
    return ScheduledReport(
      id: id ?? this.id,
      name: name ?? this.name,
      userId: userId ?? this.userId,
      format: format ?? this.format,
      selectedFields: selectedFields ?? this.selectedFields,
      frequency: frequency ?? this.frequency,
      recipientEmails: recipientEmails ?? this.recipientEmails,
      includeMetadata: includeMetadata ?? this.includeMetadata,
      createdAt: createdAt ?? this.createdAt,
      lastExecutedAt: lastExecutedAt ?? this.lastExecutedAt,
      nextExecutionAt: nextExecutionAt ?? this.nextExecutionAt,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'userId': userId,
      'format': format.toString().split('.').last,
      'selectedFields': selectedFields,
      'frequency': frequency.toString().split('.').last,
      'recipientEmails': recipientEmails,
      'includeMetadata': includeMetadata,
      'createdAt': createdAt.toIso8601String(),
      'lastExecutedAt': lastExecutedAt?.toIso8601String(),
      'nextExecutionAt': nextExecutionAt?.toIso8601String(),
      'isActive': isActive,
    };
  }

  factory ScheduledReport.fromJson(Map<String, dynamic> json) {
    return ScheduledReport(
      id: json['id'] as String,
      name: json['name'] as String,
      userId: json['userId'] as String,
      format: ReportExportFormat.values.firstWhere(
        (e) => e.toString().split('.').last == json['format'],
        orElse: () => ReportExportFormat.csv,
      ),
      selectedFields: List<String>.from(json['selectedFields'] as List? ?? []),
      frequency: ReportFrequency.values.firstWhere(
        (e) => e.toString().split('.').last == json['frequency'],
        orElse: () => ReportFrequency.once,
      ),
      recipientEmails:
          List<String>.from(json['recipientEmails'] as List? ?? []),
      includeMetadata: json['includeMetadata'] as bool? ?? true,
      createdAt: json['createdAt'] is String
          ? DateTime.parse(json['createdAt'] as String)
          : (json['createdAt'] as Timestamp).toDate(),
      lastExecutedAt: json['lastExecutedAt'] is String
          ? DateTime.parse(json['lastExecutedAt'] as String)
          : (json['lastExecutedAt'] as Timestamp?)?.toDate(),
      nextExecutionAt: json['nextExecutionAt'] is String
          ? DateTime.parse(json['nextExecutionAt'] as String)
          : (json['nextExecutionAt'] as Timestamp?)?.toDate(),
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}

/// Report execution record
class ReportExecutionRecord {
  final String id;
  final String reportId;
  final DateTime executedAt;
  final bool success;
  final String? errorMessage;
  final int recordCount;
  final int fileSizeBytes;
  final List<String> sentToEmails;

  const ReportExecutionRecord({
    required this.id,
    required this.reportId,
    required this.executedAt,
    required this.success,
    this.errorMessage,
    required this.recordCount,
    required this.fileSizeBytes,
    required this.sentToEmails,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reportId': reportId,
      'executedAt': executedAt.toIso8601String(),
      'success': success,
      'errorMessage': errorMessage,
      'recordCount': recordCount,
      'fileSizeBytes': fileSizeBytes,
      'sentToEmails': sentToEmails,
    };
  }

  factory ReportExecutionRecord.fromJson(Map<String, dynamic> json) {
    return ReportExecutionRecord(
      id: json['id'] as String,
      reportId: json['reportId'] as String,
      executedAt: json['executedAt'] is String
          ? DateTime.parse(json['executedAt'] as String)
          : (json['executedAt'] as Timestamp).toDate(),
      success: json['success'] as bool,
      errorMessage: json['errorMessage'] as String?,
      recordCount: json['recordCount'] as int,
      fileSizeBytes: json['fileSizeBytes'] as int,
      sentToEmails: List<String>.from(json['sentToEmails'] as List? ?? []),
    );
  }
}

/// Scheduled report service
class ScheduledReportService {
  static const String _reportsCollection = 'scheduled_reports';
  static const String _executionHistorySubcollection = 'execution_history';

  final FirebaseFirestore _firestore;

  ScheduledReportService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Create a new scheduled report
  Future<ScheduledReport> createScheduledReport({
    required String userId,
    required String name,
    required ReportExportFormat format,
    required List<String> selectedFields,
    required ReportFrequency frequency,
    required List<String> recipientEmails,
    bool includeMetadata = true,
  }) async {
    try {
      final now = DateTime.now();
      final reportId = _firestore.collection(_reportsCollection).doc().id;
      final nextExecutionAt = _calculateNextExecution(frequency, now);

      final report = ScheduledReport(
        id: reportId,
        name: name,
        userId: userId,
        format: format,
        selectedFields: selectedFields,
        frequency: frequency,
        recipientEmails: recipientEmails,
        includeMetadata: includeMetadata,
        createdAt: now,
        nextExecutionAt: nextExecutionAt,
        isActive: true,
      );

      await _firestore
          .collection(_reportsCollection)
          .doc(reportId)
          .set(report.toJson());

      return report;
    } catch (e) {
      rethrow;
    }
  }

  /// Get all scheduled reports for a user
  Future<List<ScheduledReport>> getScheduledReports(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_reportsCollection)
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => ScheduledReport.fromJson(doc.data()))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      rethrow;
    }
  }

  /// Get a specific scheduled report
  Future<ScheduledReport?> getScheduledReport(String reportId) async {
    try {
      final doc =
          await _firestore.collection(_reportsCollection).doc(reportId).get();

      if (!doc.exists) return null;
      return ScheduledReport.fromJson(doc.data()!);
    } catch (e) {
      rethrow;
    }
  }

  /// Update report frequency
  Future<void> updateScheduleFrequency(
    String reportId,
    ReportFrequency newFrequency,
  ) async {
    try {
      final report = await getScheduledReport(reportId);
      if (report == null) return;

      final now = DateTime.now();
      final nextExecutionAt =
          _calculateNextExecution(newFrequency, report.lastExecutedAt ?? now);

      await _firestore.collection(_reportsCollection).doc(reportId).update({
        'frequency': newFrequency.toString().split('.').last,
        'nextExecutionAt': nextExecutionAt.toIso8601String(),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Update recipient emails
  Future<void> updateRecipientEmails(
    String reportId,
    List<String> newEmails,
  ) async {
    try {
      await _firestore
          .collection(_reportsCollection)
          .doc(reportId)
          .update({'recipientEmails': newEmails});
    } catch (e) {
      rethrow;
    }
  }

  /// Disable a scheduled report
  Future<void> deleteScheduledReport(String reportId) async {
    try {
      await _firestore.collection(_reportsCollection).doc(reportId).update({
        'isActive': false,
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Execute report manually
  Future<ReportExecutionRecord> executeReport(
    String reportId, {
    required List<Map<String, dynamic>> data,
    required int fileSizeBytes,
  }) async {
    try {
      final report = await getScheduledReport(reportId);
      if (report == null) throw Exception('Report not found');

      final now = DateTime.now();
      final executionId =
          _firestore.collection(_reportsCollection).doc().id;

      final record = ReportExecutionRecord(
        id: executionId,
        reportId: reportId,
        executedAt: now,
        success: true,
        recordCount: data.length,
        fileSizeBytes: fileSizeBytes,
        sentToEmails: report.recipientEmails,
      );

      // Save execution record
      await _firestore
          .collection(_reportsCollection)
          .doc(reportId)
          .collection(_executionHistorySubcollection)
          .doc(executionId)
          .set(record.toJson());

      // Update report with last execution time
      final nextExecution = _calculateNextExecution(
        report.frequency,
        now,
      );
      await _firestore
          .collection(_reportsCollection)
          .doc(reportId)
          .update({
        'lastExecutedAt': now.toIso8601String(),
        'nextExecutionAt': nextExecution.toIso8601String(),
      });

      return record;
    } catch (e) {
      rethrow;
    }
  }

  /// Record failed report execution
  Future<ReportExecutionRecord> recordFailedExecution(
    String reportId,
    String errorMessage,
  ) async {
    try {
      final now = DateTime.now();
      final executionId =
          _firestore.collection(_reportsCollection).doc().id;

      final record = ReportExecutionRecord(
        id: executionId,
        reportId: reportId,
        executedAt: now,
        success: false,
        errorMessage: errorMessage,
        recordCount: 0,
        fileSizeBytes: 0,
        sentToEmails: const [],
      );

      await _firestore
          .collection(_reportsCollection)
          .doc(reportId)
          .collection(_executionHistorySubcollection)
          .doc(executionId)
          .set(record.toJson());

      return record;
    } catch (e) {
      rethrow;
    }
  }

  /// Get report execution history
  Future<List<ReportExecutionRecord>> getReportHistory(
    String reportId, {
    int limit = 20,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(_reportsCollection)
          .doc(reportId)
          .collection(_executionHistorySubcollection)
          .orderBy('executedAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => ReportExecutionRecord.fromJson(doc.data()))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get reports due for execution
  Future<List<ScheduledReport>> getReportsDueForExecution() async {
    try {
      final now = DateTime.now();
      final snapshot = await _firestore
          .collection(_reportsCollection)
          .where('isActive', isEqualTo: true)
          .where('nextExecutionAt',
              isLessThanOrEqualTo: now.toIso8601String())
          .get();

      return snapshot.docs
          .map((doc) => ScheduledReport.fromJson(doc.data()))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get latest execution for a report
  Future<ReportExecutionRecord?> getLatestExecution(
      String reportId) async {
    try {
      final snapshot = await _firestore
          .collection(_reportsCollection)
          .doc(reportId)
          .collection(_executionHistorySubcollection)
          .orderBy('executedAt', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      return ReportExecutionRecord.fromJson(snapshot.docs.first.data());
    } catch (e) {
      rethrow;
    }
  }

  /// Calculate next execution time based on frequency
  DateTime _calculateNextExecution(ReportFrequency frequency, DateTime from) {
    switch (frequency) {
      case ReportFrequency.once:
        return from.add(const Duration(days: 365)); // Far future
      case ReportFrequency.daily:
        return from.add(const Duration(days: 1));
      case ReportFrequency.weekly:
        return from.add(const Duration(days: 7));
      case ReportFrequency.monthly:
        return DateTime(from.year, from.month + 1, from.day);
    }
  }

  /// Get human-readable frequency label
  static String getFrequencyLabel(ReportFrequency frequency) {
    switch (frequency) {
      case ReportFrequency.once:
        return 'One-time';
      case ReportFrequency.daily:
        return 'Daily';
      case ReportFrequency.weekly:
        return 'Weekly';
      case ReportFrequency.monthly:
        return 'Monthly';
    }
  }

  /// Get human-readable format label
  static String getFormatLabel(ReportExportFormat format) {
    switch (format) {
      case ReportExportFormat.csv:
        return 'CSV';
      case ReportExportFormat.json:
        return 'JSON';
      case ReportExportFormat.text:
        return 'Text';
    }
  }
}
