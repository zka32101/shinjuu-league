import 'package:firebase_remote_config/firebase_remote_config.dart';

/// Skill progression configuration with Remote Config support.
///
/// All parameters have conservative defaults that enable gameplay without Remote Config.
/// When Remote Config is available, these values are overridden by server configuration
/// for A/B testing and live balance tuning.
class SkillProgressionConfig {
  static final SkillProgressionConfig _instance = SkillProgressionConfig._internal();

  factory SkillProgressionConfig() {
    return _instance;
  }

  SkillProgressionConfig._internal();

  late FirebaseRemoteConfig _remoteConfig;
  bool _isInitialized = false;

  // ===============================
  // Level Progression Parameters
  // ===============================

  /// Experience required to level up (base multiplier, 1.0x = standard)
  /// Lower values = faster leveling, higher = slower leveling
  /// Default: 1.0x (standard progression)
  /// Range: 0.5x (50% faster) to 2.0x (100% slower)
  static const _keyLevelDifficultyMultiplier = 'skill_progression_level_difficulty_multiplier';
  static const double _defaultLevelDifficultyMultiplier = 1.0;

  double get levelDifficultyMultiplier => _getDouble(
    _keyLevelDifficultyMultiplier,
    _defaultLevelDifficultyMultiplier,
  );

  /// Maximum character level in a battle
  /// Default: 8 (Lv1-8 progression)
  /// Range: 5 (quick games) to 15 (extended)
  static const _keyMaxCharacterLevel = 'skill_progression_max_character_level';
  static const int _defaultMaxCharacterLevel = 8;

  int get maxCharacterLevel => _getInt(
    _keyMaxCharacterLevel,
    _defaultMaxCharacterLevel,
  );

  // ===============================
  // Evolution Parameters (Lv3 & Lv6)
  // ===============================

  /// Level at which first evolution is unlocked
  /// Default: 3
  /// Range: 2-5 (faster/slower first evolution choice)
  static const _keyFirstEvolutionLevel = 'skill_progression_first_evolution_level';
  static const int _defaultFirstEvolutionLevel = 3;

  int get firstEvolutionLevel => _getInt(
    _keyFirstEvolutionLevel,
    _defaultFirstEvolutionLevel,
  );

  /// Level at which second evolution is unlocked (and switching enabled)
  /// Default: 6
  /// Range: 5-8 (when players can switch evolution types)
  static const _keySecondEvolutionLevel = 'skill_progression_second_evolution_level';
  static const int _defaultSecondEvolutionLevel = 6;

  int get secondEvolutionLevel => _getInt(
    _keySecondEvolutionLevel,
    _defaultSecondEvolutionLevel,
  );

  /// Evolution selection timeout in seconds
  /// After this duration without player input, offensive evolution is auto-selected
  /// Default: 10 seconds
  /// Range: 5-30 seconds
  static const _keyEvolutionSelectionTimeoutSeconds = 'skill_progression_evolution_timeout_seconds';
  static const int _defaultEvolutionSelectionTimeoutSeconds = 10;

  int get evolutionSelectionTimeoutSeconds => _getInt(
    _keyEvolutionSelectionTimeoutSeconds,
    _defaultEvolutionSelectionTimeoutSeconds,
  );

  // ===============================
  // Evolution Bonus Parameters
  // ===============================

  /// Offensive evolution damage bonus percentage (0.0-1.0)
  /// Default: 0.60 (60% damage boost)
  /// Range: 0.3-0.8 (30%-80%)
  static const _keyOffensiveDamageBonus = 'skill_progression_offensive_damage_bonus';
  static const double _defaultOffensiveDamageBonus = 0.60;

  double get offensiveDamageBonus => _getDouble(
    _keyOffensiveDamageBonus,
    _defaultOffensiveDamageBonus,
  );

  /// Defensive evolution HP bonus percentage (0.0-1.0)
  /// Default: 0.50 (50% HP boost)
  /// Range: 0.2-0.7 (20%-70%)
  static const _keyDefensiveHpBonus = 'skill_progression_defensive_hp_bonus';
  static const double _defaultDefensiveHpBonus = 0.50;

  double get defensiveHpBonus => _getDouble(
    _keyDefensiveHpBonus,
    _defaultDefensiveHpBonus,
  );

  /// Support evolution ally effect bonus percentage (0.0-1.0)
  /// Default: 0.45 (45% ally boost)
  /// Range: 0.2-0.6 (20%-60%)
  static const _keySupportAllyEffectBonus = 'skill_progression_support_ally_effect_bonus';
  static const double _defaultSupportAllyEffectBonus = 0.45;

  double get supportAllyEffectBonus => _getDouble(
    _keySupportAllyEffectBonus,
    _defaultSupportAllyEffectBonus,
  );

