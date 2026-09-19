# Cloud Functions: Scheduled Report Execution & Email Delivery

**Status**: Phase 40 Implementation Complete  
**Last Updated**: 2026-09-16

---

## Overview

This document describes the serverless Cloud Functions infrastructure for automatically executing scheduled reports and delivering them via email. The system uses **Pub/Sub event-driven architecture** to decouple execution from delivery, ensuring reliability and scalability.

### Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    Hourly Scheduler (Pub/Sub)                    │
│                    (0 * * * * - every hour)                       │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│            executeScheduledReports (Cloud Function)              │
│  • Query Firestore for due reports (nextExecutionAt <= now)     │
│  • Fetch audit logs from audit_logs collection                  │
│  • Generate exports (CSV/JSON/Text) per report format           │
│  • Save execution record to execution_history subcollection     │
│  • Update report: lastExecutedAt, nextExecutionAt               │
│  • Publish execution event to Pub/Sub topic                     │
└────────────────────────────┬────────────────────────────────────┘
                             │
           event: {reportId, executionId, format, data, recipients}
                             │
                             ▼
        ┌──────────────────────────────────────┐
        │  Pub/Sub Topic: report-execution-events
        └──────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│           deliverReportViaEmail (Cloud Function)                │
│  • Parse execution event                                        │
│  • Generate email templates (HTML + plain text)                 │
│  • Create MIME attachments (filename, content, type)            │
│  • Send via SendGrid (or mock if not configured)                │
│  • Track delivery status per recipient                          │
│  • Update execution_history with delivery metadata              │
└─────────────────────────────────────────────────────────────────┘
```

---

## Cloud Functions

### 1. executeScheduledReports

**Trigger**: Cloud Scheduler Pub/Sub (every hour)  
**Entry Point**: `functions/src/report-executor.ts`  
**Runtime**: Node.js 18

#### Responsibilities

- **Query Active Reports**: Filters `scheduled_reports` collection for `isActive==true` and `nextExecutionAt <= now`
- **Fetch Data**: Queries `audit_logs` collection (up to 1000 records per execution)
- **Generate Exports**: Converts logs to CSV/JSON/Text format per report specification
  - **CSV**: Escapes special characters (commas, quotes) for spreadsheet compatibility
  - **JSON**: Includes optional metadata (exportDate, totalRecords, selectedFields)
  - **Text**: Formats as human-readable report with headers/footers
- **Save Execution Record**: Creates subcollection document at `/scheduled_reports/{reportId}/execution_history/{executionId}`
  - Tracks: recordCount, fileSizeBytes, success status, timestamp
  - On failure: records errorMessage and increments retryCount
- **Update Report Metadata**:
  - Sets `lastExecutedAt = now`
  - Calculates `nextExecutionAt` based on frequency:
    - `once`: +1 year (one-time only)
    - `daily`: +1 day
    - `weekly`: +7 days
    - `monthly`: +1 month
- **Publish Event**: Sends execution event to Pub/Sub topic `report-execution-events` for email delivery

#### Environment Variables

None required (uses Firestore default credentials via Firebase Admin SDK initialization).

#### Error Handling

- **Missing Audit Logs**: Continues with empty export (still sends valid report)
- **Firestore Write Failure**: Logs error, increments retry count, does not re-throw
- **Pub/Sub Publish Failure**: Logs error but execution record is already persisted (eventual consistency)

#### Example Firestore Structure

```
scheduled_reports/
  {reportId}/
    name: "Daily Audit Report"
    userId: "user_001"
    format: "csv"
    frequency: "daily"
    recipientEmails: ["admin@example.com"]
    isActive: true
    nextExecutionAt: 2026-09-02T10:00:00Z
    
    execution_history/
      {executionId}/
        executedAt: 2026-09-01T10:00:00Z
        success: true
        recordCount: 250
        fileSizeBytes: 12800
        sentToEmails: ["admin@example.com"]
        emailDeliveryStatus: "sent"
