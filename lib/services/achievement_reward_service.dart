import 'package:shinjuu_league/data/models/achievement.dart';
import 'package:shinjuu_league/services/firestore_service.dart';

/// Handles reward distribution when achievements are unlocked
/// Manages currency, badges, cosmetics, and other rewards
class AchievementRewardService {
  final FirestoreService _firestoreService;

  AchievementRewardService({
    required FirestoreService firestoreService,
  }) : _firestoreService = firestoreService;

  /// Process unlock and distribute rewards
  /// Returns the total rewards granted
  Future<Map<String, dynamic>> processUnlock(
    String userId,
    Achievement achievement,
  ) async {
    final rewards = _calculateRewards(achievement);

    try {
      // Save achievement unlock to Firestore
      await _firestoreService.markAchievementUnlocked(
        userId,
        achievement.achievementId,
      );

      // Apply currency reward
      if (rewards['currency'] as int > 0) {
        await _applyCurrencyReward(userId, rewards['currency'] as int);
      }

      // Apply badge reward
      if (rewards['badges'] as int > 0) {
        await _applyBadgeReward(userId, rewards['badges'] as int);
      }

      // Apply cosmetic reward
      if (rewards['cosmetics'].isNotEmpty) {
        await _applyCosmeticReward(
          userId,
          rewards['cosmetics'] as List<String>,
        );
      }

      return rewards;
    } catch (e) {
      print('Error processing achievement unlock: $e');
      rethrow;
    }
  }

  /// Calculate rewards for an achievement
  Map<String, dynamic> _calculateRewards(Achievement achievement) {
    return {
      'currency': achievement.getRewardCurrency(),
      'badges': achievement.getRewardBadges(),
      'cosmetics': _getCosmeticsForTier(achievement.rewardTier),
      'tier': achievement.rewardTier.name,
    };
  }

  /// Get cosmetic rewards based on tier
  List<String> _getCosmeticsForTier(AchievementRewardTier tier) {
    switch (tier) {
      case AchievementRewardTier.bronze:
        return [];
      case AchievementRewardTier.silver:
        return ['cosmetic_badge_silver'];
      case AchievementRewardTier.gold:
        return ['cosmetic_badge_gold', 'cosmetic_frame_gold'];
      case AchievementRewardTier.platinum:
        return ['cosmetic_badge_platinum', 'cosmetic_frame_platinum', 'cosmetic_border_platinum'];
    }
  }

  /// Apply currency reward to user
  Future<void> _applyCurrencyReward(String userId, int amount) async {
    try {
      await _firestoreService.incrementUserCurrency(userId, amount);
    } catch (e) {
      print('Error applying currency reward: $e');
    }
  }

  /// Apply badge reward to user
  Future<void> _applyBadgeReward(String userId, int count) async {
    try {
      // Store badge count or add to collection
      await _firestoreService.incrementUserAchievementBadges(userId, count);
    } catch (e) {
      print('Error applying badge reward: $e');
    }
  }

  /// Apply cosmetic reward to user
  Future<void> _applyCosmeticReward(String userId, List<String> cosmetics) async {
    try {
      for (final cosmetic in cosmetics) {
        await _firestoreService.addUserCosmetic(userId, cosmetic);
      }
    } catch (e) {
      print('Error applying cosmetic reward: $e');
    }
  }

  /// Get all pending rewards for a user
  Future<Map<String, dynamic>> getPendingRewards(String userId) async {
    try {
      final userData = await _firestoreService.getUserById(userId);
      if (userData == null) return {};

      return {
        'currency': userData.currency ?? 0,
        'badges': userData.achievementBadges ?? 0,
        'cosmetics': userData.ownedCosmetics ?? [],
      };
    } catch (e) {
      print('Error fetching pending rewards: $e');
      return {};
    }
  }

  /// Debug method to dump reward info
  Map<String, dynamic> debugGetRewardInfo(Achievement achievement) {
    return _calculateRewards(achievement);
  }
}
