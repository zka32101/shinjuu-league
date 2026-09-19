/// Email service for report delivery configuration
class EmailConfig {
  final String senderEmail;
  final String senderName;
  final String sendGridApiKey;
  final bool enabled;

  const EmailConfig({
    required this.senderEmail,
    required this.senderName,
    this.sendGridApiKey = '',
    this.enabled = false,
  });

  bool get isConfigured => enabled && sendGridApiKey.isNotEmpty;
}

/// Email template for reports
class EmailTemplate {
  final String subject;
  final String htmlBody;
  final String textBody;
  final String? attachmentFileName;
  final String? attachmentContent;
  final String? attachmentMimeType;

  const EmailTemplate({
    required this.subject,
    required this.htmlBody,
    required this.textBody,
    this.attachmentFileName,
    this.attachmentContent,
    this.attachmentMimeType,
  });

  Map<String, dynamic> toJson() {
    return {
      'subject': subject,
      'htmlBody': htmlBody,
      'textBody': textBody,
      if (attachmentFileName != null) 'attachmentFileName': attachmentFileName,
      if (attachmentContent != null) 'attachmentContent': attachmentContent,
      if (attachmentMimeType != null) 'attachmentMimeType': attachmentMimeType,
    };
  }
}

/// Email delivery record
class EmailDeliveryRecord {
  final String id;
  final String reportId;
  final String recipientEmail;
  final String subject;
  final bool success;
  final String? errorMessage;
  final DateTime sentAt;
  final int? retryCount;

  const EmailDeliveryRecord({
    required this.id,
    required this.reportId,
    required this.recipientEmail,
    required this.subject,
    required this.success,
    this.errorMessage,
    required this.sentAt,
    this.retryCount,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reportId': reportId,
      'recipientEmail': recipientEmail,
      'subject': subject,
      'success': success,
      'errorMessage': errorMessage,
      'sentAt': sentAt.toIso8601String(),
      'retryCount': retryCount,
    };
  }

  factory EmailDeliveryRecord.fromJson(Map<String, dynamic> json) {
    return EmailDeliveryRecord(
      id: json['id'] as String,
      reportId: json['reportId'] as String,
      recipientEmail: json['recipientEmail'] as String,
      subject: json['subject'] as String,
      success: json['success'] as bool,
      errorMessage: json['errorMessage'] as String?,
      sentAt: DateTime.parse(json['sentAt'] as String),
      retryCount: json['retryCount'] as int?,
    );
  }
}

/// Email service for sending reports
class EmailService {
  static const String defaultSenderName = 'Analytics Reports';
  static const String defaultSubjectPrefix = '[Analytics Report]';

  final EmailConfig config;

  EmailService({required this.config});

  /// Generate email template for CSV report
  EmailTemplate generateCSVEmailTemplate({
    required String reportName,
    required int recordCount,
    required int fileSizeBytes,
    required String fileName,
  }) {
    final fileSize = _formatFileSize(fileSizeBytes);

    return EmailTemplate(
      subject: '$defaultSubjectPrefix $reportName',
      htmlBody: '''
      <html>
        <head>
          <style>
            body { font-family: Arial, sans-serif; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background-color: #f0f0f0; padding: 10px; border-radius: 5px; }
            .content { margin: 20px 0; }
            .stats { background-color: #f9f9f9; padding: 15px; border-left: 4px solid #4CAF50; }
            .stat-item { margin: 8px 0; }
            .stat-label { font-weight: bold; }
            .footer { font-size: 12px; color: #999; margin-top: 20px; }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="header">
              <h2>$reportName</h2>
              <p>CSV Export Report</p>
            </div>
            <div class="content">
              <p>Your requested analytics report is ready!</p>
              <div class="stats">
                <div class="stat-item">
                  <span class="stat-label">Records:</span> $recordCount
                </div>
                <div class="stat-item">
                  <span class="stat-label">File Size:</span> $fileSize
                </div>
                <div class="stat-item">
                  <span class="stat-label">File Name:</span> $fileName
                </div>
                <div class="stat-item">
                  <span class="stat-label">Generated:</span> ${DateTime.now().toIso8601String()}
                </div>
              </div>
              <p>The CSV file is attached to this email. You can open it with any spreadsheet application.</p>
            </div>
            <div class="footer">
              <p>This is an automated report. Please do not reply to this email.</p>
            </div>
          </div>
        </body>
      </html>
      ''',
      textBody: '''
$reportName - CSV Export Report

Your requested analytics report is ready!

Records: $recordCount
File Size: $fileSize
File Name: $fileName
Generated: ${DateTime.now().toIso8601String()}

The CSV file is attached to this email. You can open it with any spreadsheet application.

---
This is an automated report. Please do not reply to this email.
      ''',
    );
  }

