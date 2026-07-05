import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shinjuu_league/config/app_config.dart';
import 'package:shinjuu_league/config/app_routes.dart';
import 'package:shinjuu_league/data/models/match_result_model.dart';
import 'package:shinjuu_league/data/providers/service_providers.dart';
import 'package:shinjuu_league/services/battle_engine_service.dart';

class BattleScreen extends ConsumerWidget {
  const BattleScreen({super.key, required this.match});
  final MatchResult match;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(battleViewModelProvider, (previous, next) {
      if (next.isFinished && (previous == null || !previous.isFinished) && next.battle != null) {
        context.pushReplacement(AppRoutes.result, extra: next.battle);
      }
    });

    final state = ref.watch(battleViewModelProvider);
    final engine = state.engine;
    final selfId = match.teamA.isNotEmpty ? match.teamA.first.userId : null;

    if (engine == null || selfId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final selfParticipant = engine.participants.firstWhere((p) => p.userId == selfId);
    final remaining = AppConfig.battleDurationSeconds - state.elapsedSeconds;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('残り ${remaining.clamp(0, AppConfig.battleDurationSeconds)}秒'),
      ),
      body: Column(
        children: [
          if (state.ahaMomentReached)
            Container(
              width: double.infinity,
              color: Colors.amber,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: const Text(
                '🎉 初キル達成！',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatChip(label: 'キル', value: '${selfParticipant.kills}'),
                _StatChip(label: 'デス', value: '${selfParticipant.deaths}'),
                _StatChip(label: 'アシスト', value: '${selfParticipant.assists}'),
                _StatChip(label: 'スコア', value: '${selfParticipant.score}'),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _LaneView(lane: 0, engine: engine)),
                const VerticalDivider(width: 1),
                Expanded(child: _LaneView(lane: 1, engine: engine)),
              ],
            ),
          ),
          Container(
            height: 140,
            padding: const EdgeInsets.all(8),
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
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
                    fontWeight: isSelfKill ? FontWeight.bold : FontWeight.normal,
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
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}

class _LaneView extends StatelessWidget {
  const _LaneView({required this.lane, required this.engine});
  final int lane;
  final BattleEngine engine;

  @override
  Widget build(BuildContext context) {
    final teamA = engine.participants.where((p) => p.team == 0 && p.lane == lane).toList();
    final teamB = engine.participants.where((p) => p.team == 1 && p.lane == lane).toList();

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Text('レーン ${lane + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...teamA.map((p) => _ParticipantRow(participant: p, color: Colors.blue)),
          const Divider(),
          ...teamB.map((p) => _ParticipantRow(participant: p, color: Colors.red)),
        ],
      ),
    );
  }
}

class _ParticipantRow extends StatelessWidget {
  const _ParticipantRow({required this.participant, required this.color});
  final BattleParticipantState participant;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            participant.isAlive ? Icons.circle : Icons.circle_outlined,
            size: 12,
            color: participant.isAlive ? color : Colors.grey,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              participant.isSelf ? '自分' : (participant.isBot ? 'Bot' : participant.userId),
              style: TextStyle(
                fontSize: 12,
                fontWeight: participant.isSelf ? FontWeight.bold : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text('${participant.kills}/${participant.deaths}', style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}
