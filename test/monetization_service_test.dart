import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shinjuu_league/config/feature_flags.dart';
import 'package:shinjuu_league/services/monetization_service.dart';
import 'package:shinjuu_league/services/remote_config_service.dart';

void main() {
  setUpAll(() async {
    // Initialize Firebase for tests
    await Firebase.initializeApp();
    // Initialize RemoteConfig
    await RemoteConfigService().init();
  });

  group('MonetizationService', () {
    late MonetizationService monetization;

    setUp(() {
      monetization = MonetizationService();
    });

    group('Price Configuration', () {
      test('getBattlePassPriceYen returns valid price', () {
        final price = monetization.getBattlePassPriceYen();
        expect(price, greaterThan(0));
        expect(price, isA<int>());
      });

      test('getSkinGachaPriceYen returns valid price', () {
        final price = monetization.getSkinGachaPriceYen();
        expect(price, greaterThan(0));
        expect(price, isA<int>());
      });

      test('getBattlePassDurationDays returns valid duration', () {
        final duration = monetization.getBattlePassDurationDays();
        expect(duration, greaterThan(0));
        expect(duration, lessThanOrEqualTo(90)); // Reasonable max: 3 months
      });

      test('getSkinGachaCeiling returns valid ceiling', () {
        final ceiling = monetization.getSkinGachaCeiling();
        expect(ceiling, greaterThan(0));
        expect(ceiling, lessThanOrEqualTo(500)); // Reasonable max
      });
    });

    group('Feature Flags', () {
      test('isEnabled reflects RemoteConfig setting', () {
        final enabled = monetization.isEnabled;
        expect(enabled, isA<bool>());
      });
    });

    group('ABTest Scenarios', () {
      test('Price variations are respected', () {
        // Simulate ABtest: some users see ¥300, others see ¥500
        final price1 = monetization.getSkinGachaPriceYen();
        final price2 = monetization.getSkinGachaPriceYen();

        // Price should be consistent within a session
        expect(price1, equals(price2));
        expect([300, 500], contains(price1));
      });

      test('Battle pass duration can vary per ABtest', () {
        final duration = monetization.getBattlePassDurationDays();
        expect([30, 60, 90], contains(duration));
      });

      test('Gacha ceiling can vary for ABtest', () {
        final ceiling = monetization.getSkinGachaCeiling();
        expect([50, 100, 150], contains(ceiling));
      });
    });

    group('Debug utilities', () {
      test('debugDumpMonetization returns complete config', () {
        final config = monetization.debugDumpMonetization();

        expect(config, containsPair('enabled', isA<bool>()));
        expect(config, containsPair('battlepass_price_yen', isA<int>()));
        expect(config, containsPair('battlepass_duration_days', isA<int>()));
        expect(config, containsPair('skin_gacha_price_yen', isA<int>()));
        expect(config, containsPair('skin_gacha_ceiling', isA<int>()));
      });
    });
  });

  group('FeatureFlags', () {
    group('ABTest thresholds', () {
      test('getAhaMomentThreshold is valid', () {
        final threshold = FeatureFlags.getAhaMomentThreshold();
        expect(threshold, greaterThan(0));
        expect(threshold, lessThanOrEqualTo(5)); // Reasonable max
      });

      test('getMatchmakingTimeout is valid', () {
        final timeout = FeatureFlags.getMatchmakingTimeout();
        expect(timeout, greaterThan(0));
        expect(timeout, lessThanOrEqualTo(60)); // Max 60 seconds
      });

      test('getMatchmakingEloDiff is valid', () {
        final diff = FeatureFlags.getMatchmakingEloDiff();
        expect(diff, greaterThan(0));
        expect(diff, lessThanOrEqualTo(500)); // Reasonable max
      });
    });

    group('Ranked mode threshold', () {
      test('getRankedUnlockLevel is valid', () {
        final level = FeatureFlags.getRankedUnlockLevel();
        expect(level, greaterThan(0));
        expect(level, lessThanOrEqualTo(50)); // Reasonable max
      });

      test('getRankedEntryFee is non-negative', () {
        final fee = FeatureFlags.getRankedEntryFee();
        expect(fee, greaterThanOrEqualTo(0));
      });
    });

    group('Evolution difficulty', () {
      test('Evolution boosts are valid multipliers', () {
        final atkBoost = FeatureFlags.getEvolutionAttackMultiplier();
        final defBoost = FeatureFlags.getEvolutionDefenseMultiplier();
        final mobBoost = FeatureFlags.getEvolutionMobilityMultiplier();

        expect(atkBoost, greaterThan(1.0));
        expect(atkBoost, lessThan(2.0));

        expect(defBoost, greaterThan(1.0));
        expect(defBoost, lessThan(2.0));

        expect(mobBoost, greaterThan(1.0));
        expect(mobBoost, lessThan(2.0));
      });
    });

    group('Elo calculation', () {
      test('Elo K factor is valid', () {
        final kFactor = FeatureFlags.getEloKFactor();
        expect(kFactor, greaterThan(0.0));
        expect(kFactor, lessThan(100.0));
      });

      test('High rating K factor is lower than default', () {
        final defaultK = FeatureFlags.getEloKFactor();
        final highK = FeatureFlags.getEloKFactorHighRating();

        expect(highK, lessThanOrEqualTo(defaultK));
      });

      test('High rating threshold is reasonable', () {
        final threshold = FeatureFlags.getEloHighRatingThreshold();
        expect(threshold, greaterThan(1000.0)); // Above baseline
        expect(threshold, lessThan(5000.0)); // Reasonable max
      });
    });

    group('Feature flags', () {
      test('Feature flags return boolean values', () {
        expect(FeatureFlags.isRankedModeEnabled(), isA<bool>());
        expect(FeatureFlags.isSocialFeaturesEnabled(), isA<bool>());
        expect(FeatureFlags.isBattleReplayEnabled(), isA<bool>());
        expect(FeatureFlags.isMonetizationEnabled(), isA<bool>());
        expect(FeatureFlags.isMaintenanceModeEnabled(), isA<bool>());
      });
    });

    group('Debug utilities', () {
      test('debugDumpFlags returns complete mapping', () {
        final flags = FeatureFlags.debugDumpFlags();

        expect(flags, containsPair('aha_moment_threshold', isA<int>()));
        expect(flags, containsPair('matchmaking_timeout', isA<int>()));
        expect(flags, containsPair('ranked_enabled', isA<bool>()));
        expect(flags, containsPair('maintenance_mode', isA<bool>()));
      });
    });
  });
}
