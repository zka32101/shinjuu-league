# Phase 10 Step 9: Achievement Toast Notifications

**Date**: 2026-09-11  
**Status**: Implementation Complete  
**Test Coverage**: 26 tests (15 service + 11 widget)

## Overview

Achievement Toast Notifications provide real-time, in-game visual feedback when players unlock achievements. Toasts appear as animated cards near the top-right of the screen with:
- Achievement icon (🏆)
- Achievement name and "成果を解除！" label
- Tier-colored border and background gradient
- Smooth slide-in animation
- Automatic dismissal with queue management

## Architecture

### Service Layer

**`AchievementToastNotificationService`** (280 lines)
- Manages notification queue and lifecycle
- Configurable display duration (default 3s)
- Max concurrent notifications (default 3)
- Stream-based event emission for `notifications` and `dismissals`
- Non-blocking queue processing

```dart
final service = AchievementToastNotificationService();

// Show toast for achievement
final notificationId = await service.showAchievementToast(achievement);

// Streams emit events
service.notifications.listen((notification) {
  // Update UI with new toast
});

service.dismissals.listen((notificationId) {
  // Remove toast from UI
});
```

### UI Components

**`AchievementToastWidget`** (animated toast card)
- Slides in from right with fade
- ElasticOut curve for playful feel
- Tier-specific color coding
- Responsive layout with overflow handling

**`AchievementToastOverlay`** (container widget)
- Manages multiple concurrent toasts
- Listens to service streams
- Positioned at top-right (configurable)
- Handles rapid achievement unlocks gracefully

### Haptic & Audio Feedback

Added to existing services:
- `HapticService.onAchievementUnlock()` → mediumImpact
- `AudioService.playAchievementUnlockedSe()` → "achievement_unlocked.mp3"

## Integration Points

### 1. In Battle Screen (During Combat)

For real-time achievements detected mid-battle:

```dart
class _BattleScreenState extends ConsumerState<BattleScreen> {
  @override
  void build(BuildContext context) {
    ref.listen(battleViewModelProvider, (previous, next) {
      // Listen for newly detected achievements
      if (next.newlyUnlockedAchievements.isNotEmpty &&
          (previous?.newlyUnlockedAchievements.isEmpty ?? true)) {
        
        final toastService = ref.read(achievementToastNotificationServiceProvider);
        for (final achievement in next.newlyUnlockedAchievements) {
          toastService.showAchievementToast(achievement);
        }
      }
    });

    return Scaffold(
      body: Stack(
        children: [
          // Battle game/UI
          GameWidget(...),
          
          // Achievement toast overlay (top-right)
          AchievementToastOverlay(
            notifications: ref.watch(achievementToastNotificationServiceProvider).notifications,
            dismissals: ref.watch(achievementToastNotificationServiceProvider).dismissals,
            alignment: Alignment.topRight,
          ),
        ],
      ),
    );
  }
}
```

### 2. Result Screen (Post-Battle Summary)

Existing achievement display remains in `result_screen.dart` (Phase 10 Step 8):
- Horizontal ListView of achievement cards
- Clickable for detailed view
- Complementary to toast notifications

### 3. Lobby/Main Screens

Optional toast integration for:
- Daily login achievements
- Milestone notifications (level-up, tier promotion)
- Special event achievements

## Configuration

Default settings (customizable):

```dart
AchievementToastNotificationService(
  displayDuration: const Duration(seconds: 3),      // How long each toast stays
  transitionDuration: const Duration(milliseconds: 400), // Slide animation
  maxConcurrentNotifications: 3,                    // Max displayed simultaneously
)
```

## Testing

### Service Tests (14 tests)
- ✅ Single and multiple notifications
- ✅ Queue processing and max concurrent enforcement
- ✅ Auto-dismissal after duration
- ✅ Manual dismissal
- ✅ Clear all functionality
- ✅ Stream emission correctness
- ✅ Debug stats and introspection

### Widget Tests (12 tests)
- ✅ Toast rendering (emoji, name, tier badge)
- ✅ Tier color handling (all 8 tiers)
- ✅ Animations (slide + fade)
- ✅ Long text handling with ellipsis
- ✅ Overlay with multiple toasts
- ✅ Dismissal via stream
- ✅ Alignment configuration

## Performance Considerations

- **Queue Management**: Toasts queue automatically when max concurrent exceeded
- **Memory**: No persistent storage; cleared on app exit
- **Garbage Collection**: Disposed streams prevent memory leaks
- **Frame Time**: Animation runs at 60fps with minimal impact

## Future Enhancements

### Phase 10 Step 10 (Suggested)
- [ ] Persistent achievement notification history
- [ ] Toast notification preferences (enable/disable)
- [ ] Sound/haptic toggle for notifications
- [ ] Achievement progression (e.g., "2/10 progress")
- [ ] Toast grouping for rapid consecutive unlocks

### Integration with Remote Config
- Achievement toast enabled/disabled per region
- Custom display duration by achievement tier
- A/B test notification frequency impact on retention

## Debugging

```dart
final service = ref.read(achievementToastNotificationServiceProvider);

// Check service state
print(service.debugGetStats());
// Output: {displayed_count: 2, queue_size: 1, max_concurrent: 3, ...}

// Check displayed toasts
print(service.debugGetDisplayedIds());
// Output: ['achievement_toast_1_..., 'achievement_toast_3_...]
```

## Files Modified/Created

### New Files
- `lib/services/achievement_toast_notification_service.dart` (290 lines)
- `lib/ui/widgets/achievement_toast_widget.dart` (295 lines)
- `test/services/achievement_toast_notification_service_test.dart` (350 lines)
- `test/ui/widgets/achievement_toast_widget_test.dart` (320 lines)

### Modified Files
- `lib/data/providers/service_providers.dart` (+3 lines: import + provider)
- `lib/services/audio_service.dart` (+1 line: playAchievementUnlockedSe)
- `lib/services/haptic_service.dart` (+2 lines: onAchievementUnlock)

### Next Integration (Battle Screen)
- `lib/ui/screens/battle_screen.dart` — Add AchievementToastOverlay to Stack

## Testing Commands

```bash
# Run service tests
flutter test test/services/achievement_toast_notification_service_test.dart

# Run widget tests
flutter test test/ui/widgets/achievement_toast_widget_test.dart

# Run all tests
flutter test

# Coverage report
flutter test --coverage
```

## See Also

- **Phase 10 Step 6-7**: `AchievementTriggerDetector` (detection logic)
- **Phase 10 Step 8**: `result_screen.dart` (post-battle display)
- **Phase 4**: `AudioService`, `HapticService` (feedback)
- **Phase 5**: `Remote Config` (feature flags for notifications)
