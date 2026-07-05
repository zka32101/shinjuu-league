import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shinjuu_league/config/app_routes.dart';
import 'package:shinjuu_league/data/models/battle_model.dart';
import 'package:shinjuu_league/data/providers/service_providers.dart';
import 'package:shinjuu_league/ui/widgets/custom_button.dart';

class LobbyScreen extends ConsumerWidget {
  const LobbyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ロビー'),
        actions: [
          IconButton(
            icon: const Icon(Icons.leaderboard),
            tooltip: 'ランク',
            onPressed: () => context.push(AppRoutes.rank),
          ),
          IconButton(
            icon: const Icon(Icons.people),
            tooltip: 'フレンド',
            onPressed: () => context.push(AppRoutes.friends),
          ),
        ],
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('読み込みエラー: $e')),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('ユーザー情報が見つかりません'));
          }

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            child: Text(user.name.isNotEmpty ? user.name.substring(0, 1) : '?'),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(user.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text('Lv.${user.level} ・ Elo ${user.eloRating.toStringAsFixed(0)}'),
                                Text('勝率 ${(user.winRate * 100).toStringAsFixed(1)}% (${user.totalBattles}戦)'),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              _CurrencyChip(icon: Icons.diamond, label: '${user.gems}'),
                              const SizedBox(height: 4),
                              _CurrencyChip(icon: Icons.monetization_on, label: '${user.gold}'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Card(
                    child: ListTile(
                      leading: Icon(Icons.pets),
                      title: Text('選択中の神獣'),
                      subtitle: Text('デフォルト神獣（選択画面は今後実装）'),
                    ),
                  ),
                  const Spacer(),
                  CustomButton(
                    label: 'クイックマッチ',
                    icon: Icons.flash_on,
                    onPressed: () => context.push(AppRoutes.matching, extra: BattleMode.quick),
                  ),
                  const SizedBox(height: 12),
                  CustomButton(
                    label: 'ランクマッチ',
                    icon: Icons.military_tech,
                    isPrimary: false,
                    onPressed: () => context.push(AppRoutes.matching, extra: BattleMode.ranked),
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

class _CurrencyChip extends StatelessWidget {
  const _CurrencyChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 4),
        Text(label),
      ],
    );
  }
}
