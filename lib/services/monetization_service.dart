import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shinjuu_league/config/feature_flags.dart';
import 'package:shinjuu_league/services/purchases_service.dart';

/// 商品 ID の定義（App Store & Google Play に登録する際に使用）
abstract class ProductIds {
  // バトルパス
  static const battlePassMonthly = 'com.petitworksapps.shinjukuleague.battlepass.monthly';

  // スキンガチャ
  static const skinGacha1x = 'com.petitworksapps.shinjukuleague.skin.gacha.1x';
  static const skinGacha10x = 'com.petitworksapps.shinjukuleague.skin.gacha.10x';

  // ブーストパック（将来の追加機能）
  static const boostPackSmall = 'com.petitworksapps.shinjukuleague.boost.small';
  static const boostPackLarge = 'com.petitworksapps.shinjukuleague.boost.large';
}

/// 購入可能な商品の定義
enum MonetizationProduct {
  battlePassMonthly('バトルパス 30日', ProductIds.battlePassMonthly),
  skinGacha1x('スキンガチャ ×1', ProductIds.skinGacha1x),
  skinGacha10x('スキンガチャ ×10', ProductIds.skinGacha10x),
  boostPackSmall('ブーストパック', ProductIds.boostPackSmall),
  boostPackLarge('ブーストパック 大', ProductIds.boostPackLarge);

  const MonetizationProduct(this.displayName, this.id);
  final String displayName;
  final String id;
}

/// 統一的な課金管理インターフェース
/// RemoteConfig の価格戦略と RevenueCat の実装を統合
class MonetizationService {
  static final MonetizationService _instance =
      MonetizationService._internal();

  factory MonetizationService() => _instance;
  MonetizationService._internal();

  final PurchasesService _purchases = PurchasesService();
  Offerings? _cachedOfferings;
  DateTime? _offeringsCachedAt;

  /// 初期化（アプリ起動時に一度だけ呼び出し）
  Future<void> init() async {
    await _purchases.configure();
  }

  /// 課金機能が有効か判定
  bool get isEnabled => FeatureFlags.isMonetizationEnabled();

  /// 利用可能な商品一覧を取得（キャッシュあり）
  Future<Offerings?> getOfferings() async {
    if (!isEnabled) return null;

    // キャッシュ有効期限: 5分
    final now = DateTime.now();
    if (_cachedOfferings != null &&
        _offeringsCachedAt != null &&
        now.difference(_offeringsCachedAt!).inMinutes < 5) {
      return _cachedOfferings;
    }

    final offerings = await _purchases.getOfferings();
    _cachedOfferings = offerings;
    _offeringsCachedAt = now;
    return offerings;
  }

  /// バトルパスの価格を取得（RemoteConfig で ABテスト可能）
  int getBattlePassPriceYen() =>
      isEnabled ? FeatureFlags.getBattlePassPrice() : 500;

  /// スキンガチャの価格を取得（RemoteConfig で ABテスト可能）
  int getSkinGachaPriceYen() =>
      isEnabled ? FeatureFlags.getSkinGachaPrice() : 300;

  /// バトルパスの期間（日数）
  int getBattlePassDurationDays() =>
      isEnabled ? FeatureFlags.getBattlePassDuration() : 30;

  /// スキンガチャの天井（回数）
  int getSkinGachaCeiling() =>
      isEnabled ? FeatureFlags.getSkinGachaCeiling() : 100;

  /// 特定の商品を購入
  /// 返り値: PurchaseOutcome（success/cancelled/failure）
  Future<PurchaseOutcome> purchaseProduct(
    MonetizationProduct product,
  ) async {
    if (!isEnabled) {
      return PurchaseOutcome.failure('課金機能は現在利用できません');
    }

    try {
      final offerings = await getOfferings();
      if (offerings == null) {
        return PurchaseOutcome.failure('商品一覧の取得に失敗しました');
      }

      // 商品 ID で Package を検索
      Package? targetPackage;
      for (final offering in offerings.all.values) {
        for (final pkg in offering.availablePackages) {
          if (pkg.identifier == product.id) {
            targetPackage = pkg;
            break;
          }
        }
        if (targetPackage != null) break;
      }

      if (targetPackage == null) {
        return PurchaseOutcome.failure(
          '商品 ${product.id} が見つかりません',
        );
      }

      return await _purchases.purchasePackage(targetPackage);
    } catch (e) {
      return PurchaseOutcome.failure('購入処理中にエラーが発生しました: $e');
    }
  }

  /// 購入履歴を復元
  Future<CustomerInfo?> restorePurchases() async {
    if (!isEnabled) return null;
    return await _purchases.restorePurchases();
  }

  /// 顧客情報を取得（購入履歴、サブスクリプション状態等）
  Future<CustomerInfo?> getCustomerInfo() async {
    if (!isEnabled) return null;
    try {
      return await Purchases.getCustomerInfo();
    } catch (_) {
      return null;
    }
  }

  /// バトルパスが有効か判定
  Future<bool> hasBattlePass() async {
    final customerInfo = await getCustomerInfo();
    if (customerInfo == null) return false;

    // entitlements でバトルパスのアクセス権を確認
    return customerInfo.entitlements.all['battle_pass']?.isActive ?? false;
  }

  /// スキンガチャのアクセス権があるか判定
  Future<bool> canGachaSkins() async {
    // スキンガチャは通常購入なので、常に可能
    // ただし基本無料ゲームなので、課金なしでも可能にする設計
    return true;
  }

  /// デバッグ用: 価格戦略をダンプ
  Map<String, dynamic> debugDumpMonetization() {
    return {
      'enabled': isEnabled,
      'battlepass_price_yen': getBattlePassPriceYen(),
      'battlepass_duration_days': getBattlePassDurationDays(),
      'skin_gacha_price_yen': getSkinGachaPriceYen(),
      'skin_gacha_ceiling': getSkinGachaCeiling(),
    };
  }
}
