import 'package:freezed_annotation/freezed_annotation.dart';

part 'progression_stats.freezed.dart';
part 'progression_stats.g.dart';

/// Progression trend analysis
enum ProgressionTrendType {
  climbing,   // Tier improving over time
  plateau,    // Tier stable
  declining,  // Tier worsening
}

/// Single-season statistics
@freezed
class SeasonStats with _$SeasonStats {
  const factory SeasonStats({
    required String seasonId,
    required DateTime startedAt,
    DateTime? endedAt,
    required String finalTier,           // Bronze/Silver/Gold/Platinum/Diamond
    required String maxTierReached,      // Highest tier during season
    required int pointsAllocated,        // Skill tree points used
    required int totalGamesPlayed,
    required int gamesWon,
    required int gamesLost,
    required Duration totalPlayTime,    // Hours played this season
    required double winRate,             // 0.0 - 1.0
    required List<EloSnapshot> eloProgression, // ELO curve over time
    required int seasonRewards,          // Total rewards claimed
  }) = _SeasonStats;

  factory SeasonStats.fromJson(Map<String, dynamic> json) =>
      _$SeasonStatsFromJson(json);

  /// Calculate games played
  int get gamesPlayed => gamesWon + gamesLost;

  /// Get average ELO for the season
  double getAverageElo() {
    if (eloProgression.isEmpty) return 1000.0;
    return eloProgression.fold<double>(
          0,
          (sum, snapshot) => sum + snapshot.rating,
        ) /
        eloProgression.length;
  }

  /// Get peak ELO for the season
  double getPeakElo() {
    if (eloProgression.isEmpty) return 1000.0;
    return eloProgression.map((s) => s.rating).reduce((a, b) => a > b ? a : b);
  }

  /// Get lowest ELO for the season
  double getLowestElo() {
    if (eloProgression.isEmpty) return 1000.0;
    return eloProgression.map((s) => s.rating).reduce((a, b) => a < b ? a : b);
  }
}

/// ELO rating snapshot at a point in time
@freezed
class EloSnapshot with _$EloSnapshot {
  const factory EloSnapshot({
    required DateTime recordedAt,
    required double rating,
    required int gamesPlayed,
  }) = _EloSnapshot;

  factory EloSnapshot.fromJson(Map<String, dynamic> json) =>
      _$EloSnapshotFromJson(json);
}

/// Aggregate all-time statistics
@freezed
class AggregateStats with _$AggregateStats {
  const factory AggregateStats({
    required int totalSeasonsPlayed,
    required String favoriteTree,       // Most invested skill tree
    required String averageTier,        // Mean tier across seasons
    required String highestTierEver,    // Career high tier
    required int totalGamesPlayed,
    required int totalGamesWon,
    required double careerWinRate,
    required Map<String, int> totalRewardsClaimed, // reward_type → count
    required ProgressionTrend progression,
    required DateTime firstSeasonAt,
    required DateTime lastUpdatedAt,
  }) = _AggregateStats;

  factory AggregateStats.fromJson(Map<String, dynamic> json) =>
      _$AggregateStatsFromJson(json);

  /// Calculate career KDA (kills + deaths + assists in battles)
  /// Used for comparative analysis
  double get careerKDA {
    if (totalGamesPlayed == 0) return 0.0;
    return totalGamesWon / totalGamesPlayed.clamp(1, totalGamesPlayed);
  }

  /// Get average plays per season
  double get avgGamesPerSeason {
    if (totalSeasonsPlayed == 0) return 0.0;
    return totalGamesPlayed / totalSeasonsPlayed;
  }
}

/// Progression trend tracking
@freezed
class ProgressionTrend with _$ProgressionTrend {
  const factory ProgressionTrend({
    required double seasonOverSeason,    // % change in tier rating
    required double winRateTrend,        // Win rate delta
    required double eloTrend,            // Average ELO delta
    required ProgressionTrendType prediction, // Trend direction
    required int dataPointsUsed,         // Seasons analyzed
  }) = _ProgressionTrend;

  factory ProgressionTrend.fromJson(Map<String, dynamic> json) =>
      _$ProgressionTrendFromJson(json);

  /// Get trend emoji for UI display
  String getTrendEmoji() {
    switch (prediction) {
      case ProgressionTrendType.climbing:
        return '📈';
      case ProgressionTrendType.plateau:
        return '➡️';
      case ProgressionTrendType.declining:
        return '📉';
    }
  }

  /// Get trend description for UI
  String getTrendDescription() {
    switch (prediction) {
      case ProgressionTrendType.climbing:
        return '上昇中 (Climbing)';
      case ProgressionTrendType.plateau:
        return '安定中 (Stable)';
      case ProgressionTrendType.declining:
        return '下降中 (Declining)';
    }
  }
}

/// Complete player progression statistics
@freezed
class ProgressionStats with _$ProgressionStats {
  const factory ProgressionStats({
    required String userId,
    required SeasonStats? currentSeason,
    required List<SeasonStats> allSeasons,    // Historical data
    required AggregateStats allTimeStats,
  }) = _ProgressionStats;

  factory ProgressionStats.fromJson(Map<String, dynamic> json) =>
      _$ProgressionStatsFromJson(json);

  /// Get rank change from last season
  String getRankChange() {
    if (allSeasons.length < 2) return 'N/A';

    final lastSeason = allSeasons[allSeasons.length - 2];
    final currentTier = currentSeason?.finalTier ?? 'Unranked';
    final lastTier = lastSeason.finalTier;

    if (currentTier == lastTier) return '→ Same';

    final tiers = ['Bronze', 'Silver', 'Gold', 'Platinum', 'Diamond'];
    final currentIdx = tiers.indexOf(currentTier);
    final lastIdx = tiers.indexOf(lastTier);

    if (currentIdx > lastIdx) {
      return '↑ +${currentIdx - lastIdx} Tier(s)';
    } else {
      return '↓ ${lastIdx - currentIdx} Tier(s)';
    }
  }

  /// Get ELO progress chart data (for UI visualization)
  List<({DateTime date, double rating})> getEloChartData() {
    return currentSeason?.eloProgression.map((e) {
          return (date: e.recordedAt, rating: e.rating);
        }).toList() ??
        [];
  }

  /// Estimate next tier reach time (in days)
  int estimateTierProgress() {
    if (currentSeason == null) return 0;

    final avgWinRate = currentSeason!.winRate;
    if (avgWinRate == 0) return 999; // Unbeatable if no wins

    final pointsNeeded = 10; // Arbitrary threshold per tier
    final pointsPerGame = avgWinRate * 1.5; // Expected gain per game
    final gamesNeeded = (pointsNeeded / pointsPerGame).ceil();
    final daysPerGame = 1.0; // Assume 1 game per day average

    return (gamesNeeded * daysPerGame).toInt();
  }
}
