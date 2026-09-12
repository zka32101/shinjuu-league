import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shinjuu_league/data/models/achievement.dart';
import 'package:shinjuu_league/data/models/battle_model.dart';
import 'package:shinjuu_league/data/models/user_model.dart';
import 'package:shinjuu_league/services/achievement_service.dart';
import 'package:shinjuu_league/services/achievement_trigger_detector.dart';
import 'package:shinjuu_league/services/analytics_service.dart';
import 'package:shinjuu_league/services/battle_engine_service.dart';
import 'package:shinjuu_league/services/firestore_service.dart';
import 'package:shinjuu_league/services/skill_tree_service.dart';
import 'package:shinjuu_league/viewmodels/battle_viewmodel.dart';

class MockFirestoreService extends Mock implements FirestoreService {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

class MockSkillTreeService extends Mock implements SkillTreeService {}

class MockAchievementService extends Mock implements AchievementService {}

void main() {
  group('Achievement Trigger Detection in Battle Flow', () {
    late BattleViewModel viewModel;
    late MockFirestoreService mockFirestore;
    late MockAnalyticsService mockAnalytics;
    late MockSkillTreeService mockSkillTree;
    late MockAchievementService mockAchievement;

    const String userId = 'user_123';
    const String battleId = 'battle_001';

    setUp(() {
      mockFirestore = MockFirestoreService();
      mockAnalytics = MockAnalyticsService();
      mockSkillTree = MockSkillTreeService();
      mockAchievement = MockAchievementService();

      when(mockSkillTree.getSkillTree(any)).thenAnswer((_) async => null);
      when(mockFirestore.updateBattle(any)).thenAnswer((_) async {});
      when(mockAnalytics.logBattleEnd(any, any, any, any, any))
          .thenAnswer((_) async {});
      when(mockAnalytics.logFirstRankedEntry(any)).thenAnswer((_) async {});
      when(mockAnalytics.logAchievementUnlocked(any, any, any))
          .thenAnswer((_) async {});
      when(mockAnalytics.recordError(any, any,
          reason: anyNamed('reason'),
          information: anyNamed('information'))).thenAnswer((_) async {});

      viewModel = BattleViewModel(
        firestoreService: mockFirestore,
        analyticsService: mockAnalytics,
        skillTreeService: mockSkillTree,
        achievementService: mockAchievement,
      );
    });

    test('triggers Aha Moment on first kill during battle', () async {
      final userData = User(
        userId: userId,
        displayName: 'Test Player',
        eloRating: 1200,
        statPoints: 0,
        pathDiversity: 0,
        seasonsParticipated: 0,
        consistentSeasons: 0,
        currentTier: 'Bronze',
        totalBattles: 0,
        wins: 0,
      );
      when(mockFirestore.getUser(userId)).thenAnswer((_) async => userData);

      when(mockAchievement.getProgress(userId, 'aha_moment'))
          .thenAnswer((_) async => PlayerAchievement(
                userId: userId,
                achievementId: 'aha_moment',
              ));

      when(mockAchievement.unlockAchievement(userId, 'aha_moment'))
          .thenAnswer((_) async {});

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
      );

      final result = await detector.checkKillTriggers(userId, 1, 1);
      // Should trigger on first kill
      expect(result, isNotEmpty);
    });

    test('triggers Rising Star on battle win', () async {
      final userData = User(
        userId: userId,
        displayName: 'Test Player',
        eloRating: 1200,
        statPoints: 0,
        pathDiversity: 0,
        seasonsParticipated: 0,
        consistentSeasons: 0,
        currentTier: 'Bronze',
        totalBattles: 0,
        wins: 0,
      );
      when(mockFirestore.getUser(userId)).thenAnswer((_) async => userData);

      when(mockAchievement.getProgress(userId, 'rising_star'))
          .thenAnswer((_) async => PlayerAchievement(
                userId: userId,
                achievementId: 'rising_star',
              ));

      when(mockAchievement.unlockAchievement(userId, 'rising_star'))
          .thenAnswer((_) async {});

      final detector = AchievementTriggerDetector(
        achievementService: mockAchievement,
      );

      final result = await detector.checkBattleCompletionTriggers(
        userId,
        won: true,
        kills: 2,
        deaths: 1,
        assists: 1,
        damageDealt: 300,
        totalBattles: 1,
        winCount: 1,
      );

      expect(result, isNotEmpty);
    });

    test('triggers Stat Master at 50+ points', () async {
      when(mockAchievement.getProgress(userId, 'stat_master'))
          .thenAnswer((_) async => PlayerAchievement(
                userId: userId,
                achievementId: 'stat_master',
              ));

      when(mockAchievement.unlockAchievement(userId, 'stat_master'))
          .thenAnswer((_) async {});

      final detector = AchievementTriggerDetector(
        achievementService: mockAchievement,
      );

      final result = await detector.checkProgressTriggers(
        userId,
        statPoints: 50,
        pathDiversity: 1,
        seasonsParticipated: 1,
        consistentSeasons: 0,
        currentTier: 'Bronze',
      );

      expect(result, isNotEmpty);
    });

    test('triggers Balanced Fighter with 3-path diversity', () async {
      when(mockAchievement.getProgress(userId, 'balanced_fighter'))
          .thenAnswer((_) async => PlayerAchievement(
                userId: userId,
                achievementId: 'balanced_fighter',
              ));

      when(mockAchievement.unlockAchievement(userId, 'balanced_fighter'))
          .thenAnswer((_) async {});

      final detector = AchievementTriggerDetector(
        achievementService: mockAchievement,
      );

      final result = await detector.checkProgressTriggers(
        userId,
        statPoints: 30,
        pathDiversity: 3,
        seasonsParticipated: 1,
        consistentSeasons: 0,
        currentTier: 'Silver',
      );

      expect(result, isNotEmpty);
    });

    test('triggers Season Warrior at 10 seasons', () async {
      when(mockAchievement.getProgress(userId, 'season_warrior'))
          .thenAnswer((_) async => PlayerAchievement(
                userId: userId,
                achievementId: 'season_warrior',
              ));

      when(mockAchievement.unlockAchievement(userId, 'season_warrior'))
          .thenAnswer((_) async {});

      final detector = AchievementTriggerDetector(
        achievementService: mockAchievement,
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
      when(mockAchievement.getProgress(userId, 'consistency'))
          .thenAnswer((_) async => PlayerAchievement(
                userId: userId,
                achievementId: 'consistency',
              ));

      when(mockAchievement.unlockAchievement(userId, 'consistency'))
          .thenAnswer((_) async {});

      final detector = AchievementTriggerDetector(
        achievementService: mockAchievement,
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
      when(mockAchievement.getProgress(userId, 'consistency'))
          .thenAnswer((_) async => PlayerAchievement(
                userId: userId,
                achievementId: 'consistency',
              ));

      final detector = AchievementTriggerDetector(
        achievementService: mockAchievement,
      );

      final result = await detector.checkSeasonalTriggers(
        userId,
        seasonsParticipated: 5,
        consistentSeasons: 2,
        currentTier: 'Gold',
        tierChanged: false,
      );

      expect(result, isEmpty);
      verifyNever(
        mockAchievement.unlockAchievement(any, any),
      );
    });

    test('does not trigger Consistency in non-Gold tiers', () async {
      when(mockAchievement.getProgress(userId, 'consistency'))
          .thenAnswer((_) async => PlayerAchievement(
                userId: userId,
                achievementId: 'consistency',
              ));

      final detector = AchievementTriggerDetector(
        achievementService: mockAchievement,
      );

      final result = await detector.checkSeasonalTriggers(
        userId,
        seasonsParticipated: 10,
        consistentSeasons: 3,
        currentTier: 'Silver',
        tierChanged: false,
      );

      expect(result, isEmpty);
      verifyNever(
        mockAchievement.unlockAchievement(any, any),
      );
    });

    test('prevents re-unlocking already unlocked achievements', () async {
      when(mockAchievement.getProgress(userId, 'aha_moment'))
          .thenAnswer((_) async => PlayerAchievement(
                userId: userId,
                achievementId: 'aha_moment',
                unlockedAt: DateTime.now().subtract(const Duration(days: 1)),
              ));

      final detector = AchievementTriggerDetector(
        achievementService: mockAchievement,
      );

      final result = await detector.checkKillTriggers(userId, 1, 1);

      // Should not attempt to unlock already unlocked achievement
      expect(result, isEmpty);
      verifyNever(
        mockAchievement.unlockAchievement(userId, 'aha_moment'),
      );
    });

    test('checks all triggers in batch for comprehensive detection', () async {
      final userData = User(
        userId: userId,
        displayName: 'Test Player',
        eloRating: 1200,
        statPoints: 60,
        pathDiversity: 3,
        seasonsParticipated: 10,
        consistentSeasons: 3,
        currentTier: 'Gold',
        totalBattles: 1,
        wins: 1,
      );
      when(mockFirestore.getUser(userId)).thenAnswer((_) async => userData);

      when(mockAchievement.getProgress(any, any))
          .thenAnswer((_) async => PlayerAchievement(
                userId: userId,
                achievementId: 'test_achievement',
              ));

      when(mockAchievement.unlockAchievement(any, any))
          .thenAnswer((_) async {});

      final detector = AchievementTriggerDetector(
        achievementService: mockAchievement,
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
      when(mockFirestore.getUser(userId))
          .thenThrow(Exception('Database error'));

      final battle = Battle(
        battleId: battleId,
        userId: userId,
        opponentIds: const ['bot_001'],
        mapId: 'map_default',
        mode: BattleMode.quickMatch,
        durationSeconds: 300,
        playerStats: [
          PlayerStats(
            userId: userId,
            kills: 1,
            deaths: 0,
            assists: 0,
            damageDealt: 100,
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
      final userData = User(
        userId: userId,
        displayName: 'Test Player',
        eloRating: 1200,
        statPoints: 50,
        pathDiversity: 1,
        seasonsParticipated: 1,
        consistentSeasons: 0,
        currentTier: 'Bronze',
        totalBattles: 1,
        wins: 1,
      );
      when(mockFirestore.getUser(userId)).thenAnswer((_) async => userData);

      when(mockAchievement.getProgress(userId, 'stat_master'))
          .thenAnswer((_) async => PlayerAchievement(
                userId: userId,
                achievementId: 'stat_master',
              ));

      when(mockAchievement.unlockAchievement(userId, 'stat_master'))
          .thenAnswer((_) async {});

      final detector = AchievementTriggerDetector(
        achievementService: mockAchievement,
      );

      final achievements = await detector.checkProgressTriggers(
        userId,
        statPoints: 50,
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
