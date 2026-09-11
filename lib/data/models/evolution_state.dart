// 進化選択状態管理モデル

import 'package:freezed_annotation/freezed_annotation.dart';
import 'skill_catalog.dart';

part 'evolution_state.freezed.dart';
part 'evolution_state.g.dart';

/// 進化選択の履歴
@freezed
class EvolutionRecord with _$EvolutionRecord {
  const factory EvolutionRecord({
    required int level,
    required EvolutionType choice,
    required DateTime selectedAt,
  }) = _EvolutionRecord;

  factory EvolutionRecord.fromJson(Map<String, dynamic> json) =>
      _$EvolutionRecordFromJson(json);
}

/// プレイヤーのキャラ進化状態（1試合中での変化を追跡）
@freezed
class PlayerEvolutionState with _$PlayerEvolutionState {
  const factory PlayerEvolutionState({
    required String mechaId,
    required EvolutionType? currentEvolution,
    required List<EvolutionRecord> evolutionHistory,
    required int lastEvolutionLevel,
    required int currentLevel,
  }) = _PlayerEvolutionState;

  factory PlayerEvolutionState.initial({
    required String mechaId,
    required int currentLevel,
  }) => PlayerEvolutionState(
    mechaId: mechaId,
    currentEvolution: null,
    evolutionHistory: [],
    lastEvolutionLevel: 0,
    currentLevel: currentLevel,
  );

  /// Lv3での進化選択を記録
  PlayerEvolutionState selectEvolutionAtLv3(EvolutionType choice) {
    final record = EvolutionRecord(
      level: 3,
      choice: choice,
      selectedAt: DateTime.now(),
    );
    return copyWith(
      currentEvolution: choice,
      evolutionHistory: [...evolutionHistory, record],
      lastEvolutionLevel: 3,
    );
  }

  /// Lv6での進化変更を記録（維持または切り替え）
  PlayerEvolutionState updateEvolutionAtLv6(EvolutionType newChoice) {
    final record = EvolutionRecord(
      level: 6,
      choice: newChoice,
      selectedAt: DateTime.now(),
    );
    return copyWith(
      currentEvolution: newChoice,
      evolutionHistory: [...evolutionHistory, record],
      lastEvolutionLevel: 6,
    );
  }

  /// 現在の進化が何回目か（Lv3=1回目、Lv6=2回目など）
  int get evolutionCount => evolutionHistory.length;

  /// 前回の進化選択
  EvolutionRecord? get lastEvolution =>
      evolutionHistory.isEmpty ? null : evolutionHistory.last;

  factory PlayerEvolutionState.fromJson(Map<String, dynamic> json) =>
      _$PlayerEvolutionStateFromJson(json);
}

/// Lv3進化選択画面のUI状態
@freezed
class EvolutionSelectionState with _$EvolutionSelectionState {
  const factory EvolutionSelectionState({
    required int targetLevel, // 3 or 6
    required bool isVisible,
    required int remainingSeconds, // カウントダウン秒数
    EvolutionType? selectedChoice, // ユーザーが選択中の選択肢（仮）
  }) = _EvolutionSelectionState;

  factory EvolutionSelectionState.initial({required int targetLevel}) =>
      EvolutionSelectionState(
        targetLevel: targetLevel,
        isVisible: false,
        remainingSeconds: 10,
        selectedChoice: null,
      );

  EvolutionSelectionState showSelection() => copyWith(isVisible: true);

  EvolutionSelectionState updateCountdown(int seconds) =>
      copyWith(remainingSeconds: seconds);

  EvolutionSelectionState selectChoice(EvolutionType choice) =>
      copyWith(selectedChoice: choice);

  EvolutionSelectionState reset() => copyWith(
    isVisible: false,
    remainingSeconds: 10,
    selectedChoice: null,
  );

  factory EvolutionSelectionState.fromJson(Map<String, dynamic> json) =>
      _$EvolutionSelectionStateFromJson(json);
}

/// スキルプログレッション（Lv→ダメージ / 効果値のマッピング）
@freezed
class SkillProgression with _$SkillProgression {
  const factory SkillProgression({
    required String skillId,
    required Map<int, int> levelToDamage, // Lv → ダメージ値
    required Map<int, double> levelToCooldown, // Lv → クールタイム
  }) = _SkillProgression;

  int? getDamageAtLevel(int level) => levelToDamage[level];
  double? getCooldownAtLevel(int level) => levelToCooldown[level];

  factory SkillProgression.fromJson(Map<String, dynamic> json) =>
      _$SkillProgressionFromJson(json);
}
