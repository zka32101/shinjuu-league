import 'package:shinjuu_league/data/models/achievement.dart';
import 'package:shinjuu_league/services/achievement_service.dart';
import 'package:shinjuu_league/services/achievement_reward_service.dart';

/// Tier ordering for [tierAtLeast], shared by the rising_star/consistency
/// checks below and by BattleViewModel (which computes consistentSeasons
/// from season history using the same ordering). Mirrors the season-tier
/// names used throughout the ranking system (RankingService/SeasonService)
/// - a different, 5-tier scheme from the 4-tier Bronze/Silver/Gold/Platinum
/// used for Elo K-factor.
const seasonTierOrder = ['Bronze', 'Silver', 'Gold', 'Platinum', 'Diamond'];

/// True if [tier] is at or above [minTier] in season-tier ranking. An
/// unrecognized tier name is treated as below every real tier rather than
/// throwing, so a not-yet-initialized 'Bronze' default never crashes this.
bool tierAtLeast(String tier, String minTier) {
  final tierIndex = seasonTierOrder.indexOf(tier);
  final minIndex = seasonTierOrder.indexOf(minTier);
  if (tierIndex == -1 || minIndex == -1) return false;
  return tierIndex >= minIndex;
}

/// Detects when achievement unlock conditions are met during gameplay
/// Called after significant game events (kill, battle end, stat milestone)
class AchievementTriggerDetector {
  final AchievementService _achievementService;
  final AchievementRewardService _rewardService;

  AchievementTriggerDetector({
    required AchievementService achievementService,
    required AchievementRewardService rewardService,
  }) : _achievementService = achievementService,
       _rewardService = rewardService;

  /// Check all achievements for unlock after a kill event
  /// Returns newly unlocked achievements
  Future<List<Achievement>> checkKillTriggers(
    String userId,
    int kills,
    int totalKills,
  ) async {
    try {
      final unlockedList = <Achievement>[];

      // Aha Moment: First kill. Real bug fixed here: this used to check
      // `kills == 1` (exact match), so a player who got 2+ kills in their
      // very first battle would NEVER satisfy it and would never be
      // credited with the flagship "aha_moment_reached" KPI achievement
      // (CLAUDE.md: "初回で1キル達成 | Day7 リテンション"). `>= 1` is the
      // correct "got at least one kill" condition; _checkAndUnlock's own
      // already-unlocked check keeps this idempotent on later battles.
      if (kills >= 1) {
        final achieved = await _checkAndUnlock(userId, 'aha_moment');
        if (achieved != null) unlockedList.add(achieved);
      }

      return unlockedList;
    } catch (e) {
      return [];
    }
  }

  /// Check all achievements for unlock after battle completion
  /// Returns newly unlocked achievements
  Future<List<Achievement>> checkBattleCompletionTriggers(
    String userId, {
    required bool won,
    required int kills,
    required int deaths,
    required int assists,
    required int damageDealt,
    required int totalBattles,
    required int winCount,
    required int seasonsParticipated,
    required String currentTier,
  }) async {
    try {
      final unlockedList = <Achievement>[];

      // Speedrunner: Win in under 2 minutes (120 seconds)
      // Note: This requires battle duration tracking from BattleEngine
      // Temporarily disabled until duration is tracked
      // if (battleDurationSeconds < 120 && won) { ... }

      // Rising Star: reach Silver tier or better within the player's first
      // 5 seasons (matches its catalog description). Real bug fixed here:
      // this used to unlock on ANY single win regardless of tier or season
      // count, contradicting its own stated description entirely.
      if (seasonsParticipated <= 5 && tierAtLeast(currentTier, 'Silver')) {
        final achieved = await _checkAndUnlock(userId, 'rising_star');
        if (achieved != null) unlockedList.add(achieved);
      }

      return unlockedList;
    } catch (e) {
      return [];
    }
  }

