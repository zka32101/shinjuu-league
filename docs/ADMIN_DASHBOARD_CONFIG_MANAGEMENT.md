# Admin Dashboard for Config Management (Phase 31)

## Overview

Phase 31 implements an in-app admin panel for real-time configuration management, experiment control, and feature flag tuning without requiring Firebase Console access or app restarts.

**Key Capability**: Adjust difficulty, manage experiments, control feature rollout, and view audit logs all from within the game.

## Architecture

### Core Component: ConfigAdminService

Provides complete admin functionality for configuration management.

**Responsibilities:**
- Real-time config value editing
- Feature flag control (enable/disable/rollout %)
- Experiment creation and management
- Automatic audit logging
- Config snapshots and rollback
- Statistics and monitoring

**Key Methods:**

```dart
// Difficulty management
ProgressionDifficultyModifiers getDifficultyModifiers()
Future<void> applyDifficultyPreset(String preset)  // easy/normal/hard
Future<void> setDifficultyMultiplier(String type, double value)

// Feature flag control
Future<void> setFeatureEnabled(String featureName, bool enabled)
Future<void> setFeatureRollout(String featureName, int percentage)
List<FeatureFlagStatus> getAllFeatureStatus()

// Experiment management
Future<void> createExperiment(ABTestExperimentConfig config)
Future<void> updateExperimentRollout(String experimentId, int percentage)

// History and snapshots
List<ConfigChangeRecord> getChangeHistory({int limit = 50})
Future<void> rollbackToSnapshot(String name)

// Monitoring
AdminStatsSummary getStats()
String debugDump()
```

### Data Models

**FeatureFlagStatus**
```dart
class FeatureFlagStatus {
  final String name;
  final bool enabled;
  final bool killSwitch;
  final int rolloutPercentage;
  final List<String> variants;
  final String description;
}
```

**ConfigChangeRecord** (Audit Log)
```dart
class ConfigChangeRecord {
  final DateTime timestamp;
  final String type;           // DIFFICULTY_PRESET, FEATURE_TOGGLE, etc.
  final String key;            // Config key that changed
  final dynamic oldValue;
  final dynamic newValue;
  final Map<String, dynamic> details;
}
```

**AdminStatsSummary**
```dart
class AdminStatsSummary {
  final int totalFeatures;
  final int enabledFeatures;
  final int averageRollout;
  final int changeHistorySize;
  final int snapshotCount;
  
  int get disabledFeatures;
  double get enabledPercentage;
}
```

## Usage Examples

### Example 1: Quick Difficulty Adjustment

```dart
// Apply preset
await adminService.applyDifficultyPreset('easy');

// Or adjust specific multiplier
await adminService.setDifficultyMultiplier('cooldown', 0.8);
await adminService.setDifficultyMultiplier('damage', 0.9);

// Changes recorded automatically in history
final history = adminService.getChangeHistory();
print(history.last);  // ConfigChangeRecord with timestamp
```

### Example 2: Emergency Feature Disable

```dart
// Quick kill switch if bug discovered
await adminService.setFeatureEnabled('experimental_matchmaking', false);

// Feature disabled for all users on next poll
// Change recorded in audit log with timestamp and admin who made change
final stats = adminService.getStats();
print('${stats.enabledFeatures}/${stats.totalFeatures} features enabled');
```

### Example 3: Gradual Rollout Control

```dart
// Day 1: Canary release (10%)
await adminService.setFeatureRollout('new_ui_layout', 10);

// Day 3: Expand (25%)
await adminService.setFeatureRollout('new_ui_layout', 25);

// Day 7: Full rollout (100%)
await adminService.setFeatureRollout('new_ui_layout', 100);

// Audit trail shows exactly when each change was made
```

### Example 4: Create and Monitor A/B Test

