import 'package:flutter_test/flutter_test.dart';
import 'package:shinjuu_league/data/models/skill_catalog.dart';
import 'package:shinjuu_league/data/models/evolution_state.dart';
import 'package:shinjuu_league/services/skill_progression_service.dart';

void main() {
  group('SkillProgressionState', () {
    test('initial state has level 1', () {
      final state = SkillProgressionState(
        playerId: 'player1',
        mechaId: 'leon',
        currentLevel: 1,
        evolutionState:
            PlayerEvolutionState.initial(mechaId: 'leon', currentLevel: 1),
      );

      expect(state.currentLevel, equals(1));
      expect(state.evolutionState.currentEvolution, isNull);
    });

    test('getSkillDamage returns correct value at Lv1', () {
      final state = SkillProgressionState(
        playerId: 'player1',
        mechaId: 'leon',
        currentLevel: 1,
        evolutionState:
            PlayerEvolutionState.initial(mechaId: 'leon', currentLevel: 1),
      );

      final damage = state.getSkillDamage(SkillSlot.q);
      expect(damage, equals(200)); // Leon Q at Lv1
    });

    test('getSkillCooldown returns correct value', () {
      final state = SkillProgressionState(
        playerId: 'player1',
        mechaId: 'leon',
        currentLevel: 1,
        evolutionState:
            PlayerEvolutionState.initial(mechaId: 'leon', currentLevel: 1),
      );

      final cooldown = state.getSkillCooldown(SkillSlot.q);
      expect(cooldown, equals(4.0)); // Q skill cooldown
    });

    test('isSkillReady returns true when cooldown is 0', () {
      final state = SkillProgressionState(
        playerId: 'player1',
        mechaId: 'leon',
        currentLevel: 1,
        evolutionState:
            PlayerEvolutionState.initial(mechaId: 'leon', currentLevel: 1),
      );

      expect(state.isSkillReady(SkillSlot.q), isTrue);
    });

    test('useSkill sets cooldown', () {
      final state = SkillProgressionState(
        playerId: 'player1',
        mechaId: 'leon',
        currentLevel: 1,
        evolutionState:
            PlayerEvolutionState.initial(mechaId: 'leon', currentLevel: 1),
      );

      final afterUse = state.useSkill(SkillSlot.q);
      expect(afterUse.isSkillReady(SkillSlot.q), isFalse);
      expect(afterUse.skillCooldowns[SkillSlot.q], equals(4.0));
    });

    test('updateCooldowns decreases cooldown over time', () {
      final state = SkillProgressionState(
        playerId: 'player1',
        mechaId: 'leon',
        currentLevel: 1,
        evolutionState:
            PlayerEvolutionState.initial(mechaId: 'leon', currentLevel: 1),
      );

      var current = state.useSkill(SkillSlot.q);
      expect(current.skillCooldowns[SkillSlot.q], equals(4.0));

      current = current.updateCooldowns(1.0); // 1 second passed
      expect(current.skillCooldowns[SkillSlot.q], equals(3.0));

      current = current.updateCooldowns(3.0); // 3 more seconds
      expect(current.skillCooldowns[SkillSlot.q], equals(0.0));
      expect(current.isSkillReady(SkillSlot.q), isTrue);
    });

    test('levelUp increases level', () {
      final state = SkillProgressionState(
        playerId: 'player1',
        mechaId: 'leon',
        currentLevel: 1,
        evolutionState:
            PlayerEvolutionState.initial(mechaId: 'leon', currentLevel: 1),
      );

      final afterLvUp = state.levelUp();
      expect(afterLvUp.currentLevel, equals(2));
    });

    test('applyEvolution records choice at Lv3', () {
      final state = SkillProgressionState(
        playerId: 'player1',
        mechaId: 'leon',
        currentLevel: 3,
        evolutionState:
            PlayerEvolutionState.initial(mechaId: 'leon', currentLevel: 3),
      );

      final afterEvo = state.applyEvolution(EvolutionType.offensive);
      expect(afterEvo.evolutionState.currentEvolution,
          equals(EvolutionType.offensive));
      expect(afterEvo.evolutionState.lastEvolutionLevel, equals(3));
    });

    test('switchEvolution changes evolution at Lv6', () {
      var state = SkillProgressionState(
        playerId: 'player1',
        mechaId: 'leon',
        currentLevel: 6,
        evolutionState:
            PlayerEvolutionState.initial(mechaId: 'leon', currentLevel: 6),
      );

      state = state.applyEvolution(EvolutionType.offensive);
      expect(state.evolutionState.currentEvolution, equals(EvolutionType.offensive));

      state = state.switchEvolution(EvolutionType.defensive);
      expect(state.evolutionState.currentEvolution, equals(EvolutionType.defensive));
    });

    test('getEvolutionBonuses returns zeros when no evolution', () {
      final state = SkillProgressionState(
        playerId: 'player1',
        mechaId: 'leon',
        currentLevel: 2,
        evolutionState:
            PlayerEvolutionState.initial(mechaId: 'leon', currentLevel: 2),
      );

      final bonuses = state.getEvolutionBonuses();
      expect(bonuses['damage_bonus'], equals(0.0));
      expect(bonuses['hp_bonus'], equals(0.0));
    });

    test('getEvolutionBonuses returns correct values after evolution', () {
      var state = SkillProgressionState(
        playerId: 'player1',
        mechaId: 'leon',
        currentLevel: 3,
        evolutionState:
            PlayerEvolutionState.initial(mechaId: 'leon', currentLevel: 3),
      );

      state = state.applyEvolution(EvolutionType.offensive);
      final bonuses = state.getEvolutionBonuses();
      expect(bonuses['damage_bonus'], greaterThan(0.0));
    });

    test('isUltAvailable returns false before Lv7', () {
      var state = SkillProgressionState(
        playerId: 'player1',
        mechaId: 'leon',
        currentLevel: 6,
        evolutionState:
            PlayerEvolutionState.initial(mechaId: 'leon', currentLevel: 6),
      );

      expect(state.isUltAvailable(), isFalse);

      state = state.levelUp();
      expect(state.isUltAvailable(), isTrue);
    });

    test('isUltCharging returns true at Lv5-6', () {
      var state = SkillProgressionState(
        playerId: 'player1',
        mechaId: 'leon',
        currentLevel: 5,
        evolutionState:
            PlayerEvolutionState.initial(mechaId: 'leon', currentLevel: 5),
      );

      expect(state.isUltCharging(), isTrue);

      state = state.levelUp();
      expect(state.isUltCharging(), isTrue);

      state = state.levelUp();
      expect(state.isUltCharging(), isFalse);
      expect(state.isUltAvailable(), isTrue);
    });

    test('isSkillUnlocked checks slot availability', () {
      var state = SkillProgressionState(
        playerId: 'player1',
        mechaId: 'leon',
        currentLevel: 1,
        evolutionState:
            PlayerEvolutionState.initial(mechaId: 'leon', currentLevel: 1),
      );

      expect(state.isSkillUnlocked(SkillSlot.q), isTrue);
      expect(state.isSkillUnlocked(SkillSlot.r), isFalse);
      expect(state.isSkillUnlocked(SkillSlot.e), isFalse);
      expect(state.isSkillUnlocked(SkillSlot.ult), isFalse);

      state = state.levelUp(); // Lv2
      expect(state.isSkillUnlocked(SkillSlot.r), isTrue);

      state = state.levelUp(); // Lv3
      expect(state.isSkillUnlocked(SkillSlot.e), isTrue);
    });

    test('getNextEvolutionLevel returns correct level', () {
      var state = SkillProgressionState(
        playerId: 'player1',
        mechaId: 'leon',
        currentLevel: 1,
        evolutionState:
            PlayerEvolutionState.initial(mechaId: 'leon', currentLevel: 1),
      );

      expect(state.getNextEvolutionLevel(), equals(3));

      state = SkillProgressionState(
        playerId: 'player1',
        mechaId: 'leon',
        currentLevel: 3,
        evolutionState:
            PlayerEvolutionState.initial(mechaId: 'leon', currentLevel: 3),
      );
      expect(state.getNextEvolutionLevel(), equals(6));
    });
  });

  group('SkillProgressionService', () {
    late SkillProgressionService service;

    setUp(() {
      service = SkillProgressionService();
    });

    test('initializePlayer creates new player state', () {
      service.initializePlayer(playerId: 'player1', mechaId: 'leon');

      final state = service.getPlayerSkills('player1');
      expect(state, isNotNull);
      expect(state!.currentLevel, equals(1));
      expect(state.mechaId, equals('leon'));
    });

    test('levelUpPlayer increments level', () {
      service.initializePlayer(playerId: 'player1', mechaId: 'leon');
      service.levelUpPlayer('player1');

      final state = service.getPlayerSkills('player1');
      expect(state!.currentLevel, equals(2));
    });

    test('usePlayerSkill sets cooldown', () {
      service.initializePlayer(playerId: 'player1', mechaId: 'leon');
      service.usePlayerSkill('player1', SkillSlot.q);

      final state = service.getPlayerSkills('player1');
      expect(state!.isSkillReady(SkillSlot.q), isFalse);
    });

    test('updateAllCooldowns decreases all cooldowns', () {
      service.initializePlayer(playerId: 'player1', mechaId: 'leon');
      service.usePlayerSkill('player1', SkillSlot.q);

      service.updateAllCooldowns(2.0);

      final state = service.getPlayerSkills('player1');
      expect(state!.skillCooldowns[SkillSlot.q]!, lessThan(4.0));
    });

    test('confirmEvolution applies evolution at Lv3', () {
      service.initializePlayer(playerId: 'player1', mechaId: 'leon');

      // Level up to 3
      for (int i = 0; i < 2; i++) {
        service.levelUpPlayer('player1');
      }

      service.confirmEvolution('player1', EvolutionType.offensive);

      final state = service.getPlayerSkills('player1');
      expect(state!.evolutionState.currentEvolution,
          equals(EvolutionType.offensive));
    });

    test('switchEvolution changes evolution at Lv6', () {
      service.initializePlayer(playerId: 'player1', mechaId: 'leon');

      // Level up to 6
      for (int i = 0; i < 5; i++) {
        service.levelUpPlayer('player1');
      }

      service.confirmEvolution('player1', EvolutionType.offensive);
      service.switchEvolution('player1', EvolutionType.defensive);

      final state = service.getPlayerSkills('player1');
      expect(state!.evolutionState.currentEvolution,
          equals(EvolutionType.defensive));
    });

    test('full progression from Lv1 to Lv8 with evolution choices', () {
      service.initializePlayer(playerId: 'player1', mechaId: 'dragoon');

      // Simulate full game
      for (int lv = 1; lv <= 8; lv++) {
        if (lv > 1) {
          service.levelUpPlayer('player1');
        }

        var state = service.getPlayerSkills('player1');
        expect(state!.currentLevel, equals(lv));

        // Handle evolution choices
        if (lv == 3) {
          service.confirmEvolution('player1', EvolutionType.offensive);
          state = service.getPlayerSkills('player1');
          expect(state!.evolutionState.currentEvolution,
              equals(EvolutionType.offensive));
        } else if (lv == 6) {
          service.switchEvolution('player1', EvolutionType.support);
          state = service.getPlayerSkills('player1');
          expect(state!.evolutionState.currentEvolution,
              equals(EvolutionType.support));
        }

        // Check ULT states
        if (lv < 5) {
          expect(state!.isUltCharging(), isFalse);
          expect(state.isUltAvailable(), isFalse);
        } else if (lv < 7) {
          expect(state!.isUltCharging(), isTrue);
        } else {
          expect(state!.isUltAvailable(), isTrue);
        }
      }

      // Final state should be Lv8 with evolution applied
      final finalState = service.getPlayerSkills('player1');
      expect(finalState!.currentLevel, equals(8));
      expect(finalState.isUltAvailable(), isTrue);
      expect(finalState.evolutionState.evolutionCount, equals(2));
    });

    test('multiple players can have independent skill states', () {
      service.initializePlayer(playerId: 'player1', mechaId: 'leon');
      service.initializePlayer(playerId: 'player2', mechaId: 'dragoon');

      service.levelUpPlayer('player1');
      service.levelUpPlayer('player1');

      final state1 = service.getPlayerSkills('player1');
      final state2 = service.getPlayerSkills('player2');

      expect(state1!.currentLevel, equals(3));
      expect(state2!.currentLevel, equals(1));
    });

    test('getNextEvolutionLevel returns correct level', () {
      service.initializePlayer(playerId: 'player1', mechaId: 'leon');
      expect(service.getNextEvolutionLevel('player1'), equals(3));

      for (int i = 0; i < 2; i++) {
        service.levelUpPlayer('player1');
      }
      expect(service.getNextEvolutionLevel('player1'), equals(3));

      service.confirmEvolution('player1', EvolutionType.offensive);
      expect(service.getNextEvolutionLevel('player1'), equals(6));
    });

    test('debugDumpSkillStates returns all player info', () {
      service.initializePlayer(playerId: 'player1', mechaId: 'leon');
      service.levelUpPlayer('player1');
      service.confirmEvolution('player1', EvolutionType.offensive);

      final dump = service.debugDumpSkillStates();
      expect(dump['player1'], isNotNull);
      expect(dump['player1']['current_level'], equals(2));
      expect(dump['player1']['current_evolution'],
          contains('offensive'));
    });

    test('reset clears all player states', () {
      service.initializePlayer(playerId: 'player1', mechaId: 'leon');
      expect(service.getPlayerSkills('player1'), isNotNull);

      service.reset();
      expect(service.getPlayerSkills('player1'), isNull);
    });

    test('all 6 characters initialize properly', () {
      final characterIds = ['leon', 'wolf', 'dragoon', 'frost', 'phoenix', 'crystal'];

      for (final charId in characterIds) {
        service.initializePlayer(playerId: charId, mechaId: charId);
        final state = service.getPlayerSkills(charId);
        expect(state, isNotNull, reason: '$charId should initialize');
        expect(state!.mechaId, equals(charId));
      }
    });

    test('skill damage increases with level', () {
      service.initializePlayer(playerId: 'player1', mechaId: 'dragoon');

      final dmg1 = service.getPlayerSkills('player1')!.getSkillDamage(SkillSlot.q);

      // Level up to 8
      for (int i = 0; i < 7; i++) {
        service.levelUpPlayer('player1');
      }

      final dmg8 = service.getPlayerSkills('player1')!.getSkillDamage(SkillSlot.q);
      expect(dmg8, greaterThan(dmg1));
    });

    test('evolution bonuses apply correctly', () {
      service.initializePlayer(playerId: 'player1', mechaId: 'leon');

      // No evolution yet
      var bonuses = service.getPlayerSkills('player1')!.getEvolutionBonuses();
      expect(bonuses['damage_bonus'], equals(0.0));

      // Apply evolution at Lv3
      for (int i = 0; i < 2; i++) {
        service.levelUpPlayer('player1');
      }
      service.confirmEvolution('player1', EvolutionType.offensive);

      bonuses = service.getPlayerSkills('player1')!.getEvolutionBonuses();
      expect(bonuses['damage_bonus'], greaterThan(0.0));
    });
  });
}
