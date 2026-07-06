import 'dart:math';
import 'package:shinjuu_league/config/app_config.dart';

/// Elo計算はサーバー側検証が必須（クライアントの計算はプレビュー表示のみ）。
/// 実際の反映は Cloud Functions 経由での battle/end 処理を想定。
class EloService {
  /// 自分のレーティングが相手レーティングに勝つ期待値（0.0〜1.0）
  static double expectedScore({
    required double rating,
    required double opponentRating,
  }) {
    return 1 / (1 + pow(10, (opponentRating - rating) / 400));
  }

  /// 勝敗結果を反映した Elo 変化量を計算
  static double calculateEloChange({
    required double currentRating,
    required double opponentAvgRating,
    required bool isWin,
    double kFactor = AppConfig.eloKFactor,
  }) {
    final expected = expectedScore(
      rating: currentRating,
      opponentRating: opponentAvgRating,
    );
    final actual = isWin ? 1.0 : 0.0;
    final change = kFactor * (actual - expected);
    return double.parse(change.toStringAsFixed(2));
  }

  /// チーム平均レーティングを算出（マッチング・Elo計算共通で使用）
  static double averageRating(List<double> ratings) {
    if (ratings.isEmpty) return AppConfig.baseElo;
    return ratings.reduce((a, b) => a + b) / ratings.length;
  }
}
