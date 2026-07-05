import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shinjuu_league/config/app_config.dart';
import 'package:shinjuu_league/data/models/battle_model.dart';
import 'package:shinjuu_league/data/models/evolution_model.dart';
import 'package:shinjuu_league/data/models/match_result_model.dart';
import 'package:shinjuu_league/data/models/mecha_model.dart';
import 'package:shinjuu_league/services/analytics_service.dart';
import 'package:shinjuu_league/services/battle_engine_service.dart';
import 'package:shinjuu_league/services/elo_service.dart';
import 'package:shinjuu_league/services/firestore_service.dart';

// TODO(Step 7): Mecha選択画面実装後、参加者ごとの実ステータスを Firestore から取得する
final _defaultBaseStats = BaseStats(hp: 100, atk: 50, spd: 40);

class BattleState {
  const BattleState({
    required this.battle,
    required this.engine,
    required this.elapsedSeconds,
    required this.ahaMomentReached,
    required this.isEvolutionLocked,
    required this.selectedEvolution,
    required this.killFeed,
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
    killFeed: [],
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
  final List<CombatEvent> killFeed;
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
    List<CombatEvent>? killFeed,
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
      killFeed: killFeed ?? this.killFeed,
      isLoading: isLoading ?? this.isLoading,
      isFinished: isFinished ?? this.isFinished,
      error: error,
    );
  }
}

/// Vision 直結: Aha Moment（初回1キル達成）検知はキルイベント発生と同フレームで確定させる。
/// バトル終了を待たず `ahaMomentReached` を即時 true にし、Analytics へも即送信する。
class BattleViewModel extends StateNotifier<BattleState> {
  BattleViewModel({FirestoreService? firestoreService, AnalyticsService? analyticsService})
    : _firestoreService = firestoreService ?? FirestoreService(),
      _analyticsService = analyticsService ?? AnalyticsService(),
      super(BattleState.initial());

  final FirestoreService _firestoreService;
  final AnalyticsService _analyticsService;

  StreamSubscription<CombatEvent>? _combatSub;
  StreamSubscription<int>? _tickSub;

  late String _selfUserId;
  late double _selfEloAtStart;
  late double _opponentAvgElo;

  /// 進化選択画面で呼び出す：エンジンとバトル記録を用意するが、まだ交戦は開始しない。
  /// evolution ロック（[lockEvolution]）→ [beginCombat] の順で呼び出すことで、
  /// 進化ステータスが初手ティックから確実に反映される（試合前進化選択の遅延排除仕様）。
  Future<void> prepareBattle(MatchResult match, String selfUserId, double selfEloAtStart) async {
    state = state.copyWith(isLoading: true, error: null);

    _selfUserId = selfUserId;
    _selfEloAtStart = selfEloAtStart;
    _opponentAvgElo = EloService.averageRating(match.teamB.map((p) => p.eloRating).toList());

    final participants = match.allParticipants
        .map(
          (mp) => BattleParticipantState(
            userId: mp.userId,
            mechaId: mp.mechaId,
            isBot: mp.isBot,
            isSelf: mp.userId == selfUserId,
            team: mp.team,
            lane: mp.lane,
            baseStats: _defaultBaseStats,
          ),
        )
        .toList();

    final engine = BattleEngine(
      battleId: match.matchId,
      mode: match.mode,
      mapId: match.mapId,
      participants: participants,
    );

    _combatSub = engine.combatEvents.listen(_onCombatEvent);
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

    state = state.copyWith(battle: battle, engine: engine, isLoading: false);

    await _firestoreService.createBattle(battle);
    await _analyticsService.logBattleStart(selfUserId, match.mode.name);
  }

  /// 試合前進化選択：ロック後は変更不可（リアルタイム選択は廃止済み仕様）
  void lockEvolution(Evolution evolution) {
    final engine = state.engine;
    if (engine == null || state.isEvolutionLocked) return;

    engine.setEvolution(_selfUserId, evolution);
    state = state.copyWith(selectedEvolution: evolution, isEvolutionLocked: true);
  }

  /// 進化ロック後に交戦シミュレーションを開始する
  void beginCombat() {
    state.engine?.start();
  }

  void _onCombatEvent(CombatEvent event) {
    state = state.copyWith(killFeed: [...state.killFeed, event]);

    if (event.attackerId == _selfUserId && !state.ahaMomentReached) {
      state = state.copyWith(ahaMomentReached: true);
      _analyticsService.logAhaMomentReached(_selfUserId);
    }
  }

  void _onTick(int second, BattleEngine engine) {
    state = state.copyWith(elapsedSeconds: second);

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
    _tickSub?.cancel();
    state.engine?.dispose();
    super.dispose();
  }
}
