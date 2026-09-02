import 'package:shinjuu_league/data/models/resource_model.dart';

/// ゲーム内アイテムマスタカタログ。
/// 実装当初は静的カタログだが、将来Firestore化する際は参照元を差し替えるだけで済む。
class ItemCatalog {
  static final Map<String, ItemDefinition> _itemsById = {
    // === コモン（緑）：基本的なステータスアップ ===
    'item_green_1': ItemDefinition(
      itemId: 'item_green_1',
      name: 'アイアンソード',
      description: '基本的な剣。攻撃力を上げる。',
      cost: 50,
      rarity: ItemRarity.common,
      atkBonus: 8,
    ),
    'item_green_2': ItemDefinition(
      itemId: 'item_green_2',
      name: 'ブロンズシールド',
      description: '青銅盾。防御力を上げる。',
      cost: 50,
      rarity: ItemRarity.common,
      defBonus: 6,
    ),
    'item_green_3': ItemDefinition(
      itemId: 'item_green_3',
      name: 'スピードブーツ',
      description: '素早さの靴。素早さを上げる。',
      cost: 45,
      rarity: ItemRarity.common,
      spdBonus: 12,
    ),
    'item_green_4': ItemDefinition(
      itemId: 'item_green_4',
      name: 'ポーション',
      description: '回復薬。HP最大値を上げる。',
      cost: 40,
      rarity: ItemRarity.common,
      hpBonus: 25,
    ),

    // === アンコモン（青）：複合ステータス ===
    'item_blue_1': ItemDefinition(
      itemId: 'item_blue_1',
      name: 'スチールキャリバー',
      description: '鋼の剣。攻撃力と防御力を上げる。',
      cost: 100,
      rarity: ItemRarity.uncommon,
      atkBonus: 15,
      defBonus: 5,
    ),
    'item_blue_2': ItemDefinition(
      itemId: 'item_blue_2',
      name: '白銀の甲冑',
      description: 'HP と防御力を大きく上げる。',
      cost: 110,
      rarity: ItemRarity.uncommon,
      hpBonus: 40,
      defBonus: 10,
    ),
    'item_blue_3': ItemDefinition(
      itemId: 'item_blue_3',
      name: 'クイックシューズ',
      description: '攻撃力と素早さを上げるブーツ。',
      cost: 105,
      rarity: ItemRarity.uncommon,
      atkBonus: 10,
      spdBonus: 15,
    ),
    'item_blue_4': ItemDefinition(
      itemId: 'item_blue_4',
      name: 'バランスの剣',
      description: 'すべてのステータスを少し上げる。',
      cost: 95,
      rarity: ItemRarity.uncommon,
      hpBonus: 15,
      atkBonus: 8,
      defBonus: 8,
      spdBonus: 5,
    ),

    // === レア（紫）：高火力・高防御 ===
    'item_purple_1': ItemDefinition(
      itemId: 'item_purple_1',
      name: 'エクスカリバー',
      description: '伝説の剣。大幅に攻撃力を上げる。',
      cost: 200,
      rarity: ItemRarity.rare,
      atkBonus: 35,
      hpBonus: 10,
    ),
    'item_purple_2': ItemDefinition(
      itemId: 'item_purple_2',
      name: '竜の鱗甲冑',
      description: '竜の鱗でできた甲冑。防御力が大幅に上がる。',
      cost: 210,
      rarity: ItemRarity.rare,
      defBonus: 25,
      hpBonus: 30,
    ),
    'item_purple_3': ItemDefinition(
      itemId: 'item_purple_3',
      name: 'ライトニングブーツ',
      description: '雷光の靴。素早さが大幅に上がる。',
      cost: 190,
      rarity: ItemRarity.rare,
      spdBonus: 30,
      atkBonus: 10,
    ),

    // === レジェンダリー（金）：最強装備 ===
    'item_gold_1': ItemDefinition(
      itemId: 'item_gold_1',
      name: 'アーティファクト・ブレード',
      description: '神秘的な剣。すべてを圧倒する。',
      cost: 400,
      rarity: ItemRarity.legendary,
      atkBonus: 60,
      defBonus: 20,
      hpBonus: 40,
      spdBonus: 15,
    ),
  };

  /// アイテムIDからアイテム定義を取得
  static ItemDefinition? getItemDefinition(String itemId) {
    return _itemsById[itemId];
  }

  /// すべてのアイテムを取得
  static List<ItemDefinition> getAllItems() {
    return _itemsById.values.toList();
  }

  /// レアリティ別のアイテムを取得
  static List<ItemDefinition> getItemsByRarity(ItemRarity rarity) {
    return _itemsById.values
        .where((item) => item.rarity == rarity)
        .toList();
  }

  /// 推奨価格以下のアイテムを取得
  static List<ItemDefinition> getItemsByMaxCost(int maxCost) {
    return _itemsById.values
        .where((item) => item.cost <= maxCost)
        .toList();
  }

  /// アイテムデータの整合性を検証
  static bool validateItemData() {
    for (final item in _itemsById.values) {
      // ID一致チェック
      if (item.itemId.isEmpty) return false;

      // コスト正の値チェック
      if (item.cost <= 0) return false;

      // 名前と説明が空でないチェック
      if (item.name.isEmpty || item.description.isEmpty) return false;
    }
    return true;
  }
}
