import 'dart:convert';

/// Analytics Export Service (Phase 38)
///
/// Provides export capabilities for admin analytics data:
/// - Export to CSV format
/// - Export to JSON format
/// - Export to formatted text
/// - Custom field selection
/// - Timestamp-based file naming

enum ExportFormat {
  csv,
  json,
  text,
}

class ExportOptions {
  final ExportFormat format;
  final List<String> selectedFields;
  final bool includeMetadata;
  final bool prettyPrint;
  final String? customFileName;

  const ExportOptions({
    this.format = ExportFormat.csv,
    this.selectedFields = const [
      'timestamp',
      'userId',
      'action',
      'resourceType',
      'resourceId',
    ],
    this.includeMetadata = true,
    this.prettyPrint = true,
    this.customFileName,
  });

  ExportOptions copyWith({
    ExportFormat? format,
    List<String>? selectedFields,
    bool? includeMetadata,
    bool? prettyPrint,
    String? customFileName,
  }) {
    return ExportOptions(
      format: format ?? this.format,
      selectedFields: selectedFields ?? this.selectedFields,
      includeMetadata: includeMetadata ?? this.includeMetadata,
      prettyPrint: prettyPrint ?? this.prettyPrint,
      customFileName: customFileName ?? this.customFileName,
    );
  }
}

class AnalyticsExportService {
  /// Export audit logs to CSV format
  static String exportToCSV(
    List<Map<String, dynamic>> logs,
    ExportOptions options,
  ) {
    if (logs.isEmpty) {
      return 'No data to export';
    }

    final fields = options.selectedFields;
    final buffer = StringBuffer();

    // Write header
    buffer.writeln(fields.join(','));

    // Write data rows
    for (final log in logs) {
      final row = fields.map((field) {
        final value = log[field];
        if (value == null) return '';

        // Escape CSV values containing commas or quotes
        final stringValue = value.toString();
        if (stringValue.contains(',') || stringValue.contains('"')) {
          return '"${stringValue.replaceAll('"', '""')}"';
        }
        return stringValue;
      }).join(',');

      buffer.writeln(row);
    }

    // Add metadata if requested
    if (options.includeMetadata) {
      buffer.writeln('');
      buffer.writeln('# Export Metadata');
      buffer.writeln('# Total Records: ${logs.length}');
      buffer.writeln('# Export Date: ${DateTime.now().toIso8601String()}');
      buffer.writeln('# Fields: ${fields.join(", ")}');
    }

    return buffer.toString();
  }

  /// Export audit logs to JSON format
  static String exportToJSON(
    List<Map<String, dynamic>> logs,
    ExportOptions options,
  ) {
    final selectedLogs = logs.map((log) {
      final filtered = <String, dynamic>{};
      for (final field in options.selectedFields) {
        if (log.containsKey(field)) {
          filtered[field] = log[field];
        }
      }
      return filtered;
    }).toList();

    final exportData = {
      if (options.includeMetadata) ...{
        'metadata': {
          'exportDate': DateTime.now().toIso8601String(),
          'totalRecords': logs.length,
          'selectedFields': options.selectedFields,
        },
      },
      'data': selectedLogs,
    };

    if (options.prettyPrint) {
      final encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(exportData);
    } else {
      return jsonEncode(exportData);
    }
  }

  /// Export audit logs to formatted text
  static String exportToText(
    List<Map<String, dynamic>> logs,
    ExportOptions options,
  ) {
    final buffer = StringBuffer();

    // Header
    buffer.writeln('='.padRight(80, '='));
    buffer.writeln('ANALYTICS EXPORT REPORT');
    buffer.writeln('Generated: ${DateTime.now().toIso8601String()}');
    buffer.writeln('Total Records: ${logs.length}');
    buffer.writeln('='.padRight(80, '='));
    buffer.writeln('');

    // Data
    for (int i = 0; i < logs.length; i++) {
      final log = logs[i];
      buffer.writeln('Record #${i + 1}');
      buffer.writeln('-'.padRight(40, '-'));

      for (final field in options.selectedFields) {
        if (log.containsKey(field)) {
          final value = log[field] ?? 'N/A';
          buffer.writeln('$field: $value');
        }
      }

      buffer.writeln('');
    }

    // Summary
    if (options.includeMetadata) {
      buffer.writeln('='.padRight(80, '='));
      buffer.writeln('SUMMARY');
      buffer.writeln('='.padRight(80, '='));
      buffer.writeln('Total Records Exported: ${logs.length}');
      buffer.writeln('Export Fields: ${options.selectedFields.join(", ")}');
    }

    return buffer.toString();
  }

