import 'package:flutter/material.dart';
import 'package:shinjuu_league/config/theme.dart';
import 'package:shinjuu_league/data/models/resource_model.dart';
import 'package:shinjuu_league/data/models/skill_model.dart';
import 'package:shinjuu_league/services/skill_system_service.dart';

/// 戦闘中のスキルボタン
/// Q・W・E スキルと アクティブ・クールダウン状態を表示
class SkillButtons extends StatelessWidget {
  final SkillBuild skillBuild;
  final PlayerResources resources;
  final Map<String, double> cooldowns;
  final Function(String skillId, List<String> targets) onSkillTap;

  const SkillButtons({
    required this.skillBuild,
    required this.resources,
    required this.cooldowns,
    required this.onSkillTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'スキル',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF999999),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSkillButton(
                skillId: skillBuild.skillId1,
                level: skillBuild.level1,
                slot: 'Q',
              ),
              _buildSkillButton(
                skillId: skillBuild.skillId2,
                level: skillBuild.level2,
                slot: 'W',
              ),
              _buildSkillButton(
                skillId: skillBuild.skillId3,
                level: skillBuild.level3,
                slot: 'E',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSkillButton({
    required String skillId,
    required int level,
    required String slot,
  }) {
    final skill = SkillSystemService.getSkillDefinition(skillId);
    if (skill == null) return const SizedBox.shrink();

    final manaRequiredLevel = skill.getCostAtLevel(level);
    final cooldownRemaining = (cooldowns[skillId] ?? 0.0).ceil();
    final isAvailable = resources.canAffordMana(manaRequiredLevel) &&
        cooldownRemaining <= 0;
    final isOnCooldown = cooldownRemaining > 0;

    return GestureDetector(
      onTap: isAvailable
          ? () => onSkillTap(skillId, [])
          : null,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ボタン背景
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: isAvailable
                  ? _getSkillTypeColor(skill.type).withValues(alpha: 0.3)
                  : Colors.grey.withValues(alpha: 0.2),
              border: Border.all(
                color: isAvailable
                    ? _getSkillTypeColor(skill.type)
                    : Colors.grey.withValues(alpha: 0.5),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  slot,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isAvailable
                        ? _getSkillTypeColor(skill.type)
                        : Colors.grey.withValues(alpha: 0.5),
                  ),
                ),
                Text(
                  'Lv$level',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isAvailable
                        ? _getSkillTypeColor(skill.type)
                        : Colors.grey.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),

          // クールダウン表示
          if (isOnCooldown)
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '$cooldownRemaining',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

          // マナ不足表示
          if (!isAvailable && cooldownRemaining <= 0)
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '${manaRequiredLevel}G',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

          // マナ・ダメージ情報（背景に小さく表示）
          Positioned(
            bottom: 4,
            right: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                '${manaRequiredLevel}M',
                style: const TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getSkillTypeColor(SkillType type) {
    switch (type) {
      case SkillType.offensive:
        return Colors.red;
      case SkillType.defensive:
        return Colors.blue;
      case SkillType.utility:
        return Colors.green;
    }
  }
}
