# Real-Time Config Polling & Dynamic Updates (Phase 30)

## Overview

Phase 30 implements real-time Firebase Remote Config polling to enable feature flag and difficulty preset changes without app restart.

**Key Capability**: Push config changes live to all players without requiring app updates or restart.

## Architecture

### Core Components

#### ConfigPollingService
Manages periodic Firebase Remote Config polling with automatic service updates.

**Responsibilities:**
- Periodic config fetching with configurable interval (60s-3600s)
- Change detection and notification
- Automatic service updates (SkillProgressionConfig, FeatureFlagsService)
- Network error resilience with exponential backoff
- Session-level cohort persistence (prevent mid-game changes)

**Key Methods:**
```dart
// Lifecycle
void startPolling()                    // Start periodic polling
void stopPolling()                     // Stop polling
Future<bool> pollNow()                 // Manual immediate poll

// Configuration
void setPollInterval(int seconds)      // Set poll interval (clamped 60-3600s)

// Session management
void lockSessionCohort()               // Lock cohort for current session
bool isSessionCohortLocked()           // Check if locked

// State
ConfigPollingStats getStats()          // Get polling statistics
Map<String, dynamic> getSessionConfig() // Config from session start
Map<String, dynamic> getLiveConfig()    // Current live config

// Debugging
String debugDump()                     // Debug information

// Streams
Stream<ConfigUpdateEvent> get onConfigUpdate  // Config change events
Stream<ConfigPollError> get onPollError       // Polling error events
```

#### ConfigPollingService Events

**ConfigUpdateEvent**
```dart
class ConfigUpdateEvent {
  final DateTime timestamp;
  final Map<String, ConfigChange> changes;  // Changed keys and values
  final bool cohortLocked;
}
```

**ConfigChange**
```dart
class ConfigChange {
  final String key;
  final dynamic oldValue;
  final dynamic newValue;
  final DateTime changedAt;
}
```

**ConfigPollError**
```dart
class ConfigPollError {
  final DateTime timestamp;
  final String errorType;              // NETWORK, AUTH, RATE_LIMIT, UNKNOWN
  final String errorMessage;
  final int consecutiveFailures;
}
```

**ConfigPollingStats**
```dart
class ConfigPollingStats {
  final DateTime? lastSuccessfulPoll;
  final DateTime? lastConfigChange;
  final int consecutiveFailures;
  final DateTime sessionStartTime;
  final int pollIntervalSeconds;
  final bool isCohortLocked;
  
  Duration? get timeSinceLastPoll;      // Time since last successful poll
  Duration? get timeSinceLastChange;    // Time since last config change
  Duration get sessionDuration;         // Session uptime
}
```

#### ConfigUpdateNotifier
Riverpod StateNotifier for managing config update state in reactive UI.

**State:**
```dart
class ConfigUpdateState {
  final bool isPolling;
  final bool sessionCohortLocked;
  final int pollIntervalSeconds;
  final ConfigUpdateEvent? lastUpdateEvent;
  final ConfigPollError? lastError;
  
  bool get hasPendingUpdates;           // True if updates available & not locked
  bool get isHealthy;                   // True if no recent errors
  String getStatusMessage();            // Human-readable status
}
```

## Polling Behavior

### Default Schedule
- **Poll Interval**: 300 seconds (5 minutes) default
- **Fetch Timeout**: Follows Firebase Remote Config defaults
- **Cache Duration**: Half of poll interval

### Adaptive Error Handling

On repeated failures, exponential backoff is applied:
```
Failures 1-3: No backoff (60s minimum interval)
Failure 4:    60s × 2 = 120s backoff
Failure 5:    60s × 4 = 240s backoff
Failure 6:    60s × 8 = 480s backoff
Failure 7+:   Max 3600s (1 hour)
```

### Error Recovery
```dart
// On successful poll after N failures
consecutiveFailures = 0;              // Counter reset
pollInterval = resetToDefault();       // Revert to configured interval
```

### Exponential Backoff Formula
```
backoff_seconds = 60 × (1 << (failures - 3))
clamped to [60, 3600]
```

## Session Cohort Locking

### Use Case: Prevent Mid-Game Difficulty Changes

```dart
// At battle start
configPoller.lockSessionCohort();

// During battle: config changes don't affect player's session
// - Difficulty multipliers stay at battle start values
// - Progression speed unchanged
// - Ensures fair and consistent gameplay

// After battle
configPoller.unlockSessionCohort();  // (or just restart session)
```

### Important: Session vs. Live Config

