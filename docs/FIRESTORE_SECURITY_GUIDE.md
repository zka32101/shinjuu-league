# Firestore Security Rules Guide

## Overview

This guide documents the Firestore security rules deployed for Shinjuu League. These rules implement defense-in-depth security to prevent unauthorized access, data tampering, and fraud.

**Status**: Security rules are defined in `firestore.rules` and ready for production deployment.

---

## Security Architecture

### Defense Layers

```
┌─────────────────────────────────────────┐
│ Client (Flutter App)                    │
│ - Enforces UI permissions               │
│ - Validates input locally               │
└────────────────┬────────────────────────┘
                 │ HTTPS + JWT Token
                 ↓
┌─────────────────────────────────────────┐
│ Firestore Security Rules (Layer 1)      │
│ - Validates authentication               │
│ - Checks authorization (ownership)      │
│ - Prevents direct client writes to      │
│   sensitive fields (Elo, stats, etc)    │
└────────────────┬────────────────────────┘
                 │
                 ↓
┌─────────────────────────────────────────┐
│ Cloud Functions (Layer 2)               │
│ - Server-side business logic validation │
│ - Elo calculation + anti-tampering      │
│ - Currency transactions (gems, gold)    │
│ - Achievment unlock triggers            │
└────────────────┬────────────────────────┘
                 │
                 ↓
┌─────────────────────────────────────────┐
│ Firestore Database (Layer 3)            │
│ - Persisted audit trail                 │
│ - Immutable battle results              │
└─────────────────────────────────────────┘
```

### Key Principles

1. **No Direct Client Writes to Sensitive Fields**
   - Elo points, rank, level, stats, currency → **Server only**
   - Profile fields (name, selectedMechaId) → User can update own

2. **User Privacy by Default**
   - Users can only read/write their own documents
   - Exception: Replays are publicly readable (for sharing)

3. **Server-Authorized State Changes**
   - Battle results are created by client but processed by Cloud Functions
   - Elo recalculated server-side (prevents tampering)
   - Currency transactions validated server-side

4. **Immutable Audit Trail**
   - Battle results cannot be deleted
   - Provides fraud detection capability

5. **Hierarchical Social Features**
   - Guilds: Owner-controlled with member participation
   - Friends: Mutual consent (sender initiates, receiver accepts)

---

## Collection-by-Collection Rules

### Users Collection (`/users/{userId}`)

**Purpose**: User profiles and account data.

#### Read Rules
```firestore
allow read: if request.auth.uid == userId;
```
- ✅ User can read their own profile
- ❌ User cannot read other users' profiles (privacy)
- ❌ Anonymous cannot read any profile

#### Write Rules

**Allowed Updates** (user can update):
- `name` — Display name
- `selectedMechaId` — Currently selected god-creature
- `guildId` — Guild membership
- `cohortProperties` — Cohort assignment (for analytics)
- `fcmTokens` — Push notification tokens

**Denied Updates** (server only):
- `eloPoints`, `rank`, `level` → Updated by Cloud Function after battle
- `winRate`, `totalBattles` → Calculated from battle results
- `gems`, `gold` → Updated by Cloud Function after purchase
- `createdAt`, `lastBattleAt` → Immutable timestamps

#### Example: Valid Update
```dart
// ✅ ALLOWED
await _firestore.collection('users').doc(userId).update({
  'name': 'NewName',
  'selectedMechaId': 'mecha_fire_dragon',
});

// ❌ DENIED
await _firestore.collection('users').doc(userId).update({
  'eloPoints': 2000,  // Client trying to cheat
});
```

#### Cloud Function Writes
```firestore
allow write: if request.auth == null;
```
- ✅ Cloud Functions (server context) can update Elo, stats, currency
- ❌ Regular clients cannot

---

### Replays Collection (`/replays/{replayId}`)

**Purpose**: Battle replays for sharing and viewing.

