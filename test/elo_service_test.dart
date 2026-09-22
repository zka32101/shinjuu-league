import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shinjuu_league/services/elo_service.dart';

void main() {
  group('EloService.kFactorForRating (real regression guard)', () {
    // Real bug found and fixed: EloService.calculateEloChange() used to
    // default to a single flat K-factor (AppConfig.eloKFactor, 32) for
    // every player, while functions/src/elo-validator.ts already used a
    // tier-based K-factor (64/32/24/16) when actually applying Elo
    // server-side. Every Bronze-tier player (rating < 1400 - i.e. most new
    // players) saw a result_screen.dart preview roughly HALF the real
    // change the Cloud Function would apply moments later (K=32 shown vs
    // K=64 actually applied), silently "corrected" via watchUser() with no
    // explanation - directly undermining the "Elo計算は透明性高く" design
    // principle. These boundaries must exactly match ELO_TIERS in
    // functions/src/elo-validator.ts.
    const expectedTiers = [
      (rating: 400.0, kFactor: 64.0),
      (rating: 1200.0, kFactor: 64.0),
      (rating: 1399.0, kFactor: 64.0),
      (rating: 1400.0, kFactor: 32.0),
      (rating: 1799.0, kFactor: 32.0),
      (rating: 1800.0, kFactor: 24.0),
      (rating: 2199.0, kFactor: 24.0),
      (rating: 2200.0, kFactor: 16.0),
      (rating: 2999.0, kFactor: 16.0),
    ];

    for (final tier in expectedTiers) {
      test('rating ${tier.rating} resolves to K=${tier.kFactor}', () {
        expect(EloService.kFactorForRating(tier.rating), tier.kFactor);
      });
    }

    test('tier boundaries match functions/src/elo-validator.ts exactly', () {
      final source = File('functions/src/elo-validator.ts').readAsStringSync();
      // Pull each { name, minRating, maxRating, kFactor } tier entry's
      // numbers out of the ELO_TIERS array declaration and compare them
      // directly against EloService.kFactorForRating's own boundaries,
      // so this test fails the moment the two drift apart, rather than
      // only catching it via hand-copied expected values above.
      final tiersBlockStart = source.indexOf('ELO_TIERS: EloTier[] = [');
      final tiersBlockEnd = source.indexOf('];', tiersBlockStart);
      final tiersBlock = source.substring(tiersBlockStart, tiersBlockEnd);

      final entryPattern = RegExp(
        r"name:\s*'([^']+)',\s*minRating:\s*(\w+),\s*maxRating:\s*(\w+),\s*kFactor:\s*(\d+)",
      );
      final matches = entryPattern.allMatches(tiersBlock).toList();
      expect(
        matches,
        isNotEmpty,
        reason:
            'Could not parse ELO_TIERS from elo-validator.ts - has its shape changed?',
      );

      const constants = {'MIN_ELO': 400.0, 'MAX_ELO': 3000.0};

      for (final match in matches) {
        final minToken = match.group(2)!;
        final maxToken = match.group(3)!;
        final kFactor = double.parse(match.group(4)!);

        final minRating = constants[minToken] ?? double.parse(minToken);
        // Probe just inside the tier (maxRating itself belongs to the
        // NEXT tier, same as the server's `rating < tier.maxRating`).
        final maxRatingToken = constants[maxToken] ?? double.parse(maxToken);
        final probeInsideMax = maxRatingToken - 1;

        expect(
          EloService.kFactorForRating(minRating),
          kFactor,
          reason: '${match.group(1)} tier lower bound ($minRating) mismatch',
        );
        expect(
          EloService.kFactorForRating(probeInsideMax),
          kFactor,
          reason:
              '${match.group(1)} tier upper bound ($probeInsideMax) mismatch',
        );
      }
    });
  });

  group('EloService.calculateEloChange', () {
    test('auto-selects the tier K-factor when none is given', () {
      // rating 1000 -> Bronze -> K=64, equal opponent -> exactly K/2.
      final change = EloService.calculateEloChange(
        currentRating: 1000,
        opponentAvgRating: 1000,
        isWin: true,
      );
      expect(change, closeTo(32.0, 0.01));
    });

    test('an explicit kFactor still overrides the tier default', () {
      final change = EloService.calculateEloChange(
        currentRating: 1000,
        opponentAvgRating: 1000,
        isWin: true,
        kFactor: 32,
      );
      expect(change, closeTo(16.0, 0.01));
    });

    test(
      'a Gold-tier player (K=24) sees a smaller swing than a Bronze-tier player (K=64) in the same matchup shape',
      () {
        final bronzeChange = EloService.calculateEloChange(
          currentRating: 1200,
          opponentAvgRating: 1200,
          isWin: true,
        );
        final goldChange = EloService.calculateEloChange(
          currentRating: 1900,
          opponentAvgRating: 1900,
          isWin: true,
        );
        expect(goldChange, lessThan(bronzeChange));
      },
    );
  });
}
