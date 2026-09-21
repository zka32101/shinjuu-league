import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shinjuu_league/data/providers/service_providers.dart';
import 'package:shinjuu_league/ui/screens/season_rewards_screen.dart';

/// Resolves the signed-in user before handing off to [SeasonRewardsScreen],
/// which requires an explicit userId rather than resolving it itself.
/// Kept as a thin route-level wrapper so SeasonRewardsScreen's own API
/// (and its future reuse from other contexts with a known userId) stays
/// unchanged.
class SeasonRewardsRouteScreen extends ConsumerWidget {
  const SeasonRewardsRouteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userViewModelProvider);

    return userAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('季節報酬')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('季節報酬')),
        body: Center(child: Text('ユーザー情報の取得に失敗しました\n$error')),
      ),
      data: (user) {
        if (user == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('季節報酬')),
            body: const Center(child: Text('ユーザー情報が見つかりません')),
          );
        }
        return SeasonRewardsScreen(userId: user.uid);
      },
    );
  }
}
