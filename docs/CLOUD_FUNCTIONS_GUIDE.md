# Cloud Functions Deployment Guide

## Overview

This document describes the Cloud Functions implementation for 神獣リーグ (Shinjuu League), specifically the server-side ELO validation system that prevents client-side tampering.

**Status**: Phase 6 Sprint 2 Implementation  
**Priority**: MEDIUM (Security)  
**Timeline**: Phase 6 Sprint 2

---

## Architecture

### Problem Statement

Prior to this implementation, the entire ELO calculation was performed **client-side** in `BattleEngine`. While this provides instant feedback to players, it creates a security vulnerability:

1. A malicious client could submit a fake `BattleResult` to Firestore with inflated ELO gains
2. No server-side validation exists to prevent tampering
3. Leaderboard rankings become unreliable

### Solution: Server-Side Validation

We implement a Firestore-triggered Cloud Function that:

1. **Receives** a `BattleResult` document created by the client
2. **Validates** both participants exist and battle is legitimate
3. **Recalculates** ELO server-side using authoritative user data from Firestore
4. **Updates** user ELO ratings **only via server**, preventing client overwrites
5. **Logs** all calculations for audit trail

### Data Flow

```
Client (Flutter App)
  ↓ BattleEngine.tick() - local simulation for instant feedback
  ↓ Sends BattleResult to Firestore (/battle_results/{resultId})
  ↓
Firestore Trigger
  ↓ Cloud Function: validateBattleResult()
  ↓
Server-Side Validation
  1. Fetch User(userA).eloRating from Firestore (authoritative)
  2. Fetch User(userB).eloRating from Firestore (authoritative)
  3. Ignore client-submitted ELO values entirely
  4. Recalculate using current ratings + result
  5. Write new ratings back to User documents
  6. Mark battle as eloProcessed=true (idempotency)
  ↓
User Documents Updated
  (via atomic batch write)
```

### Security Properties

1. **Tamper-proof**: Client cannot influence final ELO (only server ratings matter)
2. **Idempotent**: Function fires only once per battle (`eloProcessed` flag)
3. **Atomic**: User updates + audit log happen together or not at all
4. **Auditable**: Every ELO change logged in `elo_validation_log` collection

---

## ELO Calculation

### Formula

We use the **Glicko-inspired ELO system** (simplified):

```
Expected Win Probability (EA):
  EA = 1 / (1 + 10^((RB - RA) / 400))

New Rating:
  RA' = RA + K * (SA - EA)
  
Where:
  RA  = Player A's current rating
  RB  = Player B's current rating (opponent)
  K   = K-factor (32 standard, adjustable per tier)
  SA  = Actual result (1=win, 0.5=draw, 0=loss)
  EA  = Expected probability
```

### Example Calculation

```
Player A: Rating 1600 vs Player B: Rating 1400
Result: Player A wins

EA = 1 / (1 + 10^((1400-1600)/400))
   = 1 / (1 + 10^(-0.5))
   = 1 / (1 + 0.316)
   = 0.76 (76% win probability)

RA' = 1600 + 32 * (1 - 0.76)
    = 1600 + 32 * 0.24
    = 1600 + 7.68
    = 1607.68 → 1608 (rounded)
```

Higher-rated player wins = smaller gain (expected result)  
Lower-rated player wins = larger gain (upset bonus)

### K-Factor Strategy

- **Default**: K=32 (all players)
- **Future Enhancement**: Tier-based adjustment
  - New players (< 50 battles): K=64 (faster convergence)
  - Intermediate (50-200): K=32 (standard)
  - Expert (> 200): K=16 (rating stability)

---

## Firestore Schema

### Battle Result Document

**Path**: `battle_results/{resultId}`

```typescript
{
  battleId: string;
  userId: string;
  opponentUserId: string;
  result: 'win' | 'loss' | 'draw';
  
  // Participant data (for audit trail, not used for calculation)
  participant: {
    userId: string;
    lane: number;
    baseStats: { atk, def, spd };
    eloRating: number; // Ignored by Cloud Function
  };
  opponent: {
    userId: string;
    lane: number;
    baseStats: { atk, def, spd };
    eloRating: number; // Ignored by Cloud Function
  };
  
  timestamp: serverTimestamp;
}
```

### Battle Document (Update)

**Path**: `battles/{battleId}`

After Cloud Function runs:
```typescript
{
  // ... existing fields ...
  eloProcessed: boolean = true;
  eloProcessedAt: serverTimestamp;
}
```

### User Document (Update)

**Path**: `users/{userId}`

