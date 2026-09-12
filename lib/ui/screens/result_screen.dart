import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shinjuu_league/config/app_routes.dart';
import 'package:shinjuu_league/config/theme.dart';
import 'package:shinjuu_league/data/models/achievement.dart';
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
      final replay = await ref
          .read(replayServiceProvider)
          .generateAndSave(widget.battle);
      if (!mounted) return;
      setState(() {
        _replay = replay;
        _isGeneratingReplay = false;
      });
    });
  }

  void _showAchievementUnlock(Achievement achievement) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (context) => _AchievementUnlockCard(
        achievement: achievement,
      ),
    );
  }

  void _shareReplay() {
    final replay = _replay;
    if (replay == null) return;
    final text = ref
        .read(replayServiceProvider)
        .buildShareText(widget.battle, replay);
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
      appBar: AppBar(
        title: const Text('リザルト'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  if (_isWin)
                    ParticleBurst(
                      trigger: _burstTrigger,
                      color: AppColors.gold,
                      size: 200,
                    ),
                  Column(
                    children: [
                      Text(
                        battle.result.displayName,
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: resultColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        battle.eloChange >= 0
                            ? 'Elo +${battle.eloChange.toStringAsFixed(1)}'
                            : 'Elo ${battle.eloChange.toStringAsFixed(1)}',
                        style: TextStyle(
                          fontSize: 18,
                          color: battle.eloChange >= 0
                              ? AppColors.win
                              : AppColors.loss,
                        ),
                      ),
                      if (isSelfMvp) ...[
                        const SizedBox(height: 8),
                        Chip(
                          avatar: const Icon(
                            Icons.star,
                            color: Colors.white,
                            size: 18,
                          ),
                          label: const Text(
                            'MVP',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
              // Newly unlocked achievements
              Consumer(
                builder: (context, ref, child) {
                  final battleState =
                      ref.watch(battleViewModelProvider);
                  final unlockedAchievements =
                      battleState.newlyUnlockedAchievements;

                  if (unlockedAchievements.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🏆 新しい成果を解除した！',
                        style:
                            Theme.of(context).textTheme.titleSmall?.copyWith(
                                  color: AppColors.gold,
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 140,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: unlockedAchievements.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final achievement =
                                unlockedAchievements[index];
                            return _AchievementCard(
                              achievement: achievement,
                              onTap: () =>
                                  _showAchievementUnlock(achievement),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  );
                },
              ),
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
                  subtitle: Text(
                    _isGeneratingReplay ? 'リプレイ生成中…' : 'SNSでシェアする',
                  ),
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
        Text(
          value,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final Achievement achievement;
  final VoidCallback? onTap;

  const _AchievementCard({
    required this.achievement,
    this.onTap,
  });

  Color _getRewardTierColor(AchievementRewardTier tier) {
    switch (tier) {
      case AchievementRewardTier.common:
        return const Color(0xFF808080);
      case AchievementRewardTier.uncommon:
        return const Color(0xFF00AA00);
      case AchievementRewardTier.rare:
        return const Color(0xFF0099FF);
      case AchievementRewardTier.epic:
        return const Color(0xFF9933FF);
      case AchievementRewardTier.legendary:
        return const Color(0xFFFFAA00);
      case AchievementRewardTier.mythic:
        return const Color(0xFFFF0000);
      case AchievementRewardTier.silver:
        return const Color(0xFFC0C0C0);
      case AchievementRewardTier.gold:
        return const Color(0xFFFFD700);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: _getRewardTierColor(achievement.rewardTier).withOpacity(0.5),
            width: 2,
          ),
        ),
        child: Container(
          width: 120,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _getRewardTierColor(achievement.rewardTier).withOpacity(0.1),
                _getRewardTierColor(achievement.rewardTier).withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '🏆',
                style: TextStyle(fontSize: 32),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Text(
                  achievement.name,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getRewardTierColor(achievement.rewardTier)
                      .withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'タップで詳細',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        color: _getRewardTierColor(achievement.rewardTier),
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AchievementUnlockCard extends StatefulWidget {
  final Achievement achievement;

  const _AchievementUnlockCard({required this.achievement});

  @override
  State<_AchievementUnlockCard> createState() =>
      _AchievementUnlockCardState();
}

class _AchievementUnlockCardState extends State<_AchievementUnlockCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getRewardTierColor(AchievementRewardTier tier) {
    switch (tier) {
      case AchievementRewardTier.common:
        return const Color(0xFF808080);
      case AchievementRewardTier.uncommon:
        return const Color(0xFF00AA00);
      case AchievementRewardTier.rare:
        return const Color(0xFF0099FF);
      case AchievementRewardTier.epic:
        return const Color(0xFF9933FF);
      case AchievementRewardTier.legendary:
        return const Color(0xFFFFAA00);
      case AchievementRewardTier.mythic:
        return const Color(0xFFFF0000);
      case AchievementRewardTier.silver:
        return const Color(0xFFC0C0C0);
      case AchievementRewardTier.gold:
        return const Color(0xFFFFD700);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Dialog(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '🏆',
                style: TextStyle(fontSize: 48),
              ),
              const SizedBox(height: 16),
              Text(
                '成果を解除した！',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color:
                          _getRewardTierColor(widget.achievement.rewardTier),
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.achievement.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                widget.achievement.description,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('確認'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
