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

  BattleParticipantState({
    required this.userId,
    required this.mechaId,
    required this.isBot,
    required this.isSelf,
    required this.team,
    required this.lane,
    required this.baseStats,
    this.evolution,
  });

  double get effectiveAtk => baseStats.atk * (evolution?.statBoost.atkMultiplier ?? 1.0);
  double get effectiveHp => baseStats.hp * (evolution?.statBoost.hpMultiplier ?? 1.0);
  double get effectiveSpd => baseStats.spd * (evolution?.statBoost.spdMultiplier ?? 1.0);

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

  Stream<CombatEvent> get combatEvents => _combatController.stream;
  Stream<int> get onTick => _tickController.stream;

  bool get isRunning => _isRunning;
  int get elapsedSeconds => _elapsedSeconds;
  int get remainingSeconds => durationSeconds - _elapsedSeconds;

  void setEvolution(String userId, Evolution evolution) {
    final participant = participants.where((p) => p.userId == userId).firstOrNull;
    participant?.evolution = evolution;
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
      }
    }
  }

  void _resolveEngagements() {
    for (var lane = 0; lane < AppConfig.teamsCount; lane++) {
      final teamAAlive = participants.where((p) => p.team == 0 && p.lane == lane && p.isAlive).toList();
      final teamBAlive = participants.where((p) => p.team == 1 && p.lane == lane && p.isAlive).toList();

      if (teamAAlive.isEmpty || teamBAlive.isEmpty) continue;

      for (final attacker in teamAAlive) {
        if (!attacker.isAlive) continue;
        if (_random.nextDouble() > _engagementChancePerTick) continue;
        final aliveDefenders = teamBAlive.where((p) => p.isAlive).toList();
        if (aliveDefenders.isEmpty) continue;
        _resolveDuel(attacker, aliveDefenders[_random.nextInt(aliveDefenders.length)]);
      }

      for (final attacker in teamBAlive) {
        if (!attacker.isAlive) continue;
        if (_random.nextDouble() > _engagementChancePerTick) continue;
        final aliveDefenders = teamAAlive.where((p) => p.isAlive).toList();
        if (aliveDefenders.isEmpty) continue;
        _resolveDuel(attacker, aliveDefenders[_random.nextInt(aliveDefenders.length)]);
      }
    }
  }

  void _resolveDuel(BattleParticipantState attacker, BattleParticipantState defender) {
    if (!attacker.isAlive || !defender.isAlive) return;

    final attackPower = attacker.effectiveAtk;
    final defensePower = defender.effectiveHp * 0.5 + defender.effectiveSpd * 0.3;
    final winChance = (attackPower / (attackPower + defensePower)).clamp(0.15, 0.85);

    final BattleParticipantState winner;
    final BattleParticipantState loser;
    if (_random.nextDouble() < winChance) {
      winner = attacker;
      loser = defender;
    } else {
      winner = defender;
      loser = attacker;
    }

    winner.kills++;
    loser.deaths++;
    loser.isAlive = false;
    loser.respawnAtSecond = _elapsedSeconds + _respawnDelaySeconds;

    _combatController.add(CombatEvent(
      attackerId: winner.userId,
      victimId: loser.userId,
      tickSecond: _elapsedSeconds,
    ));
  }

  List<PlayerStats> buildPlayerStats() => participants.map((p) => p.toPlayerStats()).toList();

  /// チーム合計スコアで勝敗判定。同点は引き分けなしのランダム決着（MOBAは必ず勝敗をつける）。
  BattleResult resultForUser(String userId) {
    final participant = participants.firstWhere((p) => p.userId == userId);
    final ownScore = participants.where((p) => p.team == participant.team).fold<int>(0, (s, p) => s + p.score);
    final enemyScore = participants.where((p) => p.team != participant.team).fold<int>(0, (s, p) => s + p.score);

    if (ownScore == enemyScore) {
      return _random.nextBool() ? BattleResult.win : BattleResult.loss;
    }
    return ownScore > enemyScore ? BattleResult.win : BattleResult.loss;
  }
}

extension _FirstOrNullExtension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
