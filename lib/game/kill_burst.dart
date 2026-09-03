import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart' show Colors;

/// キル発生位置から破片が飛び散る演出。寿命が尽きたら自動的に自身を除去する。
class KillBurst extends PositionComponent {
  KillBurst({required Vector2 worldPosition})
    : super(position: worldPosition, anchor: Anchor.center) {
    final random = Random();
    _particles = List.generate(10, (i) {
      final angle = (i / 10) * pi * 2 + random.nextDouble() * 0.4;
      return _Particle(angle: angle, speed: 40 + random.nextDouble() * 40);
    });
  }

  static const _lifetime = 0.45;

  late final List<_Particle> _particles;
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
    final alpha = (1.0 - progress);

    for (final particle in _particles) {
      final distance = particle.speed * _elapsed;
      final dx = cos(particle.angle) * distance;
      final dy = sin(particle.angle) * distance * 0.6;
      final paint = Paint()
        ..color = Colors.amberAccent.withValues(alpha: alpha)
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(dx, dy),
        Offset(dx - cos(particle.angle) * 6, dy - sin(particle.angle) * 6),
        paint,
      );
    }
  }
}

class _Particle {
  _Particle({required this.angle, required this.speed});
  final double angle;
  final double speed;
}
