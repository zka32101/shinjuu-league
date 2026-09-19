# Phase 10 Step 11: Achievement Unlock Detection & Reward Distribution

**Date**: 2026-09-11  
**Status**: Implementation Complete  
**Test Coverage**: 19 tests (9 detector + 10 reward)

## Overview

Achievement Unlock Detection & Reward Distribution system automatically detects when players accomplish objectives during gameplay and grants rewards. The system listens to BattleEngine events and triggers achievement unlocks, then distributes currency, badges, and cosmetics through a unified reward pipeline.

## Architecture

### Service Layer

**`AchievementDetectorService`** (180 lines)
- Monitors BattleEngine streams (combatEvents, damageEvents, hitEvents, onTick)
- Detects achievement-triggering conditions
- Emits `AchievementUnlockEvent` when achievements unlock
- Tracks unlocked achievements per session to prevent duplicate emissions
- Non-blocking event subscription pattern

```dart
final service = AchievementDetectorService(battleEngine: battleEngine);

// Start detecting for a user
service.startDetecting(userId);

// Listen for unlocks
service.unlockEvents.listen((event) {
  print('${event.achievement.name} unlocked!');
  // Process unlock (distribute rewards, show toast, etc)
});

// Stop detecting when battle ends
service.stopDetecting();
```

**`AchievementRewardService`** (220 lines)
- Processes achievement unlocks and calculates rewards
- Distributes currency, badges, and cosmetics
- Persists rewards to Firestore
- Tracks reward history per user

```dart
final rewardService = AchievementRewardService(
  firestoreService: firestoreService,
);

// Process unlock and grant rewards
final rewards = await rewardService.processUnlock(userId, achievement);
// Returns: {
//   'currency': 50,
//   'badges': 1,
//   'cosmetics': [],
//   'tier': 'bronze'
// }

// Get user's current rewards
final pending = await rewardService.getPendingRewards(userId);
```

### Reward Structure

Rewards vary by achievement tier:

| Tier | Currency | Badges | Cosmetics | Rarity |
|------|----------|--------|-----------|--------|
| Bronze | 50 | 1 | None | Common |
| Silver | 100 | 1 | 1 badge | Uncommon |
| Gold | 250 | 2 | 1 badge + 1 frame | Rare |
| Platinum | 500 | 3 | Badge + Frame + Border | Legendary |

### Achievement Detection Events

**Combat Events** (Kills)
- `first_blood`: First kill in battle
- `triple_kill`: 3 kills in one battle
- `war_kill`: Participate in any kill

**Damage Events**
- `high_damage`: Deal X damage in a battle
- `critical_strike`: Land a critical hit

**Time-Based Events**
- `speedrunner_tick`: Complete battle in X ticks
- `survival`: Survive X ticks in battle

### Integration Points

#### 1. BattleViewModel Integration

```dart
class BattleViewModelState {
  final AchievementDetectorService achievementDetector;
  
  void _initializeBattle() {
    achievementDetector.startDetecting(userId);
    
    // Listen for achievement unlocks
    achievementDetectorSubscription = achievementDetector
        .unlockEvents
        .listen((event) async {
          // Show toast notification
          toastService.showAchievementToast(event.achievement);
          
          // Distribute rewards
          await rewardService.processUnlock(userId, event.achievement);
          
          // Track analytics
          analytics.logAchievementUnlock(event.achievement.achievementId);
        });
  }
  
  void _cleanupBattle() {
    achievementDetector.stopDetecting();
    achievementDetectorSubscription?.cancel();
  }
}
```

#### 2. BattleEngine Event Streams

The detector listens to these streams:

- `combatEvents`: Fired when a kill occurs
  - Contains: killerId, victimId, timestamp, damageDealt
  - Used for: first_blood, war_kill, kill_streak

- `damageEvents`: Fired on every hit (progress-based)
  - Contains: damagerId, targetId, damageAmount, isCritical
  - Used for: high_damage, critical_strike, damage_dealt_total

- `onTick`: Fired every game tick (60 ticks per minute)
  - Contains: tick number
  - Used for: speedrunner_tick, survival, engagement_duration

#### 3. Firestore Schema

Achievement unlocks stored at:
- `/users/{userId}/achievements/{achievementId}`
- Fields: achievementId, unlockedAt, isHidden

Rewards persisted to user document:
- `User.currency` incremented
- `User.achievementBadges` incremented
- `User.ownedCosmetics` array union (cosmetic IDs added)

### Configuration

Default behavior (no configuration needed):

```dart
AchievementDetectorService(
  battleEngine: battleEngine,
)

// Automatically:
// - Listens to all BattleEngine streams
// - Tracks session state
// - Prevents duplicate unlocks per session
// - Cleans up on dispose()
```

## Testing

### Service Tests (9 tests)
- ✅ Emits unlock event on combat event
- ✅ Tracks detected achievements in session
- ✅ Stops detecting on stopDetecting call
- ✅ Only counts each achievement once per session
- ✅ Resets session state on startDetecting
- ✅ Debug stats returns valid data structure
- ✅ Achievement unlock event has correct fields
- ✅ Disposes streams properly
- ✅ Different users can have separate detection

