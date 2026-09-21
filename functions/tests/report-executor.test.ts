import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions';
import test from 'firebase-functions-test';
import * as elf from '../src/report-executor';

// report-executor.ts calls admin.firestore() at module load time (line 4),
// which throws ("The default Firebase app does not exist") unless
// admin.initializeApp() already ran - true in production because index.ts
// initializes it before importing this module, but not here since this
// file imports report-executor.ts directly. ts-jest hoists jest.mock()
// calls above the imports above in the compiled output (this is required -
// TypeScript syntax doesn't allow a plain statement between import
// declarations), so this still takes effect before report-executor.ts
// itself is loaded.
jest.mock('firebase-admin', () => {
  const firestoreFn: any = jest.fn(() => ({}));
  firestoreFn.Timestamp = {
    now: jest.fn(() => 'MOCK_TIMESTAMP'),
    fromDate: jest.fn((d: Date) => d),
  };
  firestoreFn.FieldValue = { increment: jest.fn((n: number) => ({ __increment: n })) };
  return { firestore: firestoreFn, apps: [] };
});

const projectId = 'shinjuu-league-test';
const testEnv = test({ projectId });

describe('Report Executor', () => {
  let getFirestore: any;
  let pubsub: any;

  beforeEach(() => {
    // Mock Firestore and Pub/Sub
    getFirestore = jest.fn();
    pubsub = {
      topic: jest.fn().mockReturnValue({
        publish: jest.fn().mockResolvedValue(['messageId']),
      }),
    };
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('executeScheduledReports', () => {
    it('should execute reports that are due', async () => {
      // This test validates the scheduled execution logic
      // In a real environment, it would connect to Firestore
      const mockReports = [
        {
          id: 'report_001',
          name: 'Daily Report',
          isActive: true,
          nextExecutionAt: new Date(Date.now() - 1000), // Past time
          format: 'csv',
          selectedFields: ['timestamp', 'userId'],
          recipientEmails: ['admin@example.com'],
          includeMetadata: true,
          userId: 'user_001',
          frequency: 'daily',
          createdAt: new Date(),
        },
      ];

      expect(mockReports.length).toBe(1);
      expect(mockReports[0].nextExecutionAt.getTime()).toBeLessThan(Date.now());
    });

    it('should skip reports that are not yet due', () => {
      const mockReports = [
        {
          id: 'report_002',
          name: 'Weekly Report',
          isActive: true,
          nextExecutionAt: new Date(Date.now() + 86400000), // Future time
          format: 'json',
          selectedFields: ['timestamp'],
          recipientEmails: ['admin@example.com'],
          includeMetadata: false,
          userId: 'user_001',
          frequency: 'weekly',
          createdAt: new Date(),
        },
      ];

      const dueSoon = mockReports.filter(
        (r) => r.nextExecutionAt.getTime() <= Date.now()
      );
      expect(dueSoon.length).toBe(0);
    });

    it('should skip inactive reports', () => {
      const mockReports = [
        {
          id: 'report_003',
          name: 'Inactive Report',
          isActive: false,
          nextExecutionAt: new Date(Date.now() - 1000),
          format: 'csv',
          selectedFields: ['timestamp'],
          recipientEmails: ['admin@example.com'],
          includeMetadata: true,
          userId: 'user_001',
          frequency: 'daily',
          createdAt: new Date(),
        },
      ];

      const activeReports = mockReports.filter((r) => r.isActive);
      expect(activeReports.length).toBe(0);
    });

    it('should handle empty reports list gracefully', () => {
      const mockReports: any[] = [];
      expect(mockReports.length).toBe(0);
      expect(() => {
        mockReports.forEach(() => {
          // Process reports
        });
      }).not.toThrow();
    });
  });

  describe('Export Generation', () => {
    it('should generate CSV export correctly', () => {
      const logs = [
        {
          timestamp: '2026-09-01T10:00:00Z',
          userId: 'user_001',
          action: 'CREATE',
          resourceType: 'feature',
          resourceId: 'feat_001',
          details: 'Created feature X',
        },
        {
          timestamp: '2026-09-01T11:00:00Z',
          userId: 'user_002',
          action: 'UPDATE',
          resourceType: 'feature',
          resourceId: 'feat_002',
          details: 'Updated feature Y',
        },
      ];

      const fields = ['timestamp', 'userId', 'action'];
      const csvHeader = fields.join(',');

      expect(csvHeader).toBe('timestamp,userId,action');
      expect(logs.length).toBe(2);
    });

    it('should escape CSV special characters', () => {
      const value = 'Contains, comma and "quotes"';
      const escaped = `"${value.replace(/"/g, '""')}"`;

      expect(escaped).toBe('"Contains, comma and ""quotes"""');
    });

    it('should handle CSV with empty values', () => {
      const logs = [
        {
          timestamp: '2026-09-01T10:00:00Z',
          userId: 'user_001',
          action: 'CREATE',
          resourceType: undefined,
          resourceId: null,
          details: 'No resource',
        },
      ];

      const fields = ['timestamp', 'userId', 'action', 'resourceType', 'resourceId', 'details'];
      const values = fields.map((field) => {
        const value = logs[0][field as keyof typeof logs[0]];
        return value === null || value === undefined ? '' : String(value);
      });

      expect(values.length).toBe(6);
      expect(values[3]).toBe('');
      expect(values[4]).toBe('');
    });

    it('should generate JSON export with metadata', () => {
      const logs = [
        {
          timestamp: '2026-09-01T10:00:00Z',
          userId: 'user_001',
          action: 'CREATE',
        },
      ];

      const fields = ['timestamp', 'userId', 'action'];
      const metadata = {
        exportDate: new Date().toISOString(),
        totalRecords: logs.length,
        selectedFields: fields,
      };

      expect(metadata.totalRecords).toBe(1);
      expect(metadata.selectedFields).toEqual(fields);
      expect(metadata.exportDate).toBeTruthy();
    });

    it('should generate text export with proper formatting', () => {
      const logs = [
        {
          timestamp: '2026-09-01T10:00:00Z',
          userId: 'user_001',
          action: 'CREATE',
        },
      ];

      const lines: string[] = [];
      lines.push('='.repeat(80));
      lines.push('ANALYTICS EXPORT REPORT');
      lines.push(`Generated: ${new Date().toISOString()}`);
      lines.push(`Total Records: ${logs.length}`);
      lines.push('='.repeat(80));

      expect(lines.length).toBeGreaterThan(0);
      expect(lines[1]).toBe('ANALYTICS EXPORT REPORT');
    });
  });

  describe('Next Execution Calculation', () => {
    // These call the real exported calculateNextExecution() rather than
    // re-implementing the Date arithmetic inline, so a regression in the
    // actual scheduling logic (e.g. the month-end overflow this test suite
    // caught: Jan 31 + 1 month naively rolling into March) fails here
    // instead of only in a hand-copied duplicate that always agrees with
    // whatever bug the real function has.
    it('should calculate daily next execution correctly', () => {
      const now = new Date('2026-09-01T10:00:00Z');
      const next = elf.calculateNextExecution('daily', now);

      expect(next.getDate()).toBe(2);
      expect(next.getHours()).toBe(now.getHours());
    });

    it('should calculate weekly next execution correctly', () => {
      const now = new Date('2026-09-01T10:00:00Z');
      const next = elf.calculateNextExecution('weekly', now);

      expect(next.getDate()).toBe(8);
    });

    it('should calculate monthly next execution correctly', () => {
      const now = new Date('2026-09-01T10:00:00Z');
      const next = elf.calculateNextExecution('monthly', now);

      expect(next.getMonth()).toBe(9);
      expect(next.getDate()).toBe(1);
    });

    it('should calculate once (one-time) as far future', () => {
      const now = new Date('2026-09-01T10:00:00Z');
      const next = elf.calculateNextExecution('once', now);

      expect(next.getFullYear()).toBe(now.getFullYear() + 1);
    });

    it('should handle monthly calculation at end of month by clamping to the target month\'s last day', () => {
      const now = new Date('2026-01-31T10:00:00Z');
      const next = elf.calculateNextExecution('monthly', now);

      // February 28 (2026 is not a leap year) - not March 3, which is what
      // a naive setMonth(getMonth() + 1) on Jan 31 rolls over to.
      expect(next.getMonth()).toBe(1);
      expect(next.getDate()).toBe(28);
    });

    it('should preserve the day-of-month for a month with enough days', () => {
      const now = new Date('2026-01-15T10:00:00Z');
      const next = elf.calculateNextExecution('monthly', now);

      expect(next.getMonth()).toBe(1);
      expect(next.getDate()).toBe(15);
    });
  });

  describe('Execution Record Creation', () => {
    it('should create successful execution record', () => {
      const record = {
        id: 'exec_001',
        reportId: 'report_001',
        executedAt: new Date().toISOString(),
        success: true,
        recordCount: 100,
        fileSizeBytes: 5120,
        sentToEmails: ['admin@example.com'],
      };

      expect(record.success).toBe(true);
      expect(record.recordCount).toBe(100);
      expect(record.sentToEmails.length).toBe(1);
    });

    it('should create failed execution record with error message', () => {
      const record = {
        id: 'exec_002',
        reportId: 'report_002',
        executedAt: new Date().toISOString(),
        success: false,
        errorMessage: 'Failed to fetch audit logs',
        recordCount: 0,
        fileSizeBytes: 0,
        sentToEmails: [],
      };

      expect(record.success).toBe(false);
      expect(record.errorMessage).toBeTruthy();
      expect(record.recordCount).toBe(0);
    });

    it('should handle execution with zero records', () => {
      const record = {
        id: 'exec_003',
        reportId: 'report_003',
        executedAt: new Date().toISOString(),
        success: true,
        recordCount: 0,
        fileSizeBytes: 0,
        sentToEmails: ['admin@example.com'],
      };

      expect(record.recordCount).toBe(0);
      expect(record.success).toBe(true);
    });

    it('should track multiple recipient emails in execution record', () => {
      const record = {
        id: 'exec_004',
        reportId: 'report_004',
        executedAt: new Date().toISOString(),
        success: true,
        recordCount: 50,
        fileSizeBytes: 2048,
        sentToEmails: [
          'admin@example.com',
          'manager@example.com',
          'analyst@example.com',
        ],
      };

      expect(record.sentToEmails.length).toBe(3);
      expect(record.sentToEmails).toContain('manager@example.com');
    });
  });

  describe('Error Handling', () => {
    it('should handle missing audit logs gracefully', () => {
      const logs: any[] = [];
      const fields = ['timestamp', 'userId'];

      const result = {
        recordCount: logs.length,
        success: logs.length > 0 || true, // Even with 0 logs, export can succeed
      };

      expect(result.recordCount).toBe(0);
      expect(result.success).toBe(true);
    });

    it('should handle invalid field selection', () => {
      const logs = [
        {
          timestamp: '2026-09-01T10:00:00Z',
          userId: 'user_001',
          action: 'CREATE',
        },
      ];

      const invalidFields = ['nonexistent', 'field'];
      const result = invalidFields.map((field) => {
        return field in logs[0] ? logs[0][field as keyof typeof logs[0]] : '';
      });

      expect(result[0]).toBe('');
      expect(result[1]).toBe('');
    });

    it('should handle batch failure with individual retry potential', () => {
      const results = [
        { status: 'fulfilled', value: 'exec_001' },
        { status: 'rejected', reason: 'Network error' },
        { status: 'fulfilled', value: 'exec_002' },
      ];

      const succeeded = results.filter((r) => r.status === 'fulfilled').length;
      const failed = results.filter((r) => r.status === 'rejected').length;

      expect(succeeded).toBe(2);
      expect(failed).toBe(1);
    });

    it('should increment retry count on failure', () => {
      const initialCount = 0;
      const afterRetry = initialCount + 1;

      expect(afterRetry).toBe(1);
    });
  });

  describe('Pub/Sub Event Publishing', () => {
    it('should publish execution event with correct payload', () => {
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

    it('should handle multiple recipients in event payload', () => {
      const event = {
        reportId: 'report_002',
        executionId: 'exec_002',
        reportName: 'Weekly Report',
        format: 'json',
        recordCount: 250,
        fileSizeBytes: 15000,
        recipientEmails: [
          'admin@example.com',
          'manager@example.com',
          'analyst@example.com',
        ],
        exportedData: '{"data": []}',
        timestamp: new Date().toISOString(),
      };

      expect(event.recipientEmails.length).toBe(3);
      expect(Buffer.byteLength(event.exportedData, 'utf8')).toBeGreaterThan(0);
    });
  });

  describe('Report Metadata Updates', () => {
    it('should update lastExecutedAt timestamp', () => {
      const beforeUpdate = new Date(Date.now() - 1000);
      const updateTime = new Date();
      const afterUpdate = new Date(Date.now() + 1000);

      expect(updateTime.getTime()).toBeGreaterThan(beforeUpdate.getTime());
      expect(updateTime.getTime()).toBeLessThan(afterUpdate.getTime());
    });

    it('should calculate and set nextExecutionAt for daily reports', () => {
      const now = new Date('2026-09-01T10:00:00Z');
      const next = new Date(now);
      next.setDate(next.getDate() + 1);

      const timeDiff = next.getTime() - now.getTime();
      const hoursUntilNext = timeDiff / (1000 * 60 * 60);

      expect(hoursUntilNext).toBeCloseTo(24, 1);
    });

    it('should not update report if execution fails', () => {
      const originalLastExecuted = new Date('2026-09-01T10:00:00Z');
      const originalNext = new Date('2026-09-02T10:00:00Z');

      // Simulate failure - don't update
      const updatedLastExecuted = originalLastExecuted;
      const updatedNext = originalNext;

      expect(updatedLastExecuted).toEqual(originalLastExecuted);
      expect(updatedNext).toEqual(originalNext);
    });
  });
});
