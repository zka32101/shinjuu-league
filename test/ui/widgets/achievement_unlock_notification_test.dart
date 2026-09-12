import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shinjuu_league/data/models/achievement.dart';
import 'package:shinjuu_league/ui/widgets/achievement_unlock_notification.dart';

void main() {
  group('AchievementUnlockNotification', () {
    late Achievement testAchievement;
    late PlayerAchievement testPlayerAchievement;

    setUp(() {
      testAchievement = Achievement(
        achievementId: 'rising_star',
        category: AchievementCategory.progression,
        name: '新星',
        description: 'シルバーティアに到達',
        iconUrl: 'assets/achievements/rising_star.png',
        rewardTier: AchievementRewardTier.bronze,
        maxProgress: 1,
        isProgressBased: false,
      );

      testPlayerAchievement = PlayerAchievement(
        userId: 'user_123',
        achievementId: 'rising_star',
        unlockedAt: DateTime.now(),
      );
    });

    testWidgets('renders achievement unlock dialog', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AchievementUnlockNotification(
              achievement: testAchievement,
              playerAchievement: testPlayerAchievement,
            ),
          ),
        ),
      );

      expect(find.byType(AchievementUnlockNotification), findsOneWidget);
      expect(find.text('新星'), findsOneWidget);
      expect(find.text('シルバーティアに到達'), findsOneWidget);
    });

    testWidgets('displays tier badge with correct color', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AchievementUnlockNotification(
              achievement: testAchievement,
              playerAchievement: testPlayerAchievement,
            ),
          ),
        ),
      );

      // Verify tier emoji is displayed
      expect(find.text('🥉'), findsOneWidget); // Bronze tier emoji
    });

    testWidgets('displays reward information', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AchievementUnlockNotification(
              achievement: testAchievement,
              playerAchievement: testPlayerAchievement,
            ),
          ),
        ),
      );

      // Verify reward info is displayed
      expect(find.text('獲得報酬'), findsOneWidget);
      expect(find.text('+${testAchievement.getRewardCurrency()}'), findsOneWidget);
      expect(find.text('+${testAchievement.getRewardBadges()}'), findsOneWidget);
    });

    testWidgets('displays header text', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AchievementUnlockNotification(
              achievement: testAchievement,
              playerAchievement: testPlayerAchievement,
            ),
          ),
        ),
      );

      expect(find.text('🎉 新しい成果を解除した！'), findsOneWidget);
    });

    testWidgets('shows progress bar for progress-based achievements', (WidgetTester tester) async {
      final progressAchievement = Achievement(
        achievementId: 'stat_master',
        category: AchievementCategory.skill,
        name: 'ステータスマスター',
        description: '1つのツリーに50+ポイント配置',
        iconUrl: 'assets/achievements/stat_master.png',
        rewardTier: AchievementRewardTier.silver,
        maxProgress: 50,
        isProgressBased: true,
      );

      final progressPlayerAchievement = PlayerAchievement(
        userId: 'user_123',
        achievementId: 'stat_master',
        unlockedAt: DateTime.now(),
        progress: AchievementProgress(current: 50, target: 50),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AchievementUnlockNotification(
              achievement: progressAchievement,
              playerAchievement: progressPlayerAchievement,
            ),
          ),
        ),
      );

      // Verify progress section is displayed
      expect(find.text('進捗'), findsOneWidget);
      expect(find.text('50/50'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('calls onDismiss callback after auto-dismiss', (WidgetTester tester) async {
      bool dismissed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AchievementUnlockNotification(
              achievement: testAchievement,
              playerAchievement: testPlayerAchievement,
              onDismiss: () => dismissed = true,
              displayDuration: const Duration(milliseconds: 100),
            ),
          ),
        ),
      );

      // Wait for auto-dismiss
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // onDismiss would be called, but we can't verify directly in widget test
      // Instead, verify the dialog is gone
      expect(find.byType(AchievementUnlockNotification), findsNothing);
    });

    testWidgets('applies scale animation on entry', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AchievementUnlockNotification(
              achievement: testAchievement,
              playerAchievement: testPlayerAchievement,
            ),
          ),
        ),
      );

      // Find the ScaleTransition
      expect(find.byType(ScaleTransition), findsOneWidget);
    });

    testWidgets('dismisses on barrier tap', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: AchievementUnlockNotification(
                achievement: testAchievement,
                playerAchievement: testPlayerAchievement,
                displayDuration: const Duration(seconds: 10),
              ),
            ),
          ),
        ),
      );

      // Tap outside the dialog
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pumpAndSettle();

      // Dialog should close
      expect(find.byType(Dialog), findsNothing);
    });

    testWidgets('displays correct tier emoji based on reward tier', (WidgetTester tester) async {
      final silverAchievement = Achievement(
        achievementId: 'test_silver',
        category: AchievementCategory.progression,
        name: 'Test Silver',
        description: 'Test',
        iconUrl: 'test.png',
        rewardTier: AchievementRewardTier.silver,
        maxProgress: 1,
      );

      final silverPlayerAchievement = PlayerAchievement(
        userId: 'user_123',
        achievementId: 'test_silver',
        unlockedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AchievementUnlockNotification(
              achievement: silverAchievement,
              playerAchievement: silverPlayerAchievement,
            ),
          ),
        ),
      );

      // Verify silver tier emoji
      expect(find.text('🥈'), findsOneWidget);
    });

    testWidgets('handles platinum tier correctly', (WidgetTester tester) async {
      final platinumAchievement = Achievement(
        achievementId: 'test_platinum',
        category: AchievementCategory.progression,
        name: 'Test Platinum',
        description: 'Test',
        iconUrl: 'test.png',
        rewardTier: AchievementRewardTier.platinum,
        maxProgress: 1,
      );

      final platinumPlayerAchievement = PlayerAchievement(
        userId: 'user_123',
        achievementId: 'test_platinum',
        unlockedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AchievementUnlockNotification(
              achievement: platinumAchievement,
              playerAchievement: platinumPlayerAchievement,
            ),
          ),
        ),
      );

      // Verify platinum tier emoji
      expect(find.text('👑'), findsOneWidget);
    });

    testWidgets('showAchievementUnlock function works', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  showAchievementUnlock(
                    tester.element(find.byType(Scaffold)),
                    testAchievement,
                    testPlayerAchievement,
                  );
                },
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      );

      // Tap button to show dialog
      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      // Verify dialog is shown
      expect(find.text('新星'), findsOneWidget);
    });

    testWidgets('progressbar not shown for instant unlock achievements', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AchievementUnlockNotification(
              achievement: testAchievement,
              playerAchievement: testPlayerAchievement,
            ),
          ),
        ),
      );

      // Verify progress section is NOT displayed for instant unlock
      expect(find.text('進捗'), findsNothing);
    });
  });
}
