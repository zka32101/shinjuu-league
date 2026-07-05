import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shinjuu_league/config/app_config.dart';
import 'package:shinjuu_league/data/models/battle_model.dart';
import 'package:shinjuu_league/data/models/match_result_model.dart';
import 'package:shinjuu_league/data/models/user_model.dart';
import 'package:shinjuu_league/services/matchmaking_service.dart';

class MatchingState {
  const MatchingState({
    required this.isSearching,
    required this.matchResult,
    required this.error,
    required this.elapsedSeconds,
  });

  factory MatchingState.initial() => const MatchingState(
    isSearching: false,
    matchResult: null,
    error: null,
    elapsedSeconds: 0,
  );

  final bool isSearching;
  final MatchResult? matchResult;
  final String? error;
  final int elapsedSeconds;

  MatchingState copyWith({
    bool? isSearching,
    MatchResult? matchResult,
    String? error,
    int? elapsedSeconds,
  }) {
    return MatchingState(
      isSearching: isSearching ?? this.isSearching,
      matchResult: matchResult ?? this.matchResult,
      error: error,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
    );
  }
}

/// マッチング < 30秒 を保証：タイムアウトすると Bot 込みの MatchResult が返る前提
/// （MatchmakingService 側で常に即時解決する設計）。
class MatchingViewModel extends StateNotifier<MatchingState> {
  MatchingViewModel({MatchmakingService? matchmakingService})
    : _matchmakingService = matchmakingService ?? MatchmakingService(),
      super(MatchingState.initial());

  final MatchmakingService _matchmakingService;
  Timer? _searchTimer;

  Future<void> startMatching(User currentUser, BattleMode mode) async {
    state = state.copyWith(isSearching: true, error: null, elapsedSeconds: 0);

    _searchTimer?.cancel();
    _searchTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
    });

    try {
      final match = await _matchmakingService
          .findMatch(currentUser: currentUser, mode: mode)
          .timeout(Duration(seconds: AppConfig.matchmakingTimeoutSeconds + 5));

      _searchTimer?.cancel();
      state = state.copyWith(isSearching: false, matchResult: match);
    } catch (e) {
      _searchTimer?.cancel();
      state = state.copyWith(isSearching: false, error: 'マッチングに失敗しました: $e');
    }
  }

  void cancelMatching() {
    _searchTimer?.cancel();
    state = MatchingState.initial();
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    super.dispose();
  }
}