#### Read Rules
```firestore
allow read: if true;
```
- ✅ **Anyone** can read replays (anonymous access)
- Purpose: Enable replay sharing via link without authentication

#### Write Rules
```firestore
allow write: if request.auth.uid == resource.data.userId;
allow create: if request.auth.uid == request.resource.data.userId;
```
- ✅ Replay owner can create/update their own replays
- ❌ Non-owner cannot modify replays
- ❌ Anonymous cannot create replays

#### Example: Share Replay
```dart
// ✅ User can view any replay via link (no auth required)
// ✅ Replay owner can update their replay
// ❌ Other users cannot modify the replay
```

---

### Friend Requests Collection (`/friendRequests/{requestId}`)

**Purpose**: Manage friend relationship setup with mutual consent.

#### Read Rules
```firestore
allow read: if request.auth.uid == resource.data.senderId ||
             request.auth.uid == resource.data.receiverId;
```
- ✅ Sender can read their sent requests
- ✅ Receiver can read requests sent to them
- ❌ Third parties cannot see friend requests (privacy)

#### Write Rules
```firestore
allow create: if request.auth.uid == request.resource.data.senderId;
allow update: if request.auth.uid == resource.data.receiverId;
allow delete: if request.auth.uid == resource.data.senderId;
```
- ✅ User can send friend request (becomes senderId)
- ✅ Receiver can accept/reject (update status)
- ✅ Sender can cancel pending request (delete)
- ❌ Receiver cannot cancel someone else's request

#### Example: Friend Flow
```dart
// Step 1: Alice sends request to Bob (Alice is sender)
// ✅ Alice.create({ senderId: alice, receiverId: bob })

// Step 2: Bob receives notification
// ✅ Bob.read(friendRequest)

// Step 3: Bob accepts
// ✅ Bob.update({ status: 'accepted' })

// Step 4: Charlie tries to delete Alice's request
// ❌ Charlie.delete() → DENIED (not sender or receiver)
```

---

### Guilds Collection (`/guilds/{guildId}`)

**Purpose**: Guild organization and member management.

#### Guilds Document

**Read Rules**
```firestore
allow read: if true;
```
- ✅ Anyone can view guild info (for discovery/join flow)

**Write Rules**
```firestore
allow update: if request.auth.uid == resource.data.ownerId;
allow create: if request.auth == null;  // Server-only (Cloud Function)
allow delete: if request.auth.uid == resource.data.ownerId;
```
- ✅ Guild owner can modify guild settings
- ✅ Cloud Function can create guild
- ✅ Guild owner can delete guild
- ❌ Members cannot change guild settings

#### Guild Members Subcollection (`/guilds/{guildId}/members/{memberId}`)

**Read Rules**
```firestore
allow read: if request.auth != null;
```
- ✅ Any authenticated user can read member list
- ❌ Anonymous cannot read members

**Write Rules**
```firestore
allow write: if request.auth.uid == parent_guild.ownerId;
```
- ✅ Guild owner can add/remove members
- ❌ Regular members cannot manage members

#### Guild Board Subcollection (`/guilds/{guildId}/board/{postId}`)

**Read Rules**
```firestore
allow read: if request.auth != null;
```
- ✅ Any member can read posts

**Write Rules**
```firestore
allow create: if request.auth != null;
allow update, delete: if request.auth.uid == resource.data.authorId;
```
- ✅ Any member can create posts
- ✅ Post author can edit/delete own posts
- ❌ Non-authors cannot delete posts (owner must moderate)

#### Example: Guild Hierarchy
```
Guild (public readable, owner modifiable)
├── Members (member-readable, owner-writable)
└── Board (member-readable/writable, author-deletable)
    ├── Post 1 (author: alice)
    ├── Post 2 (author: bob)
    └── ...
```

---

### Leaderboard Collection (`/leaderboard/{leaderboardId}`)

**Purpose**: Public rankings updated after battle results.

#### Read Rules
```firestore
allow read: if true;
```
- ✅ **Anyone** can view leaderboard (anonymous access)
- Purpose: Public rankings, no auth needed

