import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shinjuu_league/data/models/achievement.dart';
import 'package:shinjuu_league/data/providers/service_providers.dart';
import 'package:shinjuu_league/services/achievement_service.dart';
import 'package:shinjuu_league/ui/screens/achievements_screen.dart';

/// Real bug fixed in the screen this tests: AchievementsScreen used to
/// render an entirely hard-coded sample list (with a literal
/// `// TODO: Fetch actual achievements from AchievementService`), and its
/// route was never linked from anywhere in the app's navigation - nothing
/// ever reached it. These tests exercise the real, Riverpod-backed
/// unlock/progress state instead, via a fake AchievementService and the
/// userIdOverride test seam (real userId resolution goes through
/// AuthService()/FirebaseAuth, which needs Firebase.initializeApp()).
class FakeAchievementService implements AchievementService {
  FakeAchievementService({this.unlockedIds = const {}});

  final Set<String> unlockedIds;

  @override
  Future<List<PlayerAchievement>> getPlayerAchievements(String userId) async {
    return unlockedIds
        .map(
          (id) => PlayerAchievement(
            userId: userId,
            achievementId: id,
            unlockedAt: DateTime.now(),
          ),
        )
        .toList();
  }

  @override
  Future<List<PlayerAchievement>> getUnlockedAchievements(String userId) async {
    return getPlayerAchievements(userId);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _wrap(Widget child, {Set<String> unlockedIds = const {}}) {
  return ProviderScope(
    overrides: [
      achievementServiceProvider.overrideWithValue(
        FakeAchievementService(unlockedIds: unlockedIds),
      ),
    ],
    child: MaterialApp(home: child),
  );
}

void main() {
  group('AchievementsScreen', () {
    testWidgets('renders achievements screen with app bar', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const AchievementsScreen(userIdOverride: 'user-1')),
      );

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.text('成果'), findsOneWidget);
    });

    testWidgets('shows a login prompt with no resolvable user', (
      WidgetTester tester,
    ) async {
      // No userIdOverride, and AuthService()/FirebaseAuth throws without
      // Firebase.initializeApp() (not run in this test) - the screen must
      // degrade to this message rather than crash.
      await tester.pumpWidget(_wrap(const AchievementsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('ログインが必要です'), findsOneWidget);
    });

    testWidgets('displays category filter tabs', (WidgetTester tester) async {
      await tester.pumpWidget(
        _wrap(const AchievementsScreen(userIdOverride: 'user-1')),
      );

      expect(find.text('すべて'), findsOneWidget);
      expect(find.text('マイルストーン'), findsOneWidget);
      expect(find.text('進行'), findsOneWidget);
      expect(find.text('シーズン'), findsOneWidget);
    });

    testWidgets('displays achievement grid', (WidgetTester tester) async {
      await tester.pumpWidget(
        _wrap(const AchievementsScreen(userIdOverride: 'user-1')),
      );

      await tester.pumpAndSettle();

      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('shows the full real catalog on the "すべて" tab', (
      WidgetTester tester,
    ) async {
      // GridView.builder only builds enough cards to fill the viewport (+
      // cache extent) - all 9 real catalog entries need a tall enough
      // surface to be simultaneously present in the tree.
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        _wrap(const AchievementsScreen(userIdOverride: 'user-1')),
      );
      await tester.pumpAndSettle();

      for (final achievement in AchievementsCatalog.all) {
        expect(
          find.text(achievement.name),
          findsOneWidget,
          reason: '${achievement.achievementId} should be listed',
        );
      }
    });

    testWidgets(
      'shows unlocked achievements with a trophy, locked with a lock',
      (WidgetTester tester) async {
        addTearDown(tester.view.resetPhysicalSize);
        tester.view.physicalSize = const Size(800, 2000);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          _wrap(
            const AchievementsScreen(userIdOverride: 'user-1'),
            unlockedIds: {'aha_moment'},
          ),
        );
        await tester.pumpAndSettle();

        // 1 unlocked (aha_moment) + 8 locked among the 9 real catalog entries.
        expect(find.text('🏆'), findsOneWidget);
        expect(
          find.text('🔒'),
          findsNWidgets(AchievementsCatalog.all.length - 1),
        );
      },
    );

    testWidgets('opens detail dialog when achievement card tapped', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const AchievementsScreen(userIdOverride: 'user-1')),
      );
      await tester.pumpAndSettle();