```dart
// Create experiment
final exp = ABTestExperimentConfig(
  experimentId: 'cooldown_variants_q4',
  name: 'Cooldown Reduction Optimization',
  description: 'Testing different cooldown reduction speeds',
  startDate: DateTime.now(),
  endDate: DateTime.now().add(Duration(days: 14)),
  controlVariant: 'baseline',
  rolloutPercentage: 50,
  variantDistribution: {
    'baseline': 34,
    'reduced_0.8x': 33,
    'reduced_0.6x': 33,
  },
);

await adminService.createExperiment(exp);

// Later: adjust rollout if metrics look good
await adminService.updateExperimentRollout('cooldown_variants_q4', 100);
```

### Example 5: View Feature Status Dashboard

```dart
// Get all features with current state
final statuses = adminService.getAllFeatureStatus();

for (final status in statuses) {
  print('''
    Feature: ${status.name}
    Enabled: ${status.enabled}
    Rollout: ${status.rolloutPercentage}%
    Variants: ${status.variants.join(", ")}
  ''');
}

// Statistics
final stats = adminService.getStats();
print('Total Features: ${stats.totalFeatures}');
print('Enabled: ${stats.enabledFeatures} (${stats.enabledPercentage.toStringAsFixed(1)}%)');
print('Avg Rollout: ${stats.averageRollout}%');
```

### Example 6: Audit Log Review

```dart
// Get change history (last 20 changes)
final history = adminService.getChangeHistory(limit: 20);

for (final record in history) {
  print('''
    ${record.timestamp}: ${record.type}
    ${record.key}: ${record.oldValue} → ${record.newValue}
    Details: ${record.details}
  ''');
}
```

### Example 7: Snapshot and Rollback

```dart
// Save snapshot before major changes
adminService._saveSnapshot('before_event');

// Make changes
await adminService.applyDifficultyPreset('hard');
await adminService.setFeatureRollout('ranked_mode', 100);

// Event ends, rollback to before
await adminService.rollbackToSnapshot('before_event');

// Change recorded in audit log
```

## Admin UI Implementation (Future)

Phase 31 provides the backend service. Future phases would implement UI:

### Planned UI Screens

1. **Dashboard**
   - Feature status overview (enabled/disabled/rollout %)
   - Recent changes (last 10)
   - System health (polling status, error count)
   - Quick action buttons (presets, kill switches)

2. **Difficulty Tuning**
   - Sliders for each multiplier (level/cooldown/damage)
   - Preset buttons (easy/normal/hard)
   - Live preview (show resulting values)
   - Rollback to previous values

3. **Feature Flags**
   - List of all features
   - Toggle enable/disable
   - Rollout percentage slider
   - Variant distribution view
   - Rollout timeline (canary → beta → GA)

4. **Experiments**
   - Active experiments list
   - Experiment details (start/end date, variants, rollout)
   - Create new experiment
   - Pause/resume experiment
   - Variant distribution control

5. **Audit Log**
   - Change history (filtered by type)
   - Search by feature/experiment name
   - Timestamp precision (exact minute)
   - Reversal options per change
   - Export to CSV

6. **Config Snapshots**
   - List saved snapshots
   - Create named snapshot
   - Rollback to any snapshot
   - Compare snapshots (before/after)

## Security Considerations

### Access Control (To Be Implemented)

```dart
// Future: Role-based access control
enum AdminRole {
  viewer,          // Read-only access
  operator,        // Can adjust rollout % and kill switches
  experimenter,    // Can create/modify experiments
  admin,           // Full access
}

// Access checks before operations
if (!hasAdminPermission(userId, AdminRole.operator)) {
  throw UnauthorizedException('Insufficient permissions');
}
```

### Audit Trail

All changes automatically logged:
- **Timestamp**: Exact moment of change
- **Change Type**: DIFFICULTY_PRESET, FEATURE_TOGGLE, ROLLOUT_CHANGE, EXPERIMENT_CREATED, ROLLBACK
- **Config Key**: What was changed
- **Old/New Values**: Before and after
- **Details**: Additional context (which feature, experiment ID, etc.)

### Future: User Attribution

