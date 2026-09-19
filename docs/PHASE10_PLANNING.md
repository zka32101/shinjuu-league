# Phase 10 Planning - Advanced Progression System

**Status**: 📋 Design Phase (Pre-Implementation)  
**Target**: Advanced seasonal rewards, skill tree resets, analytics  
**Estimated Work**: 5 steps, 1500+ LOC, 50+ tests  

---

## Phase 10 Vision

Transform skill tree progression into a **seasonal competitive system** with:
- **Rewards**: Tier-based rewards (cosmetics, currency, battle pass items)
- **Resets**: Season transitions with carryover mechanics
- **Analytics**: Player progression tracking & comparative insights
- **Engagement**: Achievement system tied to progression milestones

---

## Phase 10 Planned Steps (5 Total)

### Step 1: Seasonal Rewards System (200+ LOC, 12+ tests)
**Goal**: Distribute rewards based on final season tier

**Components**:
```dart
// Data Models
SeasonalReward {
  rewardId: String,
  tier: String,              // Bronze/Silver/Gold/Platinum/Diamond
  rewardType: RewardType,    // cosmetic_skin | battle_pass_item | currency
  quantity: int,             // amount of currency / count of items
  displayName: String,
  iconUrl: String,
}

SeasonRewardDistribution {
  seasonId: String,
  userId: String,
  finalTier: String,
  rewards: List<SeasonalReward>,
  claimedAt: DateTime?,
  expiresAt: DateTime,       // Claim by end of next season
}
```

**Service Layer**:
- `SeasonRewardService.getRewardsForTier(tier)` → List<SeasonalReward>
- `SeasonRewardService.distributeSeasonRewards(seasonId, userId, finalTier)` → void
- `SeasonRewardService.claimRewards(userId, seasonId)` → bool

**UI Integration**:
- Season Results Screen: Display tier badge + reward preview
- Inventory: Show claimed rewards history
- Notifications: "Season ended! Claim your rewards"

**Tests**:
- Reward mapping by tier
- Distribution to all season participants
- Claim mechanics (one-time, expiration)
- Cross-season reward independence

---

### Step 2: Skill Tree Reset Mechanism (150+ LOC, 10+ tests)
**Goal**: Safe season transitions with optional carryover

**Components**:
```dart
// Data Models
SkillTreeReset {
  seasonId: String,
  userId: String,
  previousTree: SkillTree,     // Backup of last season
  currentTree: SkillTree,      // Fresh allocation
  resetAt: DateTime,
  carryoverMode: CarryoverMode, // none | partial | full
}

enum CarryoverMode {
  none,      // Complete reset (all tiers → 0)
  partial,   // 50% carryover (5 points → 2-3 points)
  full,      // Keep all points (retain tier progress)
}
```

**Service Layer**:
- `SkillTreeService.resetForNewSeason(userId, carryoverMode)` → SkillTree
- `SkillTreeService.getSeasonHistory(userId)` → List<SkillTreeSnapshot>
- `SkillTreeService.compareSeasons(userId, seasonId1, seasonId2)` → ProgressDelta

**Game Design**:
- Default: **Partial carryover** (fairness balance)
  - Max 5 points → 2-3 points carried forward
  - Prevents top players from dominating immediately
  - Rewards consistent play without permanent advantage
- Player Choice: Optional "Full Reset" for challenge runs

**Tests**:
- Carryover calculation correctness
- Reset history persistence
- Season isolation (no cross-contamination)
- Partial carryover math validation

---

### Step 3: Progression Analytics Dashboard (250+ LOC, 15+ tests)
**Goal**: Visualize player progression across seasons

**Components**:
```dart
// Data Models
ProgressionStats {
  userId: String,
  currentSeason: SeasonStats,
  allSeasons: List<SeasonStats>,
  allTimeStats: AggregateStats,
}

SeasonStats {
  seasonId: String,
  startedAt: DateTime,
  finalTier: String,
  maxTierReached: String,
  pointsAllocated: int,
  totalTime: Duration,         // Time played this season
  winRate: double,             // Win rate with boosted stats
  eloProgression: List<(date, rating)>,  // ELO curve
}

AggregateStats {
  totalSeasonsPlayed: int,
  favoriteTree: String,        // Most invested tree
  averageTier: String,
  highestTierEver: String,
  totalRewardsClaimed: Map<RewardType, int>,
  progression: ProgressionTrend,  // up / stable / down
}

ProgressionTrend {
  seasonOverSeason: double,    // % change in tier rating
  winRateTrend: double,
  eloTrend: double,
  prediction: String,          // "climbing" / "plateau" / "declining"
}
```

