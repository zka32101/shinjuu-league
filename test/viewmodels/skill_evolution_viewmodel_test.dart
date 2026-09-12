import 'package:flutter_test/flutter_test.dart';
import 'package:shinjuu_league/data/models/skill_catalog.dart';
import 'package:shinjuu_league/data/models/evolution_state.dart';
import 'package:shinjuu_league/viewmodels/skill_evolution_viewmodel.dart';

void main() {
  group('EvolutionSelectionViewModel', () {
    late EvolutionSelectionViewModel viewModel;

    setUp(() {
      viewModel = EvolutionSelectionViewModel(targetLevel: 3);
    });

    tearDown(() {
      viewModel.dispose();
    });

    test('initial state has selection hidden', () {
      expect(viewModel.state.isVisible, isFalse);
      expect(viewModel.state.targetLevel, equals(3));
      expect(viewModel.state.selectedChoice, isNull);
    });

    test('showSelection makes selection visible and starts countdown', () {
      viewModel.showSelection();
      expect(viewModel.state.isVisible, isTrue);
      expect(viewModel.state.remainingSeconds, lessThanOrEqualTo(10));
    });

    test('selectEvolution updates selected choice', () {
      viewModel.showSelection();
      viewModel.selectEvolution(EvolutionType.offensive);
      expect(viewModel.state.selectedChoice, equals(EvolutionType.offensive));
    });

    test('getDescription returns non-empty string for Lv3', () {
      final desc = viewModel.getDescription(EvolutionType.offensive);
      expect(desc, isNotEmpty);
      expect(desc, contains('ダメージ'));
    });

    test('isSelected returns true for selected choice', () {
      viewModel.selectEvolution(EvolutionType.defensive);
      expect(viewModel.isSelected(EvolutionType.defensive), isTrue);
      expect(viewModel.isSelected(EvolutionType.offensive), isFalse);
    });

    test('reset clears selected choice', () {
      viewModel.showSelection();
      viewModel.selectEvolution(EvolutionType.offensive);
      expect(viewModel.state.selectedChoice, isNotNull);

      viewModel.reset();
      expect(viewModel.state.selectedChoice, isNull);
      expect(viewModel.state.isVisible, isFalse);
    });

    test('countdown affects remaining seconds', () {
      viewModel.showSelection();
      final initialRemaining = viewModel.state.remainingSeconds;
      expect(initialRemaining, lessThanOrEqualTo(10));
    });
  });

  group('PlayerEvolutionViewModel', () {
    late PlayerEvolutionViewModel viewModel;

    setUp(() {
      viewModel = PlayerEvolutionViewModel(
        mechaId: 'leon',
        currentLevel: 1,
      );
    });

    test('initial state has no evolution', () {
      expect(viewModel.state.currentEvolution, isNull);
      expect(viewModel.state.evolutionCount, equals(0));
      expect(viewModel.state.currentLevel, equals(1));
    });

    test('confirmLv3Evolution records evolution', () {
      viewModel.confirmLv3Evolution(EvolutionType.offensive);
      expect(viewModel.state.currentEvolution, equals(EvolutionType.offensive));
      expect(viewModel.state.evolutionCount, equals(1));
      expect(viewModel.state.lastEvolutionLevel, equals(3));
    });

    test('confirmLv6Evolution updates evolution', () {
      viewModel.confirmLv3Evolution(EvolutionType.offensive);
      viewModel.confirmLv6Evolution(EvolutionType.defensive);

      expect(viewModel.state.currentEvolution, equals(EvolutionType.defensive));
      expect(viewModel.state.evolutionCount, equals(2));
      expect(viewModel.state.lastEvolutionLevel, equals(6));
    });

    test('getCurrentEvolutionBonuses returns valid bonuses when evolved', () {
      viewModel.confirmLv3Evolution(EvolutionType.offensive);
      final bonuses = viewModel.getCurrentEvolutionBonuses();

      expect(bonuses['damage_bonus'], greaterThan(0.0));
      expect(bonuses['hp_bonus'], equals(0.0));
    });

    test('getCurrentEvolutionBonuses returns zeros when not evolved', () {
      final bonuses = viewModel.getCurrentEvolutionBonuses();

      expect(bonuses['damage_bonus'], equals(0.0));
      expect(bonuses['hp_bonus'], equals(0.0));
      expect(bonuses['ally_effect_bonus'], equals(0.0));
    });

    test('getNextEvolutionLevel returns 3 initially', () {
      final nextLv = viewModel.getNextEvolutionLevel();
      expect(nextLv, equals(3));
    });

    test('getEvolutionBonusText returns non-empty when evolved', () {
      viewModel.confirmLv3Evolution(EvolutionType.offensive);
      final text = viewModel.getEvolutionBonusText();
      expect(text, isNotEmpty);
      expect(text, contains('ダメージ'));
    });

    test('getEvolutionBonusText returns placeholder when not evolved', () {
      final text = viewModel.getEvolutionBonusText();
      expect(text, equals('進化未選択'));
    });

    test('getLv3Description returns description text', () {
      final desc = viewModel.getLv3Description();
      expect(desc, isNotEmpty);
    });

    test('evolution history tracks multiple selections', () {
      viewModel.confirmLv3Evolution(EvolutionType.offensive);
      viewModel.confirmLv6Evolution(EvolutionType.support);

      expect(viewModel.state.evolutionHistory.length, equals(2));
      expect(viewModel.state.evolutionHistory[0].level, equals(3));
      expect(viewModel.state.evolutionHistory[1].level, equals(6));
    });

    test('lastEvolution returns most recent evolution', () {
      viewModel.confirmLv3Evolution(EvolutionType.offensive);
      expect(viewModel.state.lastEvolution!.choice, equals(EvolutionType.offensive));
      expect(viewModel.state.lastEvolution!.level, equals(3));

      viewModel.confirmLv6Evolution(EvolutionType.defensive);
      expect(viewModel.state.lastEvolution!.choice, equals(EvolutionType.defensive));
      expect(viewModel.state.lastEvolution!.level, equals(6));
    });

    test('evolution bonus text for defensive type', () {
      viewModel.confirmLv3Evolution(EvolutionType.defensive);
      final text = viewModel.getEvolutionBonusText();
      expect(text, contains('HP'));
    });

    test('evolution bonus text for support type', () {
      viewModel.confirmLv3Evolution(EvolutionType.support);
      final text = viewModel.getEvolutionBonusText();
      expect(text, contains('味方効果'));
    });

    test('switching evolution at Lv6', () {
      viewModel.confirmLv3Evolution(EvolutionType.offensive);
      expect(viewModel.state.currentEvolution, equals(EvolutionType.offensive));

      viewModel.confirmLv6Evolution(EvolutionType.support);
      expect(viewModel.state.currentEvolution, equals(EvolutionType.support));
    });
  });

  group('Evolution State Transitions', () {
    test('PlayerEvolutionState.selectEvolutionAtLv3 transitions correctly', () {
      var state = PlayerEvolutionState.initial(
        mechaId: 'leon',
        currentLevel: 3,
      );

      state = state.selectEvolutionAtLv3(EvolutionType.offensive);
      expect(state.currentEvolution, equals(EvolutionType.offensive));
      expect(state.lastEvolutionLevel, equals(3));
    });

    test('PlayerEvolutionState.updateEvolutionAtLv6 allows switch', () {
      var state = PlayerEvolutionState.initial(
        mechaId: 'leon',
        currentLevel: 6,
      );
      state = state.selectEvolutionAtLv3(EvolutionType.offensive);
      state = state.updateEvolutionAtLv6(EvolutionType.defensive);

      expect(state.currentEvolution, equals(EvolutionType.defensive));
      expect(state.evolutionHistory.length, equals(2));
    });

    test('EvolutionSelectionState countdown updates correctly', () {
      var state = EvolutionSelectionState.initial(targetLevel: 3);
      state = state.showSelection();
      state = state.updateCountdown(5);

      expect(state.remainingSeconds, equals(5));
    });

    test('EvolutionSelectionState reset works', () {
      var state = EvolutionSelectionState.initial(targetLevel: 3);
      state = state.showSelection();
      state = state.selectChoice(EvolutionType.offensive);

      state = state.reset();
      expect(state.isVisible, isFalse);
      expect(state.selectedChoice, isNull);
      expect(state.remainingSeconds, equals(10));
    });
  });

  group('Evolution Type Coverage', () {
    late PlayerEvolutionViewModel viewModel;

    setUp(() {
      viewModel = PlayerEvolutionViewModel(
        mechaId: 'wolf',
        currentLevel: 3,
      );
    });

    test('all three evolution types work', () {
      final types = [
        EvolutionType.offensive,
        EvolutionType.defensive,
        EvolutionType.support,
      ];

      for (final type in types) {
        final vm = PlayerEvolutionViewModel(
          mechaId: 'leon',
          currentLevel: 3,
        );
        vm.confirmLv3Evolution(type);
        expect(vm.state.currentEvolution, equals(type));
      }
    });
  });
}