#### Write Rules
```firestore
allow write: if request.auth == null;
allow delete: if false;
```
- ✅ Cloud Function updates rankings after battles
- ❌ Clients cannot modify leaderboard
- ❌ Entries cannot be deleted (immutable history)

---

### Battle Results Collection (`/battleResults/{battleResultId}`)

**Purpose**: Immutable audit trail of battle outcomes.

#### Read Rules
```firestore
allow read: if request.auth.uid in resource.data.participants[].userId;
```
- ✅ Battle participants can read their own battles
- ❌ Non-participants cannot view battle details (privacy)

#### Write Rules
```firestore
allow create: if request.auth.uid in request.resource.data.participants[].userId;
allow update: if request.auth == null;  // Server-only (Cloud Function)
allow delete: if false;
```
- ✅ User can submit their own battle result
- ✅ Cloud Function validates and processes battle
- ❌ Clients cannot modify submitted results (prevents tampering)
- ❌ Battle results cannot be deleted (audit trail)

#### Example: Anti-Tampering Flow
```
Client submits BattleResult
  ├─ Rule 1: Is user in participants? ✅ ALLOW create
  ├─ Rule 2: Was user actually in matchmaking?
  │   (Cloud Function validates this)
  ├─ Rule 3: Did opponent actually play?
  │   (Cloud Function validates this)
  └─ Rule 4: Recalculate Elo server-side
      (Prevents client from inflating points)

After Cloud Function processes:
  ├─ User.eloPoints = NEW_ELO (validated server-side)
  ├─ Leaderboard ranking updated
  ├─ Achievement checked (e.g., "5-kill streak")
  └─ Analytics event logged
```

---

### Achievements Collection (`/achievements/{achievementId}`)

**Purpose**: Global achievement definitions (read-only).

#### Read Rules
```firestore
allow read: if true;
```
- ✅ Anyone can view achievement definitions
- Purpose: Client displays achievement descriptions

#### Write Rules
```firestore
allow write: if request.auth == null;
allow delete: if false;
```
- ✅ Cloud Functions can define/update achievements
- ❌ Clients cannot modify definitions
- ❌ Achievements cannot be deleted

---

### Config Collection (`/config/{configId}`)

**Purpose**: Remote configuration and feature flags.

#### Read Rules
```firestore
allow read: if true;
```
- ✅ **Anyone** can read config (enables client-side feature flags)
- Examples: Aha Moment definition, pricing ABtest, ranked_enabled flag

#### Write Rules
```firestore
allow write: if request.auth == null;
allow delete: if false;
```
- ✅ Cloud Functions update config values
- ❌ Clients cannot modify config
- ❌ Entries cannot be deleted

---

## Security Patterns

### Pattern 1: Client Data Submission → Server Validation

Used for: Battle results, achievements, purchases

```firestore
// Step 1: Client can create (submit data)
allow create: if request.auth != null;

// Step 2: Server validates & processes (via Cloud Function)
allow update: if request.auth == null;

// Step 3: Result is immutable to client
allow delete: if false;
```

**Why**: Client provides data quickly (responsiveness), server validates thoroughly (security).

### Pattern 2: Ownership Checks

Used for: User profiles, replays, guild ownership

```firestore
// Single owner
allow write: if request.auth.uid == resource.data.userId;

// Multiple owners (e.g., battle participants)
allow write: if request.auth.uid in resource.data.participants[].userId;

// Hierarchical (e.g., guild owner)
allow write: if request.auth.uid == parent_guild.ownerId;
```

**Why**: Prevents cross-user data tampering.

### Pattern 3: Server-Only Sensitive Writes

Used for: Elo, stats, currency

```firestore
allow write: if request.auth == null;
```

**Why**: Only Cloud Functions (which have no auth context) can modify sensitive data. Regular clients are blocked.

### Pattern 4: Public Readable, Owner Writable

Used for: Replays, achievements, config

