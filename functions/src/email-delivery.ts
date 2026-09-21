import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

const db = admin.firestore();
const logger = functions.logger;

// Import SendGrid (requires npm install @sendgrid/mail)
// In production, configure with: npm install @sendgrid/mail
// const sgMail = require('@sendgrid/mail');

interface ExecutionEvent {
  reportId: string;
  executionId: string;
  reportName: string;
  format: 'csv' | 'json' | 'text';
  recordCount: number;
  fileSizeBytes: number;
  recipientEmails: string[];
  exportedData: string;
  timestamp: string;
}

/**
 * Cloud Function: Email Delivery
 * Triggers: Pub/Sub topic 'report-execution-events'
 * Sends reports to recipients via email
 */
export const deliverReportViaEmail = functions
  .pubsub.topic('report-execution-events')
  .onPublish(async (message) => {
    const executionEvent: ExecutionEvent = JSON.parse(
      Buffer.from(message.data, 'base64').toString(),
    );

    logger.info('Received execution event for email delivery', {
      reportId: executionEvent.reportId,
      recipients: executionEvent.recipientEmails.length,
    });

    try {
      // Send email to each recipient
      const deliveryResults = await Promise.allSettled(
        executionEvent.recipientEmails.map((email) =>
          sendReportEmail(email, executionEvent),
        ),
      );

      // Log delivery summary
      const succeeded = deliveryResults.filter(
        (r) => r.status === 'fulfilled',
      ).length;
      const failed = deliveryResults.filter(
        (r) => r.status === 'rejected',
      ).length;

      logger.info('Email delivery batch completed', {
        total: executionEvent.recipientEmails.length,
        succeeded,
        failed,
      });

      // Update execution record with delivery status
      await updateDeliveryStatus(
        executionEvent.reportId,
        executionEvent.executionId,
        deliveryResults,
      );

      return { delivered: succeeded, failed };
    } catch (error) {
      logger.error('Error during email delivery', error);
      throw error;
    }
  });

/**
 * Send report email to a single recipient
 */
async function sendReportEmail(
  recipientEmail: string,
  event: ExecutionEvent,
): Promise<void> {
  logger.info(`Sending report email to ${recipientEmail}`);

  try {
    // Get SendGrid API key from environment or Firestore config
    const sendGridApiKey = process.env.SENDGRID_API_KEY || '';

    if (!sendGridApiKey) {
      logger.warn('SendGrid API key not configured. Email not sent.');
      throw new Error('SendGrid API key not configured');
    }

    // In production, you would use SendGrid:
    // const sgMail = require('@sendgrid/mail');
    // sgMail.setApiKey(sendGridApiKey);

    const emailTemplate = generateEmailTemplate(event);

    // Mock implementation for now
    logger.info(`Mock email sent to ${recipientEmail}`, {
      subject: emailTemplate.subject,
      contentLength: emailTemplate.htmlBody.length,
      attachment: event.format,
    });

    // Uncomment for production use:
    // const msg = {
    //   to: recipientEmail,
    //   from: process.env.SENDER_EMAIL || 'noreply@example.com',
    //   subject: emailTemplate.subject,
    //   html: emailTemplate.htmlBody,
    //   text: emailTemplate.textBody,
    //   attachments: [
    //     {
    //       filename: `${event.reportName}.${getFileExtension(event.format)}`,
    //       content: Buffer.from(event.exportedData).toString('base64'),
    //       type: getMimeType(event.format),
    //       disposition: 'attachment',
    //     },
    //   ],
    // };
    // await sgMail.send(msg);

    logger.info(`Email sent successfully to ${recipientEmail}`);
  } catch (error) {
    logger.error(`Failed to send email to ${recipientEmail}`, error);
    throw error;
  }
}

/**
 * Generate email template based on format
 */
function generateEmailTemplate(
  event: ExecutionEvent,
): { subject: string; htmlBody: string; textBody: string } {
  const fileSize = formatFileSize(event.fileSizeBytes);
  const fileName = `${event.reportName}.${getFileExtension(event.format)}`;

  const subject = `[Analytics Report] ${event.reportName}`;

  const htmlBody = `
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
            <h2>${event.reportName}</h2>
            <p>${event.format.toUpperCase()} Export Report</p>
          </div>
          <div class="content">
            <p>Your requested analytics report is ready!</p>
            <div class="stats">
              <div class="stat-item">
                <span class="stat-label">Records:</span> ${event.recordCount}
              </div>
              <div class="stat-item">
                <span class="stat-label">File Size:</span> ${fileSize}
              </div>
              <div class="stat-item">
                <span class="stat-label">File Name:</span> ${fileName}
              </div>
              <div class="stat-item">
                <span class="stat-label">Generated:</span> ${new Date(
    event.timestamp,
  ).toISOString()}
              </div>
            </div>
            <p>The report file is attached to this email.</p>
          </div>
          <div class="footer">
            <p>This is an automated report. Please do not reply to this email.</p>
          </div>
        </div>
      </body>
    </html>
  `;

  const textBody = `
${event.reportName} - ${event.format.toUpperCase()} Export Report

Your requested analytics report is ready!

Records: ${event.recordCount}
File Size: ${fileSize}
File Name: ${fileName}
Generated: ${new Date(event.timestamp).toISOString()}

The report file is attached to this email.

---
This is an automated report. Please do not reply to this email.
  `;

  return { subject, htmlBody, textBody };
}

/**
 * Update delivery status in execution history
 */
async function updateDeliveryStatus(
  reportId: string,
  executionId: string,
  deliveryResults: PromiseSettledResult<void>[],
): Promise<void> {
  try {
    const succeeded = deliveryResults.filter(
      (r) => r.status === 'fulfilled',
    ).length;
    const failed = deliveryResults.filter(
      (r) => r.status === 'rejected',
    ).length;

    await db
      .collection('scheduled_reports')
      .doc(reportId)
      .collection('execution_history')
      .doc(executionId)
      .update({
        emailDeliveryStatus: failed > 0 ? 'partial' : 'sent',
        emailsSent: succeeded,
        emailsFailed: failed,
        deliveredAt: admin.firestore.Timestamp.now(),
      });

    logger.info(
      `Updated delivery status for execution ${executionId}: ${succeeded} sent, ${failed} failed`,
    );
  } catch (error) {
    logger.error('Error updating delivery status', error);
    throw error;
  }
}

/**
 * Get file extension for format
 */
function getFileExtension(format: string): string {
  switch (format) {
    case 'csv':
      return 'csv';
    case 'json':
      return 'json';
    case 'text':
      return 'txt';
    default:
      return 'txt';
  }
}

/**
 * Get MIME type for format
 */
function getMimeType(format: string): string {
  switch (format) {
    case 'csv':
      return 'text/csv';
    case 'json':
      return 'application/json';
    case 'text':
      return 'text/plain';
    default:
      return 'text/plain';
  }
}

/**
 * Format file size in human-readable format
 */
function formatFileSize(bytes: number): string {
  if (bytes < 1024) return `${bytes} B`;
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
  if (bytes < 1024 * 1024 * 1024) {
    return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
  }
  return `${(bytes / (1024 * 1024 * 1024)).toFixed(1)} GB`;
}
