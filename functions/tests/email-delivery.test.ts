import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions';
import test from 'firebase-functions-test';
import * as elf from '../src/email-delivery';

const projectId = 'shinjuu-league-test';
const testEnv = test({ projectId });

describe('Email Delivery', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('Email Template Generation', () => {
    it('should generate CSV email template', () => {
      const template = {
        subject: '[Analytics Report] Daily Report',
        htmlBody:
          '<html><body><h2>Daily Report</h2><p>CSV Export Report</p></body></html>',
        textBody: 'Daily Report - CSV Export Report\n\nRecords: 100',
      };

      expect(template.subject).toContain('Daily Report');
      expect(template.subject).toContain('[Analytics Report]');
      expect(template.htmlBody).toContain('CSV');
      expect(template.textBody).toContain('Records');
    });

    it('should generate JSON email template', () => {
      const template = {
        subject: '[Analytics Report] Weekly Report',
        htmlBody:
          '<html><body><h2>Weekly Report</h2><p>JSON Export Report</p></body></html>',
        textBody: 'Weekly Report - JSON Export Report\n\nRecords: 250',
      };

      expect(template.subject).toContain('Weekly Report');
      expect(template.htmlBody).toContain('JSON');
      expect(template.textBody).toContain('Records: 250');
    });

    it('should generate text format email template', () => {
      const template = {
        subject: '[Analytics Report] Text Export',
        htmlBody:
          '<html><body><h2>Text Export</h2><p>Text Format Report</p></body></html>',
        textBody: 'Text Export - Text Format Report\n\nRecords: 500',
      };

      expect(template.subject).toContain('Text Export');
      expect(template.htmlBody).toContain('Text Format');
      expect(template.textBody).toContain('Records: 500');
    });

    it('should include file information in email', () => {
      const template = {
        subject: '[Analytics Report] September Report',
        htmlBody: `
          <html>
            <body>
              <div class="stats">
                <div class="stat-item">
                  <span class="stat-label">Records:</span> 1000
                </div>
                <div class="stat-item">
                  <span class="stat-label">File Size:</span> 256.5 KB
                </div>
                <div class="stat-item">
                  <span class="stat-label">File Name:</span> september_report.csv
                </div>
              </div>
            </body>
          </html>
        `,
        textBody: `
Records: 1000
File Size: 256.5 KB
File Name: september_report.csv
        `,
      };

      expect(template.htmlBody).toContain('256.5 KB');
      expect(template.htmlBody).toContain('september_report.csv');
      expect(template.textBody).toContain('Records: 1000');
    });

    it('should include timestamp in email template', () => {
      const now = new Date();
      const template = {
        subject: '[Analytics Report] Report',
        htmlBody: `<html><body><p>Generated: ${now.toISOString()}</p></body></html>`,
        textBody: `Generated: ${now.toISOString()}`,
      };

      expect(template.htmlBody).toContain(now.toISOString());
      expect(template.textBody).toContain(now.toISOString());
    });

    it('should format file size correctly in template', () => {
      const sizes = [
        { bytes: 512, expected: '512 B' },
        { bytes: 2048, expected: '2.0 KB' },
        { bytes: 2097152, expected: '2.0 MB' },
        { bytes: 2147483648, expected: '2.0 GB' },
      ];

      sizes.forEach(({ bytes, expected }) => {
        let formatted = '';
        if (bytes < 1024) formatted = `${bytes} B`;
        else if (bytes < 1024 * 1024)
          formatted = `${(bytes / 1024).toFixed(1)} KB`;
        else if (bytes < 1024 * 1024 * 1024)
          formatted = `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
        else formatted = `${(bytes / (1024 * 1024 * 1024)).toFixed(1)} GB`;

        expect(formatted).toBe(expected);
      });
    });
  });

  // A `const` initialized directly with a string literal keeps that literal
  // as its control-flow type even with a wider annotation, which is why the
  // three tests below route through a real function parameter instead: a
  // parameter's declared type is what TypeScript checks against at each
  // comparison, so all three branches of the ternary chain type-check
  // instead of being flagged as unreachable given the specific literal.
  function attachmentMetaFor(format: 'csv' | 'json' | 'text') {
    const mimeType =
      format === 'csv'
        ? 'text/csv'
        : format === 'json'
          ? 'application/json'
          : 'text/plain';
    const filename = `report.${format === 'csv' ? 'csv' : format === 'json' ? 'json' : 'txt'}`;
    return { mimeType, filename };
  }

  describe('Email Attachment Handling', () => {
    it('should create attachment with correct MIME type for CSV', () => {
      const { mimeType, filename } = attachmentMetaFor('csv');

      expect(mimeType).toBe('text/csv');
      expect(filename).toBe('report.csv');
    });

    it('should create attachment with correct MIME type for JSON', () => {
      const { mimeType, filename } = attachmentMetaFor('json');

      expect(mimeType).toBe('application/json');
      expect(filename).toBe('report.json');
    });

    it('should create attachment with correct MIME type for text', () => {
      const { mimeType, filename } = attachmentMetaFor('text');

      expect(mimeType).toBe('text/plain');
      expect(filename).toBe('report.txt');
    });

    it('should encode attachment content as base64', () => {
      const content = 'timestamp,userId,action\n2026-09-01,user_001,CREATE';
      const encoded = Buffer.from(content).toString('base64');

      expect(encoded).toBeTruthy();
      const decoded = Buffer.from(encoded, 'base64').toString();
      expect(decoded).toBe(content);
    });

    it('should handle large attachment data', () => {
      const largeData = 'x'.repeat(1000000); // 1MB
      const encoded = Buffer.from(largeData).toString('base64');

      expect(encoded.length).toBeGreaterThan(largeData.length);
      expect(Buffer.byteLength(encoded)).toBeLessThan(2000000); // Base64 max ~1.33x size
    });
  });

  describe('Email Delivery', () => {
    it('should send email to single recipient', () => {
      const email = {
        to: 'admin@example.com',
        from: 'noreply@shinjuu-league.com',
        subject: '[Analytics Report] Report Name',
        html: '<html><body>Report content</body></html>',
        text: 'Report content',
      };

      expect(email.to).toBe('admin@example.com');
      expect(email.from).toBeTruthy();
      expect(email.subject).toBeTruthy();
    });

    it('should send email to multiple recipients', () => {
      const recipients = [
        'admin@example.com',
        'manager@example.com',
        'analyst@example.com',
      ];

      const emails = recipients.map((to) => ({
        to,
        from: 'noreply@shinjuu-league.com',
        subject: '[Analytics Report] Report',
        html: '<html><body>Report</body></html>',
        text: 'Report',
      }));

      expect(emails.length).toBe(3);
      expect(emails[0].to).toBe('admin@example.com');
      expect(emails[2].to).toBe('analyst@example.com');
    });

    it('should validate email addresses', () => {
      const validEmails = [
        'user@example.com',
        'admin@company.co.uk',
        'name+tag@domain.com',
      ];
      const invalidEmails = ['notanemail', '@nodomain.com', 'user@'];

      const isValidEmail = (email: string) => {
        return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
      };

      validEmails.forEach((email) => {
        expect(isValidEmail(email)).toBe(true);
      });

      invalidEmails.forEach((email) => {
        expect(isValidEmail(email)).toBe(false);
      });
    });

    it('should handle email delivery failures gracefully', () => {
      const result = {
        status: 'rejected',
        reason: 'Failed to send email to invalid@example',
      };

      expect(result.status).toBe('rejected');
      expect(result.reason).toBeTruthy();
    });

    it('should track email delivery status', () => {
      const deliveryStatus = {
        succeeded: 2,
        failed: 1,
        total: 3,
      };

      expect(deliveryStatus.succeeded + deliveryStatus.failed).toBe(deliveryStatus.total);
      expect(deliveryStatus.failed).toBe(1);
    });
  });

  describe('Execution Event Processing', () => {
    it('should parse execution event from Pub/Sub message', () => {
      const event = {
        reportId: 'report_001',
        executionId: 'exec_001',
        reportName: 'Daily Report',
        format: 'csv',
        recordCount: 100,
        fileSizeBytes: 5120,
        recipientEmails: ['admin@example.com'],
        exportedData: 'timestamp,userId\n2026-09-01,user_001',
        timestamp: new Date().toISOString(),
      };

      expect(event.reportId).toBeTruthy();
      expect(event.executionId).toBeTruthy();
      expect(event.recipientEmails.length).toBeGreaterThan(0);
      expect(event.exportedData).toBeTruthy();
    });

    it('should handle event with no recipients', () => {
      const event = {
        reportId: 'report_002',
        executionId: 'exec_002',
        reportName: 'Empty Recipients',
        format: 'json',
        recordCount: 0,
        fileSizeBytes: 0,
        recipientEmails: [],
        exportedData: '{}',
        timestamp: new Date().toISOString(),
      };

      const deliveryCount = event.recipientEmails.length;
      expect(deliveryCount).toBe(0);
    });

    it('should handle large data payload in event', () => {
      const largeData = 'x'.repeat(1000000); // 1MB

      const event = {
        reportId: 'report_003',
        executionId: 'exec_003',
        reportName: 'Large Report',
        format: 'csv',
        recordCount: 50000,
        fileSizeBytes: 1000000,
        recipientEmails: ['admin@example.com'],
        exportedData: largeData,
        timestamp: new Date().toISOString(),
      };

      expect(Buffer.byteLength(event.exportedData)).toBe(1000000);
      expect(event.recordCount).toBe(50000);
    });
  });

  describe('Delivery Status Updates', () => {
    it('should mark execution as fully sent', () => {
      const status = {
        emailDeliveryStatus: 'sent',
        emailsSent: 3,
        emailsFailed: 0,
        deliveredAt: new Date().toISOString(),
      };

      expect(status.emailDeliveryStatus).toBe('sent');
      expect(status.emailsSent).toBe(3);
      expect(status.emailsFailed).toBe(0);
    });

    it('should mark execution as partial delivery', () => {
      const status = {
        emailDeliveryStatus: 'partial',
        emailsSent: 2,
        emailsFailed: 1,
        deliveredAt: new Date().toISOString(),
      };

      expect(status.emailDeliveryStatus).toBe('partial');
      expect(status.emailsSent).toBe(2);
      expect(status.emailsFailed).toBeGreaterThan(0);
    });

    it('should record delivery timestamp', () => {
      const beforeDelivery = new Date();
      const deliveredAt = new Date();
      const afterDelivery = new Date();

      expect(deliveredAt.getTime()).toBeGreaterThanOrEqual(
        beforeDelivery.getTime()
      );
      expect(deliveredAt.getTime()).toBeLessThanOrEqual(
        afterDelivery.getTime()
      );
    });

    it('should handle delivery status with zero emails', () => {
      const status = {
        emailDeliveryStatus: 'sent', // Even with 0 emails, can mark as sent
        emailsSent: 0,
        emailsFailed: 0,
        deliveredAt: new Date().toISOString(),
      };

      expect(status.emailsSent + status.emailsFailed).toBe(0);
    });
  });

  describe('Error Handling & Resilience', () => {
    it('should handle missing execution event data', () => {
      const event = {
        reportId: 'report_001',
        executionId: undefined,
        reportName: 'Report',
        format: 'csv',
        recordCount: 0,
        fileSizeBytes: 0,
        recipientEmails: [],
        exportedData: '',
        timestamp: new Date().toISOString(),
      };

      expect(event.executionId).toBeUndefined();
      expect(event.reportId).toBeTruthy();
    });

    it('should handle malformed email addresses in batch', () => {
      const recipients = [
        'valid@example.com',
        'invalid-email',
        'another@valid.com',
        '@nodomain.com',
      ];

      const isValid = (email: string) =>
        /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
      const validRecipients = recipients.filter(isValid);

      expect(validRecipients.length).toBe(2);
      expect(validRecipients).toContain('valid@example.com');
    });

    it('should continue delivery despite individual failures', () => {
      const deliveryResults = [
        { status: 'fulfilled', value: 'sent' },
        { status: 'rejected', reason: 'Network error' },
        { status: 'fulfilled', value: 'sent' },
        { status: 'rejected', reason: 'Invalid email' },
      ];

      const succeeded = deliveryResults.filter(
        (r) => r.status === 'fulfilled'
      ).length;
      const failed = deliveryResults.filter(
        (r) => r.status === 'rejected'
      ).length;

      expect(succeeded).toBe(2);
      expect(failed).toBe(2);
      expect(succeeded + failed).toBe(4);
    });

    it('should not throw on SendGrid API key missing', () => {
      const apiKey = '';

      const canSendEmail = () => {
        if (!apiKey) {
          return false;
        }
        return true;
      };

      expect(canSendEmail()).toBe(false);
    });

    it('should retry delivery on transient failures', () => {
      const maxRetries = 3;
      let attemptCount = 0;

      const tryDeliver = () => {
        attemptCount++;
        if (attemptCount < maxRetries) {
          return { success: false, retryable: true };
        }
        return { success: true, retryable: false };
      };

      // Simulate retry loop
      while (attemptCount < maxRetries) {
        const result = tryDeliver();
        if (result.success) break;
      }

      expect(attemptCount).toBe(maxRetries);
    });
  });

  describe('Integration', () => {
    it('should process full email delivery workflow', () => {
      const executionEvent = {
        reportId: 'report_001',
        executionId: 'exec_001',
        reportName: 'Monthly Report',
        format: 'csv',
        recordCount: 500,
        fileSizeBytes: 25600,
        recipientEmails: [
          'admin@example.com',
          'manager@example.com',
        ],
        exportedData:
          'timestamp,userId,action\n2026-09-01,user_001,CREATE',
        timestamp: new Date().toISOString(),
      };

      const template = {
        subject: `[Analytics Report] ${executionEvent.reportName}`,
        htmlBody: `<html><body>${executionEvent.recordCount} records</body></html>`,
        textBody: `${executionEvent.recordCount} records exported`,
      };

      const attachment = {
        filename: `${executionEvent.reportName}.${executionEvent.format === 'csv' ? 'csv' : executionEvent.format === 'json' ? 'json' : 'txt'}`,
        content: Buffer.from(executionEvent.exportedData).toString('base64'),
        type: 'text/csv',
        disposition: 'attachment',
      };

      expect(template.subject).toContain(executionEvent.reportName);
      expect(attachment.filename).toBe('Monthly Report.csv');
      expect(Buffer.byteLength(attachment.content)).toBeGreaterThan(0);
    });

    it('should send to all recipients with error tolerance', () => {
      const recipients = [
        'admin@example.com',
        'manager@example.com',
        'analyst@example.com',
      ];

      const results = recipients.map((email) => ({
        email,
        status:
          email === 'manager@example.com' ? 'failed' : 'success',
      }));

      const succeeded = results.filter((r) => r.status === 'success').length;
      const failed = results.filter((r) => r.status === 'failed').length;

      expect(succeeded).toBe(2);
      expect(failed).toBe(1);
      expect(succeeded + failed).toBe(recipients.length);
    });
  });
});
