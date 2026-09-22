import 'package:shinjuu_league/data/models/battle_model.dart';

class MatchParticipant {
  final String userId;
  final String mechaId;
  final double eloRating;
  final bool isBot;
  final int team; // 0 = 自チーム, 1 = 敵チーム
  final int lane; // 0 or 1（2レーン）

  MatchParticipant({
    required this.userId,
    required this.mechaId,
    required this.eloRating,
    required this.isBot,
    required this.team,
    required this.lane,
  });

  factory MatchParticipant.fromJson(Map<String, dynamic> json) {
    return MatchParticipant(
      userId: json['userId'] as String,
      mechaId: json['mechaId'] as String,
      eloRating: (json['eloRating'] as num).toDouble(),
      isBot: json['isBot'] as bool,
      team: json['team'] as int,
      lane: json['lane'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'mechaId': mechaId,
    'eloRating': eloRating,
    'isBot': isBot,
    'team': team,
    'lane': lane,
  };
}

class MatchResult {
  final String matchId;
  final String mapId;
  final BattleMode mode;
  final List<MatchParticipant> teamA;
  final List<MatchParticipant> teamB;
  final int estimatedWaitSeconds;

  MatchResult({
    required this.matchId,
    required this.mapId,
    required this.mode,
    required this.teamA,
    required this.teamB,
    required this.estimatedWaitSeconds,
  });

  List<MatchParticipant> get allParticipants => [...teamA, ...teamB];

  /// マッチメイキングで実プレイヤー同士がマッチした際、相手クライアントにも
  /// 同じチーム編成を伝えるための永続化。（MatchmakingService.findMatch）
  factory MatchResult.fromJson(Map<String, dynamic> json) {
    return MatchResult(
      matchId: json['matchId'] as String,
      mapId: json['mapId'] as String,
      mode: BattleMode.values.firstWhere(
        (e) => e.name == (json['mode'] as String? ?? 'quick'),
        orElse: () => BattleMode.quick,
      ),
      teamA: (json['teamA'] as List<dynamic>)
          .map((e) => MatchParticipant.fromJson(e as Map<String, dynamic>))
          .toList(),
      teamB: (json['teamB'] as List<dynamic>)
          .map((e) => MatchParticipant.fromJson(e as Map<String, dynamic>))
          .toList(),
      estimatedWaitSeconds: json['estimatedWaitSeconds'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'matchId': matchId,
    'mapId': mapId,
    'mode': mode.name,
    'teamA': teamA.map((p) => p.toJson()).toList(),
    'teamB': teamB.map((p) => p.toJson()).toList(),
    'estimatedWaitSeconds': estimatedWaitSeconds,
  };
}
