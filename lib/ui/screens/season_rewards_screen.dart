import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../viewmodels/season_viewmodel.dart';
import '../widgets/loading_skeleton.dart';
import '../widgets/error_retry_view.dart';

/// Screen for claiming seasonal rewards
///
/// Displays:
/// - Unclaimed rewards prominently
/// - Claimed rewards grayed out
/// - Claim button with confirmation
/// - Reward details
class SeasonRewardsScreen extends ConsumerStatefulWidget {
  const SeasonRewardsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SeasonRewardsScreen> createState() =>
      _SeasonRewardsScreenState();
}

class _SeasonRewardsScreenState extends ConsumerState<SeasonRewardsScreen> {
  bool _isClaiming = false;

  @override
  Widget build(BuildContext context) {
    final seasonState = ref.watch(currentSeasonViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seasonal Rewards'),
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

          final unclaimed = progress.earnedRewardPreviews
              .where((r) => !r.claimed)
              .toList();
          final claimed = progress.earnedRewardPreviews
              .where((r) => r.claimed)
              .toList();

          if (progress.earnedRewardPreviews.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.card_giftcard, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'No rewards earned yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Keep climbing the ranks to earn rewards!',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 16),

                // Unclaimed rewards section
                if (unclaimed.isNotEmpty) ...[
                  _UnclaimedRewardsSection(
                    rewards: unclaimed,
                    isClaiming: _isClaiming,
                    onClaim: () => _handleClaimRewards(ref),
                  ),
                  const SizedBox(height: 24),
                ],

                // Claimed rewards section
                if (claimed.isNotEmpty) ...[
                  _ClaimedRewardsSection(rewards: claimed),
                  const SizedBox(height: 32),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleClaimRewards(WidgetRef ref) async {
    if (_isClaiming) return;

    setState(() {
      _isClaiming = true;
    });

    try {
      await ref
          .read(currentSeasonViewModelProvider.notifier)
          .claimRewards();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Rewards claimed successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error claiming rewards: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isClaiming = false;
        });
      }
    }
  }
}

/// Unclaimed rewards section with claim button
class _UnclaimedRewardsSection extends StatelessWidget {
  final List<dynamic> rewards;
  final bool isClaiming;
  final VoidCallback onClaim;

  const _UnclaimedRewardsSection({
    required this.rewards,
    required this.isClaiming,
    required this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.amber[50]!,
            Colors.orange[50]!,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.card_giftcard, color: Colors.amber, size: 24),
              const SizedBox(width: 8),
              Text(
                'Unclaimed Rewards',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.amber[900],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Rewards grid
          GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
            ),
            itemCount: rewards.length,
            itemBuilder: (context, index) {
              return _RewardCard(reward: rewards[index]);
            },
          ),
          const SizedBox(height: 16),

          // Claim button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isClaiming ? null : onClaim,
              icon: isClaiming
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.check_circle),
              label: Text(
                isClaiming ? 'Claiming...' : 'Claim All Rewards',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Claimed rewards section (grayed out)
class _ClaimedRewardsSection extends StatelessWidget {
  final List<dynamic> rewards;

  const _ClaimedRewardsSection({required this.rewards});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.grey, size: 24),
              const SizedBox(width: 8),
              Text(
                'Claimed Rewards',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Rewards grid
          GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
            ),
            itemCount: rewards.length,
            itemBuilder: (context, index) {
              return _RewardCard(
                reward: rewards[index],
                claimed: true,
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Individual reward card
class _RewardCard extends StatelessWidget {
  final dynamic reward;
  final bool claimed;

  const _RewardCard({
    required this.reward,
    this.claimed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: claimed ? Colors.grey[300] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: claimed ? Colors.grey[400]! : Colors.amber[200]!,
        ),
        boxShadow: claimed
            ? null
            : [
                BoxShadow(
                  color: Colors.amber.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getRewardIcon(reward.type),
                size: 32,
                color: claimed ? Colors.grey[500] : Colors.amber[700],
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  reward.displayName,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: claimed ? Colors.grey[600] : Colors.black,
                    fontWeight: claimed ? FontWeight.normal : FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          // Claimed badge
          if (claimed)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(
                  Icons.check,
                  size: 12,
                  color: Colors.white,
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
