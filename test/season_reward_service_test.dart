import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shinjuu_league/data/models/seasonal_reward.dart';
import 'package:shinjuu_league/services/season_reward_service.dart';
import 'package:shinjuu_league/services/firestore_service.dart';

class MockFirestoreService extends Mock implements FirestoreService {}

void main() {
  group('SeasonRewardService', () {
    late SeasonRewardService service;
    late MockFirestoreService mockFirestore;

    setUp(() {
      mockFirestore = MockFirestoreService();
      service = SeasonRewardService(mockFirestore);
    });

    group('getRewardsForTier', () {
      test('returns rewards for valid tier', () async {
        final rewards = await service.getRewardsForTier('Gold');
        expect(rewards, isNotEmpty);
        expect(rewards.first.tier, equals('Gold'));
      });

      test('returns empty list for invalid tier', () async {
        final rewards = await service.getRewardsForTier('InvalidTier');
        expect(rewards, isEmpty);
      });

      test('bronze tier has exactly 1 reward', () async {
        final rewards = await service.getRewardsForTier('Bronze');
        expect(rewards.length, equals(1));
        expect(rewards.first.rewardType, equals(RewardType.currency));
        expect(rewards.first.quantity, equals(100));
      });

      test('diamond tier has 3 rewards', () async {
        final rewards = await service.getRewardsForTier('Diamond');
        expect(rewards.length, equals(3));
      });

      test('rewards have non-empty IDs and display names', () async {
        final rewards = await service.getRewardsForTier('Platinum');
        for (final reward in rewards) {
          expect(reward.rewardId, isNotEmpty);
          expect(reward.displayName, isNotEmpty);
          expect(reward.iconUrl, isNotEmpty);
        }
      });
    });

    group('distributeSeasonRewards', () {
      test('creates distribution with correct tier', () async {
        when(mockFirestore.set(any, any)).thenAnswer((_) async {});

        await service.distributeSeasonRewards(
          'season_1',
          'user_123',
          'Gold',
        );

        verify(mockFirestore.set(
          'users/user_123/season_rewards/season_1',
          any,
        )).called(1);
      });

      test('throws exception for invalid tier', () {
        expect(
          () => service.distributeSeasonRewards('season_1', 'user_123', 'InvalidTier'),
          throwsException,
        );
      });

      test('distribution has 30-day claim window', () async {
        when(mockFirestore.set(any, any)).thenAnswer((invocation) async {
          final distribution = invocation.positionalArguments[1] as SeasonRewardDistribution;
          final daysDifference = distribution.expiresAt.difference(DateTime.now()).inDays;
          expect(daysDifference, equals(30));
        });

        await service.distributeSeasonRewards('season_1', 'user_123', 'Gold');
      });

      test('distribution starts unclaimed', () async {
        SeasonRewardDistribution? capturedDist;
        when(mockFirestore.set(any, any)).thenAnswer((invocation) async {
          capturedDist = invocation.positionalArguments[1] as SeasonRewardDistribution;
        });

        await service.distributeSeasonRewards('season_1', 'user_123', 'Silver');
        expect(capturedDist!.isClaimed, isFalse);
      });
    });

    group('claimRewards', () {
      test('claims rewards successfully', () async {
        final distribution = SeasonRewardDistribution(
          seasonId: 'season_1',
          userId: 'user_123',
          finalTier: 'Gold',
          rewards: await service.getRewardsForTier('Gold'),
          distributedAt: DateTime.now(),
          claimedAt: null,
          expiresAt: DateTime.now().add(const Duration(days: 30)),
        );

        when(mockFirestore.get('users/user_123/season_rewards/season_1'))
            .thenAnswer((_) async => distribution.toJson());

        when(mockFirestore.update(any, any)).thenAnswer((_) async {});

        final result = await service.claimRewards('user_123', 'season_1');
        expect(result, isTrue);
        verify(mockFirestore.update(
          'users/user_123/season_rewards/season_1',
          any,
        )).called(1);
      });

      test('prevents double claiming', () async {
        final distribution = SeasonRewardDistribution(
          seasonId: 'season_1',
          userId: 'user_123',
          finalTier: 'Gold',
          rewards: await service.getRewardsForTier('Gold'),
          distributedAt: DateTime.now().subtract(const Duration(days: 10)),
          claimedAt: DateTime.now().subtract(const Duration(days: 5)),
          expiresAt: DateTime.now().add(const Duration(days: 20)),
        );

        when(mockFirestore.get('users/user_123/season_rewards/season_1'))
            .thenAnswer((_) async => distribution.toJson());

        expect(
          () => service.claimRewards('user_123', 'season_1'),
          throwsException,
        );
      });

      test('prevents claim after expiration', () async {
        final distribution = SeasonRewardDistribution(
          seasonId: 'season_1',
          userId: 'user_123',
          finalTier: 'Gold',
          rewards: await service.getRewardsForTier('Gold'),
          distributedAt: DateTime.now().subtract(const Duration(days: 40)),
          claimedAt: null,
          expiresAt: DateTime.now().subtract(const Duration(days: 10)),
        );

        when(mockFirestore.get('users/user_123/season_rewards/season_1'))
            .thenAnswer((_) async => distribution.toJson());

        expect(
          () => service.claimRewards('user_123', 'season_1'),
          throwsException,
        );
      });

      test('throws for non-existent rewards', () async {
        when(mockFirestore.get('users/user_123/season_rewards/season_1'))
            .thenAnswer((_) async => null);

        expect(
          () => service.claimRewards('user_123', 'season_1'),
          throwsException,
        );
      });
    });

    group('getPlayerSeasonRewards', () {
      test('returns all season rewards for player', () async {
        final rewards = [
          SeasonRewardDistribution(
            seasonId: 'season_1',
            userId: 'user_123',
            finalTier: 'Gold',
            rewards: await service.getRewardsForTier('Gold'),
            distributedAt: DateTime.now(),
            claimedAt: null,
            expiresAt: DateTime.now().add(const Duration(days: 30)),
          ),
          SeasonRewardDistribution(
            seasonId: 'season_2',
            userId: 'user_123',
            finalTier: 'Silver',
            rewards: await service.getRewardsForTier('Silver'),
            distributedAt: DateTime.now(),
            claimedAt: DateTime.now(),
            expiresAt: DateTime.now().add(const Duration(days: 30)),
          ),
        ];

        when(mockFirestore.getCollection('users/user_123/season_rewards'))
            .thenAnswer((_) async => rewards.map((r) => r.toJson()).toList());

        final result = await service.getPlayerSeasonRewards('user_123');
        expect(result.length, equals(2));
      });
    });

    group('getUnclaimedRewards', () {
      test('returns only claimable rewards', () async {
        final rewards = [
          SeasonRewardDistribution(
            seasonId: 'season_1',
            userId: 'user_123',
            finalTier: 'Gold',
            rewards: await service.getRewardsForTier('Gold'),
            distributedAt: DateTime.now(),
            claimedAt: null,
            expiresAt: DateTime.now().add(const Duration(days: 30)),
          ),
          SeasonRewardDistribution(
            seasonId: 'season_2',
            userId: 'user_123',
            finalTier: 'Silver',
            rewards: await service.getRewardsForTier('Silver'),
            distributedAt: DateTime.now(),
            claimedAt: DateTime.now(),
            expiresAt: DateTime.now().add(const Duration(days: 30)),
          ),
          SeasonRewardDistribution(
            seasonId: 'season_3',
            userId: 'user_123',
            finalTier: 'Bronze',
            rewards: await service.getRewardsForTier('Bronze'),
            distributedAt: DateTime.now().subtract(const Duration(days: 40)),
            claimedAt: null,
            expiresAt: DateTime.now().subtract(const Duration(days: 10)),
          ),
        ];

        when(mockFirestore.getCollection('users/user_123/season_rewards'))
            .thenAnswer((_) async => rewards.map((r) => r.toJson()).toList());

        final result = await service.getUnclaimedRewards('user_123');
        expect(result.length, equals(1)); // Only season_1 is claimable
        expect(result.first.seasonId, equals('season_1'));
      });
    });

    group('getRewardStatus', () {
      test('returns notFound for non-existent rewards', () async {
        when(mockFirestore.get('users/user_123/season_rewards/season_1'))
            .thenAnswer((_) async => null);

        final status = await service.getRewardStatus('user_123', 'season_1');
        expect(status, equals(SeasonRewardStatus.notFound));
      });

      test('returns pending for unclaimed rewards', () async {
        final distribution = SeasonRewardDistribution(
          seasonId: 'season_1',
          userId: 'user_123',
          finalTier: 'Gold',
          rewards: await service.getRewardsForTier('Gold'),
          distributedAt: DateTime.now(),
          claimedAt: null,
          expiresAt: DateTime.now().add(const Duration(days: 30)),
        );

        when(mockFirestore.get('users/user_123/season_rewards/season_1'))
            .thenAnswer((_) async => distribution.toJson());

        final status = await service.getRewardStatus('user_123', 'season_1');
        expect(status, equals(SeasonRewardStatus.pending));
      });

      test('returns claimed for claimed rewards', () async {
        final distribution = SeasonRewardDistribution(
          seasonId: 'season_1',
          userId: 'user_123',
          finalTier: 'Gold',
          rewards: await service.getRewardsForTier('Gold'),
          distributedAt: DateTime.now(),
          claimedAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(days: 30)),
        );

        when(mockFirestore.get('users/user_123/season_rewards/season_1'))
            .thenAnswer((_) async => distribution.toJson());

        final status = await service.getRewardStatus('user_123', 'season_1');
        expect(status, equals(SeasonRewardStatus.claimed));
      });

      test('returns expired for expired rewards', () async {
        final distribution = SeasonRewardDistribution(
          seasonId: 'season_1',
          userId: 'user_123',
          finalTier: 'Gold',
          rewards: await service.getRewardsForTier('Gold'),
          distributedAt: DateTime.now().subtract(const Duration(days: 40)),
          claimedAt: null,
          expiresAt: DateTime.now().subtract(const Duration(days: 10)),
        );

        when(mockFirestore.get('users/user_123/season_rewards/season_1'))
            .thenAnswer((_) async => distribution.toJson());

        final status = await service.getRewardStatus('user_123', 'season_1');
        expect(status, equals(SeasonRewardStatus.expired));
      });
    });

    group('SeasonRewardDistribution helpers', () {
      test('getTotalCurrencyValue sums all currency rewards', () async {
        final distribution = SeasonRewardDistribution(
          seasonId: 'season_1',
          userId: 'user_123',
          finalTier: 'Diamond',
          rewards: await service.getRewardsForTier('Diamond'),
          distributedAt: DateTime.now(),
          claimedAt: null,
          expiresAt: DateTime.now().add(const Duration(days: 30)),
        );

        final total = distribution.getTotalCurrencyValue();
        expect(total, greaterThan(0));
      });

      test('getRewardsByType filters correctly', () async {
        final distribution = SeasonRewardDistribution(
          seasonId: 'season_1',
          userId: 'user_123',
          finalTier: 'Platinum',
          rewards: await service.getRewardsForTier('Platinum'),
          distributedAt: DateTime.now(),
          claimedAt: null,
          expiresAt: DateTime.now().add(const Duration(days: 30)),
        );

        final skins = distribution.getRewardsByType(RewardType.cosmetic_skin);
        expect(skins, isNotEmpty);
        for (final reward in skins) {
          expect(reward.rewardType, equals(RewardType.cosmetic_skin));
        }
      });
    });
  });
}
