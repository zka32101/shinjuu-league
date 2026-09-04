import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/season_model.dart';
import '../data/models/user_model.dart';
import '../data/models/seasonal_progress.dart';
import '../services/season_service.dart';
import '../services/ranking_service.dart';
import '../services/rewards_service.dart';
import '../services/firestore_service.dart';

/// ViewModel for current season state
///
/// Provides:
/// - Active season metadata
/// - User's seasonal progress
/// - Tier information and progression
/// - Promotion events
class CurrentSeasonViewModel extends StateNotifier<AsyncValue<SeasonalProgress?>> {
  final SeasonService _seasonService;
  final RankingService _rankingService;
  final RewardsService _rewardsService;
  final FirestoreService _firestoreService;
  final String? _userId;

  CurrentSeasonViewModel({
    required SeasonService seasonService,
    required RankingService rankingService,
    required RewardsService rewardsService,
    required FirestoreService firestoreService,
    required String? userId,
  })  : _seasonService = seasonService,
        _rankingService = rankingService,
        _rewardsService = rewardsService,
        _firestoreService = firestoreService,
        _userId = userId,
        super(const AsyncValue.loading()) {
    _initializeSeasonalProgress();
  }

  /// Initialize seasonal progress on creation
  Future<void> _initializeSeasonalProgress() async {
    try {
      if (_userId == null) {
        state = const AsyncValue.data(null);
        return;
      }

      final season = await _seasonService.getActiveSeason();
      if (season == null) {
        state = const AsyncValue.data(null);
        return;
      }

      final userSeasonData = await _rankingService.getSeasonalData(
        _userId!,
        season.seasonId,
      );

      if (userSeasonData == null) {
        // User hasn't played in this season
        state = const AsyncValue.data(null);
        return;
      }

      final progress = _buildSeasonalProgress(season, userSeasonData);
      state = AsyncValue.data(progress);
    } catch (e) {
      print('[CurrentSeasonViewModel] Error initializing: $e');
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  /// Build SeasonalProgress UI model
  SeasonalProgress _buildSeasonalProgress(
    RankedSeason season,
    Map<String, dynamic> userSeasonData,
  ) {
    final currentRating = userSeasonData['currentRating'] as int? ?? 1200;
    final currentTier = userSeasonData['currentTier'] as String? ?? 'Bronze';
    final peakTier = userSeasonData['peakTier'] as String? ?? 'Bronze';

    // Determine next tier
    final tierThresholds = season.tierThresholds;
    final tiers = tierThresholds.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    String nextTierName = currentTier;
    int ratingToNextTier = 0;

    for (int i = 0; i < tiers.length - 1; i++) {
      if (tiers[i].key == currentTier) {
        nextTierName = tiers[i + 1].key;
        ratingToNextTier = tiers[i + 1].value - currentRating;
        break;
      }
    }

    // Calculate progress percentage
    final currentThreshold =
        tierThresholds[currentTier] ?? tierThresholds['Bronze'] ?? 400;
    final nextThreshold =
        tierThresholds[nextTierName] ?? tierThresholds['Platinum'] ?? 2200;
    final tierRatingRange = nextThreshold - currentThreshold;
    final playerProgress = currentRating - currentThreshold;
    final progressPercentage =
        (playerProgress / tierRatingRange).clamp(0.0, 1.0);

    // Get earned rewards
    final earnedRewardIds =
        (userSeasonData['earnedRewards'] as List<dynamic>? ?? [])
            .cast<String>();
    final rewardPreviews = earnedRewardIds
        .map(
          (id) => TierRewardPreview(
            rewardId: id,
            displayName: 'Seasonal Reward',
            type: 'cosmetic_skin',
            iconUrl: null,
            claimed: userSeasonData['rewardsClaimed'] as bool? ?? false,
          ),
        )
        .toList();

    final userData = UserSeasonData(
      userId: _userId!,
      seasonId: season.seasonId,
      startingRating: userSeasonData['startingRating'] as int? ?? 1200,
      peakRating: userSeasonData['peakRating'] as int? ?? currentRating,
      currentRating: currentRating,
      currentTier: currentTier,
      previousTier: userSeasonData['previousTier'] as String? ?? 'Bronze',
      peakTier: peakTier,
      tierTransitions: [],
      seasonWins: userSeasonData['seasonWins'] as int? ?? 0,
      seasonLosses: userSeasonData['seasonLosses'] as int? ?? 0,
      seasonDraws: userSeasonData['seasonDraws'] as int? ?? 0,
      promotionCount: userSeasonData['promotionCount'] as int? ?? 0,
      demotionCount: userSeasonData['demotionCount'] as int? ?? 0,
      longestWinStreak: userSeasonData['longestWinStreak'] as int? ?? 0,
      currentWinStreak: userSeasonData['currentWinStreak'] as int? ?? 0,
      earnedRewards: earnedRewardIds,
      rewardsClaimed: userSeasonData['rewardsClaimed'] as bool? ?? false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return SeasonalProgress(
      season: season,
      userData: userData,
      nextTierName: nextTierName,
      ratingToNextTier: ratingToNextTier.abs(),
      progressPercentage: progressPercentage,
      isPromotionReady: ratingToNextTier <= 0,
      earnedRewardPreviews: rewardPreviews,
    );
  }

  /// Refresh seasonal progress
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    await _initializeSeasonalProgress();
  }

  /// Claim earned rewards
  Future<void> claimRewards() async {
    if (_userId == null) return;

    try {
      final currentProgress = state.value;
      if (currentProgress == null) return;

      await _rewardsService.claimRewards(
        userId: _userId!,
        seasonId: currentProgress.season.seasonId,
      );

      await refresh();
      print('[CurrentSeasonViewModel] Rewards claimed');
    } catch (e) {
      print('[CurrentSeasonViewModel] Error claiming rewards: $e');
    }
  }

  /// Get tier info for display
  TierInfo? getTierInfo(String tierName) {
    final tiers = {
      'Bronze': TierInfo(
        name: 'Bronze',
        minRating: 400,
        maxRating: 1399,
        emoji: '🥉',
        kFactor: 64,
        rewardIds: [],
      ),
      'Silver': TierInfo(
        name: 'Silver',
        minRating: 1400,
        maxRating: 1799,
        emoji: '🥈',
        kFactor: 32,
        rewardIds: [],
      ),
      'Gold': TierInfo(
        name: 'Gold',
        minRating: 1800,
        maxRating: 2199,
        emoji: '🥇',
        kFactor: 24,
        rewardIds: [],
      ),
      'Platinum': TierInfo(
        name: 'Platinum',
        minRating: 2200,
        maxRating: 2799,
        emoji: '👑',
        kFactor: 16,
        rewardIds: [],
      ),
      'Legend': TierInfo(
        name: 'Legend',
        minRating: 2800,
        maxRating: 3000,
        emoji: '⭐',
        kFactor: 16,
        rewardIds: [],
      ),
    };

    return tiers[tierName];
  }
}

/// Provider for current season ViewModel
final currentSeasonViewModelProvider =
    StateNotifierProvider.autoDispose<CurrentSeasonViewModel, AsyncValue<SeasonalProgress?>>((ref) {
  final seasonService = ref.watch(seasonServiceProvider);
  final rankingService = ref.watch(rankingServiceProvider);
  final rewardsService = ref.watch(rewardsServiceProvider);
  final firestoreService = ref.watch(firestoreServiceProvider);

  // Get current user ID (requires userViewModelProvider)
  String? userId;
  // Note: This will be wired up when userViewModelProvider is available
  // For now, passing null - will be injected from parent

  return CurrentSeasonViewModel(
    seasonService: seasonService,
    rankingService: rankingService,
    rewardsService: rewardsService,
    firestoreService: firestoreService,
    userId: userId,
  );
});

// Import needed at top of file:
// import 'package:shinjuu_league/data/providers/service_providers.dart';
