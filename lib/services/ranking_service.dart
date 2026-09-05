// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';

/// Service for managing user ranking progression within a season
///
/// Responsibilities:
/// - Detect tier promotions/demotions
/// - Track seasonal stats (wins, losses, streaks)
/// - Manage promotion history
class RankingService {
  final FirebaseFirestore _firestore;

  RankingService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Determine current tier based on rating
  String getTierForRating(
    int rating, {
    Map<String, int>? tierThresholds,
  }) {
    final thresholds = tierThresholds ?? _defaultTierThresholds();

    // Sort tiers by rating (descending)
    final sortedTiers = thresholds.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (final entry in sortedTiers) {
      if (rating >= entry.value) {
        return entry.key;
      }
    }

    return 'Bronze'; // Fallback
  }

  /// Check if a tier promotion/demotion occurred
  PromotionStatus checkPromotionStatus({
    required int currentRating,
    required int previousRating,
    required String currentTier,
    required String previousTier,
    required Map<String, int>? tierThresholds,
  }) {
    if (currentTier == previousTier) {
      return PromotionStatus.none;
    }

    // Determine if it's promotion or demotion based on tier thresholds
    final thresholds = tierThresholds ?? _defaultTierThresholds();
    final currentThreshold = thresholds[currentTier] ?? 400;
    final previousThreshold = thresholds[previousTier] ?? 400;

    if (currentThreshold > previousThreshold) {
      return PromotionStatus.promoted;
    } else {
      return PromotionStatus.demoted;
    }
  }

  /// Update user seasonal data after a battle
  ///
  /// Tracks wins/losses, streaks, tier changes, and promotion history
  Future<void> updateSeasonalProgress({
    required String userId,
    required String seasonId,
    required int newRating,
    required bool isWin,
    required Map<String, int>? tierThresholds,
  }) async {
    try {
      final userSeasonPath =
          'users/$userId/season_data/$seasonId';
      final userSeasonRef = _firestore.doc(userSeasonPath);
      final userSeasonSnapshot = await userSeasonRef.get();

      // Fetch current tier info
      final newTier = getTierForRating(newRating, tierThresholds: tierThresholds);

      if (!userSeasonSnapshot.exists) {
        // First battle of season - initialize
        await userSeasonRef.set({
          'userId': userId,
          'seasonId': seasonId,
          'startingRating': newRating,
          'peakRating': newRating,
          'currentRating': newRating,
          'currentTier': newTier,
          'previousTier': newTier,
          'peakTier': newTier,
          'tierTransitions': [],
          'seasonWins': isWin ? 1 : 0,
          'seasonLosses': isWin ? 0 : 1,
          'seasonDraws': 0,
          'promotionCount': 0,
          'demotionCount': 0,
          'longestWinStreak': isWin ? 1 : 0,
          'currentWinStreak': isWin ? 1 : 0,
          'earnedRewards': [],
          'rewardsClaimed': false,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        print('[RankingService] Initialized season data for $userId in $seasonId');
      } else {
        // Existing season data - update
        final data = userSeasonSnapshot.data() as Map<String, dynamic>;
        final previousTier = data['currentTier'] as String? ?? 'Bronze';
        final previousRating = data['currentRating'] as int? ?? 1200;
        final currentWinStreak = data['currentWinStreak'] as int? ?? 0;
        final longestWinStreak = data['longestWinStreak'] as int? ?? 0;

        // Calculate new streaks
        final newWinStreak = isWin ? currentWinStreak + 1 : 0;
        final newLongestStreak = isWin
            ? (newWinStreak > longestWinStreak ? newWinStreak : longestWinStreak)
            : longestWinStreak;

        // Check for tier change
        final promotionStatus = checkPromotionStatus(
          currentRating: newRating,
          previousRating: previousRating,
          currentTier: newTier,
          previousTier: previousTier,
          tierThresholds: tierThresholds,
        );

        List<dynamic> tierTransitions =
            (data['tierTransitions'] as List<dynamic>?) ?? [];
        int promotionCount = data['promotionCount'] as int? ?? 0;
        int demotionCount = data['demotionCount'] as int? ?? 0;

        if (promotionStatus == PromotionStatus.promoted) {
          tierTransitions.add({
            'timestamp': FieldValue.serverTimestamp(),
            'fromTier': previousTier,
            'toTier': newTier,
            'ratingAtTransition': newRating,
            'transitionType': 'promotion',
          });
          promotionCount++;
        } else if (promotionStatus == PromotionStatus.demoted) {
          tierTransitions.add({
            'timestamp': FieldValue.serverTimestamp(),
            'fromTier': previousTier,
            'toTier': newTier,
            'ratingAtTransition': newRating,
            'transitionType': 'demotion',
          });
          demotionCount++;
        }

        // Determine peak tier
        final peakTier = data['peakTier'] as String? ?? 'Bronze';
        final peakThreshold =
            tierThresholds?[peakTier] ?? _defaultTierThresholds()[peakTier] ?? 400;
        final newThreshold =
            tierThresholds?[newTier] ?? _defaultTierThresholds()[newTier] ?? 400;
        final shouldUpdatePeak = newThreshold > peakThreshold;

        await userSeasonRef.update({
          'currentRating': newRating,
          'peakRating': newRating > (data['peakRating'] as int? ?? 1200)
              ? newRating
              : data['peakRating'],
          'currentTier': newTier,
          'previousTier': previousTier,
          'peakTier': shouldUpdatePeak ? newTier : peakTier,
          'tierTransitions': tierTransitions,
          'seasonWins': (data['seasonWins'] as int? ?? 0) + (isWin ? 1 : 0),
          'seasonLosses': (data['seasonLosses'] as int? ?? 0) + (isWin ? 0 : 1),
          'promotionCount': promotionCount,
          'demotionCount': demotionCount,
          'longestWinStreak': newLongestStreak,
          'currentWinStreak': newWinStreak,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        print(
          '[RankingService] Updated $userId: $newRating rating, '
          'streak=$newWinStreak, tier=$newTier',
        );
      }
    } catch (e) {
      print('[RankingService] Error updating seasonal progress: $e');
      rethrow;
    }
  }

  /// Get user's seasonal data
  Future<Map<String, dynamic>?> getSeasonalData(
    String userId,
    String seasonId,
  ) async {
    try {
      final doc = await _firestore
          .doc('users/$userId/season_data/$seasonId')
          .get();

      return doc.exists ? doc.data() : null;
    } catch (e) {
      print('[RankingService] Error fetching seasonal data: $e');
      return null;
    }
  }

  /// Get user's promotion history for season
  Future<List<Map<String, dynamic>>> getPromotionHistory(
    String userId,
    String seasonId,
  ) async {
    try {
      final seasonalData = await getSeasonalData(userId, seasonId);
      if (seasonalData == null) return [];

      final transitions = seasonalData['tierTransitions'] as List<dynamic>? ?? [];
      return transitions.cast<Map<String, dynamic>>();
    } catch (e) {
      print('[RankingService] Error fetching promotion history: $e');
      return [];
    }
  }

  /// Calculate seasonal win rate
  double calculateWinRate({
    required int wins,
    required int losses,
    required int draws,
  }) {
    final total = wins + losses + draws;
    if (total == 0) return 0.0;
    return wins / total;
  }

  /// Get default tier thresholds
  Map<String, int> _defaultTierThresholds() {
    return {
      'Bronze': 400,
      'Silver': 1400,
      'Gold': 1800,
      'Platinum': 2200,
      'Legend': 2800,
    };
  }
}

/// Enum for promotion status
enum PromotionStatus {
  promoted,
  demoted,
  none,
}
