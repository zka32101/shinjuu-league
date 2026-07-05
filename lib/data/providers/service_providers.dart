import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shinjuu_league/data/models/user_model.dart';
import 'package:shinjuu_league/services/analytics_service.dart';
import 'package:shinjuu_league/services/auth_service.dart';
import 'package:shinjuu_league/services/firestore_service.dart';
import 'package:shinjuu_league/services/matchmaking_service.dart';
import 'package:shinjuu_league/viewmodels/battle_viewmodel.dart';
import 'package:shinjuu_league/viewmodels/matching_viewmodel.dart';
import 'package:shinjuu_league/viewmodels/user_viewmodel.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final firestoreServiceProvider = Provider<FirestoreService>((ref) => FirestoreService());
final analyticsServiceProvider = Provider<AnalyticsService>((ref) => AnalyticsService());
final matchmakingServiceProvider = Provider<MatchmakingService>((ref) => MatchmakingService());

final userViewModelProvider = StateNotifierProvider<UserViewModel, AsyncValue<User?>>((ref) {
  return UserViewModel(
    firestoreService: ref.watch(firestoreServiceProvider),
    authService: ref.watch(authServiceProvider),
  );
});

/// マッチング〜バトルはセッション単位のため autoDispose（画面離脱で状態破棄）
final matchingViewModelProvider = StateNotifierProvider.autoDispose<MatchingViewModel, MatchingState>((ref) {
  return MatchingViewModel(matchmakingService: ref.watch(matchmakingServiceProvider));
});

final battleViewModelProvider = StateNotifierProvider.autoDispose<BattleViewModel, BattleState>((ref) {
  return BattleViewModel(
    firestoreService: ref.watch(firestoreServiceProvider),
    analyticsService: ref.watch(analyticsServiceProvider),
  );
});
