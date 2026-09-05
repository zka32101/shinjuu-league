import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shinjuu_league/data/models/season_model.dart';
import 'package:shinjuu_league/data/models/seasonal_progress.dart';
import 'package:shinjuu_league/services/ranking_service.dart';
import 'package:shinjuu_league/services/rewards_service.dart';
import 'package:shinjuu_league/services/season_service.dart';
import 'package:shinjuu_league/services/firestore_service.dart';
import 'package:shinjuu_league/viewmodels/season_viewmodel.dart';

class MockSeasonService implements SeasonService {
  RankedSeason? activeSeasonResult;
  Exception? activeSeasonException;

  @override
  Future<RankedSeason?> getActiveSeason() async {
    if (activeSeasonException != null) throw activeSeasonException!;
    return activeSeasonResult;
  }

  @override
  Future<void> startNewSeason(RankedSeason season) async {}

  @override
  Future<void> endCurrentSeason() async {}

  @override
  Future<RankedSeason?> getSeasonById(String seasonId) async => null;

  @override
  Future<List<RankedSeason>> getAllSeasons() async => [];
}

class MockRankingService implements RankingService {
  Map<String, dynamic>? userSeasonDataResult;
  Exception? userSeasonDataException;

  @override
  Future<Map<String, dynamic>?> getSeasonalData(
    String userId,
    String seasonId,
  ) async {
    if (userSeasonDataException != null) throw userSeasonDataException!;
    return userSeasonDataResult;
  }

  @override
  Future<void> recordSeasonalStats(String userId, String seasonId, Map<String, dynamic> stats) async {}

  @override
  Future<List<Map<String, dynamic>>> getLeaderboard(String seasonId, {int limit = 100}) async => [];

  @override
  Future<void> updateTierTransition(String userId, String seasonId, String fromTier, String toTier) async {}

  @override
  Future<List<Map<String, dynamic>>> getTierTransitions(String userId, String seasonId) async => [];
}

class MockRewardsService implements RewardsService {
  Exception? claimRewardsException;

  @override
  Future<void> claimRewards({required String userId, required String seasonId}) async {
    if (claimRewardsException != null) throw claimRewardsException!;
  }

  @override
  Future<List<Map<String, dynamic>>> getAvailableRewards(String seasonId) async => [];

  @override
  Future<List<Map<String, dynamic>>> getEarnedRewards(String userId, String seasonId) async => [];

  @override
  Future<void> awardReward(String userId, String rewardId) async {}

  @override
  Future<bool> isRewardClaimed(String userId, String rewardId) async => false;
}

class MockFirestoreService implements FirestoreService {
  @override
  Future<Map<String, dynamic>?> getUserData(String userId) async => null;

  @override
  Future<void> updateUserData(String userId, Map<String, dynamic> data) async {}

  @override
  Future<void> createBattle(String battleId, Map<String, dynamic> battleData) async {}

  @override
  Future<Map<String, dynamic>?> getBattle(String battleId) async => null;

  @override
  Future<void> updateBattle(String battleId, Map<String, dynamic> updates) async {}

  @override
  Future<void> saveBattleResult(String userId, Map<String, dynamic> resultData) async {}

  @override
  Future<List<Map<String, dynamic>>> getUserBattleHistory(String userId, {int limit = 20}) async => [];

  @override
  Future<void> createUser(String userId, Map<String, dynamic> userData) async {}

  @override
  Future<void> sendFriendRequest(String fromUserId, String toUserId) async {}

  @override
  Future<void> acceptFriendRequest(String userId, String friendId) async {}

  @override
  Future<List<String>> getFriendList(String userId) async => [];

  @override
  Future<List<Map<String, dynamic>>> getFriendRequests(String userId) async => [];

  @override
  Future<void> createGuild(String guildId, Map<String, dynamic> guildData) async {}

  @override
  Future<Map<String, dynamic>?> getGuild(String guildId) async => null;

  @override
  Future<void> updateGuild(String guildId, Map<String, dynamic> updates) async {}

  @override
  Future<List<String>> getGuildMembers(String guildId) async => [];

  @override
  Future<void> addGuildMember(String guildId, String userId) async {}

  @override
  Future<void> removeGuildMember(String guildId, String userId) async {}

  @override
  Future<void> updateUserGuildId(String userId, String? guildId) async {}

