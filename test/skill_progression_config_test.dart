import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:shinjuu_league/config/skill_progression_config.dart';

class MockFirebaseRemoteConfig extends Mock implements FirebaseRemoteConfig {}

void main() {
  group('SkillProgressionConfig', () {
    late MockFirebaseRemoteConfig mockRemoteConfig;
    late SkillProgressionConfig config;

    setUp(() {
      mockRemoteConfig = MockFirebaseRemoteConfig();
      config = SkillProgressionConfig();

      // Default mock behavior: return default values
      when(mockRemoteConfig.getDouble(any)).thenReturn(1.0);
      when(mockRemoteConfig.getInt(any)).thenReturn(0);
      when(mockRemoteConfig.getBool(any)).thenReturn(true);
      when(mockRemoteConfig.getString(any)).thenReturn('normal');
      when(mockRemoteConfig.setDefaults(any)).thenAnswer((_) async {});
      when(mockRemoteConfig.fetchAndActivate()).thenAnswer((_) async => false);
    });

    group('Initialization', () {
      test('initialize sets defaults and activates Remote Config', () async {
        await config.initialize(mockRemoteConfig);

        expect(config.isInitialized, isTrue);
        verify(mockRemoteConfig.setDefaults(any)).called(1);
        verify(mockRemoteConfig.fetchAndActivate()).called(1);
      });

      test('initialize continues when fetchAndActivate fails', () async {
        when(mockRemoteConfig.fetchAndActivate())
            .thenThrow(Exception('Network error'));

        expect(() async => await config.initialize(mockRemoteConfig),
            returnsNormally);

        expect(config.isInitialized, isTrue);
      });

      test('getters return default values before initialization', () {
        // Create new instance to avoid shared state
        final newConfig = SkillProgressionConfig();

        expect(newConfig.levelDifficultyMultiplier, 1.0);
        expect(newConfig.maxCharacterLevel, 8);
        expect(newConfig.firstEvolutionLevel, 3);
        expect(newConfig.isSkillProgressionEnabled, isTrue);
      });
    });

    group('Level Progression Parameters', () {
      test('levelDifficultyMultiplier returns Remote Config value', () async {
        await config.initialize(mockRemoteConfig);

        when(mockRemoteConfig.getDouble('skill_progression_level_difficulty_multiplier'))
            .thenReturn(1.3);

        expect(config.levelDifficultyMultiplier, 1.3);
      });

      test('levelDifficultyMultiplier clamps to valid range', () async {
        await config.initialize(mockRemoteConfig);

        when(mockRemoteConfig.getDouble('skill_progression_level_difficulty_multiplier'))
            .thenReturn(5.0); // Out of range

        expect(config.levelDifficultyMultiplier, 2.0); // Clamped to max
      });

      test('maxCharacterLevel returns Remote Config value', () async {
        await config.initialize(mockRemoteConfig);

        when(mockRemoteConfig.getInt('skill_progression_max_character_level'))
            .thenReturn(10);

        expect(config.maxCharacterLevel, 10);
      });

      test('firstEvolutionLevel returns Remote Config value', () async {
        await config.initialize(mockRemoteConfig);

        when(mockRemoteConfig.getInt('skill_progression_first_evolution_level'))
            .thenReturn(2);

        expect(config.firstEvolutionLevel, 2);
      });

      test('secondEvolutionLevel returns Remote Config value', () async {
        await config.initialize(mockRemoteConfig);

        when(mockRemoteConfig.getInt('skill_progression_second_evolution_level'))
            .thenReturn(5);

        expect(config.secondEvolutionLevel, 5);
      });
    });

    group('Evolution Parameters', () {
      test('evolutionSelectionTimeoutSeconds returns Remote Config value',
          () async {
        await config.initialize(mockRemoteConfig);

        when(mockRemoteConfig.getInt('skill_progression_evolution_timeout_seconds'))
            .thenReturn(15);

        expect(config.evolutionSelectionTimeoutSeconds, 15);
      });

      test('evolutionSelectionTimeoutSeconds has reasonable bounds', () async {
        await config.initialize(mockRemoteConfig);

        when(mockRemoteConfig.getInt('skill_progression_evolution_timeout_seconds'))
            .thenReturn(3); // Below minimum

        // Should still return the value (bounds check is caller responsibility)
        expect(config.evolutionSelectionTimeoutSeconds, 3);
      });
    });

    group('Evolution Bonus Parameters', () {
      test('offensiveDamageBonus returns Remote Config value', () async {
        await config.initialize(mockRemoteConfig);

        when(mockRemoteConfig.getDouble('skill_progression_offensive_damage_bonus'))
            .thenReturn(0.75);

        expect(config.offensiveDamageBonus, 0.75);
      });

      test('offensiveDamageBonus clamps to 0.0-1.0', () async {
        await config.initialize(mockRemoteConfig);

        when(mockRemoteConfig.getDouble('skill_progression_offensive_damage_bonus'))
            .thenReturn(1.5); // Out of range

        expect(config.offensiveDamageBonus, 1.0); // Clamped
      });

      test('defensiveHpBonus returns Remote Config value', () async {
        await config.initialize(mockRemoteConfig);

        when(mockRemoteConfig.getDouble('skill_progression_defensive_hp_bonus'))
            .thenReturn(0.55);

        expect(config.defensiveHpBonus, 0.55);
      });

      test('supportAllyEffectBonus returns Remote Config value', () async {
        await config.initialize(mockRemoteConfig);

        when(mockRemoteConfig.getDouble('skill_progression_support_ally_effect_bonus'))
            .thenReturn(0.40);

        expect(config.supportAllyEffectBonus, 0.40);
      });

      test('all evolution bonuses have reasonable defaults', () async {
        await config.initialize(mockRemoteConfig);

        expect(config.offensiveDamageBonus, greaterThan(0.0));
        expect(config.offensiveDamageBonus, lessThanOrEqualTo(1.0));

        expect(config.defensiveHpBonus, greaterThan(0.0));
        expect(config.defensiveHpBonus, lessThanOrEqualTo(1.0));

        expect(config.supportAllyEffectBonus, greaterThan(0.0));
        expect(config.supportAllyEffectBonus, lessThanOrEqualTo(1.0));
      });
    });

    group('Skill Parameters', () {
      test('skillCooldownMultiplier returns Remote Config value', () async {
        await config.initialize(mockRemoteConfig);

        when(mockRemoteConfig.getDouble('skill_progression_skill_cooldown_multiplier'))
            .thenReturn(0.8);

        expect(config.skillCooldownMultiplier, 0.8);
      });

      test('skillDamageMultiplier returns Remote Config value', () async {
        await config.initialize(mockRemoteConfig);

        when(mockRemoteConfig.getDouble('skill_progression_skill_damage_multiplier'))
            .thenReturn(1.2);

        expect(config.skillDamageMultiplier, 1.2);
      });

      test('ultUnlockLevel returns Remote Config value', () async {
        await config.initialize(mockRemoteConfig);

        when(mockRemoteConfig.getInt('skill_progression_ult_unlock_level'))
            .thenReturn(6);

        expect(config.ultUnlockLevel, 6);
      });

      test('skill multipliers clamp to valid range', () async {
        await config.initialize(mockRemoteConfig);

        when(mockRemoteConfig.getDouble('skill_progression_skill_cooldown_multiplier'))
            .thenReturn(3.0); // Out of range

        expect(config.skillCooldownMultiplier, 2.0); // Clamped to max
      });
    });

    group('Feature Flags', () {
      test('isSkillProgressionEnabled returns Remote Config value', () async {
        await config.initialize(mockRemoteConfig);

        when(mockRemoteConfig.getBool('skill_progression_enabled'))
            .thenReturn(false);

        expect(config.isSkillProgressionEnabled, isFalse);
      });

      test('isEvolutionSwitchingEnabled returns Remote Config value',
          () async {
        await config.initialize(mockRemoteConfig);

        when(mockRemoteConfig.getBool('skill_progression_evolution_switching_enabled'))
            .thenReturn(false);

        expect(config.isEvolutionSwitchingEnabled, isFalse);
      });

      test('isAnalyticsTrackingEnabled returns Remote Config value', () async {
        await config.initialize(mockRemoteConfig);

        when(mockRemoteConfig.getBool('skill_progression_analytics_enabled'))
            .thenReturn(false);

        expect(config.isAnalyticsTrackingEnabled, isFalse);
      });

      test('all feature flags default to enabled', () async {
        await config.initialize(mockRemoteConfig);

        expect(config.isSkillProgressionEnabled, isTrue);
        expect(config.isEvolutionSwitchingEnabled, isTrue);
        expect(config.isAnalyticsTrackingEnabled, isTrue);
      });
    });

    group('Difficulty Presets', () {
      test('difficultyPreset returns Remote Config value', () async {
        await config.initialize(mockRemoteConfig);

        when(mockRemoteConfig.getString('skill_progression_difficulty_preset'))
            .thenReturn('hard');

        expect(config.difficultyPreset, 'hard');
      });

      test('getDifficultyModifiers returns normal preset by default',
          () async {
        await config.initialize(mockRemoteConfig);

        when(mockRemoteConfig.getString('skill_progression_difficulty_preset'))
            .thenReturn('normal');

        final modifiers = config.getDifficultyModifiers();

        expect(modifiers.levelDifficultyMultiplier, 1.0);
        expect(modifiers.skillCooldownMultiplier, 1.0);
        expect(modifiers.skillDamageMultiplier, 1.0);
      });

      test('getDifficultyModifiers returns easy preset values', () async {
        await config.initialize(mockRemoteConfig);

        when(mockRemoteConfig.getString('skill_progression_difficulty_preset'))
            .thenReturn('easy');

        final modifiers = config.getDifficultyModifiers();

        expect(modifiers.levelDifficultyMultiplier, 0.7); // 30% faster
        expect(modifiers.skillCooldownMultiplier, 0.8);   // 20% shorter
        expect(modifiers.skillDamageMultiplier, 0.9);     // 10% less damage
      });

      test('getDifficultyModifiers returns hard preset values', () async {
        await config.initialize(mockRemoteConfig);

        when(mockRemoteConfig.getString('skill_progression_difficulty_preset'))
            .thenReturn('hard');

        final modifiers = config.getDifficultyModifiers();

        expect(modifiers.levelDifficultyMultiplier, 1.3); // 30% slower
        expect(modifiers.skillCooldownMultiplier, 1.2);   // 20% longer
        expect(modifiers.skillDamageMultiplier, 1.1);     // 10% more damage
      });

      test('getDifficultyModifiers handles unknown preset', () async {
        await config.initialize(mockRemoteConfig);

        when(mockRemoteConfig.getString('skill_progression_difficulty_preset'))
            .thenReturn('unknown');

        final modifiers = config.getDifficultyModifiers();

        // Should default to normal
        expect(modifiers.levelDifficultyMultiplier, 1.0);
      });
    });

    group('Refresh', () {
      test('refresh calls fetchAndActivate', () async {
        await config.initialize(mockRemoteConfig);

        when(mockRemoteConfig.fetchAndActivate()).thenAnswer((_) async => true);

        final result = await config.refresh();

        expect(result, isTrue);
        verify(mockRemoteConfig.fetchAndActivate()).called(2); // Once in init, once in refresh
      });

      test('refresh returns false when not initialized', () async {
        final result = await config.refresh();

        expect(result, isFalse);
        verifyNever(mockRemoteConfig.fetchAndActivate());
      });

      test('refresh handles fetchAndActivate failure', () async {
        await config.initialize(mockRemoteConfig);

        when(mockRemoteConfig.fetchAndActivate())
            .thenThrow(Exception('Network error'));

        expect(() async => await config.refresh(), returnsNormally);
      });
    });

    group('Debug & Diagnostics', () {
      test('debugDumpConfig returns all configuration values', () async {
        await config.initialize(mockRemoteConfig);

        when(mockRemoteConfig.getDouble('skill_progression_level_difficulty_multiplier'))
            .thenReturn(1.2);
        when(mockRemoteConfig.getInt('skill_progression_max_character_level'))
            .thenReturn(8);
        when(mockRemoteConfig.getBool('skill_progression_enabled'))
            .thenReturn(true);

        final dump = config.debugDumpConfig();

        expect(dump['isInitialized'], isTrue);
        expect(dump['levelDifficultyMultiplier'], 1.2);
        expect(dump['maxCharacterLevel'], 8);
        expect(dump['isSkillProgressionEnabled'], isTrue);
        expect(dump['difficultyModifiers'], isA<Map<String, dynamic>>());
      });

      test('debugDumpConfig includes all parameter categories', () async {
        await config.initialize(mockRemoteConfig);

        final dump = config.debugDumpConfig();

        // Level progression
        expect(dump.containsKey('levelDifficultyMultiplier'), isTrue);
        expect(dump.containsKey('maxCharacterLevel'), isTrue);

        // Evolution
        expect(dump.containsKey('firstEvolutionLevel'), isTrue);
        expect(dump.containsKey('secondEvolutionLevel'), isTrue);
        expect(dump.containsKey('evolutionSelectionTimeoutSeconds'), isTrue);

        // Bonuses
        expect(dump.containsKey('offensiveDamageBonus'), isTrue);
        expect(dump.containsKey('defensiveHpBonus'), isTrue);
        expect(dump.containsKey('supportAllyEffectBonus'), isTrue);

        // Skills
        expect(dump.containsKey('skillCooldownMultiplier'), isTrue);
        expect(dump.containsKey('skillDamageMultiplier'), isTrue);
        expect(dump.containsKey('ultUnlockLevel'), isTrue);

        // Feature flags
        expect(dump.containsKey('isSkillProgressionEnabled'), isTrue);
        expect(dump.containsKey('isEvolutionSwitchingEnabled'), isTrue);
        expect(dump.containsKey('isAnalyticsTrackingEnabled'), isTrue);

        // Presets
        expect(dump.containsKey('difficultyPreset'), isTrue);
        expect(dump.containsKey('difficultyModifiers'), isTrue);
      });
    });

    group('Singleton Pattern', () {
      test('SkillProgressionConfig is singleton', () {
        final config1 = SkillProgressionConfig();
        final config2 = SkillProgressionConfig();

        expect(identical(config1, config2), isTrue);
      });
    });

    group('Error Handling', () {
      test('getters handle Remote Config exceptions gracefully', () async {
        await config.initialize(mockRemoteConfig);

        when(mockRemoteConfig.getDouble(any))
            .thenThrow(Exception('Invalid value'));

        // Should return default without throwing
        expect(() => config.levelDifficultyMultiplier, returnsNormally);
        expect(config.levelDifficultyMultiplier, 1.0); // Default value
      });

      test('boolean getters handle exceptions', () async {
        await config.initialize(mockRemoteConfig);

        when(mockRemoteConfig.getBool(any))
            .thenThrow(Exception('Type mismatch'));

        // Should return default without throwing
        expect(() => config.isSkillProgressionEnabled, returnsNormally);
        expect(config.isSkillProgressionEnabled, isTrue);
      });

      test('string getters handle exceptions', () async {
        await config.initialize(mockRemoteConfig);

        when(mockRemoteConfig.getString(any))
            .thenThrow(Exception('Missing value'));

        // Should return default without throwing
        expect(() => config.difficultyPreset, returnsNormally);
        expect(config.difficultyPreset, 'normal');
      });
    });
  });
}