```dart
// Config at session start (immutable during battle)
sessionConfig = pollingService.getSessionConfig();

// Current live config (changes in real-time)
liveConfig = pollingService.getLiveConfig();

// During locked session:
// sessionConfig[levelDifficultyMultiplier] stays 1.0
// liveConfig[levelDifficultyMultiplier] can change to 1.5
// Player still sees 1.0 (from locked session config)
```

## Change Detection

### Detected Changes

The polling service tracks changes in these keys:
- `levelDifficultyMultiplier`
- `skillCooldownMultiplier`
- `skillDamageMultiplier`
- `difficultyPreset`
- Feature flag boolean values
- Feature flag percentages

### On Change

1. **Difficulty Changes**: Applied immediately (unless cohort locked)
2. **Feature Flag Changes**: FeatureFlagsService cache cleared
3. **Listeners Notified**: ConfigUpdateEvent emitted
4. **Analytics Logged**: Change tracked for auditing

## Integration Examples

### Example 1: Enable Polling at App Startup

```dart
// In main.dart or app initialization
final pollingService = ConfigPollingService(
  remoteConfig: FirebaseRemoteConfig.instance,
  progressionConfig: SkillProgressionConfig.instance,
  featureFlags: FeatureFlagsService(),
  pollIntervalSeconds: 300, // 5 minutes
);

// Start polling
pollingService.startPolling();

// Listen to updates
pollingService.onConfigUpdate.listen((event) {
  print('Config updated: ${event.changes.length} changes');
  // Update UI, log analytics, etc.
});

// Listen to errors
pollingService.onPollError.listen((error) {
  print('Poll error: ${error.errorType}');
  // Show warning to user if critical
});
```

### Example 2: Lock Cohort During Battle

```dart
class BattleController {
  final ConfigPollingService configPoller;

  void startBattle() {
    // Lock cohort to session values at battle start
    configPoller.lockSessionCohort();
    
    print('Battle difficulty: ${configPoller.getSessionConfig()}');
    
    // Battle runs with stable config
    runBattle();
  }

  void endBattle() {
    // Cohort remains locked until session end or manual unlock
    // (New session = new cohort lock point)
  }
}
```

### Example 3: Rapid Iteration During Testing

```dart
// During development, use aggressive polling
pollingService.setPollInterval(10); // Poll every 10 seconds

// Make changes in Firebase Console
// See changes reflected in app immediately (with 10s latency)

// Before production, revert
pollingService.setPollInterval(300); // Back to 5 minutes
```

### Example 4: Manual Poll for Updates

```dart
// When user enters lobby
Future<void> onEnterLobby() async {
  // Get fresh config immediately
  final success = await configPoller.pollNow();
  
  if (success) {
    print('Config updated');
  } else {
    print('Failed to refresh config');
  }
}
```

### Example 5: Monitor Polling Health

```dart
// In UI, show sync status
Consumer(
  builder: (context, ref, child) {
    final configState = ref.watch(configUpdateProvider);
    
    return Text(
      configState.getStatusMessage(),
      style: TextStyle(
        color: configState.isHealthy ? Colors.green : Colors.orange,
      ),
    );
  },
)
```

### Example 6: Respond to Specific Changes

```dart
pollingService.onConfigUpdate.listen((event) {
  for (final change in event.changes.values) {
    if (change.key == 'skillCooldownMultiplier') {
      print('Cooldown changed: ${change.oldValue} → ${change.newValue}');
      
      // Notify UI
      ref.refresh(skillCooldownProvider);
    }
    
    if (change.key == 'rankedModeEnabled') {
      print('Ranked mode toggled');
      
      // Update navigation options
      ref.refresh(navProvider);
    }
  }
});
```

## Use Cases

### 1. Emergency Kill Switch

Config changes in Firebase Console:
```
Before: skilledCooldownReductionEnabled = true
After:  skilledCooldownReductionEnabled = false (emergency disable)

Polling Service:
1. Detects change on next poll
2. Clears FeatureFlagsService cache
3. Notifies listeners
4. Users see feature disabled within poll interval (5min max)
```

### 2. Gradual Feature Rollout

```
Day 1: experimental_matchmaking_enabled = 10% rollout
→ 10% of new users see new matchmaking

Day 3: experimental_matchmaking_enabled = 25% rollout
→ 25% of new users see new matchmaking
→ Config polled every 5min, changes live within 5min

Day 7: experimental_matchmaking_enabled = 100% rollout
→ All users see new matchmaking
```

### 3. A/B Test Variant Adjustment

