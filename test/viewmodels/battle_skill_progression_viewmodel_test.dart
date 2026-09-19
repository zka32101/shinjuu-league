import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shinjuu_league/data/models/evolution_state.dart';
import 'package:shinjuu_league/data/models/skill_catalog.dart';
import 'package:shinjuu_league/viewmodels/battle_skill_progression_viewmodel.dart';

void main() {
  group('BattleSkillProgressionUIState', () {
    test('initializes with Lv1 and no evolution', () {
      const state = BattleSkillProgressionUIState(
        playerId: 'player1',
        currentLevel: 1,
        currentEvolution: null,
        isEvolutionLocked: false,
        hasPendingLevelUp: false,
        ult_available: 0,
        ult_charging: 0,
        skillCooldowns: {},
        evolutionBonuses: {},
      );

      expect(state.playerId, equals('player1'));
      expect(state.currentLevel, equals(1));
      expect(state.currentEvolution, isNull);
      expect(state.isLocked, isFalse);
      expect(state.isUltUnlocked, isFalse);
      expect(state.isUltCharging, isFalse);
    });

    test('getEvolutionBonusText returns 未進化 when no evolution', () {
      const state = BattleSkillProgressionUIState(
        playerId: 'player1',
        currentLevel: 1,
        currentEvolution: null,
        isEvolutionLocked: false,
        hasPendingLevelUp: false,
        ult_available: 0,
        ult_charging: 0,
        skillCooldowns: {},
        evolutionBonuses: {},
      );

      expect(state.getEvolutionBonusText(), equals('未進化'));
    });

    test('getEvolutionBonusText shows damage bonus for offensive', () {
      const state = BattleSkillProgressionUIState(
        playerId: 'player1',
        currentLevel: 3,
        currentEvolution: EvolutionType.offensive,
        isEvolutionLocked: false,
        hasPendingLevelUp: false,
        ult_available: 0,
        ult_charging: 0,
        skillCooldowns: {},
        evolutionBonuses: {'damage_bonus': 0.6, 'hp_bonus': 0.0, 'ally_effect_bonus': 0.0},
      );

      final text = state.getEvolutionBonusText();
      expect(text, contains('ダメージ'));
      expect(text, contains('60'));
    });

    test('getEvolutionBonusText shows HP bonus for defensive', () {
      const state = BattleSkillProgressionUIState(
        playerId: 'player1',
        currentLevel: 3,
        currentEvolution: EvolutionType.defensive,
        isEvolutionLocked: false,
        hasPendingLevelUp: false,
        ult_available: 0,
        ult_charging: 0,
        skillCooldowns: {},
        evolutionBonuses: {'damage_bonus': 0.0, 'hp_bonus': 0.3, 'ally_effect_bonus': 0.0},
      );

      final text = state.getEvolutionBonusText();
      expect(text, contains('HP'));
      expect(text, contains('30'));
    });

    test('getEvolutionBonusText shows ally effect bonus for support', () {
      const state = BattleSkillProgressionUIState(
        playerId: 'player1',
        currentLevel: 3,
        currentEvolution: EvolutionType.support,
        isEvolutionLocked: false,
        hasPendingLevelUp: false,
        ult_available: 0,
        ult_charging: 0,
        skillCooldowns: {},
        evolutionBonuses: {'damage_bonus': 0.0, 'hp_bonus': 0.0, 'ally_effect_bonus': 0.5},
      );

      final text = state.getEvolutionBonusText();
      expect(text, contains('味方効果'));
      expect(text, contains('50'));
    });

    test('isSkillReady checks cooldown', () {
      const state = BattleSkillProgressionUIState(
        playerId: 'player1',
        currentLevel: 1,
        currentEvolution: null,
        isEvolutionLocked: false,
        hasPendingLevelUp: false,
        ult_available: 0,
        ult_charging: 0,
        skillCooldowns: {SkillSlot.q: 0.0, SkillSlot.r: 2.5},
        evolutionBonuses: {},
      );

      expect(state.isSkillReady(SkillSlot.q), isTrue);
      expect(state.isSkillReady(SkillSlot.r), isFalse);
    });

    test('isUltUnlocked checks ult_available flag', () {
      const state1 = BattleSkillProgressionUIState(
        playerId: 'player1',
        currentLevel: 6,
        currentEvolution: null,
        isEvolutionLocked: false,
        hasPendingLevelUp: false,
        ult_available: 0,
        ult_charging: 1,
        skillCooldowns: {},
        evolutionBonuses: {},
      );

      const state2 = BattleSkillProgressionUIState(
        playerId: 'player1',
        currentLevel: 7,
        currentEvolution: null,
        isEvolutionLocked: false,
        hasPendingLevelUp: false,
        ult_available: 1,
        ult_charging: 0,
        skillCooldowns: {},
        evolutionBonuses: {},
      );

      expect(state1.isUltUnlocked, isFalse);
      expect(state2.isUltUnlocked, isTrue);
    });

    test('copyWith preserves fields', () {
      const original = BattleSkillProgressionUIState(
        playerId: 'player1',
        currentLevel: 3,
        currentEvolution: EvolutionType.offensive,
        isEvolutionLocked: true,
        hasPendingLevelUp: true,
        ult_available: 0,
        ult_charging: 0,
        skillCooldowns: {SkillSlot.q: 2.0},
        evolutionBonuses: {'damage_bonus': 0.6},
      );

      final copy = original.copyWith(currentLevel: 4);
      expect(copy.playerId, equals('player1'));
      expect(copy.currentLevel, equals(4));
      expect(copy.currentEvolution, equals(EvolutionType.offensive));
      expect(copy.isEvolutionLocked, isTrue);
    });
  });

  group('BattleSkillProgressionViewModel', () {
    late BattleSkillProgressionViewModel viewModel;

    setUp(() {
      viewModel = BattleSkillProgressionViewModel();
    });

    test('initializes empty state', () {
      expect(viewModel.state, isEmpty);
    });

    test('initializePlayer creates UI state for player', () {
      viewModel.initializePlayer(playerId: 'player1', mechaId: 'leon');

      expect(viewModel.state.containsKey('player1'), isTrue);
      final uiState = viewModel.state['player1']!;
      expect(uiState.currentLevel, equals(1));
      expect(uiState.currentEvolution, isNull);
    });

    test('getPlayerUIState returns correct state', () {
      viewModel.initializePlayer(playerId: 'player1', mechaId: 'leon');

      final uiState = viewModel.getPlayerUIState('player1');
      expect(uiState, isNotNull);
      expect(uiState!.playerId, equals('player1'));
      expect(uiState.currentLevel, equals(1));
    });

    test('levelUpPlayer updates state', () {
      viewModel.initializePlayer(playerId: 'player1', mechaId: 'leon');

      viewModel.levelUpPlayer('player1');
      var uiState = viewModel.getPlayerUIState('player1');
      expect(uiState!.currentLevel, equals(2));

      viewModel.levelUpPlayer('player1');
      uiState = viewModel.getPlayerUIState('player1');
      expect(uiState!.currentLevel, equals(3));
    });

    test('levelUpPlayer triggers evolution lock at Lv3', () {
      viewModel.initializePlayer(playerId: 'player1', mechaId: 'leon');

      viewModel.levelUpPlayer('player1');
      viewModel.levelUpPlayer('player1');

      final uiState = viewModel.getPlayerUIState('player1');
      expect(uiState!.isEvolutionLocked, isTrue);
      expect(uiState.hasPendingLevelUp, isTrue);
    });

    test('confirmEvolution unlocks evolution', () {
      viewModel.initializePlayer(playerId: 'player1', mechaId: 'leon');

      viewModel.levelUpPlayer('player1');
      viewModel.levelUpPlayer('player1');

      var uiState = viewModel.getPlayerUIState('player1');
      expect(uiState!.isEvolutionLocked, isTrue);

      viewModel.confirmEvolution('player1', EvolutionType.offensive);

      uiState = viewModel.getPlayerUIState('player1');
      expect(uiState!.isEvolutionLocked, isFalse);
      expect(uiState.currentEvolution, equals(EvolutionType.offensive));
    });

    test('switchEvolution changes evolution at Lv6', () {
      viewModel.initializePlayer(playerId: 'player1', mechaId: 'leon');

      // Level to 3 and apply evolution
      for (int i = 0; i < 2; i++) {
        viewModel.levelUpPlayer('player1');
      }
      viewModel.confirmEvolution('player1', EvolutionType.offensive);

      // Level to 6
      for (int i = 0; i < 3; i++) {
        viewModel.levelUpPlayer('player1');
      }

      var uiState = viewModel.getPlayerUIState('player1');
      expect(uiState!.isEvolutionLocked, isTrue);

      viewModel.switchEvolution('player1', EvolutionType.defensive);

      uiState = viewModel.getPlayerUIState('player1');
      expect(uiState!.isEvolutionLocked, isFalse);
      expect(uiState.currentEvolution, equals(EvolutionType.defensive));
    });

    test('useSkill sets cooldown in state', () {
      viewModel.initializePlayer(playerId: 'player1', mechaId: 'leon');

      var uiState = viewModel.getPlayerUIState('player1');
      expect(uiState!.isSkillReady(SkillSlot.q), isTrue);

      viewModel.useSkill('player1', SkillSlot.q);

      uiState = viewModel.getPlayerUIState('player1');
      expect(uiState!.isSkillReady(SkillSlot.q), isFalse);
      expect(uiState.skillCooldowns[SkillSlot.q], equals(4.0));
    });

    test('updateAllCooldowns reduces cooldowns for all players', () {
      viewModel.initializePlayer(playerId: 'player1', mechaId: 'leon');
      viewModel.initializePlayer(playerId: 'player2', mechaId: 'wolf');

      viewModel.useSkill('player1', SkillSlot.q);
      viewModel.useSkill('player2', SkillSlot.r);

      var uiState1 = viewModel.getPlayerUIState('player1');
      var uiState2 = viewModel.getPlayerUIState('player2');

      expect(uiState1!.skillCooldowns[SkillSlot.q], equals(4.0));
      expect(uiState2!.skillCooldowns[SkillSlot.r], lessThan(8.0));

      viewModel.updateAllCooldowns(1.0);

      uiState1 = viewModel.getPlayerUIState('player1');
      uiState2 = viewModel.getPlayerUIState('player2');

      expect(uiState1!.skillCooldowns[SkillSlot.q], equals(3.0));
      expect(uiState2!.skillCooldowns[SkillSlot.r], lessThan(7.0));
    });

    test('multiple players maintain independent states', () {
      viewModel.initializePlayer(playerId: 'player1', mechaId: 'leon');
      viewModel.initializePlayer(playerId: 'player2', mechaId: 'wolf');

      viewModel.levelUpPlayer('player1');
      viewModel.levelUpPlayer('player1');

      final uiState1 = viewModel.getPlayerUIState('player1');
      final uiState2 = viewModel.getPlayerUIState('player2');

      expect(uiState1!.currentLevel, equals(3));
      expect(uiState2!.currentLevel, equals(1));
    });

    test('full Lv1-Lv8 progression with evolution choices', () {
      viewModel.initializePlayer(playerId: 'player1', mechaId: 'leon');

      for (int lv = 1; lv <= 8; lv++) {
        if (lv > 1) {
          viewModel.levelUpPlayer('player1');
        }

        var uiState = viewModel.getPlayerUIState('player1');
        expect(uiState!.currentLevel, equals(lv));

        if (lv == 3) {
          viewModel.confirmEvolution('player1', EvolutionType.offensive);
          uiState = viewModel.getPlayerUIState('player1');
          expect(uiState!.currentEvolution, equals(EvolutionType.offensive));
        } else if (lv == 6) {
          viewModel.switchEvolution('player1', EvolutionType.support);
          uiState = viewModel.getPlayerUIState('player1');
          expect(uiState!.currentEvolution, equals(EvolutionType.support));
        }

        // Check ULT states
        if (lv < 5) {
          expect(uiState!.isUltUnlocked, isFalse);
          expect(uiState.isUltCharging, isFalse);
        } else if (lv < 7) {
          expect(uiState!.isUltCharging, isTrue);
        } else {
          expect(uiState!.isUltUnlocked, isTrue);
        }
      }
    });

    test('reset clears all state', () {
      viewModel.initializePlayer(playerId: 'player1', mechaId: 'leon');
      viewModel.initializePlayer(playerId: 'player2', mechaId: 'wolf');

      expect(viewModel.state.length, equals(2));

      viewModel.reset();

      expect(viewModel.state, isEmpty);
    });

    test('getPlayerUIState returns null for unknown player', () {
      final uiState = viewModel.getPlayerUIState('unknown');
      expect(uiState, isNull);
    });

    test('evolution bonuses are calculated correctly', () {
      viewModel.initializePlayer(playerId: 'player1', mechaId: 'leon');

      var uiState = viewModel.getPlayerUIState('player1');
      expect(uiState!.evolutionBonuses['damage_bonus'], equals(0.0));

      viewModel.levelUpPlayer('player1');
      viewModel.levelUpPlayer('player1');
      viewModel.confirmEvolution('player1', EvolutionType.offensive);

      uiState = viewModel.getPlayerUIState('player1');
      expect(uiState!.evolutionBonuses['damage_bonus'], greaterThan(0.0));
    });

    test('all 6 characters initialize properly', () {
      final characterIds = ['leon', 'wolf', 'dragoon', 'frost', 'phoenix', 'crystal'];

      for (final charId in characterIds) {
        viewModel.initializePlayer(playerId: charId, mechaId: charId);
        final uiState = viewModel.getPlayerUIState(charId);
        expect(uiState, isNotNull, reason: '$charId should initialize');
        expect(uiState!.currentLevel, equals(1));
      }
    });
  });
}
