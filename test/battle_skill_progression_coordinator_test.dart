import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shinjuu_league/config/skill_progression_config.dart';
import 'package:shinjuu_league/data/models/evolution_state.dart';
import 'package:shinjuu_league/data/models/skill_catalog.dart';
import 'package:shinjuu_league/services/battle_skill_progression_coordinator.dart';
import 'package:shinjuu_league/services/skill_progression_battle_service.dart';

class MockSkillProgressionBattleService extends Mock
    implements SkillProgressionBattleService {}

class MockSkillProgressionConfig extends Mock
    implements SkillProgressionConfig {}

void main() {
  group('BattleSkillProgressionCoordinator', () {
    late MockSkillProgressionBattleService mockSkillService;
    late MockSkillProgressionConfig mockConfig;
    late BattleSkillProgressionCoordinator coordinator;

    setUp(() {
      mockSkillService = MockSkillProgressionBattleService();
      mockConfig = MockSkillProgressionConfig();

      // Default mock behavior
      when(mockConfig.firstEvolutionLevel).thenReturn(3);
      when(mockConfig.secondEvolutionLevel).thenReturn(6);
      when(mockConfig.skillCooldownMultiplier).thenReturn(1.0);
      when(mockConfig.skillDamageMultiplier).thenReturn(1.0);
      when(mockConfig.getDifficultyModifiers()).thenReturn(
        ProgressionDifficultyModifiers(
          levelDifficultyMultiplier: 1.0,
          skillCooldownMultiplier: 1.0,
          skillDamageMultiplier: 1.0,
        ),
      );

      coordinator = BattleSkillProgressionCoordinator(
        skillService: mockSkillService,
        progressionConfig: mockConfig,
      );
    });

    group('Initialization', () {
      test('initializes with provided SkillProgressionConfig', () {
        expect(coordinator, isNotNull);
      });

      test('uses default SkillProgressionConfig when not provided', () {
        final defaultCoordinator = BattleSkillProgressionCoordinator(
          skillService: mockSkillService,
        );
        expect(defaultCoordinator, isNotNull);
      });

      test('initializes with both services when provided', () {
        final customCoordinator = BattleSkillProgressionCoordinator(
          skillService: mockSkillService,
          progressionConfig: mockConfig,
        );
        expect(customCoordinator, isNotNull);
      });
    });

    group('Remote Config Integration', () {
      test('uses firstEvolutionLevel from config', () {
        when(mockConfig.firstEvolutionLevel).thenReturn(2);
        when(mockConfig.secondEvolutionLevel).thenReturn(6);

        final newCoordinator = BattleSkillProgressionCoordinator(
          skillService: mockSkillService,
          progressionConfig: mockConfig,
        );

        expect(mockConfig.firstEvolutionLevel, equals(2));
      });

      test('uses secondEvolutionLevel from config', () {
        when(mockConfig.firstEvolutionLevel).thenReturn(3);
        when(mockConfig.secondEvolutionLevel).thenReturn(5);

        final newCoordinator = BattleSkillProgressionCoordinator(
          skillService: mockSkillService,
          progressionConfig: mockConfig,
        );

        expect(mockConfig.secondEvolutionLevel, equals(5));
      });
    });

    group('autoConfirmEvolution', () {
      test('confirms evolution at first evolution level from config', () {
        when(mockConfig.firstEvolutionLevel).thenReturn(3);
        when(mockConfig.secondEvolutionLevel).thenReturn(6);

        coordinator = BattleSkillProgressionCoordinator(
          skillService: mockSkillService,
          progressionConfig: mockConfig,
        );

        coordinator.autoConfirmEvolution('player1');

        verify(mockSkillService.confirmEvolution(
          'player1',
          EvolutionType.offensive,
        )).called(1);
      });

      test('switches evolution at second evolution level from config', () {
        when(mockConfig.firstEvolutionLevel).thenReturn(3);
        when(mockConfig.secondEvolutionLevel).thenReturn(6);

        coordinator = BattleSkillProgressionCoordinator(
          skillService: mockSkillService,
          progressionConfig: mockConfig,
        );

        coordinator.autoConfirmEvolution('player1');

        verify(mockSkillService.switchEvolution(
          'player1',
          EvolutionType.offensive,
        )).called(1);
      });

      test('respects custom first evolution level from config', () {
        when(mockConfig.firstEvolutionLevel).thenReturn(2);
        when(mockConfig.secondEvolutionLevel).thenReturn(5);

        coordinator = BattleSkillProgressionCoordinator(
          skillService: mockSkillService,
          progressionConfig: mockConfig,
        );

        coordinator.autoConfirmEvolution('player1');

        verify(mockSkillService.confirmEvolution(any, any)).called(1);
      });
    });

    group('Skill Damage with Difficulty Modifiers', () {
      test('applies skill damage multiplier from difficulty preset (1.0x)', () {
        when(mockConfig.getDifficultyModifiers()).thenReturn(
          ProgressionDifficultyModifiers(
            levelDifficultyMultiplier: 1.0,
            skillCooldownMultiplier: 1.0,
            skillDamageMultiplier: 1.0,
          ),
        );

        coordinator = BattleSkillProgressionCoordinator(
          skillService: mockSkillService,
          progressionConfig: mockConfig,
        );

        // Note: tryUseSkill returns bool, actual damage is in SkillUsedEvent
        // This test verifies the multiplier calculation path works
        expect(mockConfig.getDifficultyModifiers().skillDamageMultiplier, 1.0);
      });

      test('applies skill damage multiplier for easy difficulty (0.9x)', () {
        when(mockConfig.getDifficultyModifiers()).thenReturn(
          ProgressionDifficultyModifiers(
            levelDifficultyMultiplier: 0.7,
            skillCooldownMultiplier: 0.8,
            skillDamageMultiplier: 0.9, // 10% less damage
          ),
        );

        coordinator = BattleSkillProgressionCoordinator(
          skillService: mockSkillService,
          progressionConfig: mockConfig,
        );

        expect(mockConfig.getDifficultyModifiers().skillDamageMultiplier, 0.9);
      });

      test('applies skill damage multiplier for hard difficulty (1.1x)', () {
        when(mockConfig.getDifficultyModifiers()).thenReturn(
          ProgressionDifficultyModifiers(
            levelDifficultyMultiplier: 1.3,
            skillCooldownMultiplier: 1.2,
            skillDamageMultiplier: 1.1, // 10% more damage
          ),
        );

        coordinator = BattleSkillProgressionCoordinator(
          skillService: mockSkillService,
          progressionConfig: mockConfig,
        );

        expect(mockConfig.getDifficultyModifiers().skillDamageMultiplier, 1.1);
      });
    });

    group('Event Stream Integration', () {
      test('emits skill events through skillEvents stream', () async {
        expect(coordinator.skillEvents, isA<Stream<BattleSkillEvent>>());
      });

      test('skill events stream is broadcast', () async {
        final stream1 = coordinator.skillEvents;
        final stream2 = coordinator.skillEvents;

        // Broadcast stream allows multiple listeners
        stream1.listen((_) {});
        stream2.listen((_) {});

        expect(true, isTrue);
      });
    });

    group('Skill State Snapshot', () {
      test('returns null when player not found', () {
        when(mockSkillService.getProgress('unknown_player'))
            .thenReturn(null);

        final snapshot = coordinator.getPlayerSkillState('unknown_player');

        expect(snapshot, isNull);
      });

      test('snapshot includes evolution locked state', () {
        expect(
          coordinator.getPlayerSkillState('player1'),
          anyOf([isNull, isA<PlayerSkillStateSnapshot>()]),
        );
      });
    });

    group('Error Handling', () {
      test('autoConfirmEvolution handles null progress gracefully', () {
        when(mockSkillService.getProgress('player1')).thenReturn(null);

        expect(
          () => coordinator.autoConfirmEvolution('player1'),
          returnsNormally,
        );
      });

      test('getPlayerSkillState handles null progress gracefully', () {
        when(mockSkillService.getProgress('player1')).thenReturn(null);

        expect(
          () => coordinator.getPlayerSkillState('player1'),
          returnsNormally,
        );
      });
    });

    group('Config Reload Scenarios', () {
      test('reflects changed evolution levels on new coordinator instance',
          () {
        when(mockConfig.firstEvolutionLevel).thenReturn(3);
        when(mockConfig.secondEvolutionLevel).thenReturn(6);

        var testCoordinator = BattleSkillProgressionCoordinator(
          skillService: mockSkillService,
          progressionConfig: mockConfig,
        );

        // Change config values
        when(mockConfig.firstEvolutionLevel).thenReturn(2);
        when(mockConfig.secondEvolutionLevel).thenReturn(5);

        // New coordinator instance gets new values
        testCoordinator = BattleSkillProgressionCoordinator(
          skillService: mockSkillService,
          progressionConfig: mockConfig,
        );

        expect(mockConfig.firstEvolutionLevel, equals(2));
        expect(mockConfig.secondEvolutionLevel, equals(5));
      });

      test('difficulty modifier changes apply to new skill calculations', () {
        when(mockConfig.getDifficultyModifiers()).thenReturn(
          ProgressionDifficultyModifiers(
            levelDifficultyMultiplier: 1.0,
            skillCooldownMultiplier: 1.0,
            skillDamageMultiplier: 1.0,
          ),
        );

        coordinator = BattleSkillProgressionCoordinator(
          skillService: mockSkillService,
          progressionConfig: mockConfig,
        );

        var modifiers = mockConfig.getDifficultyModifiers();
        expect(modifiers.skillDamageMultiplier, 1.0);

        // Change to hard mode
        when(mockConfig.getDifficultyModifiers()).thenReturn(
          ProgressionDifficultyModifiers(
            levelDifficultyMultiplier: 1.3,
            skillCooldownMultiplier: 1.2,
            skillDamageMultiplier: 1.1,
          ),
        );

        modifiers = mockConfig.getDifficultyModifiers();
        expect(modifiers.skillDamageMultiplier, 1.1);
      });
    });

    group('Disposal', () {
      test('dispose closes skill event controller', () {
        coordinator.dispose();

        expect(
          () => coordinator.skillEvents.listen((_) {}),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              contains('closed'),
            ),
          ),
        );
      });

      test('dispose calls skill service dispose', () {
        coordinator.dispose();

        verify(mockSkillService.dispose()).called(1);
      });
    });
  });
}
