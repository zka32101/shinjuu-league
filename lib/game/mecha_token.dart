import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart'
    show Colors, IconData, TextPainter, TextSpan, TextStyle, TextDirection;

/// バトルフィールド上の1参加者を表すトークン。実キャラクター素材が無いため、
/// 球体シェーディング（放射状グラデ）+ 属性アイコン + 接地影 + 浮遊ボブで
/// 「宙に浮いた立体的な駒」としての2.5D感を表現するプレースホルダー。
class MechaToken extends PositionComponent {
  MechaToken({
    required this.userId,
    required this.team,
    required this.lane,
    required this.isSelf,
    required this.icon,
    required Vector2 basePosition,
  }) : spawnPosition = basePosition.clone(),
       _bobPhase = (basePosition.x + basePosition.y) % (pi * 2),
       super(
         position: basePosition,
         size: Vector2.all(46),
         anchor: Anchor.center,
       );

  final String userId;
  final int team;
  final int lane;
  final bool isSelf;
  final IconData icon;

  /// 出撃時の位置。リスポーン時にここへ戻す（死亡地点にとどまらないようにする）。
  final Vector2 spawnPosition;

  bool isAlive = true;
  double _opacity = 1.0;
  double _targetOpacity = 1.0;
  double _scale = 1.0;
  double _targetScale = 1.0;
  double _sinkOffset = 0.0;
  double _targetSinkOffset = 0.0;

  final double _bobPhase; // 個体ごとに浮遊の位相をずらして群れ感を出す
  double _bobTime = 0.0;

  double _killFlash = 0.0; // 撃破した瞬間の金色リング拡散
  double _killPunch = 0.0; // 撃破した瞬間の自己スケールパンチ
  double _hitFlash = 0.0; // 被弾した瞬間の赤フラッシュ
  double _knockback = 0.0; // 被弾した瞬間のノックバック量（0..1で減衰）
  Vector2 _knockbackDir = Vector2.zero();

  double _hpRatio = 1.0; // 0..1、HPバー表示用（滑らかに追従）
  double _targetHpRatio = 1.0;

  /// currentHp/maxHp を受け取ってHPバーを更新する。
  void updateHp(double currentHp, double maxHp) {
    if (maxHp <= 0) return;
    _targetHpRatio = (currentHp / maxHp).clamp(0.0, 1.0);
  }

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
    _bobTime += dt;
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
    _hpRatio += (_targetHpRatio - _hpRatio) * lerpFactor;
  }

  @override
  void render(Canvas canvas) {
    // パンチ演出：撃破直後は一瞬だけ大きく膨らんでから収束する
    final punchScale = 1.0 + _killPunch * 0.35;
    final radius = (size.x / 2) * _scale * punchScale;

    // 浮遊ボブ：生存中は上下にゆっくり揺れて「宙に浮いている」立体感を出す
    final bob = isAlive ? sin(_bobTime * 2.2 + _bobPhase) * 3.0 : 0.0;

    // ノックバック：攻撃方向の反対に一瞬弾き飛ばされてから戻る
    final knockbackAmount = _knockback * _knockback * 14;
    // 接地点（影の中心）— これは浮遊しない。本体だけが bob 分だけ上に浮く。
    final groundY = size.y / 2 + _sinkOffset;
    final center = Offset(
      size.x / 2 + _knockbackDir.x * knockbackAmount,
      groundY - bob + _knockbackDir.y * knockbackAmount * 0.5,
    );

    // 接地影：本体が高く浮くほど薄く・大きくして高さを感じさせる
    final heightFactor = (bob + 3) / 6; // 0..1
    final shadowAlpha = (0.35 - heightFactor * 0.15) * _opacity;
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(shadowAlpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, groundY + radius * 0.95),
        width: radius * (1.5 + heightFactor * 0.4),
        height: radius * 0.55,
      ),
      shadowPaint,
    );

    // 被弾フラッシュ：本体の下地を赤く光らせて衝撃を伝える
    if (_hitFlash > 0) {
      final hitPaint = Paint()
        ..color = Colors.red.withOpacity(_hitFlash * 0.9)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(center, radius + 6, hitPaint);
    }

    // 球体シェーディング：左上を光源とした放射状グラデで立体的な玉に見せる
    final lightColor = Color.lerp(_teamColor, Colors.white, 0.55)!;
    final darkColor = Color.lerp(_teamColor, Colors.black, 0.45)!;
    final bodyPaint = Paint()
      ..shader = Gradient.radial(
        Offset(center.dx - radius * 0.35, center.dy - radius * 0.35),
        radius * 1.3,
        [
          lightColor.withOpacity(_opacity),
          _teamColor.withOpacity(_opacity),
          darkColor.withOpacity(_opacity),
        ],
        [0.0, 0.5, 1.0],
      );
    canvas.drawCircle(center, radius, bodyPaint);

    // リムライト：右下側の縁を暗く締めて球の丸みを強調
    final rimPaint = Paint()
      ..color = darkColor.withOpacity(_opacity * 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 1),
      0.3,
      pi * 0.9,
      false,
      rimPaint,
    );

    // ハイライトスポット：光沢のある玉の質感
    final specPaint = Paint()
      ..color = Colors.white.withOpacity(_opacity * 0.7)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawCircle(
      Offset(center.dx - radius * 0.32, center.dy - radius * 0.32),
      radius * 0.22,
      specPaint,
    );

    // 外周グロー（存在感を強調）
    final glowPaint = Paint()
      ..color = _teamColor.withOpacity(_opacity * 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 3);
    canvas.drawCircle(center, radius, glowPaint);

    if (isSelf) {
      final ringPaint = Paint()
        ..color = Colors.amber.withOpacity(_opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawCircle(center, radius + 3, ringPaint);
    }

    // キルフラッシュ：金色の衝撃波を二重リングで拡散
    if (_killFlash > 0) {
      final outerPaint = Paint()
        ..color = Colors.amberAccent.withOpacity(_killFlash)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4;
      canvas.drawCircle(center, radius + (1 - _killFlash) * 34, outerPaint);

      final innerPaint = Paint()
        ..color = Colors.white.withOpacity(_killFlash * 0.8)
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
          color: Colors.white.withOpacity(_opacity),
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

    // HPバー：頭上に表示。生存中のみ、削れ具合に応じて緑→黄→赤に変化させる
    if (isAlive) {
      const barWidth = 34.0;
      const barHeight = 4.0;
      final barTop = center.dy - radius - 12;
      final barRect = Rect.fromLTWH(
        center.dx - barWidth / 2,
        barTop,
        barWidth,
        barHeight,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(barRect, const Radius.circular(2)),
        Paint()..color = Colors.black.withOpacity(0.5 * _opacity),
      );

      final hpColor = _hpRatio > 0.5
          ? Colors.greenAccent
          : (_hpRatio > 0.2 ? Colors.amber : Colors.redAccent);
      final filledRect = Rect.fromLTWH(
        barRect.left,
        barRect.top,
        barWidth * _hpRatio,
        barHeight,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(filledRect, const Radius.circular(2)),
        Paint()..color = hpColor.withOpacity(_opacity),
      );
    }
  }
}
