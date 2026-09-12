// スキル進行管理サービス（バトル中のスキル状態追跡）

import 'package:shinjuu_league/data/models/skill_catalog.dart';
import 'package:shinjuu_league/data/models/evolution_state.dart';
import 'package:shinjuu_league/services/skill_evolution_service.dart';

/// バトル中の単一プレイヤーのスキル進行状態
class SkillProgressionState {
  final String playerId;
  final String mechaId;
  final int currentLevel;
  final PlayerEvolutionState evolutionState;

  // スキルクールタイム追跡（秒単位）
  final Map<SkillSlot, double> skillCooldowns;

  SkillProgressionState({
    required this.playerId,
    required this.mechaId,
    required this.currentLevel,
    required this.evolutionState,
    Map<SkillSlot, double>? skillCooldowns,
  }) : skillCooldowns = skillCooldowns ?? {};

  /// 指定スロットのスキルダメージを取得
  int getSkillDamage(SkillSlot slot) {
    return SkillEvolutionService.getSkillDamageAtLevel(
          mechaId,
          slot,
          currentLevel,
        ) ??
        0;
  }

  /// 指定スロットのスキルクールタイムを取得
  double getSkillCooldown(SkillSlot slot) {
    return SkillEvolutionService.getSkillCooldownAtLevel(
          mechaId,
          slot,
          currentLevel,
        ) ??
        0.0;
  }

  /// スキルが使用可能か（クールタイムがある場合は false）
  bool isSkillReady(SkillSlot slot) {
    final cooldown = skillCooldowns[slot] ?? 0.0;
    return cooldown <= 0.0;
  }

  /// スキル使用時のクールタイム設定
  SkillProgressionState useSkill(SkillSlot slot) {
    final cooldown = getSkillCooldown(slot);
    final updated = Map<SkillSlot, double>.from(skillCooldowns);
    updated[slot] = cooldown;
    return copyWith(skillCooldowns: updated);
  }

  /// フレーム更新（クールタイム減少）
  SkillProgressionState updateCooldowns(double deltaTime) {
    final updated = Map<SkillSlot, double>.from(skillCooldowns);
    skillCooldowns.forEach((slot, cooldown) {
      updated[slot] = (cooldown - deltaTime).clamp(0.0, double.infinity);
    });
    return copyWith(skillCooldowns: updated);
  }

  /// レベルアップ
  SkillProgressionState levelUp() {
    // Lv3/Lv6での進化判定は呼び出し側で実施
    return copyWith(currentLevel: currentLevel + 1);
  }

  /// 進化を適用
  SkillProgressionState applyEvolution(EvolutionType choice) {
    final updatedEvolution =
        evolutionState.selectEvolutionAtLv3(choice);
    return copyWith(evolutionState: updatedEvolution);
  }

  /// Lv6での進化切り替え
  SkillProgressionState switchEvolution(EvolutionType newChoice) {
    final updatedEvolution =
        evolutionState.updateEvolutionAtLv6(newChoice);
    return copyWith(evolutionState: updatedEvolution);
  }

  /// 進化ボーナスを計算
  Map<String, double> getEvolutionBonuses() {
    if (evolutionState.currentEvolution == null) {
      return {
        'damage_bonus': 0.0,
        'hp_bonus': 0.0,
        'ally_effect_bonus': 0.0,
      };
    }

    final levelIntoEvolution =
        currentLevel - (evolutionState.lastEvolutionLevel);
    final isSecondEvolution = evolutionState.lastEvolutionLevel >= 6;

    return SkillEvolutionService.calculateEvolutionBonuses(
      evolutionType: evolutionState.currentEvolution!,
      levelIntoEvolution: levelIntoEvolution,
      isSecondEvolution: isSecondEvolution,
    );
  }

  /// ULTが使用可能か
  bool isUltAvailable() {
    return SkillEvolutionService.isUltUnlocked(currentLevel);
  }

  /// ULTがチャージ中か（Lv5-6）
  bool isUltCharging() {
    return SkillEvolutionService.isUltCharging(currentLevel) &&
        !isUltAvailable();
  }

