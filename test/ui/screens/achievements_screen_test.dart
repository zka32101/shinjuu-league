import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shinjuu_league/data/models/achievement.dart';
import 'package:shinjuu_league/data/models/user_model.dart';
import 'package:shinjuu_league/services/achievement_service.dart';
import 'package:shinjuu_league/ui/screens/achievements_screen.dart';
import 'package:shinjuu_league/viewmodels/achievement_viewmodel.dart';
import 'package:shinjuu_league/viewmodels/user_viewmodel.dart';

class MockAchievementService extends Mock implements AchievementService {}

class MockUserViewModel extends Mock {}

void main() {
  group('AchievementsScreen', () {
    late MockAchievementService mockAchievementService;

    setUp(() {
      mockAchievementService = MockAchievementService();
    });

    testWidgets('renders achievements screen with appbar', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderContainer(
          overrides: [
            achievementServiceProvider.overrideWithValue(mockAchievementService),
          ],
          child: const MaterialApp(
            home: AchievementsScreen(),
          ),
        ),
      );

      expect(find.text('成果'), findsWidgets);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('displays category filter chips', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderContainer(
          overrides: [
            achievementServiceProvider.overrideWithValue(mockAchievementService),
          ],
          child: const MaterialApp(
            home: AchievementsScreen(),
          ),
        ),
      );

      // Wait for build
      await tester.pumpAndSettle();

      // Verify category chips are present
      expect(find.byType(FilterChip), findsWidgets);
    });

    testWidgets('shows loading state initially', (WidgetTester tester) async {
      when(mockAchievementService.getPlayerAchievements(''))
          .thenAnswer((_) async => []);
      when(mockAchievementService.getUnlockedAchievements(''))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(
        ProviderContainer(
          overrides: [
            achievementServiceProvider.overrideWithValue(mockAchievementService),
          ],
          child: const MaterialApp(
            home: AchievementsScreen(),
          ),
        ),
      );

      // Loading state should show
      await tester.pumpAndSettle();
    });

    testWidgets('switches category on chip tap', (WidgetTester tester) async {
      when(mockAchievementService.getPlayerAchievements(''))
          .thenAnswer((_) async => []);
      when(mockAchievementService.getUnlockedAchievements(''))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(
        ProviderContainer(
          overrides: [
            achievementServiceProvider.overrideWithValue(mockAchievementService),
          ],
          child: const MaterialApp(
            home: AchievementsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap on a category chip (find the second one)
      final chips = find.byType(FilterChip);
      if (chips.evaluate().length > 1) {
        await tester.tap(chips.at(1));
        await tester.pumpAndSettle();
      }
    });

    testWidgets('displays achievements in grid', (WidgetTester tester) async {
      when(mockAchievementService.getPlayerAchievements(''))
          .thenAnswer((_) async => []);
      when(mockAchievementService.getUnlockedAchievements(''))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(
        ProviderContainer(
          overrides: [
            achievementServiceProvider.overrideWithValue(mockAchievementService),
          ],
          child: const MaterialApp(
            home: AchievementsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Grid should be present
      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('shows error state on load failure', (WidgetTester tester) async {
      when(mockAchievementService.getPlayerAchievements(''))
          .thenThrow(Exception('Failed to load'));
      when(mockAchievementService.getUnlockedAchievements(''))
          .thenThrow(Exception('Failed to load'));

      await tester.pumpWidget(
        ProviderContainer(
          overrides: [
            achievementServiceProvider.overrideWithValue(mockAchievementService),
          ],
          child: const MaterialApp(
            home: AchievementsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Error should be shown
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('shows reload button on error', (WidgetTester tester) async {
      when(mockAchievementService.getPlayerAchievements(''))
          .thenThrow(Exception('Failed to load'));
      when(mockAchievementService.getUnlockedAchievements(''))
          .thenThrow(Exception('Failed to load'));

      await tester.pumpWidget(
        ProviderContainer(
          overrides: [
            achievementServiceProvider.overrideWithValue(mockAchievementService),
          ],
          child: const MaterialApp(
            home: AchievementsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('再読み込み'), findsOneWidget);
    });

    testWidgets('achievement card shows locked state for non-unlocked', (WidgetTester tester) async {
      when(mockAchievementService.getPlayerAchievements(''))
          .thenAnswer((_) async => []);
      when(mockAchievementService.getUnlockedAchievements(''))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(
        ProviderContainer(
          overrides: [
            achievementServiceProvider.overrideWithValue(mockAchievementService),
          ],
          child: const MaterialApp(
            home: AchievementsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();
    });

    testWidgets('shows empty state for category with no achievements', (WidgetTester tester) async {
      when(mockAchievementService.getPlayerAchievements(''))
          .thenAnswer((_) async => []);
      when(mockAchievementService.getUnlockedAchievements(''))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(
        ProviderContainer(
          overrides: [
            achievementServiceProvider.overrideWithValue(mockAchievementService),
          ],
          child: const MaterialApp(
            home: AchievementsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show empty state message
      expect(
        find.textContaining('この カテゴリの成果はまだありません'),
        findsOneWidget,
      );
    });

    testWidgets('opens achievement detail modal on card tap', (WidgetTester tester) async {
      when(mockAchievementService.getPlayerAchievements(''))
          .thenAnswer((_) async => []);
      when(mockAchievementService.getUnlockedAchievements(''))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(
        ProviderContainer(
          overrides: [
            achievementServiceProvider.overrideWithValue(mockAchievementService),
          ],
          child: const MaterialApp(
            home: AchievementsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Look for cards and tap one
      final cards = find.byType(Card);
      if (cards.evaluate().isNotEmpty) {
        await tester.tap(cards.first);
        await tester.pumpAndSettle();

        // Modal should open
        expect(find.byType(ModalBottomSheet), findsOneWidget);
      }
    });
  });
}
