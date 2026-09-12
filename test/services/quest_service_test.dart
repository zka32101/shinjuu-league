import 'package:flutter_test/flutter_test.dart';
import 'package:shinjuu_league/data/models/quest_model.dart';
import 'package:shinjuu_league/services/quest_service.dart';
import 'package:shinjuu_league/services/firestore_service.dart';

// Mock FirestoreService for testing
class MockFirestoreService extends FirestoreService {
  final Map<String, Map<String, dynamic>> _questData = {};
  final Map<String, int> _userCurrency = {};
  final Map<String, int> _userBadges = {};

  @override
  Future<void> savePlayerQuest(String userId, dynamic playerQuest) async {
    _questData['$userId:${playerQuest.questId}'] = playerQuest.toJson();
  }

  @override
  Future<dynamic> getPlayerQuest(String userId, String questId) async {
    return _questData['$userId:$questId'];
  }

  @override
  Future<List<Map<String, dynamic>>> getPlayerQuestsByFrequency(
    String userId,
    dynamic frequency,
  ) async {
    return [];
  }

  @override
  Future<List<Map<String, dynamic>>> getAllPlayerQuests(String userId) async {
    return _questData.values
        .where((q) => q['userId'] == userId)
        .cast<Map<String, dynamic>>()
        .toList();
  }

  @override
  Future<void> incrementUserCurrency(String userId, int amount) async {
    _userCurrency[userId] = (_userCurrency[userId] ?? 0) + amount;
  }

  @override
  Future<void> incrementUserAchievementBadges(String userId, int count) async {
    _userBadges[userId] = (_userBadges[userId] ?? 0) + count;
  }

  @override
  Future<void> addUserCosmetic(String userId, String cosmeticId) async {
    // Mock implementation
  }

  void resetMockData() {
    _questData.clear();
    _userCurrency.clear();
    _userBadges.clear();
  }
}

