import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:shinjuu_league/config/app_config.dart';
import 'package:shinjuu_league/data/models/battle_model.dart';
import 'package:shinjuu_league/data/models/match_result_model.dart';
import 'package:shinjuu_league/data/models/user_model.dart';

const _defaultMechaId = 'mecha_default_01';
const _maps = ['map_east_west', 'map_twin_valley'];

/// マッチング < 30秒を保証するため、実プレイヤーが揃わない場合はBotで即座に埋める。
/// ロール自動割当：チーム内で lane を交互に割り当て、初心者でも即戦力になれるようにする。
class MatchmakingService {
  MatchmakingService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;
  final _uuid = const Uuid();
  final _random = Random();

  Future<MatchResult> findMatch({
    required User currentUser,
    required BattleMode mode,
  }) async {
    final matchId = _uuid.v4();
    final mapId = _maps[_random.nextInt(_maps.length)];

    final queuedOpponents = await _searchQueueForOpponents(currentUser, mode);

    final teamA = _buildTeam(
      team: 0,
      humanUsers: [currentUser],
      eloTarget: currentUser.eloRating,
    );
    final teamB = _buildTeam(
      team: 1,
      humanUsers: queuedOpponents,
      eloTarget: currentUser.eloRating,
    );

    return MatchResult(
      matchId: matchId,
      mapId: mapId,
      mode: mode,
      teamA: teamA,
      teamB: teamB,
      estimatedWaitSeconds: AppConfig.matchmakingTimeoutSeconds,
    );
  }

  Future<List<User>> _searchQueueForOpponents(
    User currentUser,
    BattleMode mode,
  ) async {
    try {
      final snapshot = await _db
          .collection('matchmaking_queue')
          .where('mode', isEqualTo: mode.name)
          .where(
            'eloRating',
            isGreaterThanOrEqualTo:
                currentUser.eloRating - AppConfig.eloRangeDifference,
          )
          .where(
            'eloRating',
            isLessThanOrEqualTo:
                currentUser.eloRating + AppConfig.eloRangeDifference,
          )
          .limit(AppConfig.maxPlayersPerTeam)
          .get();

      return snapshot.docs
          .map((doc) => User.fromJson(doc.data()))
          .where((u) => u.uid != currentUser.uid)
          .toList();
    } catch (_) {
      // キュー未整備・インデックス未作成時はBot対戦にフォールバック
      return [];
    }
  }

  List<MatchParticipant> _buildTeam({
    required int team,
    required List<User> humanUsers,
    required double eloTarget,
  }) {
    final participants = <MatchParticipant>[];

    for (final user in humanUsers) {
      if (participants.length >= AppConfig.maxPlayersPerTeam) break;
      participants.add(
        MatchParticipant(
          userId: user.uid,
          mechaId: _defaultMechaId,
          eloRating: user.eloRating,
          isBot: false,
          team: team,
          lane: participants.length % AppConfig.teamsCount,
        ),
      );
    }

    while (participants.length < AppConfig.maxPlayersPerTeam) {
      final variance = (_random.nextDouble() * 100) - 50; // ±50
      participants.add(
        MatchParticipant(
          userId: 'bot_${_uuid.v4().substring(0, 8)}',
          mechaId: _defaultMechaId,
          eloRating: eloTarget + variance,
          isBot: true,
          team: team,
          lane: participants.length % AppConfig.teamsCount,
        ),
      );
    }

    return participants;
  }
}
