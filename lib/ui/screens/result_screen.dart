import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shinjuu_league/config/app_routes.dart';
import 'package:shinjuu_league/config/theme.dart';
import 'package:shinjuu_league/data/models/battle_model.dart';
import 'package:shinjuu_league/data/models/replay_model.dart';
import 'package:shinjuu_league/data/providers/service_providers.dart';
import 'package:shinjuu_league/services/audio_service.dart';
import 'package:shinjuu_league/services/haptic_service.dart';
import 'package:shinjuu_league/ui/widgets/custom_button.dart';
import 'package:shinjuu_league/ui/widgets/particle_burst.dart';

class ResultScreen extends ConsumerStatefulWidget {
  const ResultScreen({super.key, required this.battle});
  final Battle battle;

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen> {
  bool _applied = false;
  int _burstTrigger = 0;
  Replay? _replay;
  bool _isGeneratingReplay = true;

  bool get _isWin => widget.battle.result == BattleResult.win;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_applied) return;
      _applied = true;
      ref.read(userViewModelProvider.notifier).applyBattleResult(widget.battle);

      if (_isWin) {
        HapticService.onWin();
        AudioService().playWinSe();
        setState(() => _burstTrigger = 1); // スター爆発を1回再生
      } else {
        HapticService.onLoss();
        AudioService().playLossSe();
      }

      // リプレイ自動生成 → SNSシェアまでノーストレスにするため試合終了直後に生成
      final replay = await ref.read(replayServiceProvider).generateAndSave(widget.battle);
      if (!mounted) return;
      setState(() {
        _replay = replay;
        _isGeneratingReplay = false;
      });
    });
  }

  void _shareReplay() {
    final replay = _replay;
    if (replay == null) return;
    final text = ref.read(replayServiceProvider).buildShareText(widget.battle, replay);
    Share.share(text);
  }

  @override
  Widget build(BuildContext context) {
    final battle = widget.battle;
    final resultColor = _isWin ? AppColors.win : AppColors.loss;
    final selfStats = battle.playerStats.firstWhere(
      (p) => p.userId == battle.userId,
      orElse: () => battle.playerStats.first,
    );
    final mvp = battle.playerStats.isEmpty
        ? null
        : battle.playerStats.reduce((a, b) => a.score >= b.score ? a : b);
    final isSelfMvp = mvp != null && mvp.userId == battle.userId;

    return Scaffold(
      appBar: AppBar(title: const Text('リザルト'), automaticallyImplyLeading: false),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  if (_isWin) ParticleBurst(trigger: _burstTrigger, color: AppColors.gold, size: 200),
                  Column(
                    children: [
                      Text(
                        battle.result.displayName,
                        style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: resultColor),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        battle.eloChange >= 0
                            ? 'Elo +${battle.eloChange.toStringAsFixed(1)}'
                            : 'Elo ${battle.eloChange.toStringAsFixed(1)}',
                        style: TextStyle(
                          fontSize: 18,
                          color: battle.eloChange >= 0 ? AppColors.win : AppColors.loss,
                        ),
                      ),
                      if (isSelfMvp) ...[
                        const SizedBox(height: 8),
                        Chip(
                          avatar: const Icon(Icons.star, color: Colors.white, size: 18),
                          label: const Text('MVP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          backgroundColor: AppColors.gold,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _StatColumn(label: 'キル', value: '${battle.kills}'),
                      _StatColumn(label: 'デス', value: '${battle.deaths}'),
                      _StatColumn(label: 'スコア', value: '${selfStats.score}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  leading: _isGeneratingReplay
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.share),
                  title: const Text('戦績をシェア'),
                  subtitle: Text(_isGeneratingReplay ? 'リプレイ生成中…' : 'SNSでシェアする'),
                  enabled: !_isGeneratingReplay,
                  onTap: _isGeneratingReplay ? null : _shareReplay,
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