  @override
  Future<void> postGuildMessage(String guildId, Map<String, dynamic> messageData) async {}

  @override
  Future<List<Map<String, dynamic>>> getGuildMessages(String guildId) async => [];

  @override
  Future<void> updateUserPurchaseCohort(String userId, String newCohort) async {}

  @override
  Future<void> deleteAllCollections() async {}
}

void main() {
  group('CurrentSeasonViewModel', () {
    late MockSeasonService mockSeasonService;
    late MockRankingService mockRankingService;
    late MockRewardsService mockRewardsService;
    late MockFirestoreService mockFirestoreService;

    setUp(() {
      mockSeasonService = MockSeasonService();
      mockRankingService = MockRankingService();
      mockRewardsService = MockRewardsService();
      mockFirestoreService = MockFirestoreService();
    });

    test('initializes with loading state', () {
      final viewModel = CurrentSeasonViewModel(
        seasonService: mockSeasonService,
        rankingService: mockRankingService,
        rewardsService: mockRewardsService,
        firestoreService: mockFirestoreService,
        userId: 'test-user',
      );

      expect(viewModel.state, isA<AsyncValue<SeasonalProgress?>>());
      expect(viewModel.state.isLoading, true);
    });

    test('loads season data successfully', () async {
      mockSeasonService.activeSeasonResult = RankedSeason(
        seasonId: 'season-1',
        name: 'Season 1',
        startDate: DateTime(2026, 9, 1),
        endDate: DateTime(2026, 10, 1),
        tierThresholds: {
          'Bronze': 400,
          'Silver': 1400,
          'Gold': 1800,
          'Platinum': 2200,
          'Legend': 2800,
        },
      );

      mockRankingService.userSeasonDataResult = {
        'currentRating': 1500,
        'currentTier': 'Silver',
        'peakTier': 'Silver',
        'startingRating': 1200,
        'peakRating': 1500,
        'previousTier': 'Bronze',
        'seasonWins': 5,
        'seasonLosses': 3,
        'seasonDraws': 0,
        'promotionCount': 1,
        'demotionCount': 0,
        'longestWinStreak': 3,
        'currentWinStreak': 1,
        'earnedRewards': ['reward-1', 'reward-2'],
        'rewardsClaimed': false,
      };

      final viewModel = CurrentSeasonViewModel(
        seasonService: mockSeasonService,
        rankingService: mockRankingService,
        rewardsService: mockRewardsService,
        firestoreService: mockFirestoreService,
        userId: 'test-user',
      );

      await Future.delayed(const Duration(milliseconds: 100));

      expect(viewModel.state.isLoading, false);
      expect(viewModel.state.value, isNotNull);
      expect(viewModel.state.value!.userData.currentTier, equals('Silver'));
      expect(viewModel.state.value!.userData.currentRating, equals(1500));
    });

    test('calculates progress percentage correctly', () async {
      mockSeasonService.activeSeasonResult = RankedSeason(
        seasonId: 'season-1',
        name: 'Season 1',
        startDate: DateTime(2026, 9, 1),
        endDate: DateTime(2026, 10, 1),
        tierThresholds: {
          'Bronze': 400,
          'Silver': 1400,
          'Gold': 1800,
          'Platinum': 2200,
          'Legend': 2800,
        },
      );

      // Rating 1600 is between Silver (1400) and Gold (1800)
      // Progress = (1600 - 1400) / (1800 - 1400) = 200/400 = 0.5 (50%)
      mockRankingService.userSeasonDataResult = {
        'currentRating': 1600,
        'currentTier': 'Silver',
        'peakTier': 'Silver',
        'seasonWins': 0,
        'seasonLosses': 0,
        'seasonDraws': 0,
        'earnedRewards': [],
      };

      final viewModel = CurrentSeasonViewModel(
        seasonService: mockSeasonService,
        rankingService: mockRankingService,
        rewardsService: mockRewardsService,
        firestoreService: mockFirestoreService,
        userId: 'test-user',
      );

      await Future.delayed(const Duration(milliseconds: 100));

      final progress = viewModel.state.value?.progressPercentage ?? 0;
      expect(progress, closeTo(0.5, 0.01));
    });

    test('handles null user data gracefully', () async {
      mockSeasonService.activeSeasonResult = RankedSeason(
        seasonId: 'season-1',
        name: 'Season 1',
        startDate: DateTime(2026, 9, 1),
        endDate: DateTime(2026, 10, 1),
        tierThresholds: {
          'Bronze': 400,
          'Silver': 1400,
          'Gold': 1800,
          'Platinum': 2200,
          'Legend': 2800,
        },
      );

      mockRankingService.userSeasonDataResult = null;

      final viewModel = CurrentSeasonViewModel(
        seasonService: mockSeasonService,
        rankingService: mockRankingService,
        rewardsService: mockRewardsService,
        firestoreService: mockFirestoreService,
        userId: 'test-user',
      );

      await Future.delayed(const Duration(milliseconds: 100));

      expect(viewModel.state.value, isNull);
    });

    test('handles null user ID gracefully', () async {
      final viewModel = CurrentSeasonViewModel(
        seasonService: mockSeasonService,
        rankingService: mockRankingService,
        rewardsService: mockRewardsService,
        firestoreService: mockFirestoreService,
        userId: null,
      );

      await Future.delayed(const Duration(milliseconds: 100));

      expect(viewModel.state.value, isNull);
    });

    test('getTierInfo returns correct tier metadata', () {
      final viewModel = CurrentSeasonViewModel(
        seasonService: mockSeasonService,
        rankingService: mockRankingService,
        rewardsService: mockRewardsService,
        firestoreService: mockFirestoreService,
        userId: 'test-user',
      );

      final silverInfo = viewModel.getTierInfo('Silver');
      expect(silverInfo, isNotNull);
      expect(silverInfo!.name, equals('Silver'));
      expect(silverInfo.minRating, equals(1400));
      expect(silverInfo.maxRating, equals(1799));
      expect(silverInfo.emoji, equals('🥈'));
    });

    test('refresh clears and reloads state', () async {
      mockSeasonService.activeSeasonResult = RankedSeason(
        seasonId: 'season-1',
        name: 'Season 1',
        startDate: DateTime(2026, 9, 1),
        endDate: DateTime(2026, 10, 1),
        tierThresholds: {
          'Bronze': 400,
          'Silver': 1400,
          'Gold': 1800,
          'Platinum': 2200,
          'Legend': 2800,
        },
      );

      mockRankingService.userSeasonDataResult = {
        'currentRating': 1500,
        'currentTier': 'Silver',
        'seasonWins': 5,
      };

      final viewModel = CurrentSeasonViewModel(
        seasonService: mockSeasonService,
        rankingService: mockRankingService,
        rewardsService: mockRewardsService,
        firestoreService: mockFirestoreService,
        userId: 'test-user',
      );

      await Future.delayed(const Duration(milliseconds: 100));
      expect(viewModel.state.isLoading, false);

      await viewModel.refresh();

      expect(viewModel.state.isLoading, false);
      expect(viewModel.state.value, isNotNull);
    });

    test('claimRewards calls service and refreshes state', () async {
      mockSeasonService.activeSeasonResult = RankedSeason(
        seasonId: 'season-1',
        name: 'Season 1',
        startDate: DateTime(2026, 9, 1),
        endDate: DateTime(2026, 10, 1),
        tierThresholds: {'Bronze': 400},
      );

      mockRankingService.userSeasonDataResult = {
        'currentRating': 1200,
        'currentTier': 'Bronze',
        'seasonWins': 0,
        'earnedRewards': ['reward-1'],
        'rewardsClaimed': false,
      };

      final viewModel = CurrentSeasonViewModel(
        seasonService: mockSeasonService,
        rankingService: mockRankingService,
        rewardsService: mockRewardsService,
        firestoreService: mockFirestoreService,
        userId: 'test-user',
      );

      await Future.delayed(const Duration(milliseconds: 100));
      await viewModel.claimRewards();

      expect(viewModel.state.value, isNotNull);
    });

    test('handles service exceptions', () async {
      mockSeasonService.activeSeasonException = Exception('Season service error');

      final viewModel = CurrentSeasonViewModel(
        seasonService: mockSeasonService,
        rankingService: mockRankingService,
        rewardsService: mockRewardsService,
        firestoreService: mockFirestoreService,
        userId: 'test-user',
      );

      await Future.delayed(const Duration(milliseconds: 100));

      expect(viewModel.state.isLoading, false);
      expect(viewModel.state.hasError, true);
    });
  });
}
