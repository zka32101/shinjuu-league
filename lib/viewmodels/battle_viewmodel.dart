import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shinjuu_league/config/app_config.dart';
import 'package:shinjuu_league/data/mecha_catalog.dart';
import 'package:shinjuu_league/data/models/battle_model.dart';
import 'package:shinjuu_league/data/models/evolution_model.dart';
import 'package:shinjuu_league/data/models/match_result_model.dart';
import 'package:shinjuu_league/data/models/resource_model.dart';
import 'package:shinjuu_league/data/models/skill_model.dart';
import 'package:shinjuu_league/services/analytics_service.dart';
import 'package:shinjuu_league/services/battle_engine_service.dart';
import 'package:shinjuu_league/services/elo_service.dart';
import 'package:shinjuu_league/services/firestore_service.dart';

class BattleState {
  const BattleState({
    required this.battle,
    required this.engine,
    required this.elapsedSeconds,
    required this.ahaMomentReached,
    required this.isEvolutionLocked,
    required this.selectedEvolution,
    required this.skillBuild,
    required this.playerResources,
    required this.killFeed,
    required this.hitFeed,
    required this.damageEvents,
    required this.isLoading,
    required this.isFinished,
    required this.error,
  });

  factory BattleState.initial() => const BattleState(
    battle: null,
    engine: null,
    elapsedSeconds: 0,
    ahaMomentReached: false,
    isEvolutionLocked: false,
    selectedEvolution: null,
    skillBuild: null,
    playerResources: null,
    killFeed: [],
    hitFeed: [],
    damageEvents: [],
    isLoading: false,
    isFinished: false,
    error: null,
  );

  final Battle? battle;
  final BattleEngine? engine;
  final int elapsedSeconds;
  final bool ahaMomentReached;
  final bool isEvolutionLocked;
  final Evolution? selectedEvolution;
  final SkillBuild? skillBuild;
  final PlayerResources? playerResources;
  final List<CombatEvent> killFeed;
  final List<CombatEvent> hitFeed;
  final List<DamageEvent> damageEvents;
  final bool isLoading;
  final bool isFinished;
  final String? error;

  BattleState copyWith({
    Battle? battle,
    BattleEngine? engine,
    int? elapsedSeconds,
    bool? ahaMomentReached,
    bool? isEvolutionLocked,
    Evolution? selectedEvolution,
    SkillBuild? skillBuild,
    PlayerResources? playerResources,
    List<CombatEvent>? killFeed,
    List<CombatEvent>? hitFeed,
    List<DamageEvent>? damageEvents,
    bool? isLoading,
    bool? isFinished,
    String? error,
  }) {
    return BattleState(
      battle: battle ?? this.battle,
      engine: engine ?? this.engine,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      ahaMomentReached: ahaMomentReached ?? this.ahaMomentReached,
      isEvolutionLocked: isEvolutionLocked ?? this.isEvolutionLocked,
      selectedEvolution: selectedEvolution ?? this.selectedEvolution,
      skillBuild: skillBuild ?? this.skillBuild,
      playerResources: playerResources ?? this.playerResources,
      killFeed: killFeed ?? this.killFeed,
      hitFeed: hitFeed ?? this.hitFeed,
      damageEvents: damageEvents ?? this.damageEvents,
      isLoading: isLoading ?? this.isLoading,
      isFinished: isFinished ?? this.isFinished,
      error: error,
    );
  }
}

/// Vision 直結: Aha Moment（初回1キル達成）検知はキルイベント発生と同フレームで確定させる。
/// バトル終了を待たず `ahaMomentReached` を即時 true にし、Analytics へも即送信する。
class BattleViewModel extends StateNotifier<BattleState> {
  BattleViewModel({
    FirestoreService? firestoreService,
    AnalyticsService? analyticsService,
  }) : _firestoreService = firestoreService ?? FirestoreService(),
       _analyticsService = analyticsService ?? AnalyticsService(),
       super(BattleState.initial());

  final FirestoreService _firestoreService;
  final AnalyticsService _analyticsService;

  StreamSubscription<CombatEvent>? _combatSub;
  StreamSubscription<CombatEvent>? _hitSub;
  StreamSubscription<int>? _tickSub;
  StreamSubscription<DamageEvent>? _damageSub;

  late String _selfUserId;
  late double _selfEloAtStart;
  late double _opponentAvgElo;

