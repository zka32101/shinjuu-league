import 'package:shinjuu_league/data/mecha_catalog.dart';
import 'package:shinjuu_league/data/models/cohort_properties.dart';

class User {
  final String uid;
  final String name;
  final int rank;
  final int level;
  final double eloRating;
  final double winRate;
  final int totalWins;
  final int totalBattles;
  final int gems;
  final int gold;
  final List<String> ownedSkinIds;
  final bool hasBattlePassPremium;
  final String? guildId;
  final String selectedMechaId;
  final List<String> fcmTokens;
  final CohortProperties? cohortProperties;
  final DateTime createdAt;
  final DateTime lastBattleAt;

  User({
    required this.uid,
    required this.name,
    required this.rank,
    required this.level,
    required this.eloRating,
    required this.winRate,
    this.totalWins = 0,
    this.totalBattles = 0,
    required this.gems,
    required this.gold,
    this.ownedSkinIds = const [],
    this.hasBattlePassPremium = false,
    this.guildId,
    this.selectedMechaId = defaultMechaId,
    this.fcmTokens = const [],
    this.cohortProperties,
    required this.createdAt,
    required this.lastBattleAt,
  });

  User copyWith({
    String? uid,
    String? name,
    int? rank,
    int? level,
    double? eloRating,
    double? winRate,
    int? totalWins,
    int? totalBattles,
    int? gems,
    int? gold,
    List<String>? ownedSkinIds,
    bool? hasBattlePassPremium,
    String? guildId,
    String? selectedMechaId,
    List<String>? fcmTokens,
    CohortProperties? cohortProperties,
    DateTime? createdAt,
    DateTime? lastBattleAt,
  }) {
    return User(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      rank: rank ?? this.rank,
      level: level ?? this.level,
      eloRating: eloRating ?? this.eloRating,
      winRate: winRate ?? this.winRate,
      totalWins: totalWins ?? this.totalWins,
      totalBattles: totalBattles ?? this.totalBattles,
      gems: gems ?? this.gems,
      gold: gold ?? this.gold,
      ownedSkinIds: ownedSkinIds ?? this.ownedSkinIds,
      hasBattlePassPremium: hasBattlePassPremium ?? this.hasBattlePassPremium,
      guildId: guildId ?? this.guildId,
      selectedMechaId: selectedMechaId ?? this.selectedMechaId,
      fcmTokens: fcmTokens ?? this.fcmTokens,
      cohortProperties: cohortProperties ?? this.cohortProperties,
      createdAt: createdAt ?? this.createdAt,
      lastBattleAt: lastBattleAt ?? this.lastBattleAt,
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      uid: json['uid'] as String,
      name: json['name'] as String,
      rank: json['rank'] as int? ?? 0,
      level: json['level'] as int? ?? 1,
      eloRating: (json['eloRating'] as num?)?.toDouble() ?? 1000.0,
      winRate: (json['winRate'] as num?)?.toDouble() ?? 0.0,
      totalWins: json['totalWins'] as int? ?? 0,
      totalBattles: json['totalBattles'] as int? ?? 0,
      gems: json['gems'] as int? ?? 0,
      gold: json['gold'] as int? ?? 0,
      ownedSkinIds: List<String>.from(
        json['ownedSkinIds'] as List<dynamic>? ?? [],
      ),
      hasBattlePassPremium: json['hasBattlePassPremium'] as bool? ?? false,
      guildId: json['guildId'] as String?,
      selectedMechaId: json['selectedMechaId'] as String? ?? defaultMechaId,
      fcmTokens: List<String>.from(
        json['fcmTokens'] as List<dynamic>? ?? [],
      ),
      cohortProperties: json['cohortProperties'] != null
          ? CohortProperties.fromJson(
              json['cohortProperties'] as Map<String, dynamic>,
            )
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      lastBattleAt: json['lastBattleAt'] != null
          ? DateTime.parse(json['lastBattleAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'rank': rank,
      'level': level,
      'eloRating': eloRating,
      'winRate': winRate,
      'totalWins': totalWins,
      'totalBattles': totalBattles,
      'gems': gems,
      'gold': gold,
      'ownedSkinIds': ownedSkinIds,
      'hasBattlePassPremium': hasBattlePassPremium,
      'guildId': guildId,
      'selectedMechaId': selectedMechaId,
      'fcmTokens': fcmTokens,
      if (cohortProperties != null) 'cohortProperties': cohortProperties!.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'lastBattleAt': lastBattleAt.toIso8601String(),
    };
  }
}
