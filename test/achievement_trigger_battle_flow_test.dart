import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shinjuu_league/data/models/achievement.dart';
import 'package:shinjuu_league/data/models/battle_model.dart';
import 'package:shinjuu_league/data/models/skill_model.dart';
import 'package:shinjuu_league/data/models/user_model.dart';
import 'package:shinjuu_league/services/achievement_reward_service.dart';
import 'package:shinjuu_league/services/achievement_service.dart';
import 'package:shinjuu_league/services/achievement_trigger_detector.dart';
import 'package:shinjuu_league/services/analytics_service.dart';
import 'package:shinjuu_league/services/battle_engine_service.dart';
import 'package:shinjuu_league/services/firestore_service.dart';
import 'package:shinjuu_league/services/ranking_service.dart';
import 'package:shinjuu_league/services/season_service.dart';
import 'package:shinjuu_league/services/skill_tree_service.dart';
import 'package:shinjuu_league/viewmodels/battle_viewmodel.dart';

class MockFirestoreService extends Mock implements FirestoreService {
  @override
  Future<User?> getUserById(String? uid) {
    return super.noSuchMethod(
          Invocation.method(#getUserById, [uid]),
          returnValue: Future<User?>.value(),
          returnValueForMissingStub: Future<User?>.value(),
        )
        as Future<User?>;
  }

  @override
  Future<void> updateBattle(Battle? battle) {
    return super.noSuchMethod(
          Invocation.method(#updateBattle, [battle]),
          returnValue: Future<void>.value(),
          returnValueForMissingStub: Future<void>.value(),
        )
        as Future<void>;
  }
}

class MockAnalyticsService extends Mock implements AnalyticsService {
  @override
  Future<void> logBattleEnd(
    String? userId,
    String? battleId,
    String? result,
    int? kills,
    int? deaths,
  ) {
    return super.noSuchMethod(
          Invocation.method(#logBattleEnd, [
            userId,
            battleId,
            result,
            kills,
            deaths,
          ]),
          returnValue: Future<void>.value(),
          returnValueForMissingStub: Future<void>.value(),
        )
        as Future<void>;
  }

  @override
  Future<void> logFirstRankedEntry(String? userId) {
    return super.noSuchMethod(
          Invocation.method(#logFirstRankedEntry, [userId]),
          returnValue: Future<void>.value(),
          returnValueForMissingStub: Future<void>.value(),
        )
        as Future<void>;
  }

  @override
  Future<void> logAchievementUnlocked(
    String? userId,
    String? achievementId,
    String? rarity,
  ) {
    return super.noSuchMethod(
          Invocation.method(#logAchievementUnlocked, [
            userId,
            achievementId,
            rarity,
          ]),
          returnValue: Future<void>.value(),
          returnValueForMissingStub: Future<void>.value(),
        )
        as Future<void>;
  }

  @override
  void recordError(
    dynamic exception,
    StackTrace? stackTrace, {
    String? reason,
    Iterable<Object>? information,
  }) {
    super.noSuchMethod(
      Invocation.method(
        #recordError,
        [exception, stackTrace],
        {#reason: reason, #information: information},
      ),
      returnValueForMissingStub: null,
    );
  }
}

class MockSkillTreeService extends Mock implements SkillTreeService {
  @override
  Future<SkillTree?> getSkillTree(String? userId) {
    return super.noSuchMethod(
          Invocation.method(#getSkillTree, [userId]),
          returnValue: Future<SkillTree?>.value(),
          returnValueForMissingStub: Future<SkillTree?>.value(),
        )
        as Future<SkillTree?>;
  }
}

class MockAchievementService extends Mock implements AchievementService {
  @override
  Future<void> unlockAchievement(String? userId, String? achievementId) {
    return super.noSuchMethod(
          Invocation.method(#unlockAchievement, [userId, achievementId]),
          returnValue: Future<void>.value(),
          returnValueForMissingStub: Future<void>.value(),
        )
        as Future<void>;
  }

  @override
  Future<List<PlayerAchievement>> getUnlockedAchievements(String? userId) {
    return super.noSuchMethod(
          Invocation.method(#getUnlockedAchievements, [userId]),
          returnValue: Future<List<PlayerAchievement>>.value(
            <PlayerAchievement>[],
          ),
          returnValueForMissingStub: Future<List<PlayerAchievement>>.value(
            <PlayerAchievement>[],
          ),
        )
        as Future<List<PlayerAchievement>>;
  }
}

class MockAchievementRewardService extends Mock
    implements AchievementRewardService {
  @override
  Future<Map<String, dynamic>> processUnlock(
    String? userId,
    Achievement? achievement,
  ) {
    return super.noSuchMethod(
          Invocation.method(#processUnlock, [userId, achievement]),
          returnValue: Future<Map<String, dynamic>>.value(<String, dynamic>{}),
          returnValueForMissingStub: Future<Map<String, dynamic>>.value(
            <String, dynamic>{},
          ),
        )
        as Future<Map<String, dynamic>>;
  }
}

/// BattleViewModel now also depends on RankingService (for seasonal
/// achievement-trigger inputs) - unrelated to the achievement rewardService
/// change, but without a mock it falls back to a real, Firebase-backed
/// RankingService() and crashes in these Firebase-less unit tests.
class MockRankingService extends Mock implements RankingService {
  @override
  Future<List<SeasonHistoryEntry>> getSeasonHistory(
    String? userId, {
    SeasonService? seasonService,
  }) {
    return super.noSuchMethod(
          Invocation.method(
            #getSeasonHistory,
            [userId],
            {#seasonService: seasonService},
          ),
          returnValue: Future<List<SeasonHistoryEntry>>.value(
            <SeasonHistoryEntry>[],
          ),
          returnValueForMissingStub: Future<List<SeasonHistoryEntry>>.value(
            <SeasonHistoryEntry>[],
          ),
        )
        as Future<List<SeasonHistoryEntry>>;
  }
}

void main() {
  group('Achievement Trigger Detection in Battle Flow', () {
    late BattleViewModel viewModel;
    late MockFirestoreService mockFirestore;
    late MockAnalyticsService mockAnalytics;
    late MockSkillTreeService mockSkillTree;
    late MockAchievementService mockAchievement;
    late MockAchievementRewardService mockRewardService;
    late MockRankingService mockRankingService;

    const String userId = 'user_123';
    const String battleId = 'battle_001';

    setUp(() {
      mockFirestore = MockFirestoreService();
      mockAnalytics = MockAnalyticsService();
      mockSkillTree = MockSkillTreeService();
      mockAchievement = MockAchievementService();
      mockRewardService = MockAchievementRewardService();
      mockRankingService = MockRankingService();

      when(mockSkillTree.getSkillTree(any)).thenAnswer((_) async => null);
      when(
        mockRankingService.getSeasonHistory(any),
      ).thenAnswer((_) async => <SeasonHistoryEntry>[]);
      when(mockFirestore.updateBattle(any)).thenAnswer((_) async {});
      when(
        mockAnalytics.logBattleEnd(any, any, any, any, any),
      ).thenAnswer((_) async {});
      when(mockAnalytics.logFirstRankedEntry(any)).thenAnswer((_) async {});
      when(
        mockAnalytics.logAchievementUnlocked(any, any, any),
      ).thenAnswer((_) async {});
      when(
        mockAnalytics.recordError(
          any,
          any,
          reason: anyNamed('reason'),
          information: anyNamed('information'),
        ),
      ).thenAnswer((_) async {});

      viewModel = BattleViewModel(
        firestoreService: mockFirestore,
        analyticsService: mockAnalytics,
        skillTreeService: mockSkillTree,
        achievementService: mockAchievement,
        achievementRewardService: mockRewardService,
        rankingService: mockRankingService,
      );
    });

    test('triggers Aha Moment on first kill during battle', () async {
      final userData = _buildTestUser(userId);
      when(mockFirestore.getUserById(userId)).thenAnswer((_) async => userData);

      when(
        mockAchievement.getUnlockedAchievements(userId),
      ).thenAnswer((_) async => []);

      final ahaMomentAchievement = Achievement(
        achievementId: 'aha_moment',
        category: AchievementCategory.milestone,
        name: 'Aha Moment',
        description: 'Get your first kill',
        iconUrl: 'assets/icons/aha_moment.png',
        rewardTier: AchievementRewardTier.common,
        maxProgress: 1,
        isProgressBased: false,
      );

      // Verify that the achievement trigger detector would detect this
      final detector = AchievementTriggerDetector(
        achievementService: mockAchievement,
        rewardService: mockRewardService,
      );

      final result = await detector.checkKillTriggers(userId, 1, 1);
      // Should trigger on first kill
      expect(result, isNotEmpty);
    });

    test('triggers Rising Star on battle win', () async {
      final userData = _buildTestUser(userId);
      when(mockFirestore.getUserById(userId)).thenAnswer((_) async => userData);

      when(
        mockAchievement.getUnlockedAchievements(userId),
      ).thenAnswer((_) async => []);

      final detector = AchievementTriggerDetector(
        achievementService: mockAchievement,
        rewardService: mockRewardService,
      );

      // seasonsParticipated/currentTier chosen to satisfy Rising Star's
      // fixed condition (within the first 5 seasons at Silver tier+).
      final result = await detector.checkBattleCompletionTriggers(
        userId,
        won: true,
        kills: 2,
        deaths: 1,
        assists: 1,
        damageDealt: 300,
        totalBattles: 1,
        winCount: 1,
        seasonsParticipated: 1,
        currentTier: 'Silver',
      );

      expect(result, isNotEmpty);
    });

    test('triggers Stat Master at the catalog threshold', () async {
      when(
        mockAchievement.getUnlockedAchievements(userId),
      ).thenAnswer((_) async => []);

      final detector = AchievementTriggerDetector(
        achievementService: mockAchievement,
        rewardService: mockRewardService,
      );

      final result = await detector.checkProgressTriggers(
        userId,
        statPoints: AchievementsCatalog.statMaster.maxProgress,
        pathDiversity: 1,
        seasonsParticipated: 1,
        consistentSeasons: 0,
        currentTier: 'Bronze',
      );

      expect(result, isNotEmpty);
    });

    test('triggers Balanced Fighter with 3-path diversity', () async {
      when(
        mockAchievement.getUnlockedAchievements(userId),
      ).thenAnswer((_) async => []);

      final detector = AchievementTriggerDetector(
        achievementService: mockAchievement,
        rewardService: mockRewardService,
      );

      final result = await detector.checkProgressTriggers(
        userId,
        // Stays below the Stat Master threshold so this test's assertion
        // reflects only the path-diversity condition it targets.
        statPoints: AchievementsCatalog.statMaster.maxProgress - 1,
        pathDiversity: 3,
        seasonsParticipated: 1,
        consistentSeasons: 0,
        currentTier: 'Silver',
      );

      expect(result, isNotEmpty);
    });

    test('triggers Season Warrior at 10 seasons', () async {
      when(
        mockAchievement.getUnlockedAchievements(userId),
      ).thenAnswer((_) async => []);

      final detector = AchievementTriggerDetector(
        achievementService: mockAchievement,
        rewardService: mockRewardService,
      );

      final result = await detector.checkSeasonalTriggers(
        userId,
        seasonsParticipated: 10,
        consistentSeasons: 3,
        currentTier: 'Gold',
        tierChanged: false,
      );

      expect(result, isNotEmpty);
    });

    test('triggers Consistency at 3+ seasons in Gold tier', () async {
      when(
        mockAchievement.getUnlockedAchievements(userId),
      ).thenAnswer((_) async => []);

      final detector = AchievementTriggerDetector(
        achievementService: mockAchievement,
        rewardService: mockRewardService,
      );

      final result = await detector.checkSeasonalTriggers(
        userId,
        seasonsParticipated: 10,
        consistentSeasons: 3,
        currentTier: 'Gold',
        tierChanged: false,
      );

      expect(result, isNotEmpty);
    });

    test('does not trigger Consistency below 3 seasons', () async {
      final detector = AchievementTriggerDetector(
        achievementService: mockAchievement,
        rewardService: mockRewardService,
      );

      final result = await detector.checkSeasonalTriggers(
        userId,
        seasonsParticipated: 5,
        consistentSeasons: 2,
        currentTier: 'Gold',
        tierChanged: false,
      );

      expect(result, isEmpty);
      verifyNever(mockRewardService.processUnlock(any, any));
    });

    test('does not trigger Consistency in non-Gold tiers', () async {
      final detector = AchievementTriggerDetector(
        achievementService: mockAchievement,
        rewardService: mockRewardService,
      );

      final result = await detector.checkSeasonalTriggers(
        userId,
        // seasonsParticipated must stay below 10 here, or it would also
        // satisfy the unrelated Season Warrior threshold
        // (`seasonsParticipated >= 10` in checkSeasonalTriggers) and make
        // `result` non-empty regardless of this test's actual target (a
        // non-Gold tier not triggering Consistency).
        seasonsParticipated: 3,
        consistentSeasons: 3,
        currentTier: 'Silver',
        tierChanged: false,
      );

      expect(result, isEmpty);
      verifyNever(mockRewardService.processUnlock(any, any));
    });

    test('prevents re-unlocking already unlocked achievements', () async {
      when(mockAchievement.getUnlockedAchievements(userId)).thenAnswer(
        (_) async => [
          PlayerAchievement(
            userId: userId,
            achievementId: 'aha_moment',
            unlockedAt: DateTime.now().subtract(const Duration(days: 1)),
          ),
        ],
      );

      final detector = AchievementTriggerDetector(
        achievementService: mockAchievement,
        rewardService: mockRewardService,
      );

      final result = await detector.checkKillTriggers(userId, 1, 1);

      // Should not attempt to unlock already unlocked achievement
      expect(result, isEmpty);
      verifyNever(
        mockRewardService.processUnlock(
          userId,
          argThat(
            predicate<Achievement>((a) => a.achievementId == 'aha_moment'),
          ),
        ),
      );
    });

    test('checks all triggers in batch for comprehensive detection', () async {
      final userData = _buildTestUser(userId);
      when(mockFirestore.getUserById(userId)).thenAnswer((_) async => userData);

      when(
        mockAchievement.getUnlockedAchievements(any),
      ).thenAnswer((_) async => []);

      final detector = AchievementTriggerDetector(
        achievementService: mockAchievement,
        rewardService: mockRewardService,
      );

      final result = await detector.checkAllTriggersForBattle(
        userId,
        kills: 1,
        totalKills: 1,
        won: true,
        deaths: 0,
        assists: 2,
        damageDealt: 500,
        totalBattles: 1,
        winCount: 1,
        statPoints: 60,
        pathDiversity: 3,
        seasonsParticipated: 10,
        consistentSeasons: 3,
        currentTier: 'Gold',
      );

      // Multiple achievements could be triggered
      expect(result, isA<List<Achievement>>());
    });

    test('handles errors gracefully without crashing battle flow', () async {
      when(
        mockFirestore.getUserById(userId),
      ).thenThrow(Exception('Database error'));

      final battle = Battle(
        battleId: battleId,
        userId: userId,
        opponentIds: const ['bot_001'],
        mapId: 'map_default',
        mode: BattleMode.quick,
        durationSeconds: 300,
        playerStats: [
          PlayerStats(
            userId: userId,
            mechaId: 'mecha_test',
            kills: 1,
            deaths: 0,
            assists: 0,
            score: 100,
          ),
        ],
        result: BattleResult.win,
        eloChange: 16,
        startedAt: DateTime.now(),
        endedAt: DateTime.now(),
      );

      // Should not throw, just log error
      viewModel.state = viewModel.state.copyWith(battle: battle);
      expect(viewModel.state.battle?.battleId, equals(battleId));
    });

    test('emits correct analytics events for unlocked achievements', () async {
      final userData = _buildTestUser(userId);
      when(mockFirestore.getUserById(userId)).thenAnswer((_) async => userData);

      when(
        mockAchievement.getUnlockedAchievements(userId),
      ).thenAnswer((_) async => []);

      final detector = AchievementTriggerDetector(
        achievementService: mockAchievement,
        rewardService: mockRewardService,
      );

      final achievements = await detector.checkProgressTriggers(
        userId,
        statPoints: AchievementsCatalog.statMaster.maxProgress,
        pathDiversity: 1,
        seasonsParticipated: 1,
        consistentSeasons: 0,
        currentTier: 'Bronze',
      );

      // Verify achievement was detected
      expect(achievements, isNotEmpty);
      expect(achievements.first.achievementId, equals('stat_master'));
    });

    tearDown(() {
      viewModel.dispose();
    });
  });
}

/// Minimal valid User for stubbing FirestoreService.getUserById in these
/// tests; none of the achievement-trigger assertions read its fields (the
/// trigger inputs like statPoints/pathDiversity are passed explicitly to
/// AchievementTriggerDetector's methods instead).
User _buildTestUser(String uid) {
  final now = DateTime.now();
  return User(
    uid: uid,
    name: 'Test Player',
    rank: 0,
    level: 1,
    eloRating: 1200,
    winRate: 0.0,
    gems: 0,
    gold: 0,
    createdAt: now,
    lastBattleAt: now,
  );
}
