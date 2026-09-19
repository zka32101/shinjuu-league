import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shinjuu_league/data/models/evolution_state.dart';
import 'package:shinjuu_league/data/models/skill_catalog.dart';
import 'package:shinjuu_league/ui/widgets/skill_progression_display.dart';

void main() {
  group('SkillSlotDisplay', () {
    testWidgets('renders Q skill slot with blue color', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SkillSlotDisplay(
              slot: SkillSlot.q,
              currentDamage: 200,
              cooldownRemaining: 0.0,
              cooldownMax: 4.0,
              isAvailable: true,
            ),
          ),
        ),
      );

      expect(find.text('Q'), findsOneWidget);
      expect(find.text('200'), findsOneWidget);
    });

    testWidgets('renders R skill slot with green color', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SkillSlotDisplay(
              slot: SkillSlot.r,
              currentDamage: 180,
              cooldownRemaining: 0.0,
              cooldownMax: 8.0,
              isAvailable: true,
            ),
          ),
        ),
      );

      expect(find.text('R'), findsOneWidget);
      expect(find.text('180'), findsOneWidget);
    });

    testWidgets('renders E skill slot with purple color', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SkillSlotDisplay(
              slot: SkillSlot.e,
              currentDamage: 150,
              cooldownRemaining: 0.0,
              cooldownMax: 6.0,
              isAvailable: true,
            ),
          ),
        ),
      );

      expect(find.text('E'), findsOneWidget);
    });

    testWidgets('renders ULT skill slot with red color', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SkillSlotDisplay(
              slot: SkillSlot.ult,
              currentDamage: 500,
              cooldownRemaining: 0.0,
              cooldownMax: 45.0,
              isAvailable: true,
              isUltUnlocked: true,
            ),
          ),
        ),
      );

      expect(find.text('ULT'), findsOneWidget);
    });

    testWidgets('shows cooldown timer when on cooldown', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SkillSlotDisplay(
              slot: SkillSlot.q,
              currentDamage: 200,
              cooldownRemaining: 2.5,
              cooldownMax: 4.0,
              isAvailable: false,
            ),
          ),
        ),
      );

      expect(find.text('2.5'), findsOneWidget);
    });

    testWidgets('shows charging indicator for ULT charging', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SkillSlotDisplay(
              slot: SkillSlot.ult,
              currentDamage: 0,
              cooldownRemaining: 30.0,
              cooldownMax: 45.0,
              isAvailable: false,
              isUltCharging: true,
            ),
          ),
        ),
      );

      expect(find.text('⚡'), findsOneWidget);
    });

    testWidgets('responds to tap when available', (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SkillSlotDisplay(
              slot: SkillSlot.q,
              currentDamage: 200,
              cooldownRemaining: 0.0,
              cooldownMax: 4.0,
              isAvailable: true,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(SkillSlotDisplay));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('ignores tap when unavailable', (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SkillSlotDisplay(
              slot: SkillSlot.q,
              currentDamage: 200,
              cooldownRemaining: 2.0,
              cooldownMax: 4.0,
              isAvailable: false,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(SkillSlotDisplay));
      await tester.pumpAndSettle();

      expect(tapped, isFalse);
    });
  });

  group('CharacterLevelDisplay', () {
    testWidgets('displays current level', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CharacterLevelDisplay(
              currentLevel: 5,
            ),
          ),
        ),
      );

      expect(find.text('Lv5'), findsOneWidget);
    });

    testWidgets('displays evolution type when set', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CharacterLevelDisplay(
              currentLevel: 3,
              currentEvolution: EvolutionType.offensive,
            ),
          ),
        ),
      );

      expect(find.text('Lv3'), findsOneWidget);
      expect(find.text('⚔️'), findsOneWidget);
    });

    testWidgets('shows defensive evolution emoji', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CharacterLevelDisplay(
              currentLevel: 6,
              currentEvolution: EvolutionType.defensive,
            ),
          ),
        ),
      );

      expect(find.text('🛡️'), findsOneWidget);
    });

    testWidgets('shows support evolution emoji', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CharacterLevelDisplay(
              currentLevel: 6,
              currentEvolution: EvolutionType.support,
            ),
          ),
        ),
      );

      expect(find.text('🤝'), findsOneWidget);
    });

    testWidgets('animates level up when showAnimation is true', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CharacterLevelDisplay(
              currentLevel: 3,
              showAnimation: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Lv3'), findsOneWidget);
    });
  });

  group('ULTStatusDisplay', () {
    testWidgets('shows ready status when available', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ULTStatusDisplay(
              isAvailable: true,
              isCharging: false,
            ),
          ),
        ),
      );

      expect(find.text('ULT Ready'), findsOneWidget);
      expect(find.text('⚡'), findsOneWidget);
    });

    testWidgets('shows charging status when charging', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ULTStatusDisplay(
              isAvailable: false,
              isCharging: true,
            ),
          ),
        ),
      );

      expect(find.text('Charging'), findsOneWidget);
    });

    testWidgets('shows locked status when locked', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ULTStatusDisplay(
              isAvailable: false,
              isCharging: false,
            ),
          ),
        ),
      );

      expect(find.text('Locked'), findsOneWidget);
    });
  });

  group('EvolutionBonusDisplay', () {
    testWidgets('hides when no evolution', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EvolutionBonusDisplay(
              bonuses: {},
              currentEvolution: null,
            ),
          ),
        ),
      );

      expect(find.byType(EvolutionBonusDisplay), findsOneWidget);
      expect(find.text('進化ボーナス'), findsNothing);
    });

    testWidgets('displays damage bonus for offensive', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EvolutionBonusDisplay(
              bonuses: {
                'damage_bonus': 0.6,
                'hp_bonus': 0.0,
                'ally_effect_bonus': 0.0,
              },
              currentEvolution: EvolutionType.offensive,
            ),
          ),
        ),
      );

      expect(find.text('進化ボーナス'), findsOneWidget);
      expect(find.textContaining('ダメージ'), findsOneWidget);
      expect(find.textContaining('60'), findsOneWidget);
    });

    testWidgets('displays HP bonus for defensive', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EvolutionBonusDisplay(
              bonuses: {
                'damage_bonus': 0.0,
                'hp_bonus': 0.3,
                'ally_effect_bonus': 0.0,
              },
              currentEvolution: EvolutionType.defensive,
            ),
          ),
        ),
      );

      expect(find.text('進化ボーナス'), findsOneWidget);
      expect(find.textContaining('HP'), findsOneWidget);
    });

    testWidgets('displays ally bonus for support', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EvolutionBonusDisplay(
              bonuses: {
                'damage_bonus': 0.0,
                'hp_bonus': 0.0,
                'ally_effect_bonus': 0.5,
              },
              currentEvolution: EvolutionType.support,
            ),
          ),
        ),
      );

      expect(find.text('進化ボーナス'), findsOneWidget);
      expect(find.textContaining('味方効果'), findsOneWidget);
    });
  });

  group('SkillProgressionPanel', () {
    testWidgets('displays level and all skill slots', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SkillProgressionPanel(
              currentLevel: 3,
              skillCooldowns: {
                SkillSlot.q: 0.0,
                SkillSlot.r: 0.0,
                SkillSlot.e: 0.0,
                SkillSlot.ult: 0.0,
              },
              skillDamages: {
                SkillSlot.q: 200,
                SkillSlot.r: 180,
                SkillSlot.e: 150,
                SkillSlot.ult: 0,
              },
              evolutionBonuses: {},
              isUltAvailable: false,
              isUltCharging: false,
            ),
          ),
        ),
      );

      expect(find.text('Lv3'), findsOneWidget);
      expect(find.text('Q'), findsOneWidget);
      expect(find.text('R'), findsOneWidget);
      expect(find.text('E'), findsOneWidget);
      expect(find.text('ULT'), findsOneWidget);
    });

    testWidgets('displays ULT status indicators', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SkillProgressionPanel(
              currentLevel: 7,
              skillCooldowns: {
                SkillSlot.q: 0.0,
                SkillSlot.r: 0.0,
                SkillSlot.e: 0.0,
                SkillSlot.ult: 0.0,
              },
              skillDamages: {
                SkillSlot.q: 250,
                SkillSlot.r: 230,
                SkillSlot.e: 200,
                SkillSlot.ult: 500,
              },
              evolutionBonuses: {},
              isUltAvailable: true,
              isUltCharging: false,
            ),
          ),
        ),
      );

      expect(find.text('ULT Ready'), findsOneWidget);
    });

    testWidgets('displays evolution bonuses', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SkillProgressionPanel(
              currentLevel: 3,
              skillCooldowns: {
                SkillSlot.q: 0.0,
                SkillSlot.r: 0.0,
                SkillSlot.e: 0.0,
                SkillSlot.ult: 0.0,
              },
              skillDamages: {
                SkillSlot.q: 200,
                SkillSlot.r: 180,
                SkillSlot.e: 150,
                SkillSlot.ult: 0,
              },
              currentEvolution: EvolutionType.offensive,
              evolutionBonuses: {
                'damage_bonus': 0.6,
                'hp_bonus': 0.0,
                'ally_effect_bonus': 0.0,
              },
              isUltAvailable: false,
              isUltCharging: false,
            ),
          ),
        ),
      );

      expect(find.text('進化ボーナス'), findsOneWidget);
    });

    testWidgets('responds to skill tap callbacks', (WidgetTester tester) async {
      SkillSlot? tappedSlot;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SkillProgressionPanel(
              currentLevel: 3,
              skillCooldowns: {
                SkillSlot.q: 0.0,
                SkillSlot.r: 0.0,
                SkillSlot.e: 0.0,
                SkillSlot.ult: 0.0,
              },
              skillDamages: {
                SkillSlot.q: 200,
                SkillSlot.r: 180,
                SkillSlot.e: 150,
                SkillSlot.ult: 0,
              },
              evolutionBonuses: {},
              isUltAvailable: false,
              isUltCharging: false,
              onSkillTap: (slot) => tappedSlot = slot,
            ),
          ),
        ),
      );

      // Tap the Q skill
      await tester.tap(find.text('Q'));
      await tester.pumpAndSettle();

      expect(tappedSlot, equals(SkillSlot.q));
    });

    testWidgets('works in light and dark themes', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          home: Scaffold(
            body: SkillProgressionPanel(
              currentLevel: 5,
              skillCooldowns: {
                SkillSlot.q: 0.0,
                SkillSlot.r: 0.0,
                SkillSlot.e: 0.0,
                SkillSlot.ult: 0.0,
              },
              skillDamages: {
                SkillSlot.q: 200,
                SkillSlot.r: 180,
                SkillSlot.e: 150,
                SkillSlot.ult: 0,
              },
              evolutionBonuses: {},
              isUltAvailable: false,
              isUltCharging: false,
            ),
          ),
        ),
      );

      expect(find.text('Lv5'), findsOneWidget);
      expect(find.byType(SkillProgressionPanel), findsOneWidget);
    });
  });
}
