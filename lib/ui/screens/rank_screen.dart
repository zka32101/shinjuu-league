import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shinjuu_league/config/theme.dart';
import 'package:shinjuu_league/data/providers/service_providers.dart';
import 'package:shinjuu_league/ui/widgets/error_retry_view.dart';

class RankScreen extends ConsumerWidget {
  const RankScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboardAsync = ref.watch(leaderboardProvider);
    final currentUser = ref.watch(userViewModelProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('ランキング')),
      body: leaderboardAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorRetryView(
          message: 'ランキングの読み込みに失敗しました\n$e',
          onRetry: () => ref.invalidate(leaderboardProvider),
        ),
        data: (users) {
          if (users.isEmpty) {
            return const Center(child: Text('まだランキングデータがありません'));
          }
          return ListView.separated(
            itemCount: users.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final user = users[i];
              final isMe = currentUser != null && user.uid == currentUser.uid;
              return ListTile(
                tileColor: isMe ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3) : null,
                leading: CircleAvatar(
                  backgroundColor: i < 3 ? AppColors.gold : Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Text('${i + 1}'),
                ),
                title: Text(user.name, style: TextStyle(fontWeight: isMe ? FontWeight.bold : FontWeight.normal)),
                subtitle: Text('勝率 ${(user.winRate * 100).toStringAsFixed(1)}%'),
                trailing: Text(
                  'Elo ${user.eloRating.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
