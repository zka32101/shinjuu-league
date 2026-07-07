import 'package:flutter_test/flutter_test.dart';
import 'package:shinjuu_league/data/mecha_catalog.dart';

const _validRarities = {'COMMON', 'RARE', 'EPIC', 'LEGEND'};
const _validOrigins = {'EAST', 'WEST'};

void main() {
  group('mechaCatalog データ整合性', () {
    test('mechaId が重複していない', () {
      final ids = mechaCatalog.map((m) => m.mechaId).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('全ての神獣が有効な rarity/origin を持つ', () {
      for (final mecha in mechaCatalog) {
        expect(
          _validRarities.contains(mecha.rarity),
          isTrue,
          reason: '${mecha.mechaId}: ${mecha.rarity}',
        );
        expect(
          _validOrigins.contains(mecha.origin),
          isTrue,
          reason: '${mecha.mechaId}: ${mecha.origin}',
        );
      }
    });

    test('全ての神獣が name/description を持つ（空文字禁止）', () {
      for (final mecha in mechaCatalog) {
        expect(mecha.name, isNotEmpty, reason: mecha.mechaId);
        expect(mecha.description, isNotEmpty, reason: mecha.mechaId);
      }
    });

    test('全てのステータスが正の値（0以下はバトルエンジンで不整合を起こす）', () {
      for (final mecha in mechaCatalog) {
        expect(mecha.baseStats.hp, greaterThan(0), reason: mecha.mechaId);
        expect(mecha.baseStats.atk, greaterThan(0), reason: mecha.mechaId);
        expect(mecha.baseStats.spd, greaterThan(0), reason: mecha.mechaId);
      }
    });

    test('defaultMechaId がカタログに実在する', () {
      expect(mechaCatalog.any((m) => m.mechaId == defaultMechaId), isTrue);
    });

    test('mechaById は存在しないIDに対してフォールバックする（例外を投げない）', () {
      final fallback = mechaById('存在しないID');
      expect(fallback, isNotNull);
    });

    test('mechaById は正しい神獣を返す', () {
      final mecha = mechaById(mechaCatalog.last.mechaId);
      expect(mecha.mechaId, mechaCatalog.last.mechaId);
    });
  });
}
