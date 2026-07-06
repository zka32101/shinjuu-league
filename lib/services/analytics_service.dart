import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

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
}
