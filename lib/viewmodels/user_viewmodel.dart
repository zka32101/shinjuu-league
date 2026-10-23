// ignore_for_file: avoid_print

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shinjuu_league/data/models/battle_model.dart';
import 'package:shinjuu_league/data/models/user_model.dart';
import 'package:shinjuu_league/services/auth_service.dart';
import 'package:shinjuu_league/services/firestore_service.dart';
import 'package:shinjuu_league/data/models/skill_tree_reset.dart';
import 'package:shinjuu_league/services/ranking_service.dart';
import 'package:shinjuu_league/services/season_service.dart';
import 'package:shinjuu_league/services/skill_tree_reset_service.dart';

class UserViewModel extends StateNotifier<AsyncValue<User?>> {
  UserViewModel({
    FirestoreService? firestoreService,
    AuthService? authService,
    RankingService? rankingService,
    SeasonService? seasonService,
    SkillTreeResetService? skillTreeResetService,
  }) : _firestoreService = firestoreService ?? FirestoreService(),
       _authService = authService ?? AuthService(),
       _rankingService = rankingService ?? RankingService(),
       _seasonService = seasonService ?? SeasonService(),
       _skillTreeResetService =
           skillTreeResetService ?? SkillTreeResetService(firestoreService ?? FirestoreService()),
       super(const AsyncValue.loading()) {
    _init();
  }

  final FirestoreService _firestoreService;
  final AuthService _authService;
  final RankingService _rankingService;
  final SeasonService _seasonService;
  final SkillTreeResetService _skillTreeResetService;
  StreamSubscription<User?>? _userSub;

  /// Get current user ID for seasonal tracking
  String? get _currentUserId => _authService.currentUser?.uid;

  void _init() {
    final uid = _authService.currentUser?.uid;
    if (uid == null) {
      state = const AsyncValue.data(null);
      return;
    }

    _userSub = _firestoreService
        .watchUser(uid)
        .listen(
          (user) => state = AsyncValue.data(user),
          onError: (Object e, StackTrace st) => state = AsyncValue.error(e, st),
        );
  }

  /// 試合終了後、battle_results ドキュメントを送信してCloud Function
  /// (elo-validator)経由でELO・勝率・戦績を反映する。これらのフィールドは
  /// サーバー側検証必須のためクライアントから直接書き込まない（Firestore
  /// Rules でブロックされる）。サーバーの再計算結果は watchUser() ストリーム
  /// 経由でこの ViewModel の state に自動反映される。
  /// また、アクティブシーズンがあれば季節進行も同時に更新する
  Future<void> applyBattleResult(Battle battle) async {
    final current = state.value;
    if (current == null) return;

    final isWin = battle.result == BattleResult.win;
    // Bot の相手はFirestoreユーザードキュメントを持たないため、
    // サーバー側の相手レート平均計算対象から除外する
    final realOpponentIds = battle.opponentIds
        .where((id) => !id.startsWith('bot_'))
        .toList();

    await _firestoreService.addData(
      path: 'battle_results',
      data: {
        'battleId': battle.battleId,
        'userId': current.uid,
        'opponentUserIds': realOpponentIds,
        'result': battle.result.name,
        'timestamp': FieldValue.serverTimestamp(),
      },
    );

    // 【CRITICAL INTEGRATION】 季節進行を更新
    // season_data はまだサーバー権威化されていない設計のため、クライアント側の
    // 推定ELOをそのまま使って季節Tier進行を先行更新する。本体のELOは上記の
    // Cloud Function が別途確定し、watchUser() ストリーム経由で自動反映される
    try {
      final userId = _currentUserId;
      if (userId == null) return;

      final activeSeason = await _seasonService.getActiveSeason();
      if (activeSeason == null) return; // シーズンが無い場合はスキップ

      final estimatedElo = (current.eloRating + battle.eloChange).clamp(
        0.0,
        5000.0,
      );

      // Record seasonal progress (non-blocking)
      await _rankingService.updateSeasonalProgress(
        userId: userId,
        seasonId: activeSeason.seasonId,
        newRating: estimatedElo.toInt(),
        isWin: isWin,
        tierThresholds: activeSeason.tierThresholds,
      );

      await _checkSeasonTransition(userId, activeSeason.seasonId);
    } catch (e) {
      // Season progress recording is non-blocking (logging only)
      print('[UserViewModel] Error updating seasonal progress: $e');
    }
  }

  /// シーズンが切り替わっていれば、デフォルトの繰越モード（partial、50%引き継ぎ）
  /// でスキルツリーをリセットする。
  ///
  /// 元々 `SkillTreeResetService.resetForNewSeason()` は
  /// `skillTreeResetViewModelProvider`（UIの導線が存在しない）からしか
  /// 呼ばれておらず、`users/{userId}/season_snapshots` が全ユーザーで
  /// 永遠に空になっていた（ProgressionAnalyticsScreenがどのユーザーでも
  /// 空状態しか表示できない根本原因の片方）。RankingServiceの
  /// `season_data`（実際にプレイした全シーズンの記録）を正とし、
  /// まだスキルツリーのスナップショットが無い直近プレイ済みシーズンを
  /// 検出した時点で、ここから自動的にリセットをトリガーする。
  Future<void> _checkSeasonTransition(
    String userId,
    String activeSeasonId,
  ) async {
    // 直前のupdateSeasonalProgress()呼び出しで、アクティブシーズン自身の
    // season_data が既に作成/更新されている可能性があるため、「最後に
    // プレイしたシーズン」ではなく「アクティブシーズン以外で、まだ
    // スナップショットが取られていないプレイ済みシーズン」を遷移対象として
    // 探す。
    final playedSeasons = await _rankingService.getSeasonHistory(userId);
    if (playedSeasons.isEmpty) return;

    final snapshotHistory = await _skillTreeResetService.getSeasonHistory(
      userId,
    );
    final snapshottedSeasonIds = snapshotHistory
        .map((snapshot) => snapshot.seasonId)
        .toSet();

    final pendingSeasons = playedSeasons.where(
      (season) =>
          season.seasonId != activeSeasonId &&
          !snapshottedSeasonIds.contains(season.seasonId),
    );
    if (pendingSeasons.isEmpty) return; // この遷移は既に処理済み

    final previousSeason = pendingSeasons.last;
    await _skillTreeResetService.resetForNewSeason(
      userId,
      previousSeason.seasonId,
      activeSeasonId,
      previousSeason.peakTier,
      CarryoverMode.partial,
    );
  }

  /// スキンガチャ購入後に所持スキンを反映
  Future<void> updateOwnedSkins(List<String> ownedSkinIds) async {
    final current = state.value;
    if (current == null) return;

    final updated = current.copyWith(ownedSkinIds: ownedSkinIds);
    await _firestoreService.updateUser(updated);
  }

  /// 神獣選択画面での選択を反映
  Future<void> selectMecha(String mechaId) async {
    final current = state.value;
    if (current == null) return;

    final updated = current.copyWith(selectedMechaId: mechaId);
    await _firestoreService.updateUser(updated);
  }

  @override
  void dispose() {
    _userSub?.cancel();
    super.dispose();
  }
}
