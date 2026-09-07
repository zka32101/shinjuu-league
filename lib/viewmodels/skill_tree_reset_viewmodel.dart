import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shinjuu_league/data/models/skill_model.dart';
import 'package:shinjuu_league/data/models/skill_tree_reset.dart';
import 'package:shinjuu_league/services/skill_tree_reset_service.dart';

/// State for skill tree reset operations
class SkillTreeResetState {
  final List<SkillTreeSnapshot> seasonHistory;
  final List<SkillTreeReset> resetHistory;
  final ProgressDelta? comparisonDelta;
  final CarryoverMode? selectedCarryoverMode;
  final bool isLoading;
  final String? error;
  final String? successMessage;

  SkillTreeResetState({
    this.seasonHistory = const [],
    this.resetHistory = const [],
    this.comparisonDelta,
    this.selectedCarryoverMode,
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  SkillTreeResetState copyWith({
    List<SkillTreeSnapshot>? seasonHistory,
    List<SkillTreeReset>? resetHistory,
    ProgressDelta? comparisonDelta,
    CarryoverMode? selectedCarryoverMode,
    bool? isLoading,
    String? error,
    String? successMessage,
  }) {
    return SkillTreeResetState(
      seasonHistory: seasonHistory ?? this.seasonHistory,
      resetHistory: resetHistory ?? this.resetHistory,
      comparisonDelta: comparisonDelta ?? this.comparisonDelta,
      selectedCarryoverMode: selectedCarryoverMode ?? this.selectedCarryoverMode,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successMessage: successMessage,
    );
  }
}

/// ViewModel for managing skill tree resets across seasons
class SkillTreeResetViewModel extends StateNotifier<SkillTreeResetState> {
  final SkillTreeResetService _resetService;
  final String _userId;

  SkillTreeResetViewModel(
    this._resetService,
    this._userId,
  ) : super(SkillTreeResetState());

  /// Load player's season history
  Future<void> loadSeasonHistory() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final history = await _resetService.getSeasonHistory(_userId);
      state = state.copyWith(
        seasonHistory: history,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Load player's reset history
  Future<void> loadResetHistory() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final history = await _resetService.getResetHistory(_userId);
      state = state.copyWith(
        resetHistory: history,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Set selected carryover mode (for pre-reset confirmation)
  void setCarryoverMode(CarryoverMode mode) {
    state = state.copyWith(selectedCarryoverMode: mode);
  }

  /// Execute season reset with selected carryover mode
  Future<SkillTree?> executeSeasonReset(
    String currentSeasonId,
    String nextSeasonId,
    String finalTier,
  ) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final carryoverMode = state.selectedCarryoverMode ?? CarryoverMode.partial;

      final newTree = await _resetService.resetForNewSeason(
        _userId,
        currentSeasonId,
        nextSeasonId,
        finalTier,
        carryoverMode,
      );

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Season reset complete with $carryoverMode carryover',
        selectedCarryoverMode: null,
      );

      // Reload histories
      await Future.wait([
        loadSeasonHistory(),
        loadResetHistory(),
      ]);

      return newTree;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return null;
    }
  }

  /// Compare two seasons' progression
  Future<void> compareSeasons(
    String season1Id,
    String season2Id,
  ) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final delta = await _resetService.compareSeasons(
        _userId,
        season1Id,
        season2Id,
      );

      state = state.copyWith(
        comparisonDelta: delta,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Get last reset information
  SkillTreeReset? getLastReset() {
    if (state.resetHistory.isEmpty) return null;
    return state.resetHistory.last;
  }

  /// Get most recent season snapshot
  SkillTreeSnapshot? getLatestSeason() {
    if (state.seasonHistory.isEmpty) return null;
    return state.seasonHistory.last;
  }

  /// Calculate estimated points after partial carryover
  int estimatePartialCarryover(int currentPoints) {
    return (currentPoints * 0.5).floor();
  }

  /// Get carryover explanation text
  String getCarryoverExplanation(CarryoverMode mode) {
    switch (mode) {
      case CarryoverMode.none:
        return 'Start fresh: すべてのポイントをリセットして新シーズンを開始します';
      case CarryoverMode.partial:
        return 'バランス型: 前シーズンのポイントの50%を引き継ぎます';
      case CarryoverMode.full:
        return 'チャレンジ継続: 前シーズンのスキルツリーをそのまま保持します';
    }
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Clear success message
  void clearSuccessMessage() {
    state = state.copyWith(successMessage: null);
  }

  /// Get progression trend (up/down/stable)
  String getProgressionTrend() {
    if (state.seasonHistory.length < 2) return 'New player';

    final prev = state.seasonHistory[state.seasonHistory.length - 2];
    final latest = state.seasonHistory.last;

    final pointDelta = latest.totalPointsAllocated - prev.totalPointsAllocated;
    final tierIdx = (current) =>
        SkillTreeResetService.tierProgression.indexOf(current);

    final tierDelta = tierIdx(latest.finalTier) - tierIdx(prev.finalTier);

    if (pointDelta > 0 || tierDelta > 0) return '📈 上昇中';
    if (pointDelta < 0 || tierDelta < 0) return '📉 下降中';
    return '➡️   安定';
  }
}

/// Riverpod provider for skill tree reset service
final skillTreeResetServiceProvider = Provider<SkillTreeResetService>((ref) {
  throw UnimplementedError(
    'skillTreeResetServiceProvider must be provided by the application',
  );
});

/// Riverpod provider for skill tree reset view model
final skillTreeResetViewModelProvider = StateNotifierProvider.family.autoDispose<
    SkillTreeResetViewModel,
    SkillTreeResetState,
    String>((ref, userId) {
  final resetService = ref.watch(skillTreeResetServiceProvider);
  return SkillTreeResetViewModel(resetService, userId);
});
