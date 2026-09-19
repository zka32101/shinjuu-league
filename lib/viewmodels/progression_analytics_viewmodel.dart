import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shinjuu_league/data/models/progression_stats.dart';
import 'package:shinjuu_league/services/progression_analytics_service.dart';

/// State for progression analytics
class ProgressionAnalyticsState {
  final ProgressionStats? stats;
  final SeasonComparison? comparison;
  final TierPrediction? prediction;
  final bool isLoading;
  final String? error;

  ProgressionAnalyticsState({
    this.stats,
    this.comparison,
    this.prediction,
    this.isLoading = false,
    this.error,
  });

  ProgressionAnalyticsState copyWith({
    ProgressionStats? stats,
    SeasonComparison? comparison,
    TierPrediction? prediction,
    bool? isLoading,
    String? error,
  }) {
    return ProgressionAnalyticsState(
      stats: stats ?? this.stats,
      comparison: comparison ?? this.comparison,
      prediction: prediction ?? this.prediction,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// ViewModel for progression analytics
class ProgressionAnalyticsViewModel extends StateNotifier<ProgressionAnalyticsState> {
  final ProgressionAnalyticsService _analyticsService;
  final String _userId;

  ProgressionAnalyticsViewModel(
    this._analyticsService,
    this._userId,
  ) : super(ProgressionAnalyticsState());

  /// Load complete progression statistics
  Future<void> loadProgressionStats() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final stats = await _analyticsService.getProgressionStats(_userId);
      state = state.copyWith(
        stats: stats,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Compare two specific seasons
  Future<void> compareSeasons(String season1Id, String season2Id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final comparison = await _analyticsService.getSeasonComparison(
        _userId,
        season1Id,
        season2Id,
      );
      state = state.copyWith(
        comparison: comparison,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Predict next tier
  Future<void> predictNextTier() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final prediction = await _analyticsService.predictNextTier(_userId);
      state = state.copyWith(
        prediction: prediction,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Get progression trend description
  String getTrendDescription() {
    final stats = state.stats;
    if (stats == null) return 'データを読み込み中...';

    return stats.allTimeStats.progression.getTrendDescription();
  }

  /// Get progression trend emoji
  String getTrendEmoji() {
    final stats = state.stats;
    if (stats == null) return '❓';

    return stats.allTimeStats.progression.getTrendEmoji();
  }

  /// Check if player has multiple seasons (for comparison features)
  bool canCompareSeason() {
    return state.stats?.allSeasons.length ?? 0 >= 2;
  }

  /// Get current season tier or placeholder
  String getCurrentTier() {
    return state.stats?.currentSeason?.finalTier ?? 'Unranked';
  }

  /// Get all-time highest tier
  String getHighestTierEver() {
    return state.stats?.allTimeStats.highestTierEver ?? 'Unranked';
  }

  /// Get career win rate percentage
  double getCareerWinRate() {
    return state.stats?.allTimeStats.careerWinRate ?? 0.0;
  }

  /// Get total games played
  int getTotalGamesPlayed() {
    return state.stats?.allTimeStats.totalGamesPlayed ?? 0;
  }

  /// Get seasons played
  int getSeasonsPlayed() {
    return state.stats?.allTimeStats.totalSeasonsPlayed ?? 0;
  }

  /// Get average games per season
  double getAverageGamesPerSeason() {
    return state.stats?.allTimeStats.avgGamesPerSeason ?? 0.0;
  }

  /// Get progression summary text
  String getProgressionSummary() {
    final stats = state.stats;
    if (stats == null) return 'データなし';

    final highest = stats.allTimeStats.highestTierEver;
    final current = stats.currentSeason?.finalTier ?? 'Unranked';
    final seasons = stats.allTimeStats.totalSeasonsPlayed;
    final winRate = (stats.allTimeStats.careerWinRate * 100).toStringAsFixed(1);

    return '$seasons シーズンプレイ | 最高: $highest | 現在: $current | 勝率: $winRate%';
  }

  /// Get ELO chart data for visualization
  List<({DateTime date, double rating})> getEloChartData() {
    return state.stats?.getEloChartData() ?? [];
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Riverpod provider for progression analytics service
final progressionAnalyticsServiceProvider =
    Provider<ProgressionAnalyticsService>((ref) {
  throw UnimplementedError(
    'progressionAnalyticsServiceProvider must be provided by the application',
  );
});

/// Riverpod provider for progression analytics view model
final progressionAnalyticsViewModelProvider =
    StateNotifierProvider.family.autoDispose<
        ProgressionAnalyticsViewModel,
        ProgressionAnalyticsState,
        String>((ref, userId) {
  final analyticsService = ref.watch(progressionAnalyticsServiceProvider);
  return ProgressionAnalyticsViewModel(analyticsService, userId);
});

/// Provider to get progression stats directly
final progressionStatsProvider =
    FutureProvider.family.autoDispose<ProgressionStats?, String>(
  (ref, userId) async {
    final analyticsService = ref.watch(progressionAnalyticsServiceProvider);
    return analyticsService.getProgressionStats(userId);
  },
);

/// Provider to get tier prediction
final tierPredictionProvider =
    FutureProvider.family.autoDispose<TierPrediction?, String>(
  (ref, userId) async {
    final analyticsService = ref.watch(progressionAnalyticsServiceProvider);
    try {
      return await analyticsService.predictNextTier(userId);
    } catch (e) {
      return null;
    }
  },
);
