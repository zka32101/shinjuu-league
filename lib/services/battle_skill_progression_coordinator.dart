// バトル進行時にスキル進行と進化選択を調整するコーディネーター

import 'dart:async';
import 'package:shinjuu_league/config/skill_progression_config.dart';
import 'package:shinjuu_league/data/models/evolution_state.dart';
import 'package:shinjuu_league/data/models/skill_catalog.dart';
import 'package:shinjuu_league/services/skill_progression_battle_service.dart';

/// バトル進行中に発生するスキル関連イベント
abstract class BattleSkillEvent {
  final String playerId;
  BattleSkillEvent(this.playerId);
}

/// レベルアップイベント（UI表示用）
class PlayerLevelUpEvent extends BattleSkillEvent {
  final int newLevel;
  final bool showLevelUpAnimation;

  PlayerLevelUpEvent({
    required String playerId,
    required this.newLevel,
    this.showLevelUpAnimation = true,
  }) : super(playerId);
}

/// 進化選択が必要なイベント（進化選択画面トリガー）
class EvolutionSelectionRequiredEvent extends BattleSkillEvent {
  final int level;
  final EvolutionSelectionType selectionType;
  final List<EvolutionType> availableChoices;

  EvolutionSelectionRequiredEvent({
    required String playerId,
    required this.level,
    required this.selectionType,
    required this.availableChoices,
  }) : super(playerId);
}

/// スキル使用イベント（スキルエフェクトトリガー）
class SkillUsedEvent extends BattleSkillEvent {
  final SkillSlot slot;
  final int damageDealt;
  final bool isCritical;

  SkillUsedEvent({
    required String playerId,
    required this.slot,
    required this.damageDealt,
    this.isCritical = false,
  }) : super(playerId);
}

/// スキルクールダウン変更イベント
class SkillCooldownChangedEvent extends BattleSkillEvent {
  final SkillSlot slot;
  final double remainingCooldown;

  SkillCooldownChangedEvent({
    required String playerId,
    required this.slot,
    required this.remainingCooldown,
  }) : super(playerId);
}

/// バトル進行中のスキル進行を調整するコーディネーター
class BattleSkillProgressionCoordinator {
  final SkillProgressionBattleService _skillService;
  final SkillProgressionConfig _progressionConfig;

  final _skillEventController = StreamController<BattleSkillEvent>.broadcast();
  final Map<String, DateTime> _lastEvolutionSelectionTime = {};

  Stream<BattleSkillEvent> get skillEvents => _skillEventController.stream;

  BattleSkillProgressionCoordinator({
    SkillProgressionBattleService? skillService,
    SkillProgressionConfig? progressionConfig,
  }) : _skillService = skillService ?? SkillProgressionBattleService(),
       _progressionConfig = progressionConfig ?? SkillProgressionConfig();

  /// プレイヤーを初期化
  void initializePlayer({
    required String playerId,
    required String mechaId,
  }) {
    _skillService.initializePlayer(playerId: playerId, mechaId: mechaId);
    _lastEvolutionSelectionTime[playerId] = DateTime.now();
  }

  /// ゲームティック（毎秒実行）— スキルクールダウン更新
  void onGameTick(double deltaTime) {
    _skillService.updateAllCooldowns(deltaTime);
  }

  /// プレイヤーをレベルアップ（キル獲得時等）
  /// Remote Config に基づいて進化レベル判定を実施
  void levelUpPlayer(String playerId) {
    final progressBefore = _skillService.getProgress(playerId);
    if (progressBefore == null) return;

    _skillService.levelUpPlayer(playerId);

    final progressAfter = _skillService.getProgress(playerId);
    if (progressAfter == null) return;

    // レベルアップイベント発火
    _skillEventController.add(PlayerLevelUpEvent(
      playerId: playerId,
      newLevel: progressAfter.state.currentLevel,
    ));

    // 進化選択が必要な場合は通知（Remote Config の進化レベル設定を使用）
    if (progressAfter.isEvolutionLocked) {
      final level = progressAfter.state.currentLevel;
      final firstEvolutionLevel = _progressionConfig.firstEvolutionLevel;
      final secondEvolutionLevel = _progressionConfig.secondEvolutionLevel;

      late EvolutionSelectionType selectionType;
      if (level == firstEvolutionLevel) {
        selectionType = EvolutionSelectionType.first;
      } else if (level == secondEvolutionLevel) {
        selectionType = EvolutionSelectionType.second;
      } else {
        return; // 進化レベルに該当しない
      }

      final availableChoices = _getAvailableEvolutions(playerId, selectionType);

      _skillEventController.add(EvolutionSelectionRequiredEvent(
        playerId: playerId,
        level: level,
        selectionType: selectionType,
        availableChoices: availableChoices,
      ));

      _lastEvolutionSelectionTime[playerId] = DateTime.now();
    }
  }

