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
      'createdAt': createdAt.toIso8601String(),
      'lastBattleAt': lastBattleAt.toIso8601String(),
    };
  }
}
