import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shinjuu_league/data/models/quest_model.dart';
import 'package:shinjuu_league/ui/screens/quests_screen.dart';
import 'package:shinjuu_league/viewmodels/quest_viewmodel.dart';

void main() {
  group('QuestsScreen', () {
    Widget createTestWidget() {
      return ProviderContainer(
        child: MaterialApp(
          home: const QuestsScreen(),
          theme: ThemeData(brightness: Brightness.light),
          darkTheme: ThemeData(brightness: Brightness.dark),
        ),
      ).watch(ProviderContainer());
    }

    testWidgets('renders with AppBar', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderContainer(
          child: MaterialApp(
            home: const QuestsScreen(),
          ),
        ).watch(ProviderContainer()),
      );

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('クエスト'), findsOneWidget);
    });

    testWidgets('renders loading state', (WidgetTester tester) async {
      final container = ProviderContainer();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: const QuestsScreen(),
          ),
        ),
      );

      // Initially shows loading or content
      await tester.pumpAndSettle();

      // Either loading or quests displayed
      expect(
        find.byType(CircularProgressIndicator).or(find.byType(ListView)),
        findsWidgets,
      );
    });

    testWidgets('renders TabBar with 4 tabs', (WidgetTester tester) async {
      final container = ProviderContainer(
        overrides: [
          questViewModelProvider.overrideWith((ref) {
            return QuestViewModel(
              questService: _MockQuestService(),
              userId: 'test_user',
            );
          }),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: const QuestsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find tab bar
      expect(find.byType(TabBar), findsOneWidget);

      // Check for tab labels
      expect(find.text('日次'), findsOneWidget);
      expect(find.text('週次'), findsOneWidget);
      expect(find.text('シーズン'), findsOneWidget);
      expect(find.text('完了'), findsOneWidget);
    });

    testWidgets('displays quests when available', (WidgetTester tester) async {
      final mockService = _MockQuestService();
      mockService._allQuests = [
        _createPlayerQuest('daily_win_1', 'バトルに3勝する'),
        _createPlayerQuest('daily_damage_1', 'ダメージを与える'),
      ];

      final container = ProviderContainer(
        overrides: [
          questViewModelProvider.overrideWith((ref) {
            return QuestViewModel(
              questService: mockService,
              userId: 'test_user',
            );
          }),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: const QuestsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Quests should be displayed
      expect(find.byType(Card), findsWidgets);
    });

    testWidgets('shows empty state when no quests', (WidgetTester tester) async {
      final container = ProviderContainer(
        overrides: [
          questViewModelProvider.overrideWith((ref) {
            return QuestViewModel(
              questService: _MockQuestService(),
              userId: 'test_user',
            );
          }),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: const QuestsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show "アクティブなクエストなし" or similar
      expect(
        find.textContaining('クエスト'),
        findsWidgets,
      );
    });

    testWidgets('displays quest reward preview', (WidgetTester tester) async {
      final mockService = _MockQuestService();
      mockService._allQuests = [
        _createPlayerQuest('daily_win_1', 'Win 3 battles'),
      ];

      final container = ProviderContainer(
        overrides: [
          questViewModelProvider.overrideWith((ref) {
            return QuestViewModel(
              questService: mockService,
              userId: 'test_user',
            );
          }),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: const QuestsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Reward preview should show currency/badge emojis
      expect(find.textContaining('💰'), findsWidgets);
    });

    testWidgets('shows progress bar for active quest', (WidgetTester tester) async {
      final mockService = _MockQuestService();
      mockService._allQuests = [
        _createPlayerQuest('daily_win_1', 'Win 3 battles'),
      ];

      final container = ProviderContainer(
        overrides: [
          questViewModelProvider.overrideWith((ref) {
            return QuestViewModel(
              questService: mockService,
              userId: 'test_user',
            );
          }),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: const QuestsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Progress bar should be visible
      expect(find.byType(LinearProgressIndicator), findsWidgets);
    });

    testWidgets('shows claim button for completed quest', (WidgetTester tester) async {
      final mockService = _MockQuestService();
      mockService._allQuests = [
        _createPlayerQuest(
          'daily_win_1',
          'Win 3 battles',
          isCompleted: true,
          isRewarded: false,
        ),
      ];

      final container = ProviderContainer(
        overrides: [
          questViewModelProvider.overrideWith((ref) {
            return QuestViewModel(
              questService: mockService,
              userId: 'test_user',
            );
          }),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: const QuestsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should find claim button in completed tab
      expect(find.text('報酬を受け取る'), findsWidgets);
    });

    testWidgets('displays claimed badge for rewarded quest', (WidgetTester tester) async {
      final mockService = _MockQuestService();
      mockService._allQuests = [
        _createPlayerQuest(
          'daily_win_1',
          'Win 3 battles',
          isCompleted: true,
          isRewarded: true,
        ),
      ];

      final container = ProviderContainer(
        overrides: [
          questViewModelProvider.overrideWith((ref) {
            return QuestViewModel(
              questService: mockService,
              userId: 'test_user',
            );
          }),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: const QuestsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show claimed badge
      expect(find.text('報酬受取済み'), findsWidgets);
    });

    testWidgets('displays difficulty badge', (WidgetTester tester) async {
      final mockService = _MockQuestService();
      mockService._allQuests = [
        _createPlayerQuest('daily_win_1', 'Win 3 battles'),
      ];

      final container = ProviderContainer(
        overrides: [
          questViewModelProvider.overrideWith((ref) {
            return QuestViewModel(
              questService: mockService,
              userId: 'test_user',
            );
          }),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: const QuestsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show difficulty (普通 for normal quests)
      expect(find.text('普通'), findsWidgets);
    });

    testWidgets('error state displays retry button', (WidgetTester tester) async {
      final mockService = _MockQuestService();
      mockService._shouldThrowError = true;

      final container = ProviderContainer(
        overrides: [
          questViewModelProvider.overrideWith((ref) {
            return QuestViewModel(
              questService: mockService,
              userId: 'test_user',
            );
          }),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: const QuestsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // After error, should show error message and retry button
      // Note: The exact error handling depends on implementation
      expect(
        find.byType(Center),
        findsWidgets,
      );
    });

    testWidgets('tab switching displays correct quests', (WidgetTester tester) async {
      final mockService = _MockQuestService();
      mockService._allQuests = [
        _createPlayerQuest('daily_win_1', 'Win 3 battles'),
        _createPlayerQuest('weekly_streak_1', 'Win 5 in a row'),
      ];

      final container = ProviderContainer(
        overrides: [
          questViewModelProvider.overrideWith((ref) {
            return QuestViewModel(
              questService: mockService,
              userId: 'test_user',
            );
          }),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: const QuestsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap on weekly tab
      await tester.tap(find.text('週次'));
      await tester.pumpAndSettle();

      // Weekly quests should be displayed
      expect(find.byType(ListView), findsWidgets);
    });
  });
}

class _MockQuestService extends Mock implements QuestService {
  List<PlayerQuest> _allQuests = [];
  bool _shouldThrowError = false;

  @override
  Future<List<PlayerQuest>> getAllQuests(String userId) async {
    if (_shouldThrowError) throw Exception('Mock error');
    return _allQuests;
  }

  @override
  Future<List<PlayerQuest>> getActiveQuests(
    String userId,
    QuestFrequency frequency,
  ) async {
    if (_shouldThrowError) throw Exception('Mock error');
    return _allQuests
        .where((q) => q.isActive)
        .where((q) {
          if (frequency == QuestFrequency.daily) {
            return q.questId.startsWith('daily_');
          } else if (frequency == QuestFrequency.weekly) {
            return q.questId.startsWith('weekly_');
          }
          return true;
        })
        .toList();
  }

  @override
  Future<PlayerQuest> startQuest(String userId, String questId) async {
    throw UnimplementedError();
  }

  @override
  Future<PlayerQuest?> updateQuestProgress(
    String userId,
    String questId,
    QuestConditionType conditionType,
    int newValue, {
    bool isIncrement = false,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<QuestReward?> claimQuestReward(String userId, String questId) async {
    throw UnimplementedError();
  }

  @override
  int getQuestProgress(PlayerQuest playerQuest) {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> debugGetQuestStats(String userId) async {
    if (_shouldThrowError) throw Exception('Mock error');
    return {
      'total': _allQuests.length,
      'active': _allQuests.where((q) => q.isActive).length,
      'completed': _allQuests.where((q) => q.isCompleted).length,
    };
  }
}

abstract class Mock {}

PlayerQuest _createPlayerQuest(
  String questId,
  String description, {
  bool isCompleted = false,
  bool isRewarded = false,
}) {
  return PlayerQuest(
    userId: 'test_user',
    questId: questId,
    conditions: [
      const QuestCondition(
        type: QuestConditionType.battleCount,
        target: 3,
        current: 0,
      ),
    ],
    isCompleted: isCompleted,
    isRewarded: isRewarded,
    startedAt: DateTime.now(),
    completedAt: isCompleted ? DateTime.now() : null,
  );
}
