# Step 6: iOS Firebase Setup Guide

**Status**: Awaiting user Firebase Console configuration  
**Estimated Time**: 1-2 hours (including user actions)  
**Prerequisites**: Firebase project already created (Android app registered)

---

## Overview

This step registers the iOS app in Firebase Console and configures the Flutter app to use Firebase on iOS.

**Current State**:
- ✅ Android Firebase configured (`google-services.json` present)
- ✅ Dart code integrated with Firebase services
- ❌ iOS Firebase NOT YET configured (GoogleService-Info.plist missing)
- ❌ firebase_options.dart has iOS configuration placeholder

**Blockers**:
- iOS app not yet registered in Firebase Console
- GoogleService-Info.plist file needed

---

## Step-by-Step Instructions

### Part A: User Actions in Firebase Console (No Code Changes)

1. **Open Firebase Console**
   - URL: https://console.firebase.google.com/
   - Select project: `apps2-752cb` (shared project)

2. **Register iOS App**
   - Click "Add app" → "iOS"
   - Bundle ID: `com.petitworksapps.shinjukuleague` (matches Android applicationId)
   - App nickname: "Shinjuu League" (or similar)
   - Team ID: Leave blank if not available yet (can be configured later)

3. **Download GoogleService-Info.plist**
   - After registration completes, Firebase provides GoogleService-Info.plist
   - Download the file (do NOT skip - this is critical)
   - Keep the file locally for next step

4. **Verify Firestore Database**
   - Ensure Firestore is enabled in the project
   - Check security rules are configured (should already be from Android setup)

---

### Part B: Developer Actions - File Setup

5. **Place GoogleService-Info.plist**
   ```bash
   # Location: ios/Runner/GoogleService-Info.plist
   cp ~/Downloads/GoogleService-Info.plist ios/Runner/
   ```
   - File must be in `ios/Runner/` directory
   - Exact filename: `GoogleService-Info.plist` (case-sensitive)

6. **Add to Xcode Project** (Xcode GUI)
   - Open Xcode: `open ios/Runner.xcworkspace`
   - Right-click "Runner" in project navigator
   - Select "Add Files to Runner"
   - Choose `ios/Runner/GoogleService-Info.plist`
   - Ensure "Copy items if needed" is checked
   - Ensure "Runner" target is selected

7. **Verify .gitignore**
   - GoogleService-Info.plist should NOT be committed (security)
   - Check `.gitignore` includes: `GoogleService-Info.plist`
   - Already present: ✅ (line 56)

---

### Part C: Update Firebase Configuration (Code Changes)

8. **Update firebase_options.dart**
   - Parse `GoogleService-Info.plist` for iOS configuration
   - Extract: `CLIENT_ID`, `BUNDLE_ID`, `API_KEY`, `MESSAGING_SENDER_ID`, `PROJECT_ID`, `STORAGE_BUCKET`
   - Add iOS configuration to `DefaultFirebaseOptions.get currentPlatform`
   - Support both Android and iOS

   **Example Configuration Structure**:
   ```dart
   class DefaultFirebaseOptions {
     static FirebaseOptions get currentPlatform {
       if (defaultTargetPlatform == TargetPlatform.android) {
         return _androidOptions;
       } else if (defaultTargetPlatform == TargetPlatform.iOS) {
         return _iosOptions;
       }
       throw UnsupportedError('Unknown platform');
     }
     
     static const FirebaseOptions _androidOptions = FirebaseOptions(
       apiKey: 'AIzaSyDqvvJcP4lPYv811PNvs1TptSIhtHupjFY',
       appId: '1:946448575860:android:76b165ede2e5bf4f37d021',
       messagingSenderId: '946448575860',
       projectId: 'apps2-752cb',
       storageBucket: 'apps2-752cb.firebasestorage.app',
     );
     
     static const FirebaseOptions _iosOptions = FirebaseOptions(
       apiKey: '[EXTRACT FROM GoogleService-Info.plist]',
       appId: '[EXTRACT FROM GoogleService-Info.plist]',
       messagingSenderId: '[EXTRACT FROM GoogleService-Info.plist]',
       projectId: '[EXTRACT FROM GoogleService-Info.plist]',
       storageBucket: '[EXTRACT FROM GoogleService-Info.plist]',
       iosBundleId: 'com.petitworksapps.shinjukuleague',
     );
   }
   ```

---

