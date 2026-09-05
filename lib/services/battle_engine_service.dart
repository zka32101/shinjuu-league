import 'dart:async';
import 'dart:math';
import 'package:shinjuu_league/config/app_config.dart';
import 'package:shinjuu_league/data/models/battle_model.dart';
import 'package:shinjuu_league/data/models/evolution_model.dart';
import 'package:shinjuu_league/data/models/mecha_model.dart';
import 'package:shinjuu_league/data/models/resource_model.dart';
import 'package:shinjuu_league/data/models/skill_model.dart';
import 'package:shinjuu_league/services/skill_system_service.dart';

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

/// ダメージイベント（ダメージ数値表示用）
class DamageEvent {
  final String attackerId;
  final String victimId;
  final int damage;
  final bool isCritical;
  final int tickSecond;

  DamageEvent({
    required this.attackerId,
    required this.victimId,
    required this.damage,
    this.isCritical = false,
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

  // リソース管理
  late PlayerResources resources;
  SkillBuild? skillBuild;
  final Map<String, double> skillCooldowns = {}; // skillId -> 残りクールダウン秒数

  int kills = 0;
  int deaths = 0;
  int assists = 0;
  bool isAlive = true;
  int respawnAtSecond = 0;
  late double currentHp;
  int totalGoldEarned = 0; // 試合中のゴール累計

  BattleParticipantState({
    required this.userId,
    required this.mechaId,
    required this.isBot,
    required this.isSelf,
    required this.team,
    required this.lane,
    required this.baseStats,
    this.evolution,
    this.skillBuild,
    PlayerResources? initialResources,
  }) {
    currentHp = effectiveHp;
    resources = initialResources ??
        PlayerResources(
          currentMana: 100,
          maxMana: 100,
          gold: 0,
        );
    _initializeSkillCooldowns();
  }

  void _initializeSkillCooldowns() {
    if (skillBuild != null) {
      final skills = SkillSystemService.getSkillsForMecha(mechaId);
      for (final skill in skills) {
        skillCooldowns[skill.skillId] = 0.0;
      }
    }
  }

  double get effectiveAtk {
    final baseAtk = baseStats.atk * (evolution?.statBoost.atkMultiplier ?? 1.0);
    final itemBonuses = SkillSystemService.calculateItemBonuses(
      ownedItemIds: resources.ownedItemIds,
      baseStats: BaseStats(hp: baseStats.hp, atk: baseAtk.toInt(), spd: baseStats.spd),
    );
    return baseAtk + itemBonuses.atk;
  }

  double get effectiveHp {
    final baseHp = baseStats.hp * (evolution?.statBoost.hpMultiplier ?? 1.0);
    final itemBonuses = SkillSystemService.calculateItemBonuses(
      ownedItemIds: resources.ownedItemIds,
      baseStats: BaseStats(hp: baseHp.toInt(), atk: baseStats.atk, spd: baseStats.spd),
    );
    return baseHp + itemBonuses.hp;
  }

  double get effectiveSpd {
    final baseSpd = baseStats.spd * (evolution?.statBoost.spdMultiplier ?? 1.0);
    final itemBonuses = SkillSystemService.calculateItemBonuses(
      ownedItemIds: resources.ownedItemIds,
      baseStats: BaseStats(hp: baseStats.hp, atk: baseStats.atk, spd: baseSpd.toInt()),
    );
    return baseSpd + itemBonuses.spd;
  }

  int get score => kills * 3 + assists - deaths;

  /// スキルが使用可能か判定
  bool canUseSkill(String skillId) {
    final skill = SkillSystemService.getSkillDefinition(skillId);
    if (skill == null) return false;

    // スキルビルドレベルを取得
    final level = _getSkillLevel(skillId);
    if (level == 0) return false;

    // マナコストを取得
    final cost = skill.getCostAtLevel(level);

    // マナとクールダウンをチェック
    return resources.canAffordMana(cost) &&
        (skillCooldowns[skillId] ?? 0.0) <= 0.0;
  }

  /// スキルレベルを取得
  int _getSkillLevel(String skillId) {
    if (skillBuild == null) return 0;
    if (skillId == skillBuild!.skillId1) return skillBuild!.level1;
    if (skillId == skillBuild!.skillId2) return skillBuild!.level2;
    if (skillId == skillBuild!.skillId3) return skillBuild!.level3;
    return 0;
  }

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
  // ダメージイベント（ダメージ数値表示用）
  final _damageController = StreamController<DamageEvent>.broadcast(sync: true);

  Stream<CombatEvent> get combatEvents => _combatController.stream;
  Stream<int> get onTick => _tickController.stream;
  Stream<CombatEvent> get hitEvents => _hitController.stream;
  Stream<DamageEvent> get damageEvents => _damageController.stream;

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
    _damageController.close();
  }

  /// 1秒分のシミュレーションを進める。Timer.periodic から呼ばれる他、
  /// テストから直接呼び出すことで実時間を待たずに決着を検証できる。
  void tick() {
    _elapsedSeconds++;
    _resolveRespawns();
    _updateResources(); // マナ回復・ゴール配分・クールダウン減少
    _resolveEngagements();
    _tickController.add(_elapsedSeconds);

    if (_elapsedSeconds >= durationSeconds) {
      stop();
    }
  }

  /// マナ自然リジェン・パッシブゴール・スキルクールダウン更新
  void _updateResources() {
    for (final p in participants) {
      if (!p.isAlive) continue;

      // マナ回復
      p.resources = p.resources.regenMana(SkillSystemService.manaRegenPerSecond);

      // パッシブゴール獲得
      p.resources = p.resources.addGold(GoldRewards.passiveGoldPerSecond);
      p.totalGoldEarned += GoldRewards.passiveGoldPerSecond;

      // スキルクールダウン減少
      p.skillCooldowns.forEach((skillId, cooldown) {
        if (cooldown > 0) {
          p.skillCooldowns[skillId] = cooldown - 1.0;
        }
      });
    }
  }

  /// スキルを発動（マナコスト・クールダウンを適用）
  bool useSkill(String userId, String skillId, List<String> targetUserIds) {
    final attacker = participants.firstWhere(
      (p) => p.userId == userId,
      orElse: () => throw Exception('User not found: $userId'),
    );

    if (!attacker.isAlive) return false;
    if (!attacker.canUseSkill(skillId)) return false;

    final skill = SkillSystemService.getSkillDefinition(skillId);
    if (skill == null) return false;

    final level = attacker._getSkillLevel(skillId);
    final cost = skill.getCostAtLevel(level);

    // マナ消費
    attacker.resources = attacker.resources.spendMana(cost);

    // クールダウン設定
    final cooldownTime = skill.getCooldownAtLevel(level);
    attacker.skillCooldowns[skillId] = cooldownTime;

    // ダメージ適用
    final damageMultiplier = skill.getDamageMultiplierAtLevel(level);
    for (final targetId in targetUserIds) {
      final target = participants.firstWhere(
        (p) => p.userId == targetId,
        orElse: () => throw Exception('Target not found: $targetId'),
      );

      if (target.isAlive && target.team != attacker.team) {
        final damageResult = _computeDamage(attacker, target);
        final damage = damageResult.damage * damageMultiplier;
        _applyDamage(attacker, target, damage, damageResult.isCritical);
      }
    }

    return true;
  }

  /// アイテムを購入
  bool purchaseItem(String userId, String itemId) {
    final participant = participants.firstWhere(
      (p) => p.userId == userId,
      orElse: () => throw Exception('User not found: $userId'),
    );

    final item = SkillSystemService.getItemDefinition(itemId);
    if (item == null) return false;
    if (!participant.resources.canAffordGold(item.cost)) return false;

    // ゴール消費・アイテム購入
    participant.resources = participant.resources.purchaseItem(itemId, item.cost);

    // TODO: アイテムボーナスをステータスに反映
    // 今後：EffectiveStatの計算でアイテムボーナスを加算

    return true;
  }

  /// キル報酬・アシスト報酬
  void awardKillReward(String killerId, List<String> assistantIds) {
    final killer = participants.firstWhere(
      (p) => p.userId == killerId,
      orElse: () => throw Exception('Killer not found: $killerId'),
    );

    killer.resources = killer.resources.addGold(GoldRewards.killReward);
    killer.totalGoldEarned += GoldRewards.killReward;

    for (final assistantId in assistantIds) {
      final assistant = participants.firstWhere(
        (p) => p.userId == assistantId,
        orElse: () => throw Exception('Assistant not found: $assistantId'),
      );
      assistant.resources = assistant.resources.addGold(GoldRewards.assistReward);
      assistant.totalGoldEarned += GoldRewards.assistReward;
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
        final damageResult = _computeDamage(attacker, defender);
        _applyDamage(attacker, defender, damageResult.damage, damageResult.isCritical);
      }

      for (final attacker in teamBAlive) {
        if (!attacker.isAlive) continue;
        if (_random.nextDouble() > _engagementChancePerTick) continue;
        final aliveDefenders = teamAAlive.where((p) => p.isAlive).toList();
        if (aliveDefenders.isEmpty) continue;
        final defender = aliveDefenders[_random.nextInt(aliveDefenders.length)];
        final damageResult = _computeDamage(attacker, defender);
        _applyDamage(attacker, defender, damageResult.damage, damageResult.isCritical);
      }
    }
  }

