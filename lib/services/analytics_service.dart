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

  final _analytics = FirebaseAnalytics.instance;
  final _crashlytics = FirebaseCrashlytics.instance;

  // ============ KPI Events ============

  /// Aha Moment: User achieved first kill
  Future<void> logAhaMomentReached(String userId) async {
    await _analytics.logEvent(
      name: 'aha_moment_reached',
      parameters: {'user_id': userId},
    );
  }

  /// First ranked entry
  Future<void> logFirstRankedEntry(String userId) async {
    await _analytics.logEvent(
      name: 'first_ranked_entry',
      parameters: {'user_id': userId},
    );
  }

  /// Battle win streak
  Future<void> logBattleWinStreak(String userId, int streakCount) async {
    await _analytics.logEvent(
      name: 'battle_win_streak',
      parameters: {'user_id': userId, 'streak_count': streakCount},
    );
  }

  /// BattlePass purchased
  Future<void> logBattlePassPurchased(String userId, double price) async {
    await _analytics.logEvent(
      name: 'battlepass_purchased',
      parameters: {'user_id': userId, 'price': price},
    );
  }

  /// Skin/cosmetic purchased
  Future<void> logSkinPurchased(
    String userId,
    String skinId,
    double price,
  ) async {
    await _analytics.logEvent(
      name: 'skin_purchased',
      parameters: {'user_id': userId, 'skin_id': skinId, 'price': price},
    );
  }

  // ============ Session Events ============

  /// Log user session start
  Future<void> logSessionStart(String userId) async {
    await _analytics.logEvent(
      name: 'session_start',
      parameters: {'user_id': userId},
    );
  }

  /// Log battle start
  Future<void> logBattleStart(String userId, String battleMode) async {
    await _analytics.logEvent(
      name: 'battle_start',
      parameters: {'user_id': userId, 'mode': battleMode},
    );
  }

  /// Log battle end
  Future<void> logBattleEnd(
    String userId,
    String battleId,
    String result,
    int kills,
    int deaths,
  ) async {
    await _analytics.logEvent(
      name: 'battle_end',
      parameters: {
        'user_id': userId,
        'battle_id': battleId,
        'result': result,
        'kills': kills,
        'deaths': deaths,
      },
    );
  }

  // ============ Error Tracking ============

  /// Record error to Crashlytics
  void recordError(
    dynamic exception,
    StackTrace? stackTrace, {
    String? reason,
    Iterable<Object> information = const [],
  }) {
    _crashlytics.recordError(
      exception,
      stackTrace,
      reason: reason,
      information: information,
    );
  }

  /// Set user identifier for Crashlytics
  Future<void> setUserId(String userId) async {
    await _crashlytics.setUserIdentifier(userId);
  }

  /// Set custom key-value pair in Crashlytics
  void setCustomKey(String key, Object value) {
    _crashlytics.setCustomKey(key, value);
  }

  // ============ Custom Events ============

  /// Log custom event with parameters
  Future<void> logCustomEvent(
    String eventName, {
    Map<String, Object>? parameters,
  }) async {
    await _analytics.logEvent(name: eventName, parameters: parameters);
  }

  // ============ Funnel Events (Day 1 Retention) ============

  /// オンボーディング開始
  Future<void> logOnboardingStart(String userId) async {
    await _analytics.logEvent(
      name: 'onboarding_start',
      parameters: {'user_id': userId},
    );
  }

  /// チュートリアル完了
  Future<void> logTutorialComplete(String userId) async {
    await _analytics.logEvent(
      name: 'tutorial_complete',
      parameters: {'user_id': userId},
    );
  }

  /// 初バトル入場
  Future<void> logFirstBattleEnter(String userId) async {
    await _analytics.logEvent(
      name: 'first_battle_enter',
      parameters: {'user_id': userId},
    );
  }

  /// 初バトル勝利（Aha Moment）
  Future<void> logFirstBattleWin(String userId) async {
    await _analytics.logEvent(
      name: 'first_battle_win',
      parameters: {'user_id': userId},
    );
  }

  // ============ Conversion Funnel (LTV) ============

  /// ショップ表示
  Future<void> logShopViewed(String userId) async {
    await _analytics.logEvent(
      name: 'shop_viewed',
      parameters: {'user_id': userId},
    );
  }

  /// 購入完了（BattlePass または Skin Gacha）
  Future<void> logPurchaseComplete(
    String userId,
    String productType, // 'battlepass' or 'skin_gacha'
    double price,
  ) async {
    await _analytics.logEvent(
      name: 'purchase_complete',
      parameters: {
        'user_id': userId,
        'product_type': productType,
        'price': price,
      },
    );
  }

  // ============ Ranked Adoption Funnel ============

  /// ランク戦アンロック可能になった通知
  Future<void> logRankedUnlockAvailable(String userId) async {
    await _analytics.logEvent(
      name: 'ranked_unlock_available',
      parameters: {'user_id': userId},
    );
  }

  /// ランク戦に初参加
  Future<void> logRankedEntryAction(String userId) async {
    await _analytics.logEvent(
      name: 'ranked_entry',
      parameters: {'user_id': userId},
    );
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
    await _analytics.setUserProperty(
      name: 'install_cohort',
      value: installCohort,
    );
    await _analytics.setUserProperty(
      name: 'platform_cohort',
      value: platformCohort,
    );
    await _analytics.setUserProperty(
      name: 'purchase_cohort',
      value: purchaseCohort,
    );

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
        cohortProperties,
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
    await _analytics.logEvent(
      name: 'day_1_active',
      parameters: {'user_id': userId},
    );
  }

  /// Day 7 アクティブセッション記録
  Future<void> logDay7Active(String userId) async {
    await _analytics.logEvent(
      name: 'day_7_active',
      parameters: {'user_id': userId},
    );
  }

  /// Day 30 アクティブセッション記録
  Future<void> logDay30Active(String userId) async {
    await _analytics.logEvent(
      name: 'day_30_active',
      parameters: {'user_id': userId},
    );
  }

  /// Aha Moment までの時間（秒）を記録
  /// リテンション改善の主要指標
  Future<void> logTimeToAhaMoment(
    String userId,
    int secondsToFirstKill,
  ) async {
    await _analytics.logEvent(
      name: 'time_to_aha_moment',
      parameters: {
        'user_id': userId,
        'seconds': secondsToFirstKill,
      },
    );
  }

  // ============ Achievement Events ============

  /// 実績アンロック
  Future<void> logAchievementUnlocked(
    String userId,
    String achievementId,
    String rarity, // common, rare, legendary
  ) async {
    await _analytics.logEvent(
      name: 'achievement_unlocked',
      parameters: {
        'user_id': userId,
        'achievement_id': achievementId,
        'rarity': rarity,
      },
    );
  }
}
