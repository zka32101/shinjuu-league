import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shinjuu_league/config/app_config.dart';
import 'package:shinjuu_league/config/app_routes.dart';
import 'package:shinjuu_league/data/models/match_result_model.dart';
import 'package:shinjuu_league/data/models/skill_catalog.dart';
import 'package:shinjuu_league/data/providers/service_providers.dart';
import 'package:shinjuu_league/game/battlefield_game.dart';
import 'package:shinjuu_league/services/audio_service.dart';
import 'package:shinjuu_league/services/battle_engine_service.dart';
import 'package:shinjuu_league/services/battle_skill_progression_coordinator.dart';
import 'package:shinjuu_league/services/haptic_service.dart';
import 'package:shinjuu_league/ui/widgets/battle_action_cluster.dart';
import 'package:shinjuu_league/ui/widgets/minimap.dart';
import 'package:shinjuu_league/ui/widgets/particle_burst.dart';
import 'package:shinjuu_league/ui/widgets/resource_hud.dart';
import 'package:shinjuu_league/ui/widgets/skill_progression_display.dart';
import 'package:shinjuu_league/viewmodels/battle_viewmodel.dart';
import 'package:shinjuu_league/services/skill_system_service.dart';

class BattleScreen extends ConsumerStatefulWidget {
  const BattleScreen({super.key, required this.match});
  final MatchResult match;

