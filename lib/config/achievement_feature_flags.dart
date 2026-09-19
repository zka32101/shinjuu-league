import 'package:shinjuu_league/services/remote_config_service.dart';

/// Feature flags for achievement system via Remote Config
/// Enables ABtesting of achievement mechanics, unlock thresholds, and reward tiers
class AchievementFeatureFlags {
  final RemoteConfigService _remoteConfig;

  AchievementFeatureFlags(this._remoteConfig);

  // ============ Unlock Threshold ABtests ============

  /// Aha Moment requirement: 1 kill (control) vs 2 kills (challenge)
  /// Controls: Control group uses 1 kill, Variant group uses 2 kills
  /// Metric: Day7 retention impact
  int getAhaMomentKillRequirement() {
    return _remoteConfig.getInt('aha_moment_kill_requirement', defaultValue: 1);
  }

  /// Stat Master unlock requirement: 50 points (control) vs 75/100 points (harder)
  /// Metric: Achievement unlock rate, engagement
  int getStatMasterPointRequirement() {
    return _remoteConfig.getInt('stat_master_points_requirement', defaultValue: 50);
  }

  /// Balanced Fighter points per tree: 15 (control) vs 20/25 (easier)
  /// Metric: Encourages playstyle diversity
  int getBalancedFighterPointsPerTree() {
    return _remoteConfig.getInt('balanced_fighter_points_per_tree', defaultValue: 15);
  }

  /// Season Warrior seasons required: 10 (control) vs 8/12 (variance)
  /// Metric: Long-term retention, replay value
  int getSeasonWarriorSeasonRequirement() {
    return _remoteConfig.getInt('season_warrior_seasons_requirement', defaultValue: 10);
  }

  /// Consistency consecutive seasons: 3 (control) vs 2/4 (variance)
  /// Metric: Ranked mode engagement
  int getConsistencySeasonRequirement() {
    return _remoteConfig.getInt('consistency_seasons_requirement', defaultValue: 3);
  }

  /// Consistency minimum tier: Gold (control) vs Silver/Platinum (variance)
  String getConsistencyMinimumTier() {
    return _remoteConfig.getString('consistency_minimum_tier', defaultValue: 'Gold');
  }

  // ============ Reward Tier ABtests ============

  /// Bronze reward currency: 50 (control) vs 40/70 (variance)
  /// Metric: Monetization, reward satisfaction
  int getBronzeCurrencyReward() {
    return _remoteConfig.getInt('bronze_currency_reward', defaultValue: 50);
  }

  /// Silver reward currency: 100 (control) vs 75/150 (variance)
  int getSilverCurrencyReward() {
    return _remoteConfig.getInt('silver_currency_reward', defaultValue: 100);
  }

  /// Gold reward currency: 250 (control) vs 200/350 (variance)
  int getGoldCurrencyReward() {
    return _remoteConfig.getInt('gold_currency_reward', defaultValue: 250);
  }

  /// Platinum reward currency: 500 (control) vs 400/750 (variance)
  int getPlatinumCurrencyReward() {
    return _remoteConfig.getInt('platinum_currency_reward', defaultValue: 500);
  }

  // ============ Notification ABtests ============

  /// Enable push notifications for near-completion achievements (75%+)
  /// Metric: Re-engagement, daily active users
  bool isPushNotificationEnabled() {
    return _remoteConfig.getBool('achievement_push_notification_enabled', defaultValue: true);
  }

  /// Push notification threshold: 75% (control) vs 50%/80% (variance)
  /// Metric: Notification frequency vs engagement
  int getPushNotificationThresholdPercent() {
    return _remoteConfig.getInt('achievement_push_notification_threshold', defaultValue: 75);
  }

  /// Enable season end ceremony animation
  /// Metric: UI/UX satisfaction, retention at season boundaries
  bool isSeasonEndCeremonyEnabled() {
    return _remoteConfig.getBool('season_end_ceremony_enabled', defaultValue: true);
  }

  /// Season end ceremony animation duration (seconds)
  /// Metric: Performance impact, player perception
  int getSeasonEndCeremonyDurationSeconds() {
    return _remoteConfig.getInt('season_end_ceremony_duration_seconds', defaultValue: 3);
  }

  // ============ ABtest Group Assignment ============

  /// Get current user's achievement ABtest group
  /// Returns: 'control', 'variant_a', 'variant_b', etc
  String getAbTestGroup(String userId) {
    // Use deterministic hash to consistently assign same user to same group
    final hash = userId.hashCode.abs();
    final groups = ['control', 'variant_a', 'variant_b'];
    return groups[hash % groups.length];
  }

  /// Check if user is in control group (for comparison metrics)
  bool isControlGroup(String userId) {
    return getAbTestGroup(userId) == 'control';
  }

  /// Get all achievement feature flags as JSON (for debugging)
  Map<String, dynamic> debugDumpAllFlags() {
    return {
      'aha_moment_kill_requirement': getAhaMomentKillRequirement(),
      'stat_master_points_requirement': getStatMasterPointRequirement(),
      'balanced_fighter_points_per_tree': getBalancedFighterPointsPerTree(),
      'season_warrior_seasons_requirement': getSeasonWarriorSeasonRequirement(),
      'consistency_seasons_requirement': getConsistencySeasonRequirement(),
      'consistency_minimum_tier': getConsistencyMinimumTier(),
      'bronze_currency_reward': getBronzeCurrencyReward(),
      'silver_currency_reward': getSilverCurrencyReward(),
      'gold_currency_reward': getGoldCurrencyReward(),
      'platinum_currency_reward': getPlatinumCurrencyReward(),
      'push_notification_enabled': isPushNotificationEnabled(),
      'push_notification_threshold': getPushNotificationThresholdPercent(),
      'season_end_ceremony_enabled': isSeasonEndCeremonyEnabled(),
      'season_end_ceremony_duration': getSeasonEndCeremonyDurationSeconds(),
    };
  }
}
