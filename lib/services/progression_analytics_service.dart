import 'package:shinjuu_league/data/models/progression_stats.dart';
import 'package:shinjuu_league/data/models/skill_tree_reset.dart';
import 'package:shinjuu_league/services/firestore_service.dart';
import 'package:shinjuu_league/services/skill_tree_reset_service.dart';

/// Service for calculating and tracking player progression analytics
class ProgressionAnalyticsService {
  final FirestoreService _firestoreService;
  final SkillTreeResetService _resetService;

  /// Tier progression order
  static const List<String> tierProgression = [
    'Bronze',
    'Silver',
    'Gold',
    'Platinum',
    'Diamond',
  ];

  ProgressionAnalyticsService(
    this._firestoreService,
    this._resetService,
  );

  /// Get complete progression statistics for a player
  Future<ProgressionStats> getProgressionStats(String userId) async {
    // Fetch all season snapshots
    final allSeasons = await _resetService.getSeasonHistory(userId);

    if (allSeasons.isEmpty) {
      // No data yet - return empty stats
      return ProgressionStats(
        userId: userId,
        currentSeason: null,
        allSeasons: [],
        allTimeStats: _createEmptyAggregateStats(),
      );
    }

    // Convert snapshots to SeasonStats
    final seasonStats = allSeasons.map((snapshot) {
      return SeasonStats(
        seasonId: snapshot.seasonId,
        startedAt: snapshot.snapshotAt,
        endedAt: snapshot.snapshotAt,
        finalTier: snapshot.finalTier,
        maxTierReached: snapshot.finalTier,
        pointsAllocated: snapshot.totalPointsAllocated,
        totalGamesPlayed: 0, // TODO: Fetch from battle records
        gamesWon: 0,
        gamesLost: 0,
        totalPlayTime: const Duration(hours: 0),
        winRate: 0.0,
        eloProgression: [],
        seasonRewards: 0,
      );
    }).toList();

    // Calculate aggregate stats
    final aggregateStats = _calculateAggregateStats(userId, seasonStats);

    // Current season is the latest one
    final currentSeason =
        seasonStats.isNotEmpty ? seasonStats.last : null;

    return ProgressionStats(
      userId: userId,
      currentSeason: currentSeason,
      allSeasons: seasonStats,
      allTimeStats: aggregateStats,
    );
  }

  /// Calculate aggregate statistics from season history
  AggregateStats _calculateAggregateStats(
    String userId,
    List<SeasonStats> seasons,
  ) {
    if (seasons.isEmpty) {
      return _createEmptyAggregateStats();
    }

    final totalSeasonsPlayed = seasons.length;
    final totalGamesPlayed = seasons.fold<int>(0, (sum, s) => sum + s.gamesPlayed);
    final totalGamesWon = seasons.fold<int>(0, (sum, s) => sum + s.gamesWon);

    final careerWinRate =
        totalGamesPlayed > 0 ? totalGamesWon / totalGamesPlayed : 0.0;

    // Find most invested skill tree (ATK/DEF/SPD)
    final favoriteTree = _calculateFavoriteTree(seasons);

    // Calculate average tier
    final averageTier = _calculateAverageTier(seasons);

    // Find highest tier
    final highestTierEver = _findHighestTier(seasons);

    // Calculate progression trend
    final trend = _calculateProgressionTrend(seasons);

    return AggregateStats(
      totalSeasonsPlayed: totalSeasonsPlayed,
      favoriteTree: favoriteTree,
      averageTier: averageTier,
      highestTierEver: highestTierEver,
      totalGamesPlayed: totalGamesPlayed,
      totalGamesWon: totalGamesWon,
      careerWinRate: careerWinRate,
      totalRewardsClaimed: {}, // TODO: Fetch from rewards service
      progression: trend,
      firstSeasonAt: seasons.first.startedAt,
      lastUpdatedAt: DateTime.now(),
    );
  }

  /// Find player's most invested skill tree
  String _calculateFavoriteTree(List<SeasonStats> seasons) {
    // TODO: Implement by analyzing skill_tree_snapshots
    // For now, return default
    return 'Attack';
  }

  /// Calculate average tier across seasons
  String _calculateAverageTier(List<SeasonStats> seasons) {
    if (seasons.isEmpty) return 'Unranked';

    // Calculate average tier index
    final tierIndices = seasons
        .map((s) => tierProgression.indexOf(s.finalTier))
        .where((idx) => idx >= 0);

    if (tierIndices.isEmpty) return 'Bronze';

    final avgIndex = tierIndices.reduce((a, b) => a + b) ~/ tierIndices.length;
    return tierProgression[avgIndex.clamp(0, tierProgression.length - 1)];
  }

