import 'package:json_annotation/json_annotation.dart';

part 'item_model.g.dart';

/// アイテム定義（武器・防具・護符）
/// レアリティ: COMMON → RARE → EPIC → LEGEND
enum ItemRarity {
  common,
  rare,
  epic,
  legend,
}

/// アイテムタイプ（攻撃・防御・体力）
enum ItemType {
  weapon, // 攻撃力ボーナス
  armor,  // 防御力ボーナス
  charm,  // 体力ボーナス
}

/// アイテムスタッツボーナス
@JsonSerializable()
class ItemBonus {
  final double? attackBonus; // 攻撃力ボーナス（%）
  final double? defenseBonus; // 防御力ボーナス（%）
  final double? hpBonus; // 体力ボーナス（%）

  ItemBonus({
    this.attackBonus,
    this.defenseBonus,
    this.hpBonus,
  });

  factory ItemBonus.fromJson(Map<String, dynamic> json) =>
      _$ItemBonusFromJson(json);
  Map<String, dynamic> toJson() => _$ItemBonusToJson(this);

  ItemBonus copyWith({
    double? attackBonus,
    double? defenseBonus,
    double? hpBonus,
  }) {
    return ItemBonus(
      attackBonus: attackBonus ?? this.attackBonus,
      defenseBonus: defenseBonus ?? this.defenseBonus,
      hpBonus: hpBonus ?? this.hpBonus,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ItemBonus &&
          runtimeType == other.runtimeType &&
          attackBonus == other.attackBonus &&
          defenseBonus == other.defenseBonus &&
          hpBonus == other.hpBonus;

  @override
  int get hashCode => attackBonus.hashCode ^ defenseBonus.hashCode ^ hpBonus.hashCode;
}

/// プレイヤーが所有するアイテム
@JsonSerializable()
class Item {
  final String itemId;
  final String name;
  final String description;
  final ItemType type;
  final ItemRarity rarity;
  final ItemBonus bonus;
  final int purchasePrice; // ゴールド
  final DateTime acquiredAt;
  final bool isEquipped;

  Item({
    required this.itemId,
    required this.name,
    required this.description,
    required this.type,
    required this.rarity,
    required this.bonus,
    required this.purchasePrice,
    required this.acquiredAt,
    this.isEquipped = false,
  });

  factory Item.fromJson(Map<String, dynamic> json) => _$ItemFromJson(json);
  Map<String, dynamic> toJson() => _$ItemToJson(this);

  Item copyWith({
    String? itemId,
    String? name,
    String? description,
    ItemType? type,
    ItemRarity? rarity,
    ItemBonus? bonus,
    int? purchasePrice,
    DateTime? acquiredAt,
    bool? isEquipped,
  }) {
    return Item(
      itemId: itemId ?? this.itemId,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      rarity: rarity ?? this.rarity,
      bonus: bonus ?? this.bonus,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      acquiredAt: acquiredAt ?? this.acquiredAt,
      isEquipped: isEquipped ?? this.isEquipped,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Item &&
          runtimeType == other.runtimeType &&
          itemId == other.itemId &&
          name == other.name &&
          description == other.description &&
          type == other.type &&
          rarity == other.rarity &&
          bonus == other.bonus &&
          purchasePrice == other.purchasePrice &&
          acquiredAt == other.acquiredAt &&
          isEquipped == other.isEquipped;

  @override
  int get hashCode =>
      itemId.hashCode ^
      name.hashCode ^
      description.hashCode ^
      type.hashCode ^
      rarity.hashCode ^
      bonus.hashCode ^
      purchasePrice.hashCode ^
      acquiredAt.hashCode ^
      isEquipped.hashCode;

  @override
  String toString() {
    return 'Item(itemId: $itemId, name: $name, type: $type, rarity: $rarity, isEquipped: $isEquipped)';
  }
}

/// アイテムカタログ（ゲーム内で購入可能なアイテム定義）
class ItemCatalog {
  static const List<Item> availableItems = [
    // === 武器 ===
    Item(
      itemId: 'weapon_iron_sword',
      name: 'アイアンソード',
      description: '基本的な武器。攻撃力 +10%',
      type: ItemType.weapon,
      rarity: ItemRarity.common,
      bonus: ItemBonus(attackBonus: 10.0),
      purchasePrice: 100,
      acquiredAt: DateTime(2026, 9, 5),
      isEquipped: false,
    ),
    Item(
      itemId: 'weapon_steel_sword',
      name: 'スチールソード',
      description: '鋼製の武器。攻撃力 +20%',
      type: ItemType.weapon,
      rarity: ItemRarity.rare,
      bonus: ItemBonus(attackBonus: 20.0),
      purchasePrice: 300,
      acquiredAt: DateTime(2026, 9, 5),
      isEquipped: false,
    ),
    Item(
      itemId: 'weapon_mithril_sword',
      name: 'ミスリルソード',
      description: '幻の金属製。攻撃力 +35%',
      type: ItemType.weapon,
      rarity: ItemRarity.epic,
      bonus: ItemBonus(attackBonus: 35.0),
      purchasePrice: 800,
      acquiredAt: DateTime(2026, 9, 5),
      isEquipped: false,
    ),
    Item(
      itemId: 'weapon_dragon_slayer',
      name: 'ドラゴンスレイヤー',
      description: '伝説の武器。攻撃力 +60%',
      type: ItemType.weapon,
      rarity: ItemRarity.legend,
      bonus: ItemBonus(attackBonus: 60.0),
      purchasePrice: 2000,
      acquiredAt: DateTime(2026, 9, 5),
      isEquipped: false,
    ),

    // === 防具 ===
    Item(
      itemId: 'armor_leather_armor',
      name: 'レザーアーマー',
      description: '基本的な防具。防御力 +15%',
      type: ItemType.armor,
      rarity: ItemRarity.common,
      bonus: ItemBonus(defenseBonus: 15.0),
      purchasePrice: 100,
      acquiredAt: DateTime(2026, 9, 5),
      isEquipped: false,
    ),
    Item(
      itemId: 'armor_iron_armor',
      name: 'アイアンアーマー',
      description: '鋼製の防具。防御力 +25%',
      type: ItemType.armor,
      rarity: ItemRarity.rare,
      bonus: ItemBonus(defenseBonus: 25.0),
      purchasePrice: 300,
      acquiredAt: DateTime(2026, 9, 5),
      isEquipped: false,
    ),
    Item(
      itemId: 'armor_mythril_armor',
      name: 'ミスリルアーマー',
      description: '伝説の防具。防御力 +40%',
      type: ItemType.armor,
      rarity: ItemRarity.epic,
      bonus: ItemBonus(defenseBonus: 40.0),
      purchasePrice: 800,
      acquiredAt: DateTime(2026, 9, 5),
      isEquipped: false,
    ),
    Item(
      itemId: 'armor_divine_protection',
      name: '神聖なる加護',
      description: '神の加護。防御力 +60%',
      type: ItemType.armor,
      rarity: ItemRarity.legend,
      bonus: ItemBonus(defenseBonus: 60.0),
      purchasePrice: 2000,
      acquiredAt: DateTime(2026, 9, 5),
      isEquipped: false,
    ),

    // === 護符 ===
    Item(
      itemId: 'charm_ruby',
      name: 'ルビーの護符',
      description: '赤い護符。体力 +12%',
      type: ItemType.charm,
      rarity: ItemRarity.common,
      bonus: ItemBonus(hpBonus: 12.0),
      purchasePrice: 100,
      acquiredAt: DateTime(2026, 9, 5),
      isEquipped: false,
    ),
    Item(
      itemId: 'charm_sapphire',
      name: 'サファイアの護符',
      description: '青い護符。体力 +20%',
      type: ItemType.charm,
      rarity: ItemRarity.rare,
      bonus: ItemBonus(hpBonus: 20.0),
      purchasePrice: 300,
      acquiredAt: DateTime(2026, 9, 5),
      isEquipped: false,
    ),
    Item(
      itemId: 'charm_emerald',
      name: 'エメラルドの護符',
      description: '緑の護符。体力 +35%',
      type: ItemType.charm,
      rarity: ItemRarity.epic,
      bonus: ItemBonus(hpBonus: 35.0),
      purchasePrice: 800,
      acquiredAt: DateTime(2026, 9, 5),
      isEquipped: false,
    ),
    Item(
      itemId: 'charm_diamond',
      name: 'ダイヤモンドの護符',
      description: '最高の護符。体力 +50%',
      type: ItemType.charm,
      rarity: ItemRarity.legend,
      bonus: ItemBonus(hpBonus: 50.0),
      purchasePrice: 2000,
      acquiredAt: DateTime(2026, 9, 5),
      isEquipped: false,
    ),
  ];

  /// ID でアイテムを検索
  static Item? itemById(String itemId) {
    try {
      return availableItems.firstWhere((item) => item.itemId == itemId);
    } catch (e) {
      return null;
    }
  }

  /// タイプでアイテムをフィルタ
  static List<Item> itemsByType(ItemType type) {
    return availableItems.where((item) => item.type == type).toList();
  }

  /// レアリティでアイテムをフィルタ
  static List<Item> itemsByRarity(ItemRarity rarity) {
    return availableItems.where((item) => item.rarity == rarity).toList();
  }

  /// 価格でソート
  static List<Item> sortByPrice(List<Item> items) {
    final sorted = [...items];
    sorted.sort((a, b) => a.purchasePrice.compareTo(b.purchasePrice));
    return sorted;
  }
}
