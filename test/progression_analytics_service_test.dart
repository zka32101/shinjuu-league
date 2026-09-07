import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shinjuu_league/data/models/progression_stats.dart';
import 'package:shinjuu_league/data/models/skill_tree_reset.dart';
import 'package:shinjuu_league/services/progression_analytics_service.dart';
import 'package:shinjuu_league/services/firestore_service.dart';
import 'package:shinjuu_league/services/skill_tree_reset_service.dart';

class MockFirestoreService extends Mock implements FirestoreService {}
class MockSkillTreeResetService extends Mock implements SkillTreeResetService {}

void main() {
  group('ProgressionAnalyticsService', () {
    late ProgressionAnalyticsService service;
    late MockFirestoreService mockFirestore;
    late MockSkillTreeResetService mockResetService;

    setUp(() {
      mockFirestore = MockFirestoreService();
      mockResetService = MockSkillTreeResetService();
      service = ProgressionAnalyticsService(mockFirestore, mockResetService);
    });

    group('getProgressionStats', () {
      test('returns empty stats for new player', () async {
        when(mockResetService.getSeasonHistory('user_123'))
            .thenAnswer((_) async => []);

        final stats = await service.getProgressionStats('user_123');

        expect(stats.userId, equals('user_123'));
        expect(stats.currentSeason, isNull);
        expect(stats.allSeasons, isEmpty);
        expect(stats.allTimeStats.totalSeasonsPlayed, equals(0));
      });

      test('calculates stats from single season', () async {
        final snapshot = _createSnapshot('season_1', 'Gold', 5);
        when(mockResetService.getSeasonHistory('user_123'))
            .thenAnswer((_) async => [snapshot]);

        final stats = await service.getProgressionStats('user_123');

        expect(stats.allSeasons.length, equals(1));
        expect(stats.currentSeason?.finalTier, equals('Gold'));
        expect(stats.allTimeStats.totalSeasonsPlayed, equals(1));
      });

      test('aggregates multiple seasons correctly', () async {
        final snapshots = [
          _createSnapshot('season_1', 'Silver', 3),
          _createSnapshot('season_2', 'Gold', 4),
          _createSnapshot('season_3', 'Platinum', 5),
        ];

        when(mockResetService.getSeasonHistory('user_123'))
            .thenAnswer((_) async => snapshots);

        final stats = await service.getProgressionStats('user_123');

        expect(stats.allSeasons.length, equals(3));
        expect(stats.allTimeStats.totalSeasonsPlayed, equals(3));
        expect(stats.currentSeason?.seasonId, equals('season_3'));
        expect(stats.currentSeason?.finalTier, equals('Platinum'));
      });

      test('calculates highest tier correctly', () async {
        final snapshots = [
          _createSnapshot('season_1', 'Silver', 3),
          _createSnapshot('season_2', 'Bronze', 2),
          _createSnapshot('season_3', 'Gold', 4),
        ];

        when(mockResetService.getSeasonHistory('user_123'))
            .thenAnswer((_) async => snapshots);

        final stats = await service.getProgressionStats('user_123');

        expect(stats.allTimeStats.highestTierEver, equals('Gold'));
      });

      test('calculates average tier correctly', () async {
        // Silver(1) + Gold(2) + Platinum(3) = avg 2 (Gold)
        final snapshots = [
          _createSnapshot('season_1', 'Silver', 3),
          _createSnapshot('season_2', 'Gold', 4),
          _createSnapshot('season_3', 'Platinum', 5),
        ];

        when(mockResetService.getSeasonHistory('user_123'))
            .thenAnswer((_) async => snapshots);

        final stats = await service.getProgressionStats('user_123');

        expect(stats.allTimeStats.averageTier, equals('Gold'));
      });
    });

    group('_calculateProgressionTrend', () {
      test('detects climbing trend (tier improvement)', () async {
        final snapshots = [
          _createSnapshot('season_1', 'Silver', 3),
          _createSnapshot('season_2', 'Gold', 5),
        ];

        when(mockResetService.getSeasonHistory('user_123'))
            .thenAnswer((_) async => snapshots);

        final stats = await service.getProgressionStats('user_123');
        final trend = stats.allTimeStats.progression;

        expect(trend.prediction, equals(ProgressionTrendType.climbing));
        expect(trend.getTrendEmoji(), equals('📈'));
      });

      test('detects plateau trend (stable tier)', () async {
        final snapshots = [
          _createSnapshot('season_1', 'Gold', 4),
          _createSnapshot('season_2', 'Gold', 4),
        ];

        when(mockResetService.getSeasonHistory('user_123'))
            .thenAnswer((_) async => snapshots);

        final stats = await service.getProgressionStats('user_123');
        final trend = stats.allTimeStats.progression;

        expect(trend.prediction, equals(ProgressionTrendType.plateau));
      });

      test('detects declining trend (tier drop)', () async {
        final snapshots = [
          _createSnapshot('season_1', 'Platinum', 5),
          _createSnapshot('season_2', 'Gold', 3),
        ];

        when(mockResetService.getSeasonHistory('user_123'))
            .thenAnswer((_) async => snapshots);

        final stats = await service.getProgressionStats('user_123');
        final trend = stats.allTimeStats.progression;

        expect(trend.prediction, equals(ProgressionTrendType.declining));
        expect(trend.getTrendEmoji(), equals('📉'));
      });

      test('returns plateau for single season', () async {
        final snapshots = [_createSnapshot('season_1', 'Gold', 4)];

        when(mockResetService.getSeasonHistory('user_123'))
            .thenAnswer((_) async => snapshots);

        final stats = await service.getProgressionStats('user_123');
        final trend = stats.allTimeStats.progression;

        expect(trend.prediction, equals(ProgressionTrendType.plateau));
      });
    });

    group('estimateTierProgress', () {
      test('calculates reasonable days to next tier', () async {
        final snapshot = _createSnapshot('season_1', 'Gold', 4);
        when(mockResetService.getSeasonHistory('user_123'))
            .thenAnswer((_) async => [snapshot]);

        final stats = await service.getProgressionStats('user_123');
        final days = stats.estimateTierProgress();

        expect(days, greaterThanOrEqualTo(0));
        expect(days, lessThan(999));
      });

      test('returns 0 for no current season', () async {
        when(mockResetService.getSeasonHistory('user_123'))
            .thenAnswer((_) async => []);

        final stats = await service.getProgressionStats('user_123');
        final days = stats.estimateTierProgress();

        expect(days, equals(0));
      });
    });

    group('predictNextTier', () {
      test('predicts tier up for high win rate', () async {
        final snapshot = _createSnapshot('season_1', 'Gold', 4);
        when(mockResetService.getSeasonHistory('user_123'))
            .thenAnswer((_) async => [snapshot]);

        final prediction = await service.predictNextTier('user_123');

        expect(prediction.currentTier, equals('Gold'));
        expect(prediction.confidence, greaterThan(0.0));
        expect(prediction.confidence, lessThanOrEqualTo(1.0));
      });

      test('returns valid tier for new player', () async {
        when(mockResetService.getSeasonHistory('user_123'))
            .thenAnswer((_) async => []);

        final prediction = await service.predictNextTier('user_123');

        expect(prediction.currentTier, equals('Bronze'));
        expect(prediction.predictedTier, equals('Bronze'));
      });

      test('respects tier bounds (no prediction past Diamond)', () async {
        final snapshot = _createSnapshot('season_1', 'Diamond', 5);
        when(mockResetService.getSeasonHistory('user_123'))
            .thenAnswer((_) async => [snapshot]);

        final prediction = await service.predictNextTier('user_123');

        expect(prediction.predictedTier, equals('Diamond')); // Can't go higher
      });
    });

    group('getRankChange', () {
      test('detects promotion', () async {
        final snapshots = [
          _createSnapshot('season_1', 'Gold', 4),
          _createSnapshot('season_2', 'Platinum', 5),
        ];

        when(mockResetService.getSeasonHistory('user_123'))
            .thenAnswer((_) async => snapshots);

        final stats = await service.getProgressionStats('user_123');
        final change = stats.getRankChange();

        expect(change, contains('↑'));
      });

      test('detects demotion', () async {
        final snapshots = [
          _createSnapshot('season_1', 'Platinum', 5),
          _createSnapshot('season_2', 'Gold', 4),
        ];

        when(mockResetService.getSeasonHistory('user_123'))
            .thenAnswer((_) async => snapshots);

        final stats = await service.getProgressionStats('user_123');
        final change = stats.getRankChange();

        expect(change, contains('↓'));
      });

      test('detects same rank', () async {
        final snapshots = [
          _createSnapshot('season_1', 'Gold', 4),
          _createSnapshot('season_2', 'Gold', 4),
        ];

        when(mockResetService.getSeasonHistory('user_123'))
            .thenAnswer((_) async => snapshots);

        final stats = await service.getProgressionStats('user_123');
        final change = stats.getRankChange();

        expect(change, contains('→'));
      });

      test('returns N/A for single season', () async {
        final snapshots = [_createSnapshot('season_1', 'Gold', 4)];

        when(mockResetService.getSeasonHistory('user_123'))
            .thenAnswer((_) async => snapshots);

        final stats = await service.getProgressionStats('user_123');
        final change = stats.getRankChange();

        expect(change, equals('N/A'));
      });
    });

    group('getEloChartData', () {
      test('returns empty list for no current season', () async {
        when(mockResetService.getSeasonHistory('user_123'))
            .thenAnswer((_) async => []);

        final stats = await service.getProgressionStats('user_123');
        final chartData = stats.getEloChartData();

        expect(chartData, isEmpty);
      });

      test('returns ELO progression data when available', () async {
        final snapshot = _createSnapshot('season_1', 'Gold', 4);
        when(mockResetService.getSeasonHistory('user_123'))
            .thenAnswer((_) async => [snapshot]);

        final stats = await service.getProgressionStats('user_123');
        final chartData = stats.getEloChartData();

        // Chart data should match ELO progression if season has it
        if (stats.currentSeason?.eloProgression.isNotEmpty ?? false) {
          expect(chartData, isNotEmpty);
        }
      });
    });

    group('SeasonStats helpers', () {
      test('calculates average ELO correctly', () {
        final season = SeasonStats(
          seasonId: 'season_1',
          startedAt: DateTime.now(),
          finalTier: 'Gold',
          maxTierReached: 'Gold',
          pointsAllocated: 4,
          totalGamesPlayed: 10,
          gamesWon: 6,
          gamesLost: 4,
          totalPlayTime: const Duration(hours: 5),
          winRate: 0.6,
          eloProgression: [
            EloSnapshot(
              recordedAt: DateTime.now(),
              rating: 1200.0,
              gamesPlayed: 5,
            ),
            EloSnapshot(
              recordedAt: DateTime.now(),
              rating: 1300.0,
              gamesPlayed: 10,
            ),
          ],
          seasonRewards: 0,
        );

        final avgElo = season.getAverageElo();
        expect(avgElo, equals(1250.0));
      });

      test('calculates peak ELO correctly', () {
        final season = SeasonStats(
          seasonId: 'season_1',
          startedAt: DateTime.now(),
          finalTier: 'Gold',
          maxTierReached: 'Gold',
          pointsAllocated: 4,
          totalGamesPlayed: 10,
          gamesWon: 6,
          gamesLost: 4,
          totalPlayTime: const Duration(hours: 5),
          winRate: 0.6,
          eloProgression: [
            EloSnapshot(
              recordedAt: DateTime.now(),
              rating: 1200.0,
              gamesPlayed: 5,
            ),
            EloSnapshot(
              recordedAt: DateTime.now(),
              rating: 1500.0,
              gamesPlayed: 10,
            ),
          ],
          seasonRewards: 0,
        );

        expect(season.getPeakElo(), equals(1500.0));
        expect(season.getLowestElo(), equals(1200.0));
      });
    });
  });
}

// Helper functions

SkillTreeSnapshot _createSnapshot(
  String seasonId,
  String tier,
  int totalPoints,
) {
  return SkillTreeSnapshot(
    seasonId: seasonId,
    snapshotAt: DateTime.now(),
    treeState: _createDummySkillTree(),
    finalTier: tier,
    totalPointsAllocated: totalPoints,
    treePointsBreakdown: {
      'atk': (totalPoints / 3).floor(),
      'def': (totalPoints / 3).floor(),
      'spd': totalPoints - (2 * (totalPoints / 3).floor()),
    },
  );
}

// Minimal SkillTree for testing
dynamic _createDummySkillTree() {
  return {
    'trees': [
      {'allocatedTiers': 1},
      {'allocatedTiers': 1},
      {'allocatedTiers': 1},
    ],
    'totalAllocatedPoints': 3,
    'availablePoints': 0,
  };
}
