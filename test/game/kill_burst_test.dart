import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shinjuu_league/game/kill_burst.dart';

void main() {
  group('KillBurst', () {
    test('render() が例外を投げずCanvasに描画できる', () {
      final burst = KillBurst(worldPosition: Vector2(10, 20));
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      expect(() => burst.render(canvas), returnsNormally);
      recorder.endRecording().dispose();
    });

    test('寿命が尽きると自身をツリーから除去しようとする', () {
      final burst = KillBurst(worldPosition: Vector2.zero());
      // removeFromParent() はマウントされていない状態でも例外を投げない
      expect(() => burst.update(1.0), returnsNormally);
    });
  });
}
