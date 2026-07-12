import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:flutter_test/flutter_test.dart';
import 'package:shinjuu_league/game/mecha_token.dart';

MechaToken _buildToken({bool isSelf = false, int team = 0}) => MechaToken(
  userId: 'u1',
  team: team,
  isSelf: isSelf,
  icon: Icons.local_fire_department,
  basePosition: Vector2.zero(),
);

void main() {
  group('MechaToken', () {
    test('初期状態は生存', () {
      final token = _buildToken();
      expect(token.isAlive, isTrue);
    });

    test('setAlive(false) で死亡状態になる', () {
      final token = _buildToken();
      token.setAlive(false);
      expect(token.isAlive, isFalse);
    });

    test('setAlive(true) で復活状態に戻る', () {
      final token = _buildToken();
      token.setAlive(false);
      token.setAlive(true);
      expect(token.isAlive, isTrue);
    });

    test('update() を繰り返し呼んでも例外を投げない（透明度/スケールの補間）', () {
      final token = _buildToken();
      token.setAlive(false);
      for (var i = 0; i < 30; i++) {
        expect(() => token.update(1 / 60), returnsNormally);
      }
    });

    test('triggerKillFlash() 後の update() も例外を投げない', () {
      final token = _buildToken();
      token.triggerKillFlash();
      for (var i = 0; i < 10; i++) {
        expect(() => token.update(1 / 60), returnsNormally);
      }
    });

    test('render() が例外を投げずCanvasに描画できる', () {
      final token = _buildToken(isSelf: true);
      token.triggerKillFlash();
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      expect(() => token.render(canvas), returnsNormally);
      recorder.endRecording().dispose();
    });
  });
}
