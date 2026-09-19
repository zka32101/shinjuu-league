# Feature Flags & A/B Testing Infrastructure (Phase 29)

## Overview

Phase 29 implements a cohort-aware feature flags system layered on Firebase Remote Config, enabling safe experimentation with gradual rollout, canary testing, and A/B test management without code redeployment.

## Architecture

### Core Components

#### 1. FeatureFlagsService
Manages feature gates and cohort-based feature assignment.

**Responsibilities:**
- Feature gate evaluation (is feature enabled for user?)
- Cohort-based variant selection (A/B test assignment)
- Gradual rollout (% of users)
- Emergency kill switches
- Feature metadata management

**Key Methods:**
```dart
// Check if feature is enabled for a user
bool isFeatureEnabled(String userId, String featureName)

// Get A/B test variant for user (consistent hashing)
String getVariant(String userId, String featureName)

// Get difficulty cohort (easy/normal/hard)
String getDifficultyCohort(String userId)

// Feature control
void enableFeature(String featureName)
void disableFeature(String featureName)
void setRolloutPercentage(String featureName, int percentage)

// Debugging
String debugDump(String userId)
```

**Evaluation Order:**
1. Kill switch: if true, feature is disabled
2. Rollout percentage: hash(userId) % 100 < rolloutPercentage
3. Feature enabled flag

#### 2. ABTestCoordinator
Bridges feature flags with analytics to measure experiment outcomes.

**Responsibilities:**
- Experiment registration and lifecycle management
- Consistent variant assignment across sessions
- Active experiment filtering (start/end dates)
- Treatment group detection
- Event logging with experiment context

**Key Methods:**
```dart
// Experiment management
void registerExperiment(ABTestExperimentConfig config)

// Variant assignment
String getExperimentVariant(String userId, String experimentId)
bool isInTreatmentGroup(String userId, String experimentId)
Map<String, String> getUserVariants(String userId)

// Experiment discovery
List<ABTestExperimentConfig> getActiveExperiments(String userId)

// Event logging
void logEventWithExperiment(String userId, String eventName, 
  Map<String, dynamic> parameters, String experimentId)
void logEventWithFeatureFlag(String userId, String eventName,
  Map<String, dynamic> parameters, String featureName)
```

#### 3. SkillProgressionAnalyticsService (Extended)
Added analytics methods for A/B test tracking.

**New Methods:**
```dart
Future<void> logABTestVariantAssignment(
  String userId,
  String experimentId,
  String variantName,
  bool isControl,
)

Future<void> logCustomEvent(
  String userId,
  String eventName,
  Map<String, dynamic> parameters,
)
```

## Feature Flags

### Built-in Features (7 total)

1. **skill_cooldown_reduction**
   - Description: Cooldown reduction mechanics
   - Variants: `baseline`, `reduced_0.8x`, `reduced_0.6x`
   - Rollout: 100%

2. **damage_multiplier**
   - Description: Difficulty-based damage multiplier
   - Variants: `baseline`, `increased_1.1x`, `increased_1.3x`
   - Rollout: 100%

3. **evolution_difficulty**
   - Description: Evolution difficulty modifiers
   - Variants: `easy`, `normal`, `hard`
   - Rollout: 100%

4. **ranked_mode**
   - Description: Ranked competitive mode
   - Variants: `control`, `treatment`
   - Rollout: 95%

5. **new_ui_layout**
   - Description: New dashboard UI layout
   - Variants: `old`, `new`
   - Rollout: 10% (canary)

6. **experimental_matchmaking**
   - Description: Improved matchmaking algorithm
   - Variants: `v1`, `v2`
   - Rollout: 25% (beta)

7. **monetization_enabled**
   - Description: In-app purchases enabled
   - Variants: `control`, `treatment`
   - Rollout: 100%

## A/B Testing Examples

### Example 1: Cooldown Multiplier A/B Test

```dart
// Register experiment
final exp = ABTestExperimentConfig(
  experimentId: 'cooldown_test_2026_q4',
  name: 'Cooldown Reduction Variants',
  description: 'Testing different cooldown reduction speeds',
  startDate: DateTime(2026, 9, 15),
  endDate: DateTime(2026, 10, 15),
  controlVariant: 'baseline',
  rolloutPercentage: 50, // Only 50% of users
  variantDistribution: {
    'baseline': 33,      // 33% get baseline
    'reduced_0.8x': 33,  // 33% get 0.8x
    'reduced_0.6x': 34,  // 34% get 0.6x
  },
);

coordinator.registerExperiment(exp);

// Retrieve variant for user
final variant = coordinator.getExperimentVariant(userId, 'cooldown_test_2026_q4');

// Apply in combat logic
final cooldownMultiplier = switch(variant) {
  'baseline' => 1.0,
  'reduced_0.8x' => 0.8,
  'reduced_0.6x' => 0.6,
  _ => 1.0,
};

// Log with experiment context
coordinator.logEventWithExperiment(
  userId,
  'skill_used_in_battle',
  {'skill': 'fireball', 'damage': 45},
  'cooldown_test_2026_q4',
);
```

