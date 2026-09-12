# Phase 9 Step 5: iOS Firebase Setup Guide

**Status**: ⏳ Awaiting User Action  
**Target**: Complete iOS Firebase initialization for Phase 9 deployment  
**Timeline**: 15-20 minutes of manual Firebase Console work + 5 minutes of file updates

---

## Overview

This guide walks through registering the iOS app with Firebase and extracting configuration values to enable Firebase services (Auth, Firestore, Analytics, Cloud Messaging) on iOS devices.

**Current State**:
- ✅ Android Firebase: Configured with `google-services.json`
- ✅ Web Firebase: Configured in `firebase_options.dart`
- ⏳ iOS Firebase: Placeholders ready in `firebase_options.dart`, awaiting GoogleService-Info.plist

---

## Prerequisites

1. **Firebase Project Access**: Access to Firebase Console for project `apps2-752cb`
   - URL: https://console.firebase.google.com/u/0/project/apps2-752cb/overview
   - Contact: Ask project owner (petitworksapps/senjosshogi) for Collaborator access if needed

2. **iOS Bundle Identifier**: `com.petitworksapps.shinjukuleague`
   - Matches: `ios/Runner.xcodeproj` and `pubspec.yaml`
   - Verified in: `lib/firebase_options.dart` line 52

3. **Xcode (Optional)**: For manual `.plist` import if needed
   - Not required if downloading plist from Firebase Console

---

## Step-by-Step: Firebase Console Configuration

### Step 1: Navigate to Firebase Console

1. Open https://console.firebase.google.com/
2. Select project **`apps2-752cb`**
3. Click **"Project Settings"** (gear icon, top-left)

### Step 2: Register iOS App

1. In Project Settings, click the **iOS** tab at the top (or **"Add App"** if tabs not visible)
2. Click **"Add App"** → **"iOS"**
3. Fill in the form:
   - **iOS Bundle ID**: `com.petitworksapps.shinjukuleague`
   - **App Nickname** (optional): `Shinjuu League iOS`
   - **App Store ID** (skip for development): Leave blank
4. Click **"Register App"**

### Step 3: Download GoogleService-Info.plist

1. Firebase will display **"Download GoogleService-Info.plist"** button
2. Click to download the `.plist` file
   - Filename will be: `GoogleService-Info.plist`
   - Size: ~2-3 KB

3. **Save to**: 
   ```
   ios/Runner/GoogleService-Info.plist
   ```
   - This directory must exist (created during Flutter iOS setup)
   - `.plist` file will auto-link to Xcode project

### Step 4: Firebase Console: Verify iOS App Registration

1. Back in Firebase Console, click **"Next"** to continue setup
2. You should see:
   - ✅ "iOS app registered successfully"
   - iOS app listed under "Your apps" section

---

## Step-by-Step: Extract Configuration Values

### Step 5: Open GoogleService-Info.plist

1. Download the `.plist` file (from Step 3 above)
2. Open with a text editor:
   - **macOS**: Right-click → "Open With" → "TextEdit" (or any editor)
   - **Alternative**: Open with Xcode (double-click opens in Xcode)

The file will look like:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>API_KEY</key>
	<string>AIzaSy_XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX</string>
	
	<key>BUNDLE_ID</key>
	<string>com.petitworksapps.shinjukuleague</string>
	
	<key>CLIENT_ID</key>
	<string>946448575860-XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.apps.googleusercontent.com</string>
	
	<key>DATABASE_URL</key>
	<string>https://apps2-752cb.firebaseio.com</string>
	
	<key>GCM_SENDER_ID</key>
	<string>946448575860</string>
	
	<key>GOOGLE_APP_ID</key>
	<string>1:946448575860:ios:XXXXXXXXXXXXXXXXXXXXXXXX</string>
	
	<key>GOOGLE_CRASH_REPORTING_API_KEY</key>
	<string>AIzaSy_XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX</string>
	
	<key>IS_ADS_ENABLED</key>
	<false/>
	
	<key>IS_ANALYTICS_ENABLED</key>
	<true/>
	
	<key>IS_APPINVITE_ENABLED</key>
	<false/>
	
	<key>IS_GCM_ENABLED</key>
	<true/>
	
	<key>IS_SIGNIN_ENABLED</key>
	<true/>
	
	<key>MESSAGING_SENDER_ID</key>
	<string>946448575860</string>
	
	<key>PROJECT_ID</key>
	<string>apps2-752cb</string>
	
	<key>STORAGE_BUCKET</key>
	<string>apps2-752cb.firebasestorage.app</string>
