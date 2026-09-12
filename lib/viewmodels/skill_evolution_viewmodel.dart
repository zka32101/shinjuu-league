// スキル進化選択UI用ViewModel

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shinjuu_league/data/models/skill_catalog.dart';
import 'package:shinjuu_league/data/models/evolution_state.dart';
import 'package:shinjuu_league/services/skill_evolution_service.dart';

/// 進化選択画面の表示状態
class EvolutionSelectionViewModel
    extends StateNotifier<EvolutionSelectionState> {
  EvolutionSelectionViewModel({
    required int targetLevel,
  }) : super(EvolutionSelectionState.initial(targetLevel: targetLevel)) {
    _countdownTimer = null;
  }

  Timer? _countdownTimer;
  static const int countdownDuration = 10; // 秒

  /// 進化選択画面を表示開始（カウントダウン開始）
  void showSelection() {
    state = state.showSelection();
    _startCountdown();
  }

  /// カウントダウンを開始
  void _startCountdown() {
    _countdownTimer?.cancel();
    int remaining = countdownDuration;

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remaining <= 0) {
        timer.cancel();
        // タイムアウト → デフォルト選択を自動確定
        _confirmDefaultEvolution();
      } else {
        state = state.updateCountdown(remaining);
        remaining--;
      }
    });
  }

  /// ユーザーが選択肢をタップ
  void selectEvolution(EvolutionType choice) {
    state = state.selectChoice(choice);
    // 即座に確定（タップで即決）
    _countdownTimer?.cancel();
  }

  /// 選択を確定する
  void confirmSelection(EvolutionType choice) {
    _countdownTimer?.cancel();
    state = state.selectChoice(choice);
    // 呼び出し側で onEvolutionSelected callback を処理
  }

  /// デフォルト進化を自動確定
  void _confirmDefaultEvolution() {
    final defaultChoice = SkillEvolutionService.getDefaultEvolutionChoice();
    state = state.selectChoice(defaultChoice);
  }

  /// 進化選択をリセット
  void reset() {
    _countdownTimer?.cancel();
    state = state.reset();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  /// 進化型の説明文を取得
  String getDescription(EvolutionType type) {
    if (state.targetLevel == 3) {
      return SkillEvolutionService.getEvolutionDescription(type);
    } else {
      return SkillEvolutionService.getSecondEvolutionDescription(type);
    }
  }

  /// 選択されているか
  bool isSelected(EvolutionType type) => state.selectedChoice == type;

  /// カウントダウンが終了したか
  bool isTimedOut() => state.remainingSeconds <= 0;
}

/// プレイヤーの進化状態管理（試合中の追跡）
class PlayerEvolutionViewModel extends StateNotifier<PlayerEvolutionState> {
  PlayerEvolutionViewModel({
    required String mechaId,
    required int currentLevel,
  }) : super(PlayerEvolutionState.initial(
    mechaId: mechaId,
    currentLevel: currentLevel,
  ));

  /// Lv3進化を選択確定
  void confirmLv3Evolution(EvolutionType choice) {
    state = state.selectEvolutionAtLv3(choice);
  }

  /// Lv6進化を選択確定（変更または維持）
  void confirmLv6Evolution(EvolutionType choice) {
    state = state.updateEvolutionAtLv6(choice);
  }

  /// 現在の進化ボーナスを取得
  Map<String, double> getCurrentEvolutionBonuses() {
    if (state.currentEvolution == null) {
      return {
        'damage_bonus': 0.0,
        'hp_bonus': 0.0,
        'ally_effect_bonus': 0.0,
      };
    }

    final levelIntoEvolution =
        state.currentLevel - (state.lastEvolutionLevel);
    final isSecondEvolution = state.lastEvolutionLevel >= 6;

    return SkillEvolutionService.calculateEvolutionBonuses(
      evolutionType: state.currentEvolution!,
      levelIntoEvolution: levelIntoEvolution,
      isSecondEvolution: isSecondEvolution,
    );
  }

  /// 次の進化が必要なレベルを取得
  int? getNextEvolutionLevel() {
    return SkillEvolutionService.getNextEvolutionLevel(state.currentLevel);
  }

  /// 進化のボーナス記述（UI表示用）
  String getEvolutionBonusText() {
    if (state.currentEvolution == null) return '進化未選択';

    final bonuses = getCurrentEvolutionBonuses();
    final damageBonus = bonuses['damage_bonus'] ?? 0.0;
    final hpBonus = bonuses['hp_bonus'] ?? 0.0;
    final allyEffectBonus = bonuses['ally_effect_bonus'] ?? 0.0;

    final parts = <String>[];
    if (damageBonus > 0) {
      parts.add('ダメージ+${(damageBonus * 100).toInt()}%');
    }
    if (hpBonus > 0) {
      parts.add('HP+${(hpBonus * 100).toInt()}%');
    }
    if (allyEffectBonus > 0) {
      parts.add('味方効果+${(allyEffectBonus * 100).toInt()}%');
    }

    return parts.isEmpty ? '進化中' : parts.join(' / ');
  }

  /// Lv3進化の説明
  String getLv3Description() {
    return SkillEvolutionService.getEvolutionDescription(
      state.currentEvolution ?? EvolutionType.offensive,
    );
  }

  /// Lv6進化の説明
  String getLv6Description() {
    return SkillEvolutionService.getSecondEvolutionDescription(
      state.currentEvolution ?? EvolutionType.offensive,
    );
  }
}

/// Riverpod プロバイダ

// 進化選択画面用（マッチ進行中に一時的に表示）
final evolutionSelectionProvider = StateNotifierProvider.autoDispose<
    EvolutionSelectionViewModel,
    EvolutionSelectionState>((ref) {
  // 注：Lv3がデフォルト（呼び出し側で targetLevel を指定すること）
  return EvolutionSelectionViewModel(targetLevel: 3);
});

// プレイヤーの進化状態（マッチ全体で追跡）
final playerEvolutionProvider = StateNotifierProvider.autoDispose<
    PlayerEvolutionViewModel,
    PlayerEvolutionState>((ref) {
  // 注：BattleScreen で mechaId と currentLevel を指定して初期化
  return PlayerEvolutionViewModel(
    mechaId: 'default_mecha', // デフォルト値
    currentLevel: 1,
  );
});

// 次の進化レベルを取得（依存プロバイダ）
final nextEvolutionLevelProvider =
    Provider.autoDispose<int?>((ref) {
  final evolutionState = ref.watch(playerEvolutionProvider);
  return SkillEvolutionService.getNextEvolutionLevel(
    evolutionState.currentLevel,
  );
});

// 現在の進化ボーナス（依存プロバイダ）
final currentEvolutionBonusesProvider = Provider.autoDispose<
    Map<String, double>>((ref) {
  final evolutionViewModel = ref.watch(playerEvolutionProvider.notifier);
  return evolutionViewModel.getCurrentEvolutionBonuses();
});
