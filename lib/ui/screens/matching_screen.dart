import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shinjuu_league/config/app_routes.dart';
import 'package:shinjuu_league/data/models/battle_model.dart';
import 'package:shinjuu_league/data/providers/service_providers.dart';
import 'package:shinjuu_league/ui/widgets/custom_button.dart';
import 'package:shinjuu_league/ui/widgets/loading_skeleton.dart';

class MatchingScreen extends ConsumerStatefulWidget {
  const MatchingScreen({super.key, required this.mode});
  final BattleMode mode;

  @override
  ConsumerState<MatchingScreen> createState() => _MatchingScreenState();
}

class _MatchingScreenState extends ConsumerState<MatchingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startMatching());
  }

  void _startMatching() {
    final currentUser = ref.read(userViewModelProvider).value;
    if (currentUser == null) return;
    ref.read(matchingViewModelProvider.notifier).startMatching(currentUser, widget.mode);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(matchingViewModelProvider, (previous, next) {
      if (next.matchResult != null) {
        context.pushReplacement(AppRoutes.evolution, extra: next.matchResult);
      }
    });

    final state = ref.watch(matchingViewModelProvider);

    return Scaffold(
      appBar: AppBar(title: Text('${widget.mode.displayName}マッチング')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (state.error != null) ...[
                Text(state.error!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 24),
                CustomButton(label: 'ロビーへ戻る', onPressed: () => context.pop()),
              ] else ...[
                const LoadingSkeleton(width: 120, height: 120, borderRadius: 60),
                const SizedBox(height: 24),
                Text('対戦相手を探しています…', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text('${state.elapsedSeconds}秒経過', style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 32),
                CustomButton(
                  label: 'キャンセル',
                  isPrimary: false,
                  onPressed: () {
                    ref.read(matchingViewModelProvider.notifier).cancelMatching();
                    context.pop();
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