  /// Check progression-based achievements for progress updates
  /// Returns achievements with updated progress
  Future<List<Achievement>> checkProgressTriggers(
    String userId, {
    required int statPoints,
    required int pathDiversity,
    required int seasonsParticipated,
    required int consistentSeasons,
    required String currentTier,
  }) async {
    try {
      final unlockedList = <Achievement>[];

      // Stat Master: maxed a single skill tree (progress-based). Reads the
      // threshold from the catalog rather than a hand-copied literal so it
      // can never drift from AchievementsCatalog.statMaster.maxProgress
      // again (it previously hard-coded 50, which the real skill tree
      // system's 5-tier-per-branch cap could never reach).
      if (statPoints >= AchievementsCatalog.statMaster.maxProgress) {
        final achieved = await _checkAndUnlock(userId, 'stat_master');
        if (achieved != null) unlockedList.add(achieved);
      }

      // Balanced Fighter: Points in all 3 trees (progress-based)
      if (pathDiversity >= 3) {
        final achieved = await _checkAndUnlock(userId, 'balanced_fighter');
        if (achieved != null) unlockedList.add(achieved);
      }

      return unlockedList;
    } catch (e) {
      return [];
    }
  }

  /// Check seasonal achievements based on tier changes
  Future<List<Achievement>> checkSeasonalTriggers(
    String userId, {
    required int seasonsParticipated,
    required int consistentSeasons,
    required String currentTier,
    required bool tierChanged,
  }) async {
    try {
      final unlockedList = <Achievement>[];

      // Season Warrior: Participated in 10 seasons
      if (seasonsParticipated >= 10) {
        final achieved = await _checkAndUnlock(userId, 'season_warrior');
        if (achieved != null) unlockedList.add(achieved);
      }

      // Consistency: 3+ consecutive seasons at Gold tier or better. Real
      // bug fixed here: `currentTier.toLowerCase() == 'gold'` required an
      // EXACT match, so a player who kept climbing to Platinum or Diamond
      // (still "Gold+" per the achievement's own description) would never
      // satisfy it.
      if (consistentSeasons >= 3 && tierAtLeast(currentTier, 'Gold')) {
        final achieved = await _checkAndUnlock(userId, 'consistency');
        if (achieved != null) unlockedList.add(achieved);
      }

      return unlockedList;
    } catch (e) {
      return [];
    }
  }

  /// Check special/unique event achievements
  Future<List<Achievement>> checkSpecialTriggers(
    String userId, {
    required bool isFirstBattle,
    required bool isPerfectWin,
    required bool hasKilledAllEnemies,
  }) async {
    try {
      final unlockedList = <Achievement>[];

      // Collector: First achievement unlock (meta-achievement)
      if (isFirstBattle) {
        // This is special - it unlocks when any other achievement unlocks
        // Implementation deferred to achievement_service
      }

      return unlockedList;
    } catch (e) {
      return [];
    }
  }

  /// Internal method to check and unlock a single achievement. Routes
  /// through AchievementRewardService.processUnlock() (currency/badges/
  /// cosmetics + markAchievementUnlocked()) instead of the bare
  /// AchievementService.unlockAchievement() this used to call - the latter
  /// wrote the unlock with no reward at all, an inconsistency with
  /// first_blood's own unlock path, which does grant rewards.
  Future<Achievement?> _checkAndUnlock(
    String userId,
    String achievementId,
  ) async {
    try {
      // Get achievement definition
      final achievement = AchievementsCatalog.getById(achievementId);
      if (achievement == null) return null;

      // Check if already unlocked
      final unlocked = await _achievementService.getUnlockedAchievements(
        userId,
      );
      if (unlocked.any((a) => a.achievementId == achievementId)) {
        return null; // Already unlocked
      }

      // Unlock the achievement and grant its rewards.
      await _rewardService.processUnlock(userId, achievement);

      return achievement;
    } catch (e) {
      return null;
    }
  }

