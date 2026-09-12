import 'package:flutter_test/flutter_test.dart';
import 'package:shinjuu_league/data/models/evolution_state.dart';
import 'package:shinjuu_league/data/models/skill_catalog.dart';
import 'package:shinjuu_league/services/skill_progression_battle_service.dart';
import 'package:shinjuu_league/services/skill_progression_coordinator.dart';
import 'package:shinjuu_league/viewmodels/battle_skill_progression_viewmodel.dart';

void main() {
  group('Full Skill Progression Integration Tests', () {
    late BattleSkillProgressionCoordinator coordinator;
    late BattleSkillProgressionViewModel viewModel;

    setUp(() {
      coordinator = BattleSkillProgressionCoordinator();
      viewModel = BattleSkillProgressionViewModel();
    });

    tearDown(() {
      coordinator.dispose();
      viewModel.dispose();
    });

    test('Complete Lv1-Lv8 progression with Coordinator', () async {
      coordinator.initializePlayer(playerId: 'player1', mechaId: 'leon');

      final events = <BattleSkillEvent>[];
      coordinator.skillEvents.listen(events.add);

      // Level up through full progression
      for (int lv = 1; lv <= 8; lv++) {
        if (lv > 1) {
          coordinator.levelUpPlayer('player1');
        }

        var state = coordinator.getPlayerSkillState('player1');
        expect(state!.currentLevel, equals(lv));

        // Handle evolution choices
        if (lv == 3) {
          expect(state.isEvolutionLocked, isTrue);
          coordinator.confirmEvolution('player1', EvolutionType.offensive);
          state = coordinator.getPlayerSkillState('player1');
          expect(state!.isEvolutionLocked, isFalse);
        } else if (lv == 6) {
          expect(state.isEvolutionLocked, isTrue);
          coordinator.switchEvolution('player1', EvolutionType.support);
          state = coordinator.getPlayerSkillState('player1');
          expect(state!.currentEvolution, equals(EvolutionType.support));
        }
      }

      await Future.delayed(const Duration(milliseconds: 50));

      // Verify events were emitted
      expect(events.isNotEmpty, isTrue);
      final levelUpEvents = events.whereType<PlayerLevelUpEvent>().toList();
      expect(levelUpEvents.length, equals(7)); // Lv2-8

      final evolutionEvents = events.whereType<EvolutionSelectionRequiredEvent>().toList();
      expect(evolutionEvents.length, equals(2)); // Lv3 and Lv6
    });

    test('Complete progression with ViewModel state tracking', () {
      viewModel.initializePlayer(playerId: 'player1', mechaId: 'leon');

      for (int lv = 1; lv <= 8; lv++) {
        if (lv > 1) {
          viewModel.levelUpPlayer('player1');
        }

        var uiState = viewModel.getPlayerUIState('player1');
        expect(uiState!.currentLevel, equals(lv));

        if (lv == 3) {
          viewModel.confirmEvolution('player1', EvolutionType.offensive);
        } else if (lv == 6) {
          viewModel.switchEvolution('player1', EvolutionType.defensive);
        }

        // Check ULT states match expected progression
        if (lv < 5) {
          expect(uiState!.isUltUnlocked, isFalse);
          expect(uiState.isUltCharging, isFalse);
        } else if (lv < 7) {
          expect(uiState!.isUltCharging, isTrue);
        } else {
          expect(uiState!.isUltUnlocked, isTrue);
        }
      }

      final finalState = viewModel.getPlayerUIState('player1');
      expect(finalState!.currentLevel, equals(8));
      expect(finalState.currentEvolution, equals(EvolutionType.defensive));
      expect(finalState.isUltUnlocked, isTrue);
    });

    test('Skill usage integration: cooldown and evolution bonuses', () {
      coordinator.initializePlayer(playerId: 'player1', mechaId: 'leon');

      // At Lv1, use skill without evolution
      var canUse = coordinator.tryUseSkill('player1', SkillSlot.q, baseSkillDamage: 200);
      expect(canUse, isTrue);

      var state = coordinator.getPlayerSkillState('player1');
      expect(state!.skillCooldowns[SkillSlot.q], equals(4.0));

      // Advance time to reset cooldown
      coordinator.onGameTick(5.0);

      // Level up to 3 and apply offensive evolution
      coordinator.levelUpPlayer('player1');
      coordinator.levelUpPlayer('player1');
      coordinator.confirmEvolution('player1', EvolutionType.offensive);

      final events = <BattleSkillEvent>[];
      coordinator.skillEvents.listen(events.add);

      // Use skill again with evolution bonus
      canUse = coordinator.tryUseSkill('player1', SkillSlot.q, baseSkillDamage: 200);
      expect(canUse, isTrue);

      // Verify skill usage event includes bonus damage
      final skillEvents = events.whereType<SkillUsedEvent>().toList();
      expect(skillEvents.isNotEmpty, isTrue);
      expect(skillEvents[0].damageDealt, greaterThan(200)); // Should include offensive bonus
    });

    test('Multi-player independent progression', () {
      coordinator.initializePlayer(playerId: 'player1', mechaId: 'leon');
      coordinator.initializePlayer(playerId: 'player2', mechaId: 'wolf');
      coordinator.initializePlayer(playerId: 'player3', mechaId: 'dragoon');

      // Progress each player to different levels
      coordinator.levelUpPlayer('player1');
      coordinator.levelUpPlayer('player1');

      coordinator.levelUpPlayer('player2');
      coordinator.levelUpPlayer('player2');
      coordinator.levelUpPlayer('player2');
      coordinator.levelUpPlayer('player2');

      // player3 stays at Lv1

      final state1 = coordinator.getPlayerSkillState('player1');
      final state2 = coordinator.getPlayerSkillState('player2');
      final state3 = coordinator.getPlayerSkillState('player3');

      expect(state1!.currentLevel, equals(3));
      expect(state2!.currentLevel, equals(5));
      expect(state3!.currentLevel, equals(1));

      // Apply different evolutions
      coordinator.confirmEvolution('player1', EvolutionType.offensive);
      coordinator.confirmEvolution('player2', EvolutionType.defensive);

      final updated1 = coordinator.getPlayerSkillState('player1');
      final updated2 = coordinator.getPlayerSkillState('player2');

      expect(updated1!.currentEvolution, equals(EvolutionType.offensive));
      expect(updated2!.currentEvolution, equals(EvolutionType.defensive));
    });

    test('Evolution bonus calculation across all types', () {
      coordinator.initializePlayer(playerId: 'p_offensive', mechaId: 'leon');
      coordinator.initializePlayer(playerId: 'p_defensive', mechaId: 'wolf');
      coordinator.initializePlayer(playerId: 'p_support', mechaId: 'dragoon');

      // Progress to Lv3
      for (final playerId in ['p_offensive', 'p_defensive', 'p_support']) {
        coordinator.levelUpPlayer(playerId);
        coordinator.levelUpPlayer(playerId);
      }

      // Apply different evolutions
      coordinator.confirmEvolution('p_offensive', EvolutionType.offensive);
      coordinator.confirmEvolution('p_defensive', EvolutionType.defensive);
      coordinator.confirmEvolution('p_support', EvolutionType.support);

      final offensiveState = coordinator.getPlayerSkillState('p_offensive');
      final defensiveState = coordinator.getPlayerSkillState('p_defensive');
      final supportState = coordinator.getPlayerSkillState('p_support');

      // Verify bonuses are applied correctly
      expect(offensiveState!.evolutionBonuses['damage_bonus'], greaterThan(0.0));
      expect(defensiveState!.evolutionBonuses['hp_bonus'], greaterThan(0.0));
      expect(supportState!.evolutionBonuses['ally_effect_bonus'], greaterThan(0.0));
    });

    test('Evolution switching at Lv6', () {
      coordinator.initializePlayer(playerId: 'player1', mechaId: 'leon');

      // Progress to Lv3
      coordinator.levelUpPlayer('player1');
      coordinator.levelUpPlayer('player1');
      coordinator.confirmEvolution('player1', EvolutionType.offensive);

      // Progress to Lv6
      coordinator.levelUpPlayer('player1');
      coordinator.levelUpPlayer('player1');
      coordinator.levelUpPlayer('player1');

      var state = coordinator.getPlayerSkillState('player1');
      expect(state!.isEvolutionLocked, isTrue);
      expect(state.currentEvolution, equals(EvolutionType.offensive));

      // Switch evolution
      coordinator.switchEvolution('player1', EvolutionType.defensive);

      state = coordinator.getPlayerSkillState('player1');
      expect(state!.isEvolutionLocked, isFalse);
      expect(state.currentEvolution, equals(EvolutionType.defensive));
    });

    test('Skill cooldown management over time', () {
      coordinator.initializePlayer(playerId: 'player1', mechaId: 'leon');

      // Use all four skills
      coordinator.tryUseSkill('player1', SkillSlot.q, baseSkillDamage: 200);
      coordinator.tryUseSkill('player1', SkillSlot.r, baseSkillDamage: 180);

      var state = coordinator.getPlayerSkillState('player1');
      expect(state!.skillCooldowns[SkillSlot.q], equals(4.0));
      expect(state.skillCooldowns[SkillSlot.r], equals(8.0));

      // Advance 2 seconds
      coordinator.onGameTick(2.0);

      state = coordinator.getPlayerSkillState('player1');
      expect(state!.skillCooldowns[SkillSlot.q], equals(2.0));
      expect(state.skillCooldowns[SkillSlot.r], equals(6.0));

      // Advance more to fully reset Q
      coordinator.onGameTick(3.0);

      state = coordinator.getPlayerSkillState('player1');
      expect(state!.skillCooldowns[SkillSlot.q], equals(0.0)); // Clamped to 0
      expect(state.skillCooldowns[SkillSlot.r], equals(3.0));

      // Q should be usable again
      final canUseQ = coordinator.tryUseSkill('player1', SkillSlot.q, baseSkillDamage: 200);
      expect(canUseQ, isTrue);
    });

    test('Auto-confirm evolution on timeout', () {
      coordinator.initializePlayer(playerId: 'player1', mechaId: 'leon');

      coordinator.levelUpPlayer('player1');
      coordinator.levelUpPlayer('player1');

      var state = coordinator.getPlayerSkillState('player1');
      expect(state!.isEvolutionLocked, isTrue);

      // Auto-confirm (should default to offensive)
      coordinator.autoConfirmEvolution('player1');

      state = coordinator.getPlayerSkillState('player1');
      expect(state!.isEvolutionLocked, isFalse);
      expect(state.currentEvolution, equals(EvolutionType.offensive));
    });

    test('All 6 characters complete progression', () {
      final characters = ['leon', 'wolf', 'dragoon', 'frost', 'phoenix', 'crystal'];

      for (final charId in characters) {
        final testCoordinator = BattleSkillProgressionCoordinator();

        testCoordinator.initializePlayer(playerId: charId, mechaId: charId);

        for (int lv = 1; lv <= 8; lv++) {
          if (lv > 1) {
            testCoordinator.levelUpPlayer(charId);
          }

          final state = testCoordinator.getPlayerSkillState(charId);
          expect(state, isNotNull, reason: '$charId at Lv$lv should have valid state');
          expect(state!.currentLevel, equals(lv));

          if (lv == 3) {
            testCoordinator.confirmEvolution(charId, EvolutionType.offensive);
            final evolved = testCoordinator.getPlayerSkillState(charId);
            expect(evolved!.currentEvolution, equals(EvolutionType.offensive),
                reason: '$charId should have offensive evolution at Lv3');
          } else if (lv == 6) {
            testCoordinator.switchEvolution(charId, EvolutionType.support);
            final switched = testCoordinator.getPlayerSkillState(charId);
            expect(switched!.currentEvolution, equals(EvolutionType.support),
                reason: '$charId should switch to support at Lv6');
          }
        }

        testCoordinator.dispose();
      }
    });

    test('Event stream coordination between layers', () async {
      coordinator.initializePlayer(playerId: 'player1', mechaId: 'leon');

      final allEvents = <BattleSkillEvent>[];
      coordinator.skillEvents.listen(allEvents.add);

      // Trigger multiple events
      coordinator.levelUpPlayer('player1'); // LevelUpEvent
      coordinator.levelUpPlayer('player1'); // LevelUpEvent + EvolutionRequiredEvent
      coordinator.confirmEvolution('player1', EvolutionType.offensive);
      coordinator.tryUseSkill('player1', SkillSlot.q, baseSkillDamage: 200); // SkillUsedEvent

      await Future.delayed(const Duration(milliseconds: 50));

      // Verify event types and order
      expect(allEvents.length, greaterThanOrEqualTo(4));

      expect(allEvents[0], isA<PlayerLevelUpEvent>());
      expect(allEvents[1], isA<PlayerLevelUpEvent>());

      final evolutionEvent = allEvents
          .whereType<EvolutionSelectionRequiredEvent>()
          .firstWhere((e) => e.level == 3);
      expect(evolutionEvent, isNotNull);

      final skillEvent = allEvents.whereType<SkillUsedEvent>().firstOrNull;
      expect(skillEvent, isNotNull);
    });

    test('Coordinator and ViewModel state consistency', () {
      coordinator.initializePlayer(playerId: 'player1', mechaId: 'leon');
      viewModel.initializePlayer(playerId: 'player1', mechaId: 'leon');

      // Progress both in parallel
      coordinator.levelUpPlayer('player1');
      coordinator.levelUpPlayer('player1');
      viewModel.levelUpPlayer('player1');
      viewModel.levelUpPlayer('player1');

      final coordState = coordinator.getPlayerSkillState('player1');
      final vmState = viewModel.getPlayerUIState('player1');

      expect(coordState!.currentLevel, equals(vmState!.currentLevel));
      expect(coordState.currentLevel, equals(3));

      // Apply evolution
      coordinator.confirmEvolution('player1', EvolutionType.offensive);
      viewModel.confirmEvolution('player1', EvolutionType.offensive);

      final coordStateAfter = coordinator.getPlayerSkillState('player1');
      final vmStateAfter = viewModel.getPlayerUIState('player1');

      expect(coordStateAfter!.currentEvolution, equals(vmStateAfter!.currentEvolution));
    });

    test('Skill damage scaling across levels', () {
      coordinator.initializePlayer(playerId: 'player1', mechaId: 'leon');

      final damagesByLevel = <int, int>{};

      for (int lv = 1; lv <= 8; lv++) {
        if (lv > 1) {
          coordinator.levelUpPlayer('player1');
        }

        if (lv == 3) {
          coordinator.confirmEvolution('player1', EvolutionType.offensive);
        } else if (lv == 6) {
          coordinator.switchEvolution('player1', EvolutionType.offensive);
        }

        // Reset cooldown if needed
        if (lv > 1) {
          coordinator.onGameTick(10.0);
        }

        final events = <BattleSkillEvent>[];
        coordinator.skillEvents.listen(events.add);

        final canUse = coordinator.tryUseSkill('player1', SkillSlot.q, baseSkillDamage: 200);
        if (canUse) {
          final skillEvent = events.whereType<SkillUsedEvent>().firstOrNull;
          if (skillEvent != null) {
            damagesByLevel[lv] = skillEvent.damageDealt;
          }
        }
      }

      // Verify damage increases with level
      final damages = damagesByLevel.values.toList();
      for (int i = 1; i < damages.length; i++) {
        // Allow some variance due to evolution changes
        expect(damages[i], greaterThanOrEqualTo(damages[i - 1]),
            reason: 'Damage at Lv${i + 1} should be >= Lv$i');
      }
    });

    test('Event emission for all skill slots', () async {
      coordinator.initializePlayer(playerId: 'player1', mechaId: 'leon');

      final events = <BattleSkillEvent>[];
      coordinator.skillEvents.listen(events.add);

      // Try all four slots
      coordinator.tryUseSkill('player1', SkillSlot.q, baseSkillDamage: 200);
      coordinator.onGameTick(10.0);

      coordinator.tryUseSkill('player1', SkillSlot.r, baseSkillDamage: 180);
      coordinator.onGameTick(10.0);

      coordinator.tryUseSkill('player1', SkillSlot.e, baseSkillDamage: 150);
      coordinator.onGameTick(10.0);

      // Level to 7 for ULT
      for (int i = 0; i < 6; i++) {
        coordinator.levelUpPlayer('player1');
        if (i == 1) coordinator.confirmEvolution('player1', EvolutionType.offensive);
        if (i == 4) coordinator.switchEvolution('player1', EvolutionType.offensive);
      }
      coordinator.onGameTick(60.0);

      coordinator.tryUseSkill('player1', SkillSlot.ult, baseSkillDamage: 500);

      await Future.delayed(const Duration(milliseconds: 50));

      final skillEvents = events.whereType<SkillUsedEvent>().toList();
      expect(skillEvents.length, equals(4)); // All 4 slots used
      expect(skillEvents.map((e) => e.slot).toSet().length, equals(4)); // All different slots
    });
  });
}