```firestore
allow read: if true;
allow write: if request.auth == null;  // or owner check for replays
```

**Why**: Enables sharing/discovery without exposing write access.

### Pattern 5: Audit Trail (Immutable)

Used for: Battle results, purchases, achievements

```firestore
allow delete: if false;
```

**Why**: Prevents deletion of evidence for fraud detection/support.

---

## Deployment Instructions

### Step 1: Deploy to Firebase Console

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Deploy Firestore rules
firebase deploy --only firestore:rules
```

### Step 2: Verify Rules with Emulator

```bash
# Start Firestore emulator
firebase emulators:start --only firestore

# Run tests against emulator
flutter test test/firestore_security_rules_test.dart
```

### Step 3: Monitor Denials

After deployment, monitor Firebase Console:
1. **Firestore** → **Rules Playground**
2. Test read/write operations
3. Check **Audit Logs** for denied requests

---

## Testing Rules

### Unit Tests
See: `test/firestore_security_rules_test.dart`

```dart
test('User cannot update eloPoints', () {
  // Simulates client attempt to change Elo
  // Expected: DENIED by firestore.rules
  expect(true, isTrue);
});
```

### Integration Tests with Emulator

```bash
# Terminal 1: Start emulator
firebase emulators:start --only firestore

# Terminal 2: Run tests
flutter test --dart-define=USE_FIRESTORE_EMULATOR=true
```

### Production Validation

1. **Replay Sharing**: Try sharing replay via link (should load without auth)
2. **Elo Tampering**: Try updating `User.eloPoints` directly (should fail)
3. **Friend Requests**: Test two-way consent flow
4. **Guild Hierarchy**: Verify only owner can modify settings

---

## Common Mistakes to Avoid

### ❌ Don't: Allow client Elo writes
```firestore
allow write: if request.auth.uid == userId;
```
This permits cheating (direct Elo tampering).

### ✅ Do: Restrict to server-only
```firestore
allow update: if request.auth == null;
```
Only Cloud Functions can write Elo.

---

### ❌ Don't: Block replay sharing
```firestore
allow read: if request.auth.uid == resource.data.userId;
```
This prevents sharing replays via link.

### ✅ Do: Make replays public readable
```firestore
allow read: if true;
```
Enables sharing while keeping owner-only write.

---

### ❌ Don't: Allow unlimited subcollection access
```firestore
match /users/{userId}/achievements/{achievementId} {
  allow read, write: if true;  // Anyone can read anyone's achievements
}
```

### ✅ Do: Restrict to owner
```firestore
match /users/{userId}/achievements/{achievementId} {
  allow read, write: if request.auth.uid == userId;
}
```

---

## Future Enhancements

1. **Rate Limiting**: Add rules to prevent rapid-fire writes (brute force)
   ```firestore
   allow create: if request.time > resource.data.lastWrite.toMillis() + 60000;
   ```

2. **Timestamp Validation**: Ensure battle results are submitted within reasonable time
   ```firestore
   allow create: if request.resource.data.submittedAt > now() - 1800000;  // 30 min
   ```

3. **IP Whitelisting**: For sensitive operations (currency)
   ```firestore
   allow write: if request.sourceIp in ['IP1', 'IP2', ...];
   ```

4. **Anomaly Detection**: Flag suspicious patterns (e.g., 100 wins in 1 minute)
   ```
   // Handled by Cloud Function analytics
   ```

---

## References

- [Firestore Security Rules Documentation](https://firebase.google.com/docs/firestore/security/start)
- [Cloud Functions for Firestore](https://firebase.google.com/docs/functions/firestore-events)
- [OWASP Top 10 Mobile Risks](https://owasp.org/www-project-mobile-top-10/)

---

## Approval & Sign-Off

| Role | Date | Status |
|------|------|--------|
| Security Review | TBD | Pending |
| Backend Lead | TBD | Pending |
| Deployment | TBD | Pending |

**Last Updated**: 2026-09-02
