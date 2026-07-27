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
