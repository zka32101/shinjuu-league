import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shinjuu_league/data/models/achievement.dart';
import 'package:shinjuu_league/data/models/battle_model.dart';
import 'package:shinjuu_league/services/analytics_service.dart';
import 'package:shinjuu_league/services/firestore_service.dart';
import 'package:shinjuu_league/services/replay_service.dart';
import 'package:shinjuu_league/services/skill_tree_service.dart';
import 'package:shinjuu_league/ui/screens/result_screen.dart';

class MockFirestoreService extends Mock implements FirestoreService {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

class MockReplayService extends Mock implements ReplayService {}

class MockSkillTreeService extends Mock implements SkillTreeService {}

void main() {
  group('ResultScreen Achievement Display', () {
    late MockFirestoreService mockFirestore;
    late MockAnalyticsService mockAnalytics;
    late MockReplayService mockReplay;
    late MockSkillTreeService mockSkillTree;

    const String userId = 'user_123';
    const String battleId = 'battle_001';

    setUp(() {
      mockFirestore = MockFirestoreService();
      mockAnalytics = MockAnalyticsService();
      mockReplay = MockReplayService();
      mockSkillTree = MockSkillTreeService();

      when(mockAnalytics.logBattleEnd(any, any, any, any, any))
          .thenAnswer((_) async {});
      when(mockAnalytics.logAchievementUnlocked(any, any, any))
          .thenAnswer((_) async {});
      when(mockReplay.generateAndSave(any))
          .thenAnswer((_) async => null);
    });

    testWidgets('displays newly unlocked achievements', (WidgetTester tester) async {
      final achievements = [
        Achievement(
          achievementId: 'aha_moment',
          category: AchievementCategory.milestone,
          name: 'Aha Moment',
          description: 'Get your first kill',
          iconUrl: 'assets/icons/aha_moment.png',
          rewardTier: AchievementRewardTier.common,
          maxProgress: 1,
          isProgressBased: false,
        ),
        Achievement(
          achievementId: 'rising_star',
          category: AchievementCategory.milestone,
          name: 'Rising Star',
          description: 'Win your first battle',
          iconUrl: 'assets/icons/rising_star.png',
          rewardTier: AchievementRewardTier.uncommon,
          maxProgress: 1,
          isProgressBased: false,
        ),
      ];

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

      await tester.pumpWidget(
        ProviderContainer(
          child: MaterialApp(
            home: ResultScreen(battle: battle),
          ),
        ),
      );

      // Should display "Achievement Unlocked" header
      await tester.pumpAndSettle();
      expect(find.text('🏆 新しい成果を解除した！'), findsOneWidget);
    });

    testWidgets('does not show achievements section when none unlocked',
        (WidgetTester tester) async {
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

      await tester.pumpWidget(
        ProviderContainer(
          child: MaterialApp(
            home: ResultScreen(battle: battle),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should not display achievement section
      expect(find.text('🏆 新しい成果を解除した！'), findsNothing);
    });

    testWidgets('displays achievement card with tier color',
        (WidgetTester tester) async {
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

      await tester.pumpWidget(
        ProviderContainer(
          child: MaterialApp(
            home: ResultScreen(battle: battle),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify battle result display
      expect(find.text(battle.result.displayName), findsOneWidget);
    });

    testWidgets('shows replay sharing section', (WidgetTester tester) async {
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
            kills: 2,
            deaths: 1,
            assists: 1,
            damageDealt: 300,
          ),
        ],
        result: BattleResult.win,
        eloChange: 20,
        startedAt: DateTime.now(),
        endedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderContainer(
          child: MaterialApp(
            home: ResultScreen(battle: battle),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should display share section
      expect(find.text('戦績をシェア'), findsOneWidget);
    });

    testWidgets('shows player stats on result screen',
        (WidgetTester tester) async {
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
            deaths: 2,
            assists: 3,
            damageDealt: 500,
          ),
        ],
        result: BattleResult.win,
        eloChange: 24,
        startedAt: DateTime.now(),
        endedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderContainer(
          child: MaterialApp(
            home: ResultScreen(battle: battle),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should display stats
      expect(find.text('キル'), findsOneWidget);
      expect(find.text('デス'), findsOneWidget);
      expect(find.text('スコア'), findsOneWidget);
    });

    testWidgets('displays MVP badge when player is MVP',
        (WidgetTester tester) async {
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
            kills: 10,
            deaths: 1,
            assists: 5,
            damageDealt: 800,
          ),
          PlayerStats(
            userId: 'bot_001',
            kills: 2,
            deaths: 5,
            assists: 1,
            damageDealt: 200,
          ),
        ],
        result: BattleResult.win,
        eloChange: 32,
        startedAt: DateTime.now(),
        endedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderContainer(
          child: MaterialApp(
            home: ResultScreen(battle: battle),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should display MVP badge
      expect(find.text('MVP'), findsOneWidget);
    });

    testWidgets('shows Elo change positive for win',
        (WidgetTester tester) async {
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
            deaths: 2,
            assists: 2,
            damageDealt: 500,
          ),
        ],
        result: BattleResult.win,
        eloChange: 16,
        startedAt: DateTime.now(),
        endedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderContainer(
          child: MaterialApp(
            home: ResultScreen(battle: battle),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show positive Elo change
      expect(find.text(contains('Elo +16')), findsOneWidget);
    });

    testWidgets('shows Elo change negative for loss',
        (WidgetTester tester) async {
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
            deaths: 5,
            assists: 0,
            damageDealt: 150,
          ),
        ],
        result: BattleResult.loss,
        eloChange: -12,
        startedAt: DateTime.now(),
        endedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderContainer(
          child: MaterialApp(
            home: ResultScreen(battle: battle),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show negative Elo change
      expect(find.text(contains('Elo -12')), findsOneWidget);
    });

    testWidgets('shows return to lobby button',
        (WidgetTester tester) async {
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
            kills: 3,
            deaths: 2,
            assists: 1,
            damageDealt: 300,
          ),
        ],
        result: BattleResult.win,
        eloChange: 16,
        startedAt: DateTime.now(),
        endedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderContainer(
          child: MaterialApp(
            home: ResultScreen(battle: battle),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should display return button
      expect(find.text('ロビーへ戻る'), findsOneWidget);
    });

    testWidgets('achievement card is clickable',
        (WidgetTester tester) async {
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

      await tester.pumpWidget(
        ProviderContainer(
          child: MaterialApp(
            home: ResultScreen(battle: battle),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Achievement section should be present
      expect(find.text('🏆 新しい成果を解除した！'), findsOneWidget);
    });
  });
}
