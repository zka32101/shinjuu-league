import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart' show Colors;

/// 攻撃側と被弾側を一瞬つなぐ稲妻状の衝撃線。寿命が尽きたら自動的に自身を除去する。
class ImpactLine extends PositionComponent {
  ImpactLine({required this.from, required this.to});

  final Vector2 from;
  final Vector2 to;

  static const _lifetime = 0.18;
  double _elapsed = 0.0;

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    if (_elapsed >= _lifetime) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final progress = (_elapsed / _lifetime).clamp(0.0, 1.0);
    final alpha = 1.0 - progress;

    final random = Random(from.x.toInt() ^ to.y.toInt());
    final segments = 5;
    final path = Path()..moveTo(from.x, from.y);
    for (var i = 1; i < segments; i++) {
      final t = i / segments;
      final baseX = from.x + (to.x - from.x) * t;
      final baseY = from.y + (to.y - from.y) * t;
      final jitter = (random.nextDouble() - 0.5) * 12;
      path.lineTo(baseX + jitter, baseY + jitter);
    }
    path.lineTo(to.x, to.y);

    final paint = Paint()
      ..color = Colors.white.withOpacity(alpha * 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawPath(path, paint);
  }
}