  /// Generate email template for JSON report
  EmailTemplate generateJSONEmailTemplate({
    required String reportName,
    required int recordCount,
    required int fileSizeBytes,
    required String fileName,
  }) {
    final fileSize = _formatFileSize(fileSizeBytes);

    return EmailTemplate(
      subject: '$defaultSubjectPrefix $reportName',
      htmlBody: '''
      <html>
        <head>
          <style>
            body { font-family: Arial, sans-serif; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background-color: #f0f0f0; padding: 10px; border-radius: 5px; }
            .content { margin: 20px 0; }
            .stats { background-color: #f9f9f9; padding: 15px; border-left: 4px solid #2196F3; }
            .stat-item { margin: 8px 0; }
            .stat-label { font-weight: bold; }
            .footer { font-size: 12px; color: #999; margin-top: 20px; }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="header">
              <h2>$reportName</h2>
              <p>JSON Export Report</p>
            </div>
            <div class="content">
              <p>Your requested analytics report is ready!</p>
              <div class="stats">
                <div class="stat-item">
                  <span class="stat-label">Records:</span> $recordCount
                </div>
                <div class="stat-item">
                  <span class="stat-label">File Size:</span> $fileSize
                </div>
                <div class="stat-item">
                  <span class="stat-label">File Name:</span> $fileName
                </div>
                <div class="stat-item">
                  <span class="stat-label">Generated:</span> ${DateTime.now().toIso8601String()}
                </div>
              </div>
              <p>The JSON file is attached to this email. Use any JSON parser or text editor to view the data.</p>
            </div>
            <div class="footer">
              <p>This is an automated report. Please do not reply to this email.</p>
            </div>
          </div>
        </body>
      </html>
      ''',
      textBody: '''
$reportName - JSON Export Report

Your requested analytics report is ready!

Records: $recordCount
File Size: $fileSize
File Name: $fileName
Generated: ${DateTime.now().toIso8601String()}

The JSON file is attached to this email. Use any JSON parser or text editor to view the data.

---
This is an automated report. Please do not reply to this email.
      ''',
    );
  }

  /// Generate email template for text report
  EmailTemplate generateTextEmailTemplate({
    required String reportName,
    required int recordCount,
    required int fileSizeBytes,
    required String fileName,
  }) {
    final fileSize = _formatFileSize(fileSizeBytes);

    return EmailTemplate(
      subject: '$defaultSubjectPrefix $reportName',
      htmlBody: '''
      <html>
        <head>
          <style>
            body { font-family: Arial, sans-serif; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background-color: #f0f0f0; padding: 10px; border-radius: 5px; }
            .content { margin: 20px 0; }
            .stats { background-color: #f9f9f9; padding: 15px; border-left: 4px solid #FF9800; }
            .stat-item { margin: 8px 0; }
            .stat-label { font-weight: bold; }
            .footer { font-size: 12px; color: #999; margin-top: 20px; }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="header">
              <h2>$reportName</h2>
              <p>Text Format Report</p>
            </div>
            <div class="content">
              <p>Your requested analytics report is ready!</p>
              <div class="stats">
                <div class="stat-item">
                  <span class="stat-label">Records:</span> $recordCount
                </div>
                <div class="stat-item">
                  <span class="stat-label">File Size:</span> $fileSize
                </div>
                <div class="stat-item">
                  <span class="stat-label">File Name:</span> $fileName
                </div>
                <div class="stat-item">
                  <span class="stat-label">Generated:</span> ${DateTime.now().toIso8601String()}
                </div>
              </div>
              <p>The text file is attached to this email. Open it with any text editor to view the formatted data.</p>
            </div>
            <div class="footer">
              <p>This is an automated report. Please do not reply to this email.</p>
            </div>
          </div>
        </body>
      </html>
      ''',
      textBody: '''
$reportName - Text Format Report

Your requested analytics report is ready!

Records: $recordCount
File Size: $fileSize
File Name: $fileName
Generated: ${DateTime.now().toIso8601String()}

The text file is attached to this email. Open it with any text editor to view the formatted data.

---
This is an automated report. Please do not reply to this email.
      ''',
    );
  }

  /// Generate execution failure notification
  EmailTemplate generateFailureNotificationTemplate({
    required String reportName,
    required String errorMessage,
    required String? nextRetryTime,
  }) {
    return EmailTemplate(
      subject: '$defaultSubjectPrefix FAILED - $reportName',
      htmlBody: '''
      <html>
        <head>
          <style>
            body { font-family: Arial, sans-serif; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background-color: #ffebee; padding: 10px; border-radius: 5px; }
            .content { margin: 20px 0; }
            .error { background-color: #ffcdd2; padding: 15px; border-left: 4px solid #f44336; }
            .footer { font-size: 12px; color: #999; margin-top: 20px; }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="header">
              <h2>Report Execution Failed</h2>
              <p>$reportName</p>
            </div>
            <div class="content">
              <p>Unfortunately, the scheduled report execution failed.</p>
              <div class="error">
                <p><strong>Error:</strong> $errorMessage</p>
              </div>
              ${nextRetryTime != null ? '<p><strong>Next Retry:</strong> $nextRetryTime</p>' : '<p>No automatic retry is scheduled.</p>'}
            </div>
            <div class="footer">
              <p>This is an automated notification. Please do not reply to this email.</p>
            </div>
          </div>
        </body>
      </html>
      ''',
      textBody: '''
Report Execution Failed

$reportName

Unfortunately, the scheduled report execution failed.

Error: $errorMessage

${nextRetryTime != null ? 'Next Retry: $nextRetryTime' : 'No automatic retry is scheduled.'}

---
This is an automated notification. Please do not reply to this email.
      ''',
    );
  }

  /// Check if email service is ready
  bool get isReady => config.isConfigured;

  /// Format file size in human-readable format
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