</dict>
</plist>
```

### Step 6: Extract Values for Dart Configuration

Map the `.plist` keys to `lib/firebase_options.dart` iOS FirebaseOptions:

| Plist Key | Maps To | Example Value |
|-----------|---------|---------------|
| `API_KEY` | `apiKey` | `AIzaSy_...` |
| `GOOGLE_APP_ID` | `appId` | `1:946448575860:ios:...` |
| `GCM_SENDER_ID` | `messagingSenderId` | `946448575860` |
| `PROJECT_ID` | `projectId` | `apps2-752cb` (already filled) |
| `STORAGE_BUCKET` | `storageBucket` | `apps2-752cb.firebasestorage.app` (already filled) |

---

## Update lib/firebase_options.dart

### Current Placeholders (iOS section):

```dart
static const FirebaseOptions ios = FirebaseOptions(
  apiKey: 'PLACEHOLDER_API_KEY',                    // ← Replace
  appId: 'PLACEHOLDER_APP_ID',                      // ← Replace
  messagingSenderId: 'PLACEHOLDER_MESSAGING_SENDER_ID',  // ← Replace
  projectId: 'apps2-752cb',                         // ✅ Already correct
  storageBucket: 'apps2-752cb.firebasestorage.app', // ✅ Already correct
  iosBundleId: 'com.petitworksapps.shinjukuleague', // ✅ Already correct
);
```

### Steps to Update:

1. **Extract from GoogleService-Info.plist** (from Step 6 above):
   - `API_KEY` value
   - `GOOGLE_APP_ID` value
   - `GCM_SENDER_ID` value

2. **Open** `lib/firebase_options.dart`

3. **Replace placeholders**:
   ```dart
   static const FirebaseOptions ios = FirebaseOptions(
     apiKey: 'AIzaSy_XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX',          // From API_KEY
     appId: '1:946448575860:ios:XXXXXXXXXXXXXXXXXXXXXXXX',        // From GOOGLE_APP_ID
     messagingSenderId: '946448575860',                           // From GCM_SENDER_ID
     projectId: 'apps2-752cb',                                    // ✅ No change
     storageBucket: 'apps2-752cb.firebasestorage.app',            // ✅ No change
     iosBundleId: 'com.petitworksapps.shinjukuleague',            // ✅ No change
   );
   ```

4. **Save** `lib/firebase_options.dart`

---

## Place GoogleService-Info.plist in iOS Project

### Method A: Manual File Copy (Recommended)

1. **Download** `GoogleService-Info.plist` from Firebase Console (Step 3)
2. **Place** in: `ios/Runner/GoogleService-Info.plist`
3. **Verify**: 
   ```bash
   ls -la ios/Runner/GoogleService-Info.plist
   # Should show file exists, ~2-3 KB
   ```

### Method B: Xcode Import (Alternative)

1. Open Xcode: `xcode ios/Runner.xcodeproj`
2. Drag & drop `GoogleService-Info.plist` into Xcode
3. Ensure:
   - ✅ "Copy items if needed" is checked
   - ✅ "Runner" target is selected
4. Save project

---

## Verification Checklist

- [ ] `ios/Runner/GoogleService-Info.plist` exists (2-3 KB file)
- [ ] `lib/firebase_options.dart` iOS section filled with real values:
  - [ ] `apiKey` is no longer `PLACEHOLDER_*`
  - [ ] `appId` is no longer `PLACEHOLDER_*`
  - [ ] `messagingSenderId` is no longer `PLACEHOLDER_*`
  - [ ] `projectId` = `apps2-752cb`
  - [ ] `storageBucket` = `apps2-752cb.firebasestorage.app`
  - [ ] `iosBundleId` = `com.petitworksapps.shinjukuleague`
- [ ] Firebase Console shows iOS app registered under project

---

## Testing Firebase on iOS

### Local Verification (No Device Required)

```bash
# Check plist file syntax
plutil -p ios/Runner/GoogleService-Info.plist