      final ahaMomentCard = find.text(AchievementsCatalog.ahaMoment.name).first;
      await tester.ensureVisible(ahaMomentCard);
      await tester.pumpAndSettle();
      await tester.tap(ahaMomentCard);
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsOneWidget);
    });

    testWidgets('achievement detail shows description', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const AchievementsScreen(userIdOverride: 'user-1')),
      );
      await tester.pumpAndSettle();

      final ahaMomentCard = find.text(AchievementsCatalog.ahaMoment.name).first;
      await tester.ensureVisible(ahaMomentCard);
      await tester.pumpAndSettle();
      await tester.tap(ahaMomentCard);
      await tester.pumpAndSettle();

      expect(
        find.text(AchievementsCatalog.ahaMoment.description),
        findsOneWidget,
      );
    });

    testWidgets(
      'achievement detail shows real progress for a locked, progress-based achievement',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          _wrap(const AchievementsScreen(userIdOverride: 'user-1')),
        );
        await tester.pumpAndSettle();

        final statMasterCard = find
            .text(AchievementsCatalog.statMaster.name)
            .first;
        await tester.ensureVisible(statMasterCard);
        await tester.pumpAndSettle();

        await tester.tap(statMasterCard);
        await tester.pumpAndSettle();

        // No skill tree data available for this test user -> 0 progress,
        // against the real (fixed) catalog threshold of 5, not the old
        // impossible-to-reach 50.
        expect(
          find.text('進捗: 0/${AchievementsCatalog.statMaster.maxProgress}'),
          findsOneWidget,
        );
        expect(find.byType(LinearProgressIndicator), findsOneWidget);
      },
    );

    testWidgets(
      'achievement detail does not show a progress bar once unlocked',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          _wrap(
            const AchievementsScreen(userIdOverride: 'user-1'),
            unlockedIds: {'stat_master'},
          ),
        );
        await tester.pumpAndSettle();

        final statMasterCard = find
            .text(AchievementsCatalog.statMaster.name)
            .first;
        await tester.ensureVisible(statMasterCard);
        await tester.pumpAndSettle();

        await tester.tap(statMasterCard);
        await tester.pumpAndSettle();

        expect(find.byType(LinearProgressIndicator), findsNothing);
      },
    );

    testWidgets('achievement detail has close button', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const AchievementsScreen(userIdOverride: 'user-1')),
      );
      await tester.pumpAndSettle();

      final ahaMomentCard = find.text(AchievementsCatalog.ahaMoment.name).first;
      await tester.ensureVisible(ahaMomentCard);
      await tester.pumpAndSettle();
      await tester.tap(ahaMomentCard);
      await tester.pumpAndSettle();

      expect(find.text('閉じる'), findsOneWidget);
    });

    testWidgets('closes dialog when close button tapped', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const AchievementsScreen(userIdOverride: 'user-1')),
      );
      await tester.pumpAndSettle();

      final ahaMomentCard = find.text(AchievementsCatalog.ahaMoment.name).first;
      await tester.ensureVisible(ahaMomentCard);
      await tester.pumpAndSettle();
      await tester.tap(ahaMomentCard);
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsOneWidget);

      await tester.tap(find.text('閉じる'));
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsNothing);
    });

    testWidgets('category tab selection filters the grid', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const AchievementsScreen(userIdOverride: 'user-1')),
      );
      await tester.pumpAndSettle();

      // Tap the seasonal category tab - speedrunner is the only real
      // catalog entry in AchievementCategory.seasonal.
      await tester.tap(find.text('シーズン'));
      await tester.pumpAndSettle();

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.text(AchievementsCatalog.speedrunner.name), findsOneWidget);
      expect(find.text(AchievementsCatalog.ahaMoment.name), findsNothing);
    });

    testWidgets('achievement grid has proper spacing', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const AchievementsScreen(userIdOverride: 'user-1')),
      );
      await tester.pumpAndSettle();

      final gridView = find.byType(GridView);
      expect(gridView, findsOneWidget);
    });
  });
}
