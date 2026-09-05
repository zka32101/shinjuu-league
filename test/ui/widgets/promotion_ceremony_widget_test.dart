import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shinjuu_league/ui/widgets/promotion_ceremony_widget.dart';

void main() {
  group('PromotionCeremonyWidget', () {
    testWidgets('renders promotion ceremony dialog', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showPromotionCeremony(
                    context,
                    fromTier: 'Silver',
                    toTier: 'Gold',
                    fromRating: 1400,
                    toRating: 1850,
                    isPromotion: true,
                  ),
                  child: const Text('Show Promotion'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Gold'), findsWidgets);
      expect(find.text('🥇'), findsWidgets);
    });

    testWidgets('displays correct tier emojis for promotion', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showPromotionCeremony(
                    context,
                    fromTier: 'Silver',
                    toTier: 'Gold',
                    fromRating: 1400,
                    toRating: 1850,
                    isPromotion: true,
                  ),
                  child: const Text('Show'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.text('🥈'), findsWidgets); // Silver emoji
      expect(find.text('🥇'), findsWidgets); // Gold emoji
    });

    testWidgets('displays correct tier emojis for demotion', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showPromotionCeremony(
                    context,
                    fromTier: 'Gold',
                    toTier: 'Silver',
                    fromRating: 1850,
                    toRating: 1200,
                    isPromotion: false,
                  ),
                  child: const Text('Show'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.text('🥇'), findsWidgets); // Gold emoji
      expect(find.text('🥈'), findsWidgets); // Silver emoji
    });

    testWidgets('displays ratings in dialog', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showPromotionCeremony(
                    context,
                    fromTier: 'Bronze',
                    toTier: 'Silver',
                    fromRating: 1200,
                    toRating: 1450,
                    isPromotion: true,
                  ),
                  child: const Text('Show'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.text('1200'), findsWidgets);
      expect(find.text('1450'), findsWidgets);
    });

    testWidgets('closes dialog on button tap', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showPromotionCeremony(
                    context,
                    fromTier: 'Silver',
                    toTier: 'Gold',
                    fromRating: 1400,
                    toRating: 1850,
                    isPromotion: true,
                  ),
                  child: const Text('Show'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);

      await tester.tap(find.text('Great!'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('promotion message differs from demotion', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                ElevatedButton(
                  onPressed: () => showPromotionCeremony(
                    context,
                    fromTier: 'Silver',
                    toTier: 'Gold',
                    fromRating: 1400,
                    toRating: 1850,
                    isPromotion: true,
                  ),
                  child: const Text('Promotion'),
                ),
                ElevatedButton(
                  onPressed: () => showPromotionCeremony(
                    context,
                    fromTier: 'Gold',
                    toTier: 'Silver',
                    fromRating: 1850,
                    toRating: 1200,
                    isPromotion: false,
                  ),
                  child: const Text('Demotion'),
                ),
              ],
            ),
          ),
        ),
      );

      // Show promotion
      await tester.tap(find.byType(ElevatedButton).first);
      await tester.pumpAndSettle();

      final promotionDialogFinder = find.byType(AlertDialog);
      expect(promotionDialogFinder, findsOneWidget);

      final promotionText = find.descendant(
        of: promotionDialogFinder,
        matching: find.byType(Text),
      );

      expect(
        tester.widget<Text>(promotionText.first).data,
        contains('Congratulations'),
      );

      // Close dialog
      await tester.tap(find.text('Great!'));
      await tester.pumpAndSettle();

      // Show demotion
      await tester.tap(find.byType(ElevatedButton).at(1));
      await tester.pumpAndSettle();

      final demotionDialogFinder = find.byType(AlertDialog);
      expect(demotionDialogFinder, findsOneWidget);

      final demotionText = find.descendant(
        of: demotionDialogFinder,
        matching: find.byType(Text),
      );

      expect(
        tester.widget<Text>(demotionText.first).data,
        contains('demoted'),
      );
    });

    testWidgets('animation completes without crashing', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showPromotionCeremony(
                    context,
                    fromTier: 'Silver',
                    toTier: 'Gold',
                    fromRating: 1400,
                    toRating: 1850,
                    isPromotion: true,
                  ),
                  child: const Text('Show'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(AlertDialog), findsOneWidget);
    });
  });
}
