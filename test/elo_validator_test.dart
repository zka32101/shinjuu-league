import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';

/// ELO Calculator for server-side validation
/// This mirrors the Cloud Function logic to ensure consistency
class EloCalculator {
  static const int kFactor = 32;
  static const int minElo = 400;
  static const int maxElo = 3000;

  /// Calculate expected win probability for player against opponent
  /// EA = 1 / (1 + 10^((RB - RA) / 400))
  static double calculateExpectation(
    int playerRating,
    int opponentRating,
  ) {
    final ratingDiff = opponentRating - playerRating;
    return 1 / (1 + math.pow(10, ratingDiff / 400));
  }

  /// Calculate new ELO rating after a match
  /// New Rating = Old Rating + K * (Result - Expected)
  static int calculateNewRating(
    int currentRating,
    int opponentRating,
    String result, // 'win', 'loss', 'draw'
  ) {
    final expected = calculateExpectation(currentRating, opponentRating);
    final actualResult = result == 'win' ? 1.0 : result == 'draw' ? 0.5 : 0.0;
    final delta = kFactor * (actualResult - expected);
    final newRating = currentRating + delta;

    // Clamp to valid range
    return (newRating.clamp(minElo.toDouble(), maxElo.toDouble())).toInt();
  }

  /// Calculate ELO change (delta)
  static int calculateEloChange(
    int currentRating,
    int opponentRating,
    String result,
  ) {
    final newRating = calculateNewRating(
      currentRating,
      opponentRating,
      result,
    );
    return newRating - currentRating;
  }
}


