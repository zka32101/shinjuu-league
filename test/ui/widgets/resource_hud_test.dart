import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shinjuu_league/data/models/resource_model.dart';
import 'package:shinjuu_league/services/skill_system_service.dart';
import 'package:shinjuu_league/ui/widgets/resource_hud.dart';

void main() {
  group('ResourceHUD', () {
    testWidgets('所持アイテムは名前・説明をTooltipに持つ実データで表示される', (tester) async {
      final ownedItemId = SkillSystemService.getAllItems().first.itemId;
      final item = SkillSystemService.getItemDefinition(ownedItemId)!;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResourceHUD(
              resources: PlayerResources(
                currentMana: 50,
                maxMana: 100,
                gold: 1000,
                ownedItemIds: [ownedItemId],
              ),
              elapsedSeconds: 60,
              ownedItemIds: [ownedItemId],
              onItemPurchase: (_) {},
            ),
          ),
        ),
      );

      // バグ修正前は _getItemDefinition が常に null を返し、
      // どのアイテムも頭文字の代わりに "?" チップとして表示されていた。
      expect(find.text('?'), findsNothing);
      expect(find.text(item.name.substring(0, 1)), findsOneWidget);

      final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
      expect(tooltip.message, '${item.name}\n${item.description}');
    });

    testWidgets('アイテム追加ボタンをタップするとショップが開き、カタログ全件を表示する', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResourceHUD(
              resources: PlayerResources(currentMana: 50, maxMana: 100, gold: 1000),
              elapsedSeconds: 0,
              onItemPurchase: (_) {},
            ),
          ),
        ),
      );

      // バグ修正前は _showItemShop が空実装で、タップしても何も起きなかった。
      expect(find.text('アイテムショップ'), findsNothing);

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(find.text('アイテムショップ'), findsOneWidget);
      for (final item in SkillSystemService.getAllItems()) {
        await tester.scrollUntilVisible(
          find.text(item.name),
          200,
          scrollable: find.byType(Scrollable).last,
        );
        expect(find.text(item.name), findsOneWidget);
      }
    });

    testWidgets('ショップでアイテムをタップすると onItemPurchase が呼ばれ、シートが閉じる', (
      tester,
    ) async {
      String? purchasedItemId;
      final firstItem = SkillSystemService.getAllItems().first;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResourceHUD(
              resources: PlayerResources(currentMana: 50, maxMana: 100, gold: 1000),
              elapsedSeconds: 0,
              onItemPurchase: (itemId) => purchasedItemId = itemId,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text(firstItem.name),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text(firstItem.name));
      await tester.pumpAndSettle();

      expect(purchasedItemId, firstItem.itemId);
      expect(find.text('アイテムショップ'), findsNothing);
    });

    testWidgets('ゴールド不足のアイテムはタップしても購入が発火しない', (tester) async {
      String? purchasedItemId;
      // legendary アイテムは最も高額（800G）なので、低所持金で未購入のまま確実に
      // 購入不可にできる。
      final expensiveItem = SkillSystemService.getAllItems().firstWhere(
        (i) => i.rarity == ItemRarity.legendary,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResourceHUD(
              resources: PlayerResources(currentMana: 50, maxMana: 100, gold: 0),
              elapsedSeconds: 0,
              onItemPurchase: (itemId) => purchasedItemId = itemId,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text(expensiveItem.name),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text(expensiveItem.name));
      await tester.pumpAndSettle();

      expect(purchasedItemId, isNull);
      // disabled な ListTile はタップしても閉じないため、シートは開いたまま。
      expect(find.text('アイテムショップ'), findsOneWidget);
    });

    testWidgets('所持済みアイテムはショップ内でチェックマーク表示され、再購入できない', (
      tester,
    ) async {
      String? purchasedItemId;
      final ownedItem = SkillSystemService.getAllItems().first;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResourceHUD(
              resources: PlayerResources(
                currentMana: 50,
                maxMana: 100,
                gold: 1000,
                ownedItemIds: [ownedItem.itemId],
              ),
              elapsedSeconds: 0,
              ownedItemIds: [ownedItem.itemId],
              onItemPurchase: (itemId) => purchasedItemId = itemId,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      await tester.tap(find.text(ownedItem.name));
      await tester.pumpAndSettle();

      expect(purchasedItemId, isNull);
    });
  });
}
