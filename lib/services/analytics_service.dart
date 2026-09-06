import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:shinjuu_league/data/models/cohort_properties.dart';
import 'package:shinjuu_league/services/firestore_service.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();

  factory AnalyticsService() {
    return _instance;
  }

  AnalyticsService._internal();

  // Lazy initialization to support testing without Firebase
  FirebaseAnalytics? _analyticsInstance;
  FirebaseCrashlytics? _crashlyticsInstance;

  FirebaseAnalytics? get _analytics {
    try {
      return _analyticsInstance ??= FirebaseAnalytics.instance;
    } catch (e) {
      return null;
    }
  }

  FirebaseCrashlytics? get _crashlytics {
    try {
      return _crashlyticsInstance ??= FirebaseCrashlytics.instance;
    } catch (e) {
      return null;
    }
  }

  // ============ KPI Events ============

  /// Aha Moment: User achieved first kill
  Future<void> logAhaMomentReached(String userId) async {
    try {
      await _analytics?.logEvent(
        name: 'aha_moment_reached',
        parameters: {'user_id': userId},
      );
    } catch (_) {
      // Firebase not initialized
    }
  }

  /// First ranked entry
  Future<void> logFirstRankedEntry(String userId) async {
    try {
      await _analytics?.logEvent(
        name: 'first_ranked_entry',
        parameters: {'user_id': userId},
      );
    } catch (_) {
      // Firebase not initialized
    }
  }

  /// Battle win streak
  Future<void> logBattleWinStreak(String userId, int streakCount) async {
    try {
      await _analytics?.logEvent(
        name: 'battle_win_streak',
        parameters: {'user_id': userId, 'streak_count': streakCount},
      );
    } catch (_) {
      // Firebase not initialized
    }
  }

  /// BattlePass purchased
  Future<void> logBattlePassPurchased(String userId, double price) async {
    try {
      await _analytics?.logEvent(
        name: 'battlepass_purchased',
        parameters: {'user_id': userId, 'price': price},
      );
    } catch (_) {
      // Firebase not initialized
    }
  }

  /// Skin/cosmetic purchased
  Future<void> logSkinPurchased(
    String userId,
    String skinId,
    double price,
  ) async {
    try {
      await _analytics?.logEvent(
        name: 'skin_purchased',
        parameters: {'user_id': userId, 'skin_id': skinId, 'price': price},
      );
    } catch (_) {
      // Firebase not initialized
    }
  }

  // ============ Session Events ============

  /// Log user session start
  Future<void> logSessionStart(String userId) async {
    try {
      await _analytics?.logEvent(
        name: 'session_start',
        parameters: {'user_id': userId},
      );
    } catch (_) {
      // Firebase not initialized
    }
  }

  /// Log battle start
  Future<void> logBattleStart(String userId, String battleMode) async {
    try {
      await _analytics?.logEvent(
        name: 'battle_start',
        parameters: {'user_id': userId, 'mode': battleMode},
      );
    } catch (_) {
      // Firebase not initialized
    }
  }

  /// Log battle end
  Future<void> logBattleEnd(
    String userId,
    String battleId,
    String result,
    int kills,
    int deaths,
  ) async {
    try {
      await _analytics?.logEvent(
        name: 'battle_end',
        parameters: {
          'user_id': userId,
          'battle_id': battleId,
          'result': result,
          'kills': kills,
          'deaths': deaths,
        },
      );
    } catch (_) {
      // Firebase not initialized
    }
  }

  // ============ Error Tracking ============

  /// Record error to Crashlytics
  void recordError(
    dynamic exception,
    StackTrace? stackTrace, {
    String? reason,
    Iterable<Object> information = const [],
  }) {
    try {
      _crashlytics?.recordError(
        exception,
        stackTrace,
        reason: reason,
        information: information,
      );
    } catch (_) {
      // Firebase not initialized
    }
  }

  /// Set user identifier for Crashlytics
  Future<void> setUserId(String userId) async {
    try {
      await _crashlytics?.setUserIdentifier(userId);
    } catch (_) {
      // Firebase not initialized
    }
  }

  /// Set custom key-value pair in Crashlytics
  void setCustomKey(String key, Object value) {
    try {
      _crashlytics?.setCustomKey(key, value);
    } catch (_) {
      // Firebase not initialized
    }
  }

  // ============ Custom Events ============

  /// Log custom event with parameters
  Future<void> logCustomEvent(
    String eventName, {
    Map<String, Object>? parameters,
  }) async {
    try {
      await _analytics?.logEvent(name: eventName, parameters: parameters);
    } catch (_) {
      // Firebase not initialized
    }
  }

  // ============ Funnel Events (Day 1 Retention) ============

  /// オンボーディング開始
  Future<void> logOnboardingStart(String userId) async {
    try {
      await _analytics?.logEvent(
        name: 'onboarding_start',
        parameters: {'user_id': userId},
      );
    } catch (_) {
      // Firebase not initialized
    }
  }

  /// チュートリアル完了
  Future<void> logTutorialComplete(String userId) async {
    try {
      await _analytics?.logEvent(
        name: 'tutorial_complete',
        parameters: {'user_id': userId},
      );
    } catch (_) {
      // Firebase not initialized
    }
  }

  /// 初バトル入場
  Future<void> logFirstBattleEnter(String userId) async {
    try {
      await _analytics?.logEvent(
        name: 'first_battle_enter',
        parameters: {'user_id': userId},
      );
    } catch (_) {
      // Firebase not initialized
    }
  }

  /// 初バトル勝利（Aha Moment）
  Future<void> logFirstBattleWin(String userId) async {
    try {
      await _analytics?.logEvent(
        name: 'first_battle_win',
        parameters: {'user_id': userId},
      );
    } catch (_) {
      // Firebase not initialized
    }
  }

  // ============ Conversion Funnel (LTV) ============

  /// ショップ表示
  Future<void> logShopViewed(String userId) async {
    try {
      await _analytics?.logEvent(
        name: 'shop_viewed',
        parameters: {'user_id': userId},
      );
    } catch (_) {
      // Firebase not initialized
    }
  }

  /// 購入開始（ユーザーが購入ボタンをタップ）
  Future<void> logPurchaseStart(
    String userId,
    String productId, // 'battlepass_season' or 'skin_gacha_single'
  ) async {
    try {
      await _analytics?.logEvent(
        name: 'purchase_start',
        parameters: {
          'user_id': userId,
          'product_id': productId,
        },
      );
    } catch (_) {
      // Firebase not initialized
    }
  }

  /// 購入完了（BattlePass または Skin Gacha）
  Future<void> logPurchaseComplete(
    String userId,
    String productType, // 'battlepass' or 'skin_gacha'
    double price,
  ) async {
    try {
      await _analytics?.logEvent(
        name: 'purchase_complete',
        parameters: {
          'user_id': userId,
          'product_type': productType,
          'price': price,
        },
      );
    } catch (_) {
      // Firebase not initialized
    }
  }

  /// 購入失敗
  Future<void> logPurchaseFailed(
    String userId,
    String productId,
    String reason,
  ) async {
    try {
      await _analytics?.logEvent(
        name: 'purchase_failed',
        parameters: {
          'user_id': userId,
          'product_id': productId,
          'reason': reason,
        },
      );
    } catch (_) {
      // Firebase not initialized
    }
  }

  /// 購入キャンセル
  Future<void> logPurchaseCancelled(
    String userId,
    String productId,
  ) async {
    try {
      await _analytics?.logEvent(
        name: 'purchase_cancelled',
        parameters: {
          'user_id': userId,
          'product_id': productId,
        },
      );
    } catch (_) {
      // Firebase not initialized
    }
  }

  /// 購入復元（restore purchases）
  Future<void> logPurchasesRestored(
    String userId,
    int count,
  ) async {
    try {
      await _analytics?.logEvent(
        name: 'purchases_restored',
        parameters: {
          'user_id': userId,
          'restored_count': count,
        },
      );
    } catch (_) {
      // Firebase not initialized
    }
  }

  // ============ Ranked Adoption Funnel ============

  /// ランク戦アンロック可能になった通知
  Future<void> logRankedUnlockAvailable(String userId) async {
    try {
      await _analytics?.logEvent(
        name: 'ranked_unlock_available',
        parameters: {'user_id': userId},
      );
    } catch (_) {
      // Firebase not initialized
    }
  }

  /// ランク戦に初参加
  Future<void> logRankedEntryAction(String userId) async {
    try {
      await _analytics?.logEvent(
        name: 'ranked_entry',
        parameters: {'user_id': userId},
      );
    } catch (_) {
      // Firebase not initialized
    }
  }

  // ============ Cohort Tracking ============

  /// コホート情報を設定（ユーザーセッション開始時に一度だけ）
  /// installCohort: 登録日（YYYY-MM-DD）
  /// platformCohort: iOS or Android
  /// purchaseCohort: D1Payer, F2P, etc
  /// Also persists cohort properties to Firestore for querying and targeting
  Future<void> setCohortProperties(
    String userId, {
    required String installCohort,
    required String platformCohort,
    required String purchaseCohort,
    Map<String, String>? customCohorts,
  }) async {
    // Log to Firebase Analytics (for dashboard reporting)
    try {
      await _analytics?.setUserProperty(
        name: 'install_cohort',
        value: installCohort,
      );
      await _analytics?.setUserProperty(
        name: 'platform_cohort',
        value: platformCohort,
      );
      await _analytics?.setUserProperty(
        name: 'purchase_cohort',
        value: purchaseCohort,
      );
    } catch (_) {
      // Firebase not initialized
    }

    // Also persist to Firestore for querying and server-side targeting
    try {
      final cohortProperties = CohortProperties(
        installCohort: installCohort,
        platformCohort: platformCohort,
        purchaseCohort: purchaseCohort,
        customCohorts: customCohorts ?? {},
        assignedAt: DateTime.now(),
      );

      final firestoreService = FirestoreService();
      await firestoreService.updateUserCohortProperties(
        userId,
        cohortProperties.toJson(),
      );
    } catch (e) {
      // Log error but don't throw - cohort persistence is non-critical
      recordError(
        e,
        StackTrace.current,
        reason: 'Failed to persist cohort properties to Firestore',
        information: [userId],
      );
    }
  }

  // ============ Retention Metrics ============

  /// Day 1 アクティブセッション記録
  Future<void> logDay1Active(String userId) async {
    try {
      await _analytics?.logEvent(
        name: 'day_1_active',
        parameters: {'user_id': userId},
      );
    } catch (_) {
      // Firebase not initialized
    }
  }

  /// Day 7 アクティブセッション記録
  Future<void> logDay7Active(String userId) async {
    try {
      await _analytics?.logEvent(
        name: 'day_7_active',
        parameters: {'user_id': userId},
      );
    } catch (_) {
      // Firebase not initialized
    }
  }

  /// Day 30 アクティブセッション記録
  Future<void> logDay30Active(String userId) async {
    try {
      await _analytics?.logEvent(
        name: 'day_30_active',
        parameters: {'user_id': userId},
      );
    } catch (_) {
      // Firebase not initialized
    }
  }

  /// Aha Moment までの時間（秒）を記録
  /// リテンション改善の主要指標
  Future<void> logTimeToAhaMoment(
    String userId,
    int secondsToFirstKill,
  ) async {
    try {
      await _analytics?.logEvent(
        name: 'time_to_aha_moment',
        parameters: {
          'user_id': userId,
          'seconds': secondsToFirstKill,
        },
      );
    } catch (_) {
      // Firebase not initialized
    }
  }

  // ============ Achievement Events ============

  /// 実績アンロック
  Future<void> logAchievementUnlocked(
    String userId,
    String achievementId,
    String rarity, // common, rare, legendary
  ) async {
    try {
      await _analytics?.logEvent(
        name: 'achievement_unlocked',
        parameters: {
          'user_id': userId,
          'achievement_id': achievementId,
          'rarity': rarity,
        },
      );
    } catch (_) {
      // Firebase not initialized
    }
  }

  /// 実績進捗（進行系の実績）
  Future<void> logAchievementProgress(
    String userId,
    String achievementId,
    int currentProgress,
    int targetProgress,
  ) async {
    try {
      await _analytics?.logEvent(
        name: 'achievement_progress',
        parameters: {
          'user_id': userId,
          'achievement_id': achievementId,
          'current': currentProgress,
          'target': targetProgress,
          'percentage': ((currentProgress / targetProgress) * 100).toInt(),
        },
      );
    } catch (_) {
      // Firebase not initialized
    }
  }

  /// 実績カテゴリーごとのアンロック
  Future<void> logAchievementCategoryProgress(
    String userId,
    String category,
    int unlockedCount,
    int totalCount,
  ) async {
    try {
      await _analytics?.logEvent(
        name: 'achievement_category_progress',
        parameters: {
          'user_id': userId,
          'category': category,
          'unlocked': unlockedCount,
          'total': totalCount,
          'completion_percentage': ((unlockedCount / totalCount) * 100).toInt(),
        },
      );
    } catch (_) {
      // Firebase not initialized
    }
  }

  /// 全実績完了率
  Future<void> logAchievementCompletion(
    String userId,
    double completionPercentage,
    int totalUnlocked,
  ) async {
    try {
      await _analytics?.logEvent(
        name: 'achievement_completion',
        parameters: {
          'user_id': userId,
          'completion_percentage': completionPercentage.toInt(),
          'total_unlocked': totalUnlocked,
        },
      );
    } catch (_) {
      // Firebase not initialized
    }
  }

  /// 実績報酬受け取り
  Future<void> logAchievementRewardClaimed(
    String userId,
    String achievementId,
    String rewardTier,
    int currencyAmount,
    int badgeCount,
  ) async {
    try {
      await _analytics?.logEvent(
        name: 'achievement_reward_claimed',
        parameters: {
          'user_id': userId,
          'achievement_id': achievementId,
          'reward_tier': rewardTier,
          'currency_amount': currencyAmount,
          'badge_count': badgeCount,
        },
      );
    } catch (_) {
      // Firebase not initialized
    }
  }
}
