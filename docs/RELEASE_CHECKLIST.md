# Release Checklist

## Pre-Release Phase (Before Beta/Production)

### 1. Firebase Project Setup ✅
- [x] Firebase project created and linked (apps2-752cb)
- [x] Android app registered with correct package name (`com.petitworksapps.shinjukuleague`)
- [x] iOS app registered (pending)
- [x] `google-services.json` placed in `android/app/`
- [x] `lib/firebase_options.dart` updated with real credentials
- [x] Firebase Crashlytics enabled
- [x] Firebase Analytics enabled
- [x] Firebase Authentication (Anonymous) enabled
- [x] Firestore Database deployed (test mode initially)
- [ ] Firebase Storage enabled (for replay/replay sharing — optional)
- [ ] Firebase Cloud Messaging enabled (for push notifications)
- [ ] Firebase Remote Config deployed with default values

**Approval**: Firebase project admin must review Firestore security rules before production.

### 2. App Store & Play Store Accounts
- [ ] App Store Connect account created
  - [ ] Company legal name and primary contact registered
  - [ ] Payment information added
  - [ ] Tax information (W9/W8BEN) submitted
  - [ ] Banking information for payout
  
- [ ] Google Play Console account created
  - [ ] Company legal name registered
  - [ ] Payment information added
  - [ ] Merchant account linked for payments

**Timeline**: 1-2 weeks for account review and approval.

### 3. App Store Metadata
- [ ] App name finalized: "神獣リーグ" (Shinjuu League)
- [ ] Subtitle created (max 30 chars): "5v5 MOBA • 2レーン • 5分"
- [ ] Marketing description written (max 170 chars)
- [ ] Full description written (max 4000 chars)
  - [ ] Include gameplay mechanics (2-lane, 5-player teams)
  - [ ] Mention cross-platform play
  - [ ] Highlight achievement system
  - [ ] List key features (ranked, cosmetics)
  
- [ ] Keywords selected (Japanese + romanized)
  - Candidates: "MOBA", "ゲーム", "team", "battle", "5v5", "eSports"
  
- [ ] Support URL provided (community forum or contact form)
- [ ] Privacy Policy URL provided
  - [ ] Privacy policy mentions Firebase Analytics data collection
  - [ ] Privacy policy mentions Crashlytics error reporting
  - [ ] Privacy policy covers in-app purchases (RevenueCat)
  
- [ ] Gameplay video/screenshots prepared (App Store: 5 required, 10 recommended)
  - [ ] Battle screen showing 2.5D battlefield
  - [ ] Achievement unlock animation
  - [ ] Ranked leaderboard
  - [ ] Shop/monetization screens
  - [ ] Onboarding sequence

