# Known Issues & Limitations

## Current Status: Phase 5 Sprint 3 Complete

As of 2026-09-02, the following systems are fully functional:
- ✅ Firebase Core + Authentication + Firestore (basic)
- ✅ Push Notifications (FCM + local fallback)
- ✅ Achievement System (11 achievements, event-driven tracking)
- ✅ Analytics (funnel + cohort tracking)
- ✅ Monetization (shop UI, Remote Config pricing)
- ✅ 2.5D Battle Engine (Flame-based rendering)
- ✅ Elo System + Matchmaking
- ✅ Joystick + Manual Combat

The issues below represent known gaps or design decisions that will be resolved in future sprints.

---

## Critical Issues (Phase 6 Sprint 1+)

### 1. FCM Token Persistence to Firestore
**Severity**: HIGH  
**Status**: Design Complete, Implementation Pending  
**Description**: PushNotificationService retrieves FCM token and could subscribe to topics, but the token is not persisted to `User.fcmTokens[]` array in Firestore. This means:
- Server cannot send targeted push notifications to specific users (only topics)
- User push notification preferences cannot be retrieved after app restart
- Server-side push notification delivery status is not trackable

**Workaround**: Currently uses only topic-based subscriptions (all users in a topic receive the same notification).

**Solution**: Add method `PushNotificationService.persistFcmToken(userId)` that:
1. Retrieves current FCM token via `FirebaseMessaging.instance.getToken()`
2. Updates `User.fcmTokens` array in Firestore via Firestore batch write
3. Handles token refresh (re-persist when new token generated)

**Timeline**: Phase 6 Sprint 1

**Testing**: Add `test/push_notification_firestore_persistence_test.dart` to verify Firestore write succeeds.

---

### 2. Android 13+ Notification Permission Prompts Not Implemented
**Severity**: HIGH (Android 13+ only)  
**Status**: Design Complete, Implementation Pending  
**Description**: Android 13 introduced runtime permission for `POST_NOTIFICATIONS`. Current code doesn't request this permission at runtime; Android will simply not show notifications.

**Workaround**: Users must manually enable notifications in Settings after install (invisible and often missed).

**Solution**: Implement runtime permission request:
```dart
// In PushNotificationService.init()
if (Platform.isAndroid && await DeviceInfoPlugin().androidInfo.version.sdkInt >= 33) {
  final permission = await Permission.notification.request();
  if (!permission.isGranted) {
    // Log that user denied, show in-app nudge
  }
}
```

**Timeline**: Phase 6 Sprint 1 (same sprint as FCM persistence)

**Testing**: Manually test on Android 13+ device; verify permission prompt appears once on first app launch.

---

### 3. Lottie Animation Assets Not Included
**Severity**: HIGH (UX Impact)  
**Status**: Feature Configured, Assets Pending  
**Description**: Lottie animation definitions created in `lib/services/asset_service.dart`:
- `kill_burst.json` — Particle burst effect on kill
- `win_celebration.json` — Victory animation
- `aha_moment.json` — Aha Moment unlock banner
- `level_up.json` — Level up notification
- `lose_fade.json` — Defeat animation

But actual `.json` files are NOT in `assets/animations/` (folder created but empty). AssetService gracefully falls back to no-op if files missing, but visual impact is significant.

**Workaround**: None; app continues with reduced visual polish.

**Solution**: 
1. Designer creates Lottie animations in LottieFiles or After Effects
2. Export as JSON (.json)
3. Place files in `assets/animations/`
4. AssetService automatically loads on app start

**Timeline**: Depends on design team; estimated Phase 7 (post-core feature freeze)

**Testing**: Verify AssetService logs animation file paths in debug output once assets provided.

---

### 4. Sound Effects & BGM Assets Not Included
**Severity**: MEDIUM (UX Impact)  
**Status**: Feature Configured, Assets Pending  
**Description**: Audio effects defined in `lib/services/audio_service.dart`:

**SE (Sound Effects)**:
- `kill.mp3` — Kill event
- `aha_moment.mp3` — Aha Moment achievement
- `win.mp3` — Battle victory
- `lose.mp3` — Battle defeat
- `button_tap.mp3` — UI button click
- `level_up.mp3` — Level up notification
- `evolution_select.mp3` — Evolution choice made
- `skill_activate.mp3` — Skill cast
- `critical_hit.mp3` — Critical damage
- `heal.mp3` — Healing event
- `item_pickup.mp3` — Item acquisition
- `error.mp3` — Error state

**BGM (Background Music)**:
- `lobby.mp3` — Lobby/home theme (loop)
- `matching.mp3` — Matchmaking theme (loop)
- `battle.mp3` — In-battle theme (loop, varies by map)
- `result_win.mp3` — Victory result screen (loop)

