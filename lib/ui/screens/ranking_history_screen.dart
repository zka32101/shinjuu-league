import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shinjuu_league/data/providers/service_providers.dart';
import 'package:shinjuu_league/ui/widgets/error_retry_view.dart';
import 'package:shinjuu_league/ui/widgets/ranking_history_widget.dart';
import 'package:shinjuu_league/viewmodels/ranking_history_viewmodel.dart';

/// Shows the signed-in player's rating/tier progression across every
/// season they've played (season-over-season), distinct from
/// SeasonProgressScreen which shows progress within the *current* season
/// only. Resolves the current user the same way MechaSelectScreen does,
/// so this screen needs no route parameter.
class RankingHistoryScreen extends ConsumerWidget {
  const RankingHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userViewModelProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('ランク推移')),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorRetryView(message: 'ユーザー情報の取得に失敗しました'),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('ユーザー情報が見つかりません'));
          }
          return Consumer(
            builder: (context, ref, _) {
              final historyAsync = ref.watch(rankingHistoryProvider(user.uid));
              return historyAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => ErrorRetryView(
                  message: 'ランク推移の取得に失敗しました',
                  onRetry: () =>
                      ref.invalidate(rankingHistoryProvider(user.uid)),
                ),
                data: (entries) => RankingHistoryWidget(entries: entries),
              );
            },
          );
        },
      ),
    );
  }
}
