/// マナ/ゴールド/アイテムシステム

class PlayerResources {
  final int currentMana;
  final int maxMana;
  final int gold;
  final List<String> ownedItemIds; // アイテムID一覧

  PlayerResources({
    required this.currentMana,
    required this.maxMana,
    required this.gold,
    this.ownedItemIds = const [],
  });

  /// マナが十分か判定
  bool canAffordMana(int cost) => currentMana >= cost;

  /// ゴールドが十分か判定
  bool canAffordGold(int cost) => gold >= cost;

  /// マナ消費
  PlayerResources spendMana(int cost) {
    assert(canAffordMana(cost), 'Not enough mana: $currentMana < $cost');
    return PlayerResources(
      currentMana: currentMana - cost,
      maxMana: maxMana,
      gold: gold,
      ownedItemIds: ownedItemIds,
    );
  }

  /// ゴール消費（アイテム購入）
  PlayerResources spendGold(int cost) {
    assert(canAffordGold(cost), 'Not enough gold: $gold < $cost');
    return PlayerResources(
      currentMana: currentMana,
      maxMana: maxMana,
      gold: gold - cost,
      ownedItemIds: ownedItemIds,
    );
  }

  /// マナ回復（自然リジェン）
  PlayerResources regenMana(int amount) {
    return PlayerResources(
      currentMana: (currentMana + amount).clamp(0, maxMana),
      maxMana: maxMana,
      gold: gold,
      ownedItemIds: ownedItemIds,
    );
  }

  /// ゴール獲得（キル報酬など）
  PlayerResources addGold(int amount) {
    return PlayerResources(
      currentMana: currentMana,
      maxMana: maxMana,
      gold: gold + amount,
      ownedItemIds: ownedItemIds,
    );
  }

  /// アイテム購入
  PlayerResources purchaseItem(String itemId, int cost) {
    assert(canAffordGold(cost), 'Not enough gold: $gold < $cost');
    return PlayerResources(
      currentMana: currentMana,
      maxMana: maxMana,
      gold: gold - cost,
      ownedItemIds: [...ownedItemIds, itemId],
    );
  }

  /// copyWith - 指定されたフィールドだけを更新した新しいインスタンスを返す
  PlayerResources copyWith({
    int? currentMana,
    int? maxMana,
    int? gold,
    List<String>? ownedItemIds,
  }) {
    return PlayerResources(
      currentMana: currentMana ?? this.currentMana,
      maxMana: maxMana ?? this.maxMana,
      gold: gold ?? this.gold,
      ownedItemIds: ownedItemIds ?? this.ownedItemIds,
    );
  }

  factory PlayerResources.fromJson(Map<String, dynamic> json) {
    return PlayerResources(
      currentMana: json['currentMana'] as int? ?? 50,
      maxMana: json['maxMana'] as int? ?? 100,
      gold: json['gold'] as int? ?? 0,
      ownedItemIds: List<String>.from(json['ownedItemIds'] as List? ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
    'currentMana': currentMana,
    'maxMana': maxMana,
    'gold': gold,
    'ownedItemIds': ownedItemIds,
  };
}

/// アイテム定義
enum ItemRarity { common, uncommon, rare, legendary }

class ItemDefinition {
  final String itemId;
  final String name;
  final String description;
  final int cost; // ゴールド
  final ItemRarity rarity;

  // ステータスボーナス
  final int hpBonus;
  final int atkBonus;
  final int defBonus;
  final int spdBonus;

  ItemDefinition({
    required this.itemId,
    required this.name,
    required this.description,
    required this.cost,
    required this.rarity,
    this.hpBonus = 0,
    this.atkBonus = 0,
    this.defBonus = 0,
    this.spdBonus = 0,
  });
}

/// ゴール報酬テーブル
class GoldRewards {
  static const int killReward = 100;
  static const int assistReward = 50;
  static const int firstBloodReward = 150;
  static const int towerDestroyReward = 200;
  static const int baseDestroyReward = 500;
  static const int passiveGoldPerSecond = 5;
}
