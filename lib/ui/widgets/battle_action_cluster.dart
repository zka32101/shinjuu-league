import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shinjuu_league/data/models/skill_model.dart';
import 'package:shinjuu_league/game/battlefield_game.dart';

/// Pokémon UNITE風の操作クラスタ：通常攻撃(大)+スキル(小)を1つの半透明グロー
/// パネルにまとめ、押下時のスケール演出・クールダウンリングで手触りを強化する。
///
/// 実際にプレイヤーが手動発動できるスキルは1系統のみ（[BattleEngine.manualSkill]）
/// のため、Q/W/E 3ボタンで別々の操作があるように見せていた旧UIを廃し、
/// 実挙動と一致する単一のスキルボタンに統一した。
class BattleActionCluster extends StatelessWidget {
  const BattleActionCluster({
    super.key,
    required this.attackTarget,
    required this.onAttackTap,
    required this.skillType,
    required this.skillCooldownRemaining,
    required this.skillCooldownMax,
    required this.onSkillTap,
  });

  final AttackTarget? attackTarget;
  final VoidCallback onAttackTap;

  /// null の場合はスキルビルド未選択（発動不可）を表す。
  final SkillType? skillType;
  final double skillCooldownRemaining;
  final double skillCooldownMax;
  final VoidCallback onSkillTap;

  Color _skillColor() {
    switch (skillType) {
      case SkillType.offensive:
        return const Color(0xFFFF6B6B);
      case SkillType.defensive:
        return const Color(0xFF4ECDC4);
      case SkillType.utility:
        return const Color(0xFFFFD93D);
      case null:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final canAttack = attackTarget != null;
    final attackColor = attackTarget?.isMonster == true
        ? const Color(0xFF4ADE80)
        : Colors.redAccent;
    final skillOnCooldown = skillCooldownRemaining > 0;
    final skillReady = skillType != null && !skillOnCooldown;

    return SizedBox(
      width: 150,
      height: 150,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          // クラスタ全体を柔らかく浮かび上がらせる背景グロー（硬い矩形パネルにしない）
          Positioned(
            right: -10,
            bottom: -10,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.35),
                    Colors.black.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          // スキルボタン：攻撃ボタンの左上に配置（UNITEのサブボタン配置を踏襲）
          Positioned(
            left: 0,
            top: 6,
            child: _ActionButton(
              size: 58,
              color: skillReady ? _skillColor() : Colors.grey,
              glowColor: skillReady ? _skillColor() : null,
              onTap: skillReady ? onSkillTap : null,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.auto_awesome,
                    color: Colors.white.withValues(alpha: skillReady ? 1.0 : 0.5),
                    size: 26,
                  ),
                  if (skillOnCooldown)
                    CustomPaint(
                      size: const Size(58, 58),
                      painter: _CooldownRingPainter(
                        progress: (skillCooldownRemaining / skillCooldownMax).clamp(
                          0.0,
                          1.0,
                        ),
                      ),
                    ),
                  if (skillOnCooldown)
                    Text(
                      skillCooldownRemaining.ceil().toString(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                      ),
                    ),
                ],
              ),
            ),
          ),
          // 攻撃ボタン：クラスタの主役として大きく配置
          Positioned(
            right: 0,
            bottom: 0,
            child: _ActionButton(
              size: 76,
              color: canAttack ? attackColor : Colors.grey.withValues(alpha: 0.4),
              glowColor: canAttack ? attackColor : null,
              onTap: canAttack ? onAttackTap : null,
              child: Icon(
                attackTarget?.isMonster == true ? Icons.bug_report : Icons.flash_on,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 押下時に沈み込むスケール演出付きの円形ボタン。
class _ActionButton extends StatefulWidget {
  const _ActionButton({
    required this.size,
    required this.color,
    required this.child,
    this.glowColor,
    this.onTap,
  });

  final double size;
  final Color color;
  final Color? glowColor;
  final Widget child;
  final VoidCallback? onTap;

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.onTap == null) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.88 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color,
            boxShadow: widget.glowColor != null
                ? [
                    BoxShadow(
                      color: widget.glowColor!.withValues(alpha: 0.6),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Center(child: widget.child),
        ),
      ),
    );
  }
}

/// クールダウン中の残り割合を円弧で示す（残りが減るほど弧が短くなる）。
class _CooldownRingPainter extends CustomPainter {
  _CooldownRingPainter({required this.progress});

  /// 0.0（発動可能）〜1.0（発動直後）
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;

    final trackPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(center, radius, trackPaint);

    final sweepPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      sweepPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CooldownRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
