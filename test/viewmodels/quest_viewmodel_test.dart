import 'package:flutter_test/flutter_test.dart';
import 'package:shinjuu_league/data/models/quest_model.dart';
import 'package:shinjuu_league/services/quest_service.dart';
import 'package:shinjuu_league/viewmodels/quest_viewmodel.dart';

void main() {
  group('QuestViewModel', () {
    late QuestViewModel viewModel;
    late MockQuestService mockQuestService;

    const testUserId = 'test_user_123';

    setUp(() {
      mockQuestService = MockQuestService();
      viewModel = QuestViewModel(
        questService: mockQuestService,
        userId: testUserId,
      );
    });

    test('initializes with empty state', () {
      expect(viewModel.state.activeQuests, isEmpty);
      expect(viewModel.state.completedQuests, isEmpty);
      expect(viewModel.state.isLoading, isFalse);
      expect(viewModel.state.error, isNull);
    });

    test('loadQuests sets loading state', () async {
      mockQuestService._allQuests = [];

      final future = viewModel.loadQuests();
      expect(viewModel.state.isLoading, isTrue);

      await future;
      expect(viewModel.state.isLoading, isFalse);
    });

    test('loadQuests separates active and completed quests', () async {
      mockQuestService._allQuests = [
        _createPlayerQuest('daily_win_1', isActive: true, isCompleted: false),
        _createPlayerQuest('daily_damage_1', isActive: false, isCompleted: true),
        _createPlayerQuest('weekly_streak_1', isActive: true, isCompleted: false),
      ];

      await viewModel.loadQuests();

      expect(viewModel.state.allQuests, hasLength(3));
      expect(viewModel.state.activeQuests, hasLength(2));
      expect(viewModel.state.completedQuests, hasLength(1));
    });

    test('loadQuestsByFrequency filters correctly', () async {
      mockQuestService._activeQuestsByFrequency = [
        _createPlayerQuest('daily_win_1'),
        _createPlayerQuest('daily_damage_1'),
      ];

      await viewModel.loadQuestsByFrequency(QuestFrequency.daily);

      expect(viewModel.state.activeQuests, hasLength(2));
    });

    test('startQuest adds new quest to active list', () async {
      mockQuestService._newPlayerQuest = _createPlayerQuest('daily_win_1');

      await viewModel.startQuest('daily_win_1');

      expect(viewModel.state.activeQuests, hasLength(1));
      expect(viewModel.state.allQuests, hasLength(1));
    });

    test('updateQuestProgress updates existing quest', () async {
      const questId = 'daily_win_1';
      final originalQuest = _createPlayerQuest(questId);
      mockQuestService._allQuests = [originalQuest];
      await viewModel.loadQuests();

      final updatedQuest = originalQuest.copyWith(
        conditions: [
          originalQuest.conditions.first.copyWith(current: 2),
        ],
      );
      mockQuestService._updatedQuest = updatedQuest;

      await viewModel.updateQuestProgress(
        questId,
        QuestConditionType.battleCount,
        2,
      );

      final quest = viewModel.getQuestById(questId);
      expect(quest?.conditions.first.current, equals(2));
    });

    test('updateQuestProgress marks quest complete when conditions met', () async {
      const questId = 'daily_win_1';
      final quest = _createPlayerQuest(questId);
      mockQuestService._allQuests = [quest];
      await viewModel.loadQuests();

      final completedQuest = quest.copyWith(
        conditions: [
          quest.conditions.first.copyWith(current: 3),
        ],
        isCompleted: true,
        completedAt: DateTime.now(),
      );
      mockQuestService._updatedQuest = completedQuest;

      await viewModel.updateQuestProgress(
        questId,
        QuestConditionType.battleCount,
        3,
      );

      final updated = viewModel.getQuestById(questId);
      expect(updated?.isCompleted, isTrue);
      expect(updated?.completedAt, isNotNull);
    });

    test('claimQuestReward updates reward totals', () async {
      const questId = 'daily_win_1';
      final quest = _createPlayerQuest(questId, isCompleted: true);
      mockQuestService._allQuests = [quest];
      await viewModel.loadQuests();

      final reward = QuestReward(
        currency: 100,
        experiencePoints: 50,
        achievementBadges: 1,
      );
      mockQuestService._reward = reward;

      final result = await viewModel.claimQuestReward(questId);

      expect(result, isNotNull);
      expect(result!.currency, equals(100));
      expect(viewModel.state.rewardTotals['currency'], equals(100));
      expect(viewModel.state.rewardTotals['badges'], equals(1));
    });

    test('claimQuestReward prevents double-claiming', () async {
      const questId = 'daily_win_1';
      final quest = _createPlayerQuest(questId, isCompleted: true, isRewarded: true);
      mockQuestService._allQuests = [quest];
      await viewModel.loadQuests();

      mockQuestService._reward = null; // Simulate already rewarded

      final result = await viewModel.claimQuestReward(questId);

      expect(result, isNull);
    });

    test('getQuestById returns correct quest', () async {
      const questId = 'daily_win_1';
      final quest = _createPlayerQuest(questId);
      mockQuestService._allQuests = [quest];
      await viewModel.loadQuests();

      final retrieved = viewModel.getQuestById(questId);

      expect(retrieved, isNotNull);
      expect(retrieved!.questId, equals(questId));
    });

    test('getClaimableQuests returns only claimable quests', () async {
      mockQuestService._allQuests = [
        _createPlayerQuest('daily_win_1', isCompleted: true, isRewarded: false),
        _createPlayerQuest('daily_damage_1', isCompleted: false, isRewarded: false),
        _createPlayerQuest('weekly_streak_1', isCompleted: true, isRewarded: true),
      ];

      await viewModel.loadQuests();

      final claimable = viewModel.getClaimableQuests();

      expect(claimable, hasLength(1));
      expect(claimable.first.questId, equals('daily_win_1'));
    });

    test('getQuestProgress calculates percentage correctly', () async {
      const questId = 'daily_win_1';
      final quest = _createPlayerQuest(questId);
      mockQuestService._allQuests = [quest];
      mockQuestService._progressPercentage = 33;
      await viewModel.loadQuests();

      final progress = viewModel.getQuestProgress(questId);

      expect(progress, equals(33));
    });

    test('refresh reloads all quests', () async {
      mockQuestService._allQuests = [];
      await viewModel.loadQuests();
      expect(viewModel.state.allQuests, isEmpty);

      mockQuestService._allQuests = [
        _createPlayerQuest('daily_win_1'),
      ];
      await viewModel.refresh();

      expect(viewModel.state.allQuests, hasLength(1));
    });

    test('loadQuests handles errors gracefully', () async {
      mockQuestService._shouldThrowError = true;

      await viewModel.loadQuests();

      expect(viewModel.state.isLoading, isFalse);
      expect(viewModel.state.error, isNotNull);
      expect(viewModel.state.error, contains('Failed to load quests'));
    });

    test('updateQuestProgress handles errors gracefully', () async {
      mockQuestService._shouldThrowError = true;

      await viewModel.updateQuestProgress(
        'daily_win_1',
        QuestConditionType.battleCount,
        1,
      );

      expect(viewModel.state.error, isNotNull);
      expect(viewModel.state.error, contains('Failed to update quest'));
    });

    test('claimQuestReward handles errors gracefully', () async {
      mockQuestService._shouldThrowError = true;

      final result = await viewModel.claimQuestReward('daily_win_1');

      expect(result, isNull);
      expect(viewModel.state.error, isNotNull);
    });

    test('debugGetQuestStats returns valid structure', () async {
      final stats = await viewModel.debugGetQuestStats();

      expect(stats, isA<Map<String, dynamic>>());
    });

    test('state updates preserve existing data on error', () async {
      mockQuestService._allQuests = [
        _createPlayerQuest('daily_win_1'),
      ];
      await viewModel.loadQuests();

      expect(viewModel.state.allQuests, hasLength(1));

      // Trigger error
      mockQuestService._shouldThrowError = true;
      await viewModel.loadQuests();

      // Original data still intact
      expect(viewModel.state.allQuests, hasLength(1));
    });
  });
}