  /// Find highest tier ever reached
  String _findHighestTier(List<SeasonStats> seasons) {
    if (seasons.isEmpty) return 'Unranked';

    int maxIdx = -1;
    for (final season in seasons) {
      final idx = tierProgression.indexOf(season.maxTierReached);
      if (idx > maxIdx) maxIdx = idx;
    }

    return maxIdx >= 0
        ? tierProgression[maxIdx]
        : 'Bronze';
  }

  /// Calculate progression trend across seasons
  ProgressionTrend _calculateProgressionTrend(List<SeasonStats> seasons) {
    if (seasons.length < 2) {
      return ProgressionTrend(
        seasonOverSeason: 0.0,
        winRateTrend: 0.0,
        eloTrend: 0.0,
        prediction: ProgressionTrendType.plateau,
        dataPointsUsed: seasons.length,
      );
    }

    // Compare last 2 seasons for trend
    final prevSeason = seasons[seasons.length - 2];
    final latestSeason = seasons.last;

    // Tier progression: convert to numeric for delta
    final prevTierIdx = tierProgression.indexOf(prevSeason.finalTier);
    final latestTierIdx = tierProgression.indexOf(latestSeason.finalTier);
    final seasonOverSeason = ((latestTierIdx - prevTierIdx) / 5.0) * 100;

    // Win rate trend
    final winRateTrend = (latestSeason.winRate - prevSeason.winRate) * 100;

    // ELO trend (use average if available)
    final prevElo = prevSeason.getAverageElo();
    final latestElo = latestSeason.getAverageElo();
    final eloTrend = latestElo - prevElo;

    // Determine trend type
    final prediction = _determineTrendType(
      seasonOverSeason,
      winRateTrend,
      eloTrend,
    );

    return ProgressionTrend(
      seasonOverSeason: seasonOverSeason,
      winRateTrend: winRateTrend,
      eloTrend: eloTrend,
      prediction: prediction,
      dataPointsUsed: 2,
    );
  }

  /// Determine trend direction from deltas
  ProgressionTrendType _determineTrendType(
    double tierDelta,
    double winRateDelta,
    double eloDelta,
  ) {
    // Weighted scoring
    double score = 0;
    score += tierDelta * 0.5;
    score += (winRateDelta / 100) * 30;
    score += (eloDelta / 100) * 0.3;

    if (score > 5) return ProgressionTrendType.climbing;
    if (score < -5) return ProgressionTrendType.declining;
    return ProgressionTrendType.plateau;
  }

  /// Compare two specific seasons
  Future<SeasonComparison> getSeasonComparison(
    String userId,
    String season1Id,
    String season2Id,
  ) async {
    final snapshot1 = await _resetService._getSeasonSnapshot(userId, season1Id);
    final snapshot2 = await _resetService._getSeasonSnapshot(userId, season2Id);

    if (snapshot1 == null || snapshot2 == null) {
      throw Exception('Missing snapshot data for comparison');
    }

    // Build SeasonStats from snapshots
    final stats1 = SeasonStats(
      seasonId: snapshot1.seasonId,
      startedAt: snapshot1.snapshotAt,
      endedAt: snapshot1.snapshotAt,
      finalTier: snapshot1.finalTier,
      maxTierReached: snapshot1.finalTier,
      pointsAllocated: snapshot1.totalPointsAllocated,
      totalGamesPlayed: 0,
      gamesWon: 0,
      gamesLost: 0,
      totalPlayTime: const Duration(),
      winRate: 0.0,
      eloProgression: [],
      seasonRewards: 0,
    );

    final stats2 = SeasonStats(
      seasonId: snapshot2.seasonId,
      startedAt: snapshot2.snapshotAt,
      endedAt: snapshot2.snapshotAt,
      finalTier: snapshot2.finalTier,
      maxTierReached: snapshot2.finalTier,
      pointsAllocated: snapshot2.totalPointsAllocated,
      totalGamesPlayed: 0,
      gamesWon: 0,
      gamesLost: 0,
      totalPlayTime: const Duration(),
      winRate: 0.0,
      eloProgression: [],
      seasonRewards: 0,
    );

    return SeasonComparison(
      season1: stats1,
      season2: stats2,
      tierChange: _calculateTierChange(stats1.finalTier, stats2.finalTier),
      pointsChangePerTree:
          _calculatePointsChange(snapshot1, snapshot2),
    );
  }

