import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shinjuu_league/data/models/skill_catalog.dart';
import 'package:shinjuu_league/ui/screens/evolution_selection_v2_screen.dart';

void main() {
  group('EvolutionSelectionV2Screen', () {
    testWidgets('renders with title and countdown', (WidgetTester tester) async {
      bool evolutionSelected = false;
      EvolutionType? selectedType;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: EvolutionSelectionV2Screen(
              mechaId: 'leon',
              currentLevel: 3,
              onEvolutionSelected: (type) {
                evolutionSelected = true;
                selectedType = type;
              },
            ),
          ),
        ),
      );

      expect(find.text('レベル3 - 進化選択'), findsOneWidget);
      expect(find.text('神獣の力を目覚めさせよう'), findsOneWidget);
    });

    testWidgets('displays three evolution options', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: EvolutionSelectionV2Screen(
              mechaId: 'leon',
              currentLevel: 3,
              onEvolutionSelected: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('攻撃型進化'), findsOneWidget);
      expect(find.text('防御型進化'), findsOneWidget);
      expect(find.text('支援型進化'), findsOneWidget);
    });

    testWidgets('shows bonus text for each evolution type',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: EvolutionSelectionV2Screen(
              mechaId: 'leon',
              currentLevel: 3,
              onEvolutionSelected: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('ダメージ +60%'), findsOneWidget);
      expect(find.text('HP +30% / 軽減 +20%'), findsOneWidget);
      expect(find.text('味方効果 +50%'), findsOneWidget);
    });

    testWidgets('tapping evolution option selects it',
        (WidgetTester tester) async {
      bool called = false;
      EvolutionType? selectedType;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: EvolutionSelectionV2Screen(
              mechaId: 'leon',
              currentLevel: 3,
              onEvolutionSelected: (type) {
                called = true;
                selectedType = type;
              },
            ),
          ),
        ),
      );

      // 攻撃型を選択
      await tester.tap(find.text('攻撃型進化'));
      await tester.pumpAndSettle();

      expect(called, isTrue);
      expect(selectedType, equals(EvolutionType.offensive));
    });

    testWidgets('countdown timer is displayed',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: EvolutionSelectionV2Screen(
              mechaId: 'leon',
              currentLevel: 3,
              onEvolutionSelected: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('自動選択まで'), findsOneWidget);
      expect(find.textContaining('秒'), findsOneWidget);
    });

    testWidgets('selected choice shows check mark',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: EvolutionSelectionV2Screen(
              mechaId: 'leon',
              currentLevel: 3,
              onEvolutionSelected: (_) {},
            ),
          ),
        ),
      );

      // 攻撃型をタップ
      await tester.tap(find.text('攻撃型進化'));
      await tester.pumpAndSettle();

      // チェックマーク表示を確認（フラッシュバック制限のため部分確認）
      expect(find.text('選択済み'), findsOneWidget);
    });

    testWidgets('back button is disabled', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: EvolutionSelectionV2Screen(
              mechaId: 'leon',
              currentLevel: 3,
              onEvolutionSelected: (_) {},
            ),
          ),
        ),
      );

      // MaterialApp のデフォルト戻るボタンは存在しない（WillPopScope で無効化）
      expect(find.byType(WillPopScope), findsOneWidget);
    });

    testWidgets('all three evolution types are selectable',
        (WidgetTester tester) async {
      final selectedTypes = <EvolutionType>[];

      Future<void> testEvolution(EvolutionType type) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: EvolutionSelectionV2Screen(
                mechaId: 'leon',
                currentLevel: 3,
                onEvolutionSelected: (selected) {
                  selectedTypes.add(selected);
                },
              ),
            ),
          ),
        );

        // 進化タイプに対応するテキストを見つけてタップ
        if (type == EvolutionType.offensive) {
          await tester.tap(find.text('攻撃型進化'));
        } else if (type == EvolutionType.defensive) {
          await tester.tap(find.text('防御型進化'));
        } else {
          await tester.tap(find.text('支援型進化'));
        }
        await tester.pumpAndSettle();
      }

      await testEvolution(EvolutionType.offensive);
      expect(selectedTypes.last, equals(EvolutionType.offensive));

      await testEvolution(EvolutionType.defensive);
      expect(selectedTypes.last, equals(EvolutionType.defensive));

      await testEvolution(EvolutionType.support);
      expect(selectedTypes.last, equals(EvolutionType.support));
    });
  });
}
