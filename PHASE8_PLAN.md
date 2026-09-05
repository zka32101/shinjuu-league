# Phase 8: Item System + Achievement Persistence + Release Prep
**Status**: 🟡 PLANNED  
**Start Date**: 2026-09-05  
**Target**: Complete core game economy + iOS setup

---

## Overview

Phase 8 completes the game economy systems (items, achievements) and begins release preparation. Phase 7 Sprint 2 established asset/performance infrastructure; Phase 8 integrates item bonuses into battle + persists achievement progress.

**Key Deliverables**:
1. Item System Service (item bonuses → battle engine)
2. Achievement Persistence (Firestore + local cache)
3. Item Shop Modal (equip/purchase items)
4. Skill System Integration
5. iOS Firebase Setup (GoogleService-Info.plist)
6. Release Preparation Roadmap (Step 16)

---

## Detailed Scope

### 1. Item System (NEW)
**Files**:
- `lib/data/models/item_model.dart` - Item definition (name, description, rarity, bonuses)
- `lib/services/item_service.dart` - Item inventory management
- `lib/data/providers/item_provider.dart` - Riverpod providers
- `lib/viewmodels/inventory_viewmodel.dart` - ViewModel for inventory screen
- `lib/ui/screens/inventory_screen.dart` - Item equipped/unequipped UI
- `lib/ui/widgets/item_shop_modal.dart` - Shop modal from resource_hud.dart TODO
- `test/item_system_test.dart` - 20+ tests (CRUD, bonus application, shop)

**Scope**:
- Item types: Weapon (attack +), Armor (defense +), Charm (HP +)
- Rarity system: COMMON → RARE → EPIC → LEGEND
- Bonus formula: `baseStats * (1 + itemBonus%)`
- Max equipped: 3 items simultaneously
- Firestore schema: `users/{uid}/items/{itemId}` (owned) + `users/{uid}/equippedItems` (3-item array)

**Integration**:
- `BattleEngine.getParticipantStats()` → apply equipped item bonuses before damage calculation
- `BattleViewModelgetPlayerStats()` → include item modifiers in UI display

**Done Definition**:
- ✅ Item CRUD operations (create, equip, unequip, sell)
- ✅ Bonus application in battle engine
- ✅ Shop UI functional
- ✅ Persistence to Firestore
- ✅ 20+ unit/widget tests

---

### 2. Achievement System Persistence
**Files**:
- `lib/services/achievement_service.dart` (MODIFY)
  - Add `loadAchievements(userId)` → Firestore + fallback to SharedPrefs
  - Add `persistAchievementProgress(userId, achievementId, progress)`
- `lib/data/models/achievement_model.dart` - Achievement with progress tracking
- `test/achievement_persistence_test.dart` - 12+ tests (load/save, offline cache)

**Scope**:
- Load achievements from Firestore on app start
- Sync local cache (SharedPrefs) with server periodically
- Offline fallback: if Firestore unavailable, read from SharedPrefs
- Achievement progress: `current_count / target_count` (e.g., 1/3 kills for first achievement)

**Integration**:
- Battle results → `achievementService.tryUnlock(userId, achievementId, event)`
- Sync to Firestore every 30 seconds (or on achievement unlock)
- Analytics: `logAchievementUnlocked()` event

**Done Definition**:
- ✅ Firestore `achievements/{userId}/progress` schema
- ✅ SharedPrefs local cache
- ✅ Sync logic with exponential backoff on failure
- ✅ 12+ tests (offline/online scenarios)

---

### 3. Skill System Service Integration
**Files**:
- `lib/services/skill_system_service.dart` (MODIFY)
  - Add `buildSkillTree(userId)` → return available skills
  - Add `applySkillBoost(skillId, participant)` → return stat modifications
- `lib/viewmodels/skill_build_viewmodel.dart` (MODIFY)
  - Connect to SkillSystemService for real skill tree data
- `test/skill_system_integration_test.dart` - 10+ tests

**Scope**:
- Skill tree: 3 trees (Attack, Defense, Speed) each with 5 tiers
- Skill points: earned on level-up (1 point per level)
- Stat boost: ATK tree +5% per tier, DEF +8% per tier, SPD +3% per tier
- Firestore schema: `users/{uid}/skillTree` (allocated points per skill)

**Integration**:
- `User.level` → skill points available = `level - 1`
- Battle engine applies skill boosts to participant base stats before damage calculation
- UI: SkillBuildScreen shows tree, allocate/reset buttons