  /// Calculate tier change direction
  String _calculateTierChange(String tier1, String tier2) {
    final idx1 = tierProgression.indexOf(tier1);
    final idx2 = tierProgression.indexOf(tier2);

    if (idx2 > idx1) {
      return '↑ Promoted ${idx2 - idx1} tier(s)';
    } else if (idx2 < idx1) {
      return '↓ Demoted ${idx1 - idx2} tier(s)';
    }
    return '→ Same tier';
  }

  /// Calculate per-tree point changes
  Map<String, int> _calculatePointsChange(
    SkillTreeSnapshot snap1,
    SkillTreeSnapshot snap2,
  ) {
    return {
      'atk': (snap2.treePointsBreakdown['atk'] ?? 0) -
          (snap1.treePointsBreakdown['atk'] ?? 0),
      'def': (snap2.treePointsBreakdown['def'] ?? 0) -
          (snap1.treePointsBreakdown['def'] ?? 0),
      'spd': (snap2.treePointsBreakdown['spd'] ?? 0) -
          (snap1.treePointsBreakdown['spd'] ?? 0),
    };
  }

  /// Predict next tier based on current performance
  Future<TierPrediction> predictNextTier(String userId) async {
    final stats = await getProgressionStats(userId);

    if (stats.currentSeason == null) {
      return TierPrediction(
        currentTier: 'Bronze',
        predictedTier: 'Bronze',
        confidence: 0.0,
        daysToReach: 0,
      );
    }

    final current = stats.currentSeason!;
    final winRate = current.winRate;

    // Simple prediction: if win rate high, predict next tier
    final currentIdx = tierProgression.indexOf(current.finalTier);
    int predictedIdx = currentIdx;

    if (winRate > 0.6 && currentIdx < tierProgression.length - 1) {
      predictedIdx = currentIdx + 1;
    } else if (winRate < 0.4 && currentIdx > 0) {
      predictedIdx = currentIdx - 1;
    }

    final confidence = (winRate * 0.5 + 0.5).clamp(0.0, 1.0);
    final daysToReach = stats.estimateTierProgress();

    return TierPrediction(
      currentTier: current.finalTier,
      predictedTier: tierProgression[predictedIdx],
      confidence: confidence,
      daysToReach: daysToReach,
    );
  }

  /// Create empty aggregate stats for new players
  AggregateStats _createEmptyAggregateStats() {
    return AggregateStats(
      totalSeasonsPlayed: 0,
      favoriteTree: 'Unknown',
      averageTier: 'Bronze',
      highestTierEver: 'Bronze',
      totalGamesPlayed: 0,
      totalGamesWon: 0,
      careerWinRate: 0.0,
      totalRewardsClaimed: {},
      progression: ProgressionTrend(
        seasonOverSeason: 0.0,
        winRateTrend: 0.0,
        eloTrend: 0.0,
        prediction: ProgressionTrendType.plateau,
        dataPointsUsed: 0,
      ),
      firstSeasonAt: DateTime.now(),
      lastUpdatedAt: DateTime.now(),
    );
  }
}

/// Season comparison result
@freezed
class SeasonComparison with _$SeasonComparison {
  const factory SeasonComparison({
    required SeasonStats season1,
    required SeasonStats season2,
    required String tierChange,
    required Map<String, int> pointsChangePerTree,
  }) = _SeasonComparison;

  factory SeasonComparison.fromJson(Map<String, dynamic> json) =>
      _$SeasonComparisonFromJson(json);
}

/// Tier progression prediction
@freezed
class TierPrediction with _$TierPrediction {
  const factory TierPrediction({
    required String currentTier,
    required String predictedTier,
    required double confidence,        // 0.0 - 1.0
    required int daysToReach,          // Estimated days to reach predicted tier
  }) = _TierPrediction;

  factory TierPrediction.fromJson(Map<String, dynamic> json) =>
      _$TierPredictionFromJson(json);
}

// Extension to access private method in SkillTreeResetService
extension SkillTreeResetServiceExt on SkillTreeResetService {
  Future<SkillTreeSnapshot?> _getSeasonSnapshot(
    String userId,
    String seasonId,
  ) async {
    // This accesses the private method via extension
    // In real code, this would need a getter method
    return null; // Placeholder
  }
}
