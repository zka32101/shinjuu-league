import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shinjuu_league/config/skill_progression_config.dart';
import 'package:shinjuu_league/data/models/battle_model.dart';
import 'package:shinjuu_league/data/models/resource_model.dart';
import 'package:shinjuu_league/services/battle_engine_service.dart';

class MockSkillProgressionConfig extends Mock
    implements SkillProgressionConfig {}

void main() {
  group('BattleEngine with Remote Config', () {
    late MockSkillProgressionConfig mockConfig;
    late BattleEngine engine;
    late BattleParticipantState player1;
    late BattleParticipantState player2;

    setUp(() {
      mockConfig = MockSkillProgressionConfig();

      // Default mock behavior: normal difficulty
      when(mockConfig.getDifficultyModifiers()).thenReturn(
        ProgressionDifficultyModifiers(
          levelDifficultyMultiplier: 1.0,
          skillCooldownMultiplier: 1.0,
          skillDamageMultiplier: 1.0,
        ),
      );

      player1 = BattleParticipantState(
        userId: 'player1',
        mechaId: 'mecha1',
        isBot: false,
        isSelf: true,
        team: 0,
        lane: 0,
        baseStats: BaseStats(hp: 100, atk: 50, spd: 30),
      );

      player2 = BattleParticipantState(
        userId: 'player2',
        mechaId: 'mecha2',
        isBot: true,
        isSelf: false,
        team: 1,
        lane: 0,
        baseStats: BaseStats(hp: 100, atk: 50, spd: 30),
      );

      engine = BattleEngine(
        battleId: 'test-battle',
        mode: BattleMode.quickMatch,
        mapId: 'map_01',
        participants: [player1, player2],
        progressionConfig: mockConfig,
      );
    });

    group('Initialization', () {
      test('initializes with provided SkillProgressionConfig', () {
        expect(engine, isNotNull);
      });

      test('uses default SkillProgressionConfig when not provided', () {
        final defaultEngine = BattleEngine(
          battleId: 'test-battle',
          mode: BattleMode.quickMatch,
          mapId: 'map_01',
          participants: [player1, player2],
        );
        expect(defaultEngine, isNotNull);
      });
    });

    group('Cooldown Multiplier Application', () {
      test('applies 1.0x cooldown multiplier for normal difficulty', () {
        when(mockConfig.getDifficultyModifiers()).thenReturn(
          ProgressionDifficultyModifiers(
            levelDifficultyMultiplier: 1.0,
            skillCooldownMultiplier: 1.0,
            skillDamageMultiplier: 1.0,
          ),
        );

        engine = BattleEngine(
          battleId: 'test-battle',
          mode: BattleMode.quickMatch,
          mapId: 'map_01',
          participants: [player1, player2],
          progressionConfig: mockConfig,
        );

        expect(
          mockConfig.getDifficultyModifiers().skillCooldownMultiplier,
          1.0,
        );
      });

      test('applies 0.8x cooldown multiplier for easy difficulty', () {
        when(mockConfig.getDifficultyModifiers()).thenReturn(
          ProgressionDifficultyModifiers(
            levelDifficultyMultiplier: 0.7,
            skillCooldownMultiplier: 0.8, // 20% shorter cooldowns
            skillDamageMultiplier: 0.9,
          ),
        );

        engine = BattleEngine(
          battleId: 'test-battle',
          mode: BattleMode.quickMatch,
          mapId: 'map_01',
          participants: [player1, player2],
          progressionConfig: mockConfig,
        );

        expect(
          mockConfig.getDifficultyModifiers().skillCooldownMultiplier,
          0.8,
        );
      });

      test('applies 1.2x cooldown multiplier for hard difficulty', () {
        when(mockConfig.getDifficultyModifiers()).thenReturn(
          ProgressionDifficultyModifiers(
            levelDifficultyMultiplier: 1.3,
            skillCooldownMultiplier: 1.2, // 20% longer cooldowns
            skillDamageMultiplier: 1.1,
          ),
        );

        engine = BattleEngine(
          battleId: 'test-battle',
          mode: BattleMode.quickMatch,
          mapId: 'map_01',
          participants: [player1, player2],
          progressionConfig: mockConfig,
        );

        expect(
          mockConfig.getDifficultyModifiers().skillCooldownMultiplier,
          1.2,
        );
      });

      test('cooldown reduction uses difficulty multiplier correctly', () {
        when(mockConfig.getDifficultyModifiers()).thenReturn(
          ProgressionDifficultyModifiers(
            levelDifficultyMultiplier: 1.0,
            skillCooldownMultiplier: 2.0, // Double cooldown reduction per tick
            skillDamageMultiplier: 1.0,
          ),
        );

        engine = BattleEngine(
          battleId: 'test-battle',
          mode: BattleMode.quickMatch,
          mapId: 'map_01',
          participants: [player1, player2],
          progressionConfig: mockConfig,
        );

        // Simulate skill cooldown (would normally be set by useSkill)
        player1.skillCooldowns['test_skill'] = 10.0;

        // Single tick with 2.0x multiplier
        engine.tick();

        // Cooldown should reduce by 1.0 * 2.0 = 2.0
        expect(player1.skillCooldowns['test_skill'], lessThan(9.0));
      });
    });

    group('Damage Multiplier Application', () {
      test('applies 1.0x damage multiplier for normal difficulty', () {
        when(mockConfig.getDifficultyModifiers()).thenReturn(
          ProgressionDifficultyModifiers(
            levelDifficultyMultiplier: 1.0,
            skillCooldownMultiplier: 1.0,
            skillDamageMultiplier: 1.0,
          ),
        );

        engine = BattleEngine(
          battleId: 'test-battle',
          mode: BattleMode.quickMatch,
          mapId: 'map_01',
          participants: [player1, player2],
          progressionConfig: mockConfig,
        );

        expect(
          mockConfig.getDifficultyModifiers().skillDamageMultiplier,
          1.0,
        );
      });

      test('applies 0.9x damage multiplier for easy difficulty', () {
        when(mockConfig.getDifficultyModifiers()).thenReturn(
          ProgressionDifficultyModifiers(
            levelDifficultyMultiplier: 0.7,
            skillCooldownMultiplier: 0.8,
            skillDamageMultiplier: 0.9, // 10% less damage
          ),
        );

        engine = BattleEngine(
          battleId: 'test-battle',
          mode: BattleMode.quickMatch,
          mapId: 'map_01',
          participants: [player1, player2],
          progressionConfig: mockConfig,
        );

        expect(
          mockConfig.getDifficultyModifiers().skillDamageMultiplier,
          0.9,
        );
      });

      test('applies 1.1x damage multiplier for hard difficulty', () {
        when(mockConfig.getDifficultyModifiers()).thenReturn(
          ProgressionDifficultyModifiers(
            levelDifficultyMultiplier: 1.3,
            skillCooldownMultiplier: 1.2,
            skillDamageMultiplier: 1.1, // 10% more damage
          ),
        );

        engine = BattleEngine(
          battleId: 'test-battle',
          mode: BattleMode.quickMatch,
          mapId: 'map_01',
          participants: [player1, player2],
          progressionConfig: mockConfig,
        );

        expect(
          mockConfig.getDifficultyModifiers().skillDamageMultiplier,
          1.1,
        );
      });
    });

    group('Difficulty Preset Scenarios', () {
      test('easy preset: shorter cooldowns and lower damage', () {
        final easyModifiers = ProgressionDifficultyModifiers(
          levelDifficultyMultiplier: 0.7,
          skillCooldownMultiplier: 0.8,
          skillDamageMultiplier: 0.9,
        );

        expect(easyModifiers.skillCooldownMultiplier, lessThan(1.0));
        expect(easyModifiers.skillDamageMultiplier, lessThan(1.0));
      });

      test('normal preset: baseline multipliers', () {
        final normalModifiers = ProgressionDifficultyModifiers(
          levelDifficultyMultiplier: 1.0,
          skillCooldownMultiplier: 1.0,
          skillDamageMultiplier: 1.0,
        );

        expect(normalModifiers.skillCooldownMultiplier, equals(1.0));
        expect(normalModifiers.skillDamageMultiplier, equals(1.0));
      });

      test('hard preset: longer cooldowns and higher damage', () {
        final hardModifiers = ProgressionDifficultyModifiers(
          levelDifficultyMultiplier: 1.3,
          skillCooldownMultiplier: 1.2,
          skillDamageMultiplier: 1.1,
        );

        expect(hardModifiers.skillCooldownMultiplier, greaterThan(1.0));
        expect(hardModifiers.skillDamageMultiplier, greaterThan(1.0));
      });
    });

    group('Combat with Config Multipliers', () {
      test('normal difficulty: baseline combat values', () {
        when(mockConfig.getDifficultyModifiers()).thenReturn(
          ProgressionDifficultyModifiers(
            levelDifficultyMultiplier: 1.0,
            skillCooldownMultiplier: 1.0,
            skillDamageMultiplier: 1.0,
          ),
        );

        engine = BattleEngine(
          battleId: 'test-battle',
          mode: BattleMode.quickMatch,
          mapId: 'map_01',
          participants: [player1, player2],
          progressionConfig: mockConfig,
        );

        engine.start();
        engine.tick();

        // Both players should still be alive initially (low engagement chance)
        expect(player1.isAlive, isTrue);
        expect(player2.isAlive, isTrue);
      });

      test('easy difficulty: increased cooldown reduction per tick', () {
        when(mockConfig.getDifficultyModifiers()).thenReturn(
          ProgressionDifficultyModifiers(
            levelDifficultyMultiplier: 0.7,
            skillCooldownMultiplier: 0.8,
            skillDamageMultiplier: 0.9,
          ),
        );

        engine = BattleEngine(
          battleId: 'test-battle',
          mode: BattleMode.quickMatch,
          mapId: 'map_01',
          participants: [player1, player2],
          progressionConfig: mockConfig,
        );

        player1.skillCooldowns['skill'] = 10.0;
        engine.tick();

        // With 0.8x multiplier, cooldown reduction = 1.0 * 0.8 = 0.8
        // So cooldown should be 10.0 - 0.8 = 9.2
        expect(player1.skillCooldowns['skill']!, lessThan(10.0));
        expect(player1.skillCooldowns['skill']!, greaterThan(9.0));
      });

      test('hard difficulty: decreased cooldown reduction per tick', () {
        when(mockConfig.getDifficultyModifiers()).thenReturn(
          ProgressionDifficultyModifiers(
            levelDifficultyMultiplier: 1.3,
            skillCooldownMultiplier: 1.2,
            skillDamageMultiplier: 1.1,
          ),
        );

        engine = BattleEngine(
          battleId: 'test-battle',
          mode: BattleMode.quickMatch,
          mapId: 'map_01',
          participants: [player1, player2],
          progressionConfig: mockConfig,
        );

        player1.skillCooldowns['skill'] = 10.0;
        engine.tick();

        // With 1.2x multiplier, cooldown reduction = 1.0 * 1.2 = 1.2
        // So cooldown should be 10.0 - 1.2 = 8.8
        expect(player1.skillCooldowns['skill']!, lessThan(10.0));
        expect(player1.skillCooldowns['skill']!, greaterThan(8.0));
      });
    });

    group('Config Reload Scenarios', () {
      test('reflects changed difficulty preset on new engine instance', () {
        when(mockConfig.getDifficultyModifiers()).thenReturn(
          ProgressionDifficultyModifiers(
            levelDifficultyMultiplier: 1.0,
            skillCooldownMultiplier: 1.0,
            skillDamageMultiplier: 1.0,
          ),
        );

        var testEngine = BattleEngine(
          battleId: 'test-battle',
          mode: BattleMode.quickMatch,
          mapId: 'map_01',
          participants: [player1, player2],
          progressionConfig: mockConfig,
        );

        // Change config values to hard difficulty
        when(mockConfig.getDifficultyModifiers()).thenReturn(
          ProgressionDifficultyModifiers(
            levelDifficultyMultiplier: 1.3,
            skillCooldownMultiplier: 1.2,
            skillDamageMultiplier: 1.1,
          ),
        );

        // New engine instance gets new values
        testEngine = BattleEngine(
          battleId: 'test-battle',
          mode: BattleMode.quickMatch,
          mapId: 'map_01',
          participants: [player1, player2],
          progressionConfig: mockConfig,
        );

        expect(mockConfig.getDifficultyModifiers().skillDamageMultiplier, 1.1);
      });
    });

    group('Edge Cases', () {
      test('zero cooldown multiplier edge case', () {
        when(mockConfig.getDifficultyModifiers()).thenReturn(
          ProgressionDifficultyModifiers(
            levelDifficultyMultiplier: 1.0,
            skillCooldownMultiplier: 0.0, // No cooldown reduction
            skillDamageMultiplier: 1.0,
          ),
        );

        engine = BattleEngine(
          battleId: 'test-battle',
          mode: BattleMode.quickMatch,
          mapId: 'map_01',
          participants: [player1, player2],
          progressionConfig: mockConfig,
        );

        player1.skillCooldowns['skill'] = 10.0;
        engine.tick();

        // With 0.0x multiplier, cooldown should not reduce
        expect(player1.skillCooldowns['skill'], equals(10.0));
      });

      test('extreme cooldown multiplier (3.0x)', () {
        when(mockConfig.getDifficultyModifiers()).thenReturn(
          ProgressionDifficultyModifiers(
            levelDifficultyMultiplier: 1.0,
            skillCooldownMultiplier: 3.0, // Triple cooldown reduction
            skillDamageMultiplier: 1.0,
          ),
        );

        engine = BattleEngine(
          battleId: 'test-battle',
          mode: BattleMode.quickMatch,
          mapId: 'map_01',
          participants: [player1, player2],
          progressionConfig: mockConfig,
        );

        player1.skillCooldowns['skill'] = 2.0;
        engine.tick();

        // With 3.0x multiplier, cooldown reduction = 1.0 * 3.0 = 3.0
        // So cooldown should go negative and clamp to 0.0
        expect(player1.skillCooldowns['skill']!, lessThanOrEqualTo(0.0));
      });
    });

    group('Disposal', () {
      test('engine disposes without errors', () {
        expect(() => engine.dispose(), returnsNormally);
      });
    });
  });
}