### Reward Tests (10 tests)
- ✅ Processes unlock and calculates rewards for bronze tier
- ✅ Processes unlock and calculates rewards for silver tier
- ✅ Processes unlock and calculates rewards for gold tier
- ✅ Processes unlock and calculates rewards for platinum tier
- ✅ Applies currency reward correctly
- ✅ Applies badge reward correctly
- ✅ Applies cosmetic rewards correctly
- ✅ Marks achievement as unlocked in Firestore
- ✅ Accumulates rewards for multiple achievements
- ✅ Debug reward info returns correct structure

## Performance Considerations

- **Event Subscription**: Non-blocking stream listeners, no polling
- **Session Tracking**: In-memory Set<String> prevents duplicate emissions
- **Firestore Writes**: Batch reward operations where possible
- **Memory**: Session state cleared on stopDetecting() or dispose()
- **CPU**: Event listeners only active during battles

## Future Enhancements

### Phase 10 Step 12 (Suggested)
- [ ] Server-side achievement validation (Cloud Functions)
- [ ] Progression-based achievement tracking (e.g., "5/10 kills for achievement")
- [ ] Achievement cascading (unlock achievement → unlock related achievement)
- [ ] Reward multipliers (2x rewards during special events)
- [ ] Legacy/retired achievements (seasonal exclusivity)
- [ ] Achievement streaks (consecutive unlock bonuses)
- [ ] Social achievements (invite friends, guild activities)

### Performance Optimization
- Batch reward distributions during raid events
- Archive old achievement records to secondary storage
- Implement achievement unlock caching layer

### Analytics Integration
- Track unlock rates by achievement tier
- Identify underperforming achievements (too hard/easy)
- Cohort analysis: Players who unlock first_blood → higher retention

### Remote Config Integration
- Achievement unlock thresholds (configurable per season)
- Reward multipliers per tier (ABtest different economy models)
- Achievement availability (enable/disable seasonal achievements)

## Debugging

```dart
final detector = ref.read(achievementDetectorServiceProvider);

// Check detected achievements this session
print(detector.debugGetStats());
// Output: {
//   detected_count: 2,
//   achievements: ['first_blood', 'war_kill']
// }

final rewardService = ref.read(achievementRewardServiceProvider);

// Check reward amounts for any achievement
final rewards = rewardService.debugGetRewardInfo(achievement);
print(rewards);
// Output: {
//   currency: 50,
//   badges: 1,
//   cosmetics: [],
//   tier: 'bronze'
// }
```

## Files Modified/Created

### New Files
- `lib/services/achievement_detector_service.dart` (180 lines)
- `lib/services/achievement_reward_service.dart` (220 lines)
- `test/services/achievement_detector_service_test.dart` (350 lines)
- `test/services/achievement_reward_service_test.dart` (320 lines)
- `docs/PHASE10_STEP11_ACHIEVEMENT_DETECTION.md` (this file)

### Modified Files
- `lib/data/models/achievement.dart`
  - Added: `firstBlood` achievement to catalog
  - Added: `firstBlood` to `all` list
- `lib/services/firestore_service.dart`
  - Added: `markAchievementUnlocked()`
  - Added: `incrementUserCurrency()`
  - Added: `incrementUserAchievementBadges()`
  - Added: `addUserCosmetic()`
  - Added: `getUserAchievements()`
- `lib/data/providers/service_providers.dart`
  - Added: imports for new services
  - Added: `battleEngineServiceProvider`
  - Added: `achievementDetectorServiceProvider`
  - Added: `achievementRewardServiceProvider`

## Testing Commands

```bash
# Run detector service tests
flutter test test/services/achievement_detector_service_test.dart

# Run reward service tests
flutter test test/services/achievement_reward_service_test.dart

# Run all achievement tests
flutter test test/services/achievement_*_test.dart

# Run all tests
flutter test

# Coverage report
flutter test --coverage
```

## See Also

- **Phase 10 Step 9**: `AchievementToastNotificationService` (notification display)
- **Phase 10 Step 10**: `AchievementsScreen` (gallery/collection UI)
- **Phase 6 Step 1**: `BattleEngine` (event source)
- **Phase 5 Sprint 1**: `SeasonService` (seasonal tracking)
- **Phase 4**: `AnalyticsService` (event tracking)

## Integration Checklist

- [ ] Add AchievementDetectorService to BattleViewModelState initialization
- [ ] Subscribe to unlockEvents stream in battle lifecycle
- [ ] Call rewardService.processUnlock() on achievement unlock
- [ ] Show AchievementToastWidget for unlock notifications
- [ ] Track analytics event `achievement_unlocked`
- [ ] Test end-to-end battle → achievement unlock → reward flow
- [ ] Verify Firestore documents persist correctly
- [ ] Monitor performance on low-end devices during intensive battles
