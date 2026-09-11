// バトル中のスキル進行ViewModel（UI層への暴露）

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shinjuu_league/data/models/evolution_state.dart';
import 'package:shinjuu_league/data/models/skill_catalog.dart';
import 'package:shinjuu_league/services/skill_progression_battle_service.dart';
import 'package:shinjuu_league/services/skill_progression_service.dart';

/// バトル中のプレイヤー1人のスキル進行UI状態
class BattleSkillProgressionUIState {
  final String playerId;
  final int currentLevel;
  final EvolutionType? currentEvolution;
  final bool isEvolutionLocked;
  final bool hasPendingLevelUp;
  final int ult_available;
  final int ult_charging;
  final Map<SkillSlot, double> skillCooldowns;
  final Map<String, double> evolutionBonuses;
  final int? nextEvolutionLevel;

  const BattleSkillProgressionUIState({
    required this.playerId,
    required this.currentLevel,
    this.currentEvolution,
    required this.isEvolutionLocked,
    required this.hasPendingLevelUp,
    required this.ult_available,
    required this.ult_charging,
    required this.skillCooldowns,
    required this.evolutionBonuses,
    this.nextEvolutionLevel,
  });

  /// スキルがロック中か（進化選択画面表示中）
  bool get isLocked => isEvolutionLocked;

  /// ULTが使用可能か
  bool get isUltUnlocked => ult_available == 1;

  /// ULTがチャージ中か
  bool get isUltCharging => ult_charging == 1;

  /// 進化ボーナステキストを取得
  String getEvolutionBonusText() {
    if (currentEvolution == null) {
      return '未進化';
    }

    final dmgBonus = (evolutionBonuses['damage_bonus'] ?? 0.0) * 100;
    final hpBonus = (evolutionBonuses['hp_bonus'] ?? 0.0) * 100;
    final allyBonus = (evolutionBonuses['ally_effect_bonus'] ?? 0.0) * 100;

    switch (currentEvolution!) {
      case EvolutionType.offensive:
        return 'ダメージ +${dmgBonus.toStringAsFixed(0)}%';
      case EvolutionType.defensive:
        return 'HP +${hpBonus.toStringAsFixed(0)}%';
      case EvolutionType.support:
        return '味方効果 +${allyBonus.toStringAsFixed(0)}%';
    }
  }

  /// スキルが準備中か
  bool isSkillReady(SkillSlot slot) {
    final cooldown = skillCooldowns[slot] ?? 0.0;
    return cooldown <= 0.0;
  }

  /// スキルのクールダウン率を取得（0.0～1.0）
  double getSkillCooldownPercent(SkillSlot slot) {
    // TODO: SkillEvolutionService から cooldown を取得して計算
    return 0.0;
  }

  BattleSkillProgressionUIState copyWith({
    String? playerId,
    int? currentLevel,
    EvolutionType? currentEvolution,
    bool? isEvolutionLocked,
    bool? hasPendingLevelUp,
    int? ult_available,
    int? ult_charging,
    Map<SkillSlot, double>? skillCooldowns,
    Map<String, double>? evolutionBonuses,
    int? nextEvolutionLevel,
  }) {
    return BattleSkillProgressionUIState(
      playerId: playerId ?? this.playerId,
      currentLevel: currentLevel ?? this.currentLevel,
      currentEvolution: currentEvolution ?? this.currentEvolution,
      isEvolutionLocked: isEvolutionLocked ?? this.isEvolutionLocked,
      hasPendingLevelUp: hasPendingLevelUp ?? this.hasPendingLevelUp,
      ult_available: ult_available ?? this.ult_available,
      ult_charging: ult_charging ?? this.ult_charging,
      skillCooldowns: skillCooldowns ?? this.skillCooldowns,
      evolutionBonuses: evolutionBonuses ?? this.evolutionBonuses,
      nextEvolutionLevel: nextEvolutionLevel ?? this.nextEvolutionLevel,
    );
  }
}

/// バトル中のスキル進行をUIに公開するViewModel
class BattleSkillProgressionViewModel extends StateNotifier<Map<String, BattleSkillProgressionUIState>> {
  BattleSkillProgressionViewModel({
    SkillProgressionBattleService? service,
  }) : _service = service ?? SkillProgressionBattleService(),
       super({});

  final SkillProgressionBattleService _service;

  /// プレイヤーを初期化
  void initializePlayer({
    required String playerId,
    required String mechaId,
  }) {
    _service.initializePlayer(playerId: playerId, mechaId: mechaId);
    _updatePlayerUIState(playerId);
  }

  /// プレイヤーのスキル進行状態をUIに反映
  void _updatePlayerUIState(String playerId) {
    final progress = _service.getProgress(playerId);
    if (progress == null) return;

    final uiState = BattleSkillProgressionUIState(
      playerId: playerId,
      currentLevel: progress.state.currentLevel,
      currentEvolution: progress.state.evolutionState.currentEvolution,
      isEvolutionLocked: progress.isEvolutionLocked,
      hasPendingLevelUp: progress.hasPendingLevelUp,
      ult_available: progress.state.isUltAvailable() ? 1 : 0,
      ult_charging: progress.state.isUltCharging() ? 1 : 0,
      skillCooldowns: progress.state.skillCooldowns,
      evolutionBonuses: progress.state.getEvolutionBonuses(),
      nextEvolutionLevel: progress.state.getNextEvolutionLevel(),
    );

    state = {...state, playerId: uiState};
  }

  /// プレイヤーのUI状態を取得
  BattleSkillProgressionUIState? getPlayerUIState(String playerId) {
    return state[playerId];
  }

  /// レベルアップを実行
  void levelUpPlayer(String playerId) {
    _service.levelUpPlayer(playerId);
    _updatePlayerUIState(playerId);
  }

  /// スキルを使用
  void useSkill(String playerId, SkillSlot slot) {
    _service.useSkill(playerId, slot);
    _updatePlayerUIState(playerId);
  }

  /// すべてのプレイヤーのクールタイムを更新
  void updateAllCooldowns(double deltaTime) {
    _service.updateAllCooldowns(deltaTime);
    for (final playerId in state.keys) {
      _updatePlayerUIState(playerId);
    }
  }

  /// 進化を確定（Lv3）
  void confirmEvolution(String playerId, EvolutionType choice) {
    _service.confirmEvolution(playerId, choice);
    _updatePlayerUIState(playerId);
  }

  /// 進化を切り替え（Lv6）
  void switchEvolution(String playerId, EvolutionType newChoice) {
    _service.switchEvolution(playerId, newChoice);
    _updatePlayerUIState(playerId);
  }

  /// すべてのプレイヤー状態をリセット
  void reset() {
    _service.dispose();
    state = {};
  }
}

/// Riverpod provider for BattleSkillProgressionViewModel
final battleSkillProgressionViewModelProvider = StateNotifierProvider.autoDispose<
    BattleSkillProgressionViewModel,
    Map<String, BattleSkillProgressionUIState>>(
  (ref) => BattleSkillProgressionViewModel(),
);

/// 単一プレイヤーのスキル進行UI状態を取得するselector
final playerSkillProgressionSelector = FutureProvider.autoDispose.family<
    BattleSkillProgressionUIState?,
    String,
>(
  (ref, playerId) async {
    final viewModel = ref.watch(battleSkillProgressionViewModelProvider);
    return viewModel[playerId];
  },
);