After Cloud Function runs:
```typescript
{
  // ... existing fields ...
  eloRating: number; // Updated by Cloud Function only
  wins: number; // Incremented if won
  losses: number; // Incremented if lost
  draws: number; // Incremented if drew
  updatedAt: serverTimestamp;
}
```

### Audit Log Collections

#### `elo_validation_log`

Successful ELO calculations (one doc per battle):
```typescript
{
  resultId: string;
  battleId: string;
  userId: string;
  opponentUserId: string;
  
  userOldRating: number;
  userNewRating: number;
  userEloChange: number;
  
  opponentOldRating: number;
  opponentNewRating: number;
  opponentEloChange: number;
  
  clientSubmittedResult: 'win' | 'loss' | 'draw';
  serverValidatedResult: 'win' | 'loss' | 'draw';
  // ^ If these differ, potential client tampering detected
  
  timestamp: serverTimestamp;
}
```

#### `elo_validation_errors`

Failed validations (one doc per error):
```typescript
{
  resultId: string;
  battleId: string;
  error: string;
  battleResult: BattleResult; // Full data for debugging
  timestamp: serverTimestamp;
}
```

---

## Deployment

### Prerequisites

1. **Firebase CLI** installed
   ```bash
   npm install -g firebase-tools
   ```

2. **Service Account Key** for your Firebase project
   - Go to Firebase Console → Project Settings → Service Accounts
   - Generate new private key (JSON)
   - Save as `~/shinjuu-league-firebase.json` (outside repo)

3. **Node.js 18+** installed
   ```bash
   node --version  # Should be ≥ 18
   npm --version
   ```

### Setup & Build

```bash
# Navigate to functions directory
cd functions

# Install dependencies
npm install

# Build TypeScript → JavaScript
npm run build

# Verify compiled output
ls -la lib/
```

### Deploy to Production

```bash
cd functions

# Set your Firebase project
firebase use shinjuu-league-prod  # or relevant project ID

# Deploy only Cloud Functions
firebase deploy --only functions

# View deployment status
firebase functions:list

# View recent logs
firebase functions:log --limit 50
```

### Deploy to Emulator (Local Testing)

```bash
cd functions

# Build
npm run build

# Start Firestore + Functions emulator
npm run serve
# Emulator listens on localhost:5001 (Firestore) & 5000 (Functions)

# In another terminal, run tests against emulator:
cd ..
flutter test test/elo_validator_test.dart --dart-define=USE_FIRESTORE_EMULATOR=true
```

---

## Client-Side Integration

### Creating a BattleResult

After a battle completes in `BattleEngine`, the client submits:

```dart
// In BattleViewModel or similar
Future<void> submitBattleResult(
  String battleId,
  String userId,
  String opponentUserId,
  String result, // 'win', 'loss', or 'draw'
  User participant,
  User opponent,
) async {
  final battleResultRef = FirebaseFirestore.instance
      .collection('battle_results')
      .doc();  // Let Firestore generate ID

  await battleResultRef.set({
    'battleId': battleId,
    'userId': userId,
    'opponentUserId': opponentUserId,
    'result': result,
    'participant': {
      'userId': participant.uid,
      'lane': participant.currentLane,
      'baseStats': {
        'atk': participant.baseStats.atk,
        'def': participant.baseStats.def,
        'spd': participant.baseStats.spd,
      },
      'eloRating': participant.eloRating,
    },
    'opponent': {
      'userId': opponent.uid,
      'lane': opponent.currentLane,
      'baseStats': {
        'atk': opponent.baseStats.atk,
        'def': opponent.baseStats.def,
        'spd': opponent.baseStats.spd,
      },
      'eloRating': opponent.eloRating,
    },
    'timestamp': FieldValue.serverTimestamp(),
  });

  // ⚠️ Do NOT immediately apply ELO from client
  // Instead, listen to User stream and wait for server update
  // Cloud Function will update User.eloRating within ~5 seconds
}
```

### Polling for Server Update

```dart
// After submitting BattleResult, wait for User.eloRating to change
Future<void> waitForEloUpdate(String userId, int oldRating) async {
  int attempts = 0;
  const maxAttempts = 30; // ~30 seconds with 1s polling

  while (attempts < maxAttempts) {
    final user = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();
    
    if (user.exists) {
      final newRating = user.data()?['eloRating'] as int?;
      if (newRating != null && newRating != oldRating) {
        print('[BattleResult] ELO updated: $oldRating → $newRating');
        return;
      }
    }

    await Future.delayed(Duration(seconds: 1));
    attempts++;
  }

  print('[BattleResult] Warning: ELO update took > 30s');
}
```

