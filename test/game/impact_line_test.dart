import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shinjuu_league/game/impact_line.dart';

void main() {
  group('ImpactLine', () {
    test('render() が例外を投げずCanvasに描画できる', () {
      final line = ImpactLine(from: Vector2(0, 0), to: Vector2(50, 30));
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      expect(() => line.render(canvas), returnsNormally);
      recorder.endRecording().dispose();
    });

    test('寿命が尽きても例外を投げない', () {
      final line = ImpactLine(from: Vector2.zero(), to: Vector2.zero());
      expect(() => line.update(1.0), returnsNormally);
    });
  });
}