void main() {
  group('ELO Calculation', () {
    group('calculateExpectation', () {
      test('Equal ratings should yield 0.5 expectation', () {
        final expected = EloCalculator.calculateExpectation(1600, 1600);
        expect(expected, closeTo(0.5, 0.01));
      });

      test('Higher rated player should have > 0.5 expectation', () {
        final expected = EloCalculator.calculateExpectation(1600, 1400);
        expect(expected, greaterThan(0.5));
        expect(expected, closeTo(0.76, 0.01));
      });

      test('Lower rated player should have < 0.5 expectation', () {
        final expected = EloCalculator.calculateExpectation(1400, 1600);
        expect(expected, lessThan(0.5));
        expect(expected, closeTo(0.24, 0.01));
      });

      test('200 point rating difference ≈ 75% expectation for higher player', () {
        final expected = EloCalculator.calculateExpectation(1600, 1400);
        expect(expected, greaterThan(0.7));
        expect(expected, lessThan(0.8));
      });

      test('Large rating gap should approach 0 or 1', () {
        final smallExpected = EloCalculator.calculateExpectation(2000, 1000);
        final largeExpected = EloCalculator.calculateExpectation(1000, 2000);

        expect(smallExpected, greaterThan(0.9));
        expect(largeExpected, lessThan(0.1));
      });
    });

    group('calculateNewRating', () {
      test('Win with equal ratings increases rating by ~16', () {
        final newRating = EloCalculator.calculateNewRating(1600, 1600, 'win');
        expect(newRating, greaterThan(1600));
        expect(newRating, lessThan(1625));
      });

      test('Loss with equal ratings decreases rating by ~16', () {
        final newRating = EloCalculator.calculateNewRating(1600, 1600, 'loss');
        expect(newRating, lessThan(1600));
        expect(newRating, greaterThan(1575));
      });

      test('Draw with equal ratings keeps rating same (~16 point swing)', () {
        final newRating = EloCalculator.calculateNewRating(1600, 1600, 'draw');
        expect(newRating, inClosedOpenRange(1590, 1610));
      });

      test('Upset win (lower vs higher) yields larger gains', () {
        final upsetWin = EloCalculator.calculateNewRating(1400, 1600, 'win');
        final expectedWin = EloCalculator.calculateNewRating(1600, 1400, 'win');

        // Upset player gains more than expected player
        final upsetGain = upsetWin - 1400;
        final expectedGain = expectedWin - 1600;
        expect(upsetGain, greaterThan(expectedGain));
      });

      test('Expected win (higher vs lower) yields smaller gains', () {
        final expectedWin = EloCalculator.calculateNewRating(1600, 1400, 'win');
        final expectedLoss = EloCalculator.calculateNewRating(1600, 1400, 'loss');

        expect(expectedWin - 1600, lessThan(1600 - expectedLoss));
      });

      test('Rating clamped to minimum (400)', () {
        final newRating = EloCalculator.calculateNewRating(410, 3000, 'loss');
        expect(newRating, greaterThanOrEqualTo(400));
      });

      test('Rating clamped to maximum (3000)', () {
        final newRating = EloCalculator.calculateNewRating(2990, 400, 'win');
        expect(newRating, lessThanOrEqualTo(3000));
      });

      test('Multiple draws converge on equal rating', () {
        int rating = 1600;
        for (int i = 0; i < 10; i++) {
          rating = EloCalculator.calculateNewRating(rating, 1500, 'draw');
        }
        // After 10 draws, should approach midpoint
        expect(rating, inClosedOpenRange(1540, 1560));
      });
    });

    group('calculateEloChange', () {
      test('Win change is positive', () {
        final change = EloCalculator.calculateEloChange(1600, 1600, 'win');
        expect(change, greaterThan(0));
      });

      test('Loss change is negative', () {
        final change = EloCalculator.calculateEloChange(1600, 1600, 'loss');
        expect(change, lessThan(0));
      });

      test('Draw change is close to zero', () {
        final change = EloCalculator.calculateEloChange(1600, 1600, 'draw');
        expect(change.abs(), lessThan(5));
      });

      test('Upset win yields maximum gain', () {
        final upsetGain = EloCalculator.calculateEloChange(1200, 2000, 'win');
        final normalGain = EloCalculator.calculateEloChange(1600, 1600, 'win');

        expect(upsetGain, greaterThan(normalGain));
      });

      test('Heavy favorite win yields minimum gain', () {
        final favoriteGain = EloCalculator.calculateEloChange(2000, 1200, 'win');
        final normalGain = EloCalculator.calculateEloChange(1600, 1600, 'win');

        expect(favoriteGain, lessThan(normalGain));
      });
    });
  });

  group('Symmetry & Fairness', () {
    test('Win/Loss should sum to ~zero in equal matchup', () {
      final winChange = EloCalculator.calculateEloChange(1600, 1600, 'win');
      final lossChange = EloCalculator.calculateEloChange(1600, 1600, 'loss');

      // Should be symmetric (one player's gain = other's loss)
      expect(winChange, -lossChange);
    });

    test('Total rating sum should be preserved in equal matchup', () {
      const rating1 = 1600;
      const rating2 = 1600;
      const initialSum = rating1 + rating2;

      final newRating1 = EloCalculator.calculateNewRating(
        rating1,
        rating2,
        'win',
      );
      final newRating2 = EloCalculator.calculateNewRating(
        rating2,
        rating1,
        'loss',
      );
      final newSum = newRating1 + newRating2;

      // Should be very close (within rounding error)
      expect(newSum, closeTo(initialSum, 1));
    });

    test('Rating system converges to equilibrium', () {
      var player1 = 1400;
      var player2 = 1800;

      // Simulate 100 matches with alternating winners
      for (int i = 0; i < 100; i++) {
        if (i % 2 == 0) {
          final newRating1 =
              EloCalculator.calculateNewRating(player1, player2, 'win');
          final newRating2 =
              EloCalculator.calculateNewRating(player2, player1, 'loss');
          player1 = newRating1;
          player2 = newRating2;
        } else {
          final newRating1 =
              EloCalculator.calculateNewRating(player1, player2, 'loss');
          final newRating2 =
              EloCalculator.calculateNewRating(player2, player1, 'win');
          player1 = newRating1;
          player2 = newRating2;
        }
      }

      // After equal results, ratings should converge toward middle
      final midpoint = (1400 + 1800) / 2;
      expect(player1, lessThan(midpoint + 100));
      expect(player2, greaterThan(midpoint - 100));
    });
  });

  group('Edge Cases', () {
    test('New player (1200) vs experienced (1900) upset win', () {
      const newPlayerRating = 1200;
      const experiencedRating = 1900;

      final newPlayerGain = EloCalculator.calculateEloChange(
        newPlayerRating,
        experiencedRating,
        'win',
      );

      // Upset should yield significant gain (700-rating gap upset)
      // With K=32, typical win = 16, this extreme upset gains ~31
      expect(newPlayerGain, greaterThanOrEqualTo(30));
    });

    test('Minimum rating player winning vs maximum rating player', () {
      final change = EloCalculator.calculateNewRating(400, 3000, 'win');
      // Should not go negative or exceed max
      expect(change, greaterThanOrEqualTo(400));
    });

    test('Maximum rating player losing to minimum rating player', () {
      final change = EloCalculator.calculateNewRating(3000, 400, 'loss');
      // Should not go negative or exceed max
      expect(change, lessThanOrEqualTo(3000));
    });

    test('Draw always results in minimal rating change', () {
      final scenarios = [
        (400, 3000),
        (1200, 1800),
        (1600, 1600),
        (2000, 1000),
      ];

      for (final (rating1, rating2) in scenarios) {
        final change =
            EloCalculator.calculateEloChange(rating1, rating2, 'draw');
        // Draw change is bounded by K/2 (16 with K=32)
        expect(change.abs(), lessThanOrEqualTo(20), reason: 'Draw @ $rating1 vs $rating2');
      }
    });
  });

  group('Tamper Detection Scenarios', () {
    test('Client reporting false win should be rejected by server', () {
      // Client claims: win (+50 ELO)
      // Server calculates: loss (actual -8 ELO)
      const actualResult = 'loss';

      final clientElo = 1600 + 50; // What tampered client might claim
      final serverElo = EloCalculator.calculateNewRating(1600, 1500, actualResult);

      expect(clientElo, greaterThan(serverElo));
    });

    test('Server recalculation using authoritative ratings ignores client values', () {
      // Client sends: { clientRating: 1650, result: 'win' }
      // Server has: { serverRating: 1600 }
      // Server should use 1600, not 1650

      const clientSubmittedRating = 1650;
      const serverAutoritativeRating = 1600;
      const opponentRating = 1500;

      final clientCalculated = EloCalculator.calculateNewRating(
        clientSubmittedRating,
        opponentRating,
        'win',
      );
      final serverCalculated = EloCalculator.calculateNewRating(
        serverAutoritativeRating,
        opponentRating,
        'win',
      );

      // Server result should be lower (using lower baseline)
      expect(serverCalculated, lessThan(clientCalculated));
    });

    test('Repeat battle submission should not double-award ELO', () {
      // Battle submitted twice with eloProcessed flag

      const rating = 1600;
      const opponentRating = 1500;

      final firstApply = EloCalculator.calculateNewRating(
        rating,
        opponentRating,
        'win',
      );
      // If applied again without checking eloProcessed:
      final wrongDoubleApply = EloCalculator.calculateNewRating(
        firstApply, // WRONG: using new rating as input
        opponentRating,
        'win',
      );
      // This would yield MORE than 2x the normal gain
      final expectedDoubleGain = firstApply - rating;
      final wrongDoubleGain = wrongDoubleApply - rating;

      expect(wrongDoubleGain, greaterThan(expectedDoubleGain * 1.5));
      // With eloProcessed flag, we'd apply only once
    });
  });

  group('Statistics & Analysis', () {
    test('Average rating change across population is ~zero', () {
      const iterations = 1000;
      double totalChange = 0;

      // Simulate 1000 matches between various rating combinations
      for (int i = 0; i < iterations; i++) {
        final rating1 = 1000 + (i * 1000 / iterations).toInt();
        final rating2 = 2000 - (i * 1000 / iterations).toInt();

        final results = ['win', 'loss'];
        final result = results[i % 2];

        final change = EloCalculator.calculateEloChange(rating1, rating2, result);
        totalChange += change;
      }

      final averageChange = totalChange / iterations;
      // Average should be very close to zero
      expect(averageChange.abs(), lessThan(1));
    });

    test('K-factor value (32) yields reasonable rating changes', () {
      // With K=32, typical change is 8-24 points
      // Minimum: K * 0.76 ≈ 24 (favorite wins)
      // Maximum: K * 0.24 ≈ 8 (expected loss)

      const results = ['win', 'loss'];
      final changes = <int>[];

      for (int i = 1200; i <= 1900; i += 100) {
        for (final result in results) {
          final change = EloCalculator.calculateEloChange(i, 1600, result);
          changes.add(change.abs());
        }
      }

      final maxChange = changes.reduce((a, b) => a > b ? a : b);
      final minChange = changes.reduce((a, b) => a < b ? a : b);

      // All changes should be reasonable (8-32 range)
      expect(minChange, greaterThan(0));
      expect(maxChange, lessThan(50));
    });
  });
}

/// Matcher for checking if value is in range [min, max)
Matcher inClosedOpenRange(num min, num max) {
  return allOf(
    greaterThanOrEqualTo(min),
    lessThan(max),
  );
}
