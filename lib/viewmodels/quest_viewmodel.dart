import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shinjuu_league/data/models/quest_model.dart';
import 'package:shinjuu_league/services/quest_service.dart';
import 'package:shinjuu_league/data/providers/service_providers.dart';

/// State for quest management
class QuestState {
  final List<PlayerQuest> activeQuests;
  final List<PlayerQuest> completedQuests;
  final List<PlayerQuest> allQuests;
  final bool isLoading;
  final String? error;
  final Map<String, int> rewardTotals; // {currency, badges}

  QuestState({
    this.activeQuests = const [],
    this.completedQuests = const [],
    this.allQuests = const [],
    this.isLoading = false,
    this.error,
    this.rewardTotals = const {},
  });

  QuestState copyWith({
    List<PlayerQuest>? activeQuests,
    List<PlayerQuest>? completedQuests,
    List<PlayerQuest>? allQuests,
    bool? isLoading,
    String? error,
    Map<String, int>? rewardTotals,
  }) {
    return QuestState(
      activeQuests: activeQuests ?? this.activeQuests,
      completedQuests: completedQuests ?? this.completedQuests,
      allQuests: allQuests ?? this.allQuests,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      rewardTotals: rewardTotals ?? this.rewardTotals,
    );
  }
}

/// ViewModel for managing user quests
class QuestViewModel extends StateNotifier<QuestState> {
  final QuestService _questService;
  final String _userId;

  QuestViewModel({
    required QuestService questService,
    required String userId,
  })  : _questService = questService,
        _userId = userId,
        super(QuestState());

  /// Load all quests for user
  Future<void> loadQuests() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final allQuests = await _questService.getAllQuests(_userId);
      final activeQuests = allQuests.where((q) => q.isActive).toList();
      final completedQuests = allQuests.where((q) => q.isCompleted).toList();

      state = state.copyWith(
        allQuests: allQuests,
        activeQuests: activeQuests,
        completedQuests: completedQuests,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load quests: $e',
      );
    }
  }

  /// Load quests by frequency
  Future<void> loadQuestsByFrequency(QuestFrequency frequency) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final quests = await _questService.getActiveQuests(_userId, frequency);

      state = state.copyWith(
        activeQuests: quests,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load quests: $e',
      );
    }
  }

  /// Start a new quest
  Future<void> startQuest(String questId) async {
    try {
      final playerQuest = await _questService.startQuest(_userId, questId);

      final updatedActive = [...state.activeQuests, playerQuest];
      state = state.copyWith(
        activeQuests: updatedActive,
        allQuests: [...state.allQuests, playerQuest],
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to start quest: $e');
    }
  }

  /// Update progress for a quest condition
  Future<void> updateQuestProgress(
    String questId,
    QuestConditionType conditionType,
    int newValue, {
    bool isIncrement = false,
  }) async {
    try {
      state = state.copyWith(error: null);

      final updated = await _questService.updateQuestProgress(
        _userId,
        questId,
        conditionType,
        newValue,
        isIncrement: isIncrement,
      );

      if (updated != null) {
        // Update in activeQuests
        final updatedActive = state.activeQuests.map((q) {
          return q.questId == questId ? updated : q;
        }).toList();

        // If completed, move to completed
        final newCompleted = updated.isCompleted
            ? [...state.completedQuests, updated]
                .where((q) => q.questId != questId)
                .toList() +
                [updated]
            : state.completedQuests;

        state = state.copyWith(
          activeQuests: updatedActive,
          completedQuests: newCompleted,
        );
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to update quest: $e');
    }
  }

  /// Claim reward for completed quest
  Future<QuestReward?> claimQuestReward(String questId) async {
    try {
      state = state.copyWith(error: null);

      final reward = await _questService.claimQuestReward(_userId, questId);

      if (reward != null) {
        // Update quest to mark as rewarded
        final updatedActive = state.activeQuests.map((q) {
          if (q.questId == questId) {
            return q.copyWith(isRewarded: true);
          }
          return q;
        }).toList();

        // Update totals
        final newTotals = {
          'currency': (state.rewardTotals['currency'] ?? 0) + reward.currency,
          'badges': (state.rewardTotals['badges'] ?? 0) + reward.achievementBadges,
        };

        state = state.copyWith(
          activeQuests: updatedActive,
          rewardTotals: newTotals,
        );
      }

      return reward;
    } catch (e) {
      state = state.copyWith(error: 'Failed to claim reward: $e');
      return null;
    }
  }

  /// Get quest by ID
  PlayerQuest? getQuestById(String questId) {
    try {
      return state.allQuests.firstWhere((q) => q.questId == questId);
    } catch (e) {
      return null;
    }
  }

  /// Get quests claimable for reward
  List<PlayerQuest> getClaimableQuests() {
    return state.allQuests.where((q) => q.canClaimReward).toList();
  }

  /// Get quest progress percentage
  int getQuestProgress(String questId) {
    final quest = getQuestById(questId);
    if (quest == null) return 0;
    return _questService.getQuestProgress(quest);
  }

  /// Refresh all quests from server
  Future<void> refresh() async {
    await loadQuests();
  }

  /// Debug: get quest stats
  Future<Map<String, dynamic>> debugGetQuestStats() async {
    try {
      return await _questService.debugGetQuestStats(_userId);
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}

/// Riverpod provider for QuestViewModel (autoDispose per user session)
final questViewModelProvider =
    StateNotifierProvider.autoDispose<QuestViewModel, QuestState>((ref) {
  // This will need userId from auth provider
  // For now, use placeholder - should be injected from AuthService
  const userId = 'placeholder_user_id';

  final questService = ref.watch(questServiceProvider);
  return QuestViewModel(
    questService: questService,
    userId: userId,
  );
});

/// Provider to get active quests only
final activeQuestsProvider = Provider.autoDispose<List<PlayerQuest>>((ref) {
  final state = ref.watch(questViewModelProvider);
  return state.activeQuests;
});

/// Provider to get completed quests only
final completedQuestsProvider = Provider.autoDispose<List<PlayerQuest>>((ref) {
  final state = ref.watch(questViewModelProvider);
  return state.completedQuests;
});

/// Provider to get claimable quests (completed but not rewarded)
final claimableQuestsProvider = Provider.autoDispose<List<PlayerQuest>>((ref) {
  final state = ref.watch(questViewModelProvider);
  return state.allQuests.where((q) => q.canClaimReward).toList();
});

/// Provider to get reward totals from this session
final questRewardTotalsProvider =
    Provider.autoDispose<Map<String, int>>((ref) {
  final state = ref.watch(questViewModelProvider);
  return state.rewardTotals;
});