  @override
  ConsumerState<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends ConsumerState<BattleScreen> {
  late final BattlefieldGame _game;

  @override
  void initState() {
    super.initState();
    _game = BattlefieldGame(mapId: widget.match.mapId);
    // バトルBGMを開始
    AudioService().playBgm('battle_bgm');
  }

  @override
  void dispose() {
    _game.attackTargetId.dispose();
    _game.minimapEntries.dispose();
    // バトル画面を離れるときはBGMを停止
    AudioService().stopBgm();
    super.dispose();
  }

  void _onSkillTap(String skillId) {
    // targets パラメータは無視、ゲーム側で再度計算する（設計上の一貫性）
    final targets = _game.enemiesWithinSkillRadius();
    final viewModel = ref.read(battleViewModelProvider.notifier);
    final activated = viewModel.attemptManualSkill(targets);

    // クールダウン中は何も起きていないため、演出・SEも鳴らさない
    // （鳴らすと「押したのに何も起きていない」のに効果音だけ鳴る見せかけの操作感になる）
    if (!activated) {
      HapticService.onButtonTap();
      return;
    }

    HapticService.onSkillActivate();

    // スキルの種別を取得して、視覚効果＋音響効果に反映
    final skillDef = SkillSystemService.getSkillDefinition(skillId);
    _game.onSkillActivate(skillType: skillDef?.type);

    // スキルタイプ別の効果音を再生
    if (skillDef != null) {
      AudioService().playSkillSe(skillDef.type);
    }
  }

  Widget _buildSkillProgressionAndKillFeed(
    BuildContext context,
    BattleState state,
    String? selfId,
  ) {
    final selfSkillState = selfId != null
        ? state.skillProgressionStates[selfId]
        : null;

    // 横画面で画面高さが小さい端末（この試合画面の想定操作向き）でも
    // Expanded(GameWidget) の取り分を残すため、固定200dpではなく画面高さに
    // 応じて縮める（最小100dp・最大200dp）。
    final panelHeight = MediaQuery.of(context).size.height * 0.28;
    return Container(
      height: panelHeight.clamp(100, 200),
      padding: const EdgeInsets.all(12),
      color: Theme.of(context)
          .colorScheme.surfaceContainerHighest
          .withValues(alpha: 0.3),
      child: Column(
        children: [
          // スキル進行パネル
          if (selfSkillState != null)
            Expanded(
              child: SingleChildScrollView(
                child: SkillProgressionPanel(
                  currentLevel: selfSkillState.currentLevel,
                  skillCooldowns: selfSkillState.skillCooldowns,
                  skillDamages: {
                    SkillSlot.q: 200,
                    SkillSlot.r: 180,
                    SkillSlot.e: 150,
                    SkillSlot.ult: selfSkillState.isUltAvailable ? 500 : 0,
                  },
                  currentEvolution: selfSkillState.currentEvolution,
                  evolutionBonuses: selfSkillState.evolutionBonuses,
                  isUltAvailable: selfSkillState.isUltAvailable,
                  isUltCharging: selfSkillState.isUltCharging,
                  onSkillTap: (slot) {
                    // スキルタップハンドラ（将来の拡張用）
                  },
                ),
              ),
            ),
          const SizedBox(height: 8),
          // キルフィード
          Expanded(
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

  void _showEvolutionSelectionDialog(
    BuildContext context,
    EvolutionSelectionRequiredEvent event,
    String selfId,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('進化を選択'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Lv${event.level}に達しました！進化を選択してください。'),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              children: [
                for (final choice in event.availableChoices)
                  ElevatedButton(
                    onPressed: () {
                      ref
                          .read(battleViewModelProvider.notifier)
                          .confirmEvolution(selfId, choice);
                      Navigator.pop(context);
                    },
                    child: Text(_getEvolutionLabel(choice)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );

    // 10秒後に自動確認（オフェンシブを自動選択）
    Future.delayed(const Duration(seconds: 10), () {
      if (context.mounted) {
        Navigator.pop(context);
        ref
            .read(battleViewModelProvider.notifier)
            .autoConfirmEvolution(selfId);
      }
    });
  }

  String _getEvolutionLabel(EvolutionType evolution) {
    switch (evolution) {
      case EvolutionType.offensive:
        return '⚔️ 攻撃';
      case EvolutionType.defensive:
        return '🛡️ 防御';
      case EvolutionType.support:
        return '🤝 支援';
    }
  }

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
          _game.onKillEvent(event.attackerId, event.victimId);
        }
        if (selfId != null && newEvents.any((e) => e.attackerId == selfId)) {
          HapticService.onKill();
          AudioService().playKillSe();
        }
      }

      // 撃破に至らない被弾（HP削り）の軽い反応
      final prevHitCount = previous?.hitFeed.length ?? 0;
      if (next.hitFeed.length > prevHitCount) {
        for (final event in next.hitFeed.sublist(prevHitCount)) {
          _game.onHitEvent(event.victimId);
        }
      }

      // ジャングルモンスター討伐：討伐者へバフ演出+SEを再生
      final prevMonsterKillCount = previous?.monsterKillFeed.length ?? 0;
      if (next.monsterKillFeed.length > prevMonsterKillCount) {
        for (final event
            in next.monsterKillFeed.sublist(prevMonsterKillCount)) {
          _game.onMonsterKillEvent(event.killerId, event.monsterId);
        }
        if (selfId != null &&
            next.monsterKillFeed
                .sublist(prevMonsterKillCount)
                .any((e) => e.killerId == selfId)) {
          HapticService.onKill();
          AudioService().playKillSe();
        }
      }

      // ダメージ数値表示＋音響フィードバック
      final prevDamageCount = previous?.damageEvents.length ?? 0;
      if (next.damageEvents.length > prevDamageCount) {
        for (final event in next.damageEvents.sublist(prevDamageCount)) {
          _game.onDamageEvent(event.victimId, event.damage, event.isCritical);

          // クリティカルヒット時は特殊音声、通常被弾は音声なし
          if (event.isCritical) {
            AudioService().playCriticalHitSe();
          }
        }
      }

      if (next.isFinished &&
          !(previous?.isFinished ?? false) &&
          next.battle != null) {
        context.pushReplacement(AppRoutes.result, extra: next.battle);
      }

      // レベルアップ演出の瞬間にハプティクス+SEを鳴らす
      final prevShowLevelUp = previous?.showLevelUpAnimation ?? false;
      if (!prevShowLevelUp && next.showLevelUpAnimation) {
        HapticService.onLevelUp();
        AudioService().playLevelUpSe();
      }

      // スキル進行イベント処理：進化選択画面が必要な場合
      final prevEvolutionEvent = previous?.pendingEvolutionSelectEvent;
      final nextEvolutionEvent = next.pendingEvolutionSelectEvent;
      if (prevEvolutionEvent == null && nextEvolutionEvent != null) {
        _showEvolutionSelectionDialog(context, nextEvolutionEvent, selfId!);
      }
    });

    final state = ref.watch(battleViewModelProvider);
    final engine = state.engine;

    if (engine == null || selfId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    _game.sync(engine.participants);
    _game.syncMonsters(engine.jungleMonsters);

    BattleParticipantState? selfParticipant;
    try {
      selfParticipant = engine.participants.firstWhere(
        (p) => p.userId == selfId,
      );
    } catch (_) {
      selfParticipant = null;
    }

    if (selfParticipant == null) {
      return const Scaffold(
        body: Center(child: Text('プレイヤー情報が見つかりません')),
      );
    }
    final remaining = AppConfig.battleDurationSeconds - state.elapsedSeconds;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          '残り ${remaining.clamp(0, AppConfig.battleDurationSeconds)}秒',
        ),
        // ステージ名を表示：mapIdごとに異なる配色のバトルフィールドであることを伝える
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(20),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              _game.stage.name,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // マナ/ゴール/アイテム・キル統計・初キルバナーは以前 Column 内で
          // GameWidget の「上」に縦積みされており、横画面（このゲームの
          // 想定操作向き）だと画面高さがわずか300dp強しかない端末では
          // それだけで画面をほぼ埋め尽くし、Expanded(GameWidget) に残る
          // 高さが0近くまで潰れて戦場が実質見えなくなっていた
          // （ミニマップ/操作クラスタは元々 GameWidget の Stack 内に
          // Positioned で重ねられており影響を受けていなかった）。
          // 同じオーバーレイ方式に統一し、GameWidget が常に画面の
          // 残り全高を使えるようにする。
          Expanded(
            child: Stack(
              children: [
                GameWidget(game: _game),
                // 初キル達成バナー（ゲーム画面最上部に重ねる）
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: AnimatedSwitcher(
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
                ),
                // キル/デス/アシスト/スコア（左上に小さく重ねる。従来は横一杯に
                // spaceEvenly 配置していたが、オーバーレイ化に伴いミニマップ
                // 等と衝突しないよう左寄せのコンパクト表示に変更）
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _StatChip(label: 'キル', value: '${selfParticipant.kills}'),
                        const SizedBox(width: 10),
                        _StatChip(label: 'デス', value: '${selfParticipant.deaths}'),
                        const SizedBox(width: 10),
                        _StatChip(
                          label: 'アシスト',
                          value: '${selfParticipant.assists}',
                        ),
                        const SizedBox(width: 10),
                        _StatChip(label: 'スコア', value: '${selfParticipant.score}'),
                      ],
                    ),
                  ),
                ),
                // 自分のキル数が増えるたびにパーティクルバーストを再生（Lottie素材追加までの代替演出）
                Positioned(
                  top: 12,
                  left: 12,
                  child: ParticleBurst(
                    trigger: selfParticipant.kills,
                    color: Colors.amber,
                    size: 160,
                  ),
                ),
                // リソース表示：マナ・ゴール・アイテム（左下に重ねる。半透明背景で
                // ゲーム画面上でも視認できるようにする）
                if (state.skillBuild != null && state.playerResources != null)
                  Positioned(
                    left: 12,
                    bottom: 12,
                    width: 220,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ResourceHUD(
                        resources: state.playerResources!,
                        elapsedSeconds: state.elapsedSeconds,
                        ownedItemIds: state.playerResources!.ownedItemIds,
                        onItemPurchase: (itemId) {
                          ref
                              .read(battleViewModelProvider.notifier)
                              .attemptPurchaseItem(itemId);
                        },
                      ),
                    ),
                  ),
                // レベルアップアニメーション（画面上部）
                if (state.showLevelUpAnimation)
                  Positioned(
                    top: 100,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: CharacterLevelDisplay(
                        currentLevel: state.skillProgressionStates[selfId]?.currentLevel ?? 1,
                        showAnimation: true,
                        currentEvolution: state.skillProgressionStates[selfId]?.currentEvolution,
                      ),
                    ),
                  ),
                // ミニマップ：マップ全体を歩き回れるため、戦況把握を助ける俯瞰表示
                Positioned(
                  top: 12,
                  right: 12,
                  child: ValueListenableBuilder<List<MinimapEntry>>(
                    valueListenable: _game.minimapEntries,
                    builder: (context, entries, _) {
                      return Minimap(entries: entries);
                    },
                  ),
                ),
                // 操作クラスタ：通常攻撃(大)+スキル(小)をUNITE風に1つにまとめて配置
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: ValueListenableBuilder<AttackTarget?>(
                    valueListenable: _game.attackTargetId,
                    builder: (context, target, _) {
                      final skillDef = state.skillBuild != null
                          ? SkillSystemService.getSkillDefinition(
                              state.skillBuild!.skillId1,
                            )
                          : null;

                      return BattleActionCluster(
                        attackTarget: target,
                        onAttackTap: () {
                          if (target == null) return;
                          HapticService.onButtonTap();
                          final notifier = ref.read(
                            battleViewModelProvider.notifier,
                          );
                          if (target.isMonster) {
                            notifier.attemptAttackMonster(target.id);
                          } else {
                            notifier.attemptManualAttack(target.id);
                          }
                        },
                        skillType: skillDef?.type,
                        skillCooldownRemaining: state.skillCooldownRemaining,
                        skillCooldownMax: BattleViewModel.manualSkillCooldownSeconds,
                        onSkillTap: () => _onSkillTap(state.skillBuild!.skillId1),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // スキル進行パネル＆キルフィードを表示
          _buildSkillProgressionAndKillFeed(context, state, selfId),
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
