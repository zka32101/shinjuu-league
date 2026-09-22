import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:shinjuu_league/config/app_config.dart';
import 'package:shinjuu_league/data/mecha_catalog.dart';
import 'package:shinjuu_league/data/models/battle_model.dart';
import 'package:shinjuu_league/data/models/match_result_model.dart';
import 'package:shinjuu_league/data/models/user_model.dart';
import 'package:shinjuu_league/data/stage_catalog.dart';

/// マッチメイキングの候補プレイヤー情報。currentUser（フルの User）と
/// matchmaking_queue ドキュメント由来のデータ（uid/mechaId/eloRatingのみ）を
/// 同じ形で _buildTeam に渡すための軽量ラッパー。
class _MatchCandidate {
  final String userId;
  final String mechaId;
  final double eloRating;

  const _MatchCandidate({
    required this.userId,
    required this.mechaId,
    required this.eloRating,
  });

  factory _MatchCandidate.fromUser(User user) => _MatchCandidate(
    userId: user.uid,
    mechaId: user.selectedMechaId,
    eloRating: user.eloRating,
  );

  factory _MatchCandidate.fromQueueDoc(Map<String, dynamic> data) =>
      _MatchCandidate(
        userId: data['userId'] as String,
        mechaId: data['mechaId'] as String? ?? defaultMechaId,
        eloRating: (data['eloRating'] as num).toDouble(),
      );
}

/// マッチング < 30秒を保証：待機中の実プレイヤーが見つからないまま
/// matchmakingTimeoutSeconds が経過すると Bot で即座に埋める。
/// ロール自動割当：チーム内で lane を交互に割り当て、初心者でも即戦力になれるようにする。
///
/// 専用マッチメイキングサーバーは無いため、Firestore を介したクライアント主導の
/// プロトコルで実プレイヤー同士をマッチさせる：
/// 1. 自分を matchmaking_queue/{uid} へ登録
/// 2. 一定間隔で (a) 自分が他プレイヤーに既にマッチされていないか確認、
///    (b) 待機中の互換プレイヤーを見つけて自分からマッチを確定 を繰り返す
/// 3. マッチ確定はトランザクションで「候補が依然キューに存在するか」を
///    再確認してから matchmaking_matches ドキュメントを作成 + 候補のキュー
///    エントリを削除することで、複数プレイヤーによる二重クレームを防ぐ
/// 4. タイムアウトまでに見つからなければキューから離脱しBotで埋める
class MatchmakingService {
  /// [pollTimeout]/[pollInterval] control how long and how often findMatch()
  /// waits for a real opponent before falling back to bots - overridable
  /// only so tests don't have to wait the real ~30s budget for that path.
  /// [estimatedWaitSeconds] on the returned MatchResult always reflects the
  /// real product SLA (AppConfig.matchmakingTimeoutSeconds), independent of
  /// this instance's actual poll timeout.
  MatchmakingService({
    FirebaseFirestore? firestore,
    Duration? pollTimeout,
    Duration? pollInterval,
  }) : _db = firestore ?? FirebaseFirestore.instance,
       _pollTimeout =
           pollTimeout ??
           const Duration(seconds: AppConfig.matchmakingTimeoutSeconds),
       _pollInterval = pollInterval ?? const Duration(seconds: 2);

  final FirebaseFirestore _db;
  final Duration _pollTimeout;
  final Duration _pollInterval;
  final _uuid = const Uuid();
  final _random = Random();

