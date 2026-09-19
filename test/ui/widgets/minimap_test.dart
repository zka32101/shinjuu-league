import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shinjuu_league/ui/widgets/minimap.dart';

void main() {
  group('Minimap', () {
    testWidgets('エントリが空でも例外を投げずに描画される', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Minimap(entries: [])),
        ),
      );

      expect(find.byType(Minimap), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('自分・味方・敵・モンスターのエントリを描画できる', (tester) async {
      const entries = [
        MinimapEntry(id: 'self', x: 0.0, y: 0.0, type: MinimapEntryType.self, isAlive: true),
        MinimapEntry(id: 'ally_1', x: -0.5, y: 0.2, type: MinimapEntryType.ally, isAlive: true),
        MinimapEntry(id: 'enemy_1', x: 0.5, y: -0.3, type: MinimapEntryType.enemy, isAlive: false),
        MinimapEntry(id: 'jungle_0', x: 0.0, y: 0.5, type: MinimapEntryType.monster, isAlive: true),
      ];

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Minimap(entries: entries)),
        ),
      );

      expect(find.byType(Minimap), findsOneWidget);
    });

    testWidgets('範囲外(-1..1超)の座標でも例外を投げずクランプされる', (tester) async {
      const entries = [
        MinimapEntry(id: 'far', x: 5.0, y: -8.0, type: MinimapEntryType.enemy, isAlive: true),
      ];

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Minimap(entries: entries)),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('sizeパラメータで表示サイズを変更できる', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Minimap(entries: [], size: 160)),
        ),
      );

      final renderedSize = tester.getSize(find.byType(Minimap));
      expect(renderedSize.width, 160);
      expect(renderedSize.height, 160);
    });
  });
}