  /// 進化選択画面で呼び出す：エンジンとバトル記録を用意するが、まだ交戦は開始しない。
  /// evolution ロック（[lockEvolution]）→ [beginCombat] の順で呼び出すことで、
  /// 進化ステータスが初手ティックから確実に反映される（試合前進化選択の遅延排除仕様）。
  Future<void> prepareBattle(
    MatchResult match,
    String selfUserId,
    double selfEloAtStart,
  ) async {
    state = state.copyWith(isLoading: true, error: null);

    _selfUserId = selfUserId;
    _selfEloAtStart = selfEloAtStart;
    _opponentAvgElo = EloService.averageRating(
      match.teamB.map((p) => p.eloRating).toList(),
    );

    final participants = match.allParticipants
        .map(
          (mp) {
            // 自分の場合は初期リソース（100 mana, 0 gold）を設定、Botは後で設定
            final initialResources = mp.userId == selfUserId
                ? PlayerResources(
                    currentMana: 100,
                    maxMana: 100,
                    gold: 0,
                    ownedItemIds: [],
                  )
                : null;

            return BattleParticipantState(
              userId: mp.userId,
              mechaId: mp.mechaId,
              isBot: mp.isBot,
              isSelf: mp.userId == selfUserId,
              team: mp.team,
              lane: mp.lane,
              baseStats: mechaById(mp.mechaId).baseStats,
              resources: initialResources,
            );
          },
        )
        .toList();

    final engine = BattleEngine(
      battleId: match.matchId,
      mode: match.mode,
      mapId: match.mapId,
      participants: participants,
    );

    _combatSub = engine.combatEvents.listen(_onCombatEvent);
    _hitSub = engine.hitEvents.listen(_onHitEvent);
    _damageSub = engine.damageEvents.listen(_onDamageEvent);
    _tickSub = engine.onTick.listen((second) => _onTick(second, engine));

    final battle = Battle(
      battleId: match.matchId,
      userId: selfUserId,
      opponentIds: match.teamB.map((p) => p.userId).toList(),
      mapId: match.mapId,
      mode: match.mode,
      durationSeconds: AppConfig.battleDurationSeconds,
      playerStats: engine.buildPlayerStats(),
      result: BattleResult.pending,
      eloChange: 0.0,
      startedAt: DateTime.now(),
    );

    // Initialize playerResources for UI display
    final initialResources = PlayerResources(
      currentMana: 100,
      maxMana: 100,
      gold: 0,
      ownedItemIds: [],
    );

    state = state.copyWith(
      battle: battle,
      engine: engine,
      playerResources: initialResources,
      isLoading: false,
    );

    await _firestoreService.createBattle(battle);
    await _analyticsService.logBattleStart(selfUserId, match.mode.name);
  }

  /// 試合前進化選択：ロック後は変更不可（リアルタイム選択は廃止済み仕様）
  void lockEvolution(Evolution evolution) {
    final engine = state.engine;
    if (engine == null || state.isEvolutionLocked) return;

    engine.setEvolution(_selfUserId, evolution);
    state = state.copyWith(
      selectedEvolution: evolution,
      isEvolutionLocked: true,
    );
  }

  /// 進化ロック後に交戦シミュレーションを開始する
  void beginCombat() {
    state.engine?.start();
  }

  DateTime? _lastManualAttackAt;
  static const _manualAttackCooldown = Duration(milliseconds: 900);

  /// プレイヤーがマップ上で敵に接近して手動攻撃ボタンを押した時に呼ばれる。
  /// 範囲判定はBattlefieldGame側で済んでいる前提。連打防止のクールダウンのみここで管理。
  void attemptManualAttack(String targetUserId) {
    final engine = state.engine;
    if (engine == null) return;

    final now = DateTime.now();
    if (_lastManualAttackAt != null &&
        now.difference(_lastManualAttackAt!) < _manualAttackCooldown) {
      return;
    }

    final resolved = engine.manualDuel(_selfUserId, targetUserId);
    if (resolved) {
      _lastManualAttackAt = now;
    }
  }

  DateTime? _lastManualSkillAt;
  static const _manualSkillCooldown = Duration(seconds: 6);

  /// クールタイム中かどうか（UIのスキルボタン表示に使う）
  bool get isSkillOnCooldown {
    if (_lastManualSkillAt == null) return false;
    return DateTime.now().difference(_lastManualSkillAt!) <
        _manualSkillCooldown;
  }

