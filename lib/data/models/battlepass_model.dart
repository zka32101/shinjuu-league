enum RewardType {
  gems,
  skin,
  cosmetic,
  nameplate;

  String get displayName {
    switch (this) {
      case RewardType.gems:
        return 'ジェム';
      case RewardType.skin:
        return 'スキン';
      case RewardType.cosmetic:
        return 'コスメティック';
      case RewardType.nameplate:
        return 'ネームプレート';
    }
  }
}

class BattlePassReward {
  final String rewardId;
  final RewardType type;
  final String name;
  final String? imageUrl;
  final int tier;
  final bool isPremium;

  BattlePassReward({
    required this.rewardId,
    required this.type,
    required this.name,
    this.imageUrl,
    required this.tier,
    required this.isPremium,
  });

  factory BattlePassReward.fromJson(Map<String, dynamic> json) {
    return BattlePassReward(
      rewardId: json['rewardId'] as String,
      type: RewardType.values.firstWhere(
        (e) => e.name == (json['type'] as String? ?? 'gems'),
        orElse: () => RewardType.gems,
      ),
      name: json['name'] as String,
      imageUrl: json['imageUrl'] as String?,
      tier: json['tier'] as int? ?? 1,
      isPremium: json['isPremium'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'rewardId': rewardId,
    'type': type.name,
    'name': name,
    'imageUrl': imageUrl,
    'tier': tier,
    'isPremium': isPremium,
  };
}

class BattlePass {
  final String seasonId;
  final String userId;
  final int progress; // 0-100
  final int level;
  final List<BattlePassReward> claimedRewards;
  final bool isPremium;
  final DateTime startDate;
  final DateTime endDate;

  BattlePass({
    required this.seasonId,
    required this.userId,
    required this.progress,
    required this.level,
    required this.claimedRewards,
    required this.isPremium,
    required this.startDate,
    required this.endDate,
  });

  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }

  int get daysRemaining {
    final remaining = endDate.difference(DateTime.now()).inDays;
    return remaining > 0 ? remaining : 0;
  }

  factory BattlePass.fromJson(Map<String, dynamic> json) {
    return BattlePass(
      seasonId: json['seasonId'] as String,
      userId: json['userId'] as String,
      progress: json['progress'] as int? ?? 0,
      level: json['level'] as int? ?? 1,
      claimedRewards: (json['claimedRewards'] as List<dynamic>?)
              ?.map((e) => BattlePassReward.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      isPremium: json['isPremium'] as bool? ?? false,
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'] as String)
          : DateTime.now(),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : DateTime.now().add(const Duration(days: 90)),
    );
  }

  Map<String, dynamic> toJson() => {
    'seasonId': seasonId,
    'userId': userId,
    'progress': progress,
    'level': level,
    'claimedRewards': claimedRewards.map((r) => r.toJson()).toList(),
    'isPremium': isPremium,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
  };
}
