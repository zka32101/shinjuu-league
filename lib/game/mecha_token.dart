import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart'
    show Colors, IconData, TextPainter, TextSpan, TextStyle, TextDirection;

/// バトルフィールド上の1参加者を表すトークン。実キャラクター素材が無いため、
/// 円+属性アイコン（東=火焔/西=氷結）+ 影で「浮いた」2.5D感を表現するプレースホルダー。
class MechaToken extends PositionComponent {
  MechaToken({
    required this.userId,
    required this.team,
    required this.isSelf,
    required this.icon,
    required Vector2 basePosition,
  }) : super(
         position: basePosition,
         size: Vector2.all(36),
         anchor: Anchor.center,
       );

  final String userId;
  final int team;
  final bool isSelf;
  final IconData icon;

  bool isAlive = true;
  double _opacity = 1.0;
  double _targetOpacity = 1.0;
  double _scale = 1.0;
  double _targetScale = 1.0;
  double _flash = 0.0;

  Color get _teamColor =>
      team == 0 ? const Color(0xFF3B82F6) : const Color(0xFFEF4444);

  void setAlive(bool alive) {
    if (isAlive == alive) return;
    isAlive = alive;
    _targetOpacity = alive ? 1.0 : 0.25;
    _targetScale = alive ? 1.0 : 0.7;
  }

  /// 撃破した瞬間に白いリングを一瞬拡散させる演出（実エフェクト素材が無いための代替）
  void triggerKillFlash() {
    _flash = 1.0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    final lerpFactor = (dt * 6).clamp(0.0, 1.0);
    _opacity += (_targetOpacity - _opacity) * lerpFactor;
    _scale += (_targetScale - _scale) * lerpFactor;
    if (_flash > 0) {
      _flash = (_flash - dt * 2.5).clamp(0.0, 1.0);
    }
  }

  @override
  void render(Canvas canvas) {
    final radius = (size.x / 2) * _scale;
    final center = Offset(size.x / 2, size.y / 2);

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.25 * _opacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + radius * 0.9),
        width: radius * 1.6,
        height: radius * 0.6,
      ),
      shadowPaint,
    );

    final bodyPaint = Paint()..color = _teamColor.withValues(alpha: _opacity);
    canvas.drawCircle(center, radius, bodyPaint);

    if (isSelf) {
      final ringPaint = Paint()
        ..color = Colors.amber.withValues(alpha: _opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawCircle(center, radius + 2, ringPaint);
    }

    if (_flash > 0) {
      final flashPaint = Paint()
        ..color = Colors.white.withValues(alpha: _flash)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawCircle(center, radius + (1 - _flash) * 20, flashPaint);
    }

    final iconPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: radius,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: Colors.white.withValues(alpha: _opacity),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    iconPainter.paint(
      canvas,
      Offset(
        center.dx - iconPainter.width / 2,
        center.dy - iconPainter.height / 2,
      ),
    );
  }
}
