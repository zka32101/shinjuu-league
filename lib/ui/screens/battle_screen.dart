import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shinjuu_league/config/app_config.dart';
import 'package:shinjuu_league/config/app_routes.dart';
import 'package:shinjuu_league/data/models/match_result_model.dart';
import 'package:shinjuu_league/data/providers/service_providers.dart';
import 'package:shinjuu_league/game/battlefield_game.dart';
import 'package:shinjuu_league/services/audio_service.dart';
import 'package:shinjuu_league/services/haptic_service.dart';
import 'package:shinjuu_league/ui/widgets/particle_burst.dart';

class BattleScreen extends ConsumerStatefulWidget {
  const BattleScreen({super.key, required this.match});
  final MatchResult match;

  @override
  ConsumerState<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends ConsumerState<BattleScreen> {
  final _game = BattlefieldGame();

  @override
  Widget build(BuildContext context) {
    final selfId = widget.match.teamA.isNotEmpty
        ? widget.match.teamA.first.userId
        : null;

    ref.listen(battleViewModelProvider, (previous, next) {
      // Aha Moment: 初回1キル達成の瞬間にハプティクス+SEを鳴らす
      final prevAha = previous?.ahaMomentReached ?? false;
      if (!prevAha && next.ahaMomentReached) {
        HapticService.onAhaMoment();
        AudioService().playAhaMomentSe();
      }

      // 自分がキルを取った瞬間（Aha Moment以降の追加キルも含む）に軽いハプティクス
      final prevKillCount = previous?.killFeed.length ?? 0;
      if (next.killFeed.length > prevKillCount) {
        final newEvents = next.killFeed.sublist(prevKillCount);
        for (final event in newEvents) {
          _game.onKillEvent(event.attackerId);
        }
        if (selfId != null && newEvents.any((e) => e.attackerId == selfId)) {
          HapticService.onKill();
          AudioService().playKillSe();
        }
      }

      if (next.isFinished &&
          !(previous?.isFinished ?? false) &&
          next.battle != null) {
        context.pushReplacement(AppRoutes.result, extra: next.battle);
      }
    });

    final state = ref.watch(battleViewModelProvider);
    final engine = state.engine;

    if (engine == null || selfId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    _game.sync(engine.participants);

    final selfParticipant = engine.participants.firstWhere(
      (p) => p.userId == selfId,
    );
    final remaining = AppConfig.battleDurationSeconds - state.elapsedSeconds;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          '残り ${remaining.clamp(0, AppConfig.battleDurationSeconds)}秒',
        ),
      ),
      body: Column(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: state.ahaMomentReached
                ? Container(
                    key: const ValueKey('aha-banner'),
                    width: double.infinity,
                    color: Colors.amber,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: const Text(
                      '🎉 初キル達成！',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  )
                : const SizedBox.shrink(key: ValueKey('no-banner')),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _StatChip(label: 'キル', value: '${selfParticipant.kills}'),
                    _StatChip(label: 'デス', value: '${selfParticipant.deaths}'),
                    _StatChip(
                      label: 'アシスト',
                      value: '${selfParticipant.assists}',
                    ),
                    _StatChip(label: 'スコア', value: '${selfParticipant.score}'),
                  ],
                ),
              ),
              // 自分のキル数が増えるたびにパーティクルバーストを再生（Lottie素材追加までの代替演出）
              ParticleBurst(
                trigger: selfParticipant.kills,
                color: Colors.amber,
                size: 160,
              ),
            ],
          ),
          Expanded(child: GameWidget(game: _game)),
          Container(
            height: 140,
            padding: const EdgeInsets.all(8),
            color: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            child: ListView.builder(
              reverse: true,
              itemCount: state.killFeed.length,
              itemBuilder: (context, i) {
                final event = state.killFeed[state.killFeed.length - 1 - i];
                final isSelfKill = event.attackerId == selfId;
                return Text(
                  '${event.attackerId} が ${event.victimId} を撃破',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelfKill
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
