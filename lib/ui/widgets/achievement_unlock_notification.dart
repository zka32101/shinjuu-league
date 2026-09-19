import 'package:flutter/material.dart';
import 'package:shinjuu_league/data/models/achievement.dart';
import 'package:shinjuu_league/config/theme.dart';

/// Dialog showing achievement unlock notification
class AchievementUnlockNotification extends StatefulWidget {
  final Achievement achievement;
  final PlayerAchievement playerAchievement;
  final VoidCallback? onDismiss;
  final Duration displayDuration;

  const AchievementUnlockNotification({
    Key? key,
    required this.achievement,
    required this.playerAchievement,
    this.onDismiss,
    this.displayDuration = const Duration(seconds: 4),
  }) : super(key: key);

  @override
  State<AchievementUnlockNotification> createState() =>
      _AchievementUnlockNotificationState();
}

class _AchievementUnlockNotificationState
    extends State<AchievementUnlockNotification>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();

    // Auto-dismiss after duration
    Future.delayed(widget.displayDuration, () {
      if (mounted) {
        _animationController.reverse().then((_) {
          if (mounted) {
            Navigator.of(context).pop();
            widget.onDismiss?.call();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rewardTier = widget.achievement.rewardTier;
    final tierColors = {
      AchievementRewardTier.bronze: const Color(0xFFCD7F32),
      AchievementRewardTier.silver: const Color(0xFFC0C0C0),
      AchievementRewardTier.gold: const Color(0xFFFFD700),
      AchievementRewardTier.platinum: const Color(0xFFE5E4E2),
    };

    final tierEmojis = {
      AchievementRewardTier.bronze: '🥉',
      AchievementRewardTier.silver: '🥈',
      AchievementRewardTier.gold: '🥇',
      AchievementRewardTier.platinum: '👑',
    };

    return ScaleTransition(
      scale: _scaleAnimation,
      child: FadeTransition(
        opacity: _opacityAnimation,
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tier badge with glow
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: tierColors[rewardTier]?.withOpacity(0.6) ??
                            Colors.yellow.withOpacity(0.6),
                        blurRadius: 24,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: tierColors[rewardTier] ?? Colors.yellow,
                      border: Border.all(
                        color: Colors.white,
                        width: 3,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        tierEmojis[rewardTier] ?? '⭐',
                        style: const TextStyle(fontSize: 48),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Achievement card
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: tierColors[rewardTier] ?? Colors.yellow,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: tierColors[rewardTier]?.withOpacity(0.3) ??
                            Colors.yellow.withOpacity(0.3),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Header
                      Text(
                        '🎉 新しい成果を解除した！',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: Colors.amber.shade700,
                              letterSpacing: 1.2,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),

                      // Achievement name
                      Text(
                        widget.achievement.name,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),

                      // Achievement description
                      Text(
                        widget.achievement.description,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),

                      // Reward info
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '獲得報酬',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                // Currency reward
                                Column(
                                  children: [
                                    Text(
                                      '💰',
                                      style: Theme.of(context).textTheme.headlineSmall,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '+${widget.achievement.getRewardCurrency()}',
                                      style:
                                          Theme.of(context).textTheme.labelMedium?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                    ),
                                  ],
                                ),

                                // Badge reward
                                Column(
                                  children: [
                                    Text(
                                      '🏅',
                                      style: Theme.of(context).textTheme.headlineSmall,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '+${widget.achievement.getRewardBadges()}',
                                      style:
                                          Theme.of(context).textTheme.labelMedium?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      if (widget.achievement.isProgressBased &&
                          widget.playerAchievement.progress != null) ...[
                        const SizedBox(height: 16),
                        // Progress bar for progress-based achievements
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '進捗',
                                  style: Theme.of(context).textTheme.labelSmall,
                                ),
                                Text(
                                  '${widget.playerAchievement.progress!.current}/${widget.playerAchievement.progress!.target}',
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: widget.playerAchievement.progress!.percentage / 100,
                                minHeight: 6,
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.2),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  tierColors[rewardTier] ?? Colors.yellow,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Dismiss hint
                Text(
                  '自動で消えます...',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Show achievement unlock notification dialog
Future<void> showAchievementUnlock(
  BuildContext context,
  Achievement achievement,
  PlayerAchievement playerAchievement, {
  VoidCallback? onDismiss,
  Duration displayDuration = const Duration(seconds: 4),
}) {
  return showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withOpacity(0.3),
    builder: (context) => AchievementUnlockNotification(
      achievement: achievement,
      playerAchievement: playerAchievement,
      onDismiss: onDismiss,
      displayDuration: displayDuration,
    ),
  );
}
