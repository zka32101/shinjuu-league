import 'dart:math';
import 'package:shinjuu_league/config/app_config.dart';

/// Elo計算はサーバー側検証が必須（クライアントの計算はプレビュー表示のみ）。
/// 実際の反映は Cloud Functions（functions/src/elo-validator.ts）経由での
/// battle_results 処理で確定する。
class EloService {
  /// Tier-based K-factor thresholds. Must exactly mirror
  /// functions/src/elo-validator.ts's ELO_TIERS - if this drifts, the
  /// preview shown on result_screen.dart (Battle.eloChange) systematically
  /// disagrees with the value the Cloud Function actually applies moments
  /// later, silently corrected via watchUser(). This previously happened:
  /// this class used a single fixed K=32 (AppConfig.eloKFactor) regardless
  /// of tier, while the server already used tier-based K (64/32/24/16) -
  /// meaning every Bronze player (rating < 1400, i.e. most new players) saw
  /// a preview roughly HALF the real Elo change the server would apply.
  static const List<
    ({String name, double minRating, double maxRating, double kFactor})
  >
  _tiers = [
    (name: 'Bronze', minRating: 400, maxRating: 1400, kFactor: 64),
    (name: 'Silver', minRating: 1400, maxRating: 1800, kFactor: 32),
    (name: 'Gold', minRating: 1800, maxRating: 2200, kFactor: 24),
    (name: 'Platinum', minRating: 2200, maxRating: 3000, kFactor: 16),
  ];

  /// The K-factor the server will use for a player at [rating]. Falls back
  /// to [AppConfig.eloKFactor] outside the tier range, mirroring the
  /// server's own DEFAULT_K_FACTOR fallback.
  static double kFactorForRating(double rating) {
    for (final tier in _tiers) {
      if (rating >= tier.minRating && rating < tier.maxRating) {
        return tier.kFactor;
      }
    }
    return AppConfig.eloKFactor;
  }

  /// 自分のレーティングが相手レーティングに勝つ期待値（0.0〜1.0）
  static double expectedScore({
    required double rating,
    required double opponentRating,
  }) {
    return 1 / (1 + pow(10, (opponentRating - rating) / 400));
  }

  /// 勝敗結果を反映した Elo 変化量を計算。[kFactor] を明示しない場合は
  /// [currentRating] のティアから自動決定する（サーバーと同じロジック）。
  static double calculateEloChange({
    required double currentRating,
    required double opponentAvgRating,
    required bool isWin,
    double? kFactor,
  }) {
    final resolvedKFactor = kFactor ?? kFactorForRating(currentRating);
    final expected = expectedScore(
      rating: currentRating,
      opponentRating: opponentAvgRating,
    );
    final actual = isWin ? 1.0 : 0.0;
    final change = resolvedKFactor * (actual - expected);
    return double.parse(change.toStringAsFixed(2));
  }

  /// チーム平均レーティングを算出（マッチング・Elo計算共通で使用）
  static double averageRating(List<double> ratings) {
    if (ratings.isEmpty) return AppConfig.baseElo;
    return ratings.reduce((a, b) => a + b) / ratings.length;
  }
}
