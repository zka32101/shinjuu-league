import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shinjuu_league/config/app_config.dart';
import 'package:shinjuu_league/config/theme.dart';
import 'package:shinjuu_league/data/models/battlepass_model.dart';
import 'package:shinjuu_league/data/providers/service_providers.dart';
import 'package:shinjuu_league/ui/widgets/custom_button.dart';
import 'package:shinjuu_league/ui/widgets/error_retry_view.dart';

/// 表示用の報酬トラック（本物のシーズン報酬データはFirestore側の運用データ投入待ち）
const _rewardTiers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];

class BattlePassScreen extends ConsumerStatefulWidget {
  const BattlePassScreen({super.key});

  @override
  ConsumerState<BattlePassScreen> createState() => _BattlePassScreenState();
}

class _BattlePassScreenState extends ConsumerState<BattlePassScreen> {
  bool _isPurchasing = false;

  Future<void> _purchase(String userId) async {
    setState(() => _isPurchasing = true);

    final purchasesService = ref.read(purchasesServiceProvider);
    final offerings = await purchasesService.getOfferings();
    final package = offerings?.current?.availablePackages
        .where(
          (p) => p.storeProduct.identifier == AppConfig.battlePassProductId,
        )
        .firstOrNull;

    if (package == null) {
      if (!mounted) return;
      setState(() => _isPurchasing = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('現在準備中です。今しばらくお待ちください。')));
      return;
    }

    final outcome = await purchasesService.purchasePackage(package);

    if (!mounted) return;
    setState(() => _isPurchasing = false);

    if (outcome.isSuccess) {
      final now = DateTime.now();
      final battlePass = BattlePass(
        seasonId: AppConfig.currentSeasonId,
        userId: userId,
        progress: 0,
        level: 1,
        claimedRewards: const [],
        isPremium: true,
        startDate: now,
        endDate: now.add(const Duration(days: 90)),
      );
      await ref.read(firestoreServiceProvider).saveBattlePass(battlePass);
      await ref
          .read(analyticsServiceProvider)
          .logBattlePassPurchased(userId, AppConfig.battlePassPrice);
      ref.invalidate(battlePassProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('プレミアムパスを購入しました！')));
    } else if (outcome.isFailure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(outcome.errorMessage ?? '購入に失敗しました')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userViewModelProvider);
    final battlePassAsync = ref.watch(battlePassProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('バトルパス')),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorRetryView(
          message: 'ユーザー情報の読み込みに失敗しました\n$e',
          onRetry: () => ref.invalidate(userViewModelProvider),
        ),
        data: (user) {
          if (user == null) return const Center(child: Text('ユーザー情報が見つかりません'));

          final battlePass = battlePassAsync.value;
          final isPremium = battlePass?.isPremium ?? false;
          final progress = battlePass?.progress ?? 0;

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    color: AppColors.gold.withOpacity(0.15),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.workspace_premium,
                                color: AppColors.gold,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isPremium
                                    ? 'プレミアムパス加入中'
                                    : 'シーズン${AppConfig.currentSeasonId}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          LinearProgressIndicator(value: progress / 100),
                          const SizedBox(height: 4),
                          Text('進捗 $progress / 100'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.separated(
                      itemCount: _rewardTiers.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final tier = _rewardTiers[i];
                        final unlocked = progress >= tier * 10;
                        return Card(
                          child: ListTile(
                            leading: Icon(
                              unlocked
                                  ? Icons.check_circle
                                  : Icons.lock_outline,
                              color: unlocked ? AppColors.win : Colors.grey,
                            ),
                            title: Text('Tier $tier 報酬'),
                            subtitle: Text(
                              tier % 3 == 0 ? 'スキン（プレミアム限定）' : 'ジェム・コスメティック',
                            ),
                            trailing: tier % 3 == 0 && !isPremium
                                ? const Icon(
                                    Icons.workspace_premium,
                                    color: AppColors.gold,
                                    size: 18,
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
                  if (!isPremium) ...[
                    const SizedBox(height: 8),
                    Text(
                      '¥${AppConfig.battlePassPrice.toStringAsFixed(0)} で全報酬を解放（性能差は一切ありません）',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    CustomButton(
                      label: 'プレミアムパスを購入',
                      icon: Icons.workspace_premium,
                      isLoading: _isPurchasing,
                      onPressed: () => _purchase(user.uid),
                    ),
                  ],
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
