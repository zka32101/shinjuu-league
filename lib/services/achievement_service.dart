import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:shinjuu_league/data/models/achievement.dart';
import 'package:shinjuu_league/data/models/progression_stats.dart';
import 'package:shinjuu_league/services/firestore_service.dart';

/// Service for managing player achievements
class AchievementService {
  final FirestoreService _firestoreService;

  AchievementService(this._firestoreService);

  /// Check and update achievements for a player
  Future<List<AchievementUnlockEvent>> checkAchievements(
    String userId,
    ProgressionStats progressionStats,
  ) async {
    final unlockEvents = <AchievementUnlockEvent>[];
    final playerAchievements = await getPlayerAchievements(userId);
    final unlockedIds = playerAchievements
        .where((a) => a.isUnlocked)
        .map((a) => a.achievementId)
        .toSet();

    for (final achievement in AchievementsCatalog.all) {
      if (!achievement.isAvailable) continue;

      final checkResult = _checkAchievementCondition(
        achievement,
        progressionStats,
      );

      if (checkResult.isMetOrProgressed) {
        var playerAch = playerAchievements
            .cast<PlayerAchievement?>()
            .firstWhere(
              (a) => a?.achievementId == achievement.achievementId,
              orElse: () => null,
            );

        if (playerAch == null) {
          playerAch = PlayerAchievement(
            userId: userId,
            achievementId: achievement.achievementId,
            unlockedAt: DateTime.now(),
            progress: achievement.isProgressBased
                ? AchievementProgress(
                    current: checkResult.progressValue,
                    target: achievement.maxProgress,
                  )
                : null,
            isHidden:
                !achievement.isProgressBased && checkResult.progressValue == 0,
          );
        } else if (achievement.isProgressBased) {
          playerAch = playerAch.copyWith(
            progress: AchievementProgress(
              current: checkResult.progressValue,
              target: achievement.maxProgress,
            ),
          );
        }

        await _firestoreService.set(
          'users/$userId/achievements/${achievement.achievementId}',
          playerAch,
        );

        if (!unlockedIds.contains(achievement.achievementId) &&
            playerAch.isUnlocked) {
          unlockEvents.add(
            AchievementUnlockEvent(
              userId: userId,
              achievement: achievement,
              unlockedAt: DateTime.now(),
              isNewUnlock: true,
            ),
          );
        }
      }
    }

    return unlockEvents;
  }

  /// Get all player achievements.
  ///
  /// Real bug fixed here: this used to do
  /// `docs.map((doc) => PlayerAchievement.fromJson(doc))`, which THROWS
  /// for every doc actually written by FirestoreService.markAchievementUnlocked()
  /// (the shape every real unlock path - AchievementRewardService.processUnlock(),
  /// used by both the kill-detection and battle-trigger-detection systems -
  /// writes: {achievementId, name?, unlockedAt: Timestamp, isHidden}).
  /// PlayerAchievement.fromJson() requires a `userId` key (absent from that
  /// shape) and parses `unlockedAt` with `DateTime.parse()` (which cannot
  /// handle a Firestore Timestamp). Any real player with even one unlocked
  /// achievement would crash this method the instant it was called - which
  /// is exactly why nothing had ever successfully built an achievements
  /// list screen against it.
  Future<List<PlayerAchievement>> getPlayerAchievements(String userId) async {
    final docs = await _firestoreService.getCollection(
      'users/$userId/achievements',
    );
    return docs
        .map((doc) {
          final achievementId = doc['achievementId'] as String?;
          if (achievementId == null) return null;
          return PlayerAchievement(
            userId: userId,
            achievementId: achievementId,
            unlockedAt: _parseUnlockedAt(doc['unlockedAt']),
            // Every doc in this collection represents a genuine unlock (see
            // markAchievementUnlocked's callers) - progress is never
            // persisted here, so PlayerAchievement.isUnlocked (progress ==
            // null) is always correctly true for anything this returns.
            progress: null,
            isHidden: doc['isHidden'] as bool? ?? false,
          );
        })
        .whereType<PlayerAchievement>()
        .toList();
  }

