// スキル詳細表示ウィジェット

import 'package:flutter/material.dart';
import 'package:shinjuu_league/data/models/skill_catalog.dart';
import 'package:shinjuu_league/services/skill_evolution_service.dart';

/// スキル1個の詳細表示
class SkillDetailCard extends StatelessWidget {
  final String skillName;
  final SkillSlot slot;
  final int currentDamage;
  final double currentCooldown;
  final String? description;
  final bool isAvailable;
  final bool isUpcoming;

  const SkillDetailCard({
    required this.skillName,
    required this.slot,
    required this.currentDamage,
    required this.currentCooldown,
    this.description,
    required this.isAvailable,
    this.isUpcoming = false,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return AnimatedOpacity(
      opacity: isAvailable ? 1.0 : 0.6,
      duration: const Duration(milliseconds: 200),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: isAvailable
                ? (isUpcoming ? Colors.amber : Colors.blue)
                : Colors.grey[500]!,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isDarkMode ? Colors.grey[900] : Colors.grey[50],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // スキル名とスロット表示
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // スロット表示（Q/R/E/ULT）
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getSlotColor(slot),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _getSlotLabel(slot),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        skillName,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isAvailable
                                  ? null
                                  : Colors.grey[600],
                            ),
                      ),
                      if (!isAvailable)
                        Text(
                          isUpcoming ? '次のレベルで解放' : 'まだ使用不可',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                color: isUpcoming
                                    ? Colors.amber[600]
                                    : Colors.grey[600],
                              ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // スキル数値（ダメージ・クールタイム）
            if (isAvailable)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // ダメージ表示
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ダメージ',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$currentDamage',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.red[400],
                              ),
                        ),
                      ],
                    ),
                  ),

                  // クールタイム表示
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'クールタイム',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${currentCooldown.toStringAsFixed(1)}s',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[400],
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

            // 説明文
            if (description != null && description!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                description!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color:
                          isDarkMode ? Colors.grey[300] : Colors.grey[700],
                      height: 1.4,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getSlotColor(SkillSlot slot) {
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

  String _getSlotLabel(SkillSlot slot) {
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
}

/// キャラクターのスキルセット全体表示
class CharacterSkillsPanel extends StatelessWidget {
  final String mechaId;
  final int currentLevel;

  const CharacterSkillsPanel({
    required this.mechaId,
    required this.currentLevel,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final skills =
        SkillEvolutionService.getCharacterSkills(mechaId);

    if (skills == null) {
      return Center(
        child: Text(
          'スキル情報が見つかりません',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'スキル情報',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            // Q スキル
            _buildSkillSection(
              context,
              skill: skills[SkillSlot.q]!,
              currentLevel: currentLevel,
              isDarkMode: isDarkMode,
            ),

            const SizedBox(height: 12),

            // R スキル
            _buildSkillSection(
              context,
              skill: skills[SkillSlot.r]!,
              currentLevel: currentLevel,
              isDarkMode: isDarkMode,
            ),

            const SizedBox(height: 12),

            // E スキル（進化）
            _buildSkillSection(
              context,
              skill: skills[SkillSlot.e]!,
              currentLevel: currentLevel,
              isDarkMode: isDarkMode,
              isEvolution: true,
            ),

            const SizedBox(height: 12),

            // ULT スキル
            _buildSkillSection(
              context,
              skill: skills[SkillSlot.ult]!,
              currentLevel: currentLevel,
              isDarkMode: isDarkMode,
              isUlt: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillSection(
    BuildContext context, {
    required SkillDefinition skill,
    required int currentLevel,
    required bool isDarkMode,
    bool isEvolution = false,
    bool isUlt = false,
  }) {
    final isAvailable =
        SkillEvolutionService.isSkillAvailable(currentLevel, skill.slot);
    final skillData = skill.getAtLevel(currentLevel);
    final nextLevelData = skill.getAtLevel(currentLevel + 1);

    // 最小レベルを見つける
    int minLevel = 1;
    for (int lv = 1; lv <= 8; lv++) {
      if (skill.getAtLevel(lv) != null) {
        minLevel = lv;
        break;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SkillDetailCard(
          skillName: skill.name,
          slot: skill.slot,
          currentDamage: skillData?.damage ?? 0,
          currentCooldown: skillData?.cooldown ?? 0.0,
          description: skill.baseDescription,
          isAvailable: isAvailable || currentLevel >= minLevel,
          isUpcoming: !isAvailable && currentLevel >= minLevel,
        ),

        // 次レベルでの改善を表示
        if (nextLevelData != null && skillData != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Lv${currentLevel + 1}: ダメージ ${nextLevelData.damage} (${((nextLevelData.damage - skillData.damage) / skillData.damage * 100).toStringAsFixed(1)}% UP)',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.amber[600],
                  ),
            ),
          ),
      ],
    );
  }
}