```dart
// Future: Track who made each change
class ConfigChangeRecord {
  // ... existing fields ...
  final String? adminUserId;        // Future: who made this change
  final String? adminDisplayName;   // Future: admin's name
}
```

## Testing

### Unit Tests (45+ cases)

**Difficulty Management (10 tests)**
- Get current modifiers
- Apply presets (easy/normal/hard)
- Set individual multipliers
- Value clamping (0.1-3.0)
- Case-insensitive preset names

**Feature Flag Control (8 tests)**
- Enable/disable features
- Set rollout percentages
- Toggle history recording
- Multiple feature changes

**Feature Status (3 tests)**
- Retrieve all status
- Status field validation
- Reflect enabled state

**Experiment Management (4 tests)**
- Create experiment
- Record in history
- Update rollout
- Variant distribution

**Change History (5 tests)**
- Record changes
- Limited history
- Timestamp tracking
- Change details
- History size bounds

**Snapshots & Rollback (4 tests)**
- Initial snapshot creation
- Rollback recording
- Nonexistent snapshot handling
- Timestamp preservation

**Statistics (3 tests)**
- Stats summary
- Reflect current state
- Calculate percentages

**Edge Cases (5 tests)**
- Empty feature list
- Rapid changes
- Value clamping
- Negative multipliers
- Rollback during operations

### Running Tests

```bash
flutter test test/config_admin_service_test.dart
```

## Integration Points

### With ConfigPollingService (Phase 30)
- Config changes polled and applied to all services
- Admin changes eventually propagate to live game
- Changes visible in polling event stream

### With FeatureFlagsService (Phase 29)
- Feature enable/disable calls methods directly
- Rollout percentage changes clear cache
- Status reflects current feature state

### With ABTestCoordinator (Phase 29)
- New experiments registered via coordinator
- Variant distribution changes tracked
- Experiment rollout adjustments logged

### With BattleEngine (Phase 6)
- Difficulty changes affect new battles (not locked sessions)
- Multiplier changes visible next battle session

## Best Practices

1. **Always create snapshots before major changes**
   - Canary releases, difficulty adjustments, experiment launches
   - Enables quick rollback if issues emerge

2. **Use audit log for accountability**
   - Review who changed what and when
   - Correlate changes with metrics (crashes, retention drop)

3. **Test changes with small rollout first**
   - 10% canary for 1-2 days
   - 25% beta for another 2-3 days
   - 100% GA only after validation

4. **Lock session cohort during events**
   - Prevent mid-game difficulty changes affecting fairness
   - Ensures consistent user experience

5. **Monitor health metrics after changes**
   - Crash rate, error rate, engagement
   - Kill switch immediately if regression detected

## Known Limitations

1. **In-App Only**
   - Admin panel requires app launch
   - Cannot make changes for users currently in-game
   - Changes take effect on next session/battle

2. **No Real-Time Propagation**
   - Changes propagated via polling (max 5min latency)
   - Future: WebSocket push for instant updates

3. **No Permission System (Phase 31)**
   - All admins have full access
   - Future: Role-based access control

4. **No User Attribution (Phase 31)**
   - Audit log doesn't track who made changes
   - Future: User ID and timestamp for accountability

## Future Enhancements (Phase 32+)

- [ ] **Phase 32**: Web-based admin dashboard (separate from game)
- [ ] **Phase 33**: Role-based access control (viewer/operator/admin)
- [ ] **Phase 34**: User attribution on all changes
- [ ] **Phase 35**: Automated config versioning and rollback
- [ ] **Phase 36**: Scheduled config changes (activate at specific time)
- [ ] **Phase 37**: Integration with analytics for automated response (e.g., auto-disable on crash spike)

## Reference

- [ConfigAdminService](../lib/services/config_admin_service.dart)
- [Admin Service Tests](../test/config_admin_service_test.dart)
- [Feature Flags (Phase 29)](./FEATURE_FLAGS_AND_AB_TESTING.md)
- [Config Polling (Phase 30)](./CONFIG_POLLING_REAL_TIME_UPDATES.md)
