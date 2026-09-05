/// Represents a ranked season
///
/// Seasons are time-bound competitive periods with:
/// - Tier placement snapshots (promotion/demotion)
/// - Seasonal rewards distribution
/// - Leaderboard snapshots for nostalgia
class RankedSeason {
  final String seasonId;
  final String name;
  final DateTime startedAt;
  final DateTime endsAt;
  final bool isActive;

  /// Tier thresholds for this season (can vary by season)
  /// Maps tier name → minimum rating
  final Map<String, int> tierThresholds;

  /// Base seasonal rewards (can be customized per tier)
  /// Maps tier name → list of reward IDs
  final Map<String, List<String>> rewardsByTier;

  /// Season-specific rules/modifiers
  final SeasonRules rules;

  /// Timestamp for server-side verification
  final DateTime createdAt;
  final DateTime updatedAt;

  const RankedSeason({
    required this.seasonId,
    required this.name,
    required this.startedAt,
    required this.endsAt,
    required this.isActive,
    required this.tierThresholds,
    required this.rewardsByTier,
    required this.rules,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RankedSeason.fromJson(Map<String, dynamic> json) {
    return RankedSeason(
      seasonId: json['seasonId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      startedAt: _parseDateTime(json['startedAt']),
      endsAt: _parseDateTime(json['endsAt']),
      isActive: json['isActive'] as bool? ?? false,
      tierThresholds: _parseTierThresholds(json['tierThresholds']),
      rewardsByTier: _parseRewardsByTier(json['rewardsByTier']),
      rules: SeasonRules.fromJson(
        (json['rules'] as Map<String, dynamic>?) ?? {},
      ),
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'seasonId': seasonId,
      'name': name,
      'startedAt': startedAt.toIso8601String(),
      'endsAt': endsAt.toIso8601String(),
      'isActive': isActive,
      'tierThresholds': tierThresholds,
      'rewardsByTier': rewardsByTier,
      'rules': rules.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  @override
  String toString() => 'RankedSeason(seasonId: $seasonId, name: $name)';
}

/// Rules/modifiers for a season (difficulty, progression speed, etc.)
class SeasonRules {
  /// K-factor multiplier (1.0 = standard, 1.2 = faster progression)
  final double kFactorMultiplier;

  /// Minimum rating to enter ranked play for this season
  final int minEntryRating;

  /// Display seasonal theme/name in UI
  final String theme;

  const SeasonRules({
    this.kFactorMultiplier = 1.0,
    this.minEntryRating = 400,
    this.theme = 'Standard',
  });

  factory SeasonRules.fromJson(Map<String, dynamic> json) {
    return SeasonRules(
      kFactorMultiplier: (json['kFactorMultiplier'] as num?)?.toDouble() ?? 1.0,
      minEntryRating: json['minEntryRating'] as int? ?? 400,
      theme: json['theme'] as String? ?? 'Standard',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'kFactorMultiplier': kFactorMultiplier,
      'minEntryRating': minEntryRating,
      'theme': theme,
    };
  }

  @override
  String toString() =>
      'SeasonRules(kFactorMultiplier: $kFactorMultiplier, minEntryRating: $minEntryRating, theme: $theme)';
}

/// Helper functions for JSON parsing
DateTime _parseDateTime(dynamic json) {
  if (json is String) {
    return DateTime.parse(json);
  }
  if (json is int) {
    return DateTime.fromMillisecondsSinceEpoch(json * 1000);
  }
  // Fallback for Firestore Timestamp objects
  return DateTime.now();
}

Map<String, int> _parseTierThresholds(dynamic json) {
  if (json == null) return {};
  if (json is Map) {
    return json.cast<String, int>();
  }
  return {};
}

Map<String, List<String>> _parseRewardsByTier(dynamic json) {
  if (json == null) return {};
  if (json is Map) {
    final result = <String, List<String>>{};
    json.forEach((key, value) {
      if (value is List) {
        result[key.toString()] = value.cast<String>();
      }
    });
    return result;
  }
  return {};
}
