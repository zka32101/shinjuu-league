import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/season_model.dart';
import '../data/models/user_model.dart';
import '../services/ranking_service.dart';
import '../services/firestore_service.dart';

/// ViewModel for tier ladder and ranking progression UI
///
/// Provides:
/// - Tier ladder with player's position
/// - Distance to next/previous tier
/// - Estimated games to promotion
/// - Demotion risk warnings
class RankingProgressViewModel extends StateNotifier<AsyncValue<TierLadderState?>> {
  final RankingService _rankingService;
  final FirestoreService _firestoreService;
  final String? _userId;
  final String? _seasonId;
  final Map<String, int>? _tierThresholds;

  RankingProgressViewModel({
    required RankingService rankingService,
    required FirestoreService firestoreService,
    required String? userId,
    required String? seasonId,
    required Map<String, int>? tierThresholds,
  })  : _rankingService = rankingService,
        _firestoreService = firestoreService,
        _userId = userId,
        _seasonId = seasonId,
        _tierThresholds = tierThresholds,
        super(const AsyncValue.loading()) {
    _initializeTierLadder();
  }

  /// Initialize tier ladder state
  Future<void> _initializeTierLadder() async {
    try {
      if (_userId == null || _seasonId == null) {
        state = const AsyncValue.data(null);
        return;
      }

      final userSeasonData = await _rankingService.getSeasonalData(
        _userId!,
        _seasonId!,
      );

      if (userSeasonData == null) {
        state = const AsyncValue.data(null);
        return;
      }

      final currentRating = userSeasonData['currentRating'] as int? ?? 1200;
      final currentTier = userSeasonData['currentTier'] as String? ?? 'Bronze';
      final seasonWins = userSeasonData['seasonWins'] as int? ?? 0;
      final seasonLosses = userSeasonData['seasonLosses'] as int? ?? 0;

      // Build tier ladder
      final tierThresholds = _tierThresholds ?? _defaultTierThresholds();
      final tiers = tierThresholds.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final tierLadder = <TierEntry>[];
      int playerPositionIndex = 0;

      for (int i = 0; i < tiers.length; i++) {
        final tierName = tiers[i].key;
        final threshold = tiers[i].value;
        final isCurrentTier = tierName == currentTier;

        tierLadder.add(
          TierEntry(
            tierName: tierName,
            threshold: threshold,
            isCurrentTier: isCurrentTier,
            minRating: threshold,
            maxRating: i == 0 ? 3000 : tiers[i - 1].value - 1,
            kFactor: _getKFactorForTier(tierName),
          ),
        );

        if (isCurrentTier) {
          playerPositionIndex = i;
        }
      }

      // Calculate tier distances
      final nextTierIndex = playerPositionIndex - 1;
      final previousTierIndex = playerPositionIndex + 1;

      final nextTierName =
          nextTierIndex >= 0 ? tierLadder[nextTierIndex].tierName : null;
      final nextTierThreshold =
          nextTierIndex >= 0 ? tierLadder[nextTierIndex].threshold : null;

      final previousTierName =
          previousTierIndex < tiers.length ? tierLadder[previousTierIndex].tierName : null;
      final previousTierThreshold =
          previousTierIndex < tiers.length ? tierLadder[previousTierIndex].threshold : null;

      // Calculate rating distances
      final ratingToNextTier = nextTierThreshold != null
          ? nextTierThreshold - currentRating
          : null;

      final ratingToPreviousTier = previousTierThreshold != null
          ? currentRating - previousTierThreshold
          : null;

      // Calculate promotion timeline
      final winRate = _rankingService.calculateWinRate(
        wins: seasonWins,
        losses: seasonLosses,
        draws: 0,
      );

      final estimatedGamesToPromotion = ratingToNextTier != null && ratingToNextTier > 0
          ? _estimateGamesToReach(currentRating, nextTierThreshold!, winRate)
          : 0;

      // Check demotion risk
      final demotionRiskThreshold = (previousTierThreshold ?? 400) + 50;
      final isDemotionRisk = ratingToPreviousTier != null &&
          ratingToPreviousTier < 50 &&
          seasonLosses > seasonWins;

      final ladderState = TierLadderState(
        tierLadder: tierLadder,
        playerPositionIndex: playerPositionIndex,
        playerCurrentRating: currentRating,
        playerCurrentTier: currentTier,
        nextTierName: nextTierName,
        ratingToNextTier: ratingToNextTier,
        estimatedGamesToPromotion: estimatedGamesToPromotion,
        previousTierName: previousTierName,
        ratingToPreviousTier: ratingToPreviousTier ?? 0,
        isDemotionRisk: isDemotionRisk,
        seasonWinRate: winRate,
        seasonGames: seasonWins + seasonLosses,
      );

      state = AsyncValue.data(ladderState);
    } catch (e) {
      print('[RankingProgressViewModel] Error initializing: $e');
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  /// Estimate games needed to reach target rating
  int _estimateGamesToReach(int currentRating, int targetRating, double winRate) {
    if (currentRating >= targetRating) return 0;
    if (winRate <= 0) return 999;

    final kFactor = _getKFactorForRating(currentRating);
    final expectedGainPerWin = kFactor * winRate;
    final ratingDifference = targetRating - currentRating;

    return (ratingDifference / expectedGainPerWin).ceil();
  }

  /// Get K-factor for tier
  int _getKFactorForTier(String tierName) {
    switch (tierName) {
      case 'Bronze':
        return 64;
      case 'Silver':
        return 32;
      case 'Gold':
        return 24;
      case 'Platinum':
        return 16;
      case 'Legend':
        return 16;
      default:
        return 32;
    }
  }

  /// Get K-factor for rating
  int _getKFactorForRating(int rating) {
    if (rating < 1400) return 64; // Bronze
    if (rating < 1800) return 32; // Silver
    if (rating < 2200) return 24; // Gold
    return 16; // Platinum/Legend
  }

  /// Default tier thresholds
  Map<String, int> _defaultTierThresholds() {
    return {
      'Bronze': 400,
      'Silver': 1400,
      'Gold': 1800,
      'Platinum': 2200,
      'Legend': 2800,
    };
  }

  /// Refresh tier ladder state
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    await _initializeTierLadder();
  }
}

/// Tier ladder entry for display
class TierEntry {
  final String tierName;
  final int threshold;
  final bool isCurrentTier;
  final int minRating;
  final int maxRating;
  final int kFactor;

