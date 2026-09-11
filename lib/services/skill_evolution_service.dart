// スキル進化・選択システムを管理するサービス

import 'package:shinjuu_league/data/models/skill_catalog.dart';
import 'package:shinjuu_league/data/models/evolution_state.dart';

/// スキル進化サービス
/// - キャラのスキル進行（Lv→スキル情報）を管理
/// - 進化選択（Lv3/Lv6）の処理をハンドル
class SkillEvolutionService {
  /// キャラの全スキルセットを取得
  static Map<SkillSlot, SkillDefinition>? getCharacterSkills(String mechaId) {
    return SkillCatalog.getCharacterSkills(mechaId);
  }

  /// 特定レベルでのスキル（Q/R/E/ULT）の数値を取得
  static int? getSkillDamageAtLevel(
    String mechaId,
    SkillSlot slot,
    int level,
  ) {
    final skill = SkillCatalog.getSkill(mechaId, slot);
    if (skill == null) return null;
    return skill.getAtLevel(level)?.damage;
  }

  /// 特定レベルでのスキルクールタイムを取得
  static double? getSkillCooldownAtLevel(
    String mechaId,
    SkillSlot slot,
    int level,
  ) {
    final skill = SkillCatalog.getSkill(mechaId, slot);
    if (skill == null) return null;
    return skill.getAtLevel(level)?.cooldown;
  }

  /// 進化型別のステータスボーナスを計算
  /// evolutionType: 選択された進化型（攻撃/防御/支援）
  /// levelIntoEvolution: 進化以降のレベル（Lv3から進化した場合、Lv4での差分はlevelIntoEvolution=1）
  static Map<String, double> calculateEvolutionBonuses({
    required EvolutionType evolutionType,
    required int levelIntoEvolution,
    bool isSecondEvolution = false, // Lv6での進化切り替え
  }) {
    double damageBonus = 0.0;
    double hpBonus = 0.0;
    double allyEffectBonus = 0.0;

    // Lv3進化: 基本ボーナス +60% / +30% HP / +50% 味方効果
    // Lv6進化: 追加ボーナス +40%（維持）or 切り替え（既存をリセット）
    // Lv8最終: さらに強化

    final baseLevel = isSecondEvolution ? 6 : 3;
    final stepsFromBase = levelIntoEvolution;

    switch (evolutionType) {
      case EvolutionType.offensive:
        // Lv3: +60%, Lv6: +100%, Lv8: +150%
        if (isSecondEvolution) {
          // Lv6から再度選択した場合
          damageBonus = 1.0; // 既に+60%から始まっているため、追加+40%分
        } else {
          // Lv3での初期選択
          damageBonus = 0.60;
        }
        // 継続的に強化
        damageBonus += stepsFromBase * 0.15;

      case EvolutionType.defensive:
        // Lv3: +30% HP / +20% mitigation, Lv6: 追加+20%, Lv8: +50% mitigation
        if (isSecondEvolution) {
          hpBonus = 0.50; // Lv6で追加選択
        } else {
          hpBonus = 0.30;
        }
        hpBonus += stepsFromBase * 0.08;

      case EvolutionType.support:
        // Lv3: +50% 味方効果, Lv6: +100%, Lv8: +150%
        if (isSecondEvolution) {
          allyEffectBonus = 1.0;
        } else {
          allyEffectBonus = 0.50;
        }
        allyEffectBonus += stepsFromBase * 0.20;
    }

    return {
      'damage_bonus': damageBonus,
      'hp_bonus': hpBonus,
      'ally_effect_bonus': allyEffectBonus,
    };
  }

  /// Lv3進化選択時のテキスト説明
  static String getEvolutionDescription(EvolutionType type) {
    switch (type) {
      case EvolutionType.offensive:
        return 'ダメージ+60% — Q/Rの火力を徹底的に強化。敵の排除に特化。';
      case EvolutionType.defensive:
        return 'HP+30%, 軽減+20% — 生存能力を極める。タンク的な立ち回り。';
      case EvolutionType.support:
        return '味方効果+50% — 敵デバフ/味方バフを強化。チーム戦特化。';
    }
  }

  /// Lv6進化選択時のテキスト説明
  static String getSecondEvolutionDescription(EvolutionType type) {
    switch (type) {
      case EvolutionType.offensive:
        return '進化維持 — ダメージがさらに+40%増加。火力一筋の道を貫く。';
      case EvolutionType.defensive:
        return '進化切り替え — 防御特化に変更。敵チームの火力に対応。';
      case EvolutionType.support:
        return '進化維持 — 味方効果がさらに+50%増加。サポートを極める。';
    }
  }

  /// 進化選択画面のタイムアウト時の自動選択（デフォルト）
  static EvolutionType getDefaultEvolutionChoice() => EvolutionType.offensive;

  /// Lv6での進化切り替え可能性チェック
  static bool canSwitchEvolutionAtLv6() => true; // 常に切り替え可能

  /// ULTチャージ状態を確認
  static bool isUltCharging(int currentLevel) => currentLevel >= 5;

  /// ULT解放状態を確認
  static bool isUltUnlocked(int currentLevel) => currentLevel >= 7;

  /// スキル有効化の判定（例：Rは Lv2 以上で初めて使用可能）
  static bool isSkillAvailable(int currentLevel, SkillSlot slot) {
    switch (slot) {
      case SkillSlot.q:
        return currentLevel >= 1;
      case SkillSlot.r:
        return currentLevel >= 2;
      case SkillSlot.e:
        return currentLevel >= 3; // 進化選択時のみ
      case SkillSlot.ult:
        return currentLevel >= 7; // Lv7 以上で ULT 使用可能
    }
  }

  /// レベルアップ時の経験値・ゴールドボーナス
  static Map<String, int> getLevelUpRewards({required int newLevel}) {
    return {
      'experience': 20,
      'gold': 50 + (newLevel * 10), // レベルが上がるごとに少しずつ増加
    };
  }

  /// ゲーム内進化タイムライン（進化選択が発生するレベル）
  static const evolutionLevels = {
    3: 'Lv3進化選択①',
    6: 'Lv6進化選択②',
    8: 'Lv8最終進化',
  };

  /// 指定レベルで進化選択が発生するか
  static bool hasEvolutionChoice(int level) =>
      evolutionLevels.containsKey(level);

  /// 次の進化選択が必要なレベルを取得（現在のレベルから）
  static int? getNextEvolutionLevel(int currentLevel) {
    if (currentLevel < 3) return 3;
    if (currentLevel < 6) return 6;
    if (currentLevel < 8) return 8;
    return null; // 全進化完了
  }
}
