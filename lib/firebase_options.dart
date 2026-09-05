// Firebase configuration for Android and iOS
// Android: google-services.json (petitworksdev account, shared project apps2-752cb)
// iOS: GoogleService-Info.plist (registered in Firebase Console)
// See docs/STEP6_IOS_FIREBASE_SETUP.md for iOS configuration instructions

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.web:
        throw UnsupportedError(
          'DefaultFirebaseOptions has not been configured for web',
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
    apiKey: 'PLACEHOLDER_API_KEY', // Replace with value from GoogleService-Info.plist
    appId: 'PLACEHOLDER_APP_ID', // Replace with value from GoogleService-Info.plist
    messagingSenderId: 'PLACEHOLDER_MESSAGING_SENDER_ID', // Replace with GCM_SENDER_ID
    projectId: 'apps2-752cb', // Same as Android
    storageBucket: 'apps2-752cb.firebasestorage.app', // Same as Android
    iosBundleId: 'com.petitworksapps.shinjukuleague',
  );
}