  TierEntry({
    required this.tierName,
    required this.threshold,
    required this.isCurrentTier,
    required this.minRating,
    required this.maxRating,
    required this.kFactor,
  });
}

/// Complete tier ladder state
class TierLadderState {
  final List<TierEntry> tierLadder;
  final int playerPositionIndex;
  final int playerCurrentRating;
  final String playerCurrentTier;
  final String? nextTierName;
  final int? ratingToNextTier;
  final int estimatedGamesToPromotion;
  final String? previousTierName;
  final int ratingToPreviousTier;
  final bool isDemotionRisk;
  final double seasonWinRate;
  final int seasonGames;

  TierLadderState({
    required this.tierLadder,
    required this.playerPositionIndex,
    required this.playerCurrentRating,
    required this.playerCurrentTier,
    required this.nextTierName,
    required this.ratingToNextTier,
    required this.estimatedGamesToPromotion,
    required this.previousTierName,
    required this.ratingToPreviousTier,
    required this.isDemotionRisk,
    required this.seasonWinRate,
    required this.seasonGames,
  });

  /// Get emoji for current tier
  String getTierEmoji() {
    switch (playerCurrentTier) {
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

  /// Get color identifier for tier
  String getTierColor() {
    switch (playerCurrentTier) {
      case 'Bronze':
        return 'bronze';
      case 'Silver':
        return 'silver';
      case 'Gold':
        return 'gold';
      case 'Platinum':
        return 'platinum';
      case 'Legend':
        return 'legend';
      default:
        return 'default';
    }
  }

  /// Get promotion message
  String getPromotionMessage() {
    if (nextTierName == null) {
      return 'You are at the highest tier!';
    }
    if (ratingToNextTier == null || ratingToNextTier! <= 0) {
      return 'Promotion ready! Play your next battle!';
    }
    return '$ratingToNextTier rating to $nextTierName';
  }

  /// Get demotion warning message
  String? getDemotionWarning() {
    if (!isDemotionRisk) return null;
    return 'Demotion risk: $ratingToPreviousTier rating to $previousTierName';
  }
}

/// Provider for ranking progress ViewModel
final rankingProgressViewModelProvider = StateNotifierProvider.autoDispose<
    RankingProgressViewModel,
    AsyncValue<TierLadderState?>>((ref) {
  // Note: Will be wired with userViewModelProvider for userId/seasonId
  // and currentSeasonViewModelProvider for tierThresholds
  return RankingProgressViewModel(
    rankingService: ref.watch(rankingServiceProvider),
    firestoreService: ref.watch(firestoreServiceProvider),
    userId: null, // TODO: wire from userViewModelProvider
    seasonId: null, // TODO: wire from currentSeasonViewModelProvider
    tierThresholds: null, // TODO: wire from currentSeasonViewModelProvider
  );
});

// Service provider imports needed:
// import 'package:shinjuu_league/data/providers/service_providers.dart';
