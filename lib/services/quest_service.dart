import 'dart:async';
import 'package:shinjuu_league/data/models/quest_model.dart';
import 'package:shinjuu_league/services/firestore_service.dart';

/// Manages quest lifecycle: initialization, progress tracking, completion, rewards
class QuestService {
  final FirestoreService _firestoreService;

  QuestService({required FirestoreService firestoreService})
      : _firestoreService = firestoreService;

  /// Start a quest for a user (initialize PlayerQuest)
  Future<PlayerQuest> startQuest(String userId, String questId) async {
    final quest = QuestCatalog.getById(questId);
    if (quest == null) throw 'Quest not found: $questId';

    final playerQuest = PlayerQuest(
      userId: userId,
      questId: questId,
      conditions: quest.conditions,
      isCompleted: false,
      isRewarded: false,
      startedAt: DateTime.now(),
    );

    // Persist to Firestore
    await _firestoreService.savePlayerQuest(userId, playerQuest);

    return playerQuest;
  }

  /// Update quest progress for a specific condition
  Future<PlayerQuest?> updateQuestProgress(
    String userId,
    String questId,
    QuestConditionType conditionType,
    int newValue, {
    bool isIncrement = false,
  }) async {
    try {
      final playerQuest = await _firestoreService.getPlayerQuest(userId, questId);
      if (playerQuest == null) return null;

      // Update the matching condition
      final updatedConditions = playerQuest.conditions.map((condition) {
        if (condition.type == conditionType) {
          final newCurrent = isIncrement
              ? condition.current + newValue
              : newValue.clamp(0, condition.target);
          return condition.copyWith(current: newCurrent);
        }
        return condition;
      }).toList();

      // Check if quest is now complete
      final isComplete = updatedConditions.every((c) => c.isMet);
      final completedAt = isComplete && !playerQuest.isCompleted
          ? DateTime.now()
          : playerQuest.completedAt;

      final updated = playerQuest.copyWith(
        conditions: updatedConditions,
        isCompleted: isComplete,
        completedAt: completedAt,
      );

      // Persist changes
      await _firestoreService.savePlayerQuest(userId, updated);

      return updated;
    } catch (e) {
      print('Error updating quest progress: $e');
      return null;
    }
  }

  /// Claim reward for a completed quest
  Future<QuestReward?> claimQuestReward(
    String userId,
    String questId,
  ) async {
    try {
      final playerQuest = await _firestoreService.getPlayerQuest(userId, questId);
      if (playerQuest == null || !playerQuest.canClaimReward) return null;

      final quest = QuestCatalog.getById(questId);
      if (quest == null) return null;

      // Mark as rewarded
      final updated = playerQuest.copyWith(
        isRewarded: true,
        claimedRewardAt: DateTime.now(),
      );

      // Persist
      await _firestoreService.savePlayerQuest(userId, updated);

      // Apply rewards
      await _applyQuestReward(userId, quest.reward);

      return quest.reward;
    } catch (e) {
      print('Error claiming quest reward: $e');
      return null;
    }
  }

  /// Apply quest rewards to user
  Future<void> _applyQuestReward(
    String userId,
    QuestReward reward,
  ) async {
    try {
      if (reward.currency > 0) {
        await _firestoreService.incrementUserCurrency(userId, reward.currency);
      }

      if (reward.achievementBadges > 0) {
        await _firestoreService.incrementUserAchievementBadges(
          userId,
          reward.achievementBadges,
        );
      }

      for (final cosmetic in reward.cosmetics) {
        await _firestoreService.addUserCosmetic(userId, cosmetic);
      }

      // TODO: Apply experience points to level progression
    } catch (e) {
      print('Error applying quest reward: $e');
      rethrow;
    }
  }

  /// Get user's active quests for a frequency
  Future<List<PlayerQuest>> getActiveQuests(
    String userId,
    QuestFrequency frequency,
  ) async {
    try {
      final quests = await _firestoreService.getPlayerQuestsByFrequency(
        userId,
        frequency,
      );
      return quests.where((q) => q.isActive).toList();
    } catch (e) {
      print('Error fetching active quests: $e');
      return [];
    }
  }

  /// Get all quests for a user (any state)
  Future<List<PlayerQuest>> getAllQuests(String userId) async {
    try {
      return await _firestoreService.getAllPlayerQuests(userId);
    } catch (e) {
      print('Error fetching all quests: $e');
      return [];
    }
  }

  /// Reset daily quests (called at midnight JST)
  Future<void> resetDailyQuests(String userId) async {
    try {
      final dailyQuests = QuestCatalog.getByFrequency(QuestFrequency.daily);

      for (final quest in dailyQuests) {
        // Check if quest exists and is not completed
        final existing = await _firestoreService.getPlayerQuest(userId, quest.questId);

        if (existing != null) {
          // Reset for new day
          await startQuest(userId, quest.questId);
        }
      }
    } catch (e) {
      print('Error resetting daily quests: $e');
    }
  }

  /// Get quest progress percentage for UI display
  int getQuestProgress(PlayerQuest playerQuest) {
    if (playerQuest.conditions.isEmpty) return 0;
    final total = playerQuest.conditions
        .fold<int>(0, (sum, c) => sum + c.progressPercentage);
    return (total / playerQuest.conditions.length).toInt();
  }

  /// Debug: get all stats for a user's quests
  Future<Map<String, dynamic>> debugGetQuestStats(String userId) async {
    try {
      final allQuests = await getAllQuests(userId);
      final activeCount = allQuests.where((q) => q.isActive).length;
      final completedCount = allQuests.where((q) => q.isCompleted).length;
      final rewardedCount = allQuests.where((q) => q.isRewarded).length;

      return {
        'total': allQuests.length,
        'active': activeCount,
        'completed': completedCount,
        'rewarded': rewardedCount,
        'pending_rewards': allQuests.where((q) => q.canClaimReward).length,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}
