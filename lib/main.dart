import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shinjuu_league/config/app_config.dart';
import 'package:shinjuu_league/config/app_routes.dart';
import 'package:shinjuu_league/config/theme.dart';
import 'package:shinjuu_league/services/achievement_service.dart';
import 'package:shinjuu_league/services/asset_service.dart';
import 'package:shinjuu_league/services/bgm_service.dart';
import 'package:shinjuu_league/services/performance_service.dart';
import 'package:shinjuu_league/services/push_notification_service.dart';
import 'package:shinjuu_league/services/remote_config_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Firebase Remote Config を初期化（ABテスト・機能フラグ）
  await RemoteConfigService().init();

  // 資産（Lottie・SE・BGM）をプリロード
  // 実ファイルが無い場合でも安全に続行
  await AssetService().init();

  // BGM音楽管理を初期化（フェードイン/アウト、ボリューム制御）
  await BGMService().init();

  // パフォーマンス計測を初期化（デバッグモード時のみ有効）
  await PerformanceService().init();

  // プッシュ通知・実績システムを初期化
  await PushNotificationService().init();
  await AchievementService().init();

  // 未捕捉例外は全てCrashlyticsへ送る（エラーバウンダリ）
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  runApp(const ProviderScope(child: ShinJuuLeagueApp()));
}

class ShinJuuLeagueApp extends ConsumerWidget {
  const ShinJuuLeagueApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: AppConfig.gameName,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
    );
  }
}
