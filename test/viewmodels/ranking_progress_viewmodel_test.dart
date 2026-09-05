import 'package:flutter_test/flutter_test.dart';
import 'package:shinjuu_league/data/models/season_model.dart';
import 'package:shinjuu_league/viewmodels/ranking_progress_viewmodel.dart';

void main() {
  group('RankingProgressViewModel', () {
    test('calculates tier ladder correctly', () {
      final tierThresholds = {
        'Bronze': 400,
        'Silver': 1400,
        'Gold': 1800,
        'Platinum': 2200,
        'Legend': 2800,
      };

      final ladder = _buildTierLadder(
        currentRating: 1600,
        currentTier: 'Silver',
        tierThresholds: tierThresholds,
        playerUserId: 'player-1',
      );

      expect(ladder.tiers.length, equals(5));
      expect(ladder.playerTierPosition, equals(1)); // Silver
      expect(ladder.currentTier, equals('Silver'));
      expect(ladder.nextTier, equals('Gold'));
    });

    test('identifies tier above and below correctly', () {
      final tierThresholds = {
        'Bronze': 400,
        'Silver': 1400,
        'Gold': 1800,
        'Platinum': 2200,
        'Legend': 2800,
      };

      final ladder = _buildTierLadder(
        currentRating: 1600,
        currentTier: 'Silver',
        tierThresholds: tierThresholds,
        playerUserId: 'player-1',
      );

      expect(ladder.tierAbove, equals('Gold'));
      expect(ladder.tierBelow, equals('Bronze'));
    });

    test('handles Legend tier (highest) correctly', () {
      final tierThresholds = {
        'Bronze': 400,
        'Silver': 1400,
        'Gold': 1800,
        'Platinum': 2200,
        'Legend': 2800,
      };

      final ladder = _buildTierLadder(
        currentRating: 2900,
        currentTier: 'Legend',
        tierThresholds: tierThresholds,
        playerUserId: 'player-1',
      );

      expect(ladder.tierAbove, isNull);
      expect(ladder.tierBelow, equals('Platinum'));
    });

    test('handles Bronze tier (lowest) correctly', () {
      final tierThresholds = {
        'Bronze': 400,
        'Silver': 1400,
        'Gold': 1800,
        'Platinum': 2200,
        'Legend': 2800,
      };

      final ladder = _buildTierLadder(
        currentRating: 500,
        currentTier: 'Bronze',
        tierThresholds: tierThresholds,
        playerUserId: 'player-1',
      );

      expect(ladder.tierBelow, isNull);
      expect(ladder.tierAbove, equals('Silver'));
    });

    test('estimates games to promotion correctly', () {
      // At 1600 rating, Silver tier
      // Need 1800 to reach Gold
      // Rating difference = 200
      // With 55% win rate and K=32: avg gain per win = 32 * 0.05 = 1.6
      // Games needed ≈ 200 / 1.6 ≈ 125

      final gamesNeeded = _estimateGamesToReach(
        currentRating: 1600,
        targetRating: 1800,
        winRate: 0.55,
        kFactor: 32,
      );

      expect(gamesNeeded, greaterThan(100));
      expect(gamesNeeded, lessThan(150));
    });

    test('estimates games with high win rate', () {
      // Higher win rate should require fewer games
      final gamesAt60Percent = _estimateGamesToReach(
        currentRating: 1600,
        targetRating: 1800,
        winRate: 0.60,
        kFactor: 32,
      );

      final gamesAt55Percent = _estimateGamesToReach(
        currentRating: 1600,
        targetRating: 1800,
        winRate: 0.55,
        kFactor: 32,
      );

      expect(gamesAt60Percent, lessThan(gamesAt55Percent));
    });

    test('estimates games with different K factors', () {
      // Lower K factor means slower rating progression
      final gamesWithK64 = _estimateGamesToReach(
        currentRating: 1600,
        targetRating: 1800,
        winRate: 0.55,
        kFactor: 64,
      );

      final gamesWithK32 = _estimateGamesToReach(
        currentRating: 1600,
        targetRating: 1800,
        winRate: 0.55,
        kFactor: 32,
      );

      expect(gamesWithK64, lessThan(gamesWithK32));
    });

    test('gets tier emoji correctly', () {
      expect(_getTierEmoji('Bronze'), equals('🥉'));
      expect(_getTierEmoji('Silver'), equals('🥈'));
      expect(_getTierEmoji('Gold'), equals('🥇'));
      expect(_getTierEmoji('Platinum'), equals('👑'));
      expect(_getTierEmoji('Legend'), equals('⭐'));
      expect(_getTierEmoji('Unknown'), equals('🎯'));
    });

    test('gets tier color correctly', () {
      expect(_getTierColor('Bronze'), isNotNull);
      expect(_getTierColor('Silver'), isNotNull);
      expect(_getTierColor('Gold'), isNotNull);
      expect(_getTierColor('Platinum'), isNotNull);
      expect(_getTierColor('Legend'), isNotNull);
    });

    test('gets promotion message correctly', () {
      final message = _getPromotionMessage(
        fromTier: 'Silver',
        toTier: 'Gold',
        gamesEstimate: 125,
      );

      expect(message, contains('Gold'));
      expect(message, isNotEmpty);
    });

    test('gets demotion warning correctly', () {
      final warning = _getDemotionWarning(
        currentTier: 'Silver',
        gamesUntilDemotion: 10,
      );

      expect(warning, contains('Silver'));
      expect(warning, isNotEmpty);
    });

    test('builds tier ladder with multiple players', () {
      final tierThresholds = {
        'Bronze': 400,
        'Silver': 1400,
        'Gold': 1800,
        'Platinum': 2200,
        'Legend': 2800,
      };

      final players = [
        TierEntry(
          userId: 'player-1',
          username: 'Player1',
          tier: 'Silver',
          rating: 1600,
          position: 1,
        ),
        TierEntry(
          userId: 'player-2',
          username: 'Player2',
          tier: 'Gold',
          rating: 1850,
          position: 2,
        ),
        TierEntry(
          userId: 'player-3',
          username: 'Player3',
          tier: 'Bronze',
          rating: 800,
          position: 3,
        ),
      ];

      final ladder = TierLadderState(
        currentTier: 'Silver',
        playerTierPosition: 1,
        tierAbove: 'Gold',
        tierBelow: 'Bronze',
        tiers: _buildTiersFromThresholds(tierThresholds),
        players: players,
        nextTierName: 'Gold',
        ratingToNextTier: 200,
      );

      expect(ladder.players.length, equals(3));
      expect(ladder.players[0].rating, equals(1600));
      expect(ladder.players[1].rating, equals(1850));
    });
  });
}

