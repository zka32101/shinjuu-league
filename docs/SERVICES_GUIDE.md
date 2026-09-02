# Services Architecture Guide

## Overview

The shinjuu-league project implements a **layered service architecture** with three primary integration tiers:

1. **Core Services**: Foundation services (Auth, Firestore, Remote Config)
2. **Engagement Services**: User engagement systems (Push Notifications, Achievements, Analytics)
3. **Monetization Services**: Revenue integration (Purchases, Analytics Funnel)

All services follow the **Singleton Pattern** to maintain consistent state across the application lifecycle.

---

## Service Catalog

### 1. PushNotificationService

**Purpose**: FCM (Firebase Cloud Messaging) integration with local notification fallback for foreground message handling.

**Key Responsibilities**:
- Initialize FCM and request user notification permissions
- Subscribe/unsubscribe users to topic-based notification channels
- Handle foreground/background/terminated message states
- Display local notifications when app is in foreground
- Parse and route notification payloads

**Architecture**:
```dart
PushNotificationService()  // Singleton
├── Firebase Messaging Layer
│   ├── Foreground handler: _handleForegroundMessage()
│   ├── Background handler: _handleMessageOpenedApp()
│   └── Initialization: _requestNotificationPermissions()
├── Local Notification Layer
│   └── _showLocalNotification()
└── Topic Management
    ├── subscribeToTopic(topicName)
    └── unsubscribeFromTopic(topicName)
```

**Notification Topics**:
- `battlePassSeasonStart`: BattlePass seasonal updates
- `maintenanceAlert`: Server maintenance notifications
- `serverUpdate`: Game balance/feature updates
- `rankedSeasonEnd`: Ranked season conclusions
- `rankedPromotionAvailable`: Ranked rank-up availability
- `friendOnline`: Friend status changes
- `guildInvite`: Guild invitation notifications
- `achievementUnlocked`: Achievement unlock notifications

**Error Handling**:
- Missing FCM token → logs warning, continues (user notifications disabled)
- Permission denied → gracefully degraded to in-app notifications only
- Malformed payload → applies defaults, does not crash

**Integration Points**:
```
Firebase Cloud Messaging → PushNotificationService → LocalNotificationService
                                                   → AchievementService
                                                   → AnalyticsService
```

---

### 2. AchievementService

**Purpose**: Track user progression toward 11 achievements across 5 categories (tutorial, combat, ranked, monetization, social).

**Key Responsibilities**:
- Maintain state of unlocked achievements and progress counters
- Process `AchievementProgressEvent` to check unlock conditions
- Return list of newly unlocked achievements per event
- Provide achievement details (name, description, rarity, icon)
- Support debug unlock/dump functionality

**Achievement Catalog** (11 total):

| Category | Achievement | Trigger | Progress |
|----------|-------------|---------|----------|
| Tutorial | `tutorial_complete` | Complete tutorial | One-time event |
| Combat | `first_kill` | Achieve first kill in any battle | One-time event |
| Combat | `ten_kills` | Accumulate 10 kills total | Counter: 0→10 |
| Combat | `kill_streak_3` | Achieve 3-kill streak | Streak data |
| Ranked | `first_ranked_match` | Enter first ranked battle | One-time event |
| Ranked | `win_streak_5` | Win 5 ranked battles consecutively | Counter: 0→5 |
| Ranked | `level_10` | Reach player level 10 | Level tracking |
| Monetization | `first_battlepass` | Purchase BattlePass | One-time event |
| Monetization | `skin_collector` | Own 3 unique skins | Counter: owned_skins |
| Social | `social_butterfly` | Have 3+ friends | Counter: friend_count |
| Social | `guild_founder` | Create a guild | One-time event |

**State Management**:
```dart
AchievementService()  // Singleton
├── _unlockedAchievements: Set<String>
│   └── Persisted across app restarts (in-memory for now)
├── _progressCounters: Map<String, int>
│   └── Tracks cumulative progress (kills, level, etc.)
├── _achievementCatalog: Map<String, Achievement>
│   └── Static metadata for all 11 achievements
└── Methods
    ├── updateProgress(event) → List<String> (newly unlocked)
    ├── getProgress(achievementId) → int
    ├── getAllAchievements() → List<Achievement>
    ├── getAchievementDetails(id) → Achievement?
    └── Debug methods
```

**Event Flow**:
```
AchievementProgressEvent (firstKill, killCountIncrement, levelUp, etc.)
    ↓
updateProgress()
    ↓
_checkUnlock() for each achievement
    ↓
Return List<String> of newly unlocked achievements
    ↓
UI displays unlock animation + PushNotificationService sends notification
    ↓
AnalyticsService.logAchievementUnlocked()
```

**Error Handling**:
- Invalid event type → ignored, returns empty list
- Unknown achievement ID → gracefully skipped (null-safe getters)
- Duplicate unlock attempt → returns empty list (idempotent)

