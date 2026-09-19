// バトル中のスキル進行管理（BattleEngine連携層）

import 'dart:async';
import 'package:shinjuu_league/data/models/skill_catalog.dart';
import 'package:shinjuu_league/data/models/evolution_state.dart';
import 'package:shinjuu_league/services/skill_progression_service.dart';

/// バトル参加者のスキル進行状態（進化含む）
class BattleSkillProgressionState {
  final String userId;
  final SkillProgressionState state;

  // 進化ロック中フラグ（Lv3/Lv6での選択画面表示中）
  bool isEvolutionLocked = false;

  // 次のレベルアップイベントが待機中か（UI表示用）
  bool hasPendingLevelUp = false;

  BattleSkillProgressionState({
    required this.userId,
    required this.state,
  });

  /// レベルアップ（バトル内での経験値→レベル上昇）
  /// 進化選択が必要な場合は isEvolutionLocked をセットして呼び出し側に通知
  BattleSkillProgressionState levelUp() {
    final newState = state.levelUp();
    final nextEvoLevel = newState.getNextEvolutionLevel();

    // Lv3またはLv6での進化選択が必要か判定
    final isEvolutionPointReached = nextEvoLevel == newState.currentLevel;

    return BattleSkillProgressionState(userId: userId, state: newState)
      ..isEvolutionLocked = isEvolutionPointReached
      ..hasPendingLevelUp = true;
  }

  /// 進化を適用（Lv3）
  BattleSkillProgressionState applyEvolution(EvolutionType choice) {
    final newState = state.applyEvolution(choice);
    return BattleSkillProgressionState(userId: userId, state: newState)
      ..isEvolutionLocked = false;
  }

  /// 進化を切り替え（Lv6）
  BattleSkillProgressionState switchEvolution(EvolutionType newChoice) {
    final newState = state.switchEvolution(newChoice);
    return BattleSkillProgressionState(userId: userId, state: newState)
      ..isEvolutionLocked = false;
  }

  /// スキル使用（クールタイムセット）
  BattleSkillProgressionState useSkill(SkillSlot slot) {
    final newState = state.useSkill(slot);
    return BattleSkillProgressionState(userId: userId, state: newState);
  }

  /// クールタイム更新（毎フレーム減少）
  BattleSkillProgressionState updateCooldowns(double deltaTime) {
    final newState = state.updateCooldowns(deltaTime);
    return BattleSkillProgressionState(userId: userId, state: newState);
  }

  /// 現在のスキルダメージを取得（進化ボーナス含む）
  int getEffectiveSkillDamage(SkillSlot slot) {
    final baseDamage = state.getSkillDamage(slot);
    final bonuses = state.getEvolutionBonuses();
    final damageBonusPercent = (bonuses['damage_bonus'] ?? 0.0);

    // 進化ボーナス（パーセンテージ）を適用
    return (baseDamage * (1.0 + damageBonusPercent)).toInt();
  }

  /// 次の進化レベルを取得
  int? getNextEvolutionLevel() => state.getNextEvolutionLevel();

  /// コピー
  BattleSkillProgressionState copyWith({
    String? userId,
    SkillProgressionState? state,
    bool? isEvolutionLocked,
    bool? hasPendingLevelUp,
  }) {
    return BattleSkillProgressionState(
      userId: userId ?? this.userId,
      state: state ?? this.state,
    )
      ..isEvolutionLocked = isEvolutionLocked ?? this.isEvolutionLocked
      ..hasPendingLevelUp = hasPendingLevelUp ?? this.hasPendingLevelUp;
  }
}

/// バトル中のスキル進行を管理するサービス
/// - 全プレイヤーのスキル進行状態を追跡
/// - レベルアップイベントを発火
/// - 進化選択トリガーを監視
class SkillProgressionBattleService {
  final Map<String, BattleSkillProgressionState> _battleProgression = {};

  // イベントストリーム
  final _levelUpController = StreamController<LevelUpEvent>.broadcast();
  final _evolutionRequiredController = StreamController<EvolutionRequiredEvent>.broadcast();

