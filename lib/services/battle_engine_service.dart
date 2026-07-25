import 'dart:async';
import 'dart:math';
import 'package:shinjuu_league/config/app_config.dart';
import 'package:shinjuu_league/data/models/battle_model.dart';
import 'package:shinjuu_league/data/models/evolution_model.dart';
import 'package:shinjuu_league/data/models/mecha_model.dart';

/// 1秒ごとにレーン内の生存者同士を交戦させる決定論的でないリアルタイムシミュレーション。
/// 真の同期型マルチプレイ通信（専用ゲームサーバー）は将来のスコープ。
/// MVP では Aha Moment（初回1キル）への最短動線を優先し、クライアント側で
/// 即座にキルイベントを発火できるようにする（サーバー側検証は battle/end で別途実施）。
class CombatEvent {
  final String attackerId;
  final String victimId;
  final int tickSecond;

  CombatEvent({
    required this.attackerId,
    required this.victimId,
    required this.tickSecond,
  });
}

class BattleParticipantState {
  final String userId;
  final String mechaId;
  final bool isBot;
  final bool isSelf;
  final int team;
  final int lane;
  final BaseStats baseStats;
  Evolution? evolution;

  int kills = 0;
  int deaths = 0;
  int assists = 0;
  bool isAlive = true;
  int respawnAtSecond = 0;
  late double currentHp;

  BattleParticipantState({
    required this.userId,
    required this.mechaId,
    required this.isBot,
    required this.isSelf,
    required this.team,
    required this.lane,
    required this.baseStats,
    this.evolution,
  }) {
    currentHp = effectiveHp;
  }

  double get effectiveAtk =>
      baseStats.atk * (evolution?.statBoost.atkMultiplier ?? 1.0);
  double get effectiveHp =>
      baseStats.hp * (evolution?.statBoost.hpMultiplier ?? 1.0);
  double get effectiveSpd =>
      baseStats.spd * (evolution?.statBoost.spdMultiplier ?? 1.0);

  int get score => kills * 3 + assists - deaths;

  PlayerStats toPlayerStats() => PlayerStats(
    userId: userId,
    mechaId: mechaId,
    kills: kills,
    deaths: deaths,
    assists: assists,
    score: score,
  );
}

class BattleEngine {
  static const _respawnDelaySeconds = 8;
  static const _engagementChancePerTick = 0.12;
  static const _hitDamageFactor = 0.35;
  static const _skillDamageMultiplier = 2.2;

  final String battleId;
  final BattleMode mode;
  final String mapId;
  final List<BattleParticipantState> participants;
  final int durationSeconds;

  BattleEngine({
    required this.battleId,
    required this.mode,
    required this.mapId,
    required this.participants,
    this.durationSeconds = AppConfig.battleDurationSeconds,
    Random? random,
  }) : _random = random ?? Random();

  final Random _random;
  Timer? _timer;
  int _elapsedSeconds = 0;
  bool _isRunning = false;

  // sync:true でキルイベントを同フレームで即時配信する（Aha Momentの即時検知に必要）
  final _combatController = StreamController<CombatEvent>.broadcast(sync: true);
  final _tickController = StreamController<int>.broadcast();
  // 撃破に至らない被弾（HP削り）を通知する。killFeed/Aha Momentには影響させない。
  final _hitController = StreamController<CombatEvent>.broadcast(sync: true);

  Stream<CombatEvent> get combatEvents => _combatController.stream;
  Stream<int> get onTick => _tickController.stream;
  Stream<CombatEvent> get hitEvents => _hitController.stream;

  bool get isRunning => _isRunning;
  int get elapsedSeconds => _elapsedSeconds;
  int get remainingSeconds => durationSeconds - _elapsedSeconds;

  void setEvolution(String userId, Evolution evolution) {
    final participant = participants
        .where((p) => p.userId == userId)
        .firstOrNull;
    if (participant == null) return;
    participant.evolution = evolution;
    // 進化ボーナスでHP上限が変わるため、交戦開始前に満タンへ再計算する
    participant.currentHp = participant.effectiveHp;
  }

