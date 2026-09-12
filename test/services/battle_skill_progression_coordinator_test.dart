import 'package:flutter_test/flutter_test.dart';
import 'package:shinjuu_league/data/models/evolution_state.dart';
import 'package:shinjuu_league/data/models/skill_catalog.dart';
import 'package:shinjuu_league/services/battle_skill_progression_coordinator.dart';

void main() {
  group('BattleSkillProgressionCoordinator', () {
    late BattleSkillProgressionCoordinator coordinator;

    setUp(() {
      coordinator = BattleSkillProgressionCoordinator();
    });

    tearDown(() {
      coordinator.dispose();
    });

    test('initializes player with Lv1', () {
      coordinator.initializePlayer(playerId: 'player1', mechaId: 'leon');

      final state = coordinator.getPlayerSkillState('player1');
      expect(state, isNotNull);
      expect(state!.currentLevel, equals(1));
      expect(state.currentEvolution, isNull);
      expect(state.isEvolutionLocked, isFalse);
    });

    test('levelUpPlayer emits PlayerLevelUpEvent', () async {
      coordinator.initializePlayer(playerId: 'player1', mechaId: 'leon');

      final events = <BattleSkillEvent>[];
      coordinator.skillEvents.listen(events.add);

      coordinator.levelUpPlayer('player1');
      await Future.delayed(const Duration(milliseconds: 10));

      expect(events.length, greaterThanOrEqualTo(1));
      expect(events[0], isA<PlayerLevelUpEvent>());
      expect((events[0] as PlayerLevelUpEvent).newLevel, equals(2));
    });

    test('levelUpPlayer emits EvolutionSelectionRequiredEvent at Lv3', () async {
      coordinator.initializePlayer(playerId: 'player1', mechaId: 'leon');

      final events = <BattleSkillEvent>[];
      coordinator.skillEvents.listen(events.add);

      coordinator.levelUpPlayer('player1');
      coordinator.levelUpPlayer('player1');
      await Future.delayed(const Duration(milliseconds: 10));

      final evolutionEvents = events.whereType<EvolutionSelectionRequiredEvent>().toList();
      expect(evolutionEvents.isNotEmpty, isTrue);
      expect(evolutionEvents[0].level, equals(3));
      expect(evolutionEvents[0].selectionType, equals(EvolutionSelectionType.first));
    });

    test('confirmEvolution unlocks evolution', () {
      coordinator.initializePlayer(playerId: 'player1', mechaId: 'leon');

      coordinator.levelUpPlayer('player1');
      coordinator.levelUpPlayer('player1');

      var state = coordinator.getPlayerSkillState('player1');
      expect(state!.isEvolutionLocked, isTrue);

      coordinator.confirmEvolution('player1', EvolutionType.offensive);

      state = coordinator.getPlayerSkillState('player1');
      expect(state!.isEvolutionLocked, isFalse);
      expect(state.currentEvolution, equals(EvolutionType.offensive));
    });

    test('tryUseSkill returns true when skill is ready', () {
      coordinator.initializePlayer(playerId: 'player1', mechaId: 'leon');

      final canUse = coordinator.tryUseSkill(
        'player1',
        SkillSlot.q,
        baseSkillDamage: 200,
      );

      expect(canUse, isTrue);
    });

    test('tryUseSkill returns false when skill is on cooldown', () {
      coordinator.initializePlayer(playerId: 'player1', mechaId: 'leon');

      // First use
      coordinator.tryUseSkill(
        'player1',
        SkillSlot.q,
        baseSkillDamage: 200,
      );

      // Try again immediately (should be on cooldown)
      final canUse = coordinator.tryUseSkill(
        'player1',
        SkillSlot.q,
        baseSkillDamage: 200,
      );

      expect(canUse, isFalse);
    });

    test('tryUseSkill emits SkillUsedEvent', () async {
      coordinator.initializePlayer(playerId: 'player1', mechaId: 'leon');

      final events = <BattleSkillEvent>[];
      coordinator.skillEvents.listen(events.add);

      coordinator.tryUseSkill(
        'player1',
        SkillSlot.q,
        baseSkillDamage: 200,
      );
      await Future.delayed(const Duration(milliseconds: 10));

      final skillEvents = events.whereType<SkillUsedEvent>().toList();
      expect(skillEvents.isNotEmpty, isTrue);
      expect(skillEvents[0].slot, equals(SkillSlot.q));
      expect(skillEvents[0].damageDealt, greaterThan(0));
    });

    test('tryUseSkill applies evolution bonus to damage', () {
      coordinator.initializePlayer(playerId: 'player1', mechaId: 'leon');

      // First use at Lv1 (no evolution)
      final events1 = <BattleSkillEvent>[];
      coordinator.skillEvents.listen(events1.add);

      coordinator.tryUseSkill(
        'player1',
        SkillSlot.q,
        baseSkillDamage: 200,
      );

      final damageWithoutEvolution =
          (events1.whereType<SkillUsedEvent>().firstOrNull?.damageDealt ?? 0);

      // Level up and apply evolution
      coordinator.levelUpPlayer('player1');
      coordinator.levelUpPlayer('player1');
      coordinator.confirmEvolution('player1', EvolutionType.offensive);

      // Wait for cooldown to expire
      coordinator.onGameTick(5.0);

      // Use skill again with evolution
      final events2 = <BattleSkillEvent>[];
      coordinator.skillEvents.listen(events2.add);

      coordinator.tryUseSkill(
        'player1',
        SkillSlot.q,
        baseSkillDamage: 200,
      );

      final damageWithEvolution =
          (events2.whereType<SkillUsedEvent>().firstOrNull?.damageDealt ?? 0);

      expect(damageWithEvolution, greaterThan(damageWithoutEvolution));
    });

    test('switchEvolution changes evolution at Lv6', () {
      coordinator.initializePlayer(playerId: 'player1', mechaId: 'leon');

      // Progress to Lv3
      for (int i = 0; i < 2; i++) {
        coordinator.levelUpPlayer('player1');
      }
      coordinator.confirmEvolution('player1', EvolutionType.offensive);

      // Progress to Lv6
      for (int i = 0; i < 3; i++) {
        coordinator.levelUpPlayer('player1');
      }

      var state = coordinator.getPlayerSkillState('player1');
      expect(state!.isEvolutionLocked, isTrue);

      coordinator.switchEvolution('player1', EvolutionType.defensive);

      state = coordinator.getPlayerSkillState('player1');
      expect(state!.currentEvolution, equals(EvolutionType.defensive));
    });

    test('onGameTick reduces cooldowns over time', () {
      coordinator.initializePlayer(playerId: 'player1', mechaId: 'leon');

      coordinator.tryUseSkill('player1', SkillSlot.q, baseSkillDamage: 200);

      var state = coordinator.getPlayerSkillState('player1');
      expect(state!.skillCooldowns[SkillSlot.q], equals(4.0));

      coordinator.onGameTick(1.5);

      state = coordinator.getPlayerSkillState('player1');
      expect(state!.skillCooldowns[SkillSlot.q], equals(2.5));

      coordinator.onGameTick(3.0);

      state = coordinator.getPlayerSkillState('player1');
      expect(state!.skillCooldowns[SkillSlot.q], equals(0.0));
    });

    test('autoConfirmEvolution confirms at Lv3 with offensive', () {
      coordinator.initializePlayer(playerId: 'player1', mechaId: 'leon');

      coordinator.levelUpPlayer('player1');
      coordinator.levelUpPlayer('player1');

      var state = coordinator.getPlayerSkillState('player1');
      expect(state!.isEvolutionLocked, isTrue);

      coordinator.autoConfirmEvolution('player1');

      state = coordinator.getPlayerSkillState('player1');
      expect(state!.isEvolutionLocked, isFalse);
      expect(state.currentEvolution, equals(EvolutionType.offensive));
    });

    test('autoConfirmEvolution maintains evolution at Lv6', () {
      coordinator.initializePlayer(playerId: 'player1', mechaId: 'leon');

      // Progress to Lv3
      for (int i = 0; i < 2; i++) {
        coordinator.levelUpPlayer('player1');
      }
      coordinator.confirmEvolution('player1', EvolutionType.defensive);

      // Progress to Lv6
      for (int i = 0; i < 3; i++) {
        coordinator.levelUpPlayer('player1');
      }

      var state = coordinator.getPlayerSkillState('player1');
      expect(state!.currentEvolution, equals(EvolutionType.defensive));

      coordinator.autoConfirmEvolution('player1');

      state = coordinator.getPlayerSkillState('player1');
      expect(state!.currentEvolution, equals(EvolutionType.offensive)); // Auto confirms offensive
    });

    test('getPlayerSkillState returns complete snapshot', () {
      coordinator.initializePlayer(playerId: 'player1', mechaId: 'leon');

      final snapshot = coordinator.getPlayerSkillState('player1');
      expect(snapshot, isNotNull);
      expect(snapshot!.playerId, equals('player1'));
      expect(snapshot.currentLevel, equals(1));
      expect(snapshot.skillCooldowns, isNotEmpty);
      expect(snapshot.evolutionBonuses, isNotEmpty);
    });

    test('multiple players maintain independent states', () {
      coordinator.initializePlayer(playerId: 'player1', mechaId: 'leon');
      coordinator.initializePlayer(playerId: 'player2', mechaId: 'wolf');

      coordinator.levelUpPlayer('player1');
      coordinator.levelUpPlayer('player1');

      final state1 = coordinator.getPlayerSkillState('player1');
      final state2 = coordinator.getPlayerSkillState('player2');

      expect(state1!.currentLevel, equals(3));
      expect(state2!.currentLevel, equals(1));
    });

    test('full game progression Lv1-8 with skills and evolution', () {
      coordinator.initializePlayer(playerId: 'player1', mechaId: 'leon');

      for (int lv = 1; lv <= 8; lv++) {
        if (lv > 1) {
          coordinator.levelUpPlayer('player1');
        }

        var state = coordinator.getPlayerSkillState('player1');
        expect(state!.currentLevel, equals(lv));

        if (lv == 3) {
          coordinator.confirmEvolution('player1', EvolutionType.offensive);
        } else if (lv == 6) {
          coordinator.switchEvolution('player1', EvolutionType.support);
        }

        // Try to use skill (should succeed at least once per level)
        if (lv == 1) {
          final canUse = coordinator.tryUseSkill(
            'player1',
            SkillSlot.q,
            baseSkillDamage: 200,
          );
          expect(canUse, isTrue);
        }

        // Advance cooldowns
        coordinator.onGameTick(10.0);
      }

      final finalState = coordinator.getPlayerSkillState('player1');
      expect(finalState!.currentLevel, equals(8));
      expect(finalState.isUltAvailable, isTrue);
    });

    test('debugDumpAllStates returns complete state map', () {
      coordinator.initializePlayer(playerId: 'player1', mechaId: 'leon');
      coordinator.initializePlayer(playerId: 'player2', mechaId: 'wolf');

      final dump = coordinator.debugDumpAllStates();

      expect(dump.containsKey('player1'), isTrue);
      expect(dump.containsKey('player2'), isTrue);
      expect(dump['player1']['current_level'], equals(1));
      expect(dump['player2']['current_level'], equals(1));
    });

    test('all 6 characters initialize properly', () {
      final characterIds = ['leon', 'wolf', 'dragoon', 'frost', 'phoenix', 'crystal'];

      for (final charId in characterIds) {
        final testCoordinator = BattleSkillProgressionCoordinator();
        testCoordinator.initializePlayer(playerId: charId, mechaId: charId);
        final state = testCoordinator.getPlayerSkillState(charId);
        expect(state, isNotNull, reason: '$charId should initialize');
        expect(state!.currentLevel, equals(1));
        testCoordinator.dispose();
      }
    });
  });

  group('BattleSkillEvent variants', () {
    test('PlayerLevelUpEvent has correct data', () {
      final event = PlayerLevelUpEvent(
        playerId: 'player1',
        newLevel: 5,
        showLevelUpAnimation: true,
      );

      expect(event.playerId, equals('player1'));
      expect(event.newLevel, equals(5));
      expect(event.showLevelUpAnimation, isTrue);
    });

    test('EvolutionSelectionRequiredEvent has correct data', () {
      final event = EvolutionSelectionRequiredEvent(
        playerId: 'player1',
        level: 3,
        selectionType: EvolutionSelectionType.first,
        availableChoices: [EvolutionType.offensive, EvolutionType.defensive],
      );

      expect(event.playerId, equals('player1'));
      expect(event.level, equals(3));
      expect(event.selectionType, equals(EvolutionSelectionType.first));
      expect(event.availableChoices.length, equals(2));
    });

    test('SkillUsedEvent has correct data', () {
      final event = SkillUsedEvent(
        playerId: 'player1',
        slot: SkillSlot.q,
        damageDealt: 250,
        isCritical: false,
      );

      expect(event.playerId, equals('player1'));
      expect(event.slot, equals(SkillSlot.q));
      expect(event.damageDealt, equals(250));
      expect(event.isCritical, isFalse);
    });
  });

  group('PlayerSkillStateSnapshot', () {
    test('creates correct snapshot', () {
      final snapshot = PlayerSkillStateSnapshot(
        playerId: 'player1',
        currentLevel: 5,
        currentEvolution: EvolutionType.offensive,
        isEvolutionLocked: false,
        skillCooldowns: {SkillSlot.q: 2.0},
        evolutionBonuses: {'damage_bonus': 0.6},
        isUltAvailable: false,
        isUltCharging: true,
      );

      expect(snapshot.playerId, equals('player1'));
      expect(snapshot.currentLevel, equals(5));
      expect(snapshot.currentEvolution, equals(EvolutionType.offensive));
      expect(snapshot.isUltCharging, isTrue);
    });
  });
}