**UI Screens**:
1. **Seasonal Overview** - Current season stats
   - Tier badge + progress to next tier
   - Stats: points allocated, games played, win rate
   - ELO curve (season progression graph)
   - Rewards claimed / pending

2. **Progression Timeline** - Multi-season comparison
   - Season cards (tier reached, duration, rewards)
   - Line chart: ELO over time (all seasons)
   - Filter: by tree, by tier, by reward type

3. **Comparative Analysis** - Before/After comparison
   - "S1 vs S2": Stats side-by-side
   - Improvements: Tier change, ELO delta, win rate change
   - Investment: Tree allocation patterns

**Service Layer**:
- `AnalyticsService.getProgressionStats(userId)` → ProgressionStats
- `AnalyticsService.getSeasonComparison(userId, s1, s2)` → ComparisonData
- `AnalyticsService.predictNextTier(userId)` → Prediction

**Tests**:
- Stat calculation accuracy
- Multi-season aggregation
- Trend prediction logic
- Comparative math validation

---

### Step 4: Achievement System (200+ LOC, 15+ tests)
**Goal**: Milestone-based progression recognition

**Components**:
```dart
// Data Models
Achievement {
  achievementId: String,
  category: AchievementCategory,  // progression | milestone | skill | seasonal
  name: String,
  description: String,
  iconUrl: String,
  reward: RewardItem?,           // Optional badge/currency
}

enum AchievementCategory {
  progression,    // Tier milestones (reach Silver, Gold, etc)
  milestone,      // All trees maxed, 100% completion, etc
  skill,          // Allocate 20 points in one tree, etc
  seasonal,       // Win streak, perfect allocation, etc
}

PlayerAchievement {
  userId: String,
  achievementId: String,
  unlockedAt: DateTime,
  progress: AchievementProgress?,  // For progress-based achievements
}

AchievementProgress {
  current: int,     // Current progress
  target: int,      // Target (e.g., 100 for "allocate 100 points")
  percentage: int,  // 0-100
}
```

**Achievement Examples**:
- "Rising Star" - Reach Silver tier in first 5 seasons
- "Stat Master" - Allocate 50+ points in single tree
- "Balanced Fighter" - Allocate 15+ points in all 3 trees
- "Season Warrior" - Play 10+ seasons
- "Speedrunner" - Max out all trees in single season
- "Consistency" - Maintain Gold+ tier for 3 consecutive seasons
- "Collector" - Claim 10+ different rewards

**Service Layer**:
- `AchievementService.checkAchievements(userId)` → List<Achievement>
- `AchievementService.getProgress(userId, achievementId)` → AchievementProgress
- `AchievementService.unlockAchievement(userId, achievementId)` → void

**Tests**:
- Achievement unlock conditions
- Progress tracking & calculation
- Reward distribution
- Multi-achievement independence

---

### Step 5: UI Polish & Integration (200+ LOC, 12+ tests)
**Goal**: Seamless season transition flow

**Components**:
1. **Season End Ceremony**
   - Tier badge animation
   - Reward reveal sequence
   - Season stats summary

2. **Reward Claim Flow**
   - "Claim Your Rewards" button
   - Reward preview (before claiming)
   - Confirmation animation
   - Inventory update

3. **Reset Notification**
   - "New season starts in X days"
   - Carryover options preview
   - Reset confirmation dialog

4. **Analytics Integration**
   - Hook into existing Season Progress Screen
   - Add "History" tab with timeline
   - Add "Compare" mode for seasons

**Tests**:
- Navigation flow
- State transitions
- Error handling (claim failures, network)
- Animation timing

---

## Data Model Extensions

