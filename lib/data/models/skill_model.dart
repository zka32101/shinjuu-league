// スキルシステム
// 各神獣は3スキルを持ち、各スキルは3段階でレベルアップ可能

enum SkillType {
  offensive,  // 攻撃スキル
  defensive,  // 防御スキル
  utility;    // ユーティリティ

  String get displayName {
    switch (this) {
      case SkillType.offensive:
        return '攻撃';
      case SkillType.defensive:
        return '防御';
      case SkillType.utility:
        return '補助';
    }
  }
}

class SkillDefinition {
  final String skillId;
  final String name;
  final String mechaId;
  final SkillType type;
  final String description;
  final int baseCost; // マナコスト（基本値）
  final double baseDamageMultiplier; // ダメージ倍率（基本値）
  final double cooldownSeconds;

  SkillDefinition({
    required this.skillId,
    required this.name,
    required this.mechaId,
    required this.type,
    required this.description,
    required this.baseCost,
    required this.baseDamageMultiplier,
    required this.cooldownSeconds,
  });

  /// レベルに応じたコスト計算
  int getCostAtLevel(int level) {
    // レベルが上がるとコストも増える（最大レベル3）
    return (baseCost * (1.0 + (level - 1) * 0.25)).round();
  }

  /// レベルに応じたダメージ倍率
  double getDamageMultiplierAtLevel(int level) {
    // レベルが上がるとダメージも増える
    return baseDamageMultiplier * (1.0 + (level - 1) * 0.3);
  }

  /// レベルに応じたクールダウン短縮
  double getCooldownAtLevel(int level) {
    // レベルが上がるとクールダウンが短くなる
    return cooldownSeconds / (1.0 + (level - 1) * 0.2);
  }
}

/// プレイヤーが選択したスキルビルド
class SkillBuild {
  final String skillId1; // メインスキル
  final String skillId2; // サブスキル
  final String skillId3; // ユーティリティスキル
  final int level1;
  final int level2;
  final int level3;

  SkillBuild({
    required this.skillId1,
    required this.skillId2,
    required this.skillId3,
    this.level1 = 1,
    this.level2 = 1,
    this.level3 = 1,
  });

  /// スキルレベルアップ（試合中に段階的に強化される）
  SkillBuild upgradeSkill(int skillIndex) {
    assert(skillIndex >= 1 && skillIndex <= 3);
    if (skillIndex == 1) {
      return SkillBuild(
        skillId1: skillId1,
        skillId2: skillId2,
        skillId3: skillId3,
        level1: (level1 + 1).clamp(1, 3),
        level2: level2,
        level3: level3,
      );
    } else if (skillIndex == 2) {
      return SkillBuild(
        skillId1: skillId1,
        skillId2: skillId2,
        skillId3: skillId3,
        level1: level1,
        level2: (level2 + 1).clamp(1, 3),
        level3: level3,
      );
    } else {
      return SkillBuild(
        skillId1: skillId1,
        skillId2: skillId2,
        skillId3: skillId3,
        level1: level1,
        level2: level2,
        level3: (level3 + 1).clamp(1, 3),
      );
    }
  }

  factory SkillBuild.fromJson(Map<String, dynamic> json) {
    return SkillBuild(
      skillId1: json['skillId1'] as String,
      skillId2: json['skillId2'] as String,
      skillId3: json['skillId3'] as String,
      level1: json['level1'] as int? ?? 1,
      level2: json['level2'] as int? ?? 1,
      level3: json['level3'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
    'skillId1': skillId1,
    'skillId2': skillId2,
    'skillId3': skillId3,
    'level1': level1,
    'level2': level2,
    'level3': level3,
  };
}
