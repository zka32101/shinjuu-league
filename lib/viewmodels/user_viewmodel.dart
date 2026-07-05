import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shinjuu_league/data/models/battle_model.dart';
import 'package:shinjuu_league/data/models/user_model.dart';
import 'package:shinjuu_league/services/auth_service.dart';
import 'package:shinjuu_league/services/firestore_service.dart';

class UserViewModel extends StateNotifier<AsyncValue<User?>> {
  UserViewModel({
    FirestoreService? firestoreService,
    AuthService? authService,
  }) : _firestoreService = firestoreService ?? FirestoreService(),
       _authService = authService ?? AuthService(),
       super(const AsyncValue.loading()) {
    _init();
  }

  final FirestoreService _firestoreService;
  final AuthService _authService;
  StreamSubscription<User?>? _userSub;

  void _init() {
    final uid = _authService.currentUser?.uid;
    if (uid == null) {
      state = const AsyncValue.data(null);
      return;
    }

    _userSub = _firestoreService.watchUser(uid).listen(
      (user) => state = AsyncValue.data(user),
      onError: (Object e, StackTrace st) => state = AsyncValue.error(e, st),
    );
  }

  /// 試合終了後にELO・勝率・戦績を反映（サーバー側検証済みの eloChange を前提）
  Future<void> applyBattleResult(Battle battle) async {
    final current = state.value;
    if (current == null) return;

    final isWin = battle.result == BattleResult.win;
    final newTotalBattles = current.totalBattles + 1;
    final newTotalWins = current.totalWins + (isWin ? 1 : 0);
    final newWinRate = newTotalWins / newTotalBattles;
    final newElo = (current.eloRating + battle.eloChange).clamp(0.0, 5000.0);

    final updated = current.copyWith(
      eloRating: newElo,
      winRate: newWinRate,
      totalWins: newTotalWins,
      totalBattles: newTotalBattles,
      lastBattleAt: DateTime.now(),
    );

    await _firestoreService.updateUser(updated);
  }

  @override
  void dispose() {
    _userSub?.cancel();
    super.dispose();
  }
}