  /// スキルが解放されているか
  bool isSkillUnlocked(SkillSlot slot) {
    return SkillEvolutionService.isSkillAvailable(currentLevel, slot);
  }

  /// 次の進化レベルを取得
  int? getNextEvolutionLevel() {
    return SkillEvolutionService.getNextEvolutionLevel(currentLevel);
  }

  /// コピー（カスタマイザー付き）
  SkillProgressionState copyWith({
    String? playerId,
    String? mechaId,
    int? currentLevel,
    PlayerEvolutionState? evolutionState,
    Map<SkillSlot, double>? skillCooldowns,
  }) {
    return SkillProgressionState(
      playerId: playerId ?? this.playerId,
      mechaId: mechaId ?? this.mechaId,
      currentLevel: currentLevel ?? this.currentLevel,
      evolutionState: evolutionState ?? this.evolutionState,
      skillCooldowns: skillCooldowns ?? this.skillCooldowns,
    );
  }

  @override
  String toString() =>
      'SkillProgressionState(playerId: $playerId, mechaId: $mechaId, level: $currentLevel, evolution: ${evolutionState.currentEvolution})';
}

/// スキル進行管理サービス
/// - バトル中の全プレイヤーのスキル状態を管理
/// - Lv3/Lv6での進化選択をハンドル
class SkillProgressionService {
  final Map<String, SkillProgressionState> _playerSkills = {};

  /// プレイヤーのスキル進行状態を初期化
  void initializePlayer({
    required String playerId,
    required String mechaId,
  }) {
    _playerSkills[playerId] = SkillProgressionState(
      playerId: playerId,
      mechaId: mechaId,
      currentLevel: 1,
      evolutionState: PlayerEvolutionState.initial(
        mechaId: mechaId,
        currentLevel: 1,
      ),
    );
  }

  /// プレイヤーの現在のスキル状態を取得
  SkillProgressionState? getPlayerSkills(String playerId) {
    return _playerSkills[playerId];
  }

  /// プレイヤーのレベルアップ
  void levelUpPlayer(String playerId) {
    final state = _playerSkills[playerId];
    if (state != null) {
      _playerSkills[playerId] = state.levelUp();
    }
  }

  /// プレイヤーのスキル使用（クールタイム開始）
  void usePlayerSkill(String playerId, SkillSlot slot) {
    final state = _playerSkills[playerId];
    if (state != null && state.isSkillReady(slot)) {
      _playerSkills[playerId] = state.useSkill(slot);
    }
  }

  /// フレーム更新（全プレイヤーのクールタイム減少）
  void updateAllCooldowns(double deltaTime) {
    _playerSkills.forEach((playerId, state) {
      _playerSkills[playerId] = state.updateCooldowns(deltaTime);
    });
  }

  /// プレイヤーの進化を確定（Lv3）
  void confirmEvolution(String playerId, EvolutionType choice) {
    final state = _playerSkills[playerId];
    if (state != null && state.currentLevel >= 3) {
      _playerSkills[playerId] = state.applyEvolution(choice);
    }
  }

  /// プレイヤーの進化を切り替え（Lv6）
  void switchEvolution(String playerId, EvolutionType newChoice) {
    final state = _playerSkills[playerId];
    if (state != null && state.currentLevel >= 6) {
      _playerSkills[playerId] = state.switchEvolution(newChoice);
    }
  }

  /// 次の進化が発生するレベルを取得
  int? getNextEvolutionLevel(String playerId) {
    return _playerSkills[playerId]?.getNextEvolutionLevel();
  }

  /// 全プレイヤーのスキル状態をダンプ（デバッグ用）
  Map<String, dynamic> debugDumpSkillStates() {
    final result = <String, dynamic>{};
    _playerSkills.forEach((playerId, state) {
      result[playerId] = {
        'mecha_id': state.mechaId,
        'current_level': state.currentLevel,
        'current_evolution': state.evolutionState.currentEvolution?.toString(),
        'ult_available': state.isUltAvailable(),
        'ult_charging': state.isUltCharging(),
        'skill_cooldowns': state.skillCooldowns,
      };
    });
    return result;
  }

  /// 状態リセット（新しいバトル開始時）
  void reset() {
    _playerSkills.clear();
  }
}