  /// Parses the `unlockedAt` value written by markAchievementUnlocked,
  /// which is a Firestore Timestamp once the server resolves
  /// FieldValue.serverTimestamp() (or, briefly right after a local write
  /// before the server round-trip completes, null).
  DateTime _parseUnlockedAt(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  /// Get specific achievement progress. Always null: a document only ever
  /// exists here once an achievement is genuinely unlocked (see
  /// getPlayerAchievements's doc comment), and progress toward a
  /// not-yet-unlocked achievement is computed transiently from live game
  /// state (skill tree, season history) rather than persisted anywhere.
  Future<AchievementProgress?> getProgress(
    String userId,
    String achievementId,
  ) async => null;

  /// Manually unlock achievement (no reward granted - callers that should
  /// also grant currency/badges/cosmetics use AchievementRewardService.processUnlock
  /// instead, which calls this same underlying write). Delegates to
  /// FirestoreService.markAchievementUnlocked() so every unlock in the app
  /// writes the same document shape - this used to independently write a
  /// full PlayerAchievement.toJson() (including a userId field and an
  /// ISO-string unlockedAt), a different, incompatible shape that
  /// getPlayerAchievements() could not parse.
  Future<void> unlockAchievement(String userId, String achievementId) async {
    final achievement = AchievementsCatalog.getById(achievementId);
    if (achievement == null)
      throw Exception('Achievement not found: $achievementId');

    await _firestoreService.markAchievementUnlocked(
      userId,
      achievementId,
      achievementName: achievement.name,
    );
  }

  /// Get unlocked achievements only
  Future<List<PlayerAchievement>> getUnlockedAchievements(String userId) async {
    final all = await getPlayerAchievements(userId);
    return all.where((a) => a.isUnlocked).toList();
  }

  /// Get achievements by category
  Future<List<PlayerAchievement>> getAchievementsByCategory(
    String userId,
    AchievementCategory category,
  ) async {
    final all = await getPlayerAchievements(userId);
    return all.where((a) {
      final achievement = AchievementsCatalog.getById(a.achievementId);
      return achievement?.category == category;
    }).toList();
  }

  /// Get achievement unlock count
  Future<int> getUnlockCount(String userId) async {
    final unlocked = await getUnlockedAchievements(userId);
    return unlocked.length;
  }

  /// Get total achievement count
  int getTotalAvailableCount() {
    return AchievementsCatalog.all.where((a) => a.isAvailable).length;
  }

  /// Get completion percentage
  Future<double> getCompletionPercentage(String userId) async {
    final total = getTotalAvailableCount();
    if (total == 0) return 0.0;
    final unlocked = await getUnlockCount(userId);
    return (unlocked / total) * 100;
  }

  /// Check individual achievement condition
  _AchievementCheckResult _checkAchievementCondition(
    Achievement achievement,
    ProgressionStats stats,
  ) {
    switch (achievement.achievementId) {
      case 'rising_star':
        final isMet =
            stats.allTimeStats.totalSeasonsPlayed <= 5 &&
            stats.currentSeason?.finalTier != 'Bronze';
        return _AchievementCheckResult(
          isMetOrProgressed: isMet,
          progressValue: isMet ? 1 : 0,
        );

      case 'stat_master':
        final maxPointsInTree = stats.currentSeason?.pointsAllocated ?? 0;
        return _AchievementCheckResult(
          isMetOrProgressed: maxPointsInTree > 0,
          progressValue: maxPointsInTree,
        );

      case 'balanced_fighter':
        final pointsAllocated = stats.currentSeason?.pointsAllocated ?? 0;
        return _AchievementCheckResult(
          isMetOrProgressed: pointsAllocated >= 15,
          progressValue: pointsAllocated,
        );

      case 'season_warrior':
        final seasonsPlayed = stats.allTimeStats.totalSeasonsPlayed;
        return _AchievementCheckResult(
          isMetOrProgressed: seasonsPlayed > 0,
          progressValue: seasonsPlayed,
        );

      case 'speedrunner':
        final pointsAllocated = stats.currentSeason?.pointsAllocated ?? 0;
        return _AchievementCheckResult(
          isMetOrProgressed: pointsAllocated >= 15,
          progressValue: pointsAllocated >= 15 ? 1 : 0,
        );

      case 'consistency':
        final goldOrBetterTiers = ['Gold', 'Platinum', 'Diamond'];
        var streak = 0;
        for (final season in stats.allSeasons) {
          if (goldOrBetterTiers.contains(season.finalTier)) {
            streak++;
          } else {
            streak = 0;
          }
        }
        return _AchievementCheckResult(
          isMetOrProgressed: streak > 0,
          progressValue: streak,
        );

      case 'collector':
        return _AchievementCheckResult(
          isMetOrProgressed: false,
          progressValue: 0,
        );

      default:
        return _AchievementCheckResult(
          isMetOrProgressed: false,
          progressValue: 0,
        );
    }
  }
}

class _AchievementCheckResult {
  final bool isMetOrProgressed;
  final int progressValue;
  _AchievementCheckResult({
    required this.isMetOrProgressed,
    required this.progressValue,
  });
}
