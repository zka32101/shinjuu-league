import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shinjuu_league/data/models/item_model.dart';
import 'package:shinjuu_league/services/auth_service.dart';
import 'package:shinjuu_league/services/item_service.dart';

/// ユーザーのアイテムインベントリを管理するViewModel
class InventoryViewModel extends StateNotifier<AsyncValue<List<Item>>> {
  InventoryViewModel({
    ItemService? itemService,
    AuthService? authService,
  })
    : _itemService = itemService ?? ItemService(),
      _authService = authService ?? AuthService(),
      super(const AsyncValue.loading()) {
    _init();
  }

  final ItemService _itemService;
  final AuthService _authService;

  /// 現在のユーザーID
  String? get _currentUserId => _authService.currentUser?.uid;

  /// ユーザーの装備中アイテム
  AsyncValue<List<Item>> get equippedItems {
    final items = state.value ?? [];
    return AsyncValue.data(items.where((item) => item.isEquipped).toList());
  }

  /// ユーザーの未装備アイテム
  AsyncValue<List<Item>> get unequippedItems {
    final items = state.value ?? [];
    return AsyncValue.data(items.where((item) => !item.isEquipped).toList());
  }

  /// 装備中のアイテム数
  int get equippedCount {
    final items = state.value ?? [];
    return items.where((item) => item.isEquipped).length;
  }

  /// 装備中のアイテムの合計ステータスボーナス
  ItemBonus get totalEquippedBonus {
    final items = state.value ?? [];
    final equipped = items.where((item) => item.isEquipped).toList();

    double totalAttack = 0;
    double totalDefense = 0;
    double totalHp = 0;

    for (final item in equipped) {
      if (item.bonus != null) {
        totalAttack += item.bonus!.attackBonus ?? 0;
        totalDefense += item.bonus!.defenseBonus ?? 0;
        totalHp += item.bonus!.hpBonus ?? 0;
      }
    }

    return ItemBonus(
      attackBonus: totalAttack > 0 ? totalAttack : null,
      defenseBonus: totalDefense > 0 ? totalDefense : null,
      hpBonus: totalHp > 0 ? totalHp : null,
    );
  }

  /// インベントリを初期化
  Future<void> _init() async {
    final userId = _currentUserId;
    if (userId == null) {
      state = const AsyncValue.data([]);
      return;
    }

    await _loadInventory(userId);
  }

  /// ユーザーのアイテムを読み込み
  Future<void> _loadInventory(String userId) async {
    try {
      state = const AsyncValue.loading();
      final items = await _itemService.getUserItems(userId);
      state = AsyncValue.data(items);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// アイテムを装備
  /// 同じタイプの他のアイテムは自動的に外される
  Future<void> equipItem(String itemId) async {
    final userId = _currentUserId;
    if (userId == null) return;

    try {
      await _itemService.equipItem(userId, itemId);
      await _reloadInventory();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// アイテムを外す
  Future<void> unequipItem(String itemId) async {
    final userId = _currentUserId;
    if (userId == null) return;

    try {
      await _itemService.unequipItem(userId, itemId);
      await _reloadInventory();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// アイテムを削除（在庫から除去）
  Future<void> removeItem(String itemId) async {
    final userId = _currentUserId;
    if (userId == null) return;

    try {
      await _itemService.removeItem(userId, itemId);
      await _reloadInventory();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// インベントリをリロード
  Future<void> _reloadInventory() async {
    final userId = _currentUserId;
    if (userId == null) return;

    try {
      final items = await _itemService.getUserItems(userId);
      state = AsyncValue.data(items);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// 特定のタイプで装備中のアイテムを取得
  Item? getEquippedItemByType(ItemType type) {
    final items = state.value ?? [];
    try {
      return items.firstWhere(
        (item) => item.isEquipped && item.type == type,
      );
    } catch (e) {
      return null;
    }
  }

  /// アイテムがタイプ内で装備可能か確認
  /// 同じタイプで既に装備中の場合は false
  bool canEquipItem(Item item) {
    if (item.isEquipped) return false;

    final equippedByType = getEquippedItemByType(item.type);
    return equippedByType == null || equippedByType.itemId != item.itemId;
  }

  /// ユーザーのアイテム統計情報
  Map<String, dynamic> getInventoryStats() {
    final items = state.value ?? [];
    return {
      'total_items': items.length,
      'equipped_count': equippedCount,
      'unequipped_count': items.length - equippedCount,
      'by_type': {
        'weapons': items.where((i) => i.type == ItemType.weapon).length,
        'armors': items.where((i) => i.type == ItemType.armor).length,
        'charms': items.where((i) => i.type == ItemType.charm).length,
      },
      'by_rarity': {
        'common': items.where((i) => i.rarity == ItemRarity.common).length,
        'rare': items.where((i) => i.rarity == ItemRarity.rare).length,
        'epic': items.where((i) => i.rarity == ItemRarity.epic).length,
        'legend': items.where((i) => i.rarity == ItemRarity.legend).length,
      },
      'total_bonuses': {
        'attack': totalEquippedBonus.attackBonus ?? 0,
        'defense': totalEquippedBonus.defenseBonus ?? 0,
        'hp': totalEquippedBonus.hpBonus ?? 0,
      },
    };
  }

  @override
  void dispose() {
    super.dispose();
  }
}

/// Riverpod provider for InventoryViewModel
final inventoryViewModelProvider =
    StateNotifierProvider.autoDispose<InventoryViewModel, AsyncValue<List<Item>>>(
  (ref) => InventoryViewModel(),
);

/// Equipped items provider
final equippedItemsProvider =
    Provider.autoDispose<List<Item>>((ref) {
  final inventory = ref.watch(inventoryViewModelProvider);
  final items = inventory.value ?? [];
  return items.where((item) => item.isEquipped).toList();
});

/// Unequipped items provider
final unequippedItemsProvider =
    Provider.autoDispose<List<Item>>((ref) {
  final inventory = ref.watch(inventoryViewModelProvider);
  final items = inventory.value ?? [];
  return items.where((item) => !item.isEquipped).toList();
});

/// Total equipped bonus provider
final totalEquippedBonusProvider = Provider.autoDispose<AsyncValue<ItemBonus>>((ref) {
  final inventory = ref.watch(inventoryViewModelProvider);
  return inventory.whenData((items) {
    double totalAttack = 0;
    double totalDefense = 0;
    double totalHp = 0;

    for (final item in items) {
      if (item.isEquipped && item.bonus != null) {
        totalAttack += item.bonus!.attackBonus ?? 0;
        totalDefense += item.bonus!.defenseBonus ?? 0;
        totalHp += item.bonus!.hpBonus ?? 0;
      }
    }

    return ItemBonus(
      attackBonus: totalAttack > 0 ? totalAttack : null,
      defenseBonus: totalDefense > 0 ? totalDefense : null,
      hpBonus: totalHp > 0 ? totalHp : null,
    );
  });
});
