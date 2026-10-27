import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart' show Colors;

/// ゴールゾーン（Pokémon UNITE風のスコア投入ギミック）の描画。
/// 位置は固定（レーン端・自陣寄り）で、BattleEngine側の状態（teamScores等）は
/// 一切持たない — 既存の「BattlefieldGameは描画専用」という設計原則を踏襲する。
/// `isScorable` が true の間（自キャラが射程内＋エナジー所持中）はリングを
/// 強調表示し、「ここに投入できる」ことを視覚的に伝える。
class GoalZoneToken extends PositionComponent {
  GoalZoneToken({
    required this.team,
    required this.lane,
    required Vector2 basePosition,
    required this.color,
  }) : super(position: basePosition, size: Vector2.all(72), anchor: Anchor.center);

  final int team;
  final int lane;
  final Color color;

  bool isScorable = false;
  double _pulseTime = 0.0;

  @override
  void update(double dt) {
    super.update(dt);
    _pulseTime += dt;
  }

  @override
  void render(Canvas canvas) {
    final center = Offset(size.x / 2, size.y / 2);
    final baseRadius = size.x / 2;
    final pulse = 1.0 + sin(_pulseTime * 2.5) * (isScorable ? 0.12 : 0.04);
    final radius = baseRadius * pulse;

    // 地面に溶け込む淡いグロー
    canvas.drawCircle(
      center,
      radius * 1.15,
      Paint()
        ..color = color.withValues(alpha: isScorable ? 0.35 : 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );

    // 二重リング（「ここがゴール」という視認性を優先、塗りつぶしはしない）
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color.withValues(alpha: isScorable ? 0.95 : 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isScorable ? 5 : 3,
    );
    canvas.drawCircle(
      center,
      radius * 0.6,
      Paint()
        ..color = color.withValues(alpha: isScorable ? 0.7 : 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    if (isScorable) {
      canvas.drawCircle(
        center,
        radius + 6,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }
}
