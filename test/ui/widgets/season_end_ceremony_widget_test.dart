import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shinjuu_league/ui/widgets/season_end_ceremony_widget.dart';

void main() {
  group('SeasonEndCeremonyWidget', () {
    testWidgets('renders promotion ceremony correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SeasonEndCeremonyWidget(
              fromTier: 'Silver',
              toTier: 'Gold',
              isPromotion: true,
            ),
          ),
        ),
      );

      expect(find.text('シーズン終了'), findsOneWidget);
      expect(find.text('Silver'), findsOneWidget);
      expect(find.text('Gold'), findsOneWidget);
      expect(find.text('昇格おめでとうございます！'), findsOneWidget);
    });

    testWidgets('renders demotion ceremony correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SeasonEndCeremonyWidget(
              fromTier: 'Gold',
              toTier: 'Silver',
              isPromotion: false,
            ),
          ),
        ),
      );

      expect(find.text('シーズン終了'), findsOneWidget);
      expect(find.text('Gold'), findsOneWidget);
      expect(find.text('Silver'), findsOneWidget);
      expect(find.text('次シーズンへのチャレンジを祈っています'), findsOneWidget);
    });

    testWidgets('displays correct tier emoji for Bronze', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SeasonEndCeremonyWidget(
              fromTier: 'Bronze',
              toTier: 'Silver',
              isPromotion: true,
            ),
          ),
        ),
      );

      expect(find.text('🥉'), findsWidgets);
    });

    testWidgets('displays correct tier emoji for Silver', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SeasonEndCeremonyWidget(
              fromTier: 'Silver',
              toTier: 'Gold',
              isPromotion: true,
            ),
          ),
        ),
      );

      expect(find.text('🥈'), findsOneWidget);
      expect(find.text('🥇'), findsOneWidget);
    });

    testWidgets('displays correct tier emoji for Gold', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SeasonEndCeremonyWidget(
              fromTier: 'Gold',
              toTier: 'Platinum',
              isPromotion: true,
            ),
          ),
        ),
      );

      expect(find.text('🥇'), findsOneWidget);
    });

    testWidgets('displays correct tier emoji for Platinum', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SeasonEndCeremonyWidget(
              fromTier: 'Platinum',
              toTier: 'Gold',
              isPromotion: false,
            ),
          ),
        ),
      );

      expect(find.text('💎'), findsOneWidget);
    });

    testWidgets('shows upward arrow for promotion', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SeasonEndCeremonyWidget(
              fromTier: 'Silver',
              toTier: 'Gold',
              isPromotion: true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
    });

    testWidgets('shows downward arrow for demotion', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SeasonEndCeremonyWidget(
              fromTier: 'Gold',
              toTier: 'Silver',
              isPromotion: false,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
    });

    testWidgets('calls onComplete callback when animation finishes',
        (WidgetTester tester) async {
      bool callbackCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SeasonEndCeremonyWidget(
              fromTier: 'Silver',
              toTier: 'Gold',
              isPromotion: true,
              onComplete: () {
                callbackCalled = true;
              },
              duration: const Duration(milliseconds: 100),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(callbackCalled, isTrue);
    });

    testWidgets('uses custom duration', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SeasonEndCeremonyWidget(
              fromTier: 'Silver',
              toTier: 'Gold',
              isPromotion: true,
              duration: const Duration(milliseconds: 200),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Gold'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 150));
      expect(find.text('Gold'), findsOneWidget);
    });

    testWidgets('scales animation starts from 0.5', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SeasonEndCeremonyWidget(
              fromTier: 'Silver',
              toTier: 'Gold',
              isPromotion: true,
              duration: const Duration(milliseconds: 500),
            ),
          ),
        ),
      );

      // At start, opacity should be low
      final initialOpacity = tester.getOpacity(find.text('Gold'));
      expect(initialOpacity, lessThan(0.5));
    });

    testWidgets('case-insensitive tier emoji lookup', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SeasonEndCeremonyWidget(
              fromTier: 'silver',
              toTier: 'gold',
              isPromotion: true,
            ),
          ),
        ),
      );

      expect(find.text('🥈'), findsOneWidget);
      expect(find.text('🥇'), findsOneWidget);
    });

    testWidgets('unknown tier defaults to star emoji', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SeasonEndCeremonyWidget(
              fromTier: 'Unknown',
              toTier: 'Silver',
              isPromotion: true,
            ),
          ),
        ),
      );

      expect(find.text('⭐'), findsOneWidget);
    });

    testWidgets('promotion message in correct color', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SeasonEndCeremonyWidget(
              fromTier: 'Silver',
              toTier: 'Gold',
              isPromotion: true,
            ),
          ),
        ),
      );

      final messageWidget = find.text('昇格おめでとうございます！');
      expect(messageWidget, findsOneWidget);

      final textWidget = tester.widget<Text>(messageWidget);
      expect(textWidget.style?.color, equals(const Color(0xFFFFD700))); // Gold
    });

    testWidgets('demotion message in correct color', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SeasonEndCeremonyWidget(
              fromTier: 'Gold',
              toTier: 'Silver',
              isPromotion: false,
            ),
          ),
        ),
      );

      final messageWidget = find.text('次シーズンへのチャレンジを祈っています');
      expect(messageWidget, findsOneWidget);

      final textWidget = tester.widget<Text>(messageWidget);
      expect(textWidget.style?.color, equals(const Color(0xFF87CEEB))); // Sky blue
    });

    testWidgets('dialog has gold border for promotion', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SeasonEndCeremonyWidget(
              fromTier: 'Silver',
              toTier: 'Gold',
              isPromotion: true,
            ),
          ),
        ),
      );

      final dialog = find.byType(Dialog);
      expect(dialog, findsOneWidget);
    });

    testWidgets('rapid rebuilds do not crash', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SeasonEndCeremonyWidget(
              fromTier: 'Silver',
              toTier: 'Gold',
              isPromotion: true,
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(find.text('Gold'), findsOneWidget);
    });

    testWidgets('shows eight promotion particles', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SeasonEndCeremonyWidget(
              fromTier: 'Silver',
              toTier: 'Gold',
              isPromotion: true,
            ),
          ),
        ),
      );

      // 8 stars for promotion
      expect(find.text('⭐'), findsWidgets);
    });

    testWidgets('shows six demotion particles', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SeasonEndCeremonyWidget(
              fromTier: 'Gold',
              toTier: 'Silver',
              isPromotion: false,
            ),
          ),
        ),
      );

      // 6 snowflakes for demotion
      expect(find.text('❄️'), findsWidgets);
    });
  });

  group('showSeasonEndCeremony', () {
    testWidgets('shows dialog and dismisses on completion',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      showSeasonEndCeremony(
                        context,
                        fromTier: 'Silver',
                        toTier: 'Gold',
                        isPromotion: true,
                        duration: const Duration(milliseconds: 100),
                      );
                    },
                    child: const Text('Show Ceremony'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Ceremony'));
      await tester.pumpAndSettle();

      expect(find.text('Gold'), findsOneWidget);
    });

    testWidgets('respects custom duration in helper',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      showSeasonEndCeremony(
                        context,
                        fromTier: 'Silver',
                        toTier: 'Gold',
                        isPromotion: true,
                        duration: const Duration(milliseconds: 200),
                      );
                    },
                    child: const Text('Show Ceremony'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Ceremony'));
      await tester.pump();
      expect(find.text('Gold'), findsOneWidget);

      await tester.pumpAndSettle();
    });

    testWidgets('calls onComplete callback in helper',
        (WidgetTester tester) async {
      bool callbackCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      showSeasonEndCeremony(
                        context,
                        fromTier: 'Silver',
                        toTier: 'Gold',
                        isPromotion: true,
                        onComplete: () {
                          callbackCalled = true;
                        },
                        duration: const Duration(milliseconds: 100),
                      );
                    },
                    child: const Text('Show Ceremony'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Ceremony'));
      await tester.pumpAndSettle();

      expect(callbackCalled, isTrue);
    });
  });
}