Actual `.mp3` files not in `assets/sounds/` (folder created but empty). AudioService/BGMService gracefully fail without audio if files missing.

**Workaround**: None; game runs without audio feedback.

**Solution**:
1. Sound designer creates/sources audio tracks
2. Export as `.mp3` (or `.wav` for lossless → convert to MP3)
3. Place files in `assets/sounds/`
4. AudioService/BGMService automatically load on use

**Timeline**: Depends on sound design team; estimated Phase 7.

**Testing**: Verify AudioService logs audio file paths in debug output. Test on device with audio enabled.

---

### 5. Actual RevenueCat Configuration Pending
**Severity**: MEDIUM  
**Status**: Integration Complete, Credentials Pending  
**Description**: RevenueCat SDK integrated in `lib/services/purchases_service.dart`, but `AppConfig.revenueCatApiKey` is empty string. When empty, all purchase methods return success silently (no-op).

**Workaround**: App can demo shop UI without actual charging.

**Solution**:
1. RevenueCat account created
2. iOS App Store API key generated in App Store Connect
3. Android Google Play Service Account JSON downloaded
4. Keys added to RevenueCat console
5. `AppConfig.revenueCatApiKey` updated
6. In-app product SKUs configured:
   - `com.petitworksapps.shinjukuleague.battlepass_monthly`
   - `com.petitworksapps.shinjukuleague.skin_gacha_1x`
   - `com.petitworksapps.shinjukuleague.skin_gacha_10x`

**Timeline**: Phase 6 (post-core features, pre-release)

**Testing**: Test purchase flow with RevenueCat sandbox accounts.

---

## Medium Priority Issues

### 6. Firestore Security Rules Not Finalized
**Severity**: MEDIUM  
**Status**: Default Allow Rules (Development Only)  
**Description**: Firestore currently runs in **test mode** (all reads/writes allowed). Production must implement security rules:
- Users can read/write only own documents
- Elo updates only via Cloud Functions (prevent client-side tampering)
- Replay data publicly readable (shareable)
- Achievement state user-owned

**Solution**: Deploy security rules before production:
```firestore
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users: own data only
    match /users/{userId} {
      allow read: if request.auth.uid == userId;
      allow write: if request.auth.uid == userId && !request.resource.data.elo_points.exists();
    }
    
    // Replays: public read, owner write
    match /replays/{replayId} {
      allow read: if true;
      allow write: if request.auth.uid == resource.data.userId;
    }
    
    // Elo: server-only updates via Cloud Functions
    allow read: if false;
    allow write: if false;
  }
}
```

**Timeline**: Before production launch

**Testing**: Run Firestore rules emulator locally to verify access control.

---

### 7. Cloud Functions for Server-Side Elo Validation Not Deployed
**Severity**: MEDIUM  
**Status**: Design Documented, Not Implemented  
**Description**: Elo calculation in BattleEngine is client-side for instant feedback. However, clients could theoretically tamper with Elo after sending battle result. Production requires Cloud Function:

```
BattleResult submitted to Firestore
  ↓
Cloud Function triggered (battle/result created)
  ↓
Validate participants (were they in matching lobby?)
  ↓
Recalculate Elo server-side
  ↓
Update User.eloPoints (server-authorized only)
  ↓
Update matchmaking leaderboard
```

