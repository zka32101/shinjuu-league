import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/season_model.dart';
import '../../viewmodels/season_viewmodel.dart';
import '../../viewmodels/ranking_progress_viewmodel.dart';
import '../widgets/loading_skeleton.dart';
import '../widgets/error_retry_view.dart';
import 'package:go_router/go_router.dart';

/// Main seasonal progression UI screen
///
/// Displays:
/// - Current season info (name, timeline)
/// - Tier and rating display
/// - Progress bar to next tier
/// - Earned and claimed rewards
/// - Tier ladder overview
class SeasonProgressScreen extends ConsumerWidget {
  const SeasonProgressScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seasonState = ref.watch(currentSeasonViewModelProvider);
    final ladderState = ref.watch(rankingProgressViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seasonal Progress'),
        elevation: 0,
      ),
      body: seasonState.when(
        loading: () => const LoadingSkeleton(),
        error: (err, stack) => ErrorRetryView(
          error: err,
          onRetry: () => ref.refresh(currentSeasonViewModelProvider),
        ),
        data: (progress) {
          if (progress == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.inbox, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No active season'),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                // Season header
                _SeasonHeader(season: progress.season),
                const SizedBox(height: 16),

                // Tier and rating card
                _TierCard(progress: progress, ladderState: ladderState),
                const SizedBox(height: 16),

                // Progress bar
                _ProgressBar(progress: progress),
                const SizedBox(height: 16),

                // Earned rewards section
                if (progress.earnedRewardPreviews.isNotEmpty)
                  _RewardsSection(progress: progress),

                // Tier ladder section
                _TierLadderSection(ladderState: ladderState),

                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Season header with name and timeline
class _SeasonHeader extends StatelessWidget {
  final RankedSeason season;

  const _SeasonHeader({required this.season});

  @override
  Widget build(BuildContext context) {
    final daysRemaining = season.endsAt.difference(DateTime.now()).inDays;
    final startFormatted = _formatDate(season.startedAt);
    final endFormatted = _formatDate(season.endsAt);

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            season.name,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 16),
              const SizedBox(width: 8),
              Text(
                '$startFormatted - $endFormatted',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (daysRemaining > 0)
            Row(
              children: [
                const Icon(Icons.hourglass_bottom, size: 16, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  '$daysRemaining days remaining',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            )
          else if (daysRemaining == 0)
            Row(
              children: [
                const Icon(Icons.warning, size: 16, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  'Season ending today!',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            )
          else
            Text(
              'Season ended',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey,
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}';
  }
}

/// Tier and current rating display
class _TierCard extends ConsumerWidget {
  final SeasonalProgress progress;
  final AsyncValue<TierLadderState?> ladderState;

  const _TierCard({
    required this.progress,
    required this.ladderState,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _getTierGradient(progress.userData.currentTier),
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _getTierColor(progress.userData.currentTier).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            _getTierEmoji(progress.userData.currentTier),
            style: const TextStyle(fontSize: 48),
          ),
          const SizedBox(height: 12),
          Text(
            progress.userData.currentTier,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  'Current Rating',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  progress.userData.currentRating.toString(),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (ladderState.maybeWhen(
            data: (ladder) => ladder?.isDemotionRisk ?? false,
            orElse: () => false,
          ))
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.3),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '⚠️ Demotion Risk',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Color> _getTierGradient(String tier) {
    switch (tier) {
      case 'Bronze':
        return [const Color(0xFFB87333), const Color(0xFF8B5A2B)];
      case 'Silver':
        return [const Color(0xFFC0C0C0), const Color(0xFF808080)];
      case 'Gold':
        return [const Color(0xFFFFD700), const Color(0xFFDAA520)];
      case 'Platinum':
        return [const Color(0xFFE5E4E2), const Color(0xFFA8A9AD)];
      case 'Legend':
        return [const Color(0xFFFF6B6B), const Color(0xFFEE5A6F)];
      default:
        return [Colors.blue, Colors.blueAccent];
    }
  }

  Color _getTierColor(String tier) {
    switch (tier) {
      case 'Bronze':
        return const Color(0xFFB87333);
      case 'Silver':
        return const Color(0xFFC0C0C0);
      case 'Gold':
        return const Color(0xFFFFD700);
      case 'Platinum':
        return const Color(0xFFE5E4E2);
      case 'Legend':
        return const Color(0xFFFF6B6B);
      default:
        return Colors.blue;
    }
  }

  String _getTierEmoji(String tier) {
    switch (tier) {
      case 'Bronze':
        return '🥉';
      case 'Silver':
        return '🥈';
      case 'Gold':
        return '🥇';
      case 'Platinum':
        return '👑';
      case 'Legend':
        return '⭐';
      default:
        return '🎯';
    }
  }
}

/// Progress bar to next tier
class _ProgressBar extends StatelessWidget {
  final SeasonalProgress progress;

  const _ProgressBar({required this.progress});

  @override
  Widget build(BuildContext context) {
    final percentage = progress.progressPercentage;
    final ratingToNext = progress.ratingToNextTier;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (progress.isPromotionReady)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '🎉 Promotion Ready!',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'To ${progress.nextTierName ?? "next tier"}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                '$ratingToNext rating',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percentage,
              minHeight: 12,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                _getProgressColor(percentage),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(percentage * 100).toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${progress.userData.currentRating}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getProgressColor(double percentage) {
    if (percentage >= 0.75) return Colors.green;
    if (percentage >= 0.5) return Colors.blue;
    if (percentage >= 0.25) return Colors.orange;
    return Colors.red;
  }
}

/// Earned rewards section
class _RewardsSection extends ConsumerWidget {
  final SeasonalProgress progress;

  const _RewardsSection({required this.progress});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unclaimed = progress.earnedRewardPreviews
        .where((r) => !r.claimed)
        .toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Earned Rewards',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (unclaimed.isNotEmpty)
                ElevatedButton.icon(
                  onPressed: () {
                    // Navigate to rewards claiming screen
                    context.push('/seasonal-rewards');
                  },
                  icon: const Icon(Icons.card_giftcard, size: 18),
                  label: const Text('Claim'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: progress.earnedRewardPreviews.map((reward) {
              return _RewardChip(reward: reward);
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// Individual reward chip
class _RewardChip extends StatelessWidget {
  final TierRewardPreview reward;

  const _RewardChip({required this.reward});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: reward.claimed ? Colors.grey[300]! : Colors.amber,
        ),
      ),
      child: Column(
        children: [
          Icon(
            _getRewardIcon(reward.type),
            size: 24,
            color: reward.claimed ? Colors.grey : Colors.amber,
          ),
          const SizedBox(height: 4),
          Text(
            reward.displayName,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          if (reward.claimed)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Claimed',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontSize: 10,
                ),
              ),
            ),
        ],
      ),
    );
  }

  IconData _getRewardIcon(String type) {
    switch (type) {
      case 'cosmetic_skin':
        return Icons.palette;
      case 'currency':
        return Icons.paid;
      case 'badge':
        return Icons.military_tech;
      case 'emote':
        return Icons.sentiment_satisfied;
      default:
        return Icons.card_giftcard;
    }
  }
}

/// Tier ladder overview section
class _TierLadderSection extends ConsumerWidget {
  final AsyncValue<TierLadderState?> ladderState;

  const _TierLadderSection({required this.ladderState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ladderState.maybeWhen(
      data: (ladder) {
        if (ladder == null) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tier Ladder',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...ladder.tierLadder.map((tier) {
                final isPlayerTier = tier.isCurrentTier;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isPlayerTier
                        ? _getTierColor(tier.tierName).withOpacity(0.1)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isPlayerTier
                          ? _getTierColor(tier.tierName)
                          : Colors.grey[300]!,
                      width: isPlayerTier ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tier.tierName,
                              style:
                                  Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: isPlayerTier ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            Text(
                              '${tier.minRating} - ${tier.maxRating} rating',
                              style:
                                  Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isPlayerTier)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getTierColor(tier.tierName),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'You',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }

  Color _getTierColor(String tier) {
    switch (tier) {
      case 'Bronze':
        return const Color(0xFFB87333);
      case 'Silver':
        return const Color(0xFFC0C0C0);
      case 'Gold':
        return const Color(0xFFFFD700);
      case 'Platinum':
        return const Color(0xFFE5E4E2);
      case 'Legend':
        return const Color(0xFFFF6B6B);
      default:
        return Colors.blue;
    }
  }
}
