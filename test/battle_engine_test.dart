import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:shinjuu_league/data/models/battle_model.dart';
import 'package:shinjuu_league/data/models/evolution_model.dart';
import 'package:shinjuu_league/data/models/mecha_model.dart';
import 'package:shinjuu_league/services/battle_engine_service.dart';
import 'package:shinjuu_league/services/elo_service.dart';

BattleParticipantState _participant({
  required String userId,
  required int team,
  bool isSelf = false,
  BaseStats? stats,
}) {
  return BattleParticipantState(
    userId: userId,
    mechaId: 'mecha_default_01',
    isBot: !isSelf,
    isSelf: isSelf,
    team: team,
    lane: 0,
    baseStats: stats ?? BaseStats(hp: 100, atk: 50, spd: 40),
  );
}

void main() {
  group('BattleEngine Aha Moment detection', () {
    test('自分がキルを取った瞬間 combatEvents が同フレームで発火し kills も反映済みになる', () {
      // winChance は 15%〜85% にクランプされるため、1体の敵との対戦では
      // 「最初の交戦」が必ず自分の勝利になるとは限らない（相手が先に攻撃を仕掛け、
      // 低確率で勝つケースがあるため）。そのため複数の敵を用意し、
      // 「自分が撃破した最初のイベント」を追跡することで Aha Moment 検知の
      // 即時性（kills 更新と同フレームでイベントが飛ぶこと）を検証する。
      final self = _participant(
        userId: 'self',
        team: 0,
        isSelf: true,
        stats: BaseStats(hp: 100, atk: 9999, spd: 40),
      );
      final enemies = List.generate(
        4,
        (i) => _participant(userId: 'enemy_$i', team: 1),
      );

      final engine = BattleEngine(
        battleId: 'test_battle',
        mode: BattleMode.quick,
        mapId: 'map_test',
        participants: [self, ...enemies],
        random: Random(7), // 再現性のため固定シード
      );

      CombatEvent? selfFirstKillEvent;
      int? selfKillsAtEventTime;
      engine.combatEvents.listen((event) {
        if (event.attackerId == 'self' && selfFirstKillEvent == null) {
          selfFirstKillEvent = event;
          selfKillsAtEventTime = self.kills; // リスナー内で同期的に取得
        }
      });

      for (var i = 0; i < 300 && selfFirstKillEvent == null; i++) {
        engine.tick();
      }
      engine.dispose();

      expect(selfFirstKillEvent, isNotNull);
      expect(selfKillsAtEventTime, 1);
    });

    test('進化選択（攻撃）で攻撃力が1.3倍になる', () {
      final self = _participant(userId: 'self', team: 0, isSelf: true);
      final engine = BattleEngine(
        battleId: 'test_battle_2',
        mode: BattleMode.quick,
        mapId: 'map_test',
        participants: [self],
      );

      engine.setEvolution('self', Evolution.attack());

      expect(self.effectiveAtk, 50 * 1.3);
      expect(self.effectiveHp, 100.0);
      engine.dispose();
    });

    test('チーム合計スコアで勝敗を正しく判定する', () {
      final self = _participant(userId: 'self', team: 0, isSelf: true);
      final ally = _participant(userId: 'ally_1', team: 0);
      final enemy = _participant(userId: 'enemy_1', team: 1);

      self.kills = 3; // score: 3*3 = 9
      enemy.kills = 1; // score: 1*3 = 3

      final engine = BattleEngine(
        battleId: 'test_battle_3',
        mode: BattleMode.quick,
        mapId: 'map_test',
        participants: [self, ally, enemy],
      );

      expect(engine.resultForUser('self'), BattleResult.win);
      expect(engine.resultForUser('enemy_1'), BattleResult.loss);
      engine.dispose();
    });
  });

  group('EloService', () {
    test('同レーティング同士の勝利で kFactor/2 分だけ上昇する', () {
      final change = EloService.calculateEloChange(
        currentRating: 1000,
        opponentAvgRating: 1000,
        isWin: true,
        kFactor: 32,
      );
      expect(change, closeTo(16.0, 0.01));
    });

    test('格上に勝つとより多くレーティングが上昇する', () {
      final changeVsEqual = EloService.calculateEloChange(
        currentRating: 1000,
        opponentAvgRating: 1000,
        isWin: true,
      );
      final changeVsStronger = EloService.calculateEloChange(
        currentRating: 1000,
        opponentAvgRating: 1200,
        isWin: true,
      );
      expect(changeVsStronger, greaterThan(changeVsEqual));
    });
  });
}