**Workaround**: None; client-side Elo is vulnerable to tampering (low risk if players don't know).

**Solution**: Implement `battle-result-validator` Cloud Function (JavaScript/Python).

**Timeline**: Phase 6 Sprint 2

**Testing**: Simulate tampered BattleResult; verify Cloud Function rejects and recalculates.

---

### 8. Cohort Properties Not Persisted to Firestore
**Severity**: MEDIUM  
**Status**: Method Defined, Firestore Persistence Not Implemented  
**Description**: `AnalyticsService.setCohortProperties()` logs to Firebase Analytics but does not update `User.cohortProperties` in Firestore. This means:
- Cohort data is only in Analytics dashboard (transient)
- Cannot query users by cohort via Firestore (e.g., "send email to D1Payers")
- Cohort assignment not visible in user admin panel

**Workaround**: Use Firebase Analytics dashboard for cohort reporting.

**Solution**: Extend `AnalyticsService.setCohortProperties()` to:
1. Accept `cohortProperties` struct
2. Update `User.cohortProperties` in Firestore
3. Maintain consistency with Analytics logging

**Timeline**: Phase 6 Sprint 1

**Testing**: Add test verifying Firestore `User.cohortProperties` updated correctly.

---

## Low Priority Issues

### 9. LocalNotification Sounds/Haptics Not Customized Per Type
**Severity**: LOW  
**Status**: Feature Partially Implemented  
**Description**: `PushNotificationService._showLocalNotification()` uses default system sound for all notification types. Should customize per notification type:
- Achievement unlock: distinctive celebratory sound + medium haptics
- Friend online: subtle notification sound + light haptics
- Guild invite: attention-grabbing sound + strong haptics
- Maintenance alert: alert sound + haptic pulse

**Workaround**: Users hear generic notification sound for all types.

**Solution**: Create sound files and haptic profiles per notification type; configure `flutter_local_notifications` with custom settings.

**Timeline**: Phase 7 (polish phase)

---

### 10. Mecha Selection Persistence Not Connected to Battle
**Severity**: LOW  
**Status**: Partial Implementation  
**Description**: `MechaSelectScreen` allows players to select a god-creature (神獣) and persists to `User.selectedMechaId`. However:
- Selection is only cosmetic display in BattleScreen
- Mecha stats (ATK, DEF, SPD) are fetched from static `MechaCatalog`, not from player-customized upgrades
- No progression system for leveling/evolving owned Mecha

**Solution (Future Feature)**:
1. Add `User.ownedMecha[]` collection
2. Track leveling/skill unlock per Mecha
3. Load stats from Firestore instead of static catalog
4. Implement Mecha upgrade UI and progression mechanics

**Timeline**: Season 2+ (post-core feature freeze)

---

### 11. Replay Sharing Returns Text Summary Only
**Severity**: LOW (By Design)  
**Status**: Implementation Complete  
**Description**: ReplayService generates Wordle-style text summary for sharing (e.g., "⚔️🔥⚔️🔥⚔️ [Legendary 5-0 Victory]") rather than video encoding. This is intentional (lighter payload, faster sharing) but players may want replay video in future.

**Design Decision**: Wordle-style text sharing was chosen for:
- Instant sharing (no encoding delay)
- Low bandwidth (~ 200 bytes vs 50+ MB for video)
- Platform-agnostic (works on all social media)

**Future Enhancement**: Implement optional video replay encoding (Phase 8+).

---

### 12. BattleEngine Doesn't Detect Stalemate/Timeout
**Severity**: LOW  
**Status**: Design Documented, Not Critical  
**Description**: Current BattleEngine runs for fixed `maxRounds` (300 ticks = ~5 minutes). If both teams survive, battle ends in draw. Edge case: if only Bots remain, they might never kill each other (unlikely but possible).

**Solution**: Implement timeout detection and team elimination:
1. If battle exceeds `maxRounds`, switch to sudden-death mode
2. All participants lose HP per tick
3. Last team standing wins

**Timeline**: Phase 6 Sprint 3 (polish)

---

### 13. Onboarding Tutorial Not Fully Interactive
**Severity**: LOW  
**Status**: Screens Defined, Logic Simplified  
**Description**: `OnboardingScreen` shows 3 explanation slides but doesn't enforce tutorial steps. Player could skip tutorials entirely or replay multiple times.

**Solution (Future)**:
1. Enforce mandatory tutorial sequence (can't skip)
2. Track `User.tutorialCompleted` state
3. Lock ranked/advanced features until tutorial complete

**Timeline**: Phase 6 Sprint 2

---

## Limitations by Design

### Network Requirements
- **Minimum**: 2G network sufficient for turn-based updates
- **Recommended**: 4G+ for low-latency competitive play
- **Offline**: Some features (achievements, local battles) work offline, but multiplayer/rankings require connection

### Device Support
- **Minimum iOS**: 11.0
- **Minimum Android**: API 21 (Android 5.0)
- **Recommended**: iOS 14+, Android 10+
- **Tablets**: Supported but UI not optimized (portrait/landscape)

### Game Design Constraints
- **Battle Duration**: Fixed 5 minutes (300 ticks)
- **Team Size**: Fixed 5v5 (cannot be customized)
- **Ranked Unlock**: Requires level 3+ (design decision)
- **Elo Range**: ±100-200 per match (cap on swing to prevent smurfing)

---

## Tracking & Updates

### How to Report Issues
1. Check this document first (may already be listed)
2. Reproduce on latest build
3. Provide:
   - Device model + OS version
   - Crash log (if applicable)
   - Steps to reproduce
   - Expected vs actual behavior

### Issue Resolution Timeline
- **Critical** (P0): Fixed within 48 hours, hotfixed to production
- **High** (P1): Fixed within 1 sprint, included in next release
- **Medium** (P2): Fixed within 2 sprints
- **Low** (P3): Fixed when convenient (polish phase)

---

## References

- [GitHub Issues](https://github.com/zka32101/shinjuu-league/issues) — for public bug reports
- [CLAUDE.md](../CLAUDE.md) — project status and architecture
- [RELEASE_CHECKLIST.md](./RELEASE_CHECKLIST.md) — pre-release tasks
