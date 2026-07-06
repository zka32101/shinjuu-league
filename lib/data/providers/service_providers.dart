import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shinjuu_league/config/app_config.dart';
import 'package:shinjuu_league/data/models/battlepass_model.dart';
import 'package:shinjuu_league/data/models/user_model.dart';
import 'package:shinjuu_league/services/analytics_service.dart';
import 'package:shinjuu_league/services/auth_service.dart';
import 'package:shinjuu_league/services/firestore_service.dart';
import 'package:shinjuu_league/services/matchmaking_service.dart';
import 'package:shinjuu_league/services/purchases_service.dart';
import 'package:shinjuu_league/services/replay_service.dart';
import 'package:shinjuu_league/viewmodels/battle_viewmodel.dart';
import 'package:shinjuu_league/viewmodels/matching_viewmodel.dart';
import 'package:shinjuu_league/viewmodels/user_viewmodel.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final firestoreServiceProvider = Provider<FirestoreService>((ref) => FirestoreService());
final analyticsServiceProvider = Provider<AnalyticsService>((ref) => AnalyticsService());
final matchmakingServiceProvider = Provider<MatchmakingService>((ref) => MatchmakingService());
final purchasesServiceProvider = Provider<PurchasesService>((ref) => PurchasesService());
final replayServiceProvider = Provider<ReplayService>((ref) {
  return ReplayService(firestoreService: ref.watch(firestoreServiceProvider));
});

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

final leaderboardProvider = FutureProvider.autoDispose<List<User>>((ref) {
  return ref.watch(firestoreServiceProvider).getTopRankedUsers();
});

/// 現シーズンのBattlePass進捗（未購読ユーザーは null → 画面側で初期値を組み立てる）
final battlePassProvider = FutureProvider.autoDispose<BattlePass?>((ref) async {
  final user = ref.watch(userViewModelProvider).value;
  if (user == null) return null;
  return ref.watch(firestoreServiceProvider).getBattlePass(user.uid, AppConfig.currentSeasonId);
});
