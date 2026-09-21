import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { PubSub } from '@google-cloud/pubsub';

const db = admin.firestore();
const logger = functions.logger;
const pubsub = new PubSub();

interface ScheduledReport {
  id: string;
  name: string;
  userId: string;
  format: 'csv' | 'json' | 'text';
  selectedFields: string[];
  frequency: 'once' | 'daily' | 'weekly' | 'monthly';
  recipientEmails: string[];
  includeMetadata: boolean;
  createdAt: FirebaseFirestore.Timestamp;
  lastExecutedAt?: FirebaseFirestore.Timestamp;
  nextExecutionAt?: FirebaseFirestore.Timestamp;
  isActive: boolean;
}

interface AuditLog {
  timestamp: string;
  userId: string;
  action: string;
  resourceType: string;
  resourceId: string;
  [key: string]: any;
}

/**
 * Cloud Function: Execute scheduled reports
 * Triggers: Pub/Sub every hour to check for due reports
 * Firestore trigger: Monitors scheduled_reports collection
 */
export const executeScheduledReports = functions
  .pubsub.schedule('0 * * * *') // Every hour
  .timeZone('America/New_York')
  .onRun(async (context) => {
    logger.info('Starting scheduled report execution check', { timestamp: new Date().toISOString() });

    try {
      // Get all active reports with nextExecutionAt <= now
      const now = new Date();
      const reportsSnapshot = await db
        .collection('scheduled_reports')
        .where('isActive', '==', true)
        .where('nextExecutionAt', '<=', now)
        .get();

      logger.info(`Found ${reportsSnapshot.docs.length} reports due for execution`);

      // Process each report
      const results = await Promise.allSettled(
        reportsSnapshot.docs.map((doc) =>
          executeReport(doc.id, doc.data() as ScheduledReport),
        ),
      );

      // Log execution summary
      const succeeded = results.filter((r) => r.status === 'fulfilled').length;
      const failed = results.filter((r) => r.status === 'rejected').length;

      logger.info('Report execution batch completed', {
        total: results.length,
        succeeded,
        failed,
      });

      return { processed: results.length, succeeded, failed };
    } catch (error) {
      logger.error('Error during report execution check', error);
      throw error;
    }
  });

/**
 * Execute a single scheduled report
 */
async function executeReport(reportId: string, report: ScheduledReport): Promise<void> {
  logger.info(`Executing report: ${report.name} (${reportId})`);

  try {
    // Fetch audit logs for the report
    const logs = await fetchAuditLogs(report);
    logger.info(`Fetched ${logs.length} audit log records`);

    // Generate export based on format
    const exportedData = generateExport(logs, report);
    const fileSizeBytes = Buffer.byteLength(exportedData);

    logger.info(`Generated export: ${exportedData.length} characters, ${fileSizeBytes} bytes`);

    // Create execution record
    const executionId = db.collection('temp').doc().id;
    const executionRecord = {
      id: executionId,
      reportId: reportId,
      executedAt: admin.firestore.Timestamp.now(),
      success: true,
      recordCount: logs.length,
      fileSizeBytes: fileSizeBytes,
      sentToEmails: report.recipientEmails,
    };

    // Save execution record
    await db
      .collection('scheduled_reports')
      .doc(reportId)
      .collection('execution_history')
      .doc(executionId)
      .set(executionRecord);

    logger.info(`Saved execution record: ${executionId}`);

    // Update report with last execution time and next execution time
    const nextExecution = calculateNextExecution(report.frequency, new Date());

    await db.collection('scheduled_reports').doc(reportId).update({
      lastExecutedAt: admin.firestore.Timestamp.now(),
      nextExecutionAt: admin.firestore.Timestamp.fromDate(nextExecution),
    });

    logger.info(`Updated report execution times. Next: ${nextExecution.toISOString()}`);

    // Publish execution event for email delivery
    const topic = pubsub.topic('report-execution-events');
    await topic.publishMessage({
      data: Buffer.from(
        JSON.stringify({
          reportId: reportId,
          executionId: executionId,
          reportName: report.name,
          format: report.format,
          recordCount: logs.length,
          fileSizeBytes: fileSizeBytes,
          recipientEmails: report.recipientEmails,
          exportedData: exportedData,
          timestamp: new Date().toISOString(),
        }),
      ),
    });

    logger.info(`Published execution event for ${reportId}`);
  } catch (error) {
    logger.error(`Error executing report ${reportId}`, error);

    // Record failed execution
    const executionId = db.collection('temp').doc().id;
    const failedRecord = {
      id: executionId,
      reportId: reportId,
      executedAt: admin.firestore.Timestamp.now(),
      success: false,
      errorMessage: error instanceof Error ? error.message : 'Unknown error',
      recordCount: 0,
      fileSizeBytes: 0,
      sentToEmails: [],
    };

    await db
      .collection('scheduled_reports')
      .doc(reportId)
      .collection('execution_history')
      .doc(executionId)
      .set(failedRecord);

    logger.error(`Saved failed execution record for ${reportId}`);

    // Increment retry count
    const reportRef = db.collection('scheduled_reports').doc(reportId);
    await reportRef.update({
      retryCount: admin.firestore.FieldValue.increment(1),
    });

    throw error;
  }
}

