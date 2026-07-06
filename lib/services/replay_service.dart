import 'package:shinjuu_league/data/models/battle_model.dart';
import 'package:shinjuu_league/data/models/replay_model.dart';
import 'package:shinjuu_league/services/firestore_service.dart';

/// リプレイシェアは「Wordle方式」（差別化軸の一つ）：実際の動画エンコード・録画は
/// 行わず、試合結果を要約したテキストを即座にシェアできるようにする。
/// 動画/サムネイル生成（videoUrl/thumbnailUrl）は将来的な拡張ポイントとして
/// Replayモデル側にフィールドのみ用意してある。
class ReplayService {
  ReplayService({FirestoreService? firestoreService})
    : _firestoreServiceOverride = firestoreService;

  // FirestoreService() はシングルトン初期化時に FirebaseFirestore.instance に触れるため、
  // buildReplay/buildShareText のような純粋関数のみを使うテストで Firebase 初期化が
  // 不要になるよう、実際に Firestore へアクセスするまで生成を遅延する。
  final FirestoreService? _firestoreServiceOverride;
  FirestoreService get _firestoreService =>
      _firestoreServiceOverride ?? FirestoreService();

  Replay buildReplay(Battle battle) {
    final mvp = battle.playerStats.isEmpty
        ? null
        : battle.playerStats.reduce((a, b) => a.score >= b.score ? a : b);
    final totalScore = battle.playerStats.fold<int>(
      0,
      (sum, p) => sum + p.score,
    );

    return Replay(
      replayId: 'replay_${battle.battleId}',
      battleId: battle.battleId,
      // 実際のディープリンク配信基盤はまだ無いため、battleIdベースの仮URL
      shareUrl: 'https://shinjuu-league.app/replay/${battle.battleId}',
      summary: ReplaySummary(
        mvpUserId: mvp?.userId ?? battle.userId,
        topKills: mvp?.kills ?? battle.kills,
        totalScore: totalScore,
        keyMoment: battle.kills > 0 ? '${battle.kills}キルを記録' : null,
      ),
      createdAt: DateTime.now(),
    );
  }

  Future<Replay> generateAndSave(Battle battle) async {
    final replay = buildReplay(battle);
    await _firestoreService.createReplay(replay);
    return replay;
  }

  String buildShareText(Battle battle, Replay replay) {
    final resultEmoji = battle.result == BattleResult.win ? '🏆 勝利' : '💀 敗北';
    final eloText = battle.eloChange >= 0
        ? '+${battle.eloChange.toStringAsFixed(1)}'
        : battle.eloChange.toStringAsFixed(1);

    return '神獣リーグ $resultEmoji\n'
        '⚔️ ${battle.kills}キル / 💀${battle.deaths}デス\n'
        '📊 Elo $eloText\n'
        '${replay.shareUrl}\n'
        '#神獣リーグ';
  }
}
