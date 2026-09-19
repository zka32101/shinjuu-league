import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shinjuu_league/data/models/skill_model.dart';
import 'package:shinjuu_league/game/battlefield_game.dart';
import 'package:shinjuu_league/ui/widgets/battle_action_cluster.dart';

void main() {
  group('BattleActionCluster', () {
    Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

    testWidgets('攻撃対象が無い場合はタップしても呼ばれない', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        wrap(
          BattleActionCluster(
            attackTarget: null,
            onAttackTap: () => tapped = true,
            skillType: null,
            skillCooldownRemaining: 0,
            skillCooldownMax: 6,
            onSkillTap: () {},
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.flash_on));
      await tester.pump();

      expect(tapped, isFalse);
    });

    testWidgets('攻撃対象がある場合はタップでコールバックが呼ばれる', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        wrap(
          BattleActionCluster(
            attackTarget: const AttackTarget(id: 'enemy_1', isMonster: false),
            onAttackTap: () => tapped = true,
            skillType: null,
            skillCooldownRemaining: 0,
            skillCooldownMax: 6,
            onSkillTap: () {},
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.flash_on));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('モンスターが対象の場合は虫アイコンに切り替わる', (tester) async {
      await tester.pumpWidget(
        wrap(
          BattleActionCluster(
            attackTarget: const AttackTarget(id: 'jungle_0', isMonster: true),
            onAttackTap: () {},
            skillType: null,
            skillCooldownRemaining: 0,
            skillCooldownMax: 6,
            onSkillTap: () {},
          ),
        ),
      );

      expect(find.byIcon(Icons.bug_report), findsOneWidget);
      expect(find.byIcon(Icons.flash_on), findsNothing);
    });

    testWidgets('スキルビルド未選択時はスキルボタンが無効化される', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        wrap(
          BattleActionCluster(
            attackTarget: null,
            onAttackTap: () {},
            skillType: null,
            skillCooldownRemaining: 0,
            skillCooldownMax: 6,
            onSkillTap: () => tapped = true,
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.auto_awesome));
      await tester.pump();

      expect(tapped, isFalse);
    });

    testWidgets('クールダウン中はスキルボタンが無効化され残り秒数を表示する', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        wrap(
          BattleActionCluster(
            attackTarget: null,
            onAttackTap: () {},
            skillType: SkillType.offensive,
            skillCooldownRemaining: 3.4,
            skillCooldownMax: 6,
            onSkillTap: () => tapped = true,
          ),
        ),
      );

      expect(find.text('4'), findsOneWidget); // ceil(3.4) == 4

      await tester.tap(find.byIcon(Icons.auto_awesome));
      await tester.pump();
      expect(tapped, isFalse);
    });

    testWidgets('クールダウンが無い場合はスキルボタンをタップできる', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        wrap(
          BattleActionCluster(
            attackTarget: null,
            onAttackTap: () {},
            skillType: SkillType.offensive,
            skillCooldownRemaining: 0,
            skillCooldownMax: 6,
            onSkillTap: () => tapped = true,
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.auto_awesome));
      await tester.pump();

      expect(tapped, isTrue);
    });
  });
}
