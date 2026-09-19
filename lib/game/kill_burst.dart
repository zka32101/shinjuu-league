import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart' show Colors, Curves;

/// キル発生位置から破片が飛び散る演出。寿命が尽きたら自動的に自身を除去する。
class KillBurst extends PositionComponent {
  KillBurst({required Vector2 worldPosition})
    : super(position: worldPosition, anchor: Anchor.center) {
    final random = Random();
    // 28本の破片 + 大小2種の破片サイズを混在させ、より派手な爆発感を出す
    _particles = List.generate(28, (i) {
      final angle = (i / 28) * pi * 2 + random.nextDouble() * 0.35;
      return _Particle(
        angle: angle,
        speed: 55 + random.nextDouble() * 110,
        length: 5 + random.nextDouble() * 11,
      );
    });
    // 中心付近を漂う小さな火花の粒（線ではなく点）を追加し、爆発の密度感を強める
    _sparks = List.generate(14, (i) {
      final angle = random.nextDouble() * pi * 2;
      return _Particle(
        angle: angle,
        speed: 20 + random.nextDouble() * 60,
        length: 1.5 + random.nextDouble() * 2,
      );
    });
  }

  static const _lifetime = 0.6;

  late final List<_Particle> _particles;
  late final List<_Particle> _sparks;
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

    // 中心から拡散する衝撃波リング（三重）で爆発の「面」を強調
    final ringProgress = Curves.easeOut.transform(progress);
    for (final ringScale in [1.3, 1.0, 0.6]) {
      final ringPaint = Paint()
        ..color = Colors.amberAccent.withValues(alpha: alpha * 0.65 * ringScale)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3 * ringScale;
      canvas.drawCircle(Offset.zero, ringProgress * 70 * ringScale, ringPaint);
    }

    // 中心の白いフラッシュ（発生直後だけ強く光る）
    if (progress < 0.3) {
      final flashAlpha = (1.0 - progress / 0.3) * 0.9;
      canvas.drawCircle(
        Offset.zero,
        22,
        Paint()
          ..color = Colors.white.withValues(alpha: flashAlpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
    }

    // 中心付近を漂う小さな火花の粒
    for (final spark in _sparks) {
      final distance = spark.speed * _elapsed;
      final dx = cos(spark.angle) * distance;
      final dy = sin(spark.angle) * distance * 0.6;
      canvas.drawCircle(
        Offset(dx, dy),
        spark.length * (1.0 - progress * 0.6),
        Paint()..color = Colors.white.withValues(alpha: alpha * 0.9),
      );
    }

    for (final particle in _particles) {
      final distance = particle.speed * _elapsed;
      final dx = cos(particle.angle) * distance;
      final dy = sin(particle.angle) * distance * 0.6;
      final paint = Paint()
        ..color = Color.lerp(Colors.white, Colors.amberAccent, 0.6)!
            .withValues(alpha: alpha)
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(dx, dy),
        Offset(
          dx - cos(particle.angle) * particle.length,
          dy - sin(particle.angle) * particle.length,
        ),
        paint,
      );
    }
  }
}

class _Particle {
  _Particle({required this.angle, required this.speed, required this.length});
  final double angle;
  final double speed;
  final double length;
}