  void start() {
    if (_isRunning) return;
    _isRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => tick());
  }

  void stop() {
    _isRunning = false;
    _timer?.cancel();
  }

  void dispose() {
    stop();
    _combatController.close();
    _tickController.close();
    _hitController.close();
  }

  /// 1秒分のシミュレーションを進める。Timer.periodic から呼ばれる他、
  /// テストから直接呼び出すことで実時間を待たずに決着を検証できる。
  void tick() {
    _elapsedSeconds++;
    _resolveRespawns();
    _resolveEngagements();
    _tickController.add(_elapsedSeconds);

    if (_elapsedSeconds >= durationSeconds) {
      stop();
    }
  }

  void _resolveRespawns() {
    for (final p in participants) {
      if (!p.isAlive && _elapsedSeconds >= p.respawnAtSecond) {
        p.isAlive = true;
        p.currentHp = p.effectiveHp;
      }
    }
  }

  void _resolveEngagements() {
    for (var lane = 0; lane < AppConfig.teamsCount; lane++) {
      final teamAAlive = participants
          .where((p) => p.team == 0 && p.lane == lane && p.isAlive)
          .toList();
      final teamBAlive = participants
          .where((p) => p.team == 1 && p.lane == lane && p.isAlive)
          .toList();

      if (teamAAlive.isEmpty || teamBAlive.isEmpty) continue;

      for (final attacker in teamAAlive) {
        if (!attacker.isAlive) continue;
        if (_random.nextDouble() > _engagementChancePerTick) continue;
        final aliveDefenders = teamBAlive.where((p) => p.isAlive).toList();
        if (aliveDefenders.isEmpty) continue;
        final defender = aliveDefenders[_random.nextInt(aliveDefenders.length)];
        _applyDamage(attacker, defender, _computeDamage(attacker, defender));
      }

      for (final attacker in teamBAlive) {
        if (!attacker.isAlive) continue;
        if (_random.nextDouble() > _engagementChancePerTick) continue;
        final aliveDefenders = teamAAlive.where((p) => p.isAlive).toList();
        if (aliveDefenders.isEmpty) continue;
        final defender = aliveDefenders[_random.nextInt(aliveDefenders.length)];
        _applyDamage(attacker, defender, _computeDamage(attacker, defender));
      }
    }
  }

  /// 素早さが高いほど被弾を軽減する（回避寄りの簡易ミティゲーション）
  double _computeDamage(
    BattleParticipantState attacker,
    BattleParticipantState defender,
  ) {
    final mitigation =
        1.0 - (defender.effectiveSpd / (defender.effectiveSpd + 200));
    return attacker.effectiveAtk * _hitDamageFactor * mitigation;
  }

  /// HPを削り、0以下になった時点で撃破として確定する（即死判定ではなく削り合い）。
  /// 撃破に至らない場合は `hitEvents` のみへ通知し、killFeed/Aha Momentは反応させない。
  void _applyDamage(
    BattleParticipantState attacker,
    BattleParticipantState defender,
    double damage,
  ) {
    if (!attacker.isAlive || !defender.isAlive) return;

    defender.currentHp = (defender.currentHp - damage).clamp(
      0.0,
      double.infinity,
    );

    if (defender.currentHp <= 0) {
      attacker.kills++;
      defender.deaths++;
      defender.isAlive = false;
      defender.respawnAtSecond = _elapsedSeconds + _respawnDelaySeconds;

      _combatController.add(
        CombatEvent(
          attackerId: attacker.userId,
          victimId: defender.userId,
          tickSecond: _elapsedSeconds,
        ),
      );
    } else {
      _hitController.add(
        CombatEvent(
          attackerId: attacker.userId,
          victimId: defender.userId,
          tickSecond: _elapsedSeconds,
        ),
      );
    }
  }

  List<PlayerStats> buildPlayerStats() =>
      participants.map((p) => p.toPlayerStats()).toList();

  /// プレイヤーがマップ上で敵に接近して発動する手動攻撃（Pokémon UNITE風の接近戦）。
  /// 範囲判定はUI層（BattlefieldGame）が担当し、ここではチーム・生死のみ検証して
  /// 自動交戦と同じ `_applyDamage` を再利用する（ダメージ計算ロジックを二重管理しない）。
  bool manualDuel(String attackerId, String victimId) {
    final attacker = participants
        .where((p) => p.userId == attackerId)
        .firstOrNull;
    final victim = participants.where((p) => p.userId == victimId).firstOrNull;
    if (attacker == null || victim == null) return false;
    if (!attacker.isAlive || !victim.isAlive) return false;
    if (attacker.team == victim.team) return false;

    _applyDamage(attacker, victim, _computeDamage(attacker, victim));
    return true;
  }

  /// プレイヤーのスキル発動（クールタイム付き範囲攻撃）。指定半径内の敵全員に
  /// 通常攻撃よりも高い倍率でダメージを与える。範囲判定はBattlefieldGame側が担当。
  bool manualSkill(String attackerId, List<String> targetIdsInRange) {
    final attacker = participants
        .where((p) => p.userId == attackerId)
        .firstOrNull;
    if (attacker == null || !attacker.isAlive) return false;

    var hitAny = false;
    for (final targetId in targetIdsInRange) {
      final target = participants
          .where((p) => p.userId == targetId)
          .firstOrNull;
      if (target == null) continue;
      if (!target.isAlive || target.team == attacker.team) continue;
      _applyDamage(
        attacker,
        target,
        _computeDamage(attacker, target) * _skillDamageMultiplier,
      );
      hitAny = true;
    }
    return hitAny;
  }

  /// チーム合計スコアで勝敗判定。同点は引き分けなしのランダム決着（MOBAは必ず勝敗をつける）。
  BattleResult resultForUser(String userId) {
    final participant = participants.firstWhere((p) => p.userId == userId);
    final ownScore = participants
        .where((p) => p.team == participant.team)
        .fold<int>(0, (s, p) => s + p.score);
    final enemyScore = participants
        .where((p) => p.team != participant.team)
        .fold<int>(0, (s, p) => s + p.score);

    if (ownScore == enemyScore) {
      return _random.nextBool() ? BattleResult.win : BattleResult.loss;
    }
    return ownScore > enemyScore ? BattleResult.win : BattleResult.loss;
  }
}

extension _FirstOrNullExtension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
