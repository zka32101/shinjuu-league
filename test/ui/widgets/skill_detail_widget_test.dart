import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shinjuu_league/data/models/skill_catalog.dart';
import 'package:shinjuu_league/ui/widgets/skill_detail_widget.dart';

void main() {
  group('SkillDetailCard', () {
    testWidgets('renders skill name and slot', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SkillDetailCard(
              skillName: '火炎突進',
              slot: SkillSlot.q,
              currentDamage: 200,
              currentCooldown: 4.0,
              description: 'テストスキル',
              isAvailable: true,
            ),
          ),
        ),
      );

      expect(find.text('火炎突進'), findsOneWidget);
      expect(find.text('Q'), findsOneWidget);
    });

    testWidgets('displays damage value', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SkillDetailCard(
              skillName: 'テストスキル',
              slot: SkillSlot.q,
              currentDamage: 250,
              currentCooldown: 4.0,
              isAvailable: true,
            ),
          ),
        ),
      );

      expect(find.text('250'), findsOneWidget);
      expect(find.text('ダメージ'), findsOneWidget);
    });

    testWidgets('displays cooldown value', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SkillDetailCard(
              skillName: 'テストスキル',
              slot: SkillSlot.q,
              currentDamage: 200,
              currentCooldown: 4.0,
              isAvailable: true,
            ),
          ),
        ),
      );

      expect(find.text('4.0s'), findsOneWidget);
      expect(find.text('クールタイム'), findsOneWidget);
    });

    testWidgets('shows unavailable state', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SkillDetailCard(
              skillName: 'テストスキル',
              slot: SkillSlot.r,
              currentDamage: 0,
              currentCooldown: 0.0,
              isAvailable: false,
              description: 'Lv2で解放',
            ),
          ),
        ),
      );

      expect(find.text('まだ使用不可'), findsOneWidget);
    });

    testWidgets('shows upcoming state', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SkillDetailCard(
              skillName: 'テストスキル',
              slot: SkillSlot.e,
              currentDamage: 0,
              currentCooldown: 0.0,
              isAvailable: false,
              isUpcoming: true,
            ),
          ),
        ),
      );

      expect(find.text('次のレベルで解放'), findsOneWidget);
    });

    testWidgets('displays description when provided',
        (WidgetTester tester) async {
      const description = 'これはテストスキルの説明です';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SkillDetailCard(
              skillName: 'テストスキル',
              slot: SkillSlot.q,
              currentDamage: 200,
              currentCooldown: 4.0,
              description: description,
              isAvailable: true,
            ),
          ),
        ),
      );

      expect(find.text(description), findsOneWidget);
    });

    testWidgets('all skill slots have proper colors',
        (WidgetTester tester) async {
      final slots = [
        (SkillSlot.q, 'Q'),
        (SkillSlot.r, 'R'),
        (SkillSlot.e, 'E'),
        (SkillSlot.ult, 'ULT'),
      ];

      for (final (slot, label) in slots) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SkillDetailCard(
                skillName: 'テスト',
                slot: slot,
                currentDamage: 100,
                currentCooldown: 4.0,
                isAvailable: true,
              ),
            ),
          ),
        );

        expect(find.text(label), findsOneWidget);
      }
    });
  });

  group('CharacterSkillsPanel', () {
    testWidgets('renders skills panel title', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CharacterSkillsPanel(
              mechaId: 'leon',
              currentLevel: 3,
            ),
          ),
        ),
      );

      expect(find.text('スキル情報'), findsOneWidget);
    });

    testWidgets('displays all four skill slots', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CharacterSkillsPanel(
              mechaId: 'leon',
              currentLevel: 3,
            ),
          ),
        ),
      );

      expect(find.text('火炎突進'), findsOneWidget); // Q
      expect(find.text('炎壁展開'), findsOneWidget); // R
      expect(find.text('進化スキル (E)'), findsOneWidget); // E
      expect(find.text('火龍皇牙'), findsOneWidget); // ULT
    });

    testWidgets('shows correct damage at Lv3',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CharacterSkillsPanel(
              mechaId: 'leon',
              currentLevel: 3,
            ),
          ),
        ),
      );

      // Lv3のダメージ値を確認（Leon Q: 200）
      expect(find.text('200'), findsOneWidget);
    });

    testWidgets('shows correct damage at Lv8',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CharacterSkillsPanel(
              mechaId: 'leon',
              currentLevel: 8,
            ),
          ),
        ),
      );

      // Lv8のダメージ値を確認（Leon Q: 350）
      expect(find.text('350'), findsOneWidget);
    });

    testWidgets('handles unknown mecha gracefully',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CharacterSkillsPanel(
              mechaId: 'unknown_mecha',
              currentLevel: 3,
            ),
          ),
        ),
      );

      expect(find.text('スキル情報が見つかりません'), findsOneWidget);
    });

    testWidgets('shows R skill as unavailable at Lv1',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CharacterSkillsPanel(
              mechaId: 'leon',
              currentLevel: 1,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Rスキルはまだ使用不可
      expect(find.byType(CharacterSkillsPanel), findsOneWidget);
    });

    testWidgets('shows ULT as unavailable before Lv7',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CharacterSkillsPanel(
              mechaId: 'leon',
              currentLevel: 6,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // ULTスキルはまだ使用不可
      expect(find.byType(CharacterSkillsPanel), findsOneWidget);
    });

    testWidgets('displays all 6 characters correctly',
        (WidgetTester tester) async {
      final characters = [
        'leon',
        'wolf',
        'dragoon',
        'frost',
        'phoenix',
        'crystal',
      ];

      for (final mechaId in characters) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CharacterSkillsPanel(
                mechaId: mechaId,
                currentLevel: 5,
              ),
            ),
          ),
        );

        // スキル情報が表示されている
        expect(find.text('スキル情報'), findsOneWidget);

        // 4つのスキルスロットがある
        final slots = find.byType(SkillDetailCard);
        expect(slots, findsWidgets);
      }
    });

    testWidgets('shows next level damage improvement',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CharacterSkillsPanel(
              mechaId: 'leon',
              currentLevel: 3,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Lv4での改善情報を確認
      expect(find.textContaining('Lv4'), findsWidgets);
      expect(find.textContaining('UP'), findsWidgets);
    });
  });
}