### Example 2: Difficulty Cohort Testing

```dart
// Get user's difficulty cohort
final cohort = featureFlags.getDifficultyCohort(userId);

// Create experiment per cohort
for (final cohort in ['easy', 'normal', 'hard']) {
  final exp = ABTestExperimentConfig(
    experimentId: 'matchmaking_quality_$cohort',
    name: 'Matchmaking Quality - $cohort',
    description: 'Testing improved matchmaking for $cohort players',
    startDate: DateTime.now(),
    controlVariant: 'v1_original',
    rolloutPercentage: 100,
    variantDistribution: {
      'v1_original': 50,
      'v2_improved': 50,
    },
  );
  
  coordinator.registerExperiment(exp);
}

// Variant selected based on user's cohort + hash
final matchmakingVersion = coordinator.getExperimentVariant(
  userId,
  'matchmaking_quality_$cohort',
);
```

### Example 3: Feature Rollout with Gradual Ramp

```dart
// Start with canary (10% rollout)
featureFlags.setRolloutPercentage('new_ui_layout', 10);

// Monitor metrics for 1 week

// Expand to beta (25% rollout)
featureFlags.setRolloutPercentage('new_ui_layout', 25);

// Monitor for another week

// Full rollout (100%)
featureFlags.setRolloutPercentage('new_ui_layout', 100);

// Or, emergency kill switch if issues found
featureFlags.disableFeature('new_ui_layout');
```

### Example 4: Feature Gate with Cohort

```dart
// Feature only for certain cohorts
final enabled = featureFlags.isFeatureEnabled(userId, 'ranked_mode');
if (enabled) {
  final cohort = featureFlags.getDifficultyCohort(userId);
  
  // Can then adjust ranked mode parameters per cohort
  final rankingFactorMultiplier = switch(cohort) {
    'easy' => 0.8,
    'normal' => 1.0,
    'hard' => 1.2,
    _ => 1.0,
  };
}
```

## Integration Patterns

### Pattern 1: Battle Engine with Difficulty Multiplier Cohorts

```dart
// In BattleEngineService constructor
BattleEngine({
  required this.participants,
  required SkillProgressionConfig progressionConfig,
  FeatureFlagsService? featureFlags,
}) : 
  _progressionConfig = progressionConfig,
  _featureFlags = featureFlags ?? FeatureFlagsService();

// In combat logic
final difficultyModifiers = _progressionConfig.getDifficultyModifiers();

// Apply to cooldown
cooldown -= (1.0 * difficultyModifiers.skillCooldownMultiplier);

// Log with feature flag context
for (final participant in participants) {
  _featureFlags.isFeatureEnabled(participant.userId, 'skill_cooldown_reduction');
}
```

### Pattern 2: Analytics with Experiment Context

```dart
// When logging battle progression
coordinator.logEventWithExperiment(
  userId,
  'battle_completed',
  {
    'wins': battleResult.winsCount,
    'kills': battleResult.killsCount,
    'duration_seconds': battleDuration.inSeconds,
  },
  'matchmaking_quality_$cohort',
);

// Event automatically includes:
// - experiment_id: 'matchmaking_quality_...'
// - variant: 'v1_original' or 'v2_improved'
// - cohort: 'easy'/'normal'/'hard'
```

### Pattern 3: UI Feature Flags

```dart
// In Lobby Screen
Widget build(BuildContext context, WidgetRef ref) {
  final flags = ref.watch(featureFlagsProvider);
  final userId = ref.watch(currentUserProvider).value?.id;
  
  return Column(
    children: [
      // Always show ranked button
      ElevatedButton(
        onPressed: () => startRankedMatch(),
        child: Text('Ranked Match'),
      ),
      
      // Conditionally show new UI
      if (userId != null && 
          flags.isFeatureEnabled(userId, 'new_ui_layout') &&
          flags.getVariant(userId, 'new_ui_layout') == 'new')
        NewDashboardLayout()
      else
        OldDashboardLayout(),
    ],
  );
}
```

## Analytics Tracking

### Events Generated

1. **ab_test_variant_assigned**
   - Fired: When user first enters an experiment
   - Parameters:
     - `experiment_id`: Unique experiment ID
     - `variant_name`: Assigned variant
     - `is_control`: Whether in control group
     - `difficulty_preset`: User's cohort (easy/normal/hard)
     - `user_id`: User ID

2. **Custom Event with Experiment Context**
   - Any event logged via `logEventWithExperiment`
   - Automatically includes:
     - `experiment_id`
     - `variant`
     - `cohort`

### Measuring Success