# Verify Dart code compiles
flutter pub get
flutter analyze lib/firebase_options.dart
```

### Physical Device Testing (Optional)

1. Connect iOS device
2. Build and run:
   ```bash
   flutter run --release
   ```
3. Observe Firebase initialization logs:
   ```
   ✅ Firebase Core initialized successfully
   ✅ Firestore connection established
   ✅ Analytics tracking enabled
   ```

---

## Troubleshooting

### Issue: "Firebase not initialized on iOS"

**Cause**: `GoogleService-Info.plist` not found or not linked to Xcode project

**Solution**:
1. Verify file exists: `ls ios/Runner/GoogleService-Info.plist`
2. Re-add to Xcode if needed (Method B above)
3. Clean build: `flutter clean && flutter pub get`

### Issue: "Invalid API key"

**Cause**: `apiKey` in `firebase_options.dart` doesn't match `.plist`

**Solution**:
1. Double-check copy-paste in Step 6
2. Re-extract from `.plist` file
3. Verify no leading/trailing spaces

### Issue: Bundle ID mismatch

**Cause**: `iosBundleId` in Firebase != actual app bundle ID

**Solution**:
1. Verify in Xcode: Project → Runner → General → Bundle Identifier
2. Must match: `com.petitworksapps.shinjukuleague`
3. Re-register iOS app in Firebase Console if needed

---

## Next Steps After Setup

1. **Commit changes**:
   ```bash
   git add lib/firebase_options.dart ios/Runner/GoogleService-Info.plist
   git commit -m "Phase 9 Step 5: iOS Firebase Configuration

   - Add GoogleService-Info.plist to iOS project
   - Update firebase_options.dart with iOS credentials
   - Enable Firebase services on iOS (Auth, Firestore, Analytics)"
   ```

2. **Create Pull Request** with Phase 9 completion summary

3. **Optional: E2E Testing**
   - Run full suite: Skill Allocation → Battle → Stats Verify
   - Test on physical iOS device if available

4. **Phase 10 Planning**: Post-Phase 9 enhancements
   - Remote Config ABtesting
   - Seasonal rewards distribution
   - Cross-platform data sync

---

## Firebase Services Now Enabled (iOS)

✅ **Authentication** (Anonymous login, Google Sign-In)  
✅ **Firestore Database** (Real-time user/battle data)  
✅ **Analytics** (KPI events: aha_moment, battlepass_purchased, etc.)  
✅ **Crashlytics** (Error reporting & diagnostics)  
✅ **Cloud Messaging** (Push notifications for season events)  
✅ **Cloud Storage** (Replay video/asset uploads)  

---

## References

- **Firebase Console**: https://console.firebase.google.com/u/0/project/apps2-752cb/
- **Firebase iOS Setup**: https://firebase.google.com/docs/ios/setup
- **GoogleService-Info.plist Format**: https://firebase.google.com/docs/reference/config/google-services-ios
- **Project Config**: `lib/firebase_options.dart` (current implementation)

---

**Phase 9 Step 5 Status**: Ready for user to execute Firebase Console steps & provide GoogleService-Info.plist  
**Estimated Completion**: 15-20 minutes  
**Phase 9 Completion**: 80% → 100% after iOS Firebase setup complete
