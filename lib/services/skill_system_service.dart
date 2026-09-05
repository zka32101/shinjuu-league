import 'package:shinjuu_league/data/models/skill_model.dart';
import 'package:shinjuu_league/data/models/item_model.dart';
import 'package:shinjuu_league/data/models/resource_model.dart';
import 'package:shinjuu_league/data/models/mecha_model.dart';

/// スキル・マナ・アイテムシステムの統合管理サービス
class SkillSystemService {
  /// 神獣別の利用可能スキル定義
  static final Map<String, List<SkillDefinition>> _mechaSkills = {
    'mecha_east_01': [
      SkillDefinition(
        skillId: 'skill_east_01_q',
        name: '焔撃',
        mechaId: 'mecha_east_01',
        type: SkillType.offensive,
        description: '敵単体に炎を発射。ダメージを与える',
        baseCost: 40,
        baseDamageMultiplier: 1.5,
        cooldownSeconds: 4.0,
      ),
      SkillDefinition(
        skillId: 'skill_east_01_w',
        name: '炎の壁',
        mechaId: 'mecha_east_01',
        type: SkillType.defensive,
        description: '自分の周囲に炎の壁を展開。防御力UP',
        baseCost: 50,
        baseDamageMultiplier: 1.0,
        cooldownSeconds: 6.0,
      ),
      SkillDefinition(
        skillId: 'skill_east_01_e',
        name: '熱波拡散',
        mechaId: 'mecha_east_01',
        type: SkillType.utility,
        description: '周囲の敵全員にダメージ。範囲攻撃',
        baseCost: 60,
        baseDamageMultiplier: 2.0,
        cooldownSeconds: 8.0,
      ),
    ],
    'mecha_west_01': [
      SkillDefinition(
        skillId: 'skill_west_01_q',
        name: 'フロストボルト',
        mechaId: 'mecha_west_01',
        type: SkillType.offensive,
        description: '敵を凍らせる。移動速度低下効果',
        baseCost: 40,
        baseDamageMultiplier: 1.3,
        cooldownSeconds: 4.5,
      ),
      SkillDefinition(
        skillId: 'skill_west_01_w',
        name: '氷盾',
        mechaId: 'mecha_west_01',
        type: SkillType.defensive,
        description: '防御UPと一時的なシールド',
        baseCost: 45,
        baseDamageMultiplier: 1.0,
        cooldownSeconds: 6.0,
      ),
      SkillDefinition(
        skillId: 'skill_west_01_e',
        name: '極寒地帯',
        mechaId: 'mecha_west_01',
        type: SkillType.utility,
        description: '範囲内の敵の攻撃力低下',
        baseCost: 70,
        baseDamageMultiplier: 0.8,
        cooldownSeconds: 9.0,
      ),
    ],
  };

  /// アイテムカタログ
  static final List<ItemDefinition> _items = [
    ItemDefinition(
      itemId: 'item_sword_01',
      name: '鋭い剣',
      description: '攻撃力UP +10',
      cost: 300,
      rarity: ItemRarity.common,
      atkBonus: 10,
    ),
    ItemDefinition(
      itemId: 'item_armor_01',
      name: '強化装甲',
      description: '防御力UP +15',
      cost: 350,
      rarity: ItemRarity.common,
      defBonus: 15,
    ),
    ItemDefinition(
      itemId: 'item_ring_01',
      name: '速度の指輪',
      description: '素早さUP +8',
      cost: 280,
      rarity: ItemRarity.uncommon,
      spdBonus: 8,
    ),
    ItemDefinition(
      itemId: 'item_hp_01',
      name: '生命の宝珠',
      description: 'HP UP +50',
      cost: 400,
      rarity: ItemRarity.uncommon,
      hpBonus: 50,
    ),
    ItemDefinition(
      itemId: 'item_legendary_01',
      name: '伝説の秘宝',
      description: '全ステータスUP',
      cost: 800,
      rarity: ItemRarity.legendary,
      atkBonus: 25,
      defBonus: 20,
      hpBonus: 100,
      spdBonus: 10,
    ),
  ];

  /// 神獣のスキル一覧を取得
  static List<SkillDefinition> getSkillsForMecha(String mechaId) {
    return _mechaSkills[mechaId] ?? [];
  }

  /// スキルIDからスキル定義を取得
  static SkillDefinition? getSkillDefinition(String skillId) {
    for (final skills in _mechaSkills.values) {
      for (final skill in skills) {
        if (skill.skillId == skillId) {
          return skill;
        }
      }
    }
    return null;
  }

  /// 全アイテムを取得
  static List<ItemDefinition> getAllItems() => _items;

  /// アイテムIDからアイテム定義を取得
  static ItemDefinition? getItemDefinition(String itemId) {
    return ItemCatalog.getItemDefinition(itemId);
  }

  /// ビルドの有効性を検証
  static bool isValidBuild(SkillBuild build, String mechaId) {
    final skills = getSkillsForMecha(mechaId);
    final skillIds = skills.map((s) => s.skillId).toSet();
    return skillIds.contains(build.skillId1) &&
        skillIds.contains(build.skillId2) &&
        skillIds.contains(build.skillId3);
  }

  /// マナ自然リジェン（秒単位）
  static const int manaRegenPerSecond = 3;

  /// 初期マナ・最大マナ
  static const int initialMana = 100;
  static const int maxManaStandard = 100;

  /// マナの最大値を計算（アイテムボーナスなどで増加可能）
  static int calculateMaxMana({
    required int baseMax,
    required List<String> ownedItemIds,
  }) {
    int max = baseMax;
    for (final _ in ownedItemIds) {
      // 今後：アイテムがマナ最大値を増やす場合はここで追加
    }
    return max;
  }

  /// ステータスボーナスを計算（購入済みアイテムから）
  /// 新しいItemモデルは percentage-based なので、baseStatsを渡して計算
  static BaseStats calculateItemBonuses({
    required List<String> ownedItemIds,
    BaseStats? baseStats,
  }) {
    // デフォルトベース（アイテムのみから計算する場合）
    baseStats ??= BaseStats(hp: 100, atk: 50, spd: 50);

    double totalHpPercent = 0.0;
    double totalAtkPercent = 0.0;
    double totalSpdPercent = 0.0;

    for (final itemId in ownedItemIds) {
      final item = ItemCatalog.itemById(itemId);
      if (item != null && item.bonus != null) {
        if (item.bonus!.hpBonus != null) {
          totalHpPercent += item.bonus!.hpBonus!;
        }
        if (item.bonus!.attackBonus != null) {
          totalAtkPercent += item.bonus!.attackBonus!;
        }
        if (item.bonus!.defenseBonus != null) {
          // defenseBonus は def の別スキルだが、一旦 hpBonus と同じ扱いで
          totalHpPercent += item.bonus!.defenseBonus! / 2;
        }
      }
    }

    // percentage から absolute 値に変換
    final hpBonus = (baseStats.hp * (totalHpPercent / 100.0)).toInt();
    final atkBonus = (baseStats.atk * (totalAtkPercent / 100.0)).toInt();
    final spdBonus = (baseStats.spd * (totalSpdPercent / 100.0)).toInt();

    return BaseStats(
      hp: hpBonus,
      atk: atkBonus,
      spd: spdBonus,
    );
  }
}
