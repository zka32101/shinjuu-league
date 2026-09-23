import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shinjuu_league/data/models/user_model.dart';
import 'package:shinjuu_league/data/providers/service_providers.dart';
import 'package:shinjuu_league/services/monetization_service.dart';
import 'package:shinjuu_league/services/purchase_cohort_service.dart';
import 'package:shinjuu_league/ui/widgets/custom_button.dart';
import 'package:shinjuu_league/ui/widgets/error_retry_view.dart';

/// 表示用のスキンプール（本物のMecha/スキンカタログはFirestore側の運用データ投入待ち）
const _skinPool = [
  ('skin_east_flame', '緋焔の神獣'),
  ('skin_west_frost', '蒼氷の神獣'),
  ('skin_gold_dragon', '黄金龍装'),
  ('skin_shadow', '影纏いの装束'),
];

class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  bool _isPurchasing = false;
  final _random = Random();

  Future<void> _pullGacha(User user) async {
    final userId = user.uid;
    setState(() => _isPurchasing = true);

    final purchasesService = ref.read(purchasesServiceProvider);
    final analyticsService = ref.read(analyticsServiceProvider);
    final monetizationService = ref.read(monetizationServiceProvider);

    final offerings = await purchasesService.getOfferings();
    final package = offerings?.current?.availablePackages
        .where((p) => p.storeProduct.identifier == ProductIds.skinGacha1x)
        .firstOrNull;

    if (package == null) {
      if (!mounted) return;
      setState(() => _isPurchasing = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('現在準備中です。今しばらくお待ちください。')));
      return;
    }

    // Log purchase start
    await analyticsService.logPurchaseStart(userId, ProductIds.skinGacha1x);

    final outcome = await purchasesService.purchasePackage(package);

    if (!mounted) return;
    setState(() => _isPurchasing = false);

    if (outcome.isSuccess) {
      final (skinId, skinName) = _skinPool[_random.nextInt(_skinPool.length)];
      final updatedSkins = [...user.ownedSkinIds, skinId];
      final priceYen = monetizationService.getSkinGachaPriceYen().toDouble();

      final userViewModel = ref.read(userViewModelProvider.notifier);
      await userViewModel.updateOwnedSkins(updatedSkins);
      await analyticsService.logSkinPurchased(userId, skinId, priceYen);
      // Log detailed purchase completion
      await analyticsService.logPurchaseComplete(
        userId,
        'skin_gacha',
        priceYen,
      );
      // Advance the user's real purchase cohort (F2P -> D1/D7/D30Payer ->
      // Whale on repeat purchases), not a hardcoded 'D1Payer'.
      final now = DateTime.now();
      final nextCohort = PurchaseCohortService.nextCohortAfterPurchase(
        currentCohort:
            user.cohortProperties?.purchaseCohort ?? PurchaseCohortService.f2p,
        installDate: user.createdAt,
        now: now,
      );
      await ref
          .read(firestoreServiceProvider)
          .updateUserPurchaseCohort(userId, nextCohort);
      ref.invalidate(userViewModelProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('「$skinName」を獲得しました！')));
    } else if (outcome.isCancelled) {
      await analyticsService.logPurchaseCancelled(
        userId,
        ProductIds.skinGacha1x,
      );
    } else if (outcome.isFailure) {
      await analyticsService.logPurchaseFailed(
        userId,
        ProductIds.skinGacha1x,
        outcome.errorMessage ?? '不明なエラー',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(outcome.errorMessage ?? '購入に失敗しました')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userViewModelProvider);
    final skinGachaPriceYen = ref
        .watch(monetizationServiceProvider)
        .getSkinGachaPriceYen();

    return Scaffold(
      appBar: AppBar(title: const Text('スキンショップ')),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorRetryView(
          message: 'ユーザー情報の読み込みに失敗しました\n$e',
          onRetry: () => ref.invalidate(userViewModelProvider),
        ),
        data: (user) {
          if (user == null) return const Center(child: Text('ユーザー情報が見つかりません'));

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.shield_outlined),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'スキンは見た目のみの変更で、性能には一切影響しません（公平性保証）',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.9,
                          ),
                      itemCount: _skinPool.length,
                      itemBuilder: (context, i) {
                        final (skinId, skinName) = _skinPool[i];
                        final owned = user.ownedSkinIds.contains(skinId);
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  owned ? Icons.pets : Icons.help_outline,
                                  size: 48,
                                  color: owned
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.grey,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  owned ? skinName : '？？？',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '¥$skinGachaPriceYen でガチャを1回引く',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  CustomButton(
                    label: 'ガチャを引く',
                    icon: Icons.casino,
                    isLoading: _isPurchasing,
                    onPressed: () => _pullGacha(user),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

extension _FirstOrNullExtension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
