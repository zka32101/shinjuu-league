import 'package:flutter_test/flutter_test.dart';
import 'package:shinjuu_league/data/models/evolution_state.dart';
import 'package:shinjuu_league/data/models/skill_catalog.dart';
import 'package:shinjuu_league/services/skill_progression_battle_service.dart';

void main() {
  group('BattleSkillProgressionState', () {
    test('initializes with Lv1 and no evolution', () {
      final state = BattleSkillProgressionState(
        userId: 'player1',
        state: SkillProgressionState(
          playerId: 'player1',
          mechaId: 'leon',
          currentLevel: 1,
          evolutionState: PlayerEvolutionState.initial(mechaId: 'leon', currentLevel: 1),
        ),
      );

      expect(state.state.currentLevel, equals(1));
      expect(state.isEvolutionLocked, isFalse);
      expect(state.hasPendingLevelUp, isFalse);
    });

    test('levelUp triggers evolution lock at Lv3', () {
      var state = BattleSkillProgressionState(
        userId: 'player1',
        state: SkillProgressionState(
          playerId: 'player1',
          mechaId: 'leon',
          currentLevel: 2,
          evolutionState: PlayerEvolutionState.initial(mechaId: 'leon', currentLevel: 2),
        ),
      );

      state = state.levelUp();
      expect(state.state.currentLevel, equals(3));
      expect(state.isEvolutionLocked, isTrue);
      expect(state.hasPendingLevelUp, isTrue);
    });

    test('levelUp at Lv6 triggers evolution switch lock', () {
      var state = BattleSkillProgressionState(
        userId: 'player1',
        state: SkillProgressionState(
          playerId: 'player1',
          mechaId: 'leon',
          currentLevel: 5,
          evolutionState: PlayerEvolutionState.initial(mechaId: 'leon', currentLevel: 5),
        ),
      );

      state = state.levelUp();
      expect(state.state.currentLevel, equals(6));
      expect(state.isEvolutionLocked, isTrue);
    });

    test('levelUp does not lock evolution outside of Lv3/6', () {
      var state = BattleSkillProgressionState(
        userId: 'player1',
        state: SkillProgressionState(
          playerId: 'player1',
          mechaId: 'leon',
          currentLevel: 4,
          evolutionState: PlayerEvolutionState.initial(mechaId: 'leon', currentLevel: 4),
        ),
      );

      state = state.levelUp();
      expect(state.state.currentLevel, equals(5));
      expect(state.isEvolutionLocked, isFalse);
    });

    test('applyEvolution unlocks at Lv3', () {
      var state = BattleSkillProgressionState(
        userId: 'player1',
        state: SkillProgressionState(
          playerId: 'player1',
          mechaId: 'leon',
          currentLevel: 3,
          evolutionState: PlayerEvolutionState.initial(mechaId: 'leon', currentLevel: 3),
        ),
      )..isEvolutionLocked = true;

      state = state.applyEvolution(EvolutionType.offensive);
      expect(state.isEvolutionLocked, isFalse);
      expect(state.state.evolutionState.currentEvolution, equals(EvolutionType.offensive));
    });

    test('switchEvolution unlocks at Lv6', () {
      var state = BattleSkillProgressionState(
        userId: 'player1',
        state: SkillProgressionState(
          playerId: 'player1',
          mechaId: 'leon',
          currentLevel: 6,
          evolutionState: PlayerEvolutionState(
            mechaId: 'leon',
            currentLevel: 6,
            currentEvolution: EvolutionType.offensive,
            lastEvolutionLevel: 3,
            evolutionCount: 1,
          ),
        ),
      )..isEvolutionLocked = true;

      state = state.switchEvolution(EvolutionType.defensive);
      expect(state.isEvolutionLocked, isFalse);
      expect(state.state.evolutionState.currentEvolution, equals(EvolutionType.defensive));
    });

    test('useSkill sets cooldown', () {
      final state = BattleSkillProgressionState(
        userId: 'player1',
        state: SkillProgressionState(
          playerId: 'player1',
          mechaId: 'leon',
          currentLevel: 1,
          evolutionState: PlayerEvolutionState.initial(mechaId: 'leon', currentLevel: 1),
        ),
      );

      final after = state.useSkill(SkillSlot.q);
      expect(after.state.isSkillReady(SkillSlot.q), isFalse);
      expect(after.state.skillCooldowns[SkillSlot.q], equals(4.0));
    });

    test('updateCooldowns reduces all cooldowns', () {
      var state = BattleSkillProgressionState(
        userId: 'player1',
        state: SkillProgressionState(
          playerId: 'player1',
          mechaId: 'leon',
          currentLevel: 1,
          evolutionState: PlayerEvolutionState.initial(mechaId: 'leon', currentLevel: 1),
        ),
      );

      state = state.useSkill(SkillSlot.q);
      expect(state.state.skillCooldowns[SkillSlot.q], equals(4.0));

      state = state.updateCooldowns(1.5);
      expect(state.state.skillCooldowns[SkillSlot.q], equals(2.5));

      state = state.updateCooldowns(3.0);
      expect(state.state.skillCooldowns[SkillSlot.q], equals(0.0));
    });

    test('getEffectiveSkillDamage includes evolution bonus', () {
      var state = BattleSkillProgressionState(
        userId: 'player1',
        state: SkillProgressionState(
          playerId: 'player1',
          mechaId: 'leon',
          currentLevel: 3,
          evolutionState: PlayerEvolutionState.initial(mechaId: 'leon', currentLevel: 3),
        ),
      );

      // No evolution yet
      final damageNoEvolution = state.getEffectiveSkillDamage(SkillSlot.q);
      expect(damageNoEvolution, equals(200)); // Base Leon Q at Lv3

      // Apply evolution
      state = state.applyEvolution(EvolutionType.offensive);
      final damageWithEvolution = state.getEffectiveSkillDamage(SkillSlot.q);
      expect(damageWithEvolution, greaterThan(damageNoEvolution));
    });

    test('copyWith preserves all fields', () {
      final original = BattleSkillProgressionState(
        userId: 'player1',
        state: SkillProgressionState(
          playerId: 'player1',
          mechaId: 'leon',
          currentLevel: 3,
          evolutionState: PlayerEvolutionState.initial(mechaId: 'leon', currentLevel: 3),
        ),
      )
        ..isEvolutionLocked = true
        ..hasPendingLevelUp = true;

      final copy = original.copyWith();
      expect(copy.userId, equals(original.userId));
      expect(copy.state.currentLevel, equals(original.state.currentLevel));
      expect(copy.isEvolutionLocked, isTrue);
      expect(copy.hasPendingLevelUp, isTrue);
    });
  });

  group('SkillProgressionBattleService', () {
    late SkillProgressionBattleService service;

    setUp(() {
      service = SkillProgressionBattleService();
    });

    tearDown(() {
      service.dispose();
    });

    test('initializes player with Lv1', () {
      service.initializePlayer(playerId: 'player1', mechaId: 'leon');

      final progress = service.getProgress('player1');
      expect(progress, isNotNull);
      expect(progress!.state.currentLevel, equals(1));
    });

    test('levelUpPlayer triggers levelUpEvents', () async {
      service.initializePlayer(playerId: 'player1', mechaId: 'leon');

      final events = <LevelUpEvent>[];
      service.levelUpEvents.listen(events.add);

      service.levelUpPlayer('player1');
      service.levelUpPlayer('player1');

      await Future.delayed(const Duration(milliseconds: 10));

      expect(events.length, equals(2));
      expect(events[0].newLevel, equals(2));
      expect(events[1].newLevel, equals(3));
      expect(events[1].isEvolutionPointReached, isTrue);
    });

    test('levelUpPlayer triggers evolutionRequiredEvents at Lv3', () async {
      service.initializePlayer(playerId: 'player1', mechaId: 'leon');

      final events = <EvolutionRequiredEvent>[];
      service.evolutionRequiredEvents.listen(events.add);

      service.levelUpPlayer('player1');
      service.levelUpPlayer('player1');

      await Future.delayed(const Duration(milliseconds: 10));

      expect(events.length, equals(1));
      expect(events[0].level, equals(3));
      expect(events[0].evolutionType, equals(EvolutionSelectionType.first));
    });

    test('levelUpPlayer triggers evolutionRequiredEvents at Lv6', () async {
      service.initializePlayer(playerId: 'player1', mechaId: 'leon');

      final events = <EvolutionRequiredEvent>[];
      service.evolutionRequiredEvents.listen(events.add);

      // Level up to 3 and confirm evolution
      for (int i = 0; i < 2; i++) {
        service.levelUpPlayer('player1');
      }
      service.confirmEvolution('player1', EvolutionType.offensive);

      // Level up to 6
      for (int i = 0; i < 3; i++) {
        service.levelUpPlayer('player1');
      }

      await Future.delayed(const Duration(milliseconds: 10));

      expect(events.length, equals(2)); // One at Lv3, one at Lv6
      expect(events[1].evolutionType, equals(EvolutionSelectionType.second));
    });

    test('confirmEvolution locks evolution and unlocks evolution', () {
      service.initializePlayer(playerId: 'player1', mechaId: 'leon');

      // Level up to 3
      for (int i = 0; i < 2; i++) {
        service.levelUpPlayer('player1');
      }

      var progress = service.getProgress('player1');
      expect(progress!.isEvolutionLocked, isTrue);

      service.confirmEvolution('player1', EvolutionType.offensive);

      progress = service.getProgress('player1');
      expect(progress!.isEvolutionLocked, isFalse);
      expect(progress.state.evolutionState.currentEvolution, equals(EvolutionType.offensive));
    });

    test('useSkill applies cooldown', () {
      service.initializePlayer(playerId: 'player1', mechaId: 'leon');

      var progress = service.getProgress('player1');
      expect(progress!.state.isSkillReady(SkillSlot.q), isTrue);

      service.useSkill('player1', SkillSlot.q);

      progress = service.getProgress('player1');
      expect(progress!.state.isSkillReady(SkillSlot.q), isFalse);
    });

    test('updateAllCooldowns reduces cooldowns for all players', () {
      service.initializePlayer(playerId: 'player1', mechaId: 'leon');
      service.initializePlayer(playerId: 'player2', mechaId: 'wolf');

      service.useSkill('player1', SkillSlot.q);
      service.useSkill('player2', SkillSlot.r);

      service.updateAllCooldowns(2.0);

      var progress1 = service.getProgress('player1');
      var progress2 = service.getProgress('player2');

      expect(progress1!.state.skillCooldowns[SkillSlot.q], equals(2.0)); // 4.0 - 2.0
      expect(progress2!.state.skillCooldowns[SkillSlot.r], lessThan(8.0)); // 8.0 - 2.0
    });

    test('switchEvolution changes evolution at Lv6', () {
      service.initializePlayer(playerId: 'player1', mechaId: 'leon');

      // Progress to Lv6
      for (int i = 0; i < 5; i++) {
        service.levelUpPlayer('player1');
      }
      service.confirmEvolution('player1', EvolutionType.offensive);

      // Progress to Lv6
      service.levelUpPlayer('player1');

      service.switchEvolution('player1', EvolutionType.defensive);

      final progress = service.getProgress('player1');
      expect(progress!.state.evolutionState.currentEvolution, equals(EvolutionType.defensive));
    });

    test('multiple players maintain independent states', () {
      service.initializePlayer(playerId: 'player1', mechaId: 'leon');
      service.initializePlayer(playerId: 'player2', mechaId: 'wolf');

      service.levelUpPlayer('player1');
      service.levelUpPlayer('player1');

      final progress1 = service.getProgress('player1');
      final progress2 = service.getProgress('player2');

      expect(progress1!.state.currentLevel, equals(3));
      expect(progress2!.state.currentLevel, equals(1));
    });

    test('full progression from Lv1 to Lv8', () {
      service.initializePlayer(playerId: 'player1', mechaId: 'leon');

      for (int lv = 1; lv <= 8; lv++) {
        if (lv > 1) {
          service.levelUpPlayer('player1');
        }

        var progress = service.getProgress('player1');
        expect(progress!.state.currentLevel, equals(lv));

        // Handle evolution choices
        if (lv == 3) {
          service.confirmEvolution('player1', EvolutionType.offensive);
          progress = service.getProgress('player1');
          expect(progress!.state.evolutionState.currentEvolution, equals(EvolutionType.offensive));
        } else if (lv == 6) {
          service.switchEvolution('player1', EvolutionType.support);
          progress = service.getProgress('player1');
          expect(progress!.state.evolutionState.currentEvolution, equals(EvolutionType.support));
        }

        // Check ULT states
        if (lv < 5) {
          expect(progress!.state.isUltCharging(), isFalse);
          expect(progress.state.isUltAvailable(), isFalse);
        } else if (lv < 7) {
          expect(progress!.state.isUltCharging(), isTrue);
        } else {
          expect(progress!.state.isUltAvailable(), isTrue);
        }
      }
    });

    test('debugDumpBattleProgression includes all players', () {
      service.initializePlayer(playerId: 'player1', mechaId: 'leon');
      service.initializePlayer(playerId: 'player2', mechaId: 'dragoon');

      service.levelUpPlayer('player1');
      service.confirmEvolution('player1', EvolutionType.offensive);

      final dump = service.debugDumpBattleProgression();

      expect(dump['player1'], isNotNull);
      expect(dump['player1']['current_level'], equals(2));
      expect(dump['player1']['current_evolution'], contains('offensive'));
      expect(dump['player2'], isNotNull);
      expect(dump['player2']['current_level'], equals(1));
    });

    test('all 6 characters initialize properly', () {
      final characterIds = ['leon', 'wolf', 'dragoon', 'frost', 'phoenix', 'crystal'];

      for (final charId in characterIds) {
        service.initializePlayer(playerId: charId, mechaId: charId);
        final progress = service.getProgress(charId);
        expect(progress, isNotNull, reason: '$charId should initialize');
        expect(progress!.state.currentLevel, equals(1));
      }
    });
  });

  group('LevelUpEvent', () {
    test('records level and evolution point', () {
      final event = LevelUpEvent(
        playerId: 'player1',
        newLevel: 3,
        isEvolutionPointReached: true,
      );

      expect(event.playerId, equals('player1'));
      expect(event.newLevel, equals(3));
      expect(event.isEvolutionPointReached, isTrue);
    });
  });

  group('EvolutionRequiredEvent', () {
    test('records evolution type at Lv3', () {
      final event = EvolutionRequiredEvent(
        playerId: 'player1',
        level: 3,
        evolutionType: EvolutionSelectionType.first,
      );

      expect(event.playerId, equals('player1'));
      expect(event.level, equals(3));
      expect(event.evolutionType, equals(EvolutionSelectionType.first));
    });

    test('records evolution type at Lv6', () {
      final event = EvolutionRequiredEvent(
        playerId: 'player1',
        level: 6,
        evolutionType: EvolutionSelectionType.second,
      );

      expect(event.evolutionType, equals(EvolutionSelectionType.second));
    });
  });
}