  /// Generate filename with timestamp
  static String generateFileName(
    ExportOptions options, {
    DateTime? timestamp,
  }) {
    timestamp ??= DateTime.now();
    // toIso8601String() (not toString()): DateTime.toString() separates the
    // date and time with a space ("2026-09-01 10:30:45.000"), which is an
    // awkward/unsafe character to have in a downloadable file name; the ISO
    // 'T' separator avoids it.
    final dateStr =
        timestamp.toIso8601String().replaceAll(':', '-').split('.')[0];
    final customName = options.customFileName ?? 'analytics-export';
    final extension = _getExtension(options.format);

    return '$customName-$dateStr.$extension';
  }

  /// Get file extension for format
  static String _getExtension(ExportFormat format) {
    switch (format) {
      case ExportFormat.csv:
        return 'csv';
      case ExportFormat.json:
        return 'json';
      case ExportFormat.text:
        return 'txt';
    }
  }

  /// Export with custom format selection
  static String export(
    List<Map<String, dynamic>> logs,
    ExportOptions options,
  ) {
    switch (options.format) {
      case ExportFormat.csv:
        return exportToCSV(logs, options);
      case ExportFormat.json:
        return exportToJSON(logs, options);
      case ExportFormat.text:
        return exportToText(logs, options);
    }
  }

  /// Generate summary statistics for report
  static Map<String, dynamic> generateSummary(
    List<Map<String, dynamic>> logs,
  ) {
    if (logs.isEmpty) {
      return {
        'totalRecords': 0,
        // Matches the non-empty-but-no-timestamps 'N/A' sentinel below
        // (`timestamps.isEmpty ? 'N/A' : ...`) - both represent the same
        // "no date range available" case and should read the same.
        'dateRange': 'N/A',
        'uniqueUsers': 0,
        'operationTypes': 0,
      };
    }

    final userIds = <String>{};
    final operationTypes = <String>{};
    final timestamps = <String>[];

    for (final log in logs) {
      final userId = log['userId'] as String?;
      if (userId != null) userIds.add(userId);

      final action = log['action'] as String?;
      if (action != null) operationTypes.add(action);

      final timestamp = log['timestamp'] as String?;
      if (timestamp != null) timestamps.add(timestamp);
    }

    timestamps.sort();

    return {
      'totalRecords': logs.length,
      'uniqueUsers': userIds.length,
      'operationTypes': operationTypes.length,
      'dateRange': timestamps.isEmpty
          ? 'N/A'
          : '${timestamps.first} to ${timestamps.last}',
      'topUsers': userIds.take(5).toList(),
      'operationBreakdown': _getOperationBreakdown(logs),
    };
  }

  /// Get operation type breakdown
  static Map<String, int> _getOperationBreakdown(
    List<Map<String, dynamic>> logs,
  ) {
    final breakdown = <String, int>{};
    for (final log in logs) {
      final action = log['action'] as String? ?? 'UNKNOWN';
      breakdown[action] = (breakdown[action] ?? 0) + 1;
    }
    return breakdown;
  }

  /// Validate export data before exporting
  static bool validateExportData(List<Map<String, dynamic>> logs) {
    if (logs.isEmpty) return false;

    // Check if logs have required fields
    for (final log in logs) {
      if (log.isEmpty) return false;
      // At minimum, should have logId or timestamp
      if (!log.containsKey('logId') && !log.containsKey('timestamp')) {
        return false;
      }
    }

    return true;
  }

  /// Get available fields from logs
  static Set<String> getAvailableFields(List<Map<String, dynamic>> logs) {
    final fields = <String>{};
    for (final log in logs) {
      fields.addAll(log.keys);
    }
    return fields;
  }

  /// Calculate export file size estimate (in bytes)
  static int estimateFileSize(
    List<Map<String, dynamic>> logs,
    ExportFormat format,
  ) {
    if (logs.isEmpty) return 0;

    switch (format) {
      case ExportFormat.csv:
        // Rough estimate: average row length * number of rows
        return logs.length * 200;
      case ExportFormat.json:
        // JSON is typically larger than CSV
        return logs.length * 300;
      case ExportFormat.text:
        // Text format with headers and formatting
        return logs.length * 250;
    }
  }
}