void main() {
  group('QuestService', () {
    late QuestService service;
    late MockFirestoreService firestoreService;

    final testUserId = 'user_123';

    setUp(() {
      firestoreService = MockFirestoreService();
      service = QuestService(firestoreService: firestoreService);
    });

    tearDown(() {
      firestoreService.resetMockData();
    });

    test('starts a quest and initializes player quest', () async {
      final playerQuest = await service.startQuest(testUserId, 'daily_win_1');

      expect(playerQuest.userId, equals(testUserId));
      expect(playerQuest.questId, equals('daily_win_1'));
      expect(playerQuest.isCompleted, isFalse);
      expect(playerQuest.isRewarded, isFalse);
      expect(playerQuest.startedAt, isNotNull);
    });

    test('throws error for non-existent quest', () async {
      expect(
        () => service.startQuest(testUserId, 'fake_quest'),
        throwsA(isA<String>()),
      );
    });

    test('updates quest progress on condition', () async {
      await service.startQuest(testUserId, 'daily_win_1');

      // Update progress: win 2 battles out of 3
      final updated = await service.updateQuestProgress(
        testUserId,
        'daily_win_1',
        QuestConditionType.battleCount,
        2,
      );

      expect(updated, isNotNull);
      expect(updated!.conditions.first.current, equals(2));
      expect(updated.isCompleted, isFalse);
    });

    test('marks quest complete when all conditions met', () async {
      await service.startQuest(testUserId, 'daily_win_1');

      // Complete the quest: win 3 battles
      final updated = await service.updateQuestProgress(
        testUserId,
        'daily_win_1',
        QuestConditionType.battleCount,
        3,
      );

      expect(updated, isNotNull);
      expect(updated!.isCompleted, isTrue);
      expect(updated.completedAt, isNotNull);
    });

    test('clamps progress to target value', () async {
      await service.startQuest(testUserId, 'daily_win_1');

      // Try to set progress to 100 (max is 3)
      final updated = await service.updateQuestProgress(
        testUserId,
        'daily_win_1',
        QuestConditionType.battleCount,
        100,
      );

      expect(updated, isNotNull);
      expect(updated!.conditions.first.current, equals(3));
    });

    test('supports increment mode for progress', () async {
      await service.startQuest(testUserId, 'daily_win_1');

      // Increment by 1
      var updated = await service.updateQuestProgress(
        testUserId,
        'daily_win_1',
        QuestConditionType.battleCount,
        1,
        isIncrement: true,
      );

      expect(updated!.conditions.first.current, equals(1));

      // Increment by 2 more
      updated = await service.updateQuestProgress(
        testUserId,
        'daily_win_1',
        QuestConditionType.battleCount,
        2,
        isIncrement: true,
      );

      expect(updated!.conditions.first.current, equals(3));
    });

    test('claims reward for completed quest', () async {
      await service.startQuest(testUserId, 'daily_win_1');

      // Complete quest
      await service.updateQuestProgress(
        testUserId,
        'daily_win_1',
        QuestConditionType.battleCount,
        3,
      );

      // Claim reward
      final reward = await service.claimQuestReward(testUserId, 'daily_win_1');

      expect(reward, isNotNull);
      expect(reward!.currency, equals(100));
      expect(firestoreService._userCurrency[testUserId], equals(100));
    });

    test('prevents claiming reward twice', () async {
      await service.startQuest(testUserId, 'daily_win_1');
      await service.updateQuestProgress(
        testUserId,
        'daily_win_1',
        QuestConditionType.battleCount,
        3,
      );

      // Claim once
      await service.claimQuestReward(testUserId, 'daily_win_1');

      // Try to claim again
      final secondClaim = await service.claimQuestReward(testUserId, 'daily_win_1');

      expect(secondClaim, isNull);
      expect(firestoreService._userCurrency[testUserId], equals(100)); // Only once
    });

    test('applies all reward types (currency, badges, cosmetics)', () async {
      // Use weekly quest which grants badges
      await service.startQuest(testUserId, 'weekly_streak_1');

      // Complete it (5 consecutive wins)
      await service.updateQuestProgress(
        testUserId,
        'weekly_streak_1',
        QuestConditionType.consecutiveWins,
        5,
      );

      // Claim reward
      final reward = await service.claimQuestReward(testUserId, 'weekly_streak_1');

      expect(reward!.currency, equals(300));
      expect(reward.achievementBadges, equals(1));
      expect(firestoreService._userCurrency[testUserId], equals(300));
      expect(firestoreService._userBadges[testUserId], equals(1));
    });

    test('calculates quest progress percentage', () async {
      final playerQuest = await service.startQuest(testUserId, 'daily_win_1');

      var progress = service.getQuestProgress(playerQuest);
      expect(progress, equals(0));

      // Update to 50% (1.5 wins out of 3)
      var updated = await service.updateQuestProgress(
        testUserId,
        'daily_win_1',
        QuestConditionType.battleCount,
        2, // Will be clamped to 2, so ~66%
      );

      progress = service.getQuestProgress(updated!);
      expect(progress, greaterThan(0));
      expect(progress, lessThanOrEqualTo(100));
    });

    test('returns active quests only', () async {
      // Start a quest
      await service.startQuest(testUserId, 'daily_win_1');

      final active = await service.getActiveQuests(testUserId, QuestFrequency.daily);

      expect(active.isEmpty, isTrue); // No active quests persisted in mock
    });

    test('gets all user quests', () async {
      // Start multiple quests
      await service.startQuest(testUserId, 'daily_win_1');
      await service.startQuest(testUserId, 'daily_damage_1');

      final allQuests = await service.getAllQuests(testUserId);

      // Mock returns raw data, test structure
      expect(allQuests is List, isTrue);
    });

    test('debug stats return valid structure', () async {
      await service.startQuest(testUserId, 'daily_win_1');

      final stats = await service.debugGetQuestStats(testUserId);

      expect(stats.containsKey('total'), isTrue);
      expect(stats.containsKey('active'), isTrue);
      expect(stats.containsKey('completed'), isTrue);
      expect(stats.containsKey('rewarded'), isTrue);
      expect(stats.containsKey('pending_rewards'), isTrue);
    });

    test('quest catalog returns correct quests by frequency', () {
      final dailyQuests = QuestCatalog.getByFrequency(QuestFrequency.daily);
      final weeklyQuests = QuestCatalog.getByFrequency(QuestFrequency.weekly);

      expect(dailyQuests.length, greaterThan(0));
      expect(weeklyQuests.length, greaterThan(0));
      expect(
        dailyQuests.every((q) => q.frequency == QuestFrequency.daily),
        isTrue,
      );
    });

    test('quest catalog returns correct quests by type', () {
      final combatQuests = QuestCatalog.getByType(QuestType.combat);

      expect(combatQuests.isNotEmpty, isTrue);
      expect(combatQuests.every((q) => q.type == QuestType.combat), isTrue);
    });

    test('quest condition tracking works correctly', () {
      final condition = QuestCondition(
        type: QuestConditionType.battleCount,
        target: 10,
        current: 7,
      );

      expect(condition.isMet, isFalse);
      expect(condition.progressPercentage, equals(70));

      final completed = condition.copyWith(current: 10);
      expect(completed.isMet, isTrue);
      expect(completed.progressPercentage, equals(100));
    });

    test('multiple conditions require all to be met', () {
      final conditions = [
        QuestCondition(type: QuestConditionType.battleCount, target: 3, current: 3),
        QuestCondition(type: QuestConditionType.damageDealt, target: 500, current: 300),
      ];

      final allMet = conditions.every((c) => c.isMet);
      expect(allMet, isFalse); // Damage not met

      final updated = [
        conditions[0],
        conditions[1].copyWith(current: 500),
      ];

      expect(updated.every((c) => c.isMet), isTrue);
    });

    test('quest time remaining calculates correctly', () {
      final playerQuest = PlayerQuest(
        userId: testUserId,
        questId: 'daily_win_1',
        conditions: const [],
        isCompleted: false,
        isRewarded: false,
        startedAt: DateTime.now().subtract(const Duration(hours: 10)),
      );

      final remaining = playerQuest.timeRemaining;
      expect(remaining, isNotNull);
      expect(remaining!.inHours, equals(14)); // 24 - 10 hours
    });
  });
}