  Future<MatchResult> findMatch({
    required User currentUser,
    required BattleMode mode,
  }) async {
    final matchId = _uuid.v4();
    final mapId = stageCatalog[_random.nextInt(stageCatalog.length)].stageId;
    final queueRef = _db.collection('matchmaking_queue').doc(currentUser.uid);

    try {
      await queueRef.set({
        'userId': currentUser.uid,
        'mode': mode.name,
        'eloRating': currentUser.eloRating,
        'mechaId': currentUser.selectedMechaId,
        'joinedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // キュー登録に失敗した場合も対戦体験自体は止めない - 即座にBotで埋める
      return _buildBotFilledMatch(currentUser, mode, matchId, mapId);
    }

    try {
      final deadline = DateTime.now().add(_pollTimeout);

      while (DateTime.now().isBefore(deadline)) {
        final assigned = await _checkAssignedMatch(currentUser.uid);
        if (assigned != null) return assigned;

        final claimed = await _tryClaimMatch(
          currentUser: currentUser,
          mode: mode,
          matchId: matchId,
          mapId: mapId,
        );
        if (claimed != null) return claimed;

        await Future.delayed(_pollInterval);
      }

      return _buildBotFilledMatch(currentUser, mode, matchId, mapId);
    } finally {
      // マッチの成否によらずキューから離脱する。完了を待たずに返すと、自分が
      // 既にBotで埋めて立ち去った後もこのキューエントリが残り続け、別の
      // プレイヤーが「まだ待機中の実プレイヤー」として自分を誤ってクレーム
      // してしまう窓が生まれるため、必ず待ってから返す
      // （既にクレームされ削除済みの場合はエラーを握りつぶす）。
      try {
        await queueRef.delete();
      } catch (_) {}
    }
  }

  /// 他プレイヤーが自分を既にマッチへ組み込んでいないか確認する
  Future<MatchResult?> _checkAssignedMatch(String userId) async {
    try {
      final snapshot = await _db
          .collection('matchmaking_matches')
          .where('participantUserIds', arrayContains: userId)
          .limit(1)
          .get();
      if (snapshot.docs.isEmpty) return null;
      return MatchResult.fromJson(snapshot.docs.first.data());
    } catch (_) {
      return null;
    }
  }

  /// 待機中の互換プレイヤーを検索し、見つかればトランザクションでマッチを確定する
  Future<MatchResult?> _tryClaimMatch({
    required User currentUser,
    required BattleMode mode,
    required String matchId,
    required String mapId,
  }) async {
    List<QueryDocumentSnapshot<Map<String, dynamic>>> candidates;
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

      candidates = snapshot.docs
          .where((doc) => doc.id != currentUser.uid)
          .toList();
    } catch (_) {
      // キュー未整備・インデックス未作成時は次のループでリトライ
      // （最終的にタイムアウトでBot対戦にフォールバックする）
      return null;
    }

    if (candidates.isEmpty) return null;

    try {
      return await _db.runTransaction<MatchResult?>((transaction) async {
        // 自分自身のキューエントリもこのトランザクションで読む。これにより、
        // 自分を同時にクレームしようとしている別プレイヤーのトランザクション
        // （自分のエントリを削除する）と衝突検出され、Firestoreがどちらか
        // 片方を中断・再試行する。これが無いと、AがBを・BがAを同時に
        // クレームして matchmaking_matches が2つ出来てしまう競合を防げない
        // （読み取り専用の依存関係だけで十分 - 自分のエントリ自体はこの
        // トランザクションでは削除せず、成功後に findMatch の finally 節が
        // まとめて削除する）。
        final selfDoc = await transaction.get(
          _db.collection('matchmaking_queue').doc(currentUser.uid),
        );
        if (!selfDoc.exists) {
          // 既に他プレイヤーにクレームされた後 - 次のループの
          // _checkAssignedMatch がその結果を拾う
          return null;
        }

        final freshDocs = await Future.wait(
          candidates.map((c) => transaction.get(c.reference)),
        );

        final stillQueued = <_MatchCandidate>[];
        for (var i = 0; i < candidates.length; i++) {
          if (freshDocs[i].exists) {
            stillQueued.add(_MatchCandidate.fromQueueDoc(freshDocs[i].data()!));
          }
        }
        // 全候補が既に他プレイヤーにクレームされていた場合は次のループへ
        if (stillQueued.isEmpty) return null;

        final teamA = _buildTeam(
          team: 0,
          candidates: [_MatchCandidate.fromUser(currentUser)],
          eloTarget: currentUser.eloRating,
        );
        final teamB = _buildTeam(
          team: 1,
          candidates: stillQueued,
          eloTarget: currentUser.eloRating,
        );

        final match = MatchResult(
          matchId: matchId,
          mapId: mapId,
          mode: mode,
          teamA: teamA,
          teamB: teamB,
          estimatedWaitSeconds: AppConfig.matchmakingTimeoutSeconds,
        );

        final matchRef = _db.collection('matchmaking_matches').doc(matchId);
        transaction.set(matchRef, {
          ...match.toJson(),
          'participantUserIds': match.allParticipants
              .where((p) => !p.isBot)
              .map((p) => p.userId)
              .toList(),
          'createdAt': FieldValue.serverTimestamp(),
        });
        for (final candidate in candidates) {
          transaction.delete(candidate.reference);
        }

        return match;
      });
    } catch (_) {
      return null;
    }
  }

  MatchResult _buildBotFilledMatch(
    User currentUser,
    BattleMode mode,
    String matchId,
    String mapId,
  ) {
    final teamA = _buildTeam(
      team: 0,
      candidates: [_MatchCandidate.fromUser(currentUser)],
      eloTarget: currentUser.eloRating,
    );
    final teamB = _buildTeam(
      team: 1,
      candidates: const [],
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

  List<MatchParticipant> _buildTeam({
    required int team,
    required List<_MatchCandidate> candidates,
    required double eloTarget,
  }) {
    final participants = <MatchParticipant>[];

    for (final candidate in candidates) {
      if (participants.length >= AppConfig.maxPlayersPerTeam) break;
      participants.add(
        MatchParticipant(
          userId: candidate.userId,
          mechaId: candidate.mechaId,
          eloRating: candidate.eloRating,
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
          mechaId: mechaCatalog[_random.nextInt(mechaCatalog.length)].mechaId,
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