```

---

### 2. deliverReportViaEmail

**Trigger**: Pub/Sub Topic `report-execution-events`  
**Entry Point**: `functions/src/email-delivery.ts`  
**Runtime**: Node.js 18

#### Responsibilities

- **Parse Event**: Extracts execution event from Pub/Sub message (base64 decoded)
- **Generate Templates**: Creates email templates based on report format
  - All templates include: subject, htmlBody, textBody
  - HTML: styled with CSS (Arial font, stats box with border-left highlight)
  - Text: plain text version for fallback clients
- **Create Attachments**: Builds MIME-compliant attachment
  - Filename: `{reportName}.{extension}` (csv/json/txt)
  - Content: base64-encoded export data
  - Type: MIME type matching format (text/csv, application/json, text/plain)
- **Send Emails**: Calls `sendReportEmail()` for each recipient
  - Uses SendGrid API (configured via `SENDGRID_API_KEY` environment variable)
  - Mock implementation logs instead of sending if API key is not set
  - Catches per-recipient errors to allow other recipients to proceed
- **Track Delivery**: Records results in Promise.allSettled()
  - Counts successes vs failures
  - Determines status: `sent` (all succeeded) or `partial` (some failed)
- **Update Execution History**: Stores delivery status at `/scheduled_reports/{reportId}/execution_history/{executionId}`
  - Fields: emailDeliveryStatus, emailsSent, emailsFailed, deliveredAt

#### Environment Variables

- `SENDGRID_API_KEY`: SendGrid API key for production email delivery
  - If not set, email sending is mocked (logs delivery, doesn't send)
  - Safe for development without credential setup

#### Email Template Content

**CSV Example**:
```html
<html>
  <body>
    <div class="container">
      <div class="header">
        <h2>Daily Report</h2>
        <p>CSV Export Report</p>
      </div>
      <div class="stats">
        <div class="stat-item">Records: 250</div>
        <div class="stat-item">File Size: 12.5 KB</div>
        <div class="stat-item">File Name: daily_report.csv</div>
        <div class="stat-item">Generated: 2026-09-01T10:00:00Z</div>
      </div>
      <p>The report file is attached to this email.</p>
    </div>
  </body>
</html>
```

#### Error Handling

- **Missing SendGrid Key**: Logs warning, returns mock success (development safety)
- **Individual Email Failures**: Continues with next recipient, reports partial status
- **Invalid Email Addresses**: Rejected by SendGrid, counted as failed delivery
- **Attachment Too Large**: Handled by SendGrid size limits (returns error to Pub/Sub retry)

#### Example Pub/Sub Message

```json
{
  "reportId": "report_001",
  "executionId": "exec_001",
  "reportName": "Daily Audit Report",
  "format": "csv",
  "recordCount": 250,
  "fileSizeBytes": 12800,
  "recipientEmails": ["admin@example.com", "manager@example.com"],
  "exportedData": "timestamp,userId,action\n2026-09-01,user_001,CREATE\n...",
  "timestamp": "2026-09-01T10:00:00Z"
}
```

---

## Firestore Security Rules

Add the following rules to allow Cloud Functions to write execution records:

```javascript
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    // Scheduled reports: users can read/write their own reports
    match /scheduled_reports/{reportId} {
      allow read, write: if request.auth.uid == resource.data.userId;
      
      // Execution history: Cloud Functions write, users read their own
      match /execution_history/{executionId} {
        allow read: if request.auth.uid == get(/databases/$(database)/documents/scheduled_reports/$(reportId)).data.userId;
        allow write: if request.auth.uid == null; // Cloud Functions (no auth)
      }
    }
  }
}
```

---

## Deployment

### Prerequisites

1. **Firebase Project**: Already initialized (see `firebase_options.dart`)
2. **Service Account**: Generated via Firebase Console
3. **SendGrid API Key** (optional): For production email delivery

### Steps

#### 1. Install Dependencies

```bash
cd functions
npm install
```

#### 2. Build TypeScript

```bash
npm run build
```

Output: `functions/lib/report-executor.js`, `functions/lib/email-delivery.js`

#### 3. Deploy to Firebase

```bash
firebase deploy --only functions
```

This will:
- Compile TypeScript
- Upload code to Firebase
- Create HTTP triggers for Cloud Scheduler
- Register Pub/Sub topic listeners

#### 4. Configure Scheduler (One-time)

If Cloud Scheduler job doesn't exist:

```bash
gcloud scheduler jobs create pubsub execute-scheduled-reports \
  --location us-central1 \
  --schedule "0 * * * *" \
  --topic report-execution-scheduler \
  --message-body '{}'