  // ===============================
  // Skill Parameters
  // ===============================

  /// Skill cooldown multiplier (base 1.0x = standard)
  /// Lower values = shorter cooldowns, higher = longer cooldowns
  /// Default: 1.0x
  /// Range: 0.5x-1.5x
  static const _keySkillCooldownMultiplier = 'skill_progression_skill_cooldown_multiplier';
  static const double _defaultSkillCooldownMultiplier = 1.0;

  double get skillCooldownMultiplier => _getDouble(
    _keySkillCooldownMultiplier,
    _defaultSkillCooldownMultiplier,
  );

  /// Base skill damage multiplier (base 1.0x = standard)
  /// Default: 1.0x
  /// Range: 0.7x-1.5x (70%-150%)
  static const _keySkillDamageMultiplier = 'skill_progression_skill_damage_multiplier';
  static const double _defaultSkillDamageMultiplier = 1.0;

  double get skillDamageMultiplier => _getDouble(
    _keySkillDamageMultiplier,
    _defaultSkillDamageMultiplier,
  );

  /// ULT skill unlock level
  /// Default: 7
  /// Range: 6-8 (when ULT becomes available)
  static const _keyUltUnlockLevel = 'skill_progression_ult_unlock_level';
  static const int _defaultUltUnlockLevel = 7;

  int get ultUnlockLevel => _getInt(
    _keyUltUnlockLevel,
    _defaultUltUnlockLevel,
  );

  // ===============================
  // Feature Flags
  // ===============================

  /// Enable skill progression system
  /// Default: true
  static const _keySkillProgressionEnabled = 'skill_progression_enabled';
  static const bool _defaultSkillProgressionEnabled = true;

  bool get isSkillProgressionEnabled => _getBool(
    _keySkillProgressionEnabled,
    _defaultSkillProgressionEnabled,
  );

  /// Enable evolution switching at Lv6
  /// Default: true
  static const _keyEvolutionSwitchingEnabled = 'skill_progression_evolution_switching_enabled';
  static const bool _defaultEvolutionSwitchingEnabled = true;

  bool get isEvolutionSwitchingEnabled => _getBool(
    _keyEvolutionSwitchingEnabled,
    _defaultEvolutionSwitchingEnabled,
  );

  /// Enable automatic analytics tracking
  /// Default: true
  static const _keyAnalyticsTrackingEnabled = 'skill_progression_analytics_enabled';
  static const bool _defaultAnalyticsTrackingEnabled = true;

  bool get isAnalyticsTrackingEnabled => _getBool(
    _keyAnalyticsTrackingEnabled,
    _defaultAnalyticsTrackingEnabled,
  );

  // ===============================
  // Difficulty Presets (A/B Testing)
  // ===============================

  /// Progression difficulty preset: 'easy', 'normal', 'hard'
  /// Default: 'normal'
  /// Controls overall progression speed via multipliers
  static const _keyDifficultyPreset = 'skill_progression_difficulty_preset';
  static const String _defaultDifficultyPreset = 'normal';

  String get difficultyPreset => _getString(
    _keyDifficultyPreset,
    _defaultDifficultyPreset,
  );

  /// Apply difficulty preset to progression parameters
  /// Used for cohort-based A/B testing (group A gets 'easy', B gets 'hard', etc.)
  ProgressionDifficultyModifiers getDifficultyModifiers() {
    switch (difficultyPreset) {
      case 'easy':
        return ProgressionDifficultyModifiers(
          levelDifficultyMultiplier: 0.7, // 30% faster
          skillCooldownMultiplier: 0.8,   // 20% shorter cooldowns
          skillDamageMultiplier: 0.9,     // 10% less damage (balanced)
        );
      case 'hard':
        return ProgressionDifficultyModifiers(
          levelDifficultyMultiplier: 1.3, // 30% slower
          skillCooldownMultiplier: 1.2,   // 20% longer cooldowns
          skillDamageMultiplier: 1.1,     // 10% more damage (challenging)
        );
      case 'normal':
      default:
        return ProgressionDifficultyModifiers(
          levelDifficultyMultiplier: 1.0,
          skillCooldownMultiplier: 1.0,
          skillDamageMultiplier: 1.0,
        );
    }
  }

  // ===============================
  // Initialization & Refresh
  // ===============================

