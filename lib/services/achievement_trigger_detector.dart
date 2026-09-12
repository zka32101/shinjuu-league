import 'package:shinjuu_league/data/models/achievement.dart';
import 'package:shinjuu_league/services/achievement_service.dart';

/// Detects when achievement unlock conditions are met during gameplay
/// Called after significant game events (kill, battle end, stat milestone)
class AchievementTriggerDetector {
  final AchievementService _achievementService;

  AchievementTriggerDetector({
    required AchievementService achievementService,
  }) : _achievementService = achievementService;

  /// Check all achievements for unlock after a kill event
  /// Returns newly unlocked achievements
  Future<List<Achievement>> checkKillTriggers(
    String userId,
    int kills,
    int totalKills,
  ) async {
    try {
      final unlockedList = <Achievement>[];

      // Aha Moment: First kill
      if (kills == 1) {
        final achieved = await _checkAndUnlock(
          userId,
          'aha_moment',
        );
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
  }) async {
    try {
      final unlockedList = <Achievement>[];

      // Speedrunner: Win in under 2 minutes (120 seconds)
      // Note: This requires battle duration tracking from BattleEngine
      // Temporarily disabled until duration is tracked
      // if (battleDurationSeconds < 120 && won) { ... }

      // Rising Star: Win a battle (proxy for reaching Silver tier)
      if (won) {
        final achieved = await _checkAndUnlock(
          userId,
          'rising_star',
        );
        if (achieved != null) unlockedList.add(achieved);
      }

      return unlockedList;
    } catch (e) {
      return [];
    }
  }

  /// Check progression-based achievements for progress updates
  /// Returns achievements with updated progress
  Future<List<PlayerAchievement>> checkProgressTriggers(
    String userId, {
    required int statPoints,
    required int pathDiversity,
    required int seasonsParticipated,
    required int consistentSeasons,
    required String currentTier,
  }) async {
    try {
      final progressList = <PlayerAchievement>[];

      // Stat Master: 50+ points (progress-based)
      final statProgress = await _achievementService.getProgress(
        userId,
        'stat_master',
      );
      if (statProgress != null && !statProgress.isUnlocked) {
        if (statPoints >= 50) {
          final updated = await _checkAndUnlock(
            userId,
            'stat_master',
          );
          if (updated != null) progressList.add(statProgress.copyWith(isUnlocked: true));
        }
      }

      // Balanced Fighter: Points in all 3 trees (progress-based)
      final balancedProgress = await _achievementService.getProgress(
        userId,
        'balanced_fighter',
      );
      if (balancedProgress != null && !balancedProgress.isUnlocked) {
        if (pathDiversity >= 3) {
          final updated = await _checkAndUnlock(
            userId,
            'balanced_fighter',
          );
          if (updated != null) progressList.add(balancedProgress.copyWith(isUnlocked: true));
        }
      }

      return progressList;
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
        final achieved = await _checkAndUnlock(
          userId,
          'season_warrior',
        );
        if (achieved != null) unlockedList.add(achieved);
      }

      // Consistency: 3+ consecutive seasons at Gold tier
      if (consistentSeasons >= 3 && currentTier.toLowerCase() == 'gold') {
        final achieved = await _checkAndUnlock(
          userId,
          'consistency',
        );
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

  /// Internal method to check and unlock a single achievement
  Future<Achievement?> _checkAndUnlock(
    String userId,
    String achievementId,
  ) async {
    try {
      // Get achievement definition
      final achievement = AchievementsCatalog.getById(achievementId);
      if (achievement == null) return null;

      // Check if already unlocked
      final current = await _achievementService.getProgress(
        userId,
        achievementId,
      );
      if (current?.isUnlocked ?? false) {
        return null; // Already unlocked
      }

      // Unlock the achievement
      await _achievementService.unlockAchievement(userId, achievementId);

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
      allUnlocked.addAll(
        await checkKillTriggers(userId, kills, totalKills),
      );

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
        ),
      );

      // Check progress triggers
      await checkProgressTriggers(
        userId,
        statPoints: statPoints,
        pathDiversity: pathDiversity,
        seasonsParticipated: seasonsParticipated,
        consistentSeasons: consistentSeasons,
        currentTier: currentTier,
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
          'type': 'battle_completion',
          'condition': 'Win any battle',
          'trigger_value': true,
          'trigger_type': 'win_condition',
        };
      case 'stat_master':
        return {
          'type': 'progress',
          'condition': 'Accumulate 50+ stat points',
          'trigger_value': 50,
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
