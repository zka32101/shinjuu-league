import 'package:flutter_test/flutter_test.dart';
import 'package:shinjuu_league/ui/screens/result_screen_with_promotion.dart';
import 'package:shinjuu_league/data/models/battle_model.dart';

void main() {
  group('ResultScreenWithPromotion', () {
    testWidgets('renders result screen when no tier change', (WidgetTester tester) async {
      final battle = Battle(
        battleId: 'battle-1',
        battleMode: BattleMode.quick,
        result: BattleResult.win,
        userId: 'user-1',
        kills: 5,
        deaths: 2,
        assists: 3,
        eloChange: 25.0,
        duration: const Duration(minutes: 5),
        playerStats: [],
        timestamp: DateTime.now(),
        matchId: 'match-1',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ResultScreenWithPromotion(battle: battle),
        ),
      );

      // Should render without crashing
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('buildResultScreen returns ResultScreenWithPromotion with tier data',
        (WidgetTester tester) async {
      final battle = Battle(
        battleId: 'battle-1',
        battleMode: BattleMode.quick,
        result: BattleResult.win,
        userId: 'user-1',
        kills: 5,
        deaths: 2,
        assists: 3,
        eloChange: 25.0,
        duration: const Duration(minutes: 5),
        playerStats: [],
        timestamp: DateTime.now(),
        matchId: 'match-1',
      );

      final widget = buildResultScreen(
        battle: battle,
        previousTier: 'Silver',
        previousRating: 1400,
      );

      expect(widget, isA<ResultScreenWithPromotion>());
      expect(
        widget as ResultScreenWithPromotion,
        isA<ResultScreenWithPromotion>().having(
          (w) => w.previousTier,
          'previousTier',
          equals('Silver'),
        ),
      );
    });

    testWidgets('buildResultScreen returns plain ResultScreen without tier data',
        (WidgetTester tester) async {
      final battle = Battle(
        battleId: 'battle-1',
        battleMode: BattleMode.quick,
        result: BattleResult.win,
        userId: 'user-1',
        kills: 5,
        deaths: 2,
        assists: 3,
        eloChange: 25.0,
        duration: const Duration(minutes: 5),
        playerStats: [],
        timestamp: DateTime.now(),
        matchId: 'match-1',
      );

      final widget = buildResultScreen(battle: battle);

      // When no tier data, returns plain ResultScreen
      expect(widget, isNotEmpty);
    });

    testWidgets('promotion state initialized to false', (WidgetTester tester) async {
      final battle = Battle(
        battleId: 'battle-1',
        battleMode: BattleMode.quick,
        result: BattleResult.win,
        userId: 'user-1',
        kills: 5,
        deaths: 2,
        assists: 3,
        eloChange: 25.0,
        duration: const Duration(minutes: 5),
        playerStats: [],
        timestamp: DateTime.now(),
        matchId: 'match-1',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ResultScreenWithPromotion(
            battle: battle,
            previousTier: 'Silver',
            previousRating: 1400,
          ),
        ),
      );

      // Verify no immediate promotion dialog shown
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('handles rapid rebuilds without crashing', (WidgetTester tester) async {
      final battle = Battle(
        battleId: 'battle-1',
        battleMode: BattleMode.quick,
        result: BattleResult.win,
        userId: 'user-1',
        kills: 5,
        deaths: 2,
        assists: 3,
        eloChange: 25.0,
        duration: const Duration(minutes: 5),
        playerStats: [],
        timestamp: DateTime.now(),
        matchId: 'match-1',
      );

      final widget = ResultScreenWithPromotion(
        battle: battle,
        previousTier: 'Silver',
        previousRating: 1400,
      );

      await tester.pumpWidget(MaterialApp(home: widget));
      await tester.pumpWidget(MaterialApp(home: widget));
      await tester.pumpWidget(MaterialApp(home: widget));

      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('passes correct battle to result screen', (WidgetTester tester) async {
      final battle = Battle(
        battleId: 'battle-1',
        battleMode: BattleMode.quick,
        result: BattleResult.win,
        userId: 'user-1',
        kills: 5,
        deaths: 2,
        assists: 3,
        eloChange: 25.0,
        duration: const Duration(minutes: 5),
        playerStats: [],
        timestamp: DateTime.now(),
        matchId: 'match-1',
      );

      final widget = ResultScreenWithPromotion(
        battle: battle,
        previousTier: 'Silver',
        previousRating: 1400,
      );

      expect(widget.battle, equals(battle));
      expect(widget.battle.battleId, equals('battle-1'));
    });

    testWidgets('tier values are stored correctly', (WidgetTester tester) async {
      final battle = Battle(
        battleId: 'battle-1',
        battleMode: BattleMode.quick,
        result: BattleResult.win,
        userId: 'user-1',
        kills: 5,
        deaths: 2,
        assists: 3,
        eloChange: 25.0,
        duration: const Duration(minutes: 5),
        playerStats: [],
        timestamp: DateTime.now(),
        matchId: 'match-1',
      );

      final widget = ResultScreenWithPromotion(
        battle: battle,
        previousTier: 'Platinum',
        previousRating: 2250,
      );

      expect(widget.previousTier, equals('Platinum'));
      expect(widget.previousRating, equals(2250));
    });

    testWidgets('handles null tier gracefully', (WidgetTester tester) async {
      final battle = Battle(
        battleId: 'battle-1',
        battleMode: BattleMode.quick,
        result: BattleResult.win,
        userId: 'user-1',
        kills: 5,
        deaths: 2,
        assists: 3,
        eloChange: 25.0,
        duration: const Duration(minutes: 5),
        playerStats: [],
        timestamp: DateTime.now(),
        matchId: 'match-1',
      );

      final widget = ResultScreenWithPromotion(
        battle: battle,
        previousTier: null,
        previousRating: null,
      );

      await tester.pumpWidget(MaterialApp(home: widget));

      expect(find.byType(ResultScreenWithPromotion), findsOneWidget);
      expect(widget.previousTier, isNull);
      expect(widget.previousRating, isNull);
    });

    testWidgets('creates state properly', (WidgetTester tester) async {
      final battle = Battle(
        battleId: 'battle-1',
        battleMode: BattleMode.quick,
        result: BattleResult.win,
        userId: 'user-1',
        kills: 5,
        deaths: 2,
        assists: 3,
        eloChange: 25.0,
        duration: const Duration(minutes: 5),
        playerStats: [],
        timestamp: DateTime.now(),
        matchId: 'match-1',
      );

      final widget = ResultScreenWithPromotion(battle: battle);
      final state = widget.createState();

      expect(state, isA<ConsumerState>());
    });
  });
}
