import 'package:flutter_test/flutter_test.dart';
import 'package:shinjuu_league/data/mecha_catalog.dart';
import 'package:shinjuu_league/game/battlefield_game.dart';
import 'package:shinjuu_league/services/battle_engine_service.dart';

BattleParticipantState _participant({
  required String userId,
  required int team,
  required int lane,
  bool isSelf = false,
}) {
  return BattleParticipantState(
    userId: userId,
    mechaId: mechaCatalog.first.mechaId,
    isBot: !isSelf,
    isSelf: isSelf,
    team: team,
    lane: lane,
    baseStats: mechaCatalog.first.baseStats,
  );
}

void main() {
  group('BattlefieldGame 攻撃対象検出', () {
    test('sync() 直後は自陣/敵陣が離れて配置されるため attackTargetId は null', () {
      final game = BattlefieldGame();
      final self = _participant(userId: 'self', team: 0, lane: 0, isSelf: true);
      final enemy = _participant(userId: 'enemy_1', team: 1, lane: 0);

      game.sync([self, enemy]);
      game.update(0.2); // 走査タイマー(0.15s)を超えて即座に判定させる

      expect(game.attackTargetId.value, isNull);
    });

    test('同じチームの味方は距離が近くても攻撃対象として検出しない', () {
      final game = BattlefieldGame();
      final self = _participant(userId: 'self', team: 0, lane: 0, isSelf: true);
      // 同チーム・同レーンなら slotIndex による横並び配置で自分と近距離になる
      final ally = _participant(userId: 'ally_1', team: 0, lane: 0);

      game.sync([self, ally]);
      game.update(0.2);

      expect(game.attackTargetId.value, isNull);
    });

    test('レーンが異なる敵は距離が近くても攻撃対象として検出しない', () {
      final game = BattlefieldGame();
      final self = _participant(userId: 'self', team: 0, lane: 0, isSelf: true);
      // team違い・lane違いの敵。マップが自由歩行になったため画面上は接近しうるが、
      // BattleEngineの自動交戦がレーン限定である以上、手動攻撃も対象外にすべき。
      final enemy = _participant(userId: 'enemy_1', team: 1, lane: 1);

      game.sync([self, enemy]);
      game.update(0.2);

      expect(game.attackTargetId.value, isNull);
      expect(game.enemiesWithinSkillRadius(), isEmpty);
    });

    test('sync() を複数回呼んでも例外を投げない（tick毎の呼び出しを想定）', () {
      final game = BattlefieldGame();
      final self = _participant(userId: 'self', team: 0, lane: 0, isSelf: true);
      final enemy = _participant(userId: 'enemy_1', team: 1, lane: 0);

      expect(() {
        for (var i = 0; i < 5; i++) {
          game.sync([self, enemy]);
          game.update(0.2);
        }
      }, returnsNormally);
    });
  });

  group('BattlefieldGame ジャングルモンスター攻撃対象検出', () {
    // モンスターはレーン中央(gridX=0, gridY=laneCenterY)に配置される。
    // 自キャラの出撃地点(gridX=-1.8)からは自然状態で射程外のため、ジョイスティック入力を
    // 再現できないユニットテストでは debugSetSelfGridPosition で直接寄せて検証する。
    const laneCenterYForLane0 = -1.8;

    test('射程内のモンスターを攻撃対象として検出する', () {
      final game = BattlefieldGame();
      final self = _participant(userId: 'self', team: 0, lane: 0, isSelf: true);
      final monster = JungleMonster(id: 'jungle_0', lane: 0, maxHp: 400);

      game.sync([self]);
      game.syncMonsters([monster]);
      game.update(0.2);

      // 初期配置では射程外のはず
      expect(game.attackTargetId.value, isNull);

      game.debugSetSelfGridPosition(0, laneCenterYForLane0);
      game.update(0.2);

      expect(game.attackTargetId.value?.id, monster.id);
      expect(game.attackTargetId.value?.isMonster, isTrue);
    });

    test('異なるレーンのモンスターは射程内でも攻撃対象にならない', () {
      final game = BattlefieldGame();
      final self = _participant(userId: 'self', team: 0, lane: 0, isSelf: true);
      final otherLaneMonster = JungleMonster(id: 'jungle_1', lane: 1, maxHp: 400);

      game.sync([self]);
      game.syncMonsters([otherLaneMonster]);
      // モンスターの実座標(lane1中央)へ自キャラを寄せても、レーン不一致のため対象外のはず
      game.debugSetSelfGridPosition(0, 1.8);
      game.update(0.2);

      expect(game.attackTargetId.value, isNull);
    });

    test('死亡中のモンスターは攻撃対象として検出されない', () {
      final game = BattlefieldGame();
      final self = _participant(userId: 'self', team: 0, lane: 0, isSelf: true);
      final monster = JungleMonster(id: 'jungle_0', lane: 0, maxHp: 400)..isAlive = false;

      game.sync([self]);
      game.syncMonsters([monster]);
      game.debugSetSelfGridPosition(0, laneCenterYForLane0);
      game.update(0.2);

      expect(game.attackTargetId.value, isNull);
    });

    test('敵プレイヤーが射程内にいる場合はモンスターより優先して検出する', () {
      final game = BattlefieldGame();
      final self = _participant(userId: 'self', team: 0, lane: 0, isSelf: true);
      final enemy = _participant(userId: 'enemy_1', team: 1, lane: 0);
      // モンスターは自然配置のまま（自キャラからは射程外）にしておき、
      // 敵プレイヤーだけを射程内へ寄せることで優先順位（敵→モンスター）を検証する
      final monster = JungleMonster(id: 'jungle_0', lane: 0, maxHp: 400);

      game.sync([self, enemy]);
      game.syncMonsters([monster]);
      game.debugSetSelfGridPosition(1.8, -2.8); // enemy_1 の自然配置座標と一致させる
      game.update(0.2);

      expect(game.attackTargetId.value?.isMonster, isFalse);
      expect(game.attackTargetId.value?.id, 'enemy_1');
    });

    test('syncMonsters を複数回呼んでも例外を投げない', () {
      final game = BattlefieldGame();
      final monster = JungleMonster(id: 'jungle_0', lane: 0, maxHp: 400);

      expect(() {
        for (var i = 0; i < 5; i++) {
          game.syncMonsters([monster]);
          game.update(0.2);
        }
      }, returnsNormally);
    });
  });

  group('BattlefieldGame リスポーン時の位置リセット', () {
    test('Botが徘徊で自陣から離れても、死亡→復活すると出撃地点へ戻る', () {
      final game = BattlefieldGame();
      final self = _participant(userId: 'self', team: 0, lane: 0, isSelf: true);
      final enemy = _participant(userId: 'enemy_1', team: 1, lane: 0);

      game.sync([self, enemy]);

      // Bot徘徊ロジックで敵を自キャラへ近づける（出撃地点から動かす）
      for (var i = 0; i < 40; i++) {
        game.update(0.5);
      }
      final approachedNearby = game.enemiesWithinSkillRadius().isNotEmpty;

      // 死亡→復活のサイクルを起こす
      enemy.isAlive = false;
      game.sync([self, enemy]);
      enemy.isAlive = true;
      game.sync([self, enemy]);

      // 出撃地点は自陣/敵陣で離れているため、復活直後は射程外に戻るはず
      expect(approachedNearby, isTrue, reason: '徘徊によって近づいたことの前提が崩れている');
      expect(game.enemiesWithinSkillRadius(), isEmpty);
    });
  });
}
