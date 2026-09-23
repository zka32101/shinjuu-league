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

  QuestViewModel({required QuestService questService, required String userId})
    : _questService = questService,
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

      state = state.copyWith(activeQuests: quests, isLoading: false);
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
            ? [
                    ...state.completedQuests,
                    updated,
                  ].where((q) => q.questId != questId).toList() +
                  [updated]
            : state.completedQuests;

        // allQuests is a separate field from activeQuests/completedQuests
        // (see loadQuests()) and getQuestById()/getClaimableQuests() read
        // from it directly - without updating it here too, they'd keep
        // returning the stale pre-update quest even though
        // activeQuests/completedQuests were already correct.
        final updatedAll = state.allQuests.map((q) {
          return q.questId == questId ? updated : q;
        }).toList();

        state = state.copyWith(
          activeQuests: updatedActive,
          completedQuests: newCompleted,
          allQuests: updatedAll,
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
        // Update quest to mark as rewarded. A claimable quest is normally a
        // completed one (see PlayerQuest.canClaimReward), so it typically
        // lives in completedQuests rather than activeQuests - update both
        // (plus allQuests, read directly by getQuestById()/
        // getClaimableQuests()) so whichever list actually holds it, and
        // every reader, sees the rewarded flag.
        PlayerQuest markRewarded(PlayerQuest q) =>
            q.questId == questId ? q.copyWith(isRewarded: true) : q;

        final updatedActive = state.activeQuests.map(markRewarded).toList();
        final updatedCompleted = state.completedQuests
            .map(markRewarded)
            .toList();
        final updatedAll = state.allQuests.map(markRewarded).toList();

        // Update totals
        final newTotals = {
          'currency': (state.rewardTotals['currency'] ?? 0) + reward.currency,
          'badges':
              (state.rewardTotals['badges'] ?? 0) + reward.achievementBadges,
        };

        state = state.copyWith(
          activeQuests: updatedActive,
          completedQuests: updatedCompleted,
          allQuests: updatedAll,
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

/// Riverpod provider for QuestViewModel, keyed by the real signed-in user's
/// ID (mirrors achievementViewModelProvider's family-over-userId pattern).
/// This used to construct with a hardcoded 'placeholder_user_id' and read
/// the current user from `ref.watch(userViewModelProvider)` internally -
/// both wrong (every quest read/write went to a Firestore doc no real
/// player's data ever lived in) and, for the second attempt, impossible to
/// build in a widget test without Firebase.initializeApp() (userViewModelProvider
/// eagerly touches FirebaseAuth). The caller now resolves and passes the
/// user ID instead (see QuestsScreen._resolveCurrentUserId()).
final questViewModelProvider = StateNotifierProvider.family
    .autoDispose<QuestViewModel, QuestState, String>((ref, userId) {
      final questService = ref.watch(questServiceProvider);
      return QuestViewModel(questService: questService, userId: userId);
    });
