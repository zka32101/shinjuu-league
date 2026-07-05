import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shinjuu_league/config/app_routes.dart';
import 'package:shinjuu_league/config/theme.dart';
import 'package:shinjuu_league/data/models/battle_model.dart';
import 'package:shinjuu_league/data/providers/service_providers.dart';
import 'package:shinjuu_league/ui/widgets/custom_button.dart';

class ResultScreen extends ConsumerStatefulWidget {
  const ResultScreen({super.key, required this.battle});
  final Battle battle;

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen> {
  bool _applied = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_applied) return;
      _applied = true;
      ref.read(userViewModelProvider.notifier).applyBattleResult(widget.battle);
    });
  }

  @override
  Widget build(BuildContext context) {
    final battle = widget.battle;
    final isWin = battle.result == BattleResult.win;
    final resultColor = isWin ? AppColors.win : AppColors.loss;

    return Scaffold(
      appBar: AppBar(title: const Text('リザルト'), automaticallyImplyLeading: false),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text(
                battle.result.displayName,
                style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: resultColor),
              ),
              const SizedBox(height: 8),
              Text(
                battle.eloChange >= 0 ? 'Elo +${battle.eloChange.toStringAsFixed(1)}' : 'Elo ${battle.eloChange.toStringAsFixed(1)}',
                style: TextStyle(
                  fontSize: 18,
                  color: battle.eloChange >= 0 ? AppColors.win : AppColors.loss,
                ),
              ),
              const SizedBox(height: 32),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _StatColumn(label: 'キル', value: '${battle.kills}'),
                      _StatColumn(label: 'デス', value: '${battle.deaths}'),
                      _StatColumn(
                        label: 'スコア',
                        value: '${battle.playerStats.firstWhere((p) => p.userId == battle.userId, orElse: () => battle.playerStats.first).score}',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Card(
                child: ListTile(
                  leading: Icon(Icons.videocam_outlined),
                  title: Text('リプレイシェア'),
                  subtitle: Text('近日公開予定'),
                  enabled: false,
                ),
              ),
              const Spacer(),
              CustomButton(
                label: 'ロビーへ戻る',
                onPressed: () => context.go(AppRoutes.lobby),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
