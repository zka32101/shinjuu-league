// Firebase configuration for Android and iOS
// Android: google-services.json (petitworksdev account, shared project apps2-752cb)
// iOS: GoogleService-Info.plist (registered in Firebase Console)
// See docs/STEP6_IOS_FIREBASE_SETUP.md for iOS configuration instructions

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    // Web was never registered via `flutterfire configure` (only
    // Android/iOS have been, see the header comment), so this branch was
    // missing entirely - defaultTargetPlatform on web resolves to one of
    // the switch's throwing cases (fuchsia/windows/linux/macOS depending on
    // the browser's reported platform), so Firebase.initializeApp() threw
    // before main() ever reached runApp(), leaving a permanently blank
    // page. `web` below is a placeholder (not a real registered app) that
    // only lets initializeApp() succeed locally; real backend-touching
    // calls (Auth/Firestore/Analytics) will fail asynchronously until a
    // real web app is registered and these values are replaced - every
    // caller already degrades gracefully on failure (e.g.
    // AchievementsScreen's "ログインが必要です" fallback), so that's a
    // missing-feature state, not a crash.
    if (kIsWeb) {
      return web;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.fuchsia:
        throw UnsupportedError(
          'DefaultFirebaseOptions has not been configured for fuchsia',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions has not been configured for windows',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions has not been configured for linux',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions has not been configured for macos',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDqvvJcP4lPYv811PNvs1TptSIhtHupjFY',
    appId: '1:946448575860:android:76b165ede2e5bf4f37d021',
    messagingSenderId: '946448575860',
    projectId: 'apps2-752cb',
    storageBucket: 'apps2-752cb.firebasestorage.app',
  );

  /// iOS configuration from GoogleService-Info.plist
  /// UPDATE THIS with values from your downloaded GoogleService-Info.plist
  /// See docs/STEP6_IOS_FIREBASE_SETUP.md for instructions
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey:
        'PLACEHOLDER_API_KEY', // Replace with value from GoogleService-Info.plist
    appId:
        'PLACEHOLDER_APP_ID', // Replace with value from GoogleService-Info.plist
    messagingSenderId:
        'PLACEHOLDER_MESSAGING_SENDER_ID', // Replace with GCM_SENDER_ID
    projectId: 'apps2-752cb', // Same as Android
    storageBucket: 'apps2-752cb.firebasestorage.app', // Same as Android
    iosBundleId: 'com.petitworksapps.shinjukuleague',
  );

  /// Web has not been registered in the Firebase Console / via
  /// `flutterfire configure` yet - these are placeholders, NOT a real
  /// web app's credentials. They only exist to let Firebase.initializeApp()
  /// succeed locally on web (see currentPlatform's kIsWeb branch above);
  /// replace with the real config once a web app is registered for project
  /// apps2-752cb.
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'PLACEHOLDER_WEB_API_KEY',
    appId: 'PLACEHOLDER_WEB_APP_ID',
    messagingSenderId: 'PLACEHOLDER_MESSAGING_SENDER_ID',
    projectId: 'apps2-752cb', // Same as Android
    storageBucket: 'apps2-752cb.firebasestorage.app', // Same as Android
  );
}
