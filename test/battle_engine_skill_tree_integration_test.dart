import 'package:flutter_test/flutter_test.dart';
import 'package:shinjuu_league/data/models/battle_model.dart';
import 'package:shinjuu_league/data/models/mecha_model.dart';
import 'package:shinjuu_league/data/models/evolution_model.dart';
import 'package:shinjuu_league/services/battle_engine_service.dart';

void main() {
  group('BattleEngine - Skill Tree Integration', () {
    late List<BattleParticipantState> participants;
    late BattleEngine engine;

    setUp(() {
      participants = [
        _participant(
          userId: 'player1',
          team: 0,
          lane: 0,
          baseStats: BaseStats(hp: 100, atk: 20, def: 10, spd: 15),
        ),
        _participant(
          userId: 'enemy1',
          team: 1,
          lane: 0,
          baseStats: BaseStats(hp: 100, atk: 20, def: 10, spd: 15),
          isBot: true,
        ),
      ];

      engine = BattleEngine(
        battleId: 'test_battle',
        mode: BattleMode.quick,
        mapId: 'map_1',
        participants: participants,
      );
    });

    group('Skill Tree Modifier Fields', () {
      test('participant has skill tree modifier fields with default values',
          () {
        final participant = participants[0];
        expect(participant.skillTreeAtkMultiplier, equals(1.0));
        expect(participant.skillTreeDefMultiplier, equals(1.0));
        expect(participant.skillTreeSpdMultiplier, equals(1.0));
      });

      test('setSkillTreeModifiers updates all multiplier fields', () {
        final participant = participants[0];

        engine.setSkillTreeModifiers(
          'player1',
          atkMultiplier: 1.15,
          defMultiplier: 1.20,
          spdMultiplier: 1.10,
        );

        expect(participant.skillTreeAtkMultiplier, equals(1.15));
        expect(participant.skillTreeDefMultiplier, equals(1.20));
        expect(participant.skillTreeSpdMultiplier, equals(1.10));
      });

      test('setSkillTreeModifiers with invalid userId does nothing', () {
        final participant = participants[0];
        final originalAtk = participant.skillTreeAtkMultiplier;

        engine.setSkillTreeModifiers(
          'invalid_user',
          atkMultiplier: 1.15,
          defMultiplier: 1.20,
          spdMultiplier: 1.10,
        );

        expect(participant.skillTreeAtkMultiplier, equals(originalAtk));
      });
    });

    group('Effective ATK Calculation with Skill Tree Modifiers', () {
      test('effective ATK applies skill tree multiplier', () {
        final participant = participants[0];
        final baseAtk = participant.effectiveAtk;

        engine.setSkillTreeModifiers(
          'player1',
          atkMultiplier: 1.25, // +25% attack
          defMultiplier: 1.0,
          spdMultiplier: 1.0,
        );

        final modifiedAtk = participant.effectiveAtk;
        expect(modifiedAtk, closeTo(baseAtk * 1.25, 0.01));
      });

      test('effective ATK with 5% attack bonus from skill tree', () {
        final participant = participants[0];

        engine.setSkillTreeModifiers(
          'player1',
          atkMultiplier: 1.05,
          defMultiplier: 1.0,
          spdMultiplier: 1.0,
        );

        expect(participant.effectiveAtk, closeTo(21.0, 0.1));
      });

      test('effective ATK with cumulative modifiers (evolution + skill tree)', () {
        final participant = participants[0];

        // Set evolution first (assume 1.1x multiplier)
        participant.evolution = Evolution(
          from: 'normal',
          to: 'fire',
          statBoost: StatBoost(atkMultiplier: 1.1, defMultiplier: 1.0, hpMultiplier: 1.0, spdMultiplier: 1.0),
        );

        engine.setSkillTreeModifiers(
          'player1',
          atkMultiplier: 1.15,
          defMultiplier: 1.0,
          spdMultiplier: 1.0,
        );

        final atkWithEvolution = 20 * 1.1;
        final atkWithBoth = atkWithEvolution * 1.15;
        expect(participant.effectiveAtk, closeTo(atkWithBoth, 0.01));
      });

      test('effective ATK with no modifier (multiplier = 1.0)', () {
        final participant = participants[0];
        final baseAtk = participant.effectiveAtk;

        engine.setSkillTreeModifiers(
          'player1',
          atkMultiplier: 1.0,
          defMultiplier: 1.0,
          spdMultiplier: 1.0,
        );

        expect(participant.effectiveAtk, equals(baseAtk));
      });
    });

    group('Effective HP Calculation with Skill Tree Modifiers', () {
      test('effective HP applies skill tree multiplier', () {
        final participant = participants[0];
        final baseHp = participant.effectiveHp;

        engine.setSkillTreeModifiers(
          'player1',
          atkMultiplier: 1.0,
          defMultiplier: 1.40, // +40% defense (affects HP)
          spdMultiplier: 1.0,
        );

        final modifiedHp = participant.effectiveHp;
        expect(modifiedHp, closeTo(baseHp * 1.40, 0.01));
      });

      test('effective HP with 8% defense bonus from skill tree', () {
        final participant = participants[0];

        engine.setSkillTreeModifiers(
          'player1',
          atkMultiplier: 1.0,
          defMultiplier: 1.08,
          spdMultiplier: 1.0,
        );

        expect(participant.effectiveHp, closeTo(108.0, 0.1));
      });

      test('currentHp is capped when skill tree modifiers reduce max HP', () {
        final participant = participants[0];
        participant.currentHp = 150; // Over max (100)

        engine.setSkillTreeModifiers(
          'player1',
          atkMultiplier: 1.0,
          defMultiplier: 1.0,
          spdMultiplier: 1.0,
        );

        // currentHp should not exceed effectiveHp
        expect(participant.currentHp, lessThanOrEqualTo(participant.effectiveHp));
      });

      test('effective HP with cumulative modifiers (evolution + skill tree)', () {
        final participant = participants[0];

        participant.evolution = Evolution(
          from: 'normal',
          to: 'fire',
          statBoost: StatBoost(atkMultiplier: 1.0, defMultiplier: 1.0, hpMultiplier: 1.15, spdMultiplier: 1.0),
        );

        engine.setSkillTreeModifiers(
          'player1',
          atkMultiplier: 1.0,
          defMultiplier: 1.20,
          spdMultiplier: 1.0,
        );

        final hpWithEvolution = 100 * 1.15;
        final hpWithBoth = hpWithEvolution * 1.20;
        expect(participant.effectiveHp, closeTo(hpWithBoth, 0.01));
      });
    });

    group('Effective SPD Calculation with Skill Tree Modifiers', () {
      test('effective SPD applies skill tree multiplier', () {
        final participant = participants[0];
        final baseSpd = participant.effectiveSpd;

        engine.setSkillTreeModifiers(
          'player1',
          atkMultiplier: 1.0,
          defMultiplier: 1.0,
          spdMultiplier: 1.15, // +15% speed
        );

        final modifiedSpd = participant.effectiveSpd;
        expect(modifiedSpd, closeTo(baseSpd * 1.15, 0.01));
      });

      test('effective SPD with 3% speed bonus from skill tree', () {
        final participant = participants[0];

        engine.setSkillTreeModifiers(
          'player1',
          atkMultiplier: 1.0,
          defMultiplier: 1.0,
          spdMultiplier: 1.03,
        );

        expect(participant.effectiveSpd, closeTo(15.45, 0.1));
      });

      test('effective SPD with cumulative modifiers (evolution + skill tree)', () {
        final participant = participants[0];

        participant.evolution = Evolution(
          from: 'normal',
          to: 'lightning',
          statBoost: StatBoost(atkMultiplier: 1.0, defMultiplier: 1.0, hpMultiplier: 1.0, spdMultiplier: 1.10),
        );

        engine.setSkillTreeModifiers(
          'player1',
          atkMultiplier: 1.0,
          defMultiplier: 1.0,
          spdMultiplier: 1.08,
        );

        final spdWithEvolution = 15 * 1.10;
        final spdWithBoth = spdWithEvolution * 1.08;
        expect(participant.effectiveSpd, closeTo(spdWithBoth, 0.01));
      });
    });

    group('Multiplicative Skill Tree Modifiers', () {
      test('attack and speed modifiers stack multiplicatively', () {
        final participant = participants[0];

        engine.setSkillTreeModifiers(
          'player1',
          atkMultiplier: 1.25,
          defMultiplier: 1.0,
          spdMultiplier: 1.10,
        );

        final atk = participant.effectiveAtk;
        final spd = participant.effectiveSpd;

        // ATK should be 1.25x
        expect(atk, closeTo(20 * 1.25, 0.1));

        // SPD should be 1.10x
        expect(spd, closeTo(15 * 1.10, 0.1));
      });

      test('all three modifiers apply independently', () {
        final participant = participants[0];

        engine.setSkillTreeModifiers(
          'player1',
          atkMultiplier: 1.20,
          defMultiplier: 1.15,
          spdMultiplier: 1.08,
        );

        final atk = participant.effectiveAtk;
        final hp = participant.effectiveHp;
        final spd = participant.effectiveSpd;

        expect(atk, closeTo(20 * 1.20, 0.1));
        expect(hp, closeTo(100 * 1.15, 0.1));
        expect(spd, closeTo(15 * 1.08, 0.1));
      });

      test('modifiers maintain precision with small values', () {
        final participant = participants[0];

        engine.setSkillTreeModifiers(
          'player1',
          atkMultiplier: 1.05,
          defMultiplier: 1.08,
          spdMultiplier: 1.03,
        );

        final atk = participant.effectiveAtk;
        expect(atk, closeTo(20 * 1.05, 0.001));
      });
    });

    group('Multiple Participants with Different Modifiers', () {
      test('each participant has independent skill tree modifiers', () {
        final player1 = participants[0];
        final enemy1 = participants[1];

        engine.setSkillTreeModifiers(
          'player1',
          atkMultiplier: 1.25,
          defMultiplier: 1.0,
          spdMultiplier: 1.0,
        );

        engine.setSkillTreeModifiers(
          'enemy1',
          atkMultiplier: 1.0,
          defMultiplier: 1.40,
          spdMultiplier: 1.0,
        );

        expect(player1.skillTreeAtkMultiplier, equals(1.25));
        expect(enemy1.skillTreeDefMultiplier, equals(1.40));
        expect(player1.effectiveAtk, closeTo(25.0, 0.1));
        expect(enemy1.effectiveHp, closeTo(140.0, 0.1));
      });

      test('modifying one participant does not affect others', () {
        final player1 = participants[0];
        final enemy1 = participants[1];
        final originalEnemyModifiers = (
          enemy1.skillTreeAtkMultiplier,
          enemy1.skillTreeDefMultiplier,
          enemy1.skillTreeSpdMultiplier,
        );

        engine.setSkillTreeModifiers(
          'player1',
          atkMultiplier: 1.50,
          defMultiplier: 1.50,
          spdMultiplier: 1.50,
        );

        expect(enemy1.skillTreeAtkMultiplier, equals(originalEnemyModifiers.$1));
        expect(enemy1.skillTreeDefMultiplier, equals(originalEnemyModifiers.$2));
        expect(enemy1.skillTreeSpdMultiplier, equals(originalEnemyModifiers.$3));
      });
    });

    group('Combat Damage with Skill Tree Modifiers', () {
      test('damage calculation respects ATK skill tree modifier', () {
        final attacker = participants[0];
        final defender = participants[1];

        // Set attacker's ATK multiplier to 1.25
        engine.setSkillTreeModifiers(
          'player1',
          atkMultiplier: 1.25,
          defMultiplier: 1.0,
          spdMultiplier: 1.0,
        );

        final atkWithModifier = attacker.effectiveAtk;
        expect(atkWithModifier, closeTo(25.0, 0.1));
      });

      test('defense skill tree modifier increases effective HP', () {
        final defender = participants[1];

        engine.setSkillTreeModifiers(
          'enemy1',
          atkMultiplier: 1.0,
          defMultiplier: 1.20,
          spdMultiplier: 1.0,
        );

        final hpWithModifier = defender.effectiveHp;
        expect(hpWithModifier, closeTo(120.0, 0.1));
      });
    });

    group('Edge Cases', () {
      test('multiplier of 1.0 means no modification', () {
        final participant = participants[0];
        final baseAtk = participant.effectiveAtk;
        final baseHp = participant.effectiveHp;
        final baseSpd = participant.effectiveSpd;

        engine.setSkillTreeModifiers(
          'player1',
          atkMultiplier: 1.0,
          defMultiplier: 1.0,
          spdMultiplier: 1.0,
        );

        expect(participant.effectiveAtk, equals(baseAtk));
        expect(participant.effectiveHp, equals(baseHp));
        expect(participant.effectiveSpd, equals(baseSpd));
      });

      test('zero multiplier produces minimal stats', () {
        final participant = participants[0];

        engine.setSkillTreeModifiers(
          'player1',
          atkMultiplier: 0.0,
          defMultiplier: 0.0,
          spdMultiplier: 0.0,
        );

        expect(participant.effectiveAtk, closeTo(0.0, 0.01));
        expect(participant.effectiveHp, closeTo(0.0, 0.01));
        expect(participant.effectiveSpd, closeTo(0.0, 0.01));
      });

      test('very high multiplier scales stats proportionally', () {
        final participant = participants[0];
        final baseAtk = 20.0;

        engine.setSkillTreeModifiers(
          'player1',
          atkMultiplier: 5.0, // 500% multiplier
          defMultiplier: 1.0,
          spdMultiplier: 1.0,
        );

        expect(participant.effectiveAtk, closeTo(baseAtk * 5.0, 0.1));
      });
    });
  });
}

/// Helper function to create test participant
BattleParticipantState _participant({
  required String userId,
  required int team,
  required int lane,
  required BaseStats baseStats,
  bool isBot = false,
  Evolution? evolution,
}) {
  return BattleParticipantState(
    userId: userId,
    mechaId: 'mecha_1',
    isBot: isBot,
    isSelf: !isBot,
    team: team,
    lane: lane,
    baseStats: baseStats,
    evolution: evolution,
  );
}
