import 'package:firebase_remote_config/firebase_remote_config.dart';

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

  /// 初期化（アプリ起動時に一度だけ呼び出し）
  Future<void> init() async {
    if (_initialized) return;

    _remoteConfig = FirebaseRemoteConfig.instance;

    // デフォルト値を設定
    await _remoteConfig.setDefaults({
      // Aha Moment の定義
      'aha_moment_kill_count': 1,
      'aha_moment_time_limit_seconds': 300,

      // マッチング
      'matchmaking_timeout_seconds': 30,
      'matchmaking_min_elo_diff': 200,

      // ランク戦
      'ranked_min_level': 5,
      'ranked_entry_fee': 0,

      // バトルパス価格（ABテスト）
      'battlepass_price_yen': 500,
      'battlepass_duration_days': 30,

      // スキンガチャ
      'skin_gacha_price_yen': 300,
      'skin_gacha_guaranteed_pulls': 100,

      // 進化の難易度
      'evolution_attack_boost': 1.3,
      'evolution_defense_boost': 1.3,
      'evolution_mobility_boost': 1.3,

      // Elo計算
      'elo_k_factor_default': 32.0,
      'elo_k_factor_high_rating': 16.0,
      'elo_k_factor_rating_threshold': 2000.0,

      // 機能フラグ
      'enable_ranked_mode': true,
      'enable_social_features': true,
      'enable_battle_replay': true,
      'enable_monetization': true,
      'maintenance_mode': false,
    });

    // リモート設定を取得（キャッシュ有効期限：1時間）
    try {
      await _remoteConfig.fetchAndActivate();
    } catch (e) {
      // ネットワークエラー時はデフォルト値を使用
      print('Remote Config fetch failed: $e');
    }

    _initialized = true;
  }

  // ========== Aha Moment Config ==========

  int getAhaMomentKillCount() =>
      _remoteConfig.getInt('aha_moment_kill_count');

  int getAhaMomentTimeLimitSeconds() =>
      _remoteConfig.getInt('aha_moment_time_limit_seconds');

  // ========== Matchmaking Config ==========

  int getMatchmakingTimeoutSeconds() =>
      _remoteConfig.getInt('matchmaking_timeout_seconds');

  int getMatchmakingMinEloDiff() =>
      _remoteConfig.getInt('matchmaking_min_elo_diff');

  // ========== Ranked Mode Config ==========

  int getRankedMinLevel() =>
      _remoteConfig.getInt('ranked_min_level');

  int getRankedEntryFee() =>
      _remoteConfig.getInt('ranked_entry_fee');

  // ========== Monetization Config ==========

  int getBattlepassPriceYen() =>
      _remoteConfig.getInt('battlepass_price_yen');

  int getBattlepassDurationDays() =>
      _remoteConfig.getInt('battlepass_duration_days');

  int getSkinGachaPriceYen() =>
      _remoteConfig.getInt('skin_gacha_price_yen');

  int getSkinGachaGuaranteedPulls() =>
      _remoteConfig.getInt('skin_gacha_guaranteed_pulls');

  // ========== Evolution Difficulty ==========

  double getEvolutionAttackBoost() =>
      _remoteConfig.getDouble('evolution_attack_boost');

  double getEvolutionDefenseBoost() =>
      _remoteConfig.getDouble('evolution_defense_boost');

  double getEvolutionMobilityBoost() =>
      _remoteConfig.getDouble('evolution_mobility_boost');

  // ========== Elo Calculation ==========

  double getEloKFactorDefault() =>
      _remoteConfig.getDouble('elo_k_factor_default');

  double getEloKFactorHighRating() =>
      _remoteConfig.getDouble('elo_k_factor_high_rating');

  double getEloKFactorRatingThreshold() =>
      _remoteConfig.getDouble('elo_k_factor_rating_threshold');

  // ========== Feature Flags ==========

  bool isRankedModeEnabled() =>
      _remoteConfig.getBool('enable_ranked_mode');

  bool isSocialFeaturesEnabled() =>
      _remoteConfig.getBool('enable_social_features');

  bool isBattleReplayEnabled() =>
      _remoteConfig.getBool('enable_battle_replay');

  bool isMonetizationEnabled() =>
      _remoteConfig.getBool('enable_monetization');

  bool isMaintenanceModeEnabled() =>
      _remoteConfig.getBool('maintenance_mode');

  // ========== Raw Access ==========

  /// 任意の設定値にアクセス（型は String で返される）
  String getRawString(String key) => _remoteConfig.getString(key);

  /// すべての設定値を取得
  Map<String, RemoteConfigValue> getAll() =>
      _remoteConfig.getAll();
}