  /// スキルを使用
  /// 返り値: スキル使用可能なら true、不可なら false
  bool tryUseSkill(
    String playerId,
    SkillSlot slot, {
    required int baseSkillDamage,
  }) {
    final progress = _skillService.getProgress(playerId);
    if (progress == null) return false;

    // スキルが使用可能か確認
    if (!progress.state.isSkillReady(slot)) {
      return false;
    }

    // スキルを使用（クールダウン開始）
    _skillService.useSkill(playerId, slot);

    // 進化ボーナスを含む有効ダメージを計算
    var effectiveDamage = progress.getEffectiveSkillDamage(slot);

    // Remote Config の難易度プリセット倍率を適用
    final difficultyModifiers = _progressionConfig.getDifficultyModifiers();
    effectiveDamage = (effectiveDamage * difficultyModifiers.skillDamageMultiplier).toInt();

    // スキル使用イベント発火
    _skillEventController.add(SkillUsedEvent(
      playerId: playerId,
      slot: slot,
      damageDealt: effectiveDamage,
    ));

    return true;
  }

  /// 進化を確定（Lv3）
  void confirmEvolution(String playerId, EvolutionType choice) {
    _skillService.confirmEvolution(playerId, choice);
  }

  /// 進化を切り替え（Lv6）
  void switchEvolution(String playerId, EvolutionType newChoice) {
    _skillService.switchEvolution(playerId, newChoice);
  }

  /// 進化選択タイムアウトで自動確定（デフォルト攻撃）
  void autoConfirmEvolution(String playerId) {
    final progress = _skillService.getProgress(playerId);
    if (progress == null || !progress.isEvolutionLocked) return;

    final firstEvolutionLevel = _progressionConfig.firstEvolutionLevel;
    final secondEvolutionLevel = _progressionConfig.secondEvolutionLevel;

    if (progress.state.currentLevel == firstEvolutionLevel) {
      _skillService.confirmEvolution(playerId, EvolutionType.offensive);
    } else if (progress.state.currentLevel == secondEvolutionLevel) {
      _skillService.switchEvolution(playerId, EvolutionType.offensive);
    }
  }

  /// プレイヤーのスキル進行状態を取得（UI表示用）
  PlayerSkillStateSnapshot? getPlayerSkillState(String playerId) {
    final progress = _skillService.getProgress(playerId);
    if (progress == null) return null;

    return PlayerSkillStateSnapshot(
      playerId: playerId,
      currentLevel: progress.state.currentLevel,
      currentEvolution: progress.state.evolutionState.currentEvolution,
      isEvolutionLocked: progress.isEvolutionLocked,
      skillCooldowns: Map<SkillSlot, double>.from(progress.state.skillCooldowns),
      evolutionBonuses: progress.state.getEvolutionBonuses(),
      isUltAvailable: progress.state.isUltAvailable(),
      isUltCharging: progress.state.isUltCharging(),
    );
  }

  /// 利用可能な進化選択肢を取得
  List<EvolutionType> _getAvailableEvolutions(
    String playerId,
    EvolutionSelectionType selectionType,
  ) {
    if (selectionType == EvolutionSelectionType.first) {
      // Lv3: すべての進化タイプから選択可能
      return [EvolutionType.offensive, EvolutionType.defensive, EvolutionType.support];
    } else {
      // Lv6: 現在の進化と異なる2つのタイプから選択、また現在のタイプを維持も可能
      return [EvolutionType.offensive, EvolutionType.defensive, EvolutionType.support];
    }
  }

  /// デバッグ用：全プレイヤーの状態をダンプ
  Map<String, dynamic> debugDumpAllStates() {
    return _skillService.debugDumpBattleProgression();
  }

  void dispose() {
    _skillService.dispose();
    _skillEventController.close();
  }
}

/// UI表示用の単一プレイヤーのスキル状態スナップショット
class PlayerSkillStateSnapshot {
  final String playerId;
  final int currentLevel;
  final EvolutionType? currentEvolution;
  final bool isEvolutionLocked;
  final Map<SkillSlot, double> skillCooldowns;
  final Map<String, double> evolutionBonuses;
  final bool isUltAvailable;
  final bool isUltCharging;

  PlayerSkillStateSnapshot({
    required this.playerId,
    required this.currentLevel,
    this.currentEvolution,
    required this.isEvolutionLocked,
    required this.skillCooldowns,
    required this.evolutionBonuses,
    required this.isUltAvailable,
    required this.isUltCharging,
  });
}
