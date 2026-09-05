import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shinjuu_league/data/models/item_model.dart';
import 'firestore_service.dart';

/// アイテムシステムサービス
/// プレイヤーのアイテム在庫管理、装備管理、購入管理
class ItemService {
  static final ItemService _instance = ItemService._internal();

  factory ItemService() => _instance;
  ItemService._internal();

  final FirestoreService _firestoreService = FirestoreService();

  /// ユーザーの所有アイテム一覧を取得
  Future<List<Item>> getUserItems(String userId) async {
    try {
      final itemsCollection = await _firestoreService.db
          .collection('users')
          .doc(userId)
          .collection('items')
          .get();

      return itemsCollection.docs
          .map((doc) => Item.fromJson(doc.data()))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting user items: $e');
      }
      return [];
    }
  }

  /// ユーザーの装備中のアイテムを取得（最大3個）
  Future<List<Item>> getEquippedItems(String userId) async {
    try {
      final items = await getUserItems(userId);
      return items.where((item) => item.isEquipped).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting equipped items: $e');
      }
      return [];
    }
  }

  /// アイテムを購入して在庫に追加
  Future<bool> purchaseItem(
    String userId,
    String catalogItemId,
    int goldCost,
  ) async {
    try {
      final catalogItem = ItemCatalog.itemById(catalogItemId);
      if (catalogItem == null) {
        if (kDebugMode) {
          debugPrint('Item not found in catalog: $catalogItemId');
        }
        return false;
      }

      // アイテムインスタンスを作成（既に所有しているか確認）
      final newItem = catalogItem.copyWith(
        itemId: '${catalogItemId}_${DateTime.now().millisecondsSinceEpoch}',
        acquiredAt: DateTime.now(),
      );

      // Firestore に追加
      await _firestoreService.db
          .collection('users')
          .doc(userId)
          .collection('items')
          .doc(newItem.itemId)
          .set(newItem.toJson());

      // ゴール消費をユーザー側で処理（呼び出し元が責任を持つ）
      if (kDebugMode) {
        debugPrint('Item purchased: $catalogItemId, cost: $goldCost');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error purchasing item: $e');
      }
      return false;
    }
  }

  /// アイテムを装備
  /// 最大3個まで装備可能（同じタイプは1個まで）
  Future<bool> equipItem(String userId, String itemId) async {
    try {
      // 現在装備中のアイテムを取得
      final equippedItems = await getEquippedItems(userId);

      // 既に装備中の場合はスキップ
      final isAlreadyEquipped = equippedItems.any((item) => item.itemId == itemId);
      if (isAlreadyEquipped) {
        if (kDebugMode) {
          debugPrint('Item already equipped: $itemId');
        }
        return true;
      }

      // 装備数が3個以上の場合は失敗
      if (equippedItems.length >= 3) {
        if (kDebugMode) {
          debugPrint('Max equipped items reached (3)');
        }
        return false;
      }

      // 装備するアイテムの詳細を取得
      final itemDoc = await _firestoreService.db
          .collection('users')
          .doc(userId)
          .collection('items')
          .doc(itemId)
          .get();

      if (!itemDoc.exists) {
        if (kDebugMode) {
          debugPrint('Item not found: $itemId');
        }
        return false;
      }

      final item = Item.fromJson(itemDoc.data()!);

      // 同じタイプのアイテムが既に装備中の場合は外す
      final sameTypeEquipped =
          equippedItems.where((i) => i.type == item.type).toList();
      for (final equipped in sameTypeEquipped) {
        await unequipItem(userId, equipped.itemId);
      }

      // アイテムを装備状態に更新
      await _firestoreService.db
          .collection('users')
          .doc(userId)
          .collection('items')
          .doc(itemId)
          .update({'isEquipped': true});

      if (kDebugMode) {
        debugPrint('Item equipped: $itemId');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error equipping item: $e');
      }
      return false;
    }
  }

  /// アイテムを外す
  Future<bool> unequipItem(String userId, String itemId) async {
    try {
      await _firestoreService.db
          .collection('users')
          .doc(userId)
          .collection('items')
          .doc(itemId)
          .update({'isEquipped': false});

      if (kDebugMode) {
        debugPrint('Item unequipped: $itemId');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error unequipping item: $e');
      }
      return false;
    }
  }

  /// アイテムを削除（売却など）
  Future<bool> removeItem(String userId, String itemId) async {
    try {
      await _firestoreService.db
          .collection('users')
          .doc(userId)
          .collection('items')
          .doc(itemId)
          .delete();

      if (kDebugMode) {
        debugPrint('Item removed: $itemId');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error removing item: $e');
      }
      return false;
    }
  }

  /// 装備中のアイテムから総合ボーナスを計算
  Future<ItemBonus> getEquippedBonuses(String userId) async {
    try {
      final equippedItems = await getEquippedItems(userId);

      double totalAttackBonus = 0;
      double totalDefenseBonus = 0;
      double totalHpBonus = 0;

      for (final item in equippedItems) {
        totalAttackBonus += item.bonus.attackBonus ?? 0;
        totalDefenseBonus += item.bonus.defenseBonus ?? 0;
        totalHpBonus += item.bonus.hpBonus ?? 0;
      }

      return ItemBonus(
        attackBonus: totalAttackBonus > 0 ? totalAttackBonus : null,
        defenseBonus: totalDefenseBonus > 0 ? totalDefenseBonus : null,
        hpBonus: totalHpBonus > 0 ? totalHpBonus : null,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting equipped bonuses: $e');
      }
      return ItemBonus();
    }
  }

  /// ステータスにアイテムボーナスを適用
  /// 例: baseAttack=100, itemAttackBonus=20% → 100 * (1 + 0.20) = 120
  static double applyItemBonus(double baseStat, double? itemBonusPercent) {
    if (itemBonusPercent == null || itemBonusPercent == 0) {
      return baseStat;
    }
    return baseStat * (1 + (itemBonusPercent / 100.0));
  }

  /// デバッグ用: ユーザーのアイテム状態をダンプ
  Future<Map<String, dynamic>> debugDumpUserItems(String userId) async {
    try {
      final allItems = await getUserItems(userId);
      final equippedItems = await getEquippedItems(userId);
      final bonuses = await getEquippedBonuses(userId);

      return {
        'total_items': allItems.length,
        'equipped_count': equippedItems.length,
        'equipped_items': equippedItems.map((i) => i.name).toList(),
        'total_bonuses': {
          'attack': bonuses.attackBonus,
          'defense': bonuses.defenseBonus,
          'hp': bonuses.hpBonus,
        },
        'items': allItems
            .map((i) => {
                  'id': i.itemId,
                  'name': i.name,
                  'type': i.type.toString(),
                  'rarity': i.rarity.toString(),
                  'equipped': i.isEquipped,
                })
            .toList(),
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}
