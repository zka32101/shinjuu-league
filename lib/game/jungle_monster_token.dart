import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart'
    show Colors, Icons, TextDirection, TextPainter, TextSpan, TextStyle;

/// レーン中央に鎮座する中立モンスターの描画。討伐すると討伐者へゴール+攻撃バフを与える
/// （BattleEngine側の状態が唯一の正、このクラスは見た目のみ）。
class JungleMonsterToken extends PositionComponent {
  JungleMonsterToken({
    required this.monsterId,
    required this.lane,
    required Vector2 basePosition,
  }) : super(position: basePosition, size: Vector2.all(56), anchor: Anchor.center);

  final String monsterId;
  final int lane;

  bool isAlive = true;
  double _hpRatio = 1.0;
  double _targetHpRatio = 1.0;
  double _opacity = 1.0;
  double _targetOpacity = 1.0;
  double _hitFlash = 0.0;
  double _idleTime = 0.0;

  void updateHp(double currentHp, double maxHp) {
    if (maxHp <= 0) return;
    _targetHpRatio = (currentHp / maxHp).clamp(0.0, 1.0);
  }

  void setAlive(bool alive) {
    if (isAlive == alive) return;
    isAlive = alive;
    _targetOpacity = alive ? 1.0 : 0.0;
    if (alive) _targetHpRatio = 1.0;
  }

  void triggerHitFlash() {
    _hitFlash = 1.0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _idleTime += dt;
    final lerpFactor = (dt * 6).clamp(0.0, 1.0);
    _opacity += (_targetOpacity - _opacity) * lerpFactor;
    _hpRatio += (_targetHpRatio - _hpRatio) * lerpFactor;
    if (_hitFlash > 0) {
      _hitFlash = (_hitFlash - dt * 5.0).clamp(0.0, 1.0);
    }
  }

  @override
  void render(Canvas canvas) {
    if (_opacity <= 0.01) return;

    final pulse = 1.0 + sin(_idleTime * 3.0) * 0.05;
    final radius = (size.x / 2) * pulse;
    final center = Offset(size.x / 2, size.y / 2);

    // 威圧的な脈動グロー（存在をアピールする野生モンスターらしさ）
    final glowPaint = Paint()
      ..color = const Color(0xFF2ECC71).withValues(alpha: _opacity * 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(center, radius * 1.3, glowPaint);

    final lightColor = const Color(0xFF6EE7A0);
    final baseColor = const Color(0xFF16A34A);
    final darkColor = const Color(0xFF0B4D24);
    final bodyPaint = Paint()
      ..shader = Gradient.radial(
        Offset(center.dx - radius * 0.3, center.dy - radius * 0.3),
        radius * 1.3,
        [
          lightColor.withValues(alpha: _opacity),
          baseColor.withValues(alpha: _opacity),
          darkColor.withValues(alpha: _opacity),
        ],
        [0.0, 0.5, 1.0],
      );
    canvas.drawCircle(center, radius, bodyPaint);

    if (_hitFlash > 0) {
      final hitPaint = Paint()
        ..color = Colors.white.withValues(alpha: _hitFlash * 0.85)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(center, radius + 4, hitPaint);
    }

    final iconPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(Icons.bug_report.codePoint),
        style: TextStyle(
          fontSize: radius,
          fontFamily: Icons.bug_report.fontFamily,
          package: Icons.bug_report.fontPackage,
          color: Colors.white.withValues(alpha: _opacity),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    iconPainter.paint(
      canvas,
      Offset(center.dx - iconPainter.width / 2, center.dy - iconPainter.height / 2),
    );

    if (isAlive) {
      const barWidth = 44.0;
      const barHeight = 5.0;
      final barTop = center.dy - radius - 14;
      final barRect = Rect.fromLTWH(center.dx - barWidth / 2, barTop, barWidth, barHeight);
      canvas.drawRRect(
        RRect.fromRectAndRadius(barRect, const Radius.circular(2)),
        Paint()..color = Colors.black.withValues(alpha: 0.5 * _opacity),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(barRect.left, barRect.top, barWidth * _hpRatio, barHeight),
          const Radius.circular(2),
        ),
        Paint()..color = const Color(0xFF4ADE80).withValues(alpha: _opacity),
      );
    }
  }
}
