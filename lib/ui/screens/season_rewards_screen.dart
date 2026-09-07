import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shinjuu_league/data/models/seasonal_reward.dart';
import 'package:shinjuu_league/viewmodels/season_reward_viewmodel.dart';
import 'package:shinjuu_league/config/theme.dart';

/// Screen for displaying and claiming seasonal rewards
class SeasonRewardsScreen extends ConsumerStatefulWidget {
  final String userId;

  const SeasonRewardsScreen({
    required this.userId,
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<SeasonRewardsScreen> createState() =>
      _SeasonRewardsScreenState();
}

class _SeasonRewardsScreenState extends ConsumerState<SeasonRewardsScreen> {
  @override
  void initState() {
    super.initState();
    // Load rewards on screen open
    Future.microtask(() {
      ref
          .read(seasonRewardViewModelProvider(widget.userId).notifier)
          .loadPlayerRewards();
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = ref.watch(seasonRewardViewModelProvider(widget.userId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('季節報酬'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          if (viewModel.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (viewModel.playerRewards.isEmpty)
            _buildEmptyState()
          else
            _buildRewardsList(context, viewModel),
          if (viewModel.error != null) _buildErrorSnackBar(context, viewModel),
          if (viewModel.successMessage != null)
            _buildSuccessSnackBar(context, viewModel),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.card_giftcard,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '報酬がありません',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'シーズンを完了して報酬を獲得してください',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardsList(
    BuildContext context,
    SeasonRewardState viewModel,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Unclaimed rewards section
        if (viewModel.unclaimedRewards.isNotEmpty) ...[
          Text(
            '未請求報酬',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          ..._buildRewardCards(context, viewModel.unclaimedRewards, true),
          const SizedBox(height: 24),
        ],

        // Claimed rewards section
        if (viewModel.playerRewards
            .where((r) => r.isClaimed)
            .isNotEmpty) ...[
          Text(
            '請求済み報酬',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          ..._buildRewardCards(
            context,
            viewModel.playerRewards.where((r) => r.isClaimed).toList(),
            false,
          ),
          const SizedBox(height: 24),
        ],

        // Expired rewards section
        if (viewModel.playerRewards
            .where((r) => r.isExpired && !r.isClaimed)
            .isNotEmpty) ...[
          Text(
            '期限切れ報酬',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
          ),
          const SizedBox(height: 12),
          ..._buildRewardCards(
            context,
            viewModel.playerRewards
                .where((r) => r.isExpired && !r.isClaimed)
                .toList(),
            false,
            isExpired: true,
          ),
        ],
      ],
    );
  }

  List<Widget> _buildRewardCards(
    BuildContext context,
    List<SeasonRewardDistribution> rewards,
    bool isClaimable, {
    bool isExpired = false,
  }) {
    return rewards.map((distribution) {
      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with tier and status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'シーズン ${distribution.seasonId}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  _buildStatusBadge(context, distribution, isExpired),
                ],
              ),
              const SizedBox(height: 8),

              // Tier info
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getTierColor(distribution.finalTier),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      distribution.finalTier,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'シーズン終了: ${_formatDate(distribution.distributedAt)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Reward items
              ..._buildRewardItems(context, distribution.rewards),

              // Claim button or expiry warning
              const SizedBox(height: 12),
              if (isClaimable && !isExpired)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _claimRewards(context, distribution),
                    child: const Text('報酬を請求'),
                  ),
                )
              else if (isExpired)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '期限切れ: ${_formatDate(distribution.expiresAt)}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.red[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _buildRewardItems(
    BuildContext context,
    List<SeasonalReward> rewards,
  ) {
    return rewards.map((reward) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(_getRewardIcon(reward.rewardType)),
            ),
            const SizedBox(width: 12),

            // Name and quantity
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reward.displayName,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  Text(
                    _getRewardTypeLabel(reward.rewardType),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            ),

            // Quantity
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'x${reward.quantity}',
                style: TextStyle(
                  color: Colors.blue[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildStatusBadge(
    BuildContext context,
    SeasonRewardDistribution distribution,
    bool isExpired,
  ) {
    if (isExpired) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red[100],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          '期限切れ',
          style: TextStyle(
            color: Colors.red[700],
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    } else if (distribution.isClaimed) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green[100],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          '請求済み',
          style: TextStyle(
            color: Colors.green[700],
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.amber[100],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          '未請求',
          style: TextStyle(
            color: Colors.amber[700],
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
  }

  void _claimRewards(
    BuildContext context,
    SeasonRewardDistribution distribution,
  ) async {
    final viewModel =
        ref.read(seasonRewardViewModelProvider(widget.userId).notifier);
    final success = await viewModel.claimSeasonRewards(distribution.seasonId);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('報酬を請求しました!')),
      );
    }
  }

  Widget _buildErrorSnackBar(BuildContext context, SeasonRewardState viewModel) {
    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: Material(
        child: SnackBar(
          content: Text(viewModel.error ?? 'エラーが発生しました'),
          action: SnackBarAction(
            label: '閉じる',
            onPressed: () {
              ref
                  .read(seasonRewardViewModelProvider(widget.userId).notifier)
                  .clearError();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessSnackBar(BuildContext context, SeasonRewardState viewModel) {
    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: Material(
        child: SnackBar(
          content: Text(viewModel.successMessage ?? 'Success'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
          onVisible: () {
            Future.delayed(const Duration(seconds: 3), () {
              if (mounted) {
                ref
                    .read(seasonRewardViewModelProvider(widget.userId).notifier)
                    .clearSuccessMessage();
              }
            });
          },
        ),
      ),
    );
  }

  Color _getTierColor(String tier) {
    switch (tier) {
      case 'Bronze':
        return Colors.brown;
      case 'Silver':
        return Colors.blueGrey;
      case 'Gold':
        return Colors.amber;
      case 'Platinum':
        return Colors.cyan;
      case 'Diamond':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getRewardIcon(RewardType type) {
    switch (type) {
      case RewardType.cosmetic_skin:
        return Icons.person;
      case RewardType.battle_pass_item:
        return Icons.card_giftcard;
      case RewardType.currency:
        return Icons.monetization_on;
    }
  }

  String _getRewardTypeLabel(RewardType type) {
    switch (type) {
      case RewardType.cosmetic_skin:
        return 'スキン';
      case RewardType.battle_pass_item:
        return 'バトルパス道具';
      case RewardType.currency:
        return 'ゲーム通貨';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month}/${date.day}';
  }
}
