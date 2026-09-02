import 'dart:math';
import 'package:flutter/material.dart';

/// Lottie素材が用意できるまでの間、ネイティブCustomPainterで
/// キル演出・勝利のスター爆発を表現する軽量パーティクルエフェクト。
/// [trigger] の値が変化するたびにアニメーションを再生する。
class ParticleBurst extends StatefulWidget {
  const ParticleBurst({
    super.key,
    required this.trigger,
    this.particleCount = 16,
    this.color = Colors.amber,
    this.size = 120,
  });

  final Object trigger;
  final int particleCount;
  final Color color;
  final double size;

  @override
  State<ParticleBurst> createState() => _ParticleBurstState();
}

class _ParticleBurstState extends State<ParticleBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  late List<Offset> _directions = _generateDirections(widget.particleCount);

  List<Offset> _generateDirections(int count) {
    return List.generate(count, (i) {
      final angle = (2 * pi / count) * i;
      return Offset(cos(angle), sin(angle));
    });
  }

  @override
  void didUpdateWidget(covariant ParticleBurst oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.particleCount != widget.particleCount) {
      _directions = _generateDirections(widget.particleCount);
    }
    if (oldWidget.trigger != widget.trigger) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            size: Size.square(widget.size),
            painter: _BurstPainter(
              progress: _controller.value,
              directions: _directions,
              color: widget.color,
            ),
          );
        },
      ),
    );
  }
}

class _BurstPainter extends CustomPainter {
  _BurstPainter({
    required this.progress,
    required this.directions,
    required this.color,
  });

  final double progress;
  final List<Offset> directions;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;

    final center = size.center(Offset.zero);
    final maxRadius = size.width / 2;
    final paint = Paint()
      ..color = color.withOpacity((1 - progress).clamp(0.0, 1.0));

    for (final dir in directions) {
      final distance = maxRadius * progress;
      final pos = center + dir * distance;
      final radius = 4 * (1 - progress) + 1;
      canvas.drawCircle(pos, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BurstPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
