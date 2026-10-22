import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shinjuu_league/data/models/progression_stats.dart';
import 'package:shinjuu_league/data/providers/service_providers.dart';
import 'package:shinjuu_league/services/progression_analytics_service.dart';
import 'package:shinjuu_league/ui/screens/progression_analytics_screen.dart';

/// Real bug fixed in the screen/provider this tests:
/// progressionAnalyticsServiceProvider always threw UnimplementedError (no
/// override existed anywhere in the app), and ProgressionAnalyticsScreen
/// didn't exist at all - ProgressionAnalyticsViewModel/Service were fully
/// implemented but had no UI ever constructed to drive them. Both are fixed
/// here: the provider now builds a real ProgressionAnalyticsService, and
/// this screen renders its data.
class FakeProgressionAnalyticsService implements ProgressionAnalyticsService {
  FakeProgressionAnalyticsService({this.stats, this.prediction});

  final ProgressionStats? stats;
  final TierPrediction? prediction;

  @override
  Future<ProgressionStats> getProgressionStats(String userId) async {
    return stats ?? _emptyStats(userId);
  }

  @override
  Future<TierPrediction> predictNextTier(String userId) async {
    return prediction ??
        const TierPrediction(
          currentTier: 'Gold',
          predictedTier: 'Platinum',
          confidence: 0.5,
          daysToReach: 10,
        );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ProgressionStats _emptyStats(String userId) {
  return ProgressionStats(
    userId: userId,
    currentSeason: null,
    allSeasons: const [],
    allTimeStats: AggregateStats(
      totalSeasonsPlayed: 0,
      favoriteTree: 'none',
      averageTier: 'Unranked',
      highestTierEver: 'Unranked',
      totalGamesPlayed: 0,
      totalGamesWon: 0,
      careerWinRate: 0.0,
      totalRewardsClaimed: const {},
      progression: const ProgressionTrend(
        seasonOverSeason: 0,
        winRateTrend: 0,
        eloTrend: 0,
        prediction: ProgressionTrendType.plateau,
        dataPointsUsed: 0,
      ),
      firstSeasonAt: DateTime(2026),
      lastUpdatedAt: DateTime(2026),
    ),
  );
}

SeasonStats _season({
  required String id,
  required String tier,
  int gamesWon = 5,
  int gamesLost = 2,
}) {
  return SeasonStats(
    seasonId: id,
    startedAt: DateTime(2026, 1, 1),
    endedAt: DateTime(2026, 2, 1),
    finalTier: tier,
    maxTierReached: tier,
    pointsAllocated: 10,
    totalGamesPlayed: gamesWon + gamesLost,
    gamesWon: gamesWon,
    gamesLost: gamesLost,
    totalPlayTime: const Duration(hours: 5),
    winRate: gamesWon / (gamesWon + gamesLost),
    eloProgression: [
      EloSnapshot(
        recordedAt: DateTime(2026, 1, 5),
        rating: 1200,
        gamesPlayed: 3,
      ),
      EloSnapshot(
        recordedAt: DateTime(2026, 1, 20),
        rating: 1350,
        gamesPlayed: 7,
      ),
    ],
    seasonRewards: 2,
  );
}

Widget _wrap(
  Widget child, {
  ProgressionStats? stats,
  TierPrediction? prediction,
}) {
  return ProviderScope(
    overrides: [
      progressionAnalyticsServiceProvider.overrideWithValue(
        FakeProgressionAnalyticsService(stats: stats, prediction: prediction),
      ),
    ],
    child: MaterialApp(home: child),
  );
}

void main() {
  group('ProgressionAnalyticsScreen', () {
    testWidgets('shows a login prompt with no resolvable user', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_wrap(const ProgressionAnalyticsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('ログインが必要です'), findsOneWidget);
    });

    testWidgets('shows empty state when no seasons have been played', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const ProgressionAnalyticsScreen(userIdOverride: 'user-1'),
          stats: _emptyStats('user-1'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('まだシーズンのプレイ記録がありません'), findsOneWidget);
    });

    testWidgets('renders real season stats once loaded', (
      WidgetTester tester,
    ) async {
      final stats = ProgressionStats(
        userId: 'user-1',
        currentSeason: _season(id: 's2', tier: 'Gold'),
        allSeasons: [
          _season(id: 's1', tier: 'Silver'),
          _season(id: 's2', tier: 'Gold'),
        ],
        allTimeStats: AggregateStats(
          totalSeasonsPlayed: 2,
          favoriteTree: 'attack',
          averageTier: 'Silver',
          highestTierEver: 'Gold',
          totalGamesPlayed: 14,
          totalGamesWon: 10,
          careerWinRate: 10 / 14,
          totalRewardsClaimed: const {},
          progression: const ProgressionTrend(
            seasonOverSeason: 1.0,
            winRateTrend: 0.1,
            eloTrend: 50,
            prediction: ProgressionTrendType.climbing,
            dataPointsUsed: 2,
          ),
          firstSeasonAt: DateTime(2026, 1, 1),
          lastUpdatedAt: DateTime(2026, 2, 1),
        ),
      );

      await tester.pumpWidget(
        _wrap(
          const ProgressionAnalyticsScreen(userIdOverride: 'user-1'),
          stats: stats,
        ),
      );
      await tester.pumpAndSettle();

      // バグ修正前は screen が存在しなかったため、これらは何も表示されなかった。
      expect(find.text('Gold'), findsWidgets);
      expect(find.text('Silver'), findsWidgets);
      expect(find.textContaining('上昇中'), findsOneWidget);
    });

    testWidgets('renders the tier prediction card', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const ProgressionAnalyticsScreen(userIdOverride: 'user-1'),
          stats: ProgressionStats(
            userId: 'user-1',
            currentSeason: _season(id: 's1', tier: 'Gold'),
            allSeasons: [_season(id: 's1', tier: 'Gold')],
            allTimeStats: _emptyStats('user-1').allTimeStats,
          ),
          prediction: const TierPrediction(
            currentTier: 'Gold',
            predictedTier: 'Platinum',
            confidence: 0.75,
            daysToReach: 7,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Gold → Platinum'), findsOneWidget);
      expect(find.textContaining('75%'), findsOneWidget);
    });
  });
}
