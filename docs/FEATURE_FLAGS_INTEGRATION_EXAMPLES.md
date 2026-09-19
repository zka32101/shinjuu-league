# Feature Flags Integration Examples

Practical examples showing how to integrate feature flags and A/B testing into the Shinjuu League game flow.

## 1. Skill Progression with Cooldown Multiplier Experiment

### Setup

```dart
// In main.dart or app initialization
final coordinator = ABTestCoordinator(
  featureFlags: featureFlagsService,
  analytics: analyticsService,
);

// Register the cooldown experiment
coordinator.registerExperiment(
  ABTestExperimentConfig(
    experimentId: 'cooldown_reduction_exp_2026_q4',
    name: 'Cooldown Reduction Optimization',
    description: 'Testing different cooldown reduction speeds',
    startDate: DateTime(2026, 9, 15),
    endDate: DateTime(2026, 10, 15),
    controlVariant: 'baseline',
    rolloutPercentage: 50,
    variantDistribution: {
      'baseline': 34,      // 34% baseline
      'reduced_0.8x': 33,  // 33% reduced 0.8x
      'reduced_0.6x': 33,  // 33% reduced 0.6x
    },
  ),
);
```

### Battle Engine Integration

```dart
class BattleEngine {
  final SkillProgressionConfig _progressionConfig;
  final FeatureFlagsService? _featureFlags;
  final ABTestCoordinator? _coordinator;
  final List<BattleParticipantState> participants;

  BattleEngine({
    required this.participants,
    required SkillProgressionConfig progressionConfig,
    FeatureFlagsService? featureFlags,
    ABTestCoordinator? coordinator,
  })  : _progressionConfig = progressionConfig,
        _featureFlags = featureFlags,
        _coordinator = coordinator;

  /// Apply cooldown reduction with experiment variant
  void _updateSkillCooldowns() {
    final difficultyModifiers = _progressionConfig.getDifficultyModifiers();
    
    for (final participant in participants) {
      final userId = participant.userId;
      
      // Get cooldown multiplier from experiment variant
      var cooldownMultiplier = difficultyModifiers.skillCooldownMultiplier;
      
      // Override with experiment variant if user is in treatment group
      if (_coordinator != null) {
        final variant = _coordinator!.getExperimentVariant(
          userId,
          'cooldown_reduction_exp_2026_q4',
        );
        
        cooldownMultiplier = switch(variant) {
          'baseline' => 1.0,
          'reduced_0.8x' => 0.8,
          'reduced_0.6x' => 0.6,
          _ => 1.0,
        };
      }
      
      // Apply cooldown reduction
      for (final skillName in participant.skillCooldowns.keys) {
        final current = participant.skillCooldowns[skillName]!;
        participant.skillCooldowns[skillName] = 
          (current - (1.0 * cooldownMultiplier)).clamp(0.0, double.infinity);
      }
    }
  }

  /// Log battle completion with experiment context
  void _logBattleOutcome(BattleResult result) {
    for (final participant in participants) {
      if (_coordinator != null) {
        _coordinator!.logEventWithExperiment(
          participant.userId,
          'skill_progression_battle_completed',
          {
            'outcome': result.winner == participant.userId ? 'win' : 'loss',
            'skills_used': participant.skillsUsed.length,
            'avg_cooldown_efficiency': participant.avgCooldownEfficiency,
            'battle_duration_seconds': result.durationSeconds,
            'total_damage_dealt': participant.totalDamageDealt,
          },
          'cooldown_reduction_exp_2026_q4',
        );
      }
    }
  }
}
```

## 2. Difficulty Cohort-Based Progression

### User Progression with Cohort Tracking

