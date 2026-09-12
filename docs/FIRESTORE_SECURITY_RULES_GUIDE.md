# Firestore Security Rules Guide

## Overview

This document describes the Firestore Security Rules for 神獣リーグ (Shinjuu League), with emphasis on the Phase 33 Role-Based Access Control (RBAC) system for the admin dashboard.

**Key Principle**: Defense in depth — both client-side (Flutter UI) and database-level (Firestore Rules) access control.

---

## Security Architecture

### Three-Layer Defense

```
Layer 1: UI Permission Checks (Flutter/Riverpod)
         ↓ (User makes request)
Layer 2: Firestore Security Rules (Rules Language)
         ↓ (If authorized, proceed)
Layer 3: Cloud Functions Validation (Server-side business logic)
```

### Authentication Model

- **Authenticated Users**: `request.auth != null` (logged in via Firebase Auth)
- **Server (Cloud Functions)**: `request.auth == null` (service-to-service, no user context)
- **Anonymous Users**: Denied by default (all rules require authentication or special case)

---

## Helper Functions

### Core Authentication

```firestore
function isAuthenticated()
  → true if user is logged in
  
function isServerUpdate()
  → true if request is from Cloud Functions (no auth.uid)
```

### Admin Role Resolution

```firestore
function getUserAdminRole()
  → Reads from /admin_users/{userId} collection
  → Returns role string: 'admin' | 'operator' | 'viewer' | null
  
function isAdmin()
  → true if authenticated AND role == 'admin'
  
function isOperator()
  → true if authenticated AND role == 'operator'
  
function isViewer()
  → true if authenticated AND role == 'viewer'
```

**Example Role Document Structure** (`/admin_users/{userId}`):
```json
{
  "userId": "user123",
  "role": "admin",
  "email": "admin@example.com",
  "assignedAt": "2026-09-12T10:00:00Z",
  "assignedBy": "founder_uid"
}
```

---

## Collection-Level Security Rules

### 1. `/users/{userId}` — User Profiles

**Who Can Read**: Only the user themselves
```firestore
allow read: if isUserOwnData(userId)
```

**Who Can Create**: User during onboarding (without sensitive fields)
```firestore
allow create: if isUserOwnData(userId) && !request.resource.data.keys().hasAny([
  'eloPoints', 'rank', 'winRate', 'totalBattles', 'gems', 'gold'
])
```

**Who Can Update**: User only non-sensitive fields (name, selectedMechaId, etc.)
```firestore
allow update: if isUserOwnData(userId) && !request.resource.data.keys().hasAny([
  'eloPoints', 'rank', 'level', 'winRate', 'totalBattles',
  'gems', 'gold', 'createdAt', 'lastBattleAt'
])
```

**Who Can Write Sensitive Fields**: Cloud Functions only
```firestore
allow write: if isServerUpdate()  // For Elo, stats, currency updates
```

**Who Can Delete**: Nobody (audit trail)
```firestore
allow delete: if false
```

---

### 2. `/admin_users/{userId}` — Admin Role Assignments (Phase 33)

**Purpose**: Central registry of admin user roles

**Document Structure**:
```json
{
  "userId": "user_abc",
  "role": "admin",  // 'admin' | 'operator' | 'viewer'
  "email": "admin@game.com",
  "assignedAt": "2026-09-12T10:00:00Z",
  "assignedBy": "founder_uid",
  "permissions": [
    "manageAdminRoles",
    "viewFeatureFlags",
    "viewDifficulty",
    "viewExperiments",
    "viewAuditLog",
    "viewSnapshots"
  ]
}
```

**Access Control**:

| Role | Read | Write | Delete |
|------|------|-------|--------|
| Admin | ✅ | ✅ | ❌ |
| Operator | ✅ | ❌ | ❌ |
| Viewer | ❌ | ❌ | ❌ |
| Regular User | ❌ | ❌ | ❌ |

```firestore
match /admin_users/{userId} {
  allow read, write: if isAdmin()
  allow read: if isOperator()
  allow delete: if false
}
```

**Enforcement**: Only admins can assign/revoke roles via Cloud Function

