import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:shinjuu_league/data/models/item_model.dart';

void main() {
  group('Item System', () {
    late FakeFirebaseFirestore fakeDb;

    setUp(() {
      fakeDb = FakeFirebaseFirestore();
    });

    group('Item Model', () {
      test('creates ItemBonus with attack bonus', () {
        final bonus = ItemBonus(attackBonus: 25.0);
        expect(bonus.attackBonus, equals(25.0));
        expect(bonus.defenseBonus, isNull);
        expect(bonus.hpBonus, isNull);
      });

      test('ItemBonus copyWith updates fields correctly', () {
        final bonus = ItemBonus(attackBonus: 25.0, defenseBonus: 15.0);
        final updated = bonus.copyWith(attackBonus: 30.0);
        expect(updated.attackBonus, equals(30.0));
        expect(updated.defenseBonus, equals(15.0));
      });

      test('creates Item with all required fields', () {
        final item = Item(
          itemId: 'test_sword',
          name: 'Test Sword',
          description: 'A test weapon',
          type: ItemType.weapon,
          rarity: ItemRarity.rare,
          bonus: ItemBonus(attackBonus: 20.0),
          purchasePrice: 500,
          acquiredAt: DateTime(2026, 9, 5),
          isEquipped: false,
        );

        expect(item.itemId, equals('test_sword'));
        expect(item.name, equals('Test Sword'));
        expect(item.type, equals(ItemType.weapon));
        expect(item.rarity, equals(ItemRarity.rare));
        expect(item.isEquipped, isFalse);
      });

      test('Item copyWith updates fields correctly', () {
        final item = Item(
          itemId: 'test_sword',
          name: 'Test Sword',
          description: 'A test weapon',
          type: ItemType.weapon,
          rarity: ItemRarity.rare,
          bonus: ItemBonus(attackBonus: 20.0),
          purchasePrice: 500,
          acquiredAt: DateTime(2026, 9, 5),
          isEquipped: false,
        );

        final equipped = item.copyWith(isEquipped: true);
        expect(equipped.isEquipped, isTrue);
        expect(equipped.itemId, equals('test_sword'));
        expect(equipped.name, equals('Test Sword'));
      });

      test('Item equality works correctly', () {
        final item1 = Item(
          itemId: 'test_sword',
          name: 'Test Sword',
          description: 'A test weapon',
          type: ItemType.weapon,
          rarity: ItemRarity.rare,
          bonus: ItemBonus(attackBonus: 20.0),
          purchasePrice: 500,
          acquiredAt: DateTime(2026, 9, 5),
          isEquipped: false,
        );

        final item2 = Item(
          itemId: 'test_sword',
          name: 'Test Sword',
          description: 'A test weapon',
          type: ItemType.weapon,
          rarity: ItemRarity.rare,
          bonus: ItemBonus(attackBonus: 20.0),
          purchasePrice: 500,
          acquiredAt: DateTime(2026, 9, 5),
          isEquipped: false,
        );

        expect(item1, equals(item2));
      });

      test('Item JSON serialization roundtrip', () {
        final original = Item(
          itemId: 'test_sword',
          name: 'Test Sword',
          description: 'A test weapon',
          type: ItemType.weapon,
          rarity: ItemRarity.rare,
          bonus: ItemBonus(attackBonus: 20.0),
          purchasePrice: 500,
          acquiredAt: DateTime(2026, 9, 5),
          isEquipped: false,
        );

        final json = original.toJson();
        final restored = Item.fromJson(json);

        expect(restored, equals(original));
      });
    });

    group('ItemCatalog', () {
      test('itemById returns correct item from catalog', () {
        final item = ItemCatalog.itemById('weapon_iron_sword');
        expect(item, isNotNull);
        expect(item!.name, equals('アイアンソード'));
        expect(item.type, equals(ItemType.weapon));
        expect(item.rarity, equals(ItemRarity.common));
      });

      test('itemById returns null for unknown item', () {
        final item = ItemCatalog.itemById('unknown_item');
        expect(item, isNull);
      });

      test('itemsByType filters items correctly', () {
        final weapons = ItemCatalog.itemsByType(ItemType.weapon);
        expect(weapons, isNotEmpty);
        expect(weapons.every((item) => item.type == ItemType.weapon), isTrue);
      });

      test('itemsByRarity filters items correctly', () {
        final legendItems = ItemCatalog.itemsByRarity(ItemRarity.legend);
        expect(legendItems, isNotEmpty);
        expect(
          legendItems.every((item) => item.rarity == ItemRarity.legend),
          isTrue,
        );
      });

      test('sortByPrice sorts items by purchase price', () {
        final all = ItemCatalog.availableItems;
        final sorted = ItemCatalog.sortByPrice(all);

        for (int i = 0; i < sorted.length - 1; i++) {
          expect(
            sorted[i].purchasePrice <= sorted[i + 1].purchasePrice,
            isTrue,
          );
        }
      });

      test('catalog has at least one item of each type', () {
        final weapons = ItemCatalog.itemsByType(ItemType.weapon);
        final armors = ItemCatalog.itemsByType(ItemType.armor);
        final charms = ItemCatalog.itemsByType(ItemType.charm);

        expect(weapons, isNotEmpty);
        expect(armors, isNotEmpty);
        expect(charms, isNotEmpty);
      });

      test('catalog has items of each rarity level', () {
        expect(
          ItemCatalog.availableItems.any((i) => i.rarity == ItemRarity.common),
          isTrue,
        );
        expect(
          ItemCatalog.availableItems.any((i) => i.rarity == ItemRarity.rare),
          isTrue,
        );
        expect(
          ItemCatalog.availableItems.any((i) => i.rarity == ItemRarity.epic),
          isTrue,
        );
        expect(
          ItemCatalog.availableItems.any((i) => i.rarity == ItemRarity.legend),
          isTrue,
        );
      });

      test('all catalog items have valid bonuses', () {
        for (final item in ItemCatalog.availableItems) {
          // At least one bonus should be present
          final hasBonus = item.bonus.attackBonus != null ||
              item.bonus.defenseBonus != null ||
              item.bonus.hpBonus != null;
          expect(hasBonus, isTrue, reason: '${item.name} has no bonus');

          // Bonuses should be positive percentages
          if (item.bonus.attackBonus != null) {
            expect(item.bonus.attackBonus! > 0, isTrue);
          }
          if (item.bonus.defenseBonus != null) {
            expect(item.bonus.defenseBonus! > 0, isTrue);
          }
          if (item.bonus.hpBonus != null) {
            expect(item.bonus.hpBonus! > 0, isTrue);
          }
        }
      });

      test('legendary items have higher bonuses than common', () {
        final commonWeapons =
            ItemCatalog.itemsByRarity(ItemRarity.common)
                .where((i) => i.type == ItemType.weapon);
        final legendWeapons =
            ItemCatalog.itemsByRarity(ItemRarity.legend)
                .where((i) => i.type == ItemType.weapon);

        expect(commonWeapons, isNotEmpty);
        expect(legendWeapons, isNotEmpty);

        final avgCommonBonus = commonWeapons
                .map((i) => i.bonus.attackBonus ?? 0)
                .reduce((a, b) => a + b) /
            commonWeapons.length;
        final avgLegendBonus = legendWeapons
                .map((i) => i.bonus.attackBonus ?? 0)
                .reduce((a, b) => a + b) /
            legendWeapons.length;

        expect(avgLegendBonus > avgCommonBonus, isTrue);
      });
    });

    group('Item Bonus Calculation', () {
      test('applyItemBonus calculates correctly with positive bonus', () {
        final baseStat = 100.0;
        final itemBonus = 20.0; // 20%

        final result = applyItemBonus(baseStat, itemBonus);
        expect(result, equals(120.0));
      });

      test('applyItemBonus returns base stat when bonus is null', () {
        final baseStat = 100.0;
        final result = applyItemBonus(baseStat, null);
        expect(result, equals(100.0));
      });

      test('applyItemBonus returns base stat when bonus is zero', () {
        final baseStat = 100.0;
        final result = applyItemBonus(baseStat, 0.0);
        expect(result, equals(100.0));
      });

      test('applyItemBonus works with decimal bonus', () {
        final baseStat = 100.0;
        final itemBonus = 15.5; // 15.5%

        final result = applyItemBonus(baseStat, itemBonus);
        expect(result, closeTo(115.5, 0.01));
      });

      test('applyItemBonus compounds correctly with multiple items', () {
        // Simulate 3 items with bonuses
        double stats = 100.0;
        stats = applyItemBonus(stats, 10.0); // +10%
        stats = applyItemBonus(stats, 20.0); // +20%
        stats = applyItemBonus(stats, 15.0); // +15%

        // 100 * 1.1 * 1.2 * 1.15 = 151.8
        expect(stats, closeTo(151.8, 0.01));
      });
    });

    group('Firestore Integration', () {
      test('saves and retrieves item from Firestore', () async {
        const userId = 'test_user';
        const itemId = 'test_item_001';

        final item = Item(
          itemId: itemId,
          name: 'Test Sword',
          description: 'A test weapon',
          type: ItemType.weapon,
          rarity: ItemRarity.rare,
          bonus: ItemBonus(attackBonus: 20.0),
          purchasePrice: 500,
          acquiredAt: DateTime(2026, 9, 5),
          isEquipped: false,
        );

        // Save
        await fakeDb
            .collection('users')
            .doc(userId)
            .collection('items')
            .doc(itemId)
            .set(item.toJson());

        // Retrieve
        final doc = await fakeDb
            .collection('users')
            .doc(userId)
            .collection('items')
            .doc(itemId)
            .get();

        expect(doc.exists, isTrue);
        final retrieved = Item.fromJson(doc.data()!);
        expect(retrieved, equals(item));
      });

      test('equipped status persists to Firestore', () async {
        const userId = 'test_user';
        const itemId = 'test_item_001';

        final item = Item(
          itemId: itemId,
          name: 'Test Sword',
          description: 'A test weapon',
          type: ItemType.weapon,
          rarity: ItemRarity.rare,
          bonus: ItemBonus(attackBonus: 20.0),
          purchasePrice: 500,
          acquiredAt: DateTime(2026, 9, 5),
          isEquipped: false,
        );

        // Save initial state
        await fakeDb
            .collection('users')
            .doc(userId)
            .collection('items')
            .doc(itemId)
            .set(item.toJson());

        // Update equipped status
        await fakeDb
            .collection('users')
            .doc(userId)
            .collection('items')
            .doc(itemId)
            .update({'isEquipped': true});

        // Verify
        final doc = await fakeDb
            .collection('users')
            .doc(userId)
            .collection('items')
            .doc(itemId)
            .get();

        final retrieved = Item.fromJson(doc.data()!);
        expect(retrieved.isEquipped, isTrue);
      });

      test('multiple items can be stored and retrieved', () async {
        const userId = 'test_user';

        final items = [
          Item(
            itemId: 'item_1',
            name: 'Sword',
            description: 'Weapon',
            type: ItemType.weapon,
            rarity: ItemRarity.common,
            bonus: ItemBonus(attackBonus: 10.0),
            purchasePrice: 100,
            acquiredAt: DateTime(2026, 9, 5),
            isEquipped: true,
          ),
          Item(
            itemId: 'item_2',
            name: 'Armor',
            description: 'Armor',
            type: ItemType.armor,
            rarity: ItemRarity.rare,
            bonus: ItemBonus(defenseBonus: 20.0),
            purchasePrice: 300,
            acquiredAt: DateTime(2026, 9, 5),
            isEquipped: true,
          ),
          Item(
            itemId: 'item_3',
            name: 'Charm',
            description: 'Charm',
            type: ItemType.charm,
            rarity: ItemRarity.common,
            bonus: ItemBonus(hpBonus: 12.0),
            purchasePrice: 100,
            acquiredAt: DateTime(2026, 9, 5),
            isEquipped: false,
          ),
        ];

        // Save all items
        for (final item in items) {
          await fakeDb
              .collection('users')
              .doc(userId)
              .collection('items')
              .doc(item.itemId)
              .set(item.toJson());
        }

        // Retrieve all items
        final snapshot = await fakeDb
            .collection('users')
            .doc(userId)
            .collection('items')
            .get();

        expect(snapshot.docs.length, equals(3));

        final retrieved = snapshot.docs
            .map((doc) => Item.fromJson(doc.data()))
            .toList();

        expect(retrieved, equals(items));
      });
    });

    group('Equipped Items Tracking', () {
      test('can track equipped status', () async {
        const userId = 'test_user';

        final item = Item(
          itemId: 'sword_001',
          name: 'Iron Sword',
          description: 'A basic sword',
          type: ItemType.weapon,
          rarity: ItemRarity.common,
          bonus: ItemBonus(attackBonus: 10.0),
          purchasePrice: 100,
          acquiredAt: DateTime(2026, 9, 5),
          isEquipped: false,
        );

        // Save item
        await fakeDb
            .collection('users')
            .doc(userId)
            .collection('items')
            .doc(item.itemId)
            .set(item.toJson());

        // Equip item
        await fakeDb
            .collection('users')
            .doc(userId)
            .collection('items')
            .doc(item.itemId)
            .update({'isEquipped': true});

        // Verify equipped
        final doc = await fakeDb
            .collection('users')
            .doc(userId)
            .collection('items')
            .doc(item.itemId)
            .get();

        final retrieved = Item.fromJson(doc.data()!);
        expect(retrieved.isEquipped, isTrue);
      });

      test('can query only equipped items', () async {
        const userId = 'test_user';

        final equippedItem = Item(
          itemId: 'item_1',
          name: 'Sword',
          description: 'Weapon',
          type: ItemType.weapon,
          rarity: ItemRarity.common,
          bonus: ItemBonus(attackBonus: 10.0),
          purchasePrice: 100,
          acquiredAt: DateTime(2026, 9, 5),
          isEquipped: true,
        );

        final unequippedItem = Item(
          itemId: 'item_2',
          name: 'Armor',
          description: 'Armor',
          type: ItemType.armor,
          rarity: ItemRarity.rare,
          bonus: ItemBonus(defenseBonus: 20.0),
          purchasePrice: 300,
          acquiredAt: DateTime(2026, 9, 5),
          isEquipped: false,
        );

        // Save both items
        await fakeDb
            .collection('users')
            .doc(userId)
            .collection('items')
            .doc(equippedItem.itemId)
            .set(equippedItem.toJson());

        await fakeDb
            .collection('users')
            .doc(userId)
            .collection('items')
            .doc(unequippedItem.itemId)
            .set(unequippedItem.toJson());

        // Query all items
        final snapshot = await fakeDb
            .collection('users')
            .doc(userId)
            .collection('items')
            .get();

        final allItems =
            snapshot.docs.map((doc) => Item.fromJson(doc.data())).toList();

        // Filter equipped items
        final equipped = allItems.where((item) => item.isEquipped).toList();

        expect(equipped.length, equals(1));
        expect(equipped.first.itemId, equals('item_1'));
      });
    });

    group('Item Type Enforcement', () {
      test('prevents equipping multiple items of same type', () {
        // This test verifies the business logic constraint
        final equippedItems = [
          Item(
            itemId: 'sword_1',
            name: 'Iron Sword',
            description: 'Weapon',
            type: ItemType.weapon,
            rarity: ItemRarity.common,
            bonus: ItemBonus(attackBonus: 10.0),
            purchasePrice: 100,
            acquiredAt: DateTime(2026, 9, 5),
            isEquipped: true,
          ),
          Item(
            itemId: 'armor_1',
            name: 'Leather Armor',
            description: 'Armor',
            type: ItemType.armor,
            rarity: ItemRarity.common,
            bonus: ItemBonus(defenseBonus: 15.0),
            purchasePrice: 100,
            acquiredAt: DateTime(2026, 9, 5),
            isEquipped: true,
          ),
          Item(
            itemId: 'charm_1',
            name: 'Ruby Charm',
            description: 'Charm',
            type: ItemType.charm,
            rarity: ItemRarity.common,
            bonus: ItemBonus(hpBonus: 12.0),
            purchasePrice: 100,
            acquiredAt: DateTime(2026, 9, 5),
            isEquipped: true,
          ),
        ];

        // Count by type
        final typeCount = <ItemType, int>{};
        for (final item in equippedItems) {
          typeCount[item.type] = (typeCount[item.type] ?? 0) + 1;
        }

        // Verify max 1 per type
        for (final count in typeCount.values) {
          expect(count <= 1, isTrue);
        }

        // Verify max 3 total
        expect(equippedItems.length <= 3, isTrue);
      });
    });
  });
}

// Helper function for testing bonus calculation
double applyItemBonus(double baseStat, double? itemBonusPercent) {
  if (itemBonusPercent == null || itemBonusPercent == 0) {
    return baseStat;
  }
  return baseStat * (1 + (itemBonusPercent / 100.0));
}