```

#### 5. Configure SendGrid (Optional, for Production)

1. Get API key from SendGrid console
2. Set as Cloud Functions environment variable:

```bash
firebase functions:config:set sendgrid.api_key="SG.your-api-key-here"
firebase deploy --only functions
```

Or via Firebase Console UI:
- Runtime settings → Environment variables
- Add `SENDGRID_API_KEY`

---

## Local Testing

### Using Firebase Emulator

1. **Start Emulator**:
   ```bash
   firebase emulators:start --only firestore,pubsub,functions
   ```

2. **Seed Test Data**:
   ```bash
   // Connect to emulator in your Dart code (set useEmulator: true)
   // Create scheduled_reports and audit_logs collections
   ```

3. **Trigger Manually**:
   ```bash
   gcloud pubsub topics publish report-execution-scheduler --message "{}"
   ```

4. **View Logs**:
   ```bash
   firebase functions:log
   ```

### Unit Tests

```bash
npm run test
```

Runs Jest test suite (48 test cases across both functions).

---

## Monitoring & Debugging

### Firebase Console

1. **Functions** tab: View execution logs and performance metrics
2. **Pub/Sub** tab: Monitor message throughput and dead-letter queues
3. **Firestore** tab: Query execution_history to verify records

### Cloud Logging

```bash
gcloud functions logs read executeScheduledReports --limit 50
gcloud functions logs read deliverReportViaEmail --limit 50
```

### Metrics to Watch

| Metric | Threshold | Action |
|--------|-----------|--------|
| Function Execution Time | >60s | Optimize query or split batch |
| Pub/Sub Message Lag | >5min | Check deliverReportViaEmail performance |
| Email Delivery Failures | >10% | Verify recipient emails, SendGrid quota |
| Firestore Write Failures | >1% | Check quota and concurrent writes |

---

## Troubleshooting

### Issue: "Report not executing at scheduled time"

**Causes**:
- Cloud Scheduler job not created
- Pub/Sub topic name mismatch
- Firestore query not matching any reports (check `nextExecutionAt` and `isActive`)

**Solution**:
1. Verify scheduler job exists: `gcloud scheduler jobs list`
2. Check function logs: `firebase functions:log`
3. Manually trigger: `gcloud pubsub topics publish report-execution-scheduler --message "{}"`

### Issue: "Emails not being sent"

**Causes**:
- SendGrid API key not set (defaulting to mock)
- Invalid recipient email addresses
- Attachment too large (>25MB)
- SendGrid quota exceeded

**Solution**:
1. Check Cloud Functions logs for "Mock email sent" vs actual sends
2. Verify recipient emails with validation regex: `/^[^\s@]+@[^\s@]+\.[^\s@]+$/`
3. Check SendGrid dashboard for bounces/blocks
4. Set `SENDGRID_API_KEY` environment variable if production

### Issue: "Execution record not created"

**Causes**:
- Firestore security rules blocking writes
- Cloud Functions missing service account permissions

**Solution**:
1. Verify security rules allow Cloud Functions (check `request.auth.uid == null`)
2. Check service account has `Cloud Functions Service Agent` role
3. View Firestore audit logs for permission denied errors

---

## Scalability Considerations

### Batch Size Limits

- **Audit Log Query**: Limited to 1,000 records per execution
  - Rationale: Prevent memory exhaustion in Functions sandbox (512MB)
  - Mitigation: Implement pagination if >1,000 logs per report needed

- **Recipients per Report**: No limit, but email delivery happens sequentially per recipient
  - Max 5 concurrent sends recommended (Promise.allSettled default)
  - For >50 recipients, consider splitting into multiple reports

- **Concurrent Reports**: Up to 10 reports can execute per hour
  - Scheduler runs once/hour, function completes in <30s typically
  - Pub/Sub handles fan-out to email delivery (scales automatically)

### Cost Optimization

- **Function Invocations**: ~730/month (hourly) + email deliveries
- **Pub/Sub Messages**: ~730 publish + variable number of subscriptions
- **Firestore Reads**: 730 scheduled_reports queries + 730*N audit log queries
- **Recommendations**:
  - Archive old execution_history (TTL policy)
  - Batch multiple recipients into single email thread if applicable
  - Use CSV for large datasets (smaller than JSON)

---

## Future Enhancements

- [ ] **Retry Logic**: Exponential backoff for failed executions
- [ ] **Failure Notifications**: Email admins when execution fails N times
- [ ] **Compression**: Gzip export data before attachment (if >1MB)
- [ ] **Partial Delivery**: Send report to succeeded recipients even if some fail
- [ ] **Report Previews**: Include CSV/JSON preview in email body (first 50 rows)
- [ ] **Scheduled Cleanup**: Auto-archive execution_history after 90 days
- [ ] **Rate Limiting**: Queue reports to avoid Pub/Sub backpressure

---

## References

- [Firebase Cloud Functions](https://firebase.google.com/docs/functions)
- [Cloud Pub/Sub](https://cloud.google.com/pubsub/docs)
- [SendGrid Email API](https://docs.sendgrid.com/api-reference/mail-send/mail-send)
- [Firestore Security Rules](https://firebase.google.com/docs/firestore/security/start)