```dart
class SkillProgressionService {
  final BattleEngine engine;
  final SkillProgressionAnalyticsService analytics;
  final FeatureFlagsService featureFlags;

  /// Determine progression speed based on difficulty cohort
  Future<void> applyBattleProgression(
    String userId,
    BattleResult result,
  ) async {
    final cohort = featureFlags.getDifficultyCohort(userId);
    
    // Get progression speed multiplier per cohort
    final progressionMultiplier = switch(cohort) {
      'easy' => 1.2,     // 20% faster for easy players
      'normal' => 1.0,   // baseline
      'hard' => 0.8,     // 20% slower for hard players (more challenging)
      _ => 1.0,
    };
    
    // Apply skill points with multiplier
    final baseSkillPoints = _calculateSkillPoints(result);
    final finalSkillPoints = (baseSkillPoints * progressionMultiplier).toInt();
    
    // Update user progression
    await engine.addSkillPoints(userId, finalSkillPoints);
    
    // Log progression with cohort context
    await analytics.logCustomEvent(
      userId,
      'skill_points_earned',
      {
        'base_points': baseSkillPoints,
        'final_points': finalSkillPoints,
        'multiplier': progressionMultiplier,
        'cohort': cohort,
      },
    );
  }

  int _calculateSkillPoints(BattleResult result) {
    int points = result.outcome == 'win' ? 50 : 25;
    points += result.killsCount * 10;
    points += result.assistsCount * 5;
    return points;
  }
}
```

## 3. Gradual Feature Rollout with Monitoring

### New Matchmaking Algorithm Canary Release

```dart
class MatchmakingService {
  final FeatureFlagsService featureFlags;
  final ABTestCoordinator coordinator;

  /// Find match using appropriate algorithm based on feature flag
  Future<Match?> findMatch(String userId) async {
    // Start with canary rollout (10%)
    featureFlags.setRolloutPercentage('experimental_matchmaking', 10);
    
    final enabled = featureFlags.isFeatureEnabled(
      userId,
      'experimental_matchmaking',
    );
    
    if (enabled) {
      final variant = featureFlags.getVariant(
        userId,
        'experimental_matchmaking',
      );
      
      return switch(variant) {
        'v1' => await _matchmakingV1(userId),
        'v2' => await _matchmakingV2(userId),
        _ => await _matchmakingV1(userId),
      };
    } else {
      return _matchmakingV1(userId);
    }
  }

  /// Expand rollout based on metrics
  Future<void> expandRolloutIfHealthy() async {
    // Query analytics for health check
    final crashRate = await _checkCrashRate('experimental_matchmaking');
    final latencyP99 = await _checkLatencyP99('experimental_matchmaking');
    
    if (crashRate < 0.1 && latencyP99 < 2000) {
      // Expand to beta (25%)
      featureFlags.setRolloutPercentage('experimental_matchmaking', 25);
    }
  }

  /// Emergency kill switch
  Future<void> disableIfBroken() async {
    final errorRate = await _checkErrorRate('experimental_matchmaking');
    
    if (errorRate > 5.0) {
      // Kill switch engaged
      featureFlags.disableFeature('experimental_matchmaking');
    }
  }

  Future<int> _checkCrashRate(String featureName) async {
    // Query from analytics dashboard
    return 0; // Placeholder
  }

  Future<int> _checkLatencyP99(String featureName) async {
    // Query from performance monitoring
    return 0; // Placeholder
  }

  Future<double> _checkErrorRate(String featureName) async {
    // Query error rate from analytics
    return 0.0; // Placeholder
  }

  Future<Match?> _matchmakingV1(String userId) async {
    // Original algorithm
    return null; // Placeholder
  }

  Future<Match?> _matchmakingV2(String userId) async {
    // New algorithm
    return null; // Placeholder
  }
}
```

## 4. UI Feature Flags with Widgets

### Conditional UI Layout Based on Feature Flag

