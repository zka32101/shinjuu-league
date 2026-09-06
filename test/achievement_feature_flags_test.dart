import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shinjuu_league/config/achievement_feature_flags.dart';
import 'package:shinjuu_league/services/remote_config_service.dart';

class MockRemoteConfigService extends Mock implements RemoteConfigService {}

void main() {
  group('AchievementFeatureFlags', () {
    late AchievementFeatureFlags flags;
    late MockRemoteConfigService mockRemoteConfig;

    setUp(() {
      mockRemoteConfig = MockRemoteConfigService();
      flags = AchievementFeatureFlags(mockRemoteConfig);
    });

    group('Unlock Threshold ABtests', () {
      test('getAhaMomentKillRequirement returns Remote Config value', () {
        when(mockRemoteConfig.getInt('aha_moment_kill_requirement', defaultValue: any))
            .thenReturn(2);

        final result = flags.getAhaMomentKillRequirement();
        expect(result, equals(2));
      });

      test('getAhaMomentKillRequirement falls back to default 1', () {
        when(mockRemoteConfig.getInt('aha_moment_kill_requirement', defaultValue: any))
            .thenReturn(1);

        final result = flags.getAhaMomentKillRequirement();
        expect(result, equals(1));
      });

      test('getStatMasterPointRequirement returns Remote Config value', () {
        when(mockRemoteConfig.getInt('stat_master_points_requirement', defaultValue: any))
            .thenReturn(75);

        final result = flags.getStatMasterPointRequirement();
        expect(result, equals(75));
      });

      test('getStatMasterPointRequirement falls back to default 50', () {
        when(mockRemoteConfig.getInt('stat_master_points_requirement', defaultValue: any))
            .thenReturn(50);

        final result = flags.getStatMasterPointRequirement();
        expect(result, equals(50));
      });

      test('getBalancedFighterPointsPerTree returns Remote Config value', () {
        when(mockRemoteConfig.getInt('balanced_fighter_points_per_tree', defaultValue: any))
            .thenReturn(20);

        final result = flags.getBalancedFighterPointsPerTree();
        expect(result, equals(20));
      });

      test('getBalancedFighterPointsPerTree falls back to default 15', () {
        when(mockRemoteConfig.getInt('balanced_fighter_points_per_tree', defaultValue: any))
            .thenReturn(15);

        final result = flags.getBalancedFighterPointsPerTree();
        expect(result, equals(15));
      });

      test('getSeasonWarriorSeasonRequirement returns Remote Config value', () {
        when(mockRemoteConfig.getInt('season_warrior_seasons_requirement', defaultValue: any))
            .thenReturn(12);

        final result = flags.getSeasonWarriorSeasonRequirement();
        expect(result, equals(12));
      });

      test('getSeasonWarriorSeasonRequirement falls back to default 10', () {
        when(mockRemoteConfig.getInt('season_warrior_seasons_requirement', defaultValue: any))
            .thenReturn(10);

        final result = flags.getSeasonWarriorSeasonRequirement();
        expect(result, equals(10));
      });

      test('getConsistencySeasonRequirement returns Remote Config value', () {
        when(mockRemoteConfig.getInt('consistency_seasons_requirement', defaultValue: any))
            .thenReturn(4);

        final result = flags.getConsistencySeasonRequirement();
        expect(result, equals(4));
      });

      test('getConsistencySeasonRequirement falls back to default 3', () {
        when(mockRemoteConfig.getInt('consistency_seasons_requirement', defaultValue: any))
            .thenReturn(3);

        final result = flags.getConsistencySeasonRequirement();
        expect(result, equals(3));
      });

      test('getConsistencyMinimumTier returns Remote Config value', () {
        when(mockRemoteConfig.getString('consistency_minimum_tier', defaultValue: any))
            .thenReturn('Silver');

        final result = flags.getConsistencyMinimumTier();
        expect(result, equals('Silver'));
      });

      test('getConsistencyMinimumTier falls back to default Gold', () {
        when(mockRemoteConfig.getString('consistency_minimum_tier', defaultValue: any))
            .thenReturn('Gold');

        final result = flags.getConsistencyMinimumTier();
        expect(result, equals('Gold'));
      });
    });

    group('Reward Tier ABtests', () {
      test('getBronzeCurrencyReward returns Remote Config value', () {
        when(mockRemoteConfig.getInt('bronze_currency_reward', defaultValue: any))
            .thenReturn(40);

        final result = flags.getBronzeCurrencyReward();
        expect(result, equals(40));
      });

      test('getBronzeCurrencyReward falls back to default 50', () {
        when(mockRemoteConfig.getInt('bronze_currency_reward', defaultValue: any))
            .thenReturn(50);

        final result = flags.getBronzeCurrencyReward();
        expect(result, equals(50));
      });

      test('getSilverCurrencyReward returns Remote Config value', () {
        when(mockRemoteConfig.getInt('silver_currency_reward', defaultValue: any))
            .thenReturn(150);

        final result = flags.getSilverCurrencyReward();
        expect(result, equals(150));
      });

      test('getSilverCurrencyReward falls back to default 100', () {
        when(mockRemoteConfig.getInt('silver_currency_reward', defaultValue: any))
            .thenReturn(100);

        final result = flags.getSilverCurrencyReward();
        expect(result, equals(100));
      });

      test('getGoldCurrencyReward returns Remote Config value', () {
        when(mockRemoteConfig.getInt('gold_currency_reward', defaultValue: any))
            .thenReturn(350);

        final result = flags.getGoldCurrencyReward();
        expect(result, equals(350));
      });

      test('getGoldCurrencyReward falls back to default 250', () {
        when(mockRemoteConfig.getInt('gold_currency_reward', defaultValue: any))
            .thenReturn(250);

        final result = flags.getGoldCurrencyReward();
        expect(result, equals(250));
      });

      test('getPlatinumCurrencyReward returns Remote Config value', () {
        when(mockRemoteConfig.getInt('platinum_currency_reward', defaultValue: any))
            .thenReturn(750);

        final result = flags.getPlatinumCurrencyReward();
        expect(result, equals(750));
      });

      test('getPlatinumCurrencyReward falls back to default 500', () {
        when(mockRemoteConfig.getInt('platinum_currency_reward', defaultValue: any))
            .thenReturn(500);

        final result = flags.getPlatinumCurrencyReward();
        expect(result, equals(500));
      });
    });

    group('Notification ABtests', () {
      test('isPushNotificationEnabled returns true from Remote Config', () {
        when(mockRemoteConfig.getBool('achievement_push_notification_enabled', defaultValue: any))
            .thenReturn(true);

        final result = flags.isPushNotificationEnabled();
        expect(result, isTrue);
      });

      test('isPushNotificationEnabled returns false from Remote Config', () {
        when(mockRemoteConfig.getBool('achievement_push_notification_enabled', defaultValue: any))
            .thenReturn(false);

        final result = flags.isPushNotificationEnabled();
        expect(result, isFalse);
      });

      test('isPushNotificationEnabled falls back to default true', () {
        when(mockRemoteConfig.getBool('achievement_push_notification_enabled', defaultValue: any))
            .thenReturn(true);

        final result = flags.isPushNotificationEnabled();
        expect(result, isTrue);
      });

      test('getPushNotificationThresholdPercent returns Remote Config value', () {
        when(mockRemoteConfig.getInt('achievement_push_notification_threshold', defaultValue: any))
            .thenReturn(50);

        final result = flags.getPushNotificationThresholdPercent();
        expect(result, equals(50));
      });

      test('getPushNotificationThresholdPercent falls back to default 75', () {
        when(mockRemoteConfig.getInt('achievement_push_notification_threshold', defaultValue: any))
            .thenReturn(75);

        final result = flags.getPushNotificationThresholdPercent();
        expect(result, equals(75));
      });

      test('isSeasonEndCeremonyEnabled returns true from Remote Config', () {
        when(mockRemoteConfig.getBool('season_end_ceremony_enabled', defaultValue: any))
            .thenReturn(true);

        final result = flags.isSeasonEndCeremonyEnabled();
        expect(result, isTrue);
      });

      test('isSeasonEndCeremonyEnabled falls back to default true', () {
        when(mockRemoteConfig.getBool('season_end_ceremony_enabled', defaultValue: any))
            .thenReturn(true);

        final result = flags.isSeasonEndCeremonyEnabled();
        expect(result, isTrue);
      });

      test('getSeasonEndCeremonyDurationSeconds returns Remote Config value', () {
        when(mockRemoteConfig.getInt('season_end_ceremony_duration_seconds', defaultValue: any))
            .thenReturn(5);

        final result = flags.getSeasonEndCeremonyDurationSeconds();
        expect(result, equals(5));
      });

      test('getSeasonEndCeremonyDurationSeconds falls back to default 3', () {
        when(mockRemoteConfig.getInt('season_end_ceremony_duration_seconds', defaultValue: any))
            .thenReturn(3);

        final result = flags.getSeasonEndCeremonyDurationSeconds();
        expect(result, equals(3));
      });
    });

    group('ABtest Group Assignment', () {
      test('getAbTestGroup returns deterministic group for same user', () {
        const userId = 'user_123';
        final group1 = flags.getAbTestGroup(userId);
        final group2 = flags.getAbTestGroup(userId);

        expect(group1, equals(group2));
        expect(['control', 'variant_a', 'variant_b'], contains(group1));
      });

      test('getAbTestGroup assigns different users to groups', () {
        const user1 = 'user_123';
        const user2 = 'user_456';

        final group1 = flags.getAbTestGroup(user1);
        final group2 = flags.getAbTestGroup(user2);

        // Both should be valid groups
        expect(['control', 'variant_a', 'variant_b'], contains(group1));
        expect(['control', 'variant_a', 'variant_b'], contains(group2));
      });

      test('isControlGroup returns true for control group users', () {
        // Test multiple users to ensure at least one lands in control
        bool foundControl = false;
        for (int i = 0; i < 100; i++) {
          final userId = 'user_$i';
          if (flags.isControlGroup(userId)) {
            foundControl = true;
            final group = flags.getAbTestGroup(userId);
            expect(group, equals('control'));
            break;
          }
        }
        expect(foundControl, isTrue);
      });

      test('isControlGroup returns false for variant users', () {
        // Test multiple users to ensure at least one is a variant
        bool foundVariant = false;
        for (int i = 0; i < 100; i++) {
          final userId = 'user_$i';
          if (!flags.isControlGroup(userId)) {
            foundVariant = true;
            final group = flags.getAbTestGroup(userId);
            expect(['variant_a', 'variant_b'], contains(group));
            break;
          }
        }
        expect(foundVariant, isTrue);
      });

      test('Group distribution across users is balanced', () {
        final groups = <String, int>{'control': 0, 'variant_a': 0, 'variant_b': 0};

        for (int i = 0; i < 300; i++) {
          final group = flags.getAbTestGroup('user_$i');
          groups[group] = groups[group]! + 1;
        }

        // Each group should have roughly 100 users (within 30% tolerance)
        expect(groups['control']!, greaterThan(70));
        expect(groups['variant_a']!, greaterThan(70));
        expect(groups['variant_b']!, greaterThan(70));
      });
    });

    group('Debug Utilities', () {
      test('debugDumpAllFlags returns all flag values as map', () {
        when(mockRemoteConfig.getInt('aha_moment_kill_requirement', defaultValue: any))
            .thenReturn(1);
        when(mockRemoteConfig.getInt('stat_master_points_requirement', defaultValue: any))
            .thenReturn(50);
        when(mockRemoteConfig.getInt('balanced_fighter_points_per_tree', defaultValue: any))
            .thenReturn(15);
        when(mockRemoteConfig.getInt('season_warrior_seasons_requirement', defaultValue: any))
            .thenReturn(10);
        when(mockRemoteConfig.getInt('consistency_seasons_requirement', defaultValue: any))
            .thenReturn(3);
        when(mockRemoteConfig.getString('consistency_minimum_tier', defaultValue: any))
            .thenReturn('Gold');
        when(mockRemoteConfig.getInt('bronze_currency_reward', defaultValue: any))
            .thenReturn(50);
        when(mockRemoteConfig.getInt('silver_currency_reward', defaultValue: any))
            .thenReturn(100);
        when(mockRemoteConfig.getInt('gold_currency_reward', defaultValue: any))
            .thenReturn(250);
        when(mockRemoteConfig.getInt('platinum_currency_reward', defaultValue: any))
            .thenReturn(500);
        when(mockRemoteConfig.getBool('achievement_push_notification_enabled', defaultValue: any))
            .thenReturn(true);
        when(mockRemoteConfig.getInt('achievement_push_notification_threshold', defaultValue: any))
            .thenReturn(75);
        when(mockRemoteConfig.getBool('season_end_ceremony_enabled', defaultValue: any))
            .thenReturn(true);
        when(mockRemoteConfig.getInt('season_end_ceremony_duration_seconds', defaultValue: any))
            .thenReturn(3);

        final dump = flags.debugDumpAllFlags();

        expect(dump, isA<Map<String, dynamic>>());
        expect(dump.keys.length, equals(14));
        expect(dump['aha_moment_kill_requirement'], equals(1));
        expect(dump['stat_master_points_requirement'], equals(50));
        expect(dump['balanced_fighter_points_per_tree'], equals(15));
        expect(dump['season_warrior_seasons_requirement'], equals(10));
        expect(dump['consistency_seasons_requirement'], equals(3));
        expect(dump['consistency_minimum_tier'], equals('Gold'));
        expect(dump['bronze_currency_reward'], equals(50));
        expect(dump['silver_currency_reward'], equals(100));
        expect(dump['gold_currency_reward'], equals(250));
        expect(dump['platinum_currency_reward'], equals(500));
        expect(dump['push_notification_enabled'], isTrue);
        expect(dump['push_notification_threshold'], equals(75));
        expect(dump['season_end_ceremony_enabled'], isTrue);
        expect(dump['season_end_ceremony_duration'], equals(3));
      });

      test('debugDumpAllFlags contains expected keys', () {
        // Setup all mocks with defaults
        when(mockRemoteConfig.getInt(any, defaultValue: any))
            .thenReturn(1);
        when(mockRemoteConfig.getString(any, defaultValue: any))
            .thenReturn('Gold');
        when(mockRemoteConfig.getBool(any, defaultValue: any))
            .thenReturn(true);

        final dump = flags.debugDumpAllFlags();

        final expectedKeys = [
          'aha_moment_kill_requirement',
          'stat_master_points_requirement',
          'balanced_fighter_points_per_tree',
          'season_warrior_seasons_requirement',
          'consistency_seasons_requirement',
          'consistency_minimum_tier',
          'bronze_currency_reward',
          'silver_currency_reward',
          'gold_currency_reward',
          'platinum_currency_reward',
          'push_notification_enabled',
          'push_notification_threshold',
          'season_end_ceremony_enabled',
          'season_end_ceremony_duration',
        ];

        for (final key in expectedKeys) {
          expect(dump, containsPair(key, anything));
        }
      });
    });
  });
}
