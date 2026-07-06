import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shinjuu_league/ui/widgets/error_retry_view.dart';

void main() {
  group('ErrorRetryView', () {
    testWidgets('メッセージを表示する', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ErrorRetryView(message: '通信エラーが発生しました')),
        ),
      );

      expect(find.text('通信エラーが発生しました'), findsOneWidget);
    });

    testWidgets('onRetry が null なら再試行ボタンを表示しない', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ErrorRetryView(message: 'エラー')),
        ),
      );

      expect(find.text('再試行'), findsNothing);
    });

    testWidgets('再試行ボタンをタップすると onRetry が呼ばれる', (tester) async {
      var retried = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorRetryView(message: 'エラー', onRetry: () => retried = true),
          ),
        ),
      );

      await tester.tap(find.text('再試行'));
      await tester.pumpAndSettle();

      expect(retried, isTrue);
    });
  });
}