// Mock implementation
class MockQuestService extends QuestService {
  MockQuestService()
      : super(firestoreService: _MockFirestoreService());

  List<PlayerQuest> _allQuests = [];
  List<PlayerQuest> _activeQuestsByFrequency = [];
  PlayerQuest? _newPlayerQuest;
  PlayerQuest? _updatedQuest;
  QuestReward? _reward;
  int _progressPercentage = 0;
  bool _shouldThrowError = false;

  @override
  Future<List<PlayerQuest>> getAllQuests(String userId) async {
    if (_shouldThrowError) throw Exception('Mock error');
    return _allQuests;
  }

  @override
  Future<List<PlayerQuest>> getActiveQuests(
    String userId,
    QuestFrequency frequency,
  ) async {
    if (_shouldThrowError) throw Exception('Mock error');
    return _activeQuestsByFrequency;
  }

  @override
  Future<PlayerQuest> startQuest(String userId, String questId) async {
    if (_shouldThrowError) throw Exception('Mock error');
    final quest = _newPlayerQuest ??
        PlayerQuest(
          userId: userId,
          questId: questId,
          conditions: [
            const QuestCondition(
              type: QuestConditionType.battleCount,
              target: 3,
            ),
          ],
          isCompleted: false,
          isRewarded: false,
          startedAt: DateTime.now(),
        );
    _allQuests.add(quest);
    return quest;
  }

  @override
  Future<PlayerQuest?> updateQuestProgress(
    String userId,
    String questId,
    QuestConditionType conditionType,
    int newValue, {
    bool isIncrement = false,
  }) async {
    if (_shouldThrowError) throw Exception('Mock error');
    return _updatedQuest;
  }

  @override
  Future<QuestReward?> claimQuestReward(String userId, String questId) async {
    if (_shouldThrowError) throw Exception('Mock error');
    return _reward;
  }

  @override
  int getQuestProgress(PlayerQuest playerQuest) {
    return _progressPercentage;
  }

  @override
  Future<Map<String, dynamic>> debugGetQuestStats(String userId) async {
    if (_shouldThrowError) throw Exception('Mock error');
    return {
      'total': _allQuests.length,
      'active': _allQuests.where((q) => q.isActive).length,
      'completed': _allQuests.where((q) => q.isCompleted).length,
      'rewarded': _allQuests.where((q) => q.isRewarded).length,
      'pending_rewards': _allQuests.where((q) => q.canClaimReward).length,
    };
  }
}

class _MockFirestoreService {
  Future<void> savePlayerQuest(String userId, dynamic playerQuest) async {}
  Future<dynamic> getPlayerQuest(String userId, String questId) async => null;
  Future<List<Map<String, dynamic>>> getAllPlayerQuests(String userId) async => [];
}

PlayerQuest _createPlayerQuest(
  String questId, {
  bool isActive = true,
  bool isCompleted = false,
  bool isRewarded = false,
}) {
  return PlayerQuest(
    userId: 'test_user_123',
    questId: questId,
    conditions: [
      const QuestCondition(
        type: QuestConditionType.battleCount,
        target: 3,
        current: 0,
      ),
    ],
    isCompleted: isCompleted,
    isRewarded: isRewarded,
    startedAt: isActive ? DateTime.now() : null,
    completedAt: isCompleted ? DateTime.now() : null,
  );
}