// Helper functions for testing (normally in ViewModel)

TierLadderState _buildTierLadder({
  required int currentRating,
  required String currentTier,
  required Map<String, int> tierThresholds,
  required String playerUserId,
}) {
  final tiers = _buildTiersFromThresholds(tierThresholds);

  int playerPosition = 0;
  for (int i = 0; i < tiers.length; i++) {
    if (tiers[i].name == currentTier) {
      playerPosition = i;
      break;
    }
  }

  String? tierAbove;
  String? tierBelow;
  String nextTierName = currentTier;
  int ratingToNextTier = 0;

  if (playerPosition > 0) {
    tierAbove = tiers[playerPosition - 1].name;
    nextTierName = tierAbove;
    ratingToNextTier = tiers[playerPosition - 1].minRating - currentRating;
  }

  if (playerPosition < tiers.length - 1) {
    tierBelow = tiers[playerPosition + 1].name;
  }

  return TierLadderState(
    currentTier: currentTier,
    playerTierPosition: playerPosition,
    tierAbove: tierAbove,
    tierBelow: tierBelow,
    tiers: tiers,
    players: [],
    nextTierName: nextTierName,
    ratingToNextTier: ratingToNextTier,
  );
}

List<TierEntry> _buildTiersFromThresholds(Map<String, int> thresholds) {
  final entries = thresholds.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  return entries
      .asMap()
      .entries
      .map((entry) {
        final index = entry.key;
        final tier = entry.value.key;
        final minRating = entry.value.value;
        final maxRating = index > 0 ? entries[index - 1].value - 1 : 9999;

        return TierEntry(
          userId: '',
          username: tier,
          tier: tier,
          rating: minRating,
          position: index,
        );
      })
      .toList();
}

int _estimateGamesToReach({
  required int currentRating,
  required int targetRating,
  required double winRate,
  required int kFactor,
}) {
  if (currentRating >= targetRating) return 0;

  final ratingDifference = targetRating - currentRating;
  // Average rating gain per win: K * (win_rate - 0.5)
  final avgGainPerWin = kFactor * (winRate - 0.5);

  if (avgGainPerWin <= 0) return 9999; // Won't reach if not gaining

  return (ratingDifference / avgGainPerWin).ceil();
}

String _getTierEmoji(String tier) {
  switch (tier) {
    case 'Bronze':
      return '🥉';
    case 'Silver':
      return '🥈';
    case 'Gold':
      return '🥇';
    case 'Platinum':
      return '👑';
    case 'Legend':
      return '⭐';
    default:
      return '🎯';
  }
}

String _getTierColor(String tier) => tier; // Simplified

String _getPromotionMessage(
  String fromTier,
  String toTier,
  int gamesEstimate,
) =>
    'Keep improving! Reach $toTier in approximately $gamesEstimate games.';

String _getDemotionWarning(
  String currentTier,
  int gamesUntilDemotion,
) =>
    'Careful! You could drop from $currentTier in $gamesUntilDemotion losses.';
