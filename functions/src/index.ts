import * as admin from 'firebase-admin';

// Initialize Firebase Admin SDK
if (!admin.apps.length) {
  admin.initializeApp();
}

// Export all Cloud Functions
export { validateBattleResult, debugEloCalculation } from './elo-validator';
export { onSeasonEnded, applyInactivityDecay } from './season-lifecycle';
export { executeScheduledReports } from './report-executor';
export { deliverReportViaEmail } from './email-delivery';
