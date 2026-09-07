import 'package:freezed_annotation/freezed_annotation.dart';

part 'achievement.freezed.dart';
part 'achievement.g.dart';

/// Achievement category for organization
enum AchievementCategory {
  progression,    // Tier milestones (reach Silver, Gold, etc)
  milestone,      // All trees maxed, 100% completion, etc
  skill,          // Allocate points in tree, etc
  seasonal,       // Win streak, perfect allocation, etc
  special,        // Limited-time, event-based achievements
}

/// Reward tier for achievement
enum AchievementRewardTier {
  bronze,   // 50 currency + 1 badge
  silver,   // 100 currency + 1 badge + cosmetic
  gold,     // 250 currency + 2 badges + cosmetic
  platinum, // 500 currency + 3 badges + cosmetics
}

/// Base achievement definition
@freezed
class Achievement with _$Achievement {
  const factory Achievement({
    required String achievementId,
    required AchievementCategory category,
    required String name,
    required String description,
    required String iconUrl,
    required AchievementRewardTier rewardTier,
    required int maxProgress,             // Max progress for progress-based
    bool isProgressBased = false,         // False = instant unlock, True = cumulative
    bool isHidden = false,                // Hidden until progress > 0
    DateTime? unlockedAfter,              // Time-gate (null = available now)
  }) = _Achievement;

  factory Achievement.fromJson(Map<String, dynamic> json) =>
      _$AchievementFromJson(json);

  /// Get reward currency amount for tier
  int getRewardCurrency() {
    switch (rewardTier) {
      case AchievementRewardTier.bronze:
        return 50;
      case AchievementRewardTier.silver:
        return 100;
      case AchievementRewardTier.gold:
        return 250;
      case AchievementRewardTier.platinum:
        return 500;
    }
  }

  /// Get reward badge count for tier
  int getRewardBadges() {
    switch (rewardTier) {
      case AchievementRewardTier.bronze:
        return 1;
      case AchievementRewardTier.silver:
        return 1;
      case AchievementRewardTier.gold:
        return 2;
      case AchievementRewardTier.platinum:
        return 3;
    }
  }

  /// Check if achievement can currently be pursued
  bool get isAvailable {
    if (unlockedAfter == null) return true;
    return DateTime.now().isAfter(unlockedAfter!);
  }
}

/// Player-specific achievement progress
@freezed
class PlayerAchievement with _$PlayerAchievement {
  const factory PlayerAchievement({
    required String userId,
    required String achievementId,
    required DateTime unlockedAt,
    AchievementProgress? progress,      // Null = instant unlock, Present = progress-based
    bool isHidden = false,               // Still hidden if 0% progress
  }) = _PlayerAchievement;

  factory PlayerAchievement.fromJson(Map<String, dynamic> json) =>
      _$PlayerAchievementFromJson(json);

  /// Check if achievement is fully unlocked
  bool get isUnlocked {
    if (progress == null) return true; // Instant unlock achievements
    return progress!.percentage >= 100;
  }

  /// Get progress percentage (0-100)
  int getProgressPercentage() {
    return progress?.percentage ?? 100;
  }
}

/// Progress tracking for cumulative achievements
@freezed
class AchievementProgress with _$AchievementProgress {
  const factory AchievementProgress({
    required int current,      // Current progress value
    required int target,       // Target/max value
  }) = _AchievementProgress;

  factory AchievementProgress.fromJson(Map<String, dynamic> json) =>
      _$AchievementProgressFromJson(json);

  /// Calculate progress percentage (0-100)
  int get percentage => ((current / target) * 100).toInt().clamp(0, 100);

  /// Check if complete
  bool get isComplete => current >= target;
}

/// Achievement unlock notification
@freezed
class AchievementUnlockEvent with _$AchievementUnlockEvent {
  const factory AchievementUnlockEvent({
    required String userId,
    required Achievement achievement,
    required DateTime unlockedAt,
    bool isNewUnlock = true,           // True if first time, False if already unlocked
  }) = _AchievementUnlockEvent;

  factory AchievementUnlockEvent.fromJson(Map<String, dynamic> json) =>
      _$AchievementUnlockEventFromJson(json);
}

/// Achievements catalog - pre-defined achievement templates
class AchievementsCatalog {
  // Progression achievements
  static const Achievement risingStar = Achievement(
    achievementId: 'rising_star',
    category: AchievementCategory.progression,
    name: '新星',
    description: '最初の5シーズンでシルバーティアに到達',
    iconUrl: 'assets/achievements/rising_star.png',
    rewardTier: AchievementRewardTier.bronze,
    maxProgress: 1,
    isProgressBased: false,
  );

  static const Achievement statMaster = Achievement(
    achievementId: 'stat_master',
    category: AchievementCategory.skill,
    name: 'ステータスマスター',
    description: '1つのツリーに50+ポイント配置',
    iconUrl: 'assets/achievements/stat_master.png',
    rewardTier: AchievementRewardTier.silver,
    maxProgress: 50,
    isProgressBased: true,
  );

  static const Achievement balancedFighter = Achievement(
    achievementId: 'balanced_fighter',
    category: AchievementCategory.skill,
    name: 'バランスの取れた戦士',
    description: 'すべての3つのツリーに15+ポイント配置',
    iconUrl: 'assets/achievements/balanced_fighter.png',
    rewardTier: AchievementRewardTier.silver,
    maxProgress: 15,
    isProgressBased: true,
  );

  static const Achievement seasonWarrior = Achievement(
    achievementId: 'season_warrior',
    category: AchievementCategory.milestone,
    name: 'シーズン戦士',
    description: '10+シーズンプレイ',
    iconUrl: 'assets/achievements/season_warrior.png',
    rewardTier: AchievementRewardTier.gold,
    maxProgress: 10,
    isProgressBased: true,
  );

  static const Achievement speedrunner = Achievement(
    achievementId: 'speedrunner',
    category: AchievementCategory.seasonal,
    name: 'スピードランナー',
    description: '1シーズンですべてのツリーをマックスアウト',
    iconUrl: 'assets/achievements/speedrunner.png',
    rewardTier: AchievementRewardTier.gold,
    maxProgress: 1,
    isProgressBased: false,
  );

  static const Achievement consistency = Achievement(
    achievementId: 'consistency',
    category: AchievementCategory.progression,
    name: '一貫性',
    description: '3シーズン連続でゴールド+ティアを維持',
    iconUrl: 'assets/achievements/consistency.png',
    rewardTier: AchievementRewardTier.platinum,
    maxProgress: 3,
    isProgressBased: true,
  );

  static const Achievement collector = Achievement(
    achievementId: 'collector',
    category: AchievementCategory.milestone,
    name: 'コレクター',
    description: '10+の異なる報酬を請求',
    iconUrl: 'assets/achievements/collector.png',
    rewardTier: AchievementRewardTier.gold,
    maxProgress: 10,
    isProgressBased: true,
  );

  /// All available achievements
  static const List<Achievement> all = [
    risingStar,
    statMaster,
    balancedFighter,
    seasonWarrior,
    speedrunner,
    consistency,
    collector,
  ];

  /// Get achievement by ID
  static Achievement? getById(String achievementId) {
    try {
      return all.firstWhere((a) => a.achievementId == achievementId);
    } catch (e) {
      return null;
    }
  }

  /// Get achievements by category
  static List<Achievement> getByCategory(AchievementCategory category) {
    return all.where((a) => a.category == category).toList();
  }
}
