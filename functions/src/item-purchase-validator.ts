import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

/**
 * What the client submits to request a purchase. Only catalogItemId is
 * trusted as "which item" - price is never taken from the client (the
 * gold field on /users/{userId} is denylisted for direct client writes,
 * same as eloRating; see firestore.rules). Mirrors the battle_results ->
 * elo-validator.ts server-authoritative pattern.
 */
interface ItemPurchaseRequest {
  userId: string;
  catalogItemId: string;
}

interface ItemBonus {
  attackBonus?: number;
  defenseBonus?: number;
  hpBonus?: number;
}

interface CatalogItem {
  name: string;
  description: string;
  type: 'weapon' | 'armor' | 'charm';
  rarity: 'common' | 'rare' | 'epic' | 'legend';
  bonus: ItemBonus;
  price: number;
}

/**
 * Server-side mirror of lib/data/models/item_model.dart's
 * ItemCatalog.availableItems. Must be kept in sync by hand when that
 * catalog changes - there is no shared source of truth between Dart and
 * this Cloud Function, the same tradeoff the mecha catalog already makes.
 * This is the only place item prices are trusted from; the client's own
 * copy of the catalog is display-only.
 */
const ITEM_CATALOG: Record<string, CatalogItem> = {
  weapon_iron_sword: {
    name: 'アイアンソード',
    description: '基本的な武器。攻撃力 +10%',
    type: 'weapon',
    rarity: 'common',
    bonus: { attackBonus: 10.0 },
    price: 100,
  },
  weapon_steel_sword: {
    name: 'スチールソード',
    description: '鋼製の武器。攻撃力 +20%',
    type: 'weapon',
    rarity: 'rare',
    bonus: { attackBonus: 20.0 },
    price: 300,
  },
  weapon_mithril_sword: {
    name: 'ミスリルソード',
    description: '幻の金属製。攻撃力 +35%',
    type: 'weapon',
    rarity: 'epic',
    bonus: { attackBonus: 35.0 },
    price: 800,
  },
  weapon_dragon_slayer: {
    name: 'ドラゴンスレイヤー',
    description: '伝説の武器。攻撃力 +60%',
    type: 'weapon',
    rarity: 'legend',
    bonus: { attackBonus: 60.0 },
    price: 2000,
  },
  armor_leather_armor: {
    name: 'レザーアーマー',
    description: '基本的な防具。防御力 +15%',
    type: 'armor',
    rarity: 'common',
    bonus: { defenseBonus: 15.0 },
    price: 100,
  },
  armor_iron_armor: {
    name: 'アイアンアーマー',
    description: '鋼製の防具。防御力 +25%',
    type: 'armor',
    rarity: 'rare',
    bonus: { defenseBonus: 25.0 },
    price: 300,
  },
  armor_mythril_armor: {
    name: 'ミスリルアーマー',
    description: '伝説の防具。防御力 +40%',
    type: 'armor',
    rarity: 'epic',
    bonus: { defenseBonus: 40.0 },
    price: 800,
  },
  armor_divine_protection: {
    name: '神聖なる加護',
    description: '神の加護。防御力 +60%',
    type: 'armor',
    rarity: 'legend',
    bonus: { defenseBonus: 60.0 },
    price: 2000,
  },
  charm_ruby: {
    name: 'ルビーの護符',
    description: '赤い護符。体力 +12%',
    type: 'charm',
    rarity: 'common',
    bonus: { hpBonus: 12.0 },
    price: 100,
  },
  charm_sapphire: {
    name: 'サファイアの護符',
    description: '青い護符。体力 +20%',
    type: 'charm',
    rarity: 'rare',
    bonus: { hpBonus: 20.0 },
    price: 300,
  },
  charm_emerald: {
    name: 'エメラルドの護符',
    description: '緑の護符。体力 +35%',
    type: 'charm',
    rarity: 'epic',
    bonus: { hpBonus: 35.0 },
    price: 800,
  },
  charm_diamond: {
    name: 'ダイヤモンドの護符',
    description: '最高の護符。体力 +50%',
    type: 'charm',
    rarity: 'legend',
    bonus: { hpBonus: 50.0 },
    price: 2000,
  },
};

/**
 * Cloud Function: Triggered when a client submits an item_purchases
 * document. Recomputes the price server-side from ITEM_CATALOG (never
 * trusting anything the client might have sent for it), checks the
 * user's current gold, and atomically deducts gold + grants the item
 * only if the check passes. Marks the purchase document processed either
 * way so the client's listener (with a timeout) can stop waiting and show
 * the right outcome.
 */
export const validateItemPurchase = functions.firestore
  .document('item_purchases/{purchaseId}')
  .onCreate(async (snap, context) => {
    const db = admin.firestore();
    const request = snap.data() as ItemPurchaseRequest;
    const purchaseId = context.params.purchaseId;
    const purchaseRef = snap.ref;

    console.log(
      `[ItemPurchase] Processing purchase ${purchaseId} for user ${request.userId}, item ${request.catalogItemId}`
    );

    try {
      const catalogItem = ITEM_CATALOG[request.catalogItemId];
      if (!catalogItem) {
        console.error(`[ItemPurchase] Unknown catalogItemId: ${request.catalogItemId}`);
        await purchaseRef.update({
          processed: true,
          success: false,
          reason: 'invalid_item',
        });
        return;
      }

      const userRef = db.collection('users').doc(request.userId);
      const userSnap = await userRef.get();
      if (!userSnap.exists) {
        console.error(`[ItemPurchase] User ${request.userId} not found`);
        await purchaseRef.update({
          processed: true,
          success: false,
          reason: 'user_not_found',
        });
        return;
      }

      const currentGold = (userSnap.data()?.gold as number | undefined) ?? 0;
      if (currentGold < catalogItem.price) {
        console.log(
          `[ItemPurchase] Insufficient gold: user ${request.userId} has ${currentGold}, needs ${catalogItem.price}`
        );
        await purchaseRef.update({
          processed: true,
          success: false,
          reason: 'insufficient_gold',
        });
        return;
      }

      // itemId format mirrors the client's previous convention
      // (`${catalogItemId}_<unique suffix>`) so multiple instances of the
      // same catalog item can coexist in a player's inventory.
      const itemInstanceRef = userRef.collection('items').doc();
      const itemId = `${request.catalogItemId}_${itemInstanceRef.id}`;

      const batch = db.batch();
      batch.update(userRef, {
        gold: admin.firestore.FieldValue.increment(-catalogItem.price),
      });
      // acquiredAt is a plain ISO string, not FieldValue.serverTimestamp():
      // the Dart Item model parses it with DateTime.parse(), which cannot
      // handle a Firestore Timestamp object.
      batch.set(userRef.collection('items').doc(itemId), {
        itemId,
        name: catalogItem.name,
        description: catalogItem.description,
        type: catalogItem.type,
        rarity: catalogItem.rarity,
        bonus: catalogItem.bonus,
        purchasePrice: catalogItem.price,
        acquiredAt: new Date().toISOString(),
        isEquipped: false,
      });
      batch.update(purchaseRef, {
        processed: true,
        success: true,
        itemId,
      });

      await batch.commit();

      console.log(
        `[ItemPurchase] Granted ${itemId} to ${request.userId} for ${catalogItem.price} gold`
      );
    } catch (error) {
      console.error(`[ItemPurchase] Error processing purchase ${purchaseId}: ${error}`);
      try {
        await purchaseRef.update({
          processed: true,
          success: false,
          reason: 'internal_error',
        });
      } catch (updateError) {
        console.error(`[ItemPurchase] Failed to mark purchase as failed: ${updateError}`);
      }
    }
  });