**Integration Points**:
```
BattleEngine (kill events) → AchievementService → PushNotificationService
                                              → AnalyticsService
UserViewModel (level-up) → AchievementService
```

---

### 3. AnalyticsService

**Purpose**: Unified analytics event logging for Firebase Analytics with funnel tracking and cohort segmentation.

**Responsibilities**:
- Log KPI events (onboarding funnel, Aha Moment, conversions)
- Track retention metrics (Day 1/7/30 active, time-to-Aha)
- Manage user cohorts (install date, platform, purchase behavior)
- Log achievement unlocks with metadata
- Ensure graceful degradation when Firebase unavailable

**Event Categories**:

#### Onboarding Funnel
```dart
logOnboardingStart(userId)
logTutorialComplete(userId)
logFirstBattleEnter(userId)
logFirstBattleWin(userId)
```
**Cohort**: Tracks progression from signup → first win.

#### Conversion Funnel (LTV)
```dart
logShopViewed(userId)
logPurchaseComplete(userId, productType, price)
  // productType: 'battlepass' | 'skin_gacha'
```
**Cohort**: Tracks shop visit → purchase conversion.

#### Ranked Adoption
```dart
logRankedUnlockAvailable(userId)
logRankedEntryAction(userId)
```
**Cohort**: Tracks ranked feature activation.

#### Retention Metrics
```dart
logDay1Active(userId)
logDay7Active(userId)
logDay30Active(userId)
logTimeToAhaMoment(userId, secondsToFirstKill)
```
**Cohort**: Measures engagement depth and Aha Moment timing.

#### Achievement Tracking
```dart
logAchievementUnlocked(userId, achievementId, rarity)
  // rarity: 'common' | 'rare' | 'legendary'
```

#### Cohort Properties
```dart
setCohortProperties(
  userId,
  installCohort: '2026-09-02',        // YYYY-MM-DD
  platformCohort: 'android',          // 'ios' | 'android'
  purchaseCohort: 'F2P',              // 'D1Payer' | 'D7Payer' | 'D30Payer' | 'F2P' | 'Whale'
)
```
**Purpose**: Segment users for cohort analysis in Firebase Console.

**Data Flow**:
```
Application Event (kill, purchase, level-up)
    ↓
Service logs to AnalyticsService.log*() method
    ↓
Firebase Analytics tracks event + user properties
    ↓
Firebase Console: Real-time funnel visualization + cohort reports
```

**Error Handling**:
- Firebase initialization incomplete → methods return normally (silent fail-safe)
- Network unavailable → events queued locally, sent when connection restored
- Invalid event parameters → logged as-is (Firebase validates server-side)

**Integration Points**:
```
BattleEngine → logFirstBattleWin(), logTimeToAhaMoment()
AchievementService → logAchievementUnlocked()
PurchasesService → logPurchaseComplete()
UserViewModel → setCohortProperties()
OnboardingScreen → logOnboardingStart(), logTutorialComplete()
```

---

## Cross-Service Integration Patterns

### Pattern 1: Achievement Unlock → Notification → Analytics

```
User kills first enemy in battle
    ↓
BattleEngine fires CombatEvent(type: kill)
    ↓
BattleViewModel receives kill event
    ↓
AchievementService.updateProgress(AchievementProgressEvent(type: firstKill))
    ↓
Returns ['first_kill'] (newly unlocked)
    ↓
PushNotificationService.subscribeToTopic('achievementUnlocked')
    ↓
AnalyticsService.logAchievementUnlocked('user123', 'first_kill', 'common')
    ↓
Firebase Console: Achievement unlock event + user cohort analysis
```

### Pattern 2: Monetization Funnel (Purchase → Cohort Update)

```
User views shop
    ↓
ShopScreen.init() → AnalyticsService.logShopViewed(userId)
    ↓
User purchases BattlePass (¥500)
    ↓
PurchasesService handles transaction
    ↓
AnalyticsService.logPurchaseComplete(userId, 'battlepass', 500.0)
    ↓
UserViewModel updates `user.purchaseCohort = 'D1Payer'`
    ↓
AnalyticsService.setCohortProperties(userId, purchaseCohort: 'D1Payer')
    ↓
Firebase Console: Funnel visualization (shop_viewed → purchase_complete)
                  Cohort segmentation (F2P → D1Payer transition)
```

### Pattern 3: Onboarding Funnel Tracking

```
User launches app
    ↓
OnboardingScreen → AnalyticsService.logOnboardingStart(userId)
    ↓
User completes tutorial
    ↓
AnalyticsService.logTutorialComplete(userId)
    ↓
EvolutionSelectScreen + BattleScreen
    ↓
User achieves first kill (Aha Moment)
    ↓
AnalyticsService.logTimeToAhaMoment(userId, elapsedSeconds)
    ↓
BattleEndScreen
    ↓
AnalyticsService.logFirstBattleWin(userId)
    ↓
Firebase Console: Onboarding funnel cohort analysis (install → Aha Moment)
```

---

## Offline & Error Resilience