```dart
class LobbyScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final featureFlags = ref.watch(featureFlagsProvider);
    final userId = ref.watch(currentUserProvider).value?.id;
    
    if (userId == null) {
      return const SizedBox.shrink();
    }
    
    // Check if new UI layout is enabled for this user
    final useNewLayout = featureFlags.isFeatureEnabled(userId, 'new_ui_layout') &&
        featureFlags.getVariant(userId, 'new_ui_layout') == 'new';
    
    return useNewLayout ? _buildNewLayout() : _buildOldLayout();
  }

  Widget _buildNewLayout() {
    return Column(
      children: [
        _buildModernHeader(),
        _buildDashboardCardsGrid(),
        _buildActionBar(),
      ],
    );
  }

  Widget _buildOldLayout() {
    return Column(
      children: [
        _buildTraditionalHeader(),
        _buildSimpleButtonList(),
      ],
    );
  }

  Widget _buildModernHeader() => const Placeholder();
  Widget _buildDashboardCardsGrid() => const Placeholder();
  Widget _buildActionBar() => const Placeholder();
  Widget _buildTraditionalHeader() => const Placeholder();
  Widget _buildSimpleButtonList() => const Placeholder();
}
```

## 5. Multi-Cohort A/B Test

### Testing Evolution Difficulty Separately Per Cohort

```dart
class EvolutionSelectService {
  final ABTestCoordinator coordinator;
  final SkillProgressionConfig progressionConfig;

  /// Get evolution options for user with cohort-specific difficulty
  Future<List<EvolutionOption>> getEvolutionOptions(
    String userId,
    int currentLevel,
  ) async {
    final cohort = progressionConfig.getDifficultyModifiers().levelDifficultyMultiplier;
    final cohortName = cohort < 1.0 ? 'easy' : cohort > 1.0 ? 'hard' : 'normal';
    
    // Register experiment per cohort
    final experimentId = 'evolution_difficulty_${cohortName}_2026_q4';
    
    // Get variant for this user
    final variant = coordinator.getExperimentVariant(userId, experimentId);
    
    // Adjust difficulty based on variant
    final difficulty = switch(variant) {
      'easy' => 0.7,
      'normal' => 1.0,
      'hard' => 1.3,
      _ => 1.0,
    };
    
    // Generate options
    final options = _generateEvolutionOptions(currentLevel, difficulty);
    
    // Log selection screen viewed
    coordinator.logEventWithExperiment(
      userId,
      'evolution_select_shown',
      {
        'level': currentLevel,
        'option_count': options.length,
        'difficulty_multiplier': difficulty,
      },
      experimentId,
    );
    
    return options;
  }

  /// Handle user selection
  Future<void> confirmEvolution(
    String userId,
    String selectedEvolutionId,
  ) async {
    final cohort = progressionConfig.getDifficultyModifiers().levelDifficultyMultiplier;
    final cohortName = cohort < 1.0 ? 'easy' : cohort > 1.0 ? 'hard' : 'normal';
    final experimentId = 'evolution_difficulty_${cohortName}_2026_q4';
    
    coordinator.logEventWithExperiment(
      userId,
      'evolution_confirmed',
      {
        'evolution_id': selectedEvolutionId,
      },
      experimentId,
    );
  }

  List<EvolutionOption> _generateEvolutionOptions(
    int level,
    double difficulty,
  ) {
    // Generate based on difficulty
    return [];
  }
}
```

## 6. Performance Monitoring per Variant

### Track Metrics by Experiment Variant

```dart
class PerformanceAnalytics {
  final SkillProgressionAnalyticsService analytics;
  final ABTestCoordinator coordinator;

  /// Log frame time with experiment context
  void logFrameTime(
    String userId,
    Duration frameTime,
    String experimentId,
  ) {
    final ms = frameTime.inMilliseconds;
    final isSlow = ms > 16; // 60 FPS = 16ms per frame
    
    coordinator.logEventWithExperiment(
      userId,
      'frame_time_recorded',
      {
        'frame_time_ms': ms,
        'is_slow_frame': isSlow,
        'fps_equivalent': (1000 / frameTime.inMilliseconds).toStringAsFixed(1),
      },
      experimentId,
    );
  }

  /// Log memory usage per variant
  void logMemoryUsage(
    String userId,
    int memoryBytes,
    String experimentId,
  ) {
    coordinator.logEventWithExperiment(
      userId,
      'memory_usage_sampled',
      {
        'memory_mb': (memoryBytes / (1024 * 1024)).toStringAsFixed(2),
        'memory_bytes': memoryBytes,
      },
      experimentId,
    );
  }

  /// Log crash with variant information
  Future<void> logCrashWithVariant(
    String userId,
    Exception error,
    String experimentId,
  ) async {
    coordinator.logEventWithExperiment(
      userId,
      'app_crashed',
      {
        'error_type': error.runtimeType.toString(),
        'error_message': error.toString(),
      },
      experimentId,
    );
  }
}
```

