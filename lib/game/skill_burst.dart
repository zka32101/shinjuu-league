import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart' show Colors;

/// スキル発動時の範囲攻撃を示す拡大するリング演出。寿命が尽きたら自動的に自身を除去する。
class SkillBurst extends PositionComponent {
  SkillBurst({required Vector2 worldPosition, required this.radius})
    : super(position: worldPosition, anchor: Anchor.center);

  final double radius;

  static const _lifetime = 0.4;
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
    final currentRadius = radius * progress;
    final alpha = 1.0 - progress;

    canvas.drawCircle(
      Offset.zero,
      currentRadius,
      Paint()
        ..color = Colors.cyanAccent.withValues(alpha: alpha * 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
    canvas.drawCircle(
      Offset.zero,
      currentRadius,
      Paint()..color = Colors.cyanAccent.withValues(alpha: alpha * 0.12),
    );
  }
}