/**
 * Fetch audit logs for export
 */
async function fetchAuditLogs(report: ScheduledReport): Promise<AuditLog[]> {
  try {
    // Query audit logs collection
    // In a real implementation, you might want to filter by date range
    // based on report.lastExecutedAt
    const logsSnapshot = await db.collection('audit_logs').limit(1000).get();

    return logsSnapshot.docs.map(
      (doc) =>
        ({
          id: doc.id,
          ...doc.data(),
        }) as unknown as AuditLog,
    );
  } catch (error) {
    logger.error('Error fetching audit logs', error);
    throw error;
  }
}

/**
 * Generate export in requested format
 */
function generateExport(logs: AuditLog[], report: ScheduledReport): string {
  switch (report.format) {
    case 'csv':
      return generateCSV(logs, report);
    case 'json':
      return generateJSON(logs, report);
    case 'text':
      return generateText(logs, report);
    default:
      throw new Error(`Unsupported format: ${report.format}`);
  }
}

/**
 * Generate CSV export
 */
function generateCSV(logs: AuditLog[], report: ScheduledReport): string {
  const fields = report.selectedFields;
  const rows: string[] = [];

  // Header row
  rows.push(fields.join(','));

  // Data rows
  for (const log of logs) {
    const values = fields.map((field) => {
      const value = log[field];
      if (value === null || value === undefined) return '';

      const stringValue = String(value);
      // Escape CSV values
      if (stringValue.includes(',') || stringValue.includes('"')) {
        return `"${stringValue.replace(/"/g, '""')}"`;
      }
      return stringValue;
    });

    rows.push(values.join(','));
  }

  // Metadata
  if (report.includeMetadata) {
    rows.push('');
    rows.push('# Export Metadata');
    rows.push(`# Total Records: ${logs.length}`);
    rows.push(`# Export Date: ${new Date().toISOString()}`);
    rows.push(`# Fields: ${fields.join(', ')}`);
  }

  return rows.join('\n');
}

/**
 * Generate JSON export
 */
function generateJSON(logs: AuditLog[], report: ScheduledReport): string {
  const selectedLogs = logs.map((log) => {
    const filtered: { [key: string]: any } = {};
    for (const field of report.selectedFields) {
      if (field in log) {
        filtered[field] = log[field];
      }
    }
    return filtered;
  });

  const exportData: { [key: string]: any } = {};

  if (report.includeMetadata) {
    exportData.metadata = {
      exportDate: new Date().toISOString(),
      totalRecords: logs.length,
      selectedFields: report.selectedFields,
    };
  }

  exportData.data = selectedLogs;

  return JSON.stringify(exportData, null, 2);
}

/**
 * Generate text export
 */
function generateText(logs: AuditLog[], report: ScheduledReport): string {
  const lines: string[] = [];

  // Header
  lines.push('='.repeat(80));
  lines.push('ANALYTICS EXPORT REPORT');
  lines.push(`Generated: ${new Date().toISOString()}`);
  lines.push(`Total Records: ${logs.length}`);
  lines.push('='.repeat(80));
  lines.push('');

  // Data
  logs.forEach((log, index) => {
    lines.push(`Record #${index + 1}`);
    lines.push('-'.repeat(40));

    for (const field of report.selectedFields) {
      if (field in log) {
        const value = log[field] ?? 'N/A';
        lines.push(`${field}: ${value}`);
      }
    }

    lines.push('');
  });

  // Summary
  if (report.includeMetadata) {
    lines.push('='.repeat(80));
    lines.push('SUMMARY');
    lines.push('='.repeat(80));
    lines.push(`Total Records Exported: ${logs.length}`);
    lines.push(`Export Fields: ${report.selectedFields.join(', ')}`);
  }

  return lines.join('\n');
}

/**
 * Calculate next execution time based on frequency
 */
export function calculateNextExecution(
  frequency: 'once' | 'daily' | 'weekly' | 'monthly',
  from: Date,
): Date {
  const next = new Date(from);

  switch (frequency) {
    case 'once':
      // Far future - report is one-time only
      next.setFullYear(next.getFullYear() + 1);
      break;
    case 'daily':
      next.setDate(next.getDate() + 1);
      break;
    case 'weekly':
      next.setDate(next.getDate() + 7);
      break;
    case 'monthly': {
      // A naive next.setMonth(next.getMonth() + 1) overflows for a day that
      // doesn't exist in the target month (e.g. Jan 31 -> "Feb 31" rolls
      // over to Mar 3 instead of clamping to Feb 28/29), silently skipping
      // that month's execution. Advance the month from the 1st, then clamp
      // the original day-of-month to the target month's actual length.
      const originalDay = next.getDate();
      const targetMonth = next.getMonth() + 1;
      next.setDate(1);
      next.setMonth(targetMonth);
      const daysInTargetMonth = new Date(
        next.getFullYear(),
        next.getMonth() + 1,
        0,
      ).getDate();
      next.setDate(Math.min(originalDay, daysInTargetMonth));
      break;
    }
  }

  return next;
}
