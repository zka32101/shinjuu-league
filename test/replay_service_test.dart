import 'package:flutter_test/flutter_test.dart';
import 'package:shinjuu_league/data/models/battle_model.dart';
import 'package:shinjuu_league/services/replay_service.dart';

Battle _testBattle({
  required BattleResult result,
  required double eloChange,
  required List<PlayerStats> playerStats,
}) {
  final now = DateTime.now();
  return Battle(
    battleId: 'battle_1',
    userId: 'self',
    opponentIds: const ['enemy_1', 'enemy_2', 'enemy_3', 'enemy_4', 'enemy_5'],
    mapId: 'map_test',
    mode: BattleMode.quick,
    durationSeconds: 300,
    playerStats: playerStats,
    result: result,
    eloChange: eloChange,
    startedAt: now,
    endedAt: now,
  );
}

void main() {
  group('ReplayService.buildReplay', () {
    test('最高スコアのプレイヤーをMVPとして判定する', () {
      final battle = _testBattle(
        result: BattleResult.win,
        eloChange: 12,
        playerStats: [
          PlayerStats(userId: 'self', mechaId: 'm1', kills: 2, deaths: 1, assists: 0, score: 5),
          PlayerStats(userId: 'ally_1', mechaId: 'm1', kills: 10, deaths: 0, assists: 2, score: 32),
        ],
      );

      final replay = ReplayService().buildReplay(battle);

      expect(replay.summary.mvpUserId, 'ally_1');
      expect(replay.summary.topKills, 10);
      expect(replay.summary.totalScore, 37);
      expect(replay.replayId, 'replay_battle_1');
    });

    test('1キル以上でkeyMomentが設定される', () {
      final battle = _testBattle(
        result: BattleResult.win,
        eloChange: 10,
        playerStats: [PlayerStats(userId: 'self', mechaId: 'm1', kills: 3, deaths: 0, assists: 0, score: 9)],
      );

      final replay = ReplayService().buildReplay(battle);

      expect(replay.summary.keyMoment, '3キルを記録');
    });

    test('ノーキルの場合はkeyMomentがnullになる', () {
      final battle = _testBattle(
        result: BattleResult.loss,
        eloChange: -8,
        playerStats: [PlayerStats(userId: 'self', mechaId: 'm1', kills: 0, deaths: 2, assists: 0, score: -2)],
      );

      final replay = ReplayService().buildReplay(battle);

      expect(replay.summary.keyMoment, isNull);
    });
  });

  group('ReplayService.buildShareText', () {
    test('勝利時は🏆と正のElo表記を含む（Wordle方式のシェアテキスト）', () {
      final battle = _testBattle(
        result: BattleResult.win,
        eloChange: 15.5,
        playerStats: [PlayerStats(userId: 'self', mechaId: 'm1', kills: 4, deaths: 1, assists: 0, score: 11)],
      );
      final replayService = ReplayService();
      final replay = replayService.buildReplay(battle);

      final text = replayService.buildShareText(battle, replay);

      expect(text, contains('🏆 勝利'));
      expect(text, contains('+15.5'));
      expect(text, contains('4キル'));
      expect(text, contains(replay.shareUrl));
    });

    test('敗北時は💀と負のElo表記を含む', () {
      final battle = _testBattle(
        result: BattleResult.loss,
        eloChange: -14.2,
        playerStats: [PlayerStats(userId: 'self', mechaId: 'm1', kills: 1, deaths: 5, assists: 0, score: -2)],
      );
      final replayService = ReplayService();
      final replay = replayService.buildReplay(battle);

      final text = replayService.buildShareText(battle, replay);

      expect(text, contains('💀 敗北'));
      expect(text, contains('-14.2'));
    });
  });
}