  /// プレイヤーのスキル発動。範囲内の対象idはBattlefieldGame側で判定済みの前提。
  void attemptManualSkill(List<String> targetIdsInRange) {
    final engine = state.engine;
    if (engine == null || isSkillOnCooldown) return;

    engine.manualSkill(_selfUserId, targetIdsInRange);
    _lastManualSkillAt = DateTime.now();
  }

  /// スキルビルドを選択して保存する（進化選択後、バトル開始前に呼ばれる想定）
  void selectSkillBuild(SkillBuild skillBuild) {
    // 初期リソースを設定：最大100マナ、0ゴール
    final resources = PlayerResources(
      currentMana: 100,
      maxMana: 100,
      gold: 0,
      ownedItemIds: [],
    );
    state = state.copyWith(skillBuild: skillBuild, playerResources: resources);
  }

  /// エンジンのリソース状態を反映（毎フレーム tick で呼ばれる想定）
  void _updatePlayerResources() {
    final engine = state.engine;
    BattleParticipantState? selfParticipant;
    if (engine != null) {
      try {
        selfParticipant = engine.participants.firstWhere(
          (p) => p.userId == _selfUserId,
        );
      } catch (_) {
        selfParticipant = null;
      }
    }

    if (selfParticipant != null && state.playerResources != null) {
      final updated = state.playerResources!.copyWith(
        currentMana: selfParticipant.resources?.currentMana ?? 100.0,
        gold: selfParticipant.resources?.gold ?? 0,
        ownedItemIds: selfParticipant.resources?.ownedItemIds ?? [],
      );
      state = state.copyWith(playerResources: updated);
    }
  }

  /// スキルを発動する（mana コストと cooldown をサーバー側で管理）
  void attemptSkill(String skillId) {
    final engine = state.engine;
    final skillBuild = state.skillBuild;
    if (engine == null || skillBuild == null) return;

    final targets = <String>[]; // UI側で targets を計算して渡すか、ここで計算
    engine.useSkill(_selfUserId, skillId, targets);
  }

  /// アイテムを購入する（gold コストと在庫数をサーバー側で管理）
  void attemptPurchaseItem(String itemId) {
    final engine = state.engine;
    if (engine == null) return;

    engine.purchaseItem(_selfUserId, itemId);
  }

  void _onCombatEvent(CombatEvent event) {
    state = state.copyWith(killFeed: [...state.killFeed, event]);

    if (event.attackerId == _selfUserId && !state.ahaMomentReached) {
      state = state.copyWith(ahaMomentReached: true);
      _analyticsService.logAhaMomentReached(_selfUserId);
    }
  }

  void _onHitEvent(CombatEvent event) {
    state = state.copyWith(hitFeed: [...state.hitFeed, event]);
  }

  void _onDamageEvent(DamageEvent event) {
    state = state.copyWith(damageEvents: [...state.damageEvents, event]);
  }

  void _onTick(int second, BattleEngine engine) {
    state = state.copyWith(elapsedSeconds: second);
    _updatePlayerResources();

    if (!engine.isRunning && !state.isFinished) {
      unawaited(_finishBattle(engine));
    }
  }

  Future<void> _finishBattle(BattleEngine engine) async {
    final battle = state.battle;
    if (battle == null) return;

    final result = engine.resultForUser(_selfUserId);
    final eloChange = EloService.calculateEloChange(
      currentRating: _selfEloAtStart,
      opponentAvgRating: _opponentAvgElo,
      isWin: result == BattleResult.win,
    );

    final finishedBattle = Battle(
      battleId: battle.battleId,
      userId: battle.userId,
      opponentIds: battle.opponentIds,
      mapId: battle.mapId,
      mode: battle.mode,
      durationSeconds: battle.durationSeconds,
      playerStats: engine.buildPlayerStats(),
      result: result,
      eloChange: eloChange,
      startedAt: battle.startedAt,
      endedAt: DateTime.now(),
    );

    state = state.copyWith(battle: finishedBattle, isFinished: true);

    await _firestoreService.updateBattle(finishedBattle);
    await _analyticsService.logBattleEnd(
      _selfUserId,
      finishedBattle.battleId,
      result.name,
      finishedBattle.kills,
      finishedBattle.deaths,
    );

    if (battle.mode == BattleMode.ranked) {
      await _analyticsService.logFirstRankedEntry(_selfUserId);
    }
  }

  @override
  void dispose() {
    _combatSub?.cancel();
    _hitSub?.cancel();
    _tickSub?.cancel();
    _damageSub?.cancel();
    state.engine?.dispose();
    super.dispose();
  }
}
