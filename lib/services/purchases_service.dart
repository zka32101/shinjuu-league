import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shinjuu_league/config/app_config.dart';

enum PurchaseStatus { success, cancelled, failure }

class PurchaseOutcome {
  const PurchaseOutcome._(this.status, {this.customerInfo, this.errorMessage});

  factory PurchaseOutcome.success(CustomerInfo info) =>
      PurchaseOutcome._(PurchaseStatus.success, customerInfo: info);
  factory PurchaseOutcome.cancelled() =>
      const PurchaseOutcome._(PurchaseStatus.cancelled);
  factory PurchaseOutcome.failure(String message) =>
      PurchaseOutcome._(PurchaseStatus.failure, errorMessage: message);

  final PurchaseStatus status;
  final CustomerInfo? customerInfo;
  final String? errorMessage;

  bool get isSuccess => status == PurchaseStatus.success;
  bool get isCancelled => status == PurchaseStatus.cancelled;
  bool get isFailure => status == PurchaseStatus.failure;
}

/// RevenueCat 実配線。App Store Connect / Google Play Console 側の商品登録・
/// APIキー発行はまだ未実施（ストア審査前に配布キー管理システムから投入予定）。
/// 未設定の状態では課金機能全体を安全に無効化する（クラッシュしない）。
class PurchasesService {
  static final PurchasesService _instance = PurchasesService._internal();
  factory PurchasesService() => _instance;
  PurchasesService._internal();

  bool _configured = false;
  bool get isConfigured => _configured;

  Future<void> configure() async {
    if (_configured) return;
    if (AppConfig.revenueCatApiKey.isEmpty) return;

    try {
      await Purchases.configure(
        PurchasesConfiguration(AppConfig.revenueCatApiKey),
      );
      _configured = true;
    } catch (_) {
      // 設定失敗時は課金機能を無効化した状態で継続
    }
  }

  Future<Offerings?> getOfferings() async {
    if (!_configured) return null;
    try {
      return await Purchases.getOfferings();
    } catch (_) {
      return null;
    }
  }

  Future<PurchaseOutcome> purchasePackage(Package package) async {
    try {
      final customerInfo = await Purchases.purchasePackage(package);
      return PurchaseOutcome.success(customerInfo);
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        return PurchaseOutcome.cancelled();
      }
      return PurchaseOutcome.failure(e.message ?? '購入に失敗しました');
    } catch (e) {
      return PurchaseOutcome.failure('$e');
    }
  }

  Future<CustomerInfo?> restorePurchases() async {
    if (!_configured) return null;
    try {
      return await Purchases.restorePurchases();
    } catch (_) {
      return null;
    }
  }
}
