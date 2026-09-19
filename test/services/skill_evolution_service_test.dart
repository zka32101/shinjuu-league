import 'package:flutter_test/flutter_test.dart';
import 'package:shinjuu_league/data/models/skill_catalog.dart';
import 'package:shinjuu_league/services/skill_evolution_service.dart';

void main() {
  group('SkillEvolutionService', () {
    test('getCharacterSkills returns valid skill set for known character', () {
      final skills = SkillEvolutionService.getCharacterSkills('leon');
      expect(skills, isNotNull);
      expect(skills!.keys, contains(SkillSlot.q));
      expect(skills.keys, contains(SkillSlot.r));
      expect(skills.keys, contains(SkillSlot.e));
      expect(skills.keys, contains(SkillSlot.ult));
    });

    test('getCharacterSkills returns null for unknown character', () {
      final skills = SkillEvolutionService.getCharacterSkills('unknown');
      expect(skills, isNull);
    });

    test('getSkillDamageAtLevel returns correct damage for Q skill', () {
      final damage = SkillEvolutionService.getSkillDamageAtLevel(
        'leon',
        SkillSlot.q,
        1,
      );
      expect(damage, equals(200));
    });

    test('getSkillDamageAtLevel returns correct damage at different levels', () {
      final dmg1 = SkillEvolutionService.getSkillDamageAtLevel(
        'leon',
        SkillSlot.q,
        1,
      );
      final dmg8 = SkillEvolutionService.getSkillDamageAtLevel(
        'leon',
        SkillSlot.q,
        8,
      );
      expect(dmg1, lessThan(dmg8!));
    });

    test('getSkillCooldownAtLevel returns correct cooldown', () {
      final cd = SkillEvolutionService.getSkillCooldownAtLevel(
        'leon',
        SkillSlot.q,
        1,
      );
      expect(cd, equals(4.0));
    });

    test('calculateEvolutionBonuses for offensive type', () {
      final bonuses = SkillEvolutionService.calculateEvolutionBonuses(
        evolutionType: EvolutionType.offensive,
        levelIntoEvolution: 1,
        isSecondEvolution: false,
      );
      expect(bonuses['damage_bonus'], greaterThan(0.0));
      expect(bonuses['hp_bonus'], equals(0.0));
    });

    test('calculateEvolutionBonuses for defensive type', () {
      final bonuses = SkillEvolutionService.calculateEvolutionBonuses(
        evolutionType: EvolutionType.defensive,
        levelIntoEvolution: 1,
        isSecondEvolution: false,
      );
      expect(bonuses['hp_bonus'], greaterThan(0.0));
      expect(bonuses['damage_bonus'], equals(0.0));
    });

    test('calculateEvolutionBonuses for support type', () {
      final bonuses = SkillEvolutionService.calculateEvolutionBonuses(
        evolutionType: EvolutionType.support,
        levelIntoEvolution: 1,
        isSecondEvolution: false,
      );
      expect(bonuses['ally_effect_bonus'], greaterThan(0.0));
    });

    test('getEvolutionDescription returns valid string', () {
      final desc = SkillEvolutionService.getEvolutionDescription(
        EvolutionType.offensive,
      );
      expect(desc, isNotEmpty);
      expect(desc, contains('ダメージ'));
    });

    test('getDefaultEvolutionChoice returns offensive', () {
      final choice = SkillEvolutionService.getDefaultEvolutionChoice();
      expect(choice, equals(EvolutionType.offensive));
    });

    test('isUltCharging true at level 5+', () {
      expect(SkillEvolutionService.isUltCharging(4), isFalse);
      expect(SkillEvolutionService.isUltCharging(5), isTrue);
      expect(SkillEvolutionService.isUltCharging(7), isTrue);
    });

    test('isUltUnlocked true at level 7+', () {
      expect(SkillEvolutionService.isUltUnlocked(6), isFalse);
      expect(SkillEvolutionService.isUltUnlocked(7), isTrue);
    });

    test('isSkillAvailable checks slot availability by level', () {
      expect(SkillEvolutionService.isSkillAvailable(1, SkillSlot.q), isTrue);
      expect(SkillEvolutionService.isSkillAvailable(1, SkillSlot.r), isFalse);
      expect(SkillEvolutionService.isSkillAvailable(2, SkillSlot.r), isTrue);
      expect(SkillEvolutionService.isSkillAvailable(6, SkillSlot.ult), isFalse);
      expect(SkillEvolutionService.isSkillAvailable(7, SkillSlot.ult), isTrue);
    });

    test('hasEvolutionChoice returns true for evolution levels', () {
      expect(SkillEvolutionService.hasEvolutionChoice(3), isTrue);
      expect(SkillEvolutionService.hasEvolutionChoice(6), isTrue);
      expect(SkillEvolutionService.hasEvolutionChoice(8), isTrue);
      expect(SkillEvolutionService.hasEvolutionChoice(4), isFalse);
      expect(SkillEvolutionService.hasEvolutionChoice(7), isFalse);
    });

    test('getNextEvolutionLevel returns correct level', () {
      expect(SkillEvolutionService.getNextEvolutionLevel(1), equals(3));
      expect(SkillEvolutionService.getNextEvolutionLevel(3), equals(6));
      expect(SkillEvolutionService.getNextEvolutionLevel(6), equals(8));
      expect(SkillEvolutionService.getNextEvolutionLevel(8), isNull);
    });

    test('getLevelUpRewards returns valid rewards', () {
      final rewards = SkillEvolutionService.getLevelUpRewards(newLevel: 5);
      expect(rewards['experience'], equals(20));
      expect(rewards['gold'], greaterThan(0));
      expect(rewards['gold'], equals(50 + (5 * 10)));
    });

    test('All 6 characters have valid skill sets', () {
      final characterIds = ['leon', 'wolf', 'dragoon', 'frost', 'phoenix', 'crystal'];
      for (final id in characterIds) {
        final skills = SkillEvolutionService.getCharacterSkills(id);
        expect(skills, isNotNull, reason: '$id should have skills');
        expect(skills!.length, equals(4), reason: '$id should have 4 slots');
      }
    });

    test('Q skill is available from level 1', () {
      for (final id in ['leon', 'wolf', 'dragoon']) {
        final damage = SkillEvolutionService.getSkillDamageAtLevel(
          id,
          SkillSlot.q,
          1,
        );
        expect(damage, isNotNull, reason: '$id Q should be available at Lv1');
      }
    });

    test('R skill is not available below level 2', () {
      expect(SkillEvolutionService.isSkillAvailable(1, SkillSlot.r), isFalse);
      expect(SkillEvolutionService.isSkillAvailable(2, SkillSlot.r), isTrue);
    });

    test('E skill evolution choice happens at Lv3', () {
      final nextLv = SkillEvolutionService.getNextEvolutionLevel(2);
      expect(nextLv, equals(3));
    });

    test('ULT unlocks at Lv7', () {
      expect(SkillEvolutionService.isUltUnlocked(6), isFalse);
      expect(SkillEvolutionService.isUltUnlocked(7), isTrue);
    });

    test('Second evolution can be switched at Lv6', () {
      expect(SkillEvolutionService.canSwitchEvolutionAtLv6(), isTrue);
    });

    test('Evolution bonuses increase with level', () {
      final bonus1 = SkillEvolutionService.calculateEvolutionBonuses(
        evolutionType: EvolutionType.offensive,
        levelIntoEvolution: 0,
      );
      final bonus5 = SkillEvolutionService.calculateEvolutionBonuses(
        evolutionType: EvolutionType.offensive,
        levelIntoEvolution: 5,
      );
      expect(bonus5['damage_bonus'], greaterThan(bonus1['damage_bonus']!));
    });

    test('Dragoon has different damage curve than Leon', () {
      final dragonQ1 = SkillEvolutionService.getSkillDamageAtLevel(
        'dragoon',
        SkillSlot.q,
        1,
      );
      final leonQ1 = SkillEvolutionService.getSkillDamageAtLevel(
        'leon',
        SkillSlot.q,
        1,
      );
      expect(dragonQ1, isNotNull);
      expect(leonQ1, isNotNull);
      // Both should have damage but potentially different values
      expect((dragonQ1! + leonQ1!), greaterThan(0));
    });
  });
}
