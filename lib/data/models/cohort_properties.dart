/// User cohort assignment for analytics and targeting
///
/// Cohorts are used to segment users for:
/// - Retention analysis (Day 1/7/30 retention by cohort)
/// - Monetization targeting (F2P vs D1Payer vs Whale)
/// - A/B testing (control vs treatment groups)
/// - Geographic/platform analysis
class CohortProperties {
  /// When user was acquired (organic, paid, referral)
  /// Values: 'organic', 'paid_ad', 'referral', 'unknown'
  final String installCohort;

  /// User's platform
  /// Values: 'iOS', 'Android', 'web'
  final String platformCohort;

  /// User's purchase behavior
  /// Values: 'F2P' (never purchased)
  ///         'D1Payer' (first purchase within Day 1)
  ///         'D7Payer' (first purchase within Day 7)
  ///         'Whale' (multiple purchases or high LTV)
  final String purchaseCohort;

  /// Additional custom cohort properties (for A/B testing)
  /// Example: {'aha_moment_variant': 'control', 'pricing_variant': 'treatment'}
  final Map<String, String> customCohorts;

  /// Timestamp when cohorts were assigned
  final DateTime assignedAt;

  /// Timestamp of last purchase (used for D1Payer/D7Payer/Whale tracking)
  final DateTime? lastPurchaseAt;

  const CohortProperties({
    required this.installCohort,
    required this.platformCohort,
    required this.purchaseCohort,
    this.customCohorts = const {},
    required this.assignedAt,
    this.lastPurchaseAt,
  });

  /// Create from JSON (for Firestore deserialization)
  factory CohortProperties.fromJson(Map<String, dynamic> json) {
    return CohortProperties(
      installCohort: json['installCohort'] as String? ?? 'unknown',
      platformCohort: json['platformCohort'] as String? ?? 'unknown',
      purchaseCohort: json['purchaseCohort'] as String? ?? 'F2P',
      customCohorts: Map<String, String>.from(
        json['customCohorts'] as Map<dynamic, dynamic>? ?? {},
      ),
      assignedAt: json['assignedAt'] is String
          ? DateTime.parse(json['assignedAt'] as String)
          : (json['assignedAt'] as DateTime?)
          ?? DateTime.now(),
      lastPurchaseAt: json['lastPurchaseAt'] is String
          ? DateTime.parse(json['lastPurchaseAt'] as String)
          : (json['lastPurchaseAt'] as DateTime?),
    );
  }

  /// Convert to JSON (for Firestore serialization)
  Map<String, dynamic> toJson() => {
        'installCohort': installCohort,
        'platformCohort': platformCohort,
        'purchaseCohort': purchaseCohort,
        'customCohorts': customCohorts,
        'assignedAt': assignedAt.toIso8601String(),
        if (lastPurchaseAt != null) 'lastPurchaseAt': lastPurchaseAt!.toIso8601String(),
      };

  /// Create a copy with modifications
  CohortProperties copyWith({
    String? installCohort,
    String? platformCohort,
    String? purchaseCohort,
    Map<String, String>? customCohorts,
    DateTime? assignedAt,
    DateTime? lastPurchaseAt,
  }) {
    return CohortProperties(
      installCohort: installCohort ?? this.installCohort,
      platformCohort: platformCohort ?? this.platformCohort,
      purchaseCohort: purchaseCohort ?? this.purchaseCohort,
      customCohorts: customCohorts ?? this.customCohorts,
      assignedAt: assignedAt ?? this.assignedAt,
      lastPurchaseAt: lastPurchaseAt ?? this.lastPurchaseAt,
    );
  }

  @override
  String toString() =>
      'CohortProperties(install=$installCohort, platform=$platformCohort, purchase=$purchaseCohort, customs=${customCohorts.length})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CohortProperties &&
          runtimeType == other.runtimeType &&
          installCohort == other.installCohort &&
          platformCohort == other.platformCohort &&
          purchaseCohort == other.purchaseCohort &&
          customCohorts == other.customCohorts &&
          assignedAt == other.assignedAt &&
          lastPurchaseAt == other.lastPurchaseAt;

  @override
  int get hashCode =>
      installCohort.hashCode ^
      platformCohort.hashCode ^
      purchaseCohort.hashCode ^
      customCohorts.hashCode ^
      assignedAt.hashCode ^
      lastPurchaseAt.hashCode;
}