### Firebase Unavailable Scenarios

| Scenario | PushNotificationService | AchievementService | AnalyticsService |
|----------|------------------------|--------------------|------------------|
| No network | Local notifications only | Continues (in-memory state) | Queues events locally |
| FCM token missing | Topic subscriptions fail silently | Unaffected | Continues |
| Permission denied | No notifications | Unaffected | Continues |
| Firebase uninitialized | init() logs error, continues | Continues | Events dropped silently |

### Graceful Degradation

1. **PushNotificationService**: If FCM unavailable, app continues; user receives in-app notifications only.
2. **AchievementService**: Fully offline-capable; state preserved in-memory.
3. **AnalyticsService**: Events queued locally; sent when connection restored (Firebase default behavior).

---

## Riverpod Integration

All services are exposed via Riverpod providers in `lib/data/providers/service_providers.dart`:

```dart
final pushNotificationServiceProvider = Provider<PushNotificationService>(...);
final achievementServiceProvider = Provider<AchievementService>(...);
final analyticsServiceProvider = Provider<AnalyticsService>(...);
```

**Usage in Widgets**:
```dart
class BattleScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analytics = ref.watch(analyticsServiceProvider);
    final achievements = ref.watch(achievementServiceProvider);
    
    // Services available for event logging
  }
}
```

---

## Testing Services

### Unit Tests
- `test/push_notification_service_test.dart` — FCM initialization, topic subscriptions, payload handling
- `test/achievement_service_test.dart` — Achievement unlock logic, progress tracking, catalog integrity
- `test/analytics_extension_test.dart` — Event logging, funnel sequencing, cohort tracking

### Integration Tests
- `test/integration/push_achievement_funnel_test.dart` — Cross-service achievement → notification → analytics flow
- `test/integration/onboarding_to_aha_moment_test.dart` — Full onboarding funnel with cohort assignment
- `test/integration/monetization_e2e_test.dart` — Purchase → cohort transition lifecycle

### Running Tests
```bash
# All unit tests
flutter test

# Integration tests only
flutter test test/integration/

# Specific service test
flutter test test/achievement_service_test.dart
```

---

## Performance Considerations

### Memory Usage
- **PushNotificationService**: ~2-5 MB (Firebase Messaging library)
- **AchievementService**: ~0.5 MB (11 achievement definitions + progress counters)
- **AnalyticsService**: ~1-2 MB (Firebase Analytics library)

### Network Impact
- **Analytics events**: ~100 bytes per event, batched and sent periodically
- **Topic subscriptions**: One-time registration per app launch
- **FCM payload**: Max 4 KB per notification

### Optimization Tips
1. Batch multiple events into single AnalyticsService.log*() calls when possible
2. Avoid rapid repeated calls to topic subscription/unsubscription
3. Cache achievement details if checking frequently in loops

---

## Migration & Maintenance

### Firestore Integration (Future)
Achievement state and cohort properties should eventually persist to Firestore:
```dart
// Future: User.fcmTokens: Array<string>
// Future: User.unlockedAchievements: Set<string>
// Future: User.achievementProgress: Map<string, int>
// Future: User.cohortProperties: CohortData
```

### Remote Config Integration (Phase 5 Sprint 1)
Achievement unlock thresholds and analytics event parameters can be configured server-side:
```dart
// ABtest: Aha Moment threshold (1 vs 2 kills)
final ahaMomentKillThreshold = RemoteConfig.instance.getInt('aha_moment_threshold');

// ABtest: Ranked unlock level (3 vs 5 vs 10)
final rankedUnlockLevel = RemoteConfig.instance.getInt('ranked_unlock_level');
```

---

## Troubleshooting

### Achievements Not Unlocking
1. Check `AchievementProgressEvent.type` matches expected enum
2. Verify event `data` map contains required fields (e.g., `'is_ranked': true`)
3. Review `_achievementCatalog` for unlock conditions
4. Run `AchievementService().debugDumpAchievements()` to inspect state

### Notifications Not Appearing
1. Verify `PushNotificationService().init()` completed in `main.dart`
2. Check user granted notification permission (iOS: Settings > Notifications)
3. Confirm topic subscription succeeded: `subscribeToTopic('achievementUnlocked')`
4. Inspect Firebase Console → Cloud Messaging for delivery status

### Analytics Events Not Appearing in Firebase Console
1. Verify `AnalyticsService` initialized before logging events
2. Check Firebase project ID and API key in `lib/firebase_options.dart`
3. Allow 24-48 hours for data to appear in Firebase Console (real-time is limited)
4. Review Firebase Security Rules allow write access for authenticated users

---

## References

- [Firebase Cloud Messaging Documentation](https://firebase.google.com/docs/cloud-messaging)
- [Firebase Analytics Documentation](https://firebase.google.com/docs/analytics)
- [Flutter Local Notifications Plugin](https://pub.dev/packages/flutter_local_notifications)
- [Riverpod Docs](https://riverpod.dev)