  Stream<LevelUpEvent> get levelUpEvents => _levelUpController.stream;
  Stream<EvolutionRequiredEvent> get evolutionRequiredEvents => _evolutionRequiredController.stream;

  /// プレイヤーのスキル進行状態を初期化
  void initializePlayer({
    required String playerId,
    required String mechaId,
  }) {
    final state = SkillProgressionState(
      playerId: playerId,
      mechaId: mechaId,
      currentLevel: 1,
      evolutionState: PlayerEvolutionState.initial(mechaId: mechaId, currentLevel: 1),
    );
    _battleProgression[playerId] = BattleSkillProgressionState(
      userId: playerId,
      state: state,
    );
  }

  /// プレイヤーの現在の進行状態を取得
  BattleSkillProgressionState? getProgress(String playerId) {
    return _battleProgression[playerId];
  }

  /// レベルアップを実行し、イベントを発火
  void levelUpPlayer(String playerId) {
    final current = _battleProgression[playerId];
    if (current == null) return;

    final updated = current.levelUp();
    _battleProgression[playerId] = updated;

    // レベルアップイベント発火
    _levelUpController.add(LevelUpEvent(
      playerId: playerId,
      newLevel: updated.state.currentLevel,
      isEvolutionPointReached: updated.isEvolutionLocked,
    ));

    // 進化選択が必要な場合は通知
    if (updated.isEvolutionLocked) {
      _evolutionRequiredController.add(EvolutionRequiredEvent(
        playerId: playerId,
        level: updated.state.currentLevel,
        evolutionType: updated.state.evolutionState.lastEvolutionLevel == 3
          ? EvolutionSelectionType.first
          : EvolutionSelectionType.second,
      ));
    }
  }

  /// スキル使用
  void useSkill(String playerId, SkillSlot slot) {
    final current = _battleProgression[playerId];
    if (current == null) return;

    final updated = current.useSkill(slot);
    _battleProgression[playerId] = updated;
  }

  /// すべてのプレイヤーのクールタイムを更新
  void updateAllCooldowns(double deltaTime) {
    _battleProgression.forEach((playerId, state) {
      _battleProgression[playerId] = state.updateCooldowns(deltaTime);
    });
  }

  /// 進化を確定（Lv3）
  void confirmEvolution(String playerId, EvolutionType choice) {
    final current = _battleProgression[playerId];
    if (current == null || !current.isEvolutionLocked) return;

    final updated = current.applyEvolution(choice);
    _battleProgression[playerId] = updated;
  }

  /// 進化を切り替え（Lv6）
  void switchEvolution(String playerId, EvolutionType newChoice) {
    final current = _battleProgression[playerId];
    if (current == null || !current.isEvolutionLocked) return;

    final updated = current.switchEvolution(newChoice);
    _battleProgression[playerId] = updated;
  }

  /// 全プレイヤーの状態をダンプ（デバッグ用）
  Map<String, dynamic> debugDumpBattleProgression() {
    final result = <String, dynamic>{};
    _battleProgression.forEach((playerId, battleState) {
      result[playerId] = {
        'current_level': battleState.state.currentLevel,
        'current_evolution': battleState.state.evolutionState.currentEvolution?.toString(),
        'is_evolution_locked': battleState.isEvolutionLocked,
        'has_pending_level_up': battleState.hasPendingLevelUp,
        'ult_available': battleState.state.isUltAvailable(),
        'ult_charging': battleState.state.isUltCharging(),
      };
    });
    return result;
  }

  void dispose() {
    _levelUpController.close();
    _evolutionRequiredController.close();
  }
}

/// レベルアップイベント
class LevelUpEvent {
  final String playerId;
  final int newLevel;
  final bool isEvolutionPointReached;

  LevelUpEvent({
    required this.playerId,
    required this.newLevel,
    required this.isEvolutionPointReached,
  });
}

/// 進化選択が必要なイベント
class EvolutionRequiredEvent {
  final String playerId;
  final int level;
  final EvolutionSelectionType evolutionType;

  EvolutionRequiredEvent({
    required this.playerId,
    required this.level,
    required this.evolutionType,
  });
}

enum EvolutionSelectionType {
  first,  // Lv3での初回進化選択
  second, // Lv6での進化切り替え
}
