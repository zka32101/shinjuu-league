enum BattleResult {
  win,
  loss,
  pending;

  String get displayName {
    switch (this) {
      case BattleResult.win:
        return '勝利';
      case BattleResult.loss:
        return '敗北';
      case BattleResult.pending:
        return '進行中';
    }
  }
}

enum BattleMode {
  quick,
  ranked;

  String get displayName {
    switch (this) {
      case BattleMode.quick:
        return 'クイック';
      case BattleMode.ranked:
        return 'ランク';
    }
  }
}

class PlayerStats {
  final String userId;
  final String mechaId;
  final int kills;
  final int deaths;
  final int assists;
  final int score;

  PlayerStats({
    required this.userId,
    required this.mechaId,
    required this.kills,
    required this.deaths,
    required this.assists,
    required this.score,
  });

  factory PlayerStats.fromJson(Map<String, dynamic> json) {
    return PlayerStats(
      userId: json['userId'] as String,
      mechaId: json['mechaId'] as String,
      kills: json['kills'] as int? ?? 0,
      deaths: json['deaths'] as int? ?? 0,
      assists: json['assists'] as int? ?? 0,
      score: json['score'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'mechaId': mechaId,
    'kills': kills,
    'deaths': deaths,
    'assists': assists,
    'score': score,
  };
}

class Battle {
  final String battleId;
  final String userId;
  final List<String> opponentIds; // 4個（5v5なので自分+4人=5人）
  final String mapId;
  final BattleMode mode;
  final int durationSeconds;
  final List<PlayerStats> playerStats;
  final BattleResult result;
  final double eloChange;
  final String? replayHash;
  final DateTime startedAt;
  final DateTime? endedAt;

  Battle({
    required this.battleId,
    required this.userId,
    required this.opponentIds,
    required this.mapId,
    required this.mode,
    required this.durationSeconds,
    required this.playerStats,
    required this.result,
    required this.eloChange,
    this.replayHash,
    required this.startedAt,
    this.endedAt,
  });

  int get kills => playerStats
      .firstWhere((p) => p.userId == userId, orElse: () => PlayerStats(userId: userId, mechaId: '', kills: 0, deaths: 0, assists: 0, score: 0))
      .kills;

  int get deaths => playerStats
      .firstWhere((p) => p.userId == userId, orElse: () => PlayerStats(userId: userId, mechaId: '', kills: 0, deaths: 0, assists: 0, score: 0))
      .deaths;

  bool get isAhaMoment => kills >= 1 && result == BattleResult.pending;

  factory Battle.fromJson(Map<String, dynamic> json) {
    return Battle(
      battleId: json['battleId'] as String,
      userId: json['userId'] as String,
      opponentIds: List<String>.from(json['opponentIds'] as List<dynamic>? ?? []),
      mapId: json['mapId'] as String? ?? 'map_01',
      mode: BattleMode.values.firstWhere(
        (e) => e.name == (json['mode'] as String? ?? 'quick'),
        orElse: () => BattleMode.quick,
      ),
      durationSeconds: json['durationSeconds'] as int? ?? 300,
      playerStats: (json['playerStats'] as List<dynamic>?)
              ?.map((e) => PlayerStats.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      result: BattleResult.values.firstWhere(
        (e) => e.name == (json['result'] as String? ?? 'pending'),
        orElse: () => BattleResult.pending,
      ),
      eloChange: (json['eloChange'] as num?)?.toDouble() ?? 0.0,
      replayHash: json['replayHash'] as String?,
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'] as String)
          : DateTime.now(),
      endedAt: json['endedAt'] != null ? DateTime.parse(json['endedAt'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'battleId': battleId,
    'userId': userId,
    'opponentIds': opponentIds,
    'mapId': mapId,
    'mode': mode.name,
    'durationSeconds': durationSeconds,
    'playerStats': playerStats.map((p) => p.toJson()).toList(),
    'result': result.name,
    'eloChange': eloChange,
    'replayHash': replayHash,
    'startedAt': startedAt.toIso8601String(),
    'endedAt': endedAt?.toIso8601String(),
  };
}
