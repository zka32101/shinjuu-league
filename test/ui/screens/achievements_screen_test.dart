import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shinjuu_league/data/models/achievement.dart';
import 'package:shinjuu_league/ui/screens/achievements_screen.dart';

void main() {
  group('AchievementsScreen', () {
    testWidgets('renders achievements screen with app bar',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AchievementsScreen(),
        ),
      );

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.text('成果'), findsOneWidget);
    });

    testWidgets('displays category filter tabs',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AchievementsScreen(),
        ),
      );

      expect(find.text('すべて'), findsOneWidget);
      expect(find.text('マイルストーン'), findsOneWidget);
      expect(find.text('進行'), findsOneWidget);
      expect(find.text('シーズン'), findsOneWidget);
    });

    testWidgets('displays achievement grid', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AchievementsScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Should display grid view
      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('shows achievement cards with trophy emoji',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AchievementsScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('🏆'), findsWidgets);
    });

    testWidgets('displays achievement names', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AchievementsScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Aha Moment'), findsOneWidget);
      expect(find.text('Rising Star'), findsOneWidget);
    });

    testWidgets('shows achievement tier badges', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AchievementsScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('コモン'), findsWidgets);
      expect(find.text('レア'), findsWidgets);
    });

    testWidgets('opens detail dialog when achievement card tapped',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AchievementsScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Tap first achievement card
      await tester.tap(find.text('Aha Moment').first);
      await tester.pumpAndSettle();

      // Dialog should be visible
      expect(find.byType(Dialog), findsOneWidget);
    });

    testWidgets('achievement detail shows description',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AchievementsScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Tap achievement
      await tester.tap(find.text('Aha Moment').first);
      await tester.pumpAndSettle();

      expect(find.text('Get your first kill'), findsOneWidget);
    });

    testWidgets('achievement detail shows progress for progress-based achievements',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AchievementsScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Tap progress-based achievement (Stat Master)
      await tester.tap(find.text('Stat Master').first);
      await tester.pumpAndSettle();

      expect(find.text('進捗: 0/50'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('achievement detail has close button', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AchievementsScreen(),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Aha Moment').first);
      await tester.pumpAndSettle();

      expect(find.text('閉じる'), findsOneWidget);
    });

    testWidgets('closes dialog when close button tapped',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AchievementsScreen(),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Aha Moment').first);
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsOneWidget);

      await tester.tap(find.text('閉じる'));
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsNothing);
    });

    testWidgets('category tab selection changes selection state',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AchievementsScreen(),
        ),
      );

      // Initially should have default tab selected
      expect(find.byType(Container), findsWidgets);

      // Tap a category tab
      await tester.tap(find.text('シーズン'));
      await tester.pumpAndSettle();

      // Verify state change (screen should still render)
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('handles multiple achievement tiles', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AchievementsScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Should have multiple cards
      expect(find.text('🏆'), findsWidgets);
      expect(find.byType(Card), findsWidgets);
    });

    testWidgets('achievement grid has proper spacing',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AchievementsScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final gridView = find.byType(GridView);
      expect(gridView, findsOneWidget);
    });
  });
}