### User Model Addition
```dart
class User {
  // ... existing fields ...
  
  // Phase 9
  String? selectedMechaId;
  
  // Phase 10 additions
  List<SeasonalReward> claimedRewards;
  List<PlayerAchievement> achievements;
  Map<String, SeasonStats> seasonHistory;  // seasonId → stats
}
```

### Firestore Schema
```
users/
  {userId}/
    skillTree/                 # Phase 9
    selectedMechaId            # Phase 9
    claimedRewards/            # Phase 10 (subcollection)
      {rewardId}/
        claimedAt, expiresAt
    achievements/              # Phase 10 (subcollection)
      {achievementId}/
        unlockedAt, progress
    seasonHistory/             # Phase 10 (subcollection)
      {seasonId}/
        tier, eloProgression, rewards

seasons/                       # Phase 10 (new collection)
  {seasonId}/
    startDate, endDate
    rewards/                   # subcollection
      {tier}/
        list of rewards
    achievements/              # subcollection
      list of phase 10 achievements
```

---

## Implementation Strategy

### Tech Stack (Same as Phase 9)
- **State**: Riverpod StateNotifier<AsyncValue<T>>
- **Storage**: Firestore (primary) + SharedPrefs (cache)
- **Testing**: Mockito + FakeFirebaseFirestore
- **UI**: Flutter widgets + custom animations

### Parallel Development
```
Week 1:
  - Step 1: Seasonal Rewards (Service + Tests)
  - Step 2: Skill Tree Reset (Service + Tests)

Week 2:
  - Step 3: Analytics Dashboard (ViewModel + UI)
  - Step 4: Achievement System (Service + Tests)

Week 3:
  - Step 5: UI Integration & Polish
  - Testing & Bug Fixes
```

### Testing Strategy
- **Unit Tests**: 40+ for services & calculations
- **Widget Tests**: 15+ for UI components
- **Integration Tests**: 10+ for full flows
- **E2E Tests**: 5+ for season transitions
- **Total**: 70+ test cases

---

## Known Risks & Mitigation

| Risk | Impact | Mitigation |
|------|--------|-----------|
| Season sync issues | Data corruption | Firestore transactions, idempotent resets |
| Reward distribution bugs | Player trust loss | Comprehensive tests, admin audit trail |
| Analytics performance | Slow dashboard | Pagination, denormalized stats, caching |
| Achievement spam | Player fatigue | Meaningful achievements, balanced unlock rates |

---

## Success Criteria

✅ **Functionality**:
- All rewards distributed correctly by tier
- Season resets work without data loss
- Analytics dashboard loads < 2 seconds
- Achievements unlock without race conditions

✅ **Quality**:
- 70+ test cases with > 90% pass rate
- No Firebase errors in production
- Smooth animations (60 fps)

✅ **Performance**:
- Season transition < 5 minutes server-side
- Dashboard: < 2 second load time
- Reward claim: < 500ms response

✅ **UX**:
- Clear season end flow
- Intuitive reward claiming
- Meaningful achievement notifications

---

## Phase 10 Timeline

| Phase | Duration | Deliverables |
|-------|----------|--------------|
| Planning (Now) | 1 day | Requirements, data models |
| Implementation | 2 weeks | 5 steps, 1500+ LOC |
| Testing | 3-5 days | 70+ test cases |
| QA & Polish | 2-3 days | Performance, UX refinement |
| **Total** | **3-4 weeks** | **Production-ready** |

---

## Phase 10 Next Steps

1. ✅ **Requirements Finalized** (this doc)
2. ⏳ **Firestore Schema** → Create migration scripts
3. ⏳ **Step 1 Implementation** → SeasonRewardService
4. ⏳ **Parallel Development** → Steps 2-5
5. ⏳ **Testing & Deployment** → Full CI/CD validation

---

## Notes for Implementation

- Keep Phase 9 code clean (don't merge with Phase 10)
- Use separate branch: `claude/shinjuu-league-phase10-dev`
- Ensure backward compatibility with Phase 9 data
- Season transitions must be reversible (audit trail)
- All monetary rewards must be logged (Firestore + Analytics)

