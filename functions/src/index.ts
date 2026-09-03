import * as admin from 'firebase-admin';

// Initialize Firebase Admin SDK
if (!admin.apps.length) {
  admin.initializeApp();
}

// Export all Cloud Functions
export { validateBattleResult, debugEloCalculation } from './elo-validator';
