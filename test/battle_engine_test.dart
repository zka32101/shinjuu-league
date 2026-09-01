import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:shinjuu_league/data/models/battle_model.dart';
import 'package:shinjuu_league/data/models/evolution_model.dart';
import 'package:shinjuu_league/data/models/mecha_model.dart';
import 'package:shinjuu_league/data/models/skill_model.dart';
import 'package:shinjuu_league/data/models/resource_model.dart';
import 'package:shinjuu_league/services/battle_engine_service.dart';
import 'package:shinjuu_league/services/elo_service.dart';
import 'package:shinjuu_league/services/skill_system_service.dart';

BattleParticipantState _participant({
  required String userId,
  required int team,
  bool isSelf = false,
  BaseStats? stats,
  int lane = 0,
}) {
  return BattleParticipantState(
    userId: userId,
    mechaId: 'mecha_default_01',
    isBot: !isSelf,
    isSelf: isSelf,
    team: team,
    lane: lane,
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

  group('BattleEngine.manualDuel（プレイヤー手動攻撃）', () {
    test('敵チームへの手動攻撃は成功しCombatEventが発火する', () {
      final self = _participant(
        userId: 'self',
        team: 0,
        isSelf: true,
        stats: BaseStats(hp: 100, atk: 9999, spd: 40),
      );
      final enemy = _participant(userId: 'enemy_1', team: 1);
      final engine = BattleEngine(
        battleId: 'test_manual_1',
        mode: BattleMode.quick,
        mapId: 'map_test',
        participants: [self, enemy],
      );

      CombatEvent? received;
      engine.combatEvents.listen((event) => received = event);

      final resolved = engine.manualDuel('self', 'enemy_1');

      expect(resolved, isTrue);
      expect(received, isNotNull);
      expect(
        received!.attackerId == 'self' || received!.victimId == 'self',
        isTrue,
      );
      engine.dispose();
    });

    test('同じチームへの手動攻撃は無効化される', () {
      final self = _participant(userId: 'self', team: 0, isSelf: true);
      final ally = _participant(userId: 'ally_1', team: 0);
      final engine = BattleEngine(
        battleId: 'test_manual_2',
        mode: BattleMode.quick,
        mapId: 'map_test',
        participants: [self, ally],
      );

      final resolved = engine.manualDuel('self', 'ally_1');

      expect(resolved, isFalse);
      expect(self.kills, 0);
      expect(ally.kills, 0);
      engine.dispose();
    });

    test('存在しないuserIdへの手動攻撃は例外を投げず失敗を返す', () {
      final self = _participant(userId: 'self', team: 0, isSelf: true);
      final engine = BattleEngine(
        battleId: 'test_manual_3',
        mode: BattleMode.quick,
        mapId: 'map_test',
        participants: [self],
      );

      expect(() => engine.manualDuel('self', '存在しないID'), returnsNormally);
      expect(engine.manualDuel('self', '存在しないID'), isFalse);
      engine.dispose();
    });

    test('死亡中の対象への手動攻撃は無効化される', () {
      final self = _participant(userId: 'self', team: 0, isSelf: true);
      final enemy = _participant(userId: 'enemy_1', team: 1)..isAlive = false;
      final engine = BattleEngine(
        battleId: 'test_manual_4',
        mode: BattleMode.quick,
        mapId: 'map_test',
        participants: [self, enemy],
      );

      final resolved = engine.manualDuel('self', 'enemy_1');

      expect(resolved, isFalse);
      engine.dispose();
    });

    test('レーンが異なる敵への手動攻撃は無効化される（2レーン制の設計を守る）', () {
      final self = _participant(userId: 'self', team: 0, lane: 0, isSelf: true);
      final enemy = _participant(userId: 'enemy_1', team: 1, lane: 1);
      final engine = BattleEngine(
        battleId: 'test_manual_5',
        mode: BattleMode.quick,
        mapId: 'map_test',
        participants: [self, enemy],
      );

      final resolved = engine.manualDuel('self', 'enemy_1');

      expect(resolved, isFalse);
      expect(self.kills, 0);
      engine.dispose();
    });
  });

  group('BattleEngine.manualSkill（プレイヤーのスキル発動）', () {
    test('範囲内の敵チーム全員にダメージを与える', () {
      final self = _participant(
        userId: 'self',
        team: 0,
        isSelf: true,
        stats: BaseStats(hp: 100, atk: 9999, spd: 40),
      );
      final enemy1 = _participant(userId: 'enemy_1', team: 1);
      final enemy2 = _participant(userId: 'enemy_2', team: 1);
      final engine = BattleEngine(
        battleId: 'test_skill_1',
        mode: BattleMode.quick,
        mapId: 'map_test',
        participants: [self, enemy1, enemy2],
      );

      final hitAny = engine.manualSkill('self', ['enemy_1', 'enemy_2']);

      expect(hitAny, isTrue);
      expect(enemy1.isAlive, isFalse);
      expect(enemy2.isAlive, isFalse);
      engine.dispose();
    });

    test('レーンが異なる対象idを渡してもダメージを与えない', () {
      final self = _participant(
        userId: 'self',
        team: 0,
        lane: 0,
        isSelf: true,
        stats: BaseStats(hp: 100, atk: 9999, spd: 40),
      );
      final enemy = _participant(userId: 'enemy_1', team: 1, lane: 1);
      final engine = BattleEngine(
        battleId: 'test_skill_2',
        mode: BattleMode.quick,
        mapId: 'map_test',
        participants: [self, enemy],
      );

      final hitAny = engine.manualSkill('self', ['enemy_1']);

      expect(hitAny, isFalse);
      expect(enemy.isAlive, isTrue);
      engine.dispose();
    });

    test('同じチームの対象idを渡してもダメージを与えない', () {
      final self = _participant(userId: 'self', team: 0, isSelf: true);
      final ally = _participant(userId: 'ally_1', team: 0);
      final engine = BattleEngine(
        battleId: 'test_skill_3',
        mode: BattleMode.quick,
        mapId: 'map_test',
        participants: [self, ally],
      );

      final hitAny = engine.manualSkill('self', ['ally_1']);

      expect(hitAny, isFalse);
      engine.dispose();
    });
  });

  group('BattleEngine HPダメージ蓄積（削り合い）', () {
    test('弱い攻撃力では一撃で倒せず、HPが減るだけでcombatEventsは発火しない', () {
      final self = _participant(
        userId: 'self',
        team: 0,
        isSelf: true,
        stats: BaseStats(hp: 100, atk: 20, spd: 40),
      );
      final enemy = _participant(
        userId: 'enemy_1',
        team: 1,
        stats: BaseStats(hp: 200, atk: 50, spd: 40),
      );
      final engine = BattleEngine(
        battleId: 'test_hp_1',
        mode: BattleMode.quick,
        mapId: 'map_test',
        participants: [self, enemy],
      );

      CombatEvent? killEvent;
      CombatEvent? hitEvent;
      engine.combatEvents.listen((e) => killEvent = e);
      engine.hitEvents.listen((e) => hitEvent = e);

      final resolved = engine.manualDuel('self', 'enemy_1');

      expect(resolved, isTrue);
      expect(enemy.isAlive, isTrue);
      expect(enemy.currentHp, lessThan(200));
      expect(killEvent, isNull);
      expect(hitEvent, isNotNull);
      engine.dispose();
    });

    test('累積ダメージがHPを上回った瞬間に撃破が確定しcombatEventsが発火する', () {
      final self = _participant(
        userId: 'self',
        team: 0,
        isSelf: true,
        stats: BaseStats(hp: 100, atk: 30, spd: 40),
      );
      final enemy = _participant(
        userId: 'enemy_1',
        team: 1,
        stats: BaseStats(hp: 100, atk: 50, spd: 40),
      );
      final engine = BattleEngine(
        battleId: 'test_hp_2',
        mode: BattleMode.quick,
        mapId: 'map_test',
        participants: [self, enemy],
      );

      var killCount = 0;
      engine.combatEvents.listen((_) => killCount++);

      // 十分な回数の手動攻撃を積めば必ず撃破に至る
      for (var i = 0; i < 50 && enemy.isAlive; i++) {
        engine.manualDuel('self', 'enemy_1');
      }

      expect(enemy.isAlive, isFalse);
      expect(killCount, 1);
      expect(self.kills, 1);
      engine.dispose();
    });

    test('リスポーン時にHPが上限まで全回復する', () {
      // 自動交戦（レーン内の確率交戦）との干渉を避けるため、self/enemyを異なるレーンに
      // 置く。manualDuelはレーン一致が必須のため使えず、死亡状態は直接構築する
      // （このテストの目的は撃破手段の検証ではなく _resolveRespawns のHP全回復確認のため）。
      final self = _participant(userId: 'self', team: 0, lane: 0, isSelf: true);
      final enemy =
          _participant(
              userId: 'enemy_1',
              team: 1,
              lane: 1,
              stats: BaseStats(hp: 50, atk: 10, spd: 10),
            )
            ..isAlive = false
            ..currentHp = 0
            ..respawnAtSecond = 8;
      final engine = BattleEngine(
        battleId: 'test_hp_3',
        mode: BattleMode.quick,
        mapId: 'map_test',
        participants: [self, enemy],
      );

      // respawnAtSecondに到達するまでtickを進める（レーンが違うため自動交戦は発生しない）
      for (var i = 0; i < 20 && !enemy.isAlive; i++) {
        engine.tick();
      }

      expect(enemy.isAlive, isTrue);
      expect(enemy.currentHp, enemy.effectiveHp);
      engine.dispose();
    });
  });

  group('BattleEngine マナ・ゴールシステム', () {
    test('毎秒マナが自然回復する', () {
      final self = _participant(userId: 'self', team: 0, isSelf: true);
      self.resources = self.resources.spendMana(50);
      expect(self.resources.currentMana, 50);

      final engine = BattleEngine(
        battleId: 'test_mana_1',
        mode: BattleMode.quick,
        mapId: 'map_test',
        participants: [self],
      );

      for (var i = 0; i < 10; i++) {
        engine.tick();
      }

      expect(self.resources.currentMana, 80); // 50 + (3 * 10)
      engine.dispose();
    });

    test('毎秒パッシブゴールが獲得される', () {
      final self = _participant(userId: 'self', team: 0, isSelf: true);
      expect(self.resources.gold, 0);

      final engine = BattleEngine(
        battleId: 'test_gold_1',
        mode: BattleMode.quick,
        mapId: 'map_test',
        participants: [self],
      );

      for (var i = 0; i < 5; i++) {
        engine.tick();
      }

      expect(self.resources.gold, 25); // 5 * 5秒
      expect(self.totalGoldEarned, 25);
      engine.dispose();
    });

    test('キル報酬でゴールが与えられる', () {
      final killer = _participant(userId: 'killer', team: 0, isSelf: true);
      final assistant1 =
          _participant(userId: 'assistant_1', team: 0, isSelf: false);
      final assistant2 =
          _participant(userId: 'assistant_2', team: 0, isSelf: false);
      final victim = _participant(userId: 'victim', team: 1, isSelf: false);

      final engine = BattleEngine(
        battleId: 'test_gold_2',
        mode: BattleMode.quick,
        mapId: 'map_test',
        participants: [killer, assistant1, assistant2, victim],
      );

      engine.awardKillReward('killer', ['assistant_1', 'assistant_2']);

      expect(killer.resources.gold, 100); // killReward
      expect(killer.totalGoldEarned, 100);
      expect(assistant1.resources.gold, 50); // assistReward
      expect(assistant2.resources.gold, 50);
      engine.dispose();
    });

    test('マナ不足ではスキルが使用できない', () {
      final self = _participant(
        userId: 'self',
        team: 0,
        isSelf: true,
        stats: BaseStats(hp: 100, atk: 50, spd: 40),
      );
      final skill =
          SkillBuild(
            skillId1: 'skill_east_01_q',
            skillId2: 'skill_east_01_w',
            skillId3: 'skill_east_01_e',
            level1: 3, // レベル3 = コスト60
          );
      self.skillBuild = skill;
      self.resources = self.resources.spendMana(45); // マナ55に

      final enemy = _participant(userId: 'enemy', team: 1);

      final engine = BattleEngine(
        battleId: 'test_skill_1',
        mode: BattleMode.quick,
        mapId: 'map_test',
        participants: [self, enemy],
      );

      final result =
          engine.useSkill('self', 'skill_east_01_q', ['enemy']);
      expect(result, isFalse); // マナ不足
      engine.dispose();
    });

    test('スキル使用後はクールダウンが発生', () {
      final self = _participant(
        userId: 'self',
        team: 0,
        isSelf: true,
        stats: BaseStats(hp: 100, atk: 50, spd: 40),
      );
      final skill =
          SkillBuild(
            skillId1: 'skill_east_01_q',
            skillId2: 'skill_east_01_w',
            skillId3: 'skill_east_01_e',
          );
      self.skillBuild = skill;

      final enemy = _participant(userId: 'enemy', team: 1);

      final engine = BattleEngine(
        battleId: 'test_skill_2',
        mode: BattleMode.quick,
        mapId: 'map_test',
        participants: [self, enemy],
      );

      expect(self.skillCooldowns['skill_east_01_q'], 0.0);

      final result =
          engine.useSkill('self', 'skill_east_01_q', ['enemy']);
      expect(result, isTrue);
      expect(
        self.skillCooldowns['skill_east_01_q'],
        greaterThan(0.0),
      ); // クールダウン中

      // 5秒待つ
      for (var i = 0; i < 5; i++) {
        engine.tick();
      }

      expect(
        self.skillCooldowns['skill_east_01_q'],
        lessThanOrEqualTo(0.0),
      ); // クールダウン終了
      expect(self.canUseSkill('skill_east_01_q'), isTrue);
      engine.dispose();
    });

    test('アイテム購入でステータスが変わる', () {
      final self = _participant(userId: 'self', team: 0, isSelf: true);
      self.resources = self.resources.addGold(500);

      final engine = BattleEngine(
        battleId: 'test_item_1',
        mode: BattleMode.quick,
        mapId: 'map_test',
        participants: [self],
      );

      final initialGold = self.resources.gold;
      final result = engine.purchaseItem('self', 'item_sword_01');

      expect(result, isTrue);
      expect(self.resources.gold, initialGold - 300);
      expect(self.resources.ownedItemIds.contains('item_sword_01'), true);
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
