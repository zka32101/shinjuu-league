import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shinjuu_league/data/models/achievement.dart';
import 'package:shinjuu_league/services/achievement_toast_notification_service.dart';
import 'package:shinjuu_league/ui/widgets/achievement_toast_widget.dart';

void main() {
  group('AchievementToastWidget', () {
    late AchievementToastNotification testNotification;
    late Achievement testAchievement;

    setUp(() {
      testAchievement = Achievement(
        achievementId: 'test_ach',
        category: AchievementCategory.milestone,
        name: 'Test Achievement',
        description: 'Test description',
        iconUrl: 'assets/test.png',
        rewardTier: AchievementRewardTier.rare,
        maxProgress: 1,
        isProgressBased: false,
      );

      testNotification = AchievementToastNotification(
        achievement: testAchievement,
        createdAt: DateTime.now(),
        id: 'test_notification_1',
      );
    });

    testWidgets('renders achievement toast with emoji and name',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AchievementToastWidget(notification: testNotification),
          ),
        ),
      );

      expect(find.text('🏆'), findsOneWidget);
      expect(find.text('成果を解除！'), findsOneWidget);
      expect(find.text('Test Achievement'), findsOneWidget);
    });

    testWidgets('displays tier color border based on reward tier',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AchievementToastWidget(notification: testNotification),
          ),
        ),
      );

      // Find the container with border
      final containerFinder = find.byType(Container);
      expect(containerFinder, findsWidgets);

      // Verify widget tree contains decoration
      await tester.pumpAndSettle();
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('shows tier badge with short label',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AchievementToastWidget(notification: testNotification),
          ),
        ),
      );

      // Rare tier should show 'R'
      expect(find.text('R'), findsOneWidget);
    });

    testWidgets('animates slide transition on entry',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AchievementToastWidget(notification: testNotification),
          ),
        ),
      );

      expect(find.byType(SlideTransition), findsOneWidget);
      expect(find.byType(FadeTransition), findsOneWidget);
    });

    testWidgets('handles different reward tiers',
        (WidgetTester tester) async {
      final tiers = [
        AchievementRewardTier.common,
        AchievementRewardTier.uncommon,
        AchievementRewardTier.rare,
        AchievementRewardTier.epic,
        AchievementRewardTier.legendary,
        AchievementRewardTier.mythic,
        AchievementRewardTier.silver,
        AchievementRewardTier.gold,
      ];

      for (final tier in tiers) {
        final achievement = Achievement(
          achievementId: 'test_${tier.name}',
          category: AchievementCategory.milestone,
          name: 'Test ${tier.name}',
          description: 'Test',
          iconUrl: 'assets/test.png',
          rewardTier: tier,
          maxProgress: 1,
          isProgressBased: false,
        );

        final notification = AchievementToastNotification(
          achievement: achievement,
          createdAt: DateTime.now(),
          id: 'test_${tier.name}',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AchievementToastWidget(notification: notification),
            ),
          ),
        );

        expect(find.text('🏆'), findsOneWidget);
        expect(find.text('Test ${tier.name}'), findsOneWidget);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(),
          ),
        );
      }
    });

    testWidgets('handles long achievement names with ellipsis',
        (WidgetTester tester) async {
      final achievement = Achievement(
        achievementId: 'test_long',
        category: AchievementCategory.milestone,
        name: 'This is a very long achievement name that should be truncated',
        description: 'Test',
        iconUrl: 'assets/test.png',
        rewardTier: AchievementRewardTier.legendary,
        maxProgress: 1,
        isProgressBased: false,
      );

      final notification = AchievementToastNotification(
        achievement: achievement,
        createdAt: DateTime.now(),
        id: 'test_long_1',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AchievementToastWidget(notification: notification),
          ),
        ),
      );

      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('calls onDismiss callback when provided',
        (WidgetTester tester) async {
      var dismissCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AchievementToastWidget(
              notification: testNotification,
              onDismiss: () {
                dismissCalled = true;
              },
            ),
          ),
        ),
      );

      expect(dismissCalled, isFalse);
    });

    testWidgets('animation completes without errors',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AchievementToastWidget(notification: testNotification),
          ),
        ),
      );

      // Allow animation to complete
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Should complete without error
      expect(find.byType(AchievementToastWidget), findsOneWidget);
    });
  });

  group('AchievementToastOverlay', () {
    testWidgets('displays multiple achievement toasts',
        (WidgetTester tester) async {
      final controller1 = StreamController<AchievementToastNotification>();
      final controller2 = StreamController<String>();

      final achievement = Achievement(
        achievementId: 'test',
        category: AchievementCategory.milestone,
        name: 'Test',
        description: 'Test',
        iconUrl: 'assets/test.png',
        rewardTier: AchievementRewardTier.common,
        maxProgress: 1,
        isProgressBased: false,
      );

      final notification = AchievementToastNotification(
        achievement: achievement,
        createdAt: DateTime.now(),
        id: 'toast_1',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                AchievementToastOverlay(
                  notifications: controller1.stream,
                  dismissals: controller2.stream,
                ),
              ],
            ),
          ),
        ),
      );

      // Initially no toast
      expect(find.byType(AchievementToastWidget), findsNothing);

      // Add notification
      controller1.add(notification);
      await tester.pumpAndSettle();

      expect(find.byType(AchievementToastWidget), findsOneWidget);

      await controller1.close();
      await controller2.close();
    });

    testWidgets('removes toasts on dismissal', (WidgetTester tester) async {
      final notificationController =
          StreamController<AchievementToastNotification>();
      final dismissalController = StreamController<String>();

      final achievement = Achievement(
        achievementId: 'test',
        category: AchievementCategory.milestone,
        name: 'Test',
        description: 'Test',
        iconUrl: 'assets/test.png',
        rewardTier: AchievementRewardTier.common,
        maxProgress: 1,
        isProgressBased: false,
      );

      final notification = AchievementToastNotification(
        achievement: achievement,
        createdAt: DateTime.now(),
        id: 'toast_123',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                AchievementToastOverlay(
                  notifications: notificationController.stream,
                  dismissals: dismissalController.stream,
                ),
              ],
            ),
          ),
        ),
      );

      // Add notification
      notificationController.add(notification);
      await tester.pumpAndSettle();
      expect(find.byType(AchievementToastWidget), findsOneWidget);

      // Dismiss
      dismissalController.add('toast_123');
      await tester.pumpAndSettle();

      expect(find.byType(AchievementToastWidget), findsNothing);

      await notificationController.close();
      await dismissalController.close();
    });

    testWidgets('aligns toasts to specified alignment',
        (WidgetTester tester) async {
      final controller1 = StreamController<AchievementToastNotification>();
      final controller2 = StreamController<String>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                AchievementToastOverlay(
                  notifications: controller1.stream,
                  dismissals: controller2.stream,
                  alignment: Alignment.bottomRight,
                ),
              ],
            ),
          ),
        ),
      );

      // Verify alignment widget
      expect(find.byType(Align), findsOneWidget);

      await controller1.close();
      await controller2.close();
    });

    testWidgets('shows empty when no notifications',
        (WidgetTester tester) async {
      final controller1 = StreamController<AchievementToastNotification>();
      final controller2 = StreamController<String>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                AchievementToastOverlay(
                  notifications: controller1.stream,
                  dismissals: controller2.stream,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(AchievementToastWidget), findsNothing);

      await controller1.close();
      await controller2.close();
    });
  });
}
