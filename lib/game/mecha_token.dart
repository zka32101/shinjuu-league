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
         size: Vector2.all(42),
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
  double _sinkOffset = 0.0;
  double _targetSinkOffset = 0.0;

  double _killFlash = 0.0; // 撃破した瞬間の金色リング拡散
  double _killPunch = 0.0; // 撃破した瞬間の自己スケールパンチ
  double _hitFlash = 0.0; // 被弾した瞬間の赤フラッシュ
  double _knockback = 0.0; // 被弾した瞬間のノックバック量（0..1で減衰）
  Vector2 _knockbackDir = Vector2.zero();

  Color get _teamColor =>
      team == 0 ? const Color(0xFF3B82F6) : const Color(0xFFEF4444);

  void setAlive(bool alive) {
    if (isAlive == alive) return;
    isAlive = alive;
    _targetOpacity = alive ? 1.0 : 0.25;
    _targetScale = alive ? 1.0 : 0.7;
    _targetSinkOffset = alive ? 0.0 : 10.0;
  }

  /// 撃破した瞬間：金色リング拡散 + 自分が一瞬膨らむパンチ演出
  void triggerKillFlash() {
    _killFlash = 1.0;
    _killPunch = 1.0;
  }

  /// 被弾（撃破された）瞬間：赤フラッシュ + ノックバックで衝撃を強調
  void triggerHitFlash({Vector2? knockbackDirection}) {
    _hitFlash = 1.0;
    _knockback = 1.0;
    if (knockbackDirection != null && knockbackDirection.length2 > 0) {
      _knockbackDir = knockbackDirection.normalized();
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    final lerpFactor = (dt * 6).clamp(0.0, 1.0);
    _opacity += (_targetOpacity - _opacity) * lerpFactor;
    _scale += (_targetScale - _scale) * lerpFactor;
    _sinkOffset += (_targetSinkOffset - _sinkOffset) * lerpFactor;

    if (_killFlash > 0) {
      _killFlash = (_killFlash - dt * 2.2).clamp(0.0, 1.0);
    }
    if (_killPunch > 0) {
      _killPunch = (_killPunch - dt * 4.5).clamp(0.0, 1.0);
    }
    if (_hitFlash > 0) {
      _hitFlash = (_hitFlash - dt * 5.0).clamp(0.0, 1.0);
    }
    if (_knockback > 0) {
      _knockback = (_knockback - dt * 4.0).clamp(0.0, 1.0);
    }
  }

  @override
  void render(Canvas canvas) {
    // パンチ演出：撃破直後は一瞬だけ大きく膨らんでから収束する
    final punchScale = 1.0 + _killPunch * 0.35;
    final radius = (size.x / 2) * _scale * punchScale;
    // ノックバック：攻撃方向の反対に一瞬弾き飛ばされてから戻る
    final knockbackAmount = _knockback * _knockback * 14;
    final center = Offset(
      size.x / 2 + _knockbackDir.x * knockbackAmount,
      size.y / 2 + _sinkOffset + _knockbackDir.y * knockbackAmount * 0.5,
    );

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3 * _opacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, size.y / 2 + radius * 0.9),
        width: radius * 1.7,
        height: radius * 0.6,
      ),
      shadowPaint,
    );

    // 被弾フラッシュ：本体の下地を赤く光らせて衝撃を伝える
    if (_hitFlash > 0) {
      final hitPaint = Paint()
        ..color = Colors.red.withValues(alpha: _hitFlash * 0.9);
      canvas.drawCircle(center, radius + 6, hitPaint);
    }

    final bodyPaint = Paint()..color = _teamColor.withValues(alpha: _opacity);
    canvas.drawCircle(center, radius, bodyPaint);

    // 外周グロー（存在感を強調）
    final glowPaint = Paint()
      ..color = _teamColor.withValues(alpha: _opacity * 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 3);
    canvas.drawCircle(center, radius, glowPaint);

    if (isSelf) {
      final ringPaint = Paint()
        ..color = Colors.amber.withValues(alpha: _opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawCircle(center, radius + 3, ringPaint);
    }

    // キルフラッシュ：金色の衝撃波を二重リングで拡散
    if (_killFlash > 0) {
      final outerPaint = Paint()
        ..color = Colors.amberAccent.withValues(alpha: _killFlash)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4;
      canvas.drawCircle(center, radius + (1 - _killFlash) * 34, outerPaint);

      final innerPaint = Paint()
        ..color = Colors.white.withValues(alpha: _killFlash * 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(center, radius + (1 - _killFlash) * 18, innerPaint);
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