## Extraction Guide: GoogleService-Info.plist → firebase_options.dart

### How to Read GoogleService-Info.plist

1. **Open the plist file in a text editor** (or Xcode)
   ```bash
   cat ios/Runner/GoogleService-Info.plist | head -30
   ```

2. **Key-Value Mapping**:
   | Plist Key | firebase_options.dart | Example Value |
   |-----------|----------------------|---------------|
   | `API_KEY` | `apiKey` | `AIzaSy...` |
   | `CLIENT_ID` | `appId` (first part before `:`) | `1:946448575860:ios:...` |
   | `GCM_SENDER_ID` | `messagingSenderId` | `946448575860` |
   | `PROJECT_ID` | `projectId` | `apps2-752cb` |
   | `STORAGE_BUCKET` | `storageBucket` | `apps2-752cb.firebasestorage.app` |
   | `BUNDLE_ID` | `iosBundleId` | `com.petitworksapps.shinjukuleague` |

3. **Extract Command** (for reference):
   ```bash
   # Extract API_KEY
   defaults read ios/Runner/GoogleService-Info.plist API_KEY
   
   # Extract CLIENT_ID
   defaults read ios/Runner/GoogleService-Info.plist CLIENT_ID
   ```

---

## Testing & Validation

### 9. Verify Configuration

```bash
# Check file exists
ls -la ios/Runner/GoogleService-Info.plist

# Verify firebase_options.dart syntax
dart analyze lib/firebase_options.dart

# Check for compilation errors
flutter pub get
flutter analyze
```

### 10. Build iOS App (Test)

```bash
# Clean build
flutter clean

# Build iOS app (debug)
flutter build ios

# Or run on simulator
flutter run --debug -d simulator
```

### 11. Firebase Initialization Test

On app startup, check for initialization logs:
```
I/Firebase: Firebase app successfully initialized
I/Firestore: Firestore initialized successfully
```

If you see errors, check:
- GoogleService-Info.plist path is correct
- Firestore Security Rules allow read/write (or test mode enabled)
- Network connectivity available

---

## Troubleshooting

### Issue: "GoogleService-Info.plist not found"
**Solution**: Ensure file is in `ios/Runner/` directory and properly added to Xcode target

### Issue: "GOOGLE_APP_ID not found"
**Solution**: Verify `GoogleService-Info.plist` is valid and complete

### Issue: Firebase initialization fails on iOS
**Solution**: Check:
1. Bundle ID matches Firebase Console registration
2. GoogleService-Info.plist is in correct location
3. Xcode build cache cleared (`flutter clean`)

### Issue: "Unable to parse GoogleService-Info.plist"
**Solution**: File might be corrupted during download. Re-download from Firebase Console.

---

## Security Notes

- ❌ Do NOT commit `GoogleService-Info.plist` to git (already in .gitignore)
- ❌ Do NOT share API keys in chat/documentation
- ✅ Keep GoogleService-Info.plist in Xcode project only
- ✅ Use environment-specific configurations for production builds

---

## Next Steps After iOS Setup

Once iOS Firebase is configured:

1. **Test Firebase Services**
   - Run app on iOS simulator/device
   - Verify Firestore reads/writes work
   - Check Analytics events are logged

2. **Update CI/CD Pipeline** (if applicable)
   - Add iOS build to GitHub Actions (future step)
   - Configure App Store Connect integration

3. **Prepare for Release**
   - Code signing certificates
   - Provisioning profiles
   - App Store Connect setup

---

## Files Modified in This Step

| File | Change | Status |
|------|--------|--------|
| `ios/Runner/GoogleService-Info.plist` | NEW (downloaded from Firebase) | ⏳ Awaiting user |
| `lib/firebase_options.dart` | UPDATE (add iOS config) | ⏳ Awaiting plist file |
| `.github/workflows/ci.yml` | No change needed (iOS CI future) | ✅ Current |

---

## Resources

- [Firebase Console](https://console.firebase.google.com/)
- [FlutterFire Installation Guide](https://firebase.flutter.dev/docs/overview/)
- [iOS Firebase Integration](https://firebase.google.com/docs/ios/setup)
- [GoogleService-Info.plist Location](https://firebase.google.com/docs/ios/setup#add_firebase_to_your_ios_project)

---

**Status**: Ready for user to proceed with Firebase Console registration  
**Next Action**: Register iOS app, download GoogleService-Info.plist, run Part B-C code changes
