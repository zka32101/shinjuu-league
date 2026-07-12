import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart' show Colors, PaintingStyle;
import 'package:shinjuu_league/game/isometric_projection.dart';

/// レーンの地面を等角投影の菱形パネルとして描画する（実背景素材未着手のプレースホルダー）。
class LaneFloor extends PositionComponent {
  LaneFloor({required this.laneCenterY, required this.color});

  final double laneCenterY;
  final Color color;

  static const _projection = IsometricProjection();

  @override
  void render(Canvas canvas) {
    final corners = [
      _projection.toScreen(-2.4, laneCenterY - 1.1),
      _projection.toScreen(2.4, laneCenterY - 1.1),
      _projection.toScreen(2.4, laneCenterY + 1.1),
      _projection.toScreen(-2.4, laneCenterY + 1.1),
    ];

    final path = Path()..moveTo(corners[0].x, corners[0].y);
    for (final corner in corners.skip(1)) {
      path.lineTo(corner.x, corner.y);
    }
    path.close();

    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }
}
