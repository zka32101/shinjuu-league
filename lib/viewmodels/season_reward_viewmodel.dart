import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shinjuu_league/data/models/seasonal_reward.dart';
import 'package:shinjuu_league/services/season_reward_service.dart';

/// State for season reward operations
class SeasonRewardState {
  final List<SeasonRewardDistribution> playerRewards;
  final List<SeasonRewardDistribution> unclaimedRewards;
  final bool isLoading;
  final String? error;
  final String? successMessage;

  SeasonRewardState({
    this.playerRewards = const [],
    this.unclaimedRewards = const [],
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  SeasonRewardState copyWith({
    List<SeasonRewardDistribution>? playerRewards,
    List<SeasonRewardDistribution>? unclaimedRewards,
    bool? isLoading,
    String? error,
    String? successMessage,
  }) {
    return SeasonRewardState(
      playerRewards: playerRewards ?? this.playerRewards,
      unclaimedRewards: unclaimedRewards ?? this.unclaimedRewards,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successMessage: successMessage,
    );
  }
}

/// ViewModel for managing seasonal rewards
class SeasonRewardViewModel extends StateNotifier<SeasonRewardState> {
  final SeasonRewardService _rewardService;
  final String _userId;

  SeasonRewardViewModel(
    this._rewardService,
    this._userId,
  ) : super(SeasonRewardState());

  /// Load all rewards for the current player
  Future<void> loadPlayerRewards() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final rewards = await _rewardService.getPlayerSeasonRewards(_userId);
      final unclaimed = await _rewardService.getUnclaimedRewards(_userId);

      state = state.copyWith(
        playerRewards: rewards,
        unclaimedRewards: unclaimed,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Claim rewards for a specific season
  Future<bool> claimSeasonRewards(String seasonId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final success = await _rewardService.claimRewards(_userId, seasonId);

      if (success) {
        // Reload rewards to reflect claimed status
        await loadPlayerRewards();
        state = state.copyWith(
          successMessage: 'Rewards claimed successfully!',
        );
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Get reward status for a specific season
  Future<SeasonRewardStatus> getRewardStatus(String seasonId) async {
    return _rewardService.getRewardStatus(_userId, seasonId);
  }

  /// Get rewards for a specific tier (for preview purposes)
  Future<List<SeasonalReward>> getRewardsForTier(String tier) async {
    return _rewardService.getRewardsForTier(tier);
  }

  /// Clear success message
  void clearSuccessMessage() {
    state = state.copyWith(successMessage: null);
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Get claimed reward count
  int getClaimedCount() {
    return state.playerRewards.where((r) => r.isClaimed).length;
  }

  /// Get total unclaimed reward count
  int getUnclaimedCount() {
    return state.unclaimedRewards.length;
  }

  /// Check if any rewards are about to expire (within 7 days)
  List<SeasonRewardDistribution> getExpiringRewards() {
    final now = DateTime.now();
    final sevenDaysFromNow = now.add(const Duration(days: 7));

    return state.unclaimedRewards.where((r) {
      return r.expiresAt.isAfter(now) && r.expiresAt.isBefore(sevenDaysFromNow);
    }).toList();
  }
}

/// Riverpod provider for season reward service
final seasonRewardServiceProvider = Provider<SeasonRewardService>((ref) {
  throw UnimplementedError(
    'seasonRewardServiceProvider must be provided by the application',
  );
});

/// Riverpod provider for season reward view model
final seasonRewardViewModelProvider = StateNotifierProvider.family.autoDispose<
    SeasonRewardViewModel,
    SeasonRewardState,
    String>((ref, userId) {
  final rewardService = ref.watch(seasonRewardServiceProvider);
  return SeasonRewardViewModel(rewardService, userId);
});

/// Provider to get rewards for a specific tier
final tierRewardsProvider = FutureProvider.family<List<SeasonalReward>, String>(
  (ref, tier) async {
    final rewardService = ref.watch(seasonRewardServiceProvider);
    return rewardService.getRewardsForTier(tier);
  },
);

/// Provider to get reward status
final rewardStatusProvider =
    FutureProvider.family<SeasonRewardStatus, (String, String)>(
  (ref, args) async {
    final (userId, seasonId) = args;
    final rewardService = ref.watch(seasonRewardServiceProvider);
    return rewardService.getRewardStatus(userId, seasonId);
  },
);