**Done Definition**:
- ✅ Skill tree CRUD (allocate, reset)
- ✅ Stat boost calculation
- ✅ Firestore persistence
- ✅ 10+ tests

---

### 4. iOS Firebase Setup
**Manual Steps** (User action required):
1. Go to Firebase Console → `apps2-752cb` project
2. Click "Create new app" → iOS
3. Enter bundle ID: `com.petitworksapps.shinjukuleague`
4. Download `GoogleService-Info.plist`
5. Drag into Xcode project under `Runner/Runner`

**Code Changes**:
- Update `lib/firebase_options.dart` to include iOS platform configuration
- Test iOS build: `flutter build ios --no-codesign`

**Done Definition**:
- ✅ GoogleService-Info.plist configured
- ✅ iOS build compiles successfully
- ✅ Firebase initialization works on iOS simulator

---

### 5. Release Preparation (Step 16)
**Documentation**:
- Create `docs/STEP_16_RELEASE_PREPARATION.md` (already exists, review/update)
- App Store listing template
- Privacy Policy + EULA template
- Release notes (v0.1.0)

**Staging Build**:
- Create `staging` branch from `main`
- Enable production features: `RemoteConfig` values finalized
- Test all purchase flows
- Performance validation: 60 FPS sustained, memory < 200MB

**Done Definition**:
- ✅ Documentation complete
- ✅ Staging build tested
- ✅ Release notes drafted
- ✅ Legal docs ready for review

---

## Implementation Order (Week 1-2)

### Week 1
- **Day 1-2**: Item System (models + service + tests)
- **Day 2-3**: Item Shop UI + inventory integration
- **Day 3-4**: Achievement Persistence (Firestore + cache)
- **Day 4**: Skill System Integration

### Week 2
- **Day 1**: iOS Firebase Setup
- **Day 1-2**: Release Preparation + documentation
- **Day 2-3**: Integration testing + QA
- **Day 3**: Code review + merge to main

---

## Testing Strategy

### Unit Tests (40+ tests)
- Item CRUD: 8 tests
- Bonus calculation: 6 tests
- Achievement persistence: 12 tests
- Skill system: 10 tests
- iOS Firebase: 4 tests

### Widget Tests (15+ tests)
- ItemShopModal: 4 tests
- InventoryScreen: 5 tests
- SkillBuildScreen: 6 tests

### Integration Tests (5+ tests)
- Full purchase + item equip flow
- Achievement unlock + sync flow
- Skill allocation + battle with boosts

---

## Success Criteria

1. **Items Working**:
   - ✅ Equip/unequip items changes battle stats
   - ✅ Shop modal displays + purchase works
   - ✅ 3-item limit enforced

2. **Achievements Synced**:
   - ✅ Offline: achievements load from SharedPrefs
   - ✅ Online: Firestore syncs every 30s
   - ✅ New achievement unlocks fire analytics event

3. **Skills Integrated**:
   - ✅ Allocate points → stat changes
   - ✅ Battle engine applies boosts
   - ✅ UI reflects real skill tree

4. **iOS Ready**:
   - ✅ Firebase initialized on iOS
   - ✅ APK + IPA build successful
   - ✅ Android + iOS versions feature-parity

5. **Release Ready**:
   - ✅ All docs complete
   - ✅ Staging build passes QA
   - ✅ No known high-priority bugs

---

## Blockers & Risks

### 🟡 Moderate Risk
- **Item balance** might require tuning post-launch
  - Mitigation: Use Remote Config for item bonus percentages
- **Achievement unlock conditions** might be too strict/loose
  - Mitigation: Monitor telemetry, adjust via Remote Config

### 🟢 No Blockers
- Asset files (design team) can arrive anytime without blocking
- RevenueCat (revenue team) setup is independent

---

## Out of Scope (Phase 9+)

- Cosmetic items (skins beyond battle pass)
- Achievement seasons/leaderboards
- Advanced skill tree UI (3D visualization)
- Cross-progression (sync across devices)

---

## Branch Strategy

- Feature branch: `claude/shinjuu-league-phase8-dev`
- Create from `main` after Phase 7 Sprint 2 merge
- Merge back to `main` when all tests pass + code review approved
- Tag as `v0.8.0-beta` for staging release

---

**Created**: 2026-09-05  
**Estimated Duration**: 10-12 working days  
**Next Review**: After Phase 7 Sprint 2 successfully merges to main
