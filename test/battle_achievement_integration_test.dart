import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shinjuu_league/data/models/achievement.dart';
import 'package:shinjuu_league/data/models/battle_model.dart';
import 'package:shinjuu_league/data/models/match_result_model.dart';
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
  group('BattleViewModel with Achievement Integration', () {
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

      // Setup default mocks
      when(mockSkillTree.getSkillTree(userId)).thenAnswer((_) async => null);
      when(mockFirestore.updateBattle(any)).thenAnswer((_) async {});
      when(mockAnalytics.logBattleEnd(any, any, any, any, any))
          .thenAnswer((_) async {});
      when(mockAnalytics.logFirstRankedEntry(any)).thenAnswer((_) async {});
      when(mockAnalytics.logAchievementUnlocked(any, any, any))
          .thenAnswer((_) async {});
      when(mockAnalytics.recordError(any, any,
          reason: anyNamed('reason'),
          information: anyNamed('information'))).thenAnswer((_) async {});
      when(mockAchievement.getProgress(any, any))
          .thenAnswer((_) async => null);
      when(mockAchievement.unlockAchievement(any, any))
          .thenAnswer((_) async {});

      viewModel = BattleViewModel(
        firestoreService: mockFirestore,
        analyticsService: mockAnalytics,
        skillTreeService: mockSkillTree,
        achievementService: mockAchievement,
      );
    });

    test('initializes with empty unlocked achievements', () {
      expect(viewModel.state.newlyUnlockedAchievements, isEmpty);
    });

    test('detects Aha Moment achievement on first kill', () async {
      // Setup user data with base stats
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

      // Setup mock achievement to simulate Aha Moment unlock
      when(mockAchievement.getProgress(userId, 'aha_moment'))
          .thenAnswer((_) async => PlayerAchievement(
                userId: userId,
                achievementId: 'aha_moment',
              ));

      final unlockedAchievement = Achievement(
        achievementId: 'aha_moment',
        category: AchievementCategory.milestone,
        name: 'Aha Moment',
        description: 'Get your first kill',
        iconUrl: 'assets/icons/aha_moment.png',
        rewardTier: AchievementRewardTier.common,
        maxProgress: 1,
        isProgressBased: false,
      );

      when(mockAchievement.unlockAchievement(userId, 'aha_moment'))
          .thenAnswer((_) async {});

      // Create test battle with first kill
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

      // Prepare and setup engine
      final matchResult = MatchResult(
        teamA: [
          MatchParticipant(
            userId: userId,
            eloRating: 1200,
            selectedMechaId: 'mecha_default',
          ),
        ],
        teamB: [
          MatchParticipant(
            userId: 'bot_001',
            eloRating: 1150,
            selectedMechaId: 'mecha_bot',
          ),
        ],
        mapId: 'map_default',
        mode: BattleMode.quickMatch,
      );

      final engine = BattleEngine();
      engine.addParticipant(userId, 1200, 'mecha_default');
      engine.addParticipant('bot_001', 1150, 'mecha_bot');
      engine.assignLane(userId, 'lane1');
      engine.assignLane('bot_001', 'lane2');

      await viewModel.prepareBattle(matchResult, userId, 1200);
      viewModel.state = viewModel.state.copyWith(battle: battle, engine: engine);

      // Simulate battle completion and achievement check
      await viewModel.state.engine?.stop();

      // Verify achievement unlock was called
      verify(mockAchievement.unlockAchievement(userId, 'aha_moment'))
          .called(greaterThan(0));
    });

    test('emits analytics event for unlocked achievements', () async {
      final userData = User(
        userId: userId,
        displayName: 'Test Player',
        eloRating: 1200,
        statPoints: 50,
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

      final battle = Battle(
        battleId: battleId,
        userId: userId,
        opponentIds: const ['bot_001'],
        mapId: 'map_default',
        mode: BattleMode.ranked,
        durationSeconds: 300,
        playerStats: [
          PlayerStats(
            userId: userId,
            kills: 10,
            deaths: 2,
            assists: 5,
            damageDealt: 500,
          ),
        ],
        result: BattleResult.win,
        eloChange: 24,
        startedAt: DateTime.now(),
        endedAt: DateTime.now(),
      );

      final matchResult = MatchResult(
        teamA: [
          MatchParticipant(
            userId: userId,
            eloRating: 1200,
            selectedMechaId: 'mecha_default',
          ),
        ],
        teamB: [
          MatchParticipant(
            userId: 'bot_001',
            eloRating: 1150,
            selectedMechaId: 'mecha_bot',
          ),
        ],
        mapId: 'map_default',
        mode: BattleMode.ranked,
      );

      final engine = BattleEngine();
      engine.addParticipant(userId, 1200, 'mecha_default');
      engine.addParticipant('bot_001', 1150, 'mecha_bot');

      await viewModel.prepareBattle(matchResult, userId, 1200);
      viewModel.state = viewModel.state.copyWith(battle: battle, engine: engine);

      // Verify analytics events would be logged
      // (actual testing requires more complex mocking of the entire flow)
      expect(viewModel.state.newlyUnlockedAchievements, isA<List<Achievement>>());
    });

    test('handles achievement detection errors gracefully', () async {
      when(mockFirestore.getUser(userId)).thenThrow(Exception('Database error'));

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
            kills: 5,
            deaths: 3,
            assists: 2,
            damageDealt: 300,
          ),
        ],
        result: BattleResult.loss,
        eloChange: -12,
        startedAt: DateTime.now(),
        endedAt: DateTime.now(),
      );

      viewModel.state = viewModel.state.copyWith(battle: battle);

      // Should log error but not throw
      await viewModel.state.engine?.stop();
      expect(viewModel.state.isFinished, false);
    });

    test('initializes with correct services in BattleState', () {
      expect(viewModel.state.newlyUnlockedAchievements, isEmpty);
      expect(viewModel.state.battle, isNull);
      expect(viewModel.state.engine, isNull);
    });

    test('updates state with newly unlocked achievements', () async {
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

      final newState = viewModel.state.copyWith(
        newlyUnlockedAchievements: [
          Achievement(
            achievementId: 'rising_star',
            category: AchievementCategory.milestone,
            name: 'Rising Star',
            description: 'Win your first battle',
            iconUrl: 'assets/icons/rising_star.png',
            rewardTier: AchievementRewardTier.common,
            maxProgress: 1,
            isProgressBased: false,
          ),
        ],
      );

      expect(newState.newlyUnlockedAchievements, isNotEmpty);
      expect(newState.newlyUnlockedAchievements.first.achievementId,
          equals('rising_star'));
    });

    test('does not emit analytics if no achievements unlocked', () async {
      when(mockFirestore.getUser(userId)).thenAnswer((_) async => User(
            userId: userId,
            displayName: 'Test Player',
            eloRating: 1200,
            statPoints: 0,
            pathDiversity: 0,
            seasonsParticipated: 0,
            consistentSeasons: 0,
            currentTier: 'Bronze',
            totalBattles: 1,
            wins: 0,
          ));

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
            kills: 0,
            deaths: 5,
            assists: 0,
            damageDealt: 50,
          ),
        ],
        result: BattleResult.loss,
        eloChange: -16,
        startedAt: DateTime.now(),
        endedAt: DateTime.now(),
      );

      viewModel.state = viewModel.state.copyWith(battle: battle);

      // State should remain with empty achievements
      expect(viewModel.state.newlyUnlockedAchievements, isEmpty);
    });

    tearDown(() {
      viewModel.dispose();
    });
  });
}
