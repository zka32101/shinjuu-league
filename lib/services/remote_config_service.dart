import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

/// Firebase Remote Config 統合
/// ABテストと機能フラグの一元管理
class RemoteConfigService {
  static final RemoteConfigService _instance = RemoteConfigService._internal();

  factory RemoteConfigService() {
    return _instance;
  }

  RemoteConfigService._internal();

  late FirebaseRemoteConfig _remoteConfig;
  bool _initialized = false;

  // ========== Default Values ==========
  // テスト環境や初期化前でも安全に使用できるデフォルト値
  static const int _DEFAULT_AHA_MOMENT_KILL_COUNT = 1;
  static const int _DEFAULT_AHA_MOMENT_TIME_LIMIT_SECONDS = 300;
  static const int _DEFAULT_MATCHMAKING_TIMEOUT_SECONDS = 30;
  static const int _DEFAULT_MATCHMAKING_MIN_ELO_DIFF = 200;
  static const int _DEFAULT_RANKED_MIN_LEVEL = 5;
  static const int _DEFAULT_RANKED_ENTRY_FEE = 0;
  static const int _DEFAULT_BATTLEPASS_PRICE_YEN = 500;
  static const int _DEFAULT_BATTLEPASS_DURATION_DAYS = 30;
  static const int _DEFAULT_SKIN_GACHA_PRICE_YEN = 300;
  static const int _DEFAULT_SKIN_GACHA_GUARANTEED_PULLS = 100;
  static const double _DEFAULT_EVOLUTION_ATTACK_BOOST = 1.3;
  static const double _DEFAULT_EVOLUTION_DEFENSE_BOOST = 1.3;
  static const double _DEFAULT_EVOLUTION_MOBILITY_BOOST = 1.3;
  static const double _DEFAULT_ELO_K_FACTOR_DEFAULT = 32.0;
  static const double _DEFAULT_ELO_K_FACTOR_HIGH_RATING = 16.0;
  static const double _DEFAULT_ELO_K_FACTOR_RATING_THRESHOLD = 2000.0;
  static const bool _DEFAULT_ENABLE_RANKED_MODE = true;
  static const bool _DEFAULT_ENABLE_SOCIAL_FEATURES = true;
  static const bool _DEFAULT_ENABLE_BATTLE_REPLAY = true;
  static const bool _DEFAULT_ENABLE_MONETIZATION = true;
  static const bool _DEFAULT_MAINTENANCE_MODE = false;

  /// 初期化（アプリ起動時に一度だけ呼び出し）
  Future<void> init() async {
    if (_initialized) return;

    _remoteConfig = FirebaseRemoteConfig.instance;

    // デフォルト値を設定
    await _remoteConfig.setDefaults({
      // Aha Moment の定義
      'aha_moment_kill_count': _DEFAULT_AHA_MOMENT_KILL_COUNT,
      'aha_moment_time_limit_seconds': _DEFAULT_AHA_MOMENT_TIME_LIMIT_SECONDS,

      // マッチング
      'matchmaking_timeout_seconds': _DEFAULT_MATCHMAKING_TIMEOUT_SECONDS,
      'matchmaking_min_elo_diff': _DEFAULT_MATCHMAKING_MIN_ELO_DIFF,

      // ランク戦
      'ranked_min_level': _DEFAULT_RANKED_MIN_LEVEL,
      'ranked_entry_fee': _DEFAULT_RANKED_ENTRY_FEE,

      // バトルパス価格（ABテスト）
      'battlepass_price_yen': _DEFAULT_BATTLEPASS_PRICE_YEN,
      'battlepass_duration_days': _DEFAULT_BATTLEPASS_DURATION_DAYS,

      // スキンガチャ
      'skin_gacha_price_yen': _DEFAULT_SKIN_GACHA_PRICE_YEN,
      'skin_gacha_guaranteed_pulls': _DEFAULT_SKIN_GACHA_GUARANTEED_PULLS,

      // 進化の難易度
      'evolution_attack_boost': _DEFAULT_EVOLUTION_ATTACK_BOOST,
      'evolution_defense_boost': _DEFAULT_EVOLUTION_DEFENSE_BOOST,
      'evolution_mobility_boost': _DEFAULT_EVOLUTION_MOBILITY_BOOST,

      // Elo計算
      'elo_k_factor_default': _DEFAULT_ELO_K_FACTOR_DEFAULT,
      'elo_k_factor_high_rating': _DEFAULT_ELO_K_FACTOR_HIGH_RATING,
      'elo_k_factor_rating_threshold': _DEFAULT_ELO_K_FACTOR_RATING_THRESHOLD,

      // 機能フラグ
      'enable_ranked_mode': _DEFAULT_ENABLE_RANKED_MODE,
      'enable_social_features': _DEFAULT_ENABLE_SOCIAL_FEATURES,
      'enable_battle_replay': _DEFAULT_ENABLE_BATTLE_REPLAY,
      'enable_monetization': _DEFAULT_ENABLE_MONETIZATION,
      'maintenance_mode': _DEFAULT_MAINTENANCE_MODE,
    });

    // リモート設定を取得（キャッシュ有効期限：1時間）
    try {
      await _remoteConfig.fetchAndActivate();
    } catch (e) {
      // ネットワークエラー時はデフォルト値を使用
      debugPrint('Remote Config fetch failed: $e');
    }

    _initialized = true;
  }

