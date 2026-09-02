import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'firestore_service.dart';

/// プッシュ通知（FCM）統合サービス
/// バックグラウンド・フォアグラウンド・終了状態の通知をハンドル
class PushNotificationService {
  static final PushNotificationService _instance =
      PushNotificationService._internal();

  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  late final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  late final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// 通知受信ストリーム（フォアグラウンド）
  late final Stream<RemoteMessage> _foregroundStream;

  /// 初期化
  Future<void> init() async {
    try {
      // iOS の APN 許可をリクエスト
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        if (kDebugMode) {
          debugPrint('User declined push notification permission');
        }
        return;
      }

      // FCM トークンを取得・保存
      final token = await _messaging.getToken();
      if (token != null) {
        await _saveFCMToken(token);
        if (kDebugMode) {
          debugPrint('FCM Token: $token');
        }
      }

      // トークンリフレッシュ時にキャッシュを更新
      _messaging.onTokenRefresh.listen((token) => _onTokenRefresh(token));

      // ローカル通知の初期化
      await _initializeLocalNotifications();

      // フォアグラウンド メッセージハンドラ
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // バックグラウンド メッセージハンドラ
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      // 終了状態からのアプリ起動時の初期メッセージ確認
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleMessageOpenedApp(initialMessage);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('PushNotificationService.init error: $e');
      }
    }
  }

  /// ローカル通知の初期化
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null) {
          _handleNotificationPayload(payload);
        }
      },
    );
  }

  /// FCM トークンリフレッシュ時のコールバック
  Future<void> _onTokenRefresh(String token) async {
    if (kDebugMode) {
      debugPrint('FCM token refreshed: $token');
    }
    await _saveFCMToken(token);
  }

  /// フォアグラウンド メッセージハンドラ
  void _handleForegroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      debugPrint(
        'Foreground message: title=${message.notification?.title}, body=${message.notification?.body}',
      );
    }

    // ローカル通知で表示
    _showLocalNotification(
      title: message.notification?.title ?? 'Notification',
      body: message.notification?.body ?? '',
      payload: message.data.toString(),
    );
  }

  /// バックグラウンド メッセージハンドラ
  void _handleMessageOpenedApp(RemoteMessage message) {
    if (kDebugMode) {
      debugPrint('Message opened: title=${message.notification?.title}');
    }

    final payload = message.data;
    _handleNotificationPayload(payload.toString());
  }

  /// ローカル通知を表示
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'shinjuu_league_channel',
        'Game Notifications',
        channelDescription: 'Important game notifications and achievements',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        0,
        title,
        body,
        details,
        payload: payload,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error showing local notification: $e');
      }
    }
  }

  /// 通知ペイロードの処理
  void _handleNotificationPayload(String payload) {
    if (kDebugMode) {
      debugPrint('Handling notification payload: $payload');
    }

    // ペイロード例: {"type": "achievement_unlock", "achievement_id": "first_kill"}
    // アプリはこのペイロードに基づいて画面遷移等を実行
    // （実装は ViewModel 層で処理）
  }

  /// FCM トークンを Firestore に永続化
  Future<void> _saveFCMToken(String token) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final firestoreService = FirestoreService();
        await firestoreService.persistFcmToken(user.uid, token);
        if (kDebugMode) {
          debugPrint('FCM token persisted for user ${user.uid}');
        }
      } else {
        if (kDebugMode) {
          debugPrint('User not authenticated, skipping FCM token persistence');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error persisting FCM token: $e');
      }
      // Don't throw - token persistence is non-critical
      // App continues to function with only topic-based subscriptions
    }
  }

  /// トピックをサブスクライブ
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      if (kDebugMode) {
        debugPrint('Subscribed to topic: $topic');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error subscribing to topic $topic: $e');
      }
    }
  }

  /// トピックをアンサブスクライブ
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      if (kDebugMode) {
        debugPrint('Unsubscribed from topic: $topic');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error unsubscribing from topic $topic: $e');
      }
    }
  }

  /// デバッグ用: 通知許可状態をダンプ
  Future<Map<String, dynamic>> debugDumpNotificationSettings() async {
    try {
      final settings = await _messaging.getNotificationSettings();
      final token = await _messaging.getToken();

      return {
        'authorization_status':
            settings.authorizationStatus.toString(),
        'alert': settings.alert.toString(),
        'sound': settings.sound.toString(),
        'badge': settings.badge.toString(),
        'fcm_token': token ?? 'not_available',
      };
    } catch (e) {
      return {
        'error': e.toString(),
      };
    }
  }
}

/// 通知トピックの定義
abstract class NotificationTopics {
  // ゲーム内イベント
  static const battlePassSeasonStart = 'battlepass_season_start';
  static const maintenanceAlert = 'maintenance_alert';
  static const serverUpdate = 'server_update';

  // ランク戦
  static const rankedSeasonEnd = 'ranked_season_end';
  static const rankedPromotionAvailable = 'ranked_promotion_available';

  // ソーシャル
  static const friendOnline = 'friend_online';
  static const guildInvite = 'guild_invite';

  // 実績
  static const achievementUnlocked = 'achievement_unlocked';
}

/// 通知ペイロード型定義
class NotificationPayload {
  final String type;
  final Map<String, dynamic> data;

  NotificationPayload({
    required this.type,
    required this.data,
  });

  factory NotificationPayload.fromJson(Map<String, dynamic> json) {
    return NotificationPayload(
      type: json['type'] as String? ?? 'unknown',
      data: json['data'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type,
    'data': data,
  };
}