```
Experiment running: cooldown_reduction_variants
Old distribution: baseline 34%, reduced_0.8x 33%, reduced_0.6x 33%

Issue detected: reduced_0.6x shows concerning metrics
→ Update in Firebase Console:
   cooldown_variants_distribution = {baseline: 50, reduced_0.8x: 50, reduced_0.6x: 0}

Next polls: existing users in reduced_0.6x stay there (locked)
New users: no longer assigned to reduced_0.6x variant
```

### 4. Difficulty Adjustment During Event

```
Event announcement: "Shadow Labyrinth Mega Challenge"
→ Temporarily increase difficulty:
   levelDifficultyMultiplier = 2.0 (2x)
   skillCooldownMultiplier = 1.5 (50% longer cooldowns)

Battle starts: Player's session is locked to session config
→ If mid-battle, uses session start difficulty
→ After battle, new session uses updated multipliers

Event ends: Revert multipliers
→ New sessions use original values
```

## Testing

### Unit Tests (35+ cases)

**Polling Lifecycle**
- Start/stop polling
- Manual poll triggering
- Automatic restart after stop

**Interval Management**
- Set interval with clamping
- Restart timer on interval change

**Cohort Locking**
- Lock/unlock state
- Prevent mid-game changes
- Lock persistence

**Change Detection**
- Detect value changes
- Listener notifications
- Stream functionality

**Error Handling**
- Network errors
- Consecutive failure counting
- Exponential backoff
- Error categorization

**Statistics**
- Poll timing tracking
- Failure counting
- Duration calculations

### Running Tests

```bash
flutter test test/config_polling_service_test.dart
```

## Best Practices

1. **Start polling early**: Begin at app startup, before first gameplay
2. **Use appropriate interval**: 5min (default) balances freshness vs. API quota
3. **Lock cohort during sensitive operations**: Especially during battles
4. **Monitor polling health**: Show status indicator to user
5. **Handle errors gracefully**: Don't break gameplay on poll failures
6. **Test exhaustively**: Simulate network failures, config changes, timing edge cases

## Configuration

### Via SkillProgressionConfig

Changes defined in Remote Config are automatically detected:
```dart
// Firebase Console Remote Config
{
  "levelDifficultyMultiplier": 1.3,
  "skillCooldownMultiplier": 1.2,
  "skillDamageMultiplier": 1.1,
  "difficultyPreset": "hard"
}

// Polling Service detects these changes next poll
// SkillProgressionConfig.getDifficultyModifiers() returns new values
```

### Polling Interval

```dart
// Set in code (will auto-adjust on repeated errors)
pollingService.setPollInterval(300);  // 5 minutes

// Firebase Console Remote Config (future enhancement)
{
  "config_polling_interval_seconds": 120
}
```

## Known Limitations

1. **Client-side Detection Only**
   - Changes detected when app polls, not pushed from server
   - Max latency = poll interval (5min default)
   - Future: WebSocket for true real-time push

2. **Cohort Lock is Session-Only**
   - Resets on app restart
   - Cannot persist across device restarts
   - Future: Store in local preferences if needed

3. **Batch Updates Only**
   - Multiple changes in one poll detected together
   - No per-change granularity
   - Future: Timestamp each change for ordering

4. **No Rollback**
   - Config changes are one-way (no automatic rollback)
   - Must manually revert in Firebase Console
   - Future: Scheduled automatic rollback

## Future Enhancements (Phase 31+)

- [ ] **Phase 31**: WebSocket push for true real-time updates (no polling delay)
- [ ] **Phase 32**: Admin dashboard to manage config without Firebase Console
- [ ] **Phase 33**: Automated config versioning and rollback
- [ ] **Phase 34**: Scheduled config changes (activate at specific time)
- [ ] **Phase 35**: A/B test config orchestration (automatic variant switching)

## Integration Points

**With Feature Flags (Phase 29):**
- Changes to feature flag values automatically clear cache
- Variant distribution changes take effect on next poll

**With Remote Config (Phases 25-28):**
- Difficulty multipliers polled from Firebase Remote Config
- Changes applied automatically to BattleEngine

**With Battle System (Phase 6):**
- Battle cohort locked at start for consistency
- Post-battle: new config values for next battle

**With Analytics (Phase 6 Sprint 2):**
- Config changes logged for audit trail
- Each change attributed with timestamp

## Reference

- [ConfigPollingService](../lib/services/config_polling_service.dart)
- [ConfigUpdateNotifier](../lib/services/config_update_notifier.dart)
- [Config Polling Tests](../test/config_polling_service_test.dart)
- [Firebase Remote Config Docs](https://firebase.google.com/docs/remote-config)
