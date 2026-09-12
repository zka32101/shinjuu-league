// バトル画面のスキル進行表示ウィジェット

import 'package:flutter/material.dart';
import 'package:shinjuu_league/data/models/evolution_state.dart';
import 'package:shinjuu_league/data/models/skill_catalog.dart';

/// スキルスロット表示（Q/R/E/ULT）
class SkillSlotDisplay extends StatelessWidget {
  final SkillSlot slot;
  final int currentDamage;
  final double cooldownRemaining;
  final double cooldownMax;
  final bool isAvailable;
  final bool isUltCharging;
  final bool isUltUnlocked;
  final VoidCallback? onTap;

  const SkillSlotDisplay({
    required this.slot,
    required this.currentDamage,
    required this.cooldownRemaining,
    required this.cooldownMax,
    required this.isAvailable,
    this.isUltCharging = false,
    this.isUltUnlocked = false,
    this.onTap,
    Key? key,
  }) : super(key: key);

  Color _getSlotColor() {
    switch (slot) {
      case SkillSlot.q:
        return Colors.blue;
      case SkillSlot.r:
        return Colors.green;
      case SkillSlot.e:
        return Colors.purple;
      case SkillSlot.ult:
        return Colors.red;
    }
  }

  String _getSlotLabel() {
    switch (slot) {
      case SkillSlot.q:
        return 'Q';
      case SkillSlot.r:
        return 'R';
      case SkillSlot.e:
        return 'E';
      case SkillSlot.ult:
        return 'ULT';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cooldownPercent = cooldownMax > 0 ? cooldownRemaining / cooldownMax : 0.0;

    return GestureDetector(
      onTap: isAvailable ? onTap : null,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isAvailable ? _getSlotColor() : Colors.grey[600]!,
            width: 2,
          ),
          color: isDarkMode ? Colors.grey[900] : Colors.grey[100],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // クールダウンオーバーレイ
            if (!isAvailable)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: Colors.black.withOpacity(0.3),
                  ),
                  child: Center(
                    child: Text(
                      cooldownRemaining.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              )
            else if (isUltCharging)
              // ULTチャージ中のインジケータ
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: Colors.amber.withOpacity(0.3),
                  ),
                  child: const Center(
                    child: Text(
                      '⚡',
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
                ),
              ),

            // スロットラベル
            Text(
              _getSlotLabel(),
              style: TextStyle(
                color: isAvailable ? _getSlotColor() : Colors.grey[600],
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),

            // ダメージ表示（モーバイル版は省略可能）
            if (isAvailable)
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                  decoration: BoxDecoration(
                    color: _getSlotColor(),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    '$currentDamage',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// キャラクターレベル表示（Lv1-8）
class CharacterLevelDisplay extends StatefulWidget {
  final int currentLevel;
  final bool showAnimation;
  final EvolutionType? currentEvolution;

  const CharacterLevelDisplay({
    required this.currentLevel,
    this.showAnimation = false,
    this.currentEvolution,
    Key? key,
  }) : super(key: key);

  @override
  State<CharacterLevelDisplay> createState() => _CharacterLevelDisplayState();
}

class _CharacterLevelDisplayState extends State<CharacterLevelDisplay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    if (widget.showAnimation) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(CharacterLevelDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentLevel > oldWidget.currentLevel && widget.showAnimation) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _getEvolutionEmoji() {
    switch (widget.currentEvolution) {
      case EvolutionType.offensive:
        return '⚔️';
      case EvolutionType.defensive:
        return '🛡️';
      case EvolutionType.support:
        return '🤝';
      case null:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: FadeTransition(
        opacity: _opacityAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isDarkMode
                ? Colors.grey[800]
                : Colors.blue[50],
            border: Border.all(
              color: Colors.blue,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Lv${widget.currentLevel}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              if (widget.currentEvolution != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _getEvolutionEmoji(),
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.currentEvolution.toString().split('.').last,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ULTステータス表示
class ULTStatusDisplay extends StatelessWidget {
  final bool isAvailable;
  final bool isCharging;

  const ULTStatusDisplay({
    required this.isAvailable,
    required this.isCharging,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (isAvailable) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.red[700],
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.5),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '⚡',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(width: 6),
            Text(
              'ULT Ready',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    if (isCharging) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.amber[600],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '⚡',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(width: 6),
            Text(
              'Charging',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[700] : Colors.grey[400],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '⚡',
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(width: 6),
          Text(
            'Locked',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// 進化ボーナス表示
class EvolutionBonusDisplay extends StatelessWidget {
  final Map<String, double> bonuses;
  final EvolutionType? currentEvolution;

  const EvolutionBonusDisplay({
    required this.bonuses,
    this.currentEvolution,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (currentEvolution == null) {
      return const SizedBox.shrink();
    }

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final dmgBonus = (bonuses['damage_bonus'] ?? 0.0) * 100;
    final hpBonus = (bonuses['hp_bonus'] ?? 0.0) * 100;
    final allyBonus = (bonuses['ally_effect_bonus'] ?? 0.0) * 100;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
        border: Border.all(
          color: Colors.purple[300]!,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '進化ボーナス',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          if (dmgBonus > 0)
            Text(
              'ダメージ +${dmgBonus.toStringAsFixed(0)}%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.red[400],
              ),
            ),
          if (hpBonus > 0)
            Text(
              'HP +${hpBonus.toStringAsFixed(0)}%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.green[400],
              ),
            ),
          if (allyBonus > 0)
            Text(
              '味方効果 +${allyBonus.toStringAsFixed(0)}%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.blue[400],
              ),
            ),
        ],
      ),
    );
  }
}

/// スキルプログレッションパネル（全4スキル + ボーナス表示）
class SkillProgressionPanel extends StatelessWidget {
  final int currentLevel;
  final Map<SkillSlot, double> skillCooldowns;
  final Map<SkillSlot, int> skillDamages;
  final EvolutionType? currentEvolution;
  final Map<String, double> evolutionBonuses;
  final bool isUltAvailable;
  final bool isUltCharging;
  final Function(SkillSlot)? onSkillTap;

  const SkillProgressionPanel({
    required this.currentLevel,
    required this.skillCooldowns,
    required this.skillDamages,
    this.currentEvolution,
    required this.evolutionBonuses,
    required this.isUltAvailable,
    required this.isUltCharging,
    this.onSkillTap,
    Key? key,
  }) : super(key: key);

  double _getSkillCooldownMax(SkillSlot slot) {
    switch (slot) {
      case SkillSlot.q:
        return 4.0;
      case SkillSlot.r:
        return 8.0;
      case SkillSlot.e:
        return 6.0;
      case SkillSlot.ult:
        return 45.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // レベル表示
        CharacterLevelDisplay(
          currentLevel: currentLevel,
          currentEvolution: currentEvolution,
        ),
        const SizedBox(height: 12),

        // スキルスロット表示
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            SkillSlotDisplay(
              slot: SkillSlot.q,
              currentDamage: skillDamages[SkillSlot.q] ?? 0,
              cooldownRemaining: skillCooldowns[SkillSlot.q] ?? 0.0,
              cooldownMax: _getSkillCooldownMax(SkillSlot.q),
              isAvailable: (skillCooldowns[SkillSlot.q] ?? 0.0) <= 0.0,
              onTap: () => onSkillTap?.call(SkillSlot.q),
            ),
            SkillSlotDisplay(
              slot: SkillSlot.r,
              currentDamage: skillDamages[SkillSlot.r] ?? 0,
              cooldownRemaining: skillCooldowns[SkillSlot.r] ?? 0.0,
              cooldownMax: _getSkillCooldownMax(SkillSlot.r),
              isAvailable: (skillCooldowns[SkillSlot.r] ?? 0.0) <= 0.0,
              onTap: () => onSkillTap?.call(SkillSlot.r),
            ),
            SkillSlotDisplay(
              slot: SkillSlot.e,
              currentDamage: skillDamages[SkillSlot.e] ?? 0,
              cooldownRemaining: skillCooldowns[SkillSlot.e] ?? 0.0,
              cooldownMax: _getSkillCooldownMax(SkillSlot.e),
              isAvailable: (skillCooldowns[SkillSlot.e] ?? 0.0) <= 0.0,
              onTap: () => onSkillTap?.call(SkillSlot.e),
            ),
            SkillSlotDisplay(
              slot: SkillSlot.ult,
              currentDamage: skillDamages[SkillSlot.ult] ?? 0,
              cooldownRemaining: skillCooldowns[SkillSlot.ult] ?? 0.0,
              cooldownMax: _getSkillCooldownMax(SkillSlot.ult),
              isAvailable: isUltAvailable,
              isUltCharging: isUltCharging,
              isUltUnlocked: isUltAvailable,
              onTap: () => onSkillTap?.call(SkillSlot.ult),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ULT状態表示
        ULTStatusDisplay(
          isAvailable: isUltAvailable,
          isCharging: isUltCharging,
        ),
        const SizedBox(height: 12),

        // 進化ボーナス表示
        EvolutionBonusDisplay(
          bonuses: evolutionBonuses,
          currentEvolution: currentEvolution,
        ),
      ],
    );
  }
}