  /// Batch check all relevant triggers for a battle completion
  Future<List<Achievement>> checkAllTriggersForBattle(
    String userId, {
    required int kills,
    required int totalKills,
    required bool won,
    required int deaths,
    required int assists,
    required int damageDealt,
    required int totalBattles,
    required int winCount,
    required int statPoints,
    required int pathDiversity,
    required int seasonsParticipated,
    required int consistentSeasons,
    required String currentTier,
  }) async {
    try {
      final allUnlocked = <Achievement>[];

      // Check kill triggers
      allUnlocked.addAll(await checkKillTriggers(userId, kills, totalKills));

      // Check battle completion triggers
      allUnlocked.addAll(
        await checkBattleCompletionTriggers(
          userId,
          won: won,
          kills: kills,
          deaths: deaths,
          assists: assists,
          damageDealt: damageDealt,
          totalBattles: totalBattles,
          winCount: winCount,
          seasonsParticipated: seasonsParticipated,
          currentTier: currentTier,
        ),
      );

      // Check progress triggers
      allUnlocked.addAll(
        await checkProgressTriggers(
          userId,
          statPoints: statPoints,
          pathDiversity: pathDiversity,
          seasonsParticipated: seasonsParticipated,
          consistentSeasons: consistentSeasons,
          currentTier: currentTier,
        ),
      );

      // Check seasonal triggers
      allUnlocked.addAll(
        await checkSeasonalTriggers(
          userId,
          seasonsParticipated: seasonsParticipated,
          consistentSeasons: consistentSeasons,
          currentTier: currentTier,
          tierChanged: false,
        ),
      );

      // Check special triggers
      allUnlocked.addAll(
        await checkSpecialTriggers(
          userId,
          isFirstBattle: totalBattles == 1,
          isPerfectWin: won && deaths == 0,
          hasKilledAllEnemies: kills >= 5,
        ),
      );

      return allUnlocked;
    } catch (e) {
      return [];
    }
  }

  /// Debug: Get trigger conditions for an achievement
  Map<String, dynamic> debugGetTriggerConditions(String achievementId) {
    switch (achievementId) {
      case 'aha_moment':
        return {
          'type': 'kill',
          'condition': 'First kill in battle',
          'trigger_value': 1,
          'trigger_type': 'first_event',
        };
      case 'rising_star':
        return {
          'type': 'seasonal',
          'condition': 'Reach Silver tier or better within the first 5 seasons',
          'trigger_value': 5,
          'trigger_type': 'season_and_tier',
        };
      case 'stat_master':
        return {
          'type': 'progress',
          'condition': 'Max out a single skill tree (5 tiers)',
          'trigger_value': AchievementsCatalog.statMaster.maxProgress,
          'trigger_type': 'threshold',
        };
      case 'balanced_fighter':
        return {
          'type': 'progress',
          'condition': 'Gain points in all 3 evolution trees',
          'trigger_value': 3,
          'trigger_type': 'diversity',
        };
      case 'season_warrior':
        return {
          'type': 'seasonal',
          'condition': 'Participate in 10 seasons',
          'trigger_value': 10,
          'trigger_type': 'cumulative',
        };
      case 'consistency':
        return {
          'type': 'seasonal',
          'condition': '3+ consecutive seasons at Gold tier',
          'trigger_value': 3,
          'trigger_type': 'consecutive',
        };
      case 'speedrunner':
        return {
          'type': 'battle_completion',
          'condition': 'Win a battle in under 2 minutes',
          'trigger_value': 120,
          'trigger_type': 'time_limit',
        };
      case 'collector':
        return {
          'type': 'special',
          'condition': 'First time unlocking any achievement',
          'trigger_value': 1,
          'trigger_type': 'meta',
        };
      default:
        return {
          'type': 'unknown',
          'condition': 'Unknown achievement',
          'trigger_value': null,
          'trigger_type': 'unknown',
        };
    }
  }
}
