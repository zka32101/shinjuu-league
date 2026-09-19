import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:shinjuu_league/data/mecha_catalog.dart';
import 'package:shinjuu_league/game/mecha_glyph.dart';

void main() {
  group('MechaGlyph', () {
    test('同じ神獣からは常に同じ形状パラメータが得られる（決定的）', () {
      final mecha = mechaById('mecha_east_flame');
      final a = MechaGlyph.forMecha(mecha);
      final b = MechaGlyph.forMecha(mecha);

      expect(a.isArmored, equals(b.isArmored));
      expect(a.spikeCount, equals(b.spikeCount));
      expect(a.accentCount, equals(b.accentCount));
      expect(a.rotationOffset, equals(b.rotationOffset));
    });

    test('スパイク数は常に2〜6本の範囲に収まる', () {
      for (final mecha in mechaCatalog) {
        final glyph = MechaGlyph.forMecha(mecha);
        expect(glyph.spikeCount, inInclusiveRange(2, 6));
      }
    });

    test('レアリティが高いほどアクセント数・グロー強度が大きくなる', () {
      final common = MechaGlyph.forMecha(mechaById('mecha_east_flame')); // COMMON
      final legend = MechaGlyph.forMecha(mechaById('mecha_west_gold')); // LEGEND

      expect(legend.accentCount, greaterThan(common.accentCount));
      expect(legend.glowStrength, greaterThan(common.glowStrength));
    });

    test('EAST/WESTでアクセントカラーが異なる', () {
      final east = MechaGlyph.forMecha(mechaById('mecha_east_flame'));
      final west = MechaGlyph.forMecha(mechaById('mecha_west_frost'));
      expect(east.accentColor, isNot(equals(west.accentColor)));
    });

    test('カタログ全神獣に対してrender()相当のpaint()が例外を投げない', () {
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      for (final mecha in mechaCatalog) {
        final glyph = MechaGlyph.forMecha(mecha);
        expect(
          () => glyph.paint(canvas, const ui.Offset(50, 50), 23, 1.0),
          returnsNormally,
        );
      }
      recorder.endRecording().dispose();
    });

    test('未知のmechaIdでもmechaByIdのフォールバックにより例外を投げない', () {
      final mecha = mechaById('nonexistent_id');
      expect(() => MechaGlyph.forMecha(mecha), returnsNormally);
    });
  });
}
