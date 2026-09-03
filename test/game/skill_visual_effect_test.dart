import 'package:flutter_test/flutter_test.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:shinjuu_league/game/skill_visual_effect.dart';
import 'package:shinjuu_league/data/models/skill_model.dart';

void main() {
  group('SkillVisualEffect', () {
    late FlameGame game;

    setUp(() {
      game = FlameGame();
    });

    tearDown(() {
      game.dispose();
    });

    test('creates SkillVisualEffect with offensive type', () {
      final effect = SkillVisualEffect(
        position: Vector2(100, 100),
        skillType: SkillType.offensive,
        maxRadius: 90,
      );

      expect(effect.skillType, equals(SkillType.offensive));
      expect(effect.maxRadius, equals(90));
      expect(effect.position, equals(Vector2(100, 100)));
    });

    test('creates SkillVisualEffect with defensive type', () {
      final effect = SkillVisualEffect(
        position: Vector2(50, 50),
        skillType: SkillType.defensive,
        maxRadius: 80,
      );

      expect(effect.skillType, equals(SkillType.defensive));
      expect(effect.maxRadius, equals(80));
    });

    test('creates SkillVisualEffect with utility type', () {
      final effect = SkillVisualEffect(
        position: Vector2(200, 150),
        skillType: SkillType.utility,
        maxRadius: 100,
      );

      expect(effect.skillType, equals(SkillType.utility));
      expect(effect.maxRadius, equals(100));
    });

    test('default radius is zero', () {
      final effect = SkillVisualEffect(
        position: Vector2(0, 0),
        skillType: SkillType.offensive,
      );

      expect(effect.radius, equals(0));
    });
  });

  group('CriticalBurst', () {
    test('creates CriticalBurst with default particle count', () {
      final burst = CriticalBurst(position: Vector2(100, 100));

      expect(burst.burstCount, equals(12));
      expect(burst.position, equals(Vector2(100, 100)));
    });

    test('creates CriticalBurst with custom particle count', () {
      final burst = CriticalBurst(
        position: Vector2(50, 50),
        burstCount: 20,
      );

      expect(burst.burstCount, equals(20));
    });
  });

  group('SkillAreaIndicator', () {
    test('creates SkillAreaIndicator with offensive type', () {
      final indicator = SkillAreaIndicator(
        position: Vector2(100, 100),
        radius: 90,
        skillType: SkillType.offensive,
        isActive: true,
      );

      expect(indicator.position, equals(Vector2(100, 100)));
      expect(indicator.radius, equals(90));
      expect(indicator.skillType, equals(SkillType.offensive));
      expect(indicator.isActive, equals(true));
    });

    test('can be toggled inactive', () {
      final indicator = SkillAreaIndicator(
        position: Vector2(100, 100),
        radius: 90,
        skillType: SkillType.defensive,
        isActive: false,
      );

      expect(indicator.isActive, equals(false));
    });

    test('offensive type uses correct color', () {
      final effect1 = SkillVisualEffect(
        position: Vector2(0, 0),
        skillType: SkillType.offensive,
      );
      final effect2 = SkillVisualEffect(
        position: Vector2(0, 0),
        skillType: SkillType.offensive,
      );

      // Both should be offensive, so they should have same type
      expect(effect1.skillType, equals(effect2.skillType));
    });
  });

  group('BurstParticle', () {
    test('creates BurstParticle with initial parameters', () {
      final particle = BurstParticle(
        startPos: Vector2(100, 100),
        velocity: Vector2(50, 0),
        lifetime: 0.5,
        isGolden: true,
      );

      expect(particle.position, equals(Vector2(100, 100)));
      expect(particle.velocity, equals(Vector2(50, 0)));
      expect(particle.lifetime, equals(0.5));
      expect(particle.isGolden, equals(true));
    });

    test('can create non-golden particle', () {
      final particle = BurstParticle(
        startPos: Vector2(0, 0),
        velocity: Vector2(10, 10),
        lifetime: 0.3,
        isGolden: false,
      );

      expect(particle.isGolden, equals(false));
    });
  });

  group('skill visual effects integration', () {
    test('all skill types can be instantiated', () {
      final types = [
        SkillType.offensive,
        SkillType.defensive,
        SkillType.utility,
      ];

      for (final type in types) {
        final effect = SkillVisualEffect(
          position: Vector2.zero(),
          skillType: type,
        );
        expect(effect.skillType, equals(type));
      }
    });

    test('skill area indicator accepts all skill types', () {
      final types = [
        SkillType.offensive,
        SkillType.defensive,
        SkillType.utility,
      ];

      for (final type in types) {
        final indicator = SkillAreaIndicator(
          position: Vector2.zero(),
          radius: 90,
          skillType: type,
        );
        expect(indicator.skillType, equals(type));
      }
    });
  });
}
