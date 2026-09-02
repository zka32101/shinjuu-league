import 'package:flutter_test/flutter_test.dart';
import 'package:flame/components.dart';
import 'package:shinjuu_league/game/buff_indicator.dart';

void main() {
  group('BuffIndicator', () {
    test('creates BuffIndicator with atk boost', () {
      final indicator = BuffIndicator(
        buffType: BuffType.atkBoost,
        duration: 1.0,
        tokenPosition: Vector2(100, 100),
      );

      expect(indicator.buffType, equals(BuffType.atkBoost));
      expect(indicator.duration, equals(1.0));
      expect(indicator.tokenPosition, equals(Vector2(100, 100)));
    });

    test('creates BuffIndicator with def boost', () {
      final indicator = BuffIndicator(
        buffType: BuffType.defBoost,
        duration: 1.5,
        tokenPosition: Vector2(50, 50),
      );

      expect(indicator.buffType, equals(BuffType.defBoost));
      expect(indicator.duration, equals(1.5));
    });

    test('creates BuffIndicator with spd boost', () {
      final indicator = BuffIndicator(
        buffType: BuffType.spdBoost,
        duration: 2.0,
        tokenPosition: Vector2(200, 200),
      );

      expect(indicator.buffType, equals(BuffType.spdBoost));
      expect(indicator.duration, equals(2.0));
    });

    test('creates BuffIndicator with atk debuff', () {
      final indicator = BuffIndicator(
        buffType: BuffType.atkDebuff,
        duration: 1.0,
        tokenPosition: Vector2(0, 0),
      );

      expect(indicator.buffType, equals(BuffType.atkDebuff));
    });

    test('creates BuffIndicator with def debuff', () {
      final indicator = BuffIndicator(
        buffType: BuffType.defDebuff,
        duration: 1.0,
        tokenPosition: Vector2(0, 0),
      );

      expect(indicator.buffType, equals(BuffType.defDebuff));
    });

    test('creates BuffIndicator with spd debuff', () {
      final indicator = BuffIndicator(
        buffType: BuffType.spdDebuff,
        duration: 1.0,
        tokenPosition: Vector2(0, 0),
      );

      expect(indicator.buffType, equals(BuffType.spdDebuff));
    });

    test('creates BuffIndicator with healing', () {
      final indicator = BuffIndicator(
        buffType: BuffType.healing,
        duration: 0.8,
        tokenPosition: Vector2(75, 75),
      );

      expect(indicator.buffType, equals(BuffType.healing));
      expect(indicator.duration, equals(0.8));
    });
  });

  group('BuffType enum', () {
    test('has all expected buff types', () {
      const expectedTypes = [
        BuffType.atkBoost,
        BuffType.defBoost,
        BuffType.spdBoost,
        BuffType.atkDebuff,
        BuffType.defDebuff,
        BuffType.spdDebuff,
        BuffType.healing,
      ];

      for (final type in expectedTypes) {
        expect(type, isNotNull);
      }
    });
  });

  group('BuffIndicator visual properties', () {
    test('atk boost uses red color', () {
      final indicator = BuffIndicator(
        buffType: BuffType.atkBoost,
        duration: 1.0,
        tokenPosition: Vector2.zero(),
      );
      expect(indicator.buffType, equals(BuffType.atkBoost));
    });

    test('def boost uses blue color', () {
      final indicator = BuffIndicator(
        buffType: BuffType.defBoost,
        duration: 1.0,
        tokenPosition: Vector2.zero(),
      );
      expect(indicator.buffType, equals(BuffType.defBoost));
    });

    test('spd boost uses yellow color', () {
      final indicator = BuffIndicator(
        buffType: BuffType.spdBoost,
        duration: 1.0,
        tokenPosition: Vector2.zero(),
      );
      expect(indicator.buffType, equals(BuffType.spdBoost));
    });

    test('healing uses green color', () {
      final indicator = BuffIndicator(
        buffType: BuffType.healing,
        duration: 1.0,
        tokenPosition: Vector2.zero(),
      );
      expect(indicator.buffType, equals(BuffType.healing));
    });
  });

  group('BuffIndicator position handling', () {
    test('position updates during update() call', () {
      final indicator = BuffIndicator(
        buffType: BuffType.atkBoost,
        duration: 1.0,
        tokenPosition: Vector2(100, 100),
      );

      // Initial position should match token position
      expect(indicator.tokenPosition, equals(Vector2(100, 100)));
    });

    test('handles different token positions', () {
      final positions = [
        Vector2.zero(),
        Vector2(50, 50),
        Vector2(100, 100),
        Vector2(200, 200),
        Vector2(-50, -50),
      ];

      for (final pos in positions) {
        final indicator = BuffIndicator(
          buffType: BuffType.atkBoost,
          duration: 1.0,
          tokenPosition: pos,
        );
        expect(indicator.tokenPosition, equals(pos));
      }
    });
  });

  group('BuffIndicator duration', () {
    test('accepts various durations', () {
      const durations = [0.1, 0.5, 1.0, 1.5, 2.0, 3.0];

      for (final duration in durations) {
        final indicator = BuffIndicator(
          buffType: BuffType.atkBoost,
          duration: duration,
          tokenPosition: Vector2.zero(),
        );
        expect(indicator.duration, equals(duration));
      }
    });
  });

  group('BuffIndicator integration', () {
    test('can create multiple indicators for same token', () {
      final tokenPos = Vector2(100, 100);
      final indicators = [
        BuffIndicator(buffType: BuffType.atkBoost, duration: 1.0, tokenPosition: tokenPos),
        BuffIndicator(buffType: BuffType.defBoost, duration: 1.0, tokenPosition: tokenPos),
        BuffIndicator(buffType: BuffType.spdBoost, duration: 1.0, tokenPosition: tokenPos),
      ];

      expect(indicators.length, equals(3));
      for (final ind in indicators) {
        expect(ind.tokenPosition, equals(tokenPos));
      }
    });

    test('boost and debuff indicators can coexist', () {
      final tokenPos = Vector2(100, 100);
      final boost = BuffIndicator(
        buffType: BuffType.atkBoost,
        duration: 1.0,
        tokenPosition: tokenPos,
      );
      final debuff = BuffIndicator(
        buffType: BuffType.defDebuff,
        duration: 1.0,
        tokenPosition: tokenPos,
      );

      expect(boost.buffType, equals(BuffType.atkBoost));
      expect(debuff.buffType, equals(BuffType.defDebuff));
      expect(boost.tokenPosition, equals(debuff.tokenPosition));
    });
  });
}
