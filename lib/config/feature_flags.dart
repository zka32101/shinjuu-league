import 'package:shinjuu_league/services/remote_config_service.dart';

/// ABテストと機能フラグの統一インターフェース
/// RemoteConfigService をラップして、アプリ全体で一貫した設定アクセスを提供
class FeatureFlags {
  static final RemoteConfigService _remoteConfig = RemoteConfigService();

  // ========== Aha Moment テスト ==========

  /// Aha Moment 達成に必要なキル数（デフォルト: 1）
  /// ABテスト: キル数を 1 or 2 に変更してリテンション改善を測定
  static int getAhaMomentThreshold() =>
      _remoteConfig.getAhaMomentKillCount();

  /// Aha Moment の時間制限（デフォルト: 300秒 = 5分試合全体）
  static int getAhaMomentTimeLimit() =>
      _remoteConfig.getAhaMomentTimeLimitSeconds();

  // ========== Matchmaking 難易度テスト ==========

  /// マッチング検索のタイムアウト秒数（デフォルト: 30秒）
  /// ABテスト: 20秒 vs 30秒でユーザー満足度を測定
  static int getMatchmakingTimeout() =>
      _remoteConfig.getMatchmakingTimeoutSeconds();

  /// マッチング時の Elo 差分許容値（デフォルト: 200）
  /// ABテスト: 100 vs 200 vs 300 で難易度感を測定
  static int getMatchmakingEloDiff() =>
      _remoteConfig.getMatchmakingMinEloDiff();

  // ========== ランク戦開放テスト ==========

  /// ランク戦に必要なレベル（デフォルト: 5）
  /// ABテスト: 3 vs 5 vs 10 で早期マネタイゼーション効果を測定
  static int getRankedUnlockLevel() =>
      _remoteConfig.getRankedMinLevel();

  /// ランク戦参加費用（デフォルト: 0 無料）
  /// ABテスト: 0 vs 100 vs 500 ゴールドで LTV 改善を測定
  static int getRankedEntryFee() =>
      _remoteConfig.getRankedEntryFee();

  // ========== 課金テスト（価格最適化）==========

  /// バトルパスの価格（yen、デフォルト: 500）
  /// ABテスト: ¥300 vs ¥500 vs ¥800 で購買率を測定
  static int getBattlePassPrice() =>
      _remoteConfig.getBattlepassPriceYen();

  /// バトルパスの期間（日数、デフォルト: 30）
  static int getBattlePassDuration() =>
      _remoteConfig.getBattlepassDurationDays();

  /// スキンガチャの価格（yen、デフォルト: 300）
  /// ABテスト: ¥100 vs ¥300 vs ¥500 で回転数を測定
  static int getSkinGachaPrice() =>
      _remoteConfig.getSkinGachaPriceYen();

  /// スキンガチャの天井（デフォルト: 100回）
  /// ABテスト: 50 vs 100 vs 150 で LTV 最適化
  static int getSkinGachaCeiling() =>
      _remoteConfig.getSkinGachaGuaranteedPulls();

  // ========== ゲームバランステスト ==========

  /// 攻撃進化の倍率（デフォルト: 1.3倍）
  /// ABテスト: 1.2 vs 1.3 vs 1.4 で進化選択バランスを測定
  static double getEvolutionAttackMultiplier() =>
      _remoteConfig.getEvolutionAttackBoost();

  /// 防御進化の倍率（デフォルト: 1.3倍）
  static double getEvolutionDefenseMultiplier() =>
      _remoteConfig.getEvolutionDefenseBoost();

  /// 機動進化の倍率（デフォルト: 1.3倍）
  static double getEvolutionMobilityMultiplier() =>
      _remoteConfig.getEvolutionMobilityBoost();

  // ========== Elo 計算テスト ==========

  /// デフォルト K 値（デフォルト: 32.0）
  /// ABテスト: 16 vs 32 vs 64 で勝率変動の敏感度を測定
  static double getEloKFactor() =>
      _remoteConfig.getEloKFactorDefault();

  /// 高レート向け K 値（デフォルト: 16.0）
  static double getEloKFactorHighRating() =>
      _remoteConfig.getEloKFactorHighRating();

  /// K 値を切り替える Elo 閾値（デフォルト: 2000）
  static double getEloHighRatingThreshold() =>
      _remoteConfig.getEloKFactorRatingThreshold();

  // ========== 機能フラグ ==========

  /// ランク戦機能の有効/無効
  static bool isRankedModeEnabled() =>
      _remoteConfig.isRankedModeEnabled();

  /// ソーシャル機能（フレンド、ギルド）の有効/無効
  static bool isSocialFeaturesEnabled() =>
      _remoteConfig.isSocialFeaturesEnabled();

  /// バトルリプレイ機能の有効/無効
  static bool isBattleReplayEnabled() =>
      _remoteConfig.isBattleReplayEnabled();

  /// 課金機能全体の有効/無効
  static bool isMonetizationEnabled() =>
      _remoteConfig.isMonetizationEnabled();

  /// メンテナンスモード（ユーザーをシャットダウン画面に表示）
  static bool isMaintenanceModeEnabled() =>
      _remoteConfig.isMaintenanceModeEnabled();

  // ========== デバッグ ==========

  /// すべての現在のフラグ値をダンプ（開発用）
  static Map<String, dynamic> debugDumpFlags() {
    return {
      'aha_moment_threshold': getAhaMomentThreshold(),
      'aha_moment_time_limit': getAhaMomentTimeLimit(),
      'matchmaking_timeout': getMatchmakingTimeout(),
      'matchmaking_elo_diff': getMatchmakingEloDiff(),
      'ranked_unlock_level': getRankedUnlockLevel(),
      'ranked_entry_fee': getRankedEntryFee(),
      'battlepass_price': getBattlePassPrice(),
      'battlepass_duration': getBattlePassDuration(),
      'skin_gacha_price': getSkinGachaPrice(),
      'skin_gacha_ceiling': getSkinGachaCeiling(),
      'evolution_attack_mult': getEvolutionAttackMultiplier(),
      'evolution_defense_mult': getEvolutionDefenseMultiplier(),
      'evolution_mobility_mult': getEvolutionMobilityMultiplier(),
      'elo_k_factor': getEloKFactor(),
      'elo_k_factor_high': getEloKFactorHighRating(),
      'elo_high_rating_threshold': getEloHighRatingThreshold(),
      'ranked_enabled': isRankedModeEnabled(),
      'social_enabled': isSocialFeaturesEnabled(),
      'replay_enabled': isBattleReplayEnabled(),
      'monetization_enabled': isMonetizationEnabled(),
      'maintenance_mode': isMaintenanceModeEnabled(),
    };
  }
}
