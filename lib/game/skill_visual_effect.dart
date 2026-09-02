import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:shinjuu_league/data/models/skill_model.dart';

/// 拡大するスキル効果リング（既存の SkillBurst を置き換える簡潔版）
class SkillVisualEffect extends Component {
  final SkillType skillType;
  final double radius;
  final double maxRadius;

  SkillVisualEffect({
    required Vector2 position,
    required this.skillType,
    this.radius = 0,
    this.maxRadius = 90,
  }) : super(
    position: position,
    size: Vector2.all(maxRadius * 2.5),
    anchor: Anchor.center,
  );

  late double _startTime;

  @override
  Future<void> onLoad() async {
    _startTime = gameRef.clock.t;
  }

  @override
  void update(double dt) {
    super.update(dt);
    final elapsed = gameRef.clock.t - _startTime;
    if (elapsed > 0.4) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final elapsed = gameRef.clock.t - _startTime;
    final progress = (elapsed / 0.4).clamp(0, 1);

    // スキルタイプ別カラー
    final color = _getColorForSkillType();

    // 外側リング（拡大 + フェードアウト）
    canvas.drawCircle(
      Offset.zero,
      maxRadius * progress,
      Paint()
        ..color = color.withOpacity(0.7 * (1 - progress))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    // 内側リング（遅延して拡大）
    if (progress > 0.2) {
      canvas.drawCircle(
        Offset.zero,
        maxRadius * (progress - 0.2) * 1.25,
        Paint()
          ..color = color.withOpacity(0.5 * (1 - progress))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  Color _getColorForSkillType() {
    switch (skillType) {
      case SkillType.offensive:
        return const Color(0xFFFF6B6B); // 赤：攻撃
      case SkillType.defensive:
        return const Color(0xFF4ECDC4); // 青緑：防御
      case SkillType.utility:
        return const Color(0xFFFFD93D); // 黄：ユーティリティ
    }
  }
}

/// クリティカルヒット用の拡張バースト（既存パーティクルを補強）
class CriticalBurst extends Component {
  final int burstCount;

  CriticalBurst({
    required Vector2 position,
    this.burstCount = 12,
  }) : super(
    position: position,
    anchor: Anchor.center,
  );

  late double _startTime;
  late List<BurstParticle> particles;

  @override
  Future<void> onLoad() async {
    _startTime = gameRef.clock.t;
    final random = math.Random();

    particles = List.generate(burstCount, (i) {
      final angle = (i / burstCount) * 2 * math.pi + random.nextDouble() * 0.3;
      final speed = 80 + random.nextDouble() * 40;
      return BurstParticle(
        startPos: position,
        velocity: Vector2(math.cos(angle) * speed, math.sin(angle) * speed),
        lifetime: 0.5 + random.nextDouble() * 0.1,
        isGolden: true,
      );
    });

    for (final p in particles) {
      add(p);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    final elapsed = gameRef.clock.t - _startTime;
    if (elapsed > 0.6) {
      removeFromParent();
    }
  }
}

/// スキルエリアインジケーター（発動範囲の可視化）
class SkillAreaIndicator extends Component {
  final double radius;
  final SkillType skillType;
  final bool isActive;

  SkillAreaIndicator({
    required Vector2 position,
    required this.radius,
    required this.skillType,
    this.isActive = true,
  }) : super(
    position: position,
    size: Vector2.all(radius * 2),
    anchor: Anchor.center,
  );

  late double _pulseTime;

  @override
  Future<void> onLoad() async {
    _pulseTime = 0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _pulseTime += dt;
    if (_pulseTime > 1.0) {
      _pulseTime -= 1.0;
    }
  }

  @override
  void render(Canvas canvas) {
    if (!isActive) return;

    final color = _getColorForSkillType();
    final opacity = 0.3 + (math.sin(_pulseTime * 2 * math.pi) * 0.1);

    // 破線エリア（パルスしながら表示）
    _drawDashedCircle(
      canvas,
      Offset.zero,
      radius,
      Paint()
        ..color = color.withOpacity(opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // 中央ドット
    canvas.drawCircle(
      Offset.zero,
      3,
      Paint()..color = color.withOpacity(0.6),
    );
  }

  void _drawDashedCircle(Canvas canvas, Offset center, double radius, Paint paint) {
    const dashLength = 8.0;
    const gapLength = 8.0;
    const totalLength = dashLength + gapLength;

    final circumference = 2 * math.pi * radius;
    final dashCount = (circumference / totalLength).ceil();

    for (int i = 0; i < dashCount; i++) {
      final startAngle = (i * totalLength / circumference) * 2 * math.pi;
      final endAngle = ((i * totalLength + dashLength) / circumference) * 2 * math.pi;

      final startX = center.dx + radius * math.cos(startAngle);
      final startY = center.dy + radius * math.sin(startAngle);
      final endX = center.dx + radius * math.cos(endAngle);
      final endY = center.dy + radius * math.sin(endAngle);

      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);
    }
  }

  Color _getColorForSkillType() {
    switch (skillType) {
      case SkillType.offensive:
        return const Color(0xFFFF6B6B);
      case SkillType.defensive:
        return const Color(0xFF4ECDC4);
      case SkillType.utility:
        return const Color(0xFFFFD93D);
    }
  }
}

/// バースト粒子（再利用可能な基本パーティクル）
class BurstParticle extends Component {
  final Vector2 velocity;
  final double lifetime;
  final bool isGolden;
  final Vector2 startPos;

  late double _birthTime;

  BurstParticle({
    required this.startPos,
    required this.velocity,
    required this.lifetime,
    required this.isGolden,
  }) : super(
    position: startPos,
    size: Vector2.all(8),
    anchor: Anchor.center,
  );

  @override
  Future<void> onLoad() async {
    _birthTime = gameRef.clock.t;
  }

  @override
  void update(double dt) {
    super.update(dt);
    position += velocity * dt;

    final age = gameRef.clock.t - _birthTime;
    if (age > lifetime) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final age = gameRef.clock.t - _birthTime;
    final progress = (age / lifetime).clamp(0, 1);
    final opacity = 1.0 - progress;

    final color = isGolden
        ? Color(0xFFFFD700).withOpacity(opacity * 0.8)
        : Color(0xFFFFAA00).withOpacity(opacity * 0.6);

    canvas.drawCircle(
      Offset.zero,
      4 * (1 - progress * 0.5),
      Paint()..color = color,
    );
  }
}
