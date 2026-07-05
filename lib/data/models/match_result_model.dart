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
}