**Resources**:
- [App Store Screenshots Best Practices](https://developer.apple.com/app-store/screenshots/)
- [Google Play Store Listing Guide](https://support.google.com/googleplay/android-developer/answer/9859674)

### 4. Content Rating & Age Classification
- **IARC (International Age Rating Coalition)**
  - [ ] Complete IARC questionnaire for App Store
    - Violence: "Mild" (gameplay violence, no blood)
    - Online connectivity: Checked
    - In-app purchases: Checked
  - [ ] IARC auto-generates PEGI (Europe), GRAC (Korea), ClassInd (Brazil), USK (Germany)
  
- **App Store Age Rating**: 4+ (or 12+ if monetization is prominent)
- **Google Play Age Rating**: 3+ (or Teen if stronger monetization messaging)

### 5. Monetization Configuration
#### RevenueCat Setup (for cross-platform purchase handling)
- [ ] RevenueCat project created
- [ ] iOS App Store Connect API key added to RevenueCat
- [ ] Android Google Play Service Account JSON added to RevenueCat
- [ ] AppConfig.revenueCatApiKey updated in code
  - [ ] Move from empty string to actual API key
  - [ ] Sensitive key stored in environment variables (CI/CD)

#### iOS In-App Purchases
- [ ] App Store Connect → App → In-App Purchases configured:
  - [ ] `com.petitworksapps.shinjukuleague.battlepass_monthly` (¥500/month or equivalent)
  - [ ] `com.petitworksapps.shinjukuleague.skin_gacha_1x` (¥300 or equivalent)
  - [ ] `com.petitworksapps.shinjukuleague.skin_gacha_10x` (¥2400 with 10% bonus)
  
- [ ] Each IAP has:
  - [ ] Display name (Japanese)
  - [ ] Description
  - [ ] Localizations (Japanese minimum, English recommended)
  - [ ] Pricing tier selected
  - [ ] Renewal period configured (BattlePass)
  - [ ] Billing renewal notifications enabled

#### Google Play In-App Purchases
- [ ] Google Play Console → Monetize → In-app products configured:
  - [ ] SKU names match iOS exactly (RevenueCat requires consistency)
  - [ ] Prices set in JPY
  - [ ] Active status confirmed

#### Testing & Sandbox Accounts
- [ ] iOS TestFlight sandbox account created
  - [ ] Account added to iTunes Connect
  - [ ] Can make test purchases without charging
  
- [ ] Google Play internal testing sandbox configured
  - [ ] Test account email added
  - [ ] Can make test purchases without charging

### 6. Push Notifications Setup
- [ ] Firebase Cloud Messaging enabled in Firebase Console
- [ ] iOS APNS Certificate created
  - [ ] Certificate generated from Apple Developer Program
  - [ ] Uploaded to Firebase Console
  
- [ ] Android FCM credentials configured
  - [ ] google-services.json includes FCM server key
  - [ ] FCM sender ID matches in Firebase Console

- [ ] Notification topics pre-configured in Firebase Console
  - [ ] `battlePassSeasonStart`
  - [ ] `maintenanceAlert`
  - [ ] `rankedSeasonEnd`
  - [ ] `friendOnline`
  - [ ] `achievementUnlocked`

- [ ] Test push notification sent successfully to test device

### 7. Remote Config Configuration
- [ ] Firebase Remote Config initialized in Firebase Console
- [ ] Default parameters configured:
  ```json
  {
    "aha_moment_threshold": 1,
    "ranked_unlock_level": 3,
    "battlepass_price_jpy": 500,
    "skin_gacha_price_jpy": 300,
    "matching_elo_tolerance": 100,
    "evolution_difficulty_multiplier": 1.2,
    "elo_k_value": 32
  }
  ```

- [ ] Firebase Console → Remote Config → Create variants for A/B tests
  - [ ] Variant A: Conservative settings (current)
  - [ ] Variant B: Aggressive settings (e.g., Aha Moment = 2 kills)
  - [ ] Targeting rules (% of users)

### 8. Crashlytics Configuration
- [ ] Crashlytics dashboard reviewed for baseline crashes
- [ ] Onboarding crash survey completed (Firebase auto-generates)
- [ ] Team members invited to Crashlytics alerts
  - [ ] Set up Slack integration for crash notifications (optional)

### 9. Analytics Verification
- [ ] Firebase Analytics Dashboard shows test events
  - [ ] Custom event: `aha_moment_reached`
  - [ ] Custom event: `first_ranked_entry`
  - [ ] Custom event: `battlepass_purchased`
  - [ ] Custom event: `skin_purchased`
  
- [ ] Funnel analysis configured
  - [ ] Onboarding funnel: onboarding_start → tutorial_complete → first_battle_enter → first_battle_win
  - [ ] Monetization funnel: shop_viewed → purchase_complete
  - [ ] Retention funnel: day1_active → day7_active → day30_active

- [ ] Cohort comparison set up
  - [ ] Install cohort (by date)
  - [ ] Platform cohort (iOS vs Android)
  - [ ] Purchase cohort (D1Payer vs F2P vs Whale)

### 10. Security & Permissions

#### iOS Permissions
- [ ] Info.plist configured for required permissions:
  ```xml
  <key>NSNotificationPermissionUsageDescription</key>
  <string>プッシュ通知でゲーム情報をお知らせします</string>
  ```

- [ ] Privacy policy reviewed for data collection
  - [ ] Firebase Analytics privacy disclosure
  - [ ] Crashlytics error data privacy
  - [ ] Location/device identifier usage

#### Android Permissions
- [ ] AndroidManifest.xml includes required permissions:
  ```xml
  <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
  ```

- [ ] Google Play Policy compliance verified
  - [ ] No malware/spyware
  - [ ] No misleading content
  - [ ] Accessibility considerations (minimum text size, contrast)

#### Sensitive Data Handling
- [ ] API keys not hardcoded in source (use environment variables)
- [ ] Firebase API key restricted to client apps only (Firebase Console)
- [ ] RevenueCat API key stored in secure environment (not in git)
- [ ] Firestore Security Rules enforce user authentication

### 11. Testing Checklist

#### Functional Testing
- [ ] Onboarding flow works end-to-end (tutorial → first battle → Aha Moment)
- [ ] Matching system finds opponents in < 30 seconds
- [ ] Battle engine runs smoothly (60 FPS on target devices)
- [ ] Battle results recorded correctly
- [ ] Elo calculation verified (no extreme jumps)
- [ ] Achievements unlock correctly
- [ ] Push notifications receive properly
- [ ] Monetization flow works (shop view → purchase → cohort update)

#### Device Testing
- [ ] iPhone SE (minimum supported) — performance acceptable
- [ ] iPhone 12+ — smooth 60 FPS
- [ ] Samsung Galaxy A (minimum Android) — performance acceptable
- [ ] Samsung Galaxy S20+ — smooth 60 FPS
- [ ] Tablet support verified (iPad, Android tablets)

#### Network Resilience
- [ ] App continues if FCM unavailable (in-app notifications only)
- [ ] Analytics events queued offline, sent when reconnected
- [ ] Firestore read/write failures handled gracefully (error UI)
- [ ] No crashes on slow/intermittent network

#### Security Testing
- [ ] Firestore Security Rules tested (read/write unauthorized users denied)
- [ ] Elo manipulation impossible (server-side validation)
- [ ] Replay/share data publicly readable (SharePlay endpoint)
- [ ] User data protected (own data only, no cross-user access)

### 12. Build & Submission

#### iOS Build
- [ ] Provisioning profiles created
- [ ] Code signing certificate valid (not expired)
- [ ] Bundle ID matches Firebase project (`com.petitworksapps.shinjukuleague`)
- [ ] Build number incremented (App Store requires monotonic increase)
- [ ] Version number follows semver (1.0.0 for initial release)
- [ ] TestFlight build uploaded and validated by iOS App Store
- [ ] Automatic resign settings configured in Xcode

**Command**:
```bash
flutter build ipa --release
# Then upload via Xcode organizer
```

#### Android Build
- [ ] APK signed with release keystore
  - [ ] Keystore file backed up securely (not in git)
  - [ ] Keystore password stored securely
  - [ ] Signing certificate SHA256 fingerprint recorded
  
- [ ] Build name/version updated in pubspec.yaml
- [ ] Build artifact uploaded to Google Play Console (signed AAB, not APK)
- [ ] Internal testing track used first (Closed Testing)

**Command**:
```bash
flutter build appbundle --release
# Upload to Google Play Console
```

#### CI/CD Pipeline
- [ ] GitHub Actions workflow configured (.github/workflows/ci.yml)
- [ ] Release build triggered on tag push (vX.Y.Z)
- [ ] Automated build step generates APK/AAB
- [ ] Automated test step verifies no regressions
- [ ] Build artifacts uploaded to cloud storage or artifact repository

### 13. Staged Rollout

#### Closed Beta (Internal Testing)
- [ ] TestFlight/Internal Testing track limited to team
- [ ] Run for 1 week minimum
- [ ] Collect feedback from ~5-10 testers
- [ ] Verify Crashlytics captures test crashes
- [ ] Verify Analytics events flowing correctly

#### Open Beta (Limited Release)
- [ ] Expand to 5-10% of users
- [ ] Monitor Crashlytics for critical crashes
- [ ] Monitor Analytics for funnel drop-offs
- [ ] Collect user feedback (in-app survey or social media)
- [ ] Run for 1-2 weeks

#### Production Release
- [ ] Expand to 50% of users (gradual rollout)
- [ ] Monitor crash rate (target < 0.1% crash-free users)
- [ ] Monitor retention metrics (target 40% D7 retention)
- [ ] If stable, roll out to 100%

### 14. Post-Release Operations

#### Monitoring
- [ ] Crashlytics dashboard monitored daily
- [ ] Analytics retention funnels reviewed weekly
- [ ] Server logs monitored for fraud/abuse
- [ ] Community feedback monitored (Discord, social media)

#### Support
- [ ] Customer support email/Discord channel established
- [ ] FAQ document created (common crashes, gameplay questions)
- [ ] Bug report template created (reproducible steps required)

#### Updates
- [ ] Patch release process documented (hotfix branch from release tag)
- [ ] Feature release process documented (version bump, CHANGELOG.md)
- [ ] Release notes localized (Japanese + English)

---

## Post-Release Maintenance

### Week 1
- [ ] Monitor crash rate (investigate if > 1%)
- [ ] Verify analytics events flowing (check Firebase Console)
- [ ] Respond to community feedback
- [ ] Prepare hotfix if critical bugs found

### Month 1
- [ ] Analyze Day 1 retention (target 60%+)
- [ ] Analyze Aha Moment timing (average time to first kill)
- [ ] Review monetization funnel (shop_viewed → purchase conversion rate)
- [ ] Plan first feature update (balance changes, seasonal content)

### Month 3
- [ ] Analyze Day 30 retention (target 20%+)
- [ ] Review cohort lifetime value (D1Payer vs F2P)
- [ ] Plan Season 2 battlepass content
- [ ] Optimize onboarding if early drop-off detected

---

## Sign-Off

| Role | Name | Date | Status |
|------|------|------|--------|
| Project Lead | (User) | TBD | Pending |
| QA Lead | TBD | TBD | Pending |
| Firebase Admin | TBD | TBD | Pending |
| App Store Contact | TBD | TBD | Pending |
| Google Play Contact | TBD | TBD | Pending |

---

## Appendix: Useful Links

- [App Store Connect Help](https://help.apple.com/app-store-connect/)
- [Google Play Console Help](https://support.google.com/googleplay/android-developer/)
- [Firebase Documentation](https://firebase.google.com/docs)
- [RevenueCat Documentation](https://docs.revenuecat.com/)
- [Flutter Deployment Guide](https://flutter.dev/docs/deployment/ios)