  // ========== Aha Moment Config ==========

  int getAhaMomentKillCount() =>
      _initialized ? _remoteConfig.getInt('aha_moment_kill_count') : _DEFAULT_AHA_MOMENT_KILL_COUNT;

  int getAhaMomentTimeLimitSeconds() =>
      _initialized ? _remoteConfig.getInt('aha_moment_time_limit_seconds') : _DEFAULT_AHA_MOMENT_TIME_LIMIT_SECONDS;

  // ========== Matchmaking Config ==========

  int getMatchmakingTimeoutSeconds() =>
      _initialized ? _remoteConfig.getInt('matchmaking_timeout_seconds') : _DEFAULT_MATCHMAKING_TIMEOUT_SECONDS;

  int getMatchmakingMinEloDiff() =>
      _initialized ? _remoteConfig.getInt('matchmaking_min_elo_diff') : _DEFAULT_MATCHMAKING_MIN_ELO_DIFF;

  // ========== Ranked Mode Config ==========

  int getRankedMinLevel() =>
      _initialized ? _remoteConfig.getInt('ranked_min_level') : _DEFAULT_RANKED_MIN_LEVEL;

  int getRankedEntryFee() =>
      _initialized ? _remoteConfig.getInt('ranked_entry_fee') : _DEFAULT_RANKED_ENTRY_FEE;

  // ========== Monetization Config ==========

  int getBattlepassPriceYen() =>
      _initialized ? _remoteConfig.getInt('battlepass_price_yen') : _DEFAULT_BATTLEPASS_PRICE_YEN;

  int getBattlepassDurationDays() =>
      _initialized ? _remoteConfig.getInt('battlepass_duration_days') : _DEFAULT_BATTLEPASS_DURATION_DAYS;

  int getSkinGachaPriceYen() =>
      _initialized ? _remoteConfig.getInt('skin_gacha_price_yen') : _DEFAULT_SKIN_GACHA_PRICE_YEN;

  int getSkinGachaGuaranteedPulls() =>
      _initialized ? _remoteConfig.getInt('skin_gacha_guaranteed_pulls') : _DEFAULT_SKIN_GACHA_GUARANTEED_PULLS;

  // ========== Evolution Difficulty ==========

  double getEvolutionAttackBoost() =>
      _initialized ? _remoteConfig.getDouble('evolution_attack_boost') : _DEFAULT_EVOLUTION_ATTACK_BOOST;

  double getEvolutionDefenseBoost() =>
      _initialized ? _remoteConfig.getDouble('evolution_defense_boost') : _DEFAULT_EVOLUTION_DEFENSE_BOOST;

  double getEvolutionMobilityBoost() =>
      _initialized ? _remoteConfig.getDouble('evolution_mobility_boost') : _DEFAULT_EVOLUTION_MOBILITY_BOOST;

  // ========== Elo Calculation ==========

  double getEloKFactorDefault() =>
      _initialized ? _remoteConfig.getDouble('elo_k_factor_default') : _DEFAULT_ELO_K_FACTOR_DEFAULT;

  double getEloKFactorHighRating() =>
      _initialized ? _remoteConfig.getDouble('elo_k_factor_high_rating') : _DEFAULT_ELO_K_FACTOR_HIGH_RATING;

  double getEloKFactorRatingThreshold() =>
      _initialized ? _remoteConfig.getDouble('elo_k_factor_rating_threshold') : _DEFAULT_ELO_K_FACTOR_RATING_THRESHOLD;

  // ========== Feature Flags ==========

  bool isRankedModeEnabled() =>
      _initialized ? _remoteConfig.getBool('enable_ranked_mode') : _DEFAULT_ENABLE_RANKED_MODE;

  bool isSocialFeaturesEnabled() =>
      _initialized ? _remoteConfig.getBool('enable_social_features') : _DEFAULT_ENABLE_SOCIAL_FEATURES;

  bool isBattleReplayEnabled() =>
      _initialized ? _remoteConfig.getBool('enable_battle_replay') : _DEFAULT_ENABLE_BATTLE_REPLAY;

  bool isMonetizationEnabled() =>
      _initialized ? _remoteConfig.getBool('enable_monetization') : _DEFAULT_ENABLE_MONETIZATION;

  bool isMaintenanceModeEnabled() =>
      _initialized ? _remoteConfig.getBool('maintenance_mode') : _DEFAULT_MAINTENANCE_MODE;

  // ========== Raw Access ==========

  /// 任意の設定値にアクセス（型は String で返される）
  /// 初期化前は空文字列を返す
  String getRawString(String key) =>
      _initialized ? _remoteConfig.getString(key) : '';

  /// すべての設定値を取得
  /// 初期化前は空の Map を返す
  Map<String, RemoteConfigValue> getAll() =>
      _initialized ? _remoteConfig.getAll() : {};
}
