import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Ranking history widget displaying promotion/demotion timeline
///
/// Features:
/// - Timeline view of tier transitions
/// - Promotion (green) vs demotion (red) indicators
/// - Rating at transition
/// - Timestamp
/// - Smooth animations
class RankingHistoryWidget extends StatelessWidget {
  final List<TierTransitionEntry> transitions;
  final VoidCallback? onRefresh;

  const RankingHistoryWidget({
    required this.transitions,
    this.onRefresh,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (transitions.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.trending_flat, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              Text(
                'No promotion history yet',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Promotion History',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (onRefresh != null)
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: onRefresh,
                  tooltip: 'Refresh',
                ),
            ],
          ),
        ),

        // Timeline
        ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: transitions.length,
          itemBuilder: (context, index) {
            final transition = transitions[index];
            final isPromotion = transition.isPromotion;
            final isFirst = index == 0;
            final isLast = index == transitions.length - 1;

            return _TimelineEntry(
              transition: transition,
              isFirst: isFirst,
              isLast: isLast,
            );
          },
        ),
      ],
    );
  }
}

/// Individual timeline entry for a tier transition
class _TimelineEntry extends StatelessWidget {
  final TierTransitionEntry transition;
  final bool isFirst;
  final bool isLast;

  const _TimelineEntry({
    required this.transition,
    required this.isFirst,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final isPromotion = transition.isPromotion;
    final color = isPromotion ? Colors.green : Colors.red;
    const timelineRadius = 20.0;

    return Row(
      children: [
        // Timeline line and circle
        SizedBox(
          width: 48,
          child: Column(
            children: [
              // Top line
              if (!isFirst)
                Container(
                  height: 16,
                  width: 2,
                  color: color.withOpacity(0.3),
                )
              else
                const SizedBox(height: 16),

              // Circle
              Container(
                width: timelineRadius * 2,
                height: timelineRadius * 2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    isPromotion ? Icons.arrow_upward : Icons.arrow_downward,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),

              // Bottom line
              if (!isLast)
                Container(
                  height: 16,
                  width: 2,
                  color: color.withOpacity(0.3),
                )
              else
                const SizedBox(height: 16),
            ],
          ),
        ),

        // Entry content
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isPromotion
                  ? Colors.green.withOpacity(0.05)
                  : Colors.red.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: color.withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Title and rating
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isPromotion ? '🎉 Promoted' : '📉 Demoted',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${transition.ratingAtTransition}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Tier transition
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: _TierBadge(
                        tier: transition.fromTier,
                        label: 'From',
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(Icons.arrow_forward, size: 16),
                    ),
                    Expanded(
                      child: _TierBadge(
                        tier: transition.toTier,
                        label: 'To',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Timestamp
                Text(
                  _formatTimestamp(transition.timestamp),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d, y').format(timestamp);
    }
  }
}

/// Small tier badge for timeline
class _TierBadge extends StatelessWidget {
  final String tier;
  final String label;

  const _TierBadge({
    required this.tier,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _getTierEmoji(tier),
          style: const TextStyle(fontSize: 20),
        ),
        const SizedBox(height: 4),
        Text(
          tier,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey,
            fontSize: 10,
          ),
        ),
      ],
    );
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

/// Model for tier transition entry
class TierTransitionEntry {
  final DateTime timestamp;
  final String fromTier;
  final String toTier;
  final int ratingAtTransition;
  final bool isPromotion;

  TierTransitionEntry({
    required this.timestamp,
    required this.fromTier,
    required this.toTier,
    required this.ratingAtTransition,
    required this.isPromotion,
  });

  /// Create from Firestore data
  factory TierTransitionEntry.fromJson(Map<String, dynamic> json) {
    final fromTier = json['fromTier'] as String? ?? 'Bronze';
    final toTier = json['toTier'] as String? ?? 'Bronze';
    final transitionType = json['transitionType'] as String? ?? 'promotion';

    return TierTransitionEntry(
      timestamp: json['timestamp'] is DateTime
          ? json['timestamp'] as DateTime
          : DateTime.now(),
      fromTier: fromTier,
      toTier: toTier,
      ratingAtTransition: json['ratingAtTransition'] as int? ?? 1200,
      isPromotion: transitionType == 'promotion',
    );
  }

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp,
    'fromTier': fromTier,
    'toTier': toTier,
    'ratingAtTransition': ratingAtTransition,
    'transitionType': isPromotion ? 'promotion' : 'demotion',
  };
}

/// Extended widget for full ranking history screen
class RankingHistoryScreen extends StatefulWidget {
  final List<TierTransitionEntry> transitions;

  const RankingHistoryScreen({
    required this.transitions,
    Key? key,
  }) : super(key: key);

  @override
  State<RankingHistoryScreen> createState() => _RankingHistoryScreenState();
}

class _RankingHistoryScreenState extends State<RankingHistoryScreen> {
  bool _filterPromotions = false;
  bool _filterDemotions = false;

  @override
  Widget build(BuildContext context) {
    var filtered = widget.transitions;

    if (_filterPromotions && !_filterDemotions) {
      filtered = filtered.where((t) => t.isPromotion).toList();
    } else if (_filterDemotions && !_filterPromotions) {
      filtered = filtered.where((t) => !t.isPromotion).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ranking History'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Filter buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: FilterChip(
                    label: const Text('All'),
                    selected: !_filterPromotions && !_filterDemotions,
                    onSelected: (selected) {
                      setState(() {
                        _filterPromotions = false;
                        _filterDemotions = false;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilterChip(
                    label: const Text('Promotions'),
                    selected: _filterPromotions,
                    backgroundColor: Colors.green.withOpacity(0.1),
                    selectedColor: Colors.green.withOpacity(0.3),
                    onSelected: (selected) {
                      setState(() {
                        _filterPromotions = selected;
                        _filterDemotions = false;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilterChip(
                    label: const Text('Demotions'),
                    selected: _filterDemotions,
                    backgroundColor: Colors.red.withOpacity(0.1),
                    selectedColor: Colors.red.withOpacity(0.3),
                    onSelected: (selected) {
                      setState(() {
                        _filterDemotions = selected;
                        _filterPromotions = false;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),

          // History list
          Expanded(
            child: SingleChildScrollView(
              child: RankingHistoryWidget(
                transitions: filtered,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
