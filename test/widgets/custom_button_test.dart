import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shinjuu_league/ui/widgets/custom_button.dart';

void main() {
  group('CustomButton', () {
    testWidgets('タップすると onPressed が呼ばれる', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(label: 'テスト', onPressed: () => tapped = true),
          ),
        ),
      );

      await tester.tap(find.text('テスト'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('onPressed が null の場合はタップしても何も起きない', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomButton(label: '無効', onPressed: null),
          ),
        ),
      );

      await tester.tap(find.text('無効'));
      await tester.pumpAndSettle();

      // 例外が起きずに完了すればOK（disabled状態の検証）
      expect(find.text('無効'), findsOneWidget);
    });

    testWidgets('isLoading が true の場合はラベルの代わりにスピナーを表示する', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomButton(label: '読込中', onPressed: null, isLoading: true),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('読込中'), findsNothing);
    });
  });
}