---

### 3. `/admin_role_audit_log/{logId}` — Role Change History (Phase 33)

**Purpose**: Immutable audit trail of all role assignment/changes

**Document Structure**:
```json
{
  "logId": "log_xyz",
  "timestamp": "2026-09-12T10:05:30Z",
  "userId": "target_user_id",
  "action": "ASSIGN_ROLE",  // 'ASSIGN_ROLE' | 'UPDATE_ROLE' | 'REVOKE_ROLE'
  "fromRole": null,
  "toRole": "operator",
  "performedBy": "admin_user_id",
  "performedByEmail": "admin@game.com",
  "reason": "Promoted to manage experiments"
}
```

**Access Control**:

| Role | Read | Write | Delete |
|------|------|-------|--------|
| Admin | ✅ | ✅* | ❌ |
| Operator | ✅ | ❌ | ❌ |
| Viewer | ❌ | ❌ | ❌ |
| Server | — | ✅ | — |

*Admin can write for testing; production writes via Cloud Functions only

```firestore
match /admin_role_audit_log/{logId} {
  allow read, write: if isAdmin()
  allow read: if isOperator()
  allow write: if isServerUpdate()
  allow delete: if false
}
```

**Immutability**: Logs cannot be deleted — compliance requires full history

---

### 4. `/audit_log/{logId}` — General Admin Operations Log (Phase 33)

**Purpose**: Comprehensive trail of all admin dashboard operations

**Document Structure**:
```json
{
  "logId": "audit_abc",
  "timestamp": "2026-09-12T10:10:00Z",
  "userId": "admin_uid",
  "userEmail": "admin@game.com",
  "userRole": "admin",
  "action": "SET_ROLLOUT",  // 'SET_ENABLED', 'SET_ROLLOUT', 'APPLY_PRESET', etc.
  "resourceType": "feature_rollout",
  "resourceId": "weekly_quest",
  "details": {
    "oldValue": "25",
    "newValue": "50",
    "reason": "Weekend boost"
  }
}
```

**Access Control**:

| Role | Read | Write | Delete |
|------|------|-------|--------|
| Admin | ✅ | ❌ | ❌ |
| Operator | ✅ | ❌ | ❌ |
| Viewer | ✅ | ❌ | ❌ |
| Server | — | ✅ | — |

```firestore
match /audit_log/{logId} {
  allow read: if isAdmin()
  allow read: if isOperator()
  allow read: if isViewer()
  allow write: if isServerUpdate()
  allow delete: if false
}
```

**Non-Blocking Writes**: Audit logging failures don't prevent core operations

---

### 5. Other Collections (Pre-existing)

#### `/replays/{replayId}` — Battle Replays
- Anyone can read (public sharing)
- Owner can write/delete
- Cloud Functions can create

#### `/friendRequests/{requestId}` — Friend System
- Sender and receiver can read
- Receiver can accept/reject
- Sender can delete own request

#### `/guilds/{guildId}` — Guild Management
- Anyone can read (for join/search)
- Guild owner can update
- Members subcollection is restricted to guild members

#### `/leaderboard/{leaderboardId}` — Public Rankings
- Anyone can read (public rankings)
- Cloud Functions only can update

#### `/battleResults/{battleResultId}` — Match Results
- Participants can read own results
- Participants can create
- Cloud Functions can update (process/validate)

#### `/config/{configId}` — Feature Flags & Config
- Anyone can read (for client features)
- Cloud Functions only can update

---

## Validation Logic in Rules

### Example: Admin Creating Role Assignment

**Client Request**:
```dart
// Flutter code attempts to assign role
firestore.collection('admin_users').doc(targetUserId).set({
  'userId': targetUserId,
  'role': 'operator',
  'assignedAt': FieldValue.serverTimestamp(),
  'assignedBy': currentUser.uid,
})
```

**Firestore Rules Check**:
1. Is `request.auth` non-null? (Is user logged in?)
2. Does `/admin_users/currentUserId` exist?
3. Is `role` field == 'admin'?
4. If all true → Allow write