## 7. Complete Battle Session Flow with Experiments

```dart
class BattleSessionWithExperiments {
  final BattleEngine engine;
  final ABTestCoordinator coordinator;
  final FeatureFlagsService featureFlags;
  final SkillProgressionAnalyticsService analytics;

  /// Run complete battle session with all experiments
  Future<BattleResult> runBattleSession(
    String userId,
    String opponentId,
  ) async {
    // Get all active experiments for user
    final activeExperiments = coordinator.getActiveExperiments(userId);
    
    print('Active experiments: ${activeExperiments.length}');
    for (final exp in activeExperiments) {
      final variant = coordinator.getExperimentVariant(userId, exp.experimentId);
      print('  ${exp.experimentId}: $variant');
    }
    
    // Prepare battle with experiment variants
    final cooldownVariant = coordinator.getExperimentVariant(
      userId,
      'cooldown_reduction_exp_2026_q4',
    );
    
    final matchmakingVariant = coordinator.getExperimentVariant(
      userId,
      'experimental_matchmaking',
    );
    
    // Start battle
    engine.start();
    
    // Run battle loop
    while (!engine.isFinished) {
      engine.tick();
      await Future.delayed(Duration(milliseconds: 100));
    }
    
    // Get result
    final result = engine.getResult();
    
    // Log all events with experiment context
    for (final exp in activeExperiments) {
      coordinator.logEventWithExperiment(
        userId,
        'battle_session_completed',
        {
          'outcome': result.winner == userId ? 'win' : 'loss',
          'kills': result.killsCount,
          'duration_seconds': result.durationSeconds,
          'elo_change': result.eloChange,
        },
        exp.experimentId,
      );
    }
    
    return result;
  }
}
```

## Testing These Integrations

```dart
test('cooldown multiplier varies by experiment variant', () {
  final featureFlags = FeatureFlagsService();
  final analytics = MockAnalyticsService();
  final coordinator = ABTestCoordinator(
    featureFlags: featureFlags,
    analytics: analytics,
  );
  
  // Register experiment
  coordinator.registerExperiment(
    ABTestExperimentConfig(
      experimentId: 'test_cooldown',
      name: 'Test',
      description: 'Test',
      startDate: DateTime.now().subtract(Duration(days: 1)),
      controlVariant: 'baseline',
      rolloutPercentage: 100,
      variantDistribution: {
        'baseline': 50,
        'reduced_0.8x': 50,
      },
    ),
  );
  
  // Test that different users get different variants
  final variant1 = coordinator.getExperimentVariant('user_a', 'test_cooldown');
  final variant2 = coordinator.getExperimentVariant('user_b', 'test_cooldown');
  
  // At least some variation (statistically likely)
  print('User A: $variant1, User B: $variant2');
});
```

## Deployment Checklist

- [ ] Register all experiments in `main.dart`
- [ ] Add experiment IDs to analytics event tracking
- [ ] Set up Remote Config values for feature flags
- [ ] Configure rollout percentages for canary launch
- [ ] Set up monitoring for variant comparison
- [ ] Create dashboard for experiment metrics
- [ ] Document variant interpretation for data team
- [ ] Test kill switch procedure
- [ ] Plan rollout schedule (canary → beta → GA)