  /// 素早さが高いほど被弾を軽減する（回避寄りの簡易ミティゲーション）
  /// 攻撃力が高いほどクリティカル確率が上がる
  ({double damage, bool isCritical}) _computeDamage(
    BattleParticipantState attacker,
    BattleParticipantState defender,
  ) {
    final mitigation =
        1.0 - (defender.effectiveSpd / (defender.effectiveSpd + 200));
    final baseDamage = attacker.effectiveAtk * _hitDamageFactor * mitigation;

    // クリティカル判定：攻撃力 / 600 が基本確率（最大25%）
    final critChance = (attacker.effectiveAtk / 600).clamp(0, 0.25);
    final isCritical = _random.nextDouble() < critChance;

    final finalDamage = isCritical ? baseDamage * 2.0 : baseDamage;

    return (damage: finalDamage, isCritical: isCritical);
  }

  /// HPを削り、0以下になった時点で撃破として確定する（即死判定ではなく削り合い）。
  /// 撃破に至らない場合は `hitEvents` のみへ通知し、killFeed/Aha Momentは反応させない。
  /// ダメージイベントは常に emitされ、ダメージ数値表示に使用される。
  void _applyDamage(
    BattleParticipantState attacker,
    BattleParticipantState defender,
    double damage,
    bool isCritical,
  ) {
    if (!attacker.isAlive || !defender.isAlive) return;

    defender.currentHp = (defender.currentHp - damage).clamp(
      0.0,
      double.infinity,
    );

    // ダメージイベント（ダメージ数値表示用、常に emit）
    _damageController.add(
      DamageEvent(
        attackerId: attacker.userId,
        victimId: defender.userId,
        damage: damage.toInt(),
        isCritical: isCritical,
        tickSecond: _elapsedSeconds,
      ),
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
  /// 範囲判定はUI層（BattlefieldGame）が担当し、ここではチーム・レーン・生死を検証して
  /// 自動交戦と同じ `_applyDamage` を再利用する（ダメージ計算ロジックを二重管理しない）。
  /// laneが一致しない相手を攻撃できてしまうと2レーン制の設計そのものが崩れるため必須の検証。
  bool manualDuel(String attackerId, String victimId) {
    final attacker = participants
        .where((p) => p.userId == attackerId)
        .firstOrNull;
    final victim = participants.where((p) => p.userId == victimId).firstOrNull;
    if (attacker == null || victim == null) return false;
    if (!attacker.isAlive || !victim.isAlive) return false;
    if (attacker.team == victim.team) return false;
    if (attacker.lane != victim.lane) return false;

    final damageResult = _computeDamage(attacker, victim);
    _applyDamage(attacker, victim, damageResult.damage, damageResult.isCritical);
    return true;
  }

  /// プレイヤーのスキル発動（クールタイム付き範囲攻撃）。指定半径内の敵全員に
  /// 通常攻撃よりも高い倍率でダメージを与える。範囲判定はBattlefieldGame側が担当。
  /// manualDuelと同様、レーンをまたいだ対象は除外する。
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
      if (!target.isAlive ||
          target.team == attacker.team ||
          target.lane != attacker.lane) {
        continue;
      }
      final damageResult = _computeDamage(attacker, target);
      _applyDamage(
        attacker,
        target,
        damageResult.damage * _skillDamageMultiplier,
        damageResult.isCritical,
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