  /// Initialize Remote Config with caching and defaults
  Future<void> initialize(FirebaseRemoteConfig remoteConfig) async {
    _remoteConfig = remoteConfig;

    // Set default values if not already set
    await _remoteConfig.setDefaults({
      _keyLevelDifficultyMultiplier: _defaultLevelDifficultyMultiplier,
      _keyMaxCharacterLevel: _defaultMaxCharacterLevel,
      _keyFirstEvolutionLevel: _defaultFirstEvolutionLevel,
      _keySecondEvolutionLevel: _defaultSecondEvolutionLevel,
      _keyEvolutionSelectionTimeoutSeconds: _defaultEvolutionSelectionTimeoutSeconds,
      _keyOffensiveDamageBonus: _defaultOffensiveDamageBonus,
      _keyDefensiveHpBonus: _defaultDefensiveHpBonus,
      _keySupportAllyEffectBonus: _defaultSupportAllyEffectBonus,
      _keySkillCooldownMultiplier: _defaultSkillCooldownMultiplier,
      _keySkillDamageMultiplier: _defaultSkillDamageMultiplier,
      _keyUltUnlockLevel: _defaultUltUnlockLevel,
      _keySkillProgressionEnabled: _defaultSkillProgressionEnabled,
      _keyEvolutionSwitchingEnabled: _defaultEvolutionSwitchingEnabled,
      _keyAnalyticsTrackingEnabled: _defaultAnalyticsTrackingEnabled,
      _keyDifficultyPreset: _defaultDifficultyPreset,
    });

    // Fetch from Remote Config with cache expiration (5 minutes for development, 1 hour for production)
    try {
      await _remoteConfig.fetchAndActivate();
    } catch (e) {
      // Remote Config fetch failed, continue with defaults
      // This allows offline gameplay without Remote Config
    }

    _isInitialized = true;
  }

  /// Refresh Remote Config values (call periodically or on demand)
  /// Returns true if new values were fetched and activated
  Future<bool> refresh() async {
    if (!_isInitialized) return false;

    try {
      final updated = await _remoteConfig.fetchAndActivate();
      return updated;
    } catch (e) {
      // Refresh failed, use cached values
      return false;
    }
  }

  bool get isInitialized => _isInitialized;

  // ===============================
  // Debug & Diagnostics
  // ===============================

  /// Dump all current configuration values for debugging
  Map<String, dynamic> debugDumpConfig() {
    return {
      'isInitialized': _isInitialized,
      'levelDifficultyMultiplier': levelDifficultyMultiplier,
      'maxCharacterLevel': maxCharacterLevel,
      'firstEvolutionLevel': firstEvolutionLevel,
      'secondEvolutionLevel': secondEvolutionLevel,
      'evolutionSelectionTimeoutSeconds': evolutionSelectionTimeoutSeconds,
      'offensiveDamageBonus': offensiveDamageBonus,
      'defensiveHpBonus': defensiveHpBonus,
      'supportAllyEffectBonus': supportAllyEffectBonus,
      'skillCooldownMultiplier': skillCooldownMultiplier,
      'skillDamageMultiplier': skillDamageMultiplier,
      'ultUnlockLevel': ultUnlockLevel,
      'isSkillProgressionEnabled': isSkillProgressionEnabled,
      'isEvolutionSwitchingEnabled': isEvolutionSwitchingEnabled,
      'isAnalyticsTrackingEnabled': isAnalyticsTrackingEnabled,
      'difficultyPreset': difficultyPreset,
      'difficultyModifiers': getDifficultyModifiers().toMap(),
    };
  }

  // ===============================
  // Private Helpers
  // ===============================

  double _getDouble(String key, double defaultValue) {
    if (!_isInitialized) return defaultValue;
    try {
      final value = _remoteConfig.getDouble(key);
      // Validate range (most bonuses are 0.0-1.0, multipliers are 0.5-2.0)
      return value.clamp(0.0, 2.0);
    } catch (e) {
      return defaultValue;
    }
  }

  int _getInt(String key, int defaultValue) {
    if (!_isInitialized) return defaultValue;
    try {
      return _remoteConfig.getInt(key);
    } catch (e) {
      return defaultValue;
    }
  }

  bool _getBool(String key, bool defaultValue) {
    if (!_isInitialized) return defaultValue;
    try {
      return _remoteConfig.getBool(key);
    } catch (e) {
      return defaultValue;
    }
  }

  String _getString(String key, String defaultValue) {
    if (!_isInitialized) return defaultValue;
    try {
      return _remoteConfig.getString(key);
    } catch (e) {
      return defaultValue;
    }
  }
}

/// Difficulty modifier container for preset-based tuning
class ProgressionDifficultyModifiers {
  final double levelDifficultyMultiplier;
  final double skillCooldownMultiplier;
  final double skillDamageMultiplier;

  ProgressionDifficultyModifiers({
    required this.levelDifficultyMultiplier,
    required this.skillCooldownMultiplier,
    required this.skillDamageMultiplier,
  });

  Map<String, dynamic> toMap() => {
    'levelDifficultyMultiplier': levelDifficultyMultiplier,
    'skillCooldownMultiplier': skillCooldownMultiplier,
    'skillDamageMultiplier': skillDamageMultiplier,
  };
}