#### Example Metrics by Variant

For cooldown reduction experiment:
- **Primary KPI**: Time-to-first-kill (TTK)
- **Secondary KPI**: Engagement rate (battles/day)
- **Safety KPI**: Crash rate (should not increase)

```dart
// Query results by variant
// SELECT 
//   variant, 
//   AVG(time_to_first_kill) as avg_ttk,
//   COUNT(*) as sample_size
// FROM events
// WHERE experiment_id = 'cooldown_test_2026_q4'
// GROUP BY variant
```

## Implementation Checklist

- [x] **Phase 29a**: Core FeatureFlagsService
  - [x] Feature gate evaluation
  - [x] Consistent hashing for variant assignment
  - [x] Kill switch control
  - [x] Rollout percentage management
  - [x] Debug output

- [x] **Phase 29b**: ABTestCoordinator
  - [x] Experiment registration
  - [x] Variant assignment with caching
  - [x] Active experiment filtering
  - [x] Treatment group detection
  - [x] Event logging enrichment
  - [x] Analytics integration

- [x] **Phase 29c**: Analytics Integration
  - [x] A/B test variant assignment logging
  - [x] Custom event with cohort context
  - [x] Cohort parameter injection
  - [x] SkillProgressionAnalyticsService extension

- [x] **Phase 29d**: Comprehensive Testing
  - [x] Feature flags unit tests (30+ test cases)
  - [x] A/B test coordinator unit tests (40+ test cases)
  - [x] Integration scenarios
  - [x] Edge case handling

## Testing

### Running Feature Flags Tests

```bash
flutter test test/feature_flags_test.dart
```

**Coverage (30 test cases):**
- Feature gate evaluation (3)
- Variant assignment (5)
- Difficulty cohorts (3)
- Metadata management (3)
- Kill switches (2)
- Rollout percentages (3)
- Debug output (2)
- Edge cases (4)

### Running A/B Test Coordinator Tests

```bash
flutter test test/ab_test_coordinator_test.dart
```

**Coverage (40+ test cases):**
- Experiment registration (2)
- Variant assignment (5)
- Active filtering (5)
- Treatment group detection (3)
- Variant retrieval (3)
- Event logging (3)
- Cache management (1)
- Rollout percentages (3)
- Debug output (1)
- Edge cases (3)

## Configuration via Remote Config

Future integration with Firebase Remote Config will enable:

```dart
// Fetch from Remote Config
final config = await RemoteConfig.instance.fetch();
final cooldownMultiplier = config.getDouble('cooldown_reduction_multiplier');
final easyRolloutPercentage = config.getInt('easy_cohort_rollout_percentage');
```

## Best Practices

1. **Always use consistent hashing** for variant assignment
   - Ensures same user gets same variant across sessions
   - Enables reproducible A/B tests

2. **Set appropriate rollout percentages**
   - Canary: 5-10% (test with small group)
   - Beta: 25-50% (expand if metrics good)
   - GA: 100% (full rollout)

3. **Monitor key metrics**
   - Engagement, retention, conversion per variant
   - Don't run too many concurrent experiments

4. **Clear caches after changes**
   - When updating feature flags via dashboard
   - Ensures new settings take effect immediately

5. **Always include experiment context in logging**
   - Use `logEventWithExperiment` not just `logEvent`
   - Essential for later analysis and attribution

## Known Limitations

1. **Local Evaluation Only**
   - Feature flags evaluated client-side only
   - Cannot prevent determined users from reverse-engineering
   - For security-critical features, require server-side validation

2. **Stale Config**
   - Changes to feature flags take effect only on next app launch
   - Future: integrate Remote Config polling for real-time updates

3. **No Cohort Persistence**
   - Cohort assignment based on config at evaluation time
   - Mid-session config changes affect subsequent calls
   - Future: persist cohort assignment at session start

## Future Enhancements

- [ ] **Phase 30**: Real-time config polling from Firebase Remote Config
- [ ] **Phase 31**: Admin dashboard for managing experiments
- [ ] **Phase 32**: Automated statistical significance testing
- [ ] **Phase 33**: Tiered rollout automation (canary → beta → GA)
- [ ] **Phase 34**: Multi-cohort experiment design (factorial testing)
- [ ] **Phase 35**: User segmentation (geographic, device type, etc.)

## Related Phases

- **Phase 25-28**: Remote Config Integration (Difficulty Presets)
- **Phase 29**: Feature Flags & A/B Testing (this phase)
- **Phase 30-35**: Future A/B testing enhancements

## Reference

- [FeatureFlagsService](../lib/services/feature_flags_service.dart)
- [ABTestCoordinator](../lib/services/ab_test_coordinator.dart)
- [Feature Flags Tests](../test/feature_flags_test.dart)
- [A/B Test Coordinator Tests](../test/ab_test_coordinator_test.dart)
