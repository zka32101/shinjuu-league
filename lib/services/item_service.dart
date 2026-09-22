import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shinjuu_league/data/models/item_model.dart';
import 'firestore_service.dart';

/// アイテム購入リクエストの結果。
/// gold フィールドはクライアントから直接書き込めない（Firestore Rules）ため、
/// 購入は item_purchases ドキュメント経由でサーバー側検証（Cloud Function）に
/// 委ねる。この enum はその検証結果をUI層に伝える。
enum ItemPurchaseResult {
  success,
  insufficientGold,
  invalidItem,
  timeout,
  error,
}

/// アイテムシステムサービス
/// プレイヤーのアイテム在庫管理、装備管理、購入管理
class ItemService {
  static final ItemService _instance = ItemService._internal();

  factory ItemService() => _instance;
  ItemService._internal();

  /// Test-only seam: builds a standalone (non-singleton) ItemService backed
  /// by a caller-provided FirestoreService, matching ReplayService's pattern.
  ItemService.forFirestore(FirestoreService firestoreService)
    : _firestoreServiceOverride = firestoreService;

  FirestoreService? _firestoreServiceOverride;
  FirestoreService get _firestoreService =>
      _firestoreServiceOverride ??= FirestoreService();

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

  /// アイテムを購入（サーバー側検証）
  /// gold フィールドはクライアントから直接書き込めない（Firestore Rules、
  /// 他の通貨/統計フィールドと同様）ため、item_purchases ドキュメントを
  /// 送信して item-purchase-validator Cloud Function にゴールド消費と
  /// アイテム付与を委ねる。これは battle_results → elo-validator.ts と
  /// 同じサーバー権威検証パターン。Cloud Function は独自の価格カタログを
  /// 参照するため、クライアントが送るのは catalogItemId のみで価格は
  /// 一切信用しない。
  Future<ItemPurchaseResult> purchaseItem(
    String userId,
    String catalogItemId, {
    Duration timeout = const Duration(seconds: 15),
  }) async {
    if (ItemCatalog.itemById(catalogItemId) == null) {
      return ItemPurchaseResult.invalidItem;
    }

    try {
      final purchaseRef = await _firestoreService.db
          .collection('item_purchases')
          .add({
            'userId': userId,
            'catalogItemId': catalogItemId,
            'timestamp': FieldValue.serverTimestamp(),
          });

      final processedSnap = await purchaseRef
          .snapshots()
          .firstWhere((snap) => snap.data()?['processed'] == true)
          .timeout(timeout);

      final data = processedSnap.data();
      if (data?['success'] == true) {
        return ItemPurchaseResult.success;
      }
      if (data?['reason'] == 'insufficient_gold') {
        return ItemPurchaseResult.insufficientGold;
      }
      return ItemPurchaseResult.error;
    } on TimeoutException {
      return ItemPurchaseResult.timeout;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error purchasing item: $e');
      }
      return ItemPurchaseResult.error;
    }
  }

  /// アイテムを装備
  /// 最大3個まで装備可能（同じタイプは1個まで）
  Future<bool> equipItem(String userId, String itemId) async {
    try {
      // 現在装備中のアイテムを取得
      final equippedItems = await getEquippedItems(userId);

      // 既に装備中の場合はスキップ
      final isAlreadyEquipped = equippedItems.any(
        (item) => item.itemId == itemId,
      );
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
      final sameTypeEquipped = equippedItems
          .where((i) => i.type == item.type)
          .toList();
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
        totalAttackBonus += item.bonus?.attackBonus ?? 0;
        totalDefenseBonus += item.bonus?.defenseBonus ?? 0;
        totalHpBonus += item.bonus?.hpBonus ?? 0;
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
            .map(
              (i) => {
                'id': i.itemId,
                'name': i.name,
                'type': i.type.toString(),
                'rarity': i.rarity.toString(),
                'equipped': i.isEquipped,
              },
            )
            .toList(),
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}