### Handling Client-Side Display

```dart
// Show instant result to player (client-side ELO)
resultScreen.showEloChange(
  clientCalculatedChange: 15, // From BattleEngine
  label: 'Calculated (pending server validation)',
);

// After server updates, refresh and show final ELO
await waitForEloUpdate(userId, currentUser.eloRating);
resultScreen.showFinalEloChange(
  serverCalculatedChange: user.eloRating - currentUser.eloRating,
  label: 'Final (server-validated)',
);
```

---

## Testing

### Unit Tests (Dart)

See `test/elo_validator_test.dart` for:
- ELO calculation correctness
- Expectation formula validation
- Tampered BattleResult rejection
- Idempotency (double-application prevention)

Run:
```bash
flutter test test/elo_validator_test.dart
```

### Integration Tests (Cloud Functions Emulator)

See `functions/test/elo-validator.test.ts` for:
- Cloud Function trigger behavior
- Batch write atomicity
- Error handling and logging
- Audit trail generation

Run:
```bash
cd functions
npm test
```

### Manual Testing Checklist

1. **Local Emulator**
   ```bash
   npm run serve
   # In Flutter app, set USE_FIRESTORE_EMULATOR=true
   # Complete a battle and verify:
   #   - BattleResult created
   #   - Cloud Function logs appear in emulator
   #   - User.eloRating updated server-side
   ```

2. **Production Dry-Run** (staging environment)
   ```bash
   firebase deploy --only functions --project shinjuu-league-staging
   # Complete battles and monitor:
   firebase functions:log --project shinjuu-league-staging
   ```

3. **Leaderboard Verification**
   - Check that top players' ELO is consistent
   - Verify wins/losses/draws increment correctly
   - Inspect audit log for any errors

---

## Monitoring & Debugging

### View Real-Time Logs

```bash
# Follow logs in real-time
firebase functions:log --lines 50 --project shinjuu-league-prod

# Filter for errors only
firebase functions:log --lines 100 | grep ERROR
```

### Inspect Audit Collections

**In Firebase Console**:
1. Go to Firestore → Collections
2. View `elo_validation_log` (successful)
3. View `elo_validation_errors` (failures)

**Via Dart SDK**:
```dart
final logs = await FirebaseFirestore.instance
    .collection('elo_validation_log')
    .where('userId', isEqualTo: userId)
    .orderBy('timestamp', descending: true)
    .limit(10)
    .get();

for (final doc in logs.docs) {
  final data = doc.data();
  print('${data['userOldRating']} → ${data['userNewRating']} '
        '(${data['userEloChange'] > 0 ? '+' : ''}${data['userEloChange'].toStringAsFixed(1)})');
}
```

### Debugging ELO Calculation

Use the `debugEloCalculation` callable function to verify calculations:

```dart
// In Dart
final result = await FirebaseFunctions.instance
    .httpsCallable('debugEloCalculation')
    .call({
  'playerRating': 1600,
  'opponentRating': 1400,
  'result': 'win',
});

print('Expected: ${result.data['expectation']}');
print('New Rating: ${result.data['newRating']}');
print('ELO Change: ${result.data['eloChange']}');
```

---

## Troubleshooting

| Issue | Cause | Solution |
|-------|-------|----------|
| Cloud Function doesn't trigger | Firestore trigger path mismatch | Verify `battle_results/{resultId}` collection exists |
| "User not found" error | BattleResult created before User document | Ensure User created before submitting BattleResult |
| ELO not updating | `eloProcessed` already true | Check if battle processed twice |
| Double ELO update | Function fires twice (rare Firestore behavior) | Handled by `eloProcessed` flag |
| Timeout (> 30s wait) | Cloud Function slow or failed silently | Check `elo_validation_errors` collection |

---

## Future Enhancements

1. **Tier-Based K-Factor**: Adjust K based on player tier (new/intermediate/expert)
2. **Decay System**: Inactive players' ratings decay slightly
3. **Provisional Period**: New players get final rating after 20 games
4. **Glicko-2**: Implement full Glicko-2 with RD (rating deviation)
5. **Compression**: Archive old `elo_validation_log` entries monthly
6. **Dashboard**: Admin panel showing real-time ELO distribution

---

## References

- [Firestore Triggers Documentation](https://firebase.google.com/docs/functions/firestore-events)
- [ELO Rating System](https://en.wikipedia.org/wiki/Elo_rating_system)
- [Cloud Functions Pricing](https://firebase.google.com/pricing/functions)
- [TypeScript on Cloud Functions](https://firebase.google.com/docs/functions/typescript)