**If Denied**:
- Error: "PERMISSION_DENIED"
- Client-side error handler shows "Insufficient Permissions"

**If Allowed**:
- Document written
- Cloud Function triggered (optional validation)
- Audit log entry created automatically

---

## Security Principles

### 1. **Deny by Default**
```firestore
// Final fallback rule
match /{document=**} {
  allow read, write, delete: if false
}
```
Any collection/document not explicitly allowed is rejected.

### 2. **Role-Based, Not User-Based**
```firestore
// ❌ WRONG: Hardcode specific user IDs
allow write: if request.auth.uid == 'admin_user_123'

// ✅ CORRECT: Check admin_users collection
allow write: if isAdmin()  // Reads current role dynamically
```

### 3. **Immutable Audit Trails**
```firestore
// All audit collections reject deletes
allow delete: if false
```

### 4. **Server-Side Authority**
```firestore
// Critical updates (Elo, stats, role assignments) only via Cloud Functions
allow write: if isServerUpdate()  // Not from user auth
```

### 5. **Minimal Privilege**
- Viewers: read-only audit logs
- Operators: read audit logs + admin assignments
- Admins: full CRUD on admin collections + all reads

---

## Testing & Validation

### Local Testing with Firebase Emulator

```bash
# Start emulator
firebase emulators:start

# Run tests (Dart)
dart test test/firestore_rules_test.dart

# Or test via Firestore emulator REST API
curl -X POST http://localhost:8080/v1/projects/shinjuu-league/databases/\(default\)/documents/admin_users \
  -H "Authorization: Bearer $(gcloud auth identity-token --audiences=http://localhost:8080)" \
  -d '{"fields": {"role": {"stringValue": "admin"}}}'
```

### Rule Verification Checklist

- [ ] `/admin_users` write fails for non-admin users
- [ ] `/admin_role_audit_log` read fails for viewers
- [ ] `/audit_log` read succeeds for all admin roles
- [ ] Server updates (Cloud Functions) bypass role checks
- [ ] Delete operations fail on all audit collections
- [ ] Regular users cannot access any admin collections

---

## Deployment Checklist

1. **Review Rules**: Verify all role references match `UserAdminRole` enum
2. **Test Locally**: Run Dart + emulator integration tests
3. **Staging Validation**: Deploy to Firebase staging project, test with real auth
4. **Audit Trail Check**: Verify audit_log entries appear after operations
5. **Production Rollout**:
   ```bash
   firebase deploy --only firestore:rules
   ```
6. **Monitoring**: Check Firebase console for rule rejection errors (should be 0% on admin collections)

---

## Common Issues & Solutions

### Issue: "PERMISSION_DENIED" on `/admin_users` read

**Cause**: User not in admin_users collection (no admin role assigned)

**Solution**:
1. Admin navigates to `/admin-roles` screen
2. Admin assigns role via UI (calls AdminRoleService.assignRoleToUser)
3. Firestore document created in `/admin_users/{userId}`
4. Subsequent reads succeed

### Issue: Audit log writes silently failing

**Cause**: Non-blocking audit logging, errors not visible

**Solution**:
1. Check `_logOperation()` in WebAdminDashboardService for try-catch
2. Look at Firebase Console → Firestore → Usage for rule violations
3. Ensure AuditLoggerService is properly initialized in service_providers.dart

### Issue: Cloud Function cannot update Elo after battle

**Cause**: Function's service account lacks `isServerUpdate()` permission

**Solution**:
1. Verify Cloud Function runs with Firestore admin credentials
2. In `functions/` Node.js: use `admin.firestore()` (auto-authenticated)
3. No `request.auth` in Cloud Function context (isServerUpdate() returns true)

---

## Future Enhancements

- [ ] Time-based access (e.g., only during game maintenance windows)
- [ ] Rate limiting (max role changes per hour)
- [ ] IP whitelist for admin operations
- [ ] 2FA requirement for sensitive operations
- [ ] Automated reports of access anomalies

---

**Last Updated**: 2026-09-12  
**Version**: 1.0  
**Maintainer**: Claude Code (Haiku)
