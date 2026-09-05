/// Service for detecting tier promotions/demotions
///
/// Compares before/after tier states to determine if a transition occurred
class PromotionDetectorService {
  /// Detect if a promotion/demotion occurred
  static PromotionEvent? detectPromotion({
    required String previousTier,
    required String currentTier,
    required int previousRating,
    required int currentRating,
    required Map<String, int>? tierThresholds,
  }) {
    if (previousTier == currentTier) {
      return null; // No tier change
    }

    final thresholds = tierThresholds ?? _defaultTierThresholds();
    final previousThreshold = thresholds[previousTier] ?? 400;
    final currentThreshold = thresholds[currentTier] ?? 400;

    final isPromotion = currentThreshold > previousThreshold;

    return PromotionEvent(
      fromTier: previousTier,
      toTier: currentTier,
      fromRating: previousRating,
      toRating: currentRating,
      isPromotion: isPromotion,
    );
  }

  /// Default tier thresholds
  static Map<String, int> _defaultTierThresholds() {
    return {
      'Bronze': 400,
      'Silver': 1400,
      'Gold': 1800,
      'Platinum': 2200,
      'Legend': 2800,
    };
  }
}

/// Promotion/Demotion event data
class PromotionEvent {
  final String fromTier;
  final String toTier;
  final int fromRating;
  final int toRating;
  final bool isPromotion;

  PromotionEvent({
    required this.fromTier,
    required this.toTier,
    required this.fromRating,
    required this.toRating,
    required this.isPromotion,
  });

  /// Get emoji for "from" tier
  String get fromTierEmoji => _getTierEmoji(fromTier);

  /// Get emoji for "to" tier
  String get toTierEmoji => _getTierEmoji(toTier);

  /// Get message for promotion/demotion
  String get message {
    if (isPromotion) {
      return 'Congratulations on reaching $toTier!';
    } else {
      return "You've been demoted to $toTier. Keep improving!";
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
