import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// バフ/デバフの種類
enum BuffType {
  atkBoost,    // 攻撃力UP
  defBoost,    // 防御力UP
  spdBoost,    // 素早さUP
  atkDebuff,   // 攻撃力DOWN
  defDebuff,   // 防御力DOWN
  spdDebuff,   // 素早さDOWN
  healing,     // 回復
}

/// トークン上に浮く複数のバフ/デバフインジケーター
class BuffIndicator extends PositionComponent {
  final BuffType buffType;
  final double duration;
  final Vector2 tokenPosition;

  late double _startTime;

  BuffIndicator({
    required this.buffType,
    required this.duration,
    required this.tokenPosition,
  }) : super(position: tokenPosition, anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _startTime = game.clock.t;
  }

  @override
  void update(double dt) {
    super.update(dt);
    final elapsed = game.clock.t - _startTime;

    // 上昇アニメーション（time-wise）
    position = Vector2(
      tokenPosition.x + math.sin(elapsed * 3) * 4, // 左右微動
      tokenPosition.y - 30 - (elapsed * 20), // 上昇
    );

    if (elapsed > duration) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final elapsed = game.clock.t - _startTime;
    final progress = (elapsed / duration).clamp(0, 1);
    final opacity = 1.0 - progress;

    // アイコン背景（半透明円）
    canvas.drawCircle(
      Offset.zero,
      12,
      Paint()
        ..color = _getBackgroundColor().withValues(alpha: opacity * 0.7)
        ..style = PaintingStyle.fill,
    );

    // 外枠（輝き）
    canvas.drawCircle(
      Offset.zero,
      12,
      Paint()
        ..color = _getMainColor().withValues(alpha: opacity * 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // アイコン描画
    _drawBuffIcon(canvas, opacity);
  }

  void _drawBuffIcon(Canvas canvas, double opacity) {
    final paint = Paint()
      ..color = _getMainColor().withValues(alpha: opacity)
      ..style = PaintingStyle.fill;

    switch (buffType) {
      case BuffType.atkBoost:
        // 上向き矢印（攻撃UP）
        canvas.drawPath(
          _createArrowPath(true),
          paint,
        );
        break;
      case BuffType.defBoost:
        // シールド形状（防御UP）
        canvas.drawPath(
          _createShieldPath(),
          paint,
        );
        break;
      case BuffType.spdBoost:
        // 稲妻形状（素早さUP）
        canvas.drawPath(
          _createLightningPath(),
          paint,
        );
        break;
      case BuffType.atkDebuff:
        // 下向き矢印（攻撃DOWN）
        canvas.drawPath(
          _createArrowPath(false),
          paint,
        );
        break;
      case BuffType.defDebuff:
        // ひび割れシールド（防御DOWN）
        canvas.drawPath(
          _createBrokenShieldPath(),
          paint,
        );
        break;
      case BuffType.spdDebuff:
        // 遅い稲妻（素早さDOWN）
        canvas.drawPath(
          _createSlowLightningPath(),
          paint,
        );
        break;
      case BuffType.healing:
        // プラス記号（回復）
        canvas.drawPath(
          _createCrossPath(),
          paint,
        );
        break;
    }
  }

  Path _createArrowPath(bool up) {
    final path = Path();

    if (up) {
      // 上向き矢印
      path.moveTo(0, -8);
      path.lineTo(-4, 0);
      path.lineTo(-1, 0);
      path.lineTo(-1, 6);
      path.lineTo(1, 6);
      path.lineTo(1, 0);
      path.lineTo(4, 0);
      path.close();
    } else {
      // 下向き矢印
      path.moveTo(0, 8);
      path.lineTo(-4, 0);
      path.lineTo(-1, 0);
      path.lineTo(-1, -6);
      path.lineTo(1, -6);
      path.lineTo(1, 0);
      path.lineTo(4, 0);
      path.close();
    }

    return path;
  }

  Path _createShieldPath() {
    final path = Path();
    path.moveTo(-6, -4);
    path.lineTo(6, -4);
    path.lineTo(6, 0);
    path.quadraticBezierTo(0, 8, -6, 0);
    path.close();
    return path;
  }

  Path _createBrokenShieldPath() {
    final path = Path();
    path.moveTo(-6, -4);
    path.lineTo(6, -4);
    path.lineTo(6, 0);
    path.quadraticBezierTo(0, 8, -6, 0);
    path.close();

    // ひび割れ線を追加
    path.moveTo(-2, -1);
    path.lineTo(2, 4);
    path.moveTo(2, -1);
    path.lineTo(-2, 4);
    return path;
  }

  Path _createLightningPath() {
    final path = Path();
    path.moveTo(0, -8);
    path.lineTo(3, -1);
    path.lineTo(1, -1);
    path.lineTo(3, 8);
    path.lineTo(-3, 1);
    path.lineTo(1, 1);
    path.lineTo(-3, -8);
    path.close();
    return path;
  }

  Path _createSlowLightningPath() {
    final path = Path();
    path.moveTo(0, -6);
    path.lineTo(2, 0);
    path.lineTo(0, 0);
    path.lineTo(2, 6);
    path.lineTo(-2, 2);
    path.lineTo(0, 2);
    path.lineTo(-2, -6);
    path.close();
    return path;
  }

  Path _createCrossPath() {
    final path = Path();
    // 横線
    path.moveTo(-4, -1);
    path.lineTo(4, -1);
    path.lineTo(4, 1);
    path.lineTo(-4, 1);
    path.close();
    // 縦線
    path.moveTo(-1, -4);
    path.lineTo(1, -4);
    path.lineTo(1, 4);
    path.lineTo(-1, 4);
    path.close();
    return path;
  }

  Color _getMainColor() {
    switch (buffType) {
      case BuffType.atkBoost:
      case BuffType.atkDebuff:
        return const Color(0xFFFF6B6B); // 赤：攻撃系
      case BuffType.defBoost:
      case BuffType.defDebuff:
        return const Color(0xFF4ECDC4); // 青：防御系
      case BuffType.spdBoost:
      case BuffType.spdDebuff:
        return const Color(0xFFFFD93D); // 黄：素早さ系
      case BuffType.healing:
        return const Color(0xFF90EE90); // 緑：回復
      default:
        return const Color(0xFFFFFFFF); // 白：デフォルト
    }
  }

  Color _getBackgroundColor() {
    return _getMainColor().withValues(alpha: 0.3);
  }
}
