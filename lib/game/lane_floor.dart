import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart' show Colors, PaintingStyle;
import 'package:shinjuu_league/game/isometric_projection.dart';

/// レーンの地面を等角投影の菱形パネルとして描画する（実背景素材未着手のプレースホルダー）。
/// 奥行きグラデーション + 内部グリッド + 縁のハイライトで「床のタイル」らしい質感を出す。
class LaneFloor extends PositionComponent {
  LaneFloor({required this.laneCenterY, required this.color});

  final double laneCenterY;
  final Color color;

  static const _projection = IsometricProjection();
  static const _halfWidth = 2.4;
  static const _halfDepth = 1.1;

  @override
  void render(Canvas canvas) {
    final near = _projection.toScreen(_halfWidth, laneCenterY + _halfDepth);
    final far = _projection.toScreen(-_halfWidth, laneCenterY - _halfDepth);

    final corners = [
      _projection.toScreen(-_halfWidth, laneCenterY - _halfDepth),
      _projection.toScreen(_halfWidth, laneCenterY - _halfDepth),
      _projection.toScreen(_halfWidth, laneCenterY + _halfDepth),
      _projection.toScreen(-_halfWidth, laneCenterY + _halfDepth),
    ];

    final path = Path()..moveTo(corners[0].x, corners[0].y);
    for (final corner in corners.skip(1)) {
      path.lineTo(corner.x, corner.y);
    }
    path.close();

    // 奥（暗）→手前（明）の縦グラデーションで地面に奥行きを与える
    final fillPaint = Paint()
      ..shader = Gradient.linear(
        Offset(far.x, far.y),
        Offset(near.x, near.y),
        [
          Color.lerp(color, Colors.black, 0.35)!,
          color,
          Color.lerp(color, Colors.white, 0.06)!,
        ],
        [0.0, 0.6, 1.0],
      );
    canvas.drawPath(path, fillPaint);

    // 内部グリッド線（等角のマス目）でスケール感を出す
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var i = 1; i < 6; i++) {
      final t = -_halfWidth + (i / 6) * (_halfWidth * 2);
      final a = _projection.toScreen(t, laneCenterY - _halfDepth);
      final b = _projection.toScreen(t, laneCenterY + _halfDepth);
      canvas.drawLine(Offset(a.x, a.y), Offset(b.x, b.y), gridPaint);
    }

    // 縁のハイライト（面取りされたタイルの手触り）
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withOpacity(0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }
}
