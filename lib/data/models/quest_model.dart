import 'package:freezed_annotation/freezed_annotation.dart';

part 'quest_model.freezed.dart';
part 'quest_model.g.dart';

/// Quest frequency/recurrence
enum QuestFrequency {
  daily,      // Resets at midnight JST
  weekly,     // Resets Monday
  seasonal,   // Entire season (fixed dates)
  oneTime,    // One-time quest, never resets
}

/// Quest type for UI/UX categorization
enum QuestType {
  combat,       // Win X battles, deal X damage
  achievement,  // Unlock X achievements
  progression,  // Reach tier X, collect X cosmetics
  social,       // Invite friends, join guild
  daily,        // Generic daily challenges
}

/// Quest difficulty/priority
enum QuestDifficulty {
  easy,      // 1-5 min effort
  normal,    // 5-15 min effort
  hard,      // 15-30 min effort
  extreme,   // 30+ min effort
}

/// Condition types for quest progress
enum QuestConditionType {
  battleCount,      // Win X battles
  damageDealt,      // Deal X total damage
  killCount,        // Get X kills
  achievementUnlock, // Unlock X achievements
  tierReach,        // Reach tier X
  playtime,         // Play for X minutes
  consecutiveWins,  // Win X battles in a row
  levelUp,          // Reach level X
}

/// Quest condition definition
@freezed
class QuestCondition with _$QuestCondition {
  const factory QuestCondition({
    required QuestConditionType type,
    required int target,              // Goal value
    int current = 0,                  // Current progress
  }) = _QuestCondition;

  factory QuestCondition.fromJson(Map<String, dynamic> json) =>
      _$QuestConditionFromJson(json);

  /// Check if condition is met
  bool get isMet => current >= target;

  /// Progress percentage (0-100)
  int get progressPercentage => ((current / target) * 100).toInt().clamp(0, 100);
}

/// Quest reward definition
@freezed
class QuestReward with _$QuestReward {
  const factory QuestReward({
    required int currency,            // Gold/gems
    int experiencePoints = 0,         // XP for level progression
    int achievementBadges = 0,        // Cosmetic badges
    List<String> cosmetics = const [], // Cosmetic item IDs
  }) = _QuestReward;

  factory QuestReward.fromJson(Map<String, dynamic> json) =>
      _$QuestRewardFromJson(json);
}

/// Base quest definition
@freezed
class Quest with _$Quest {
  const factory Quest({
    required String questId,
    required String title,
    required String description,
    required QuestType type,
    required QuestFrequency frequency,
    required QuestDifficulty difficulty,
    required List<QuestCondition> conditions,  // All must be met
    required QuestReward reward,
    DateTime? availableFrom,          // When quest becomes available
    DateTime? availableUntil,         // Quest expiration
    int? displayOrder,                // For UI sorting (1, 2, 3...)
  }) = _Quest;

  factory Quest.fromJson(Map<String, dynamic> json) =>
      _$QuestFromJson(json);

  /// Check if quest can be started
  bool get isAvailable {
    final now = DateTime.now();
    if (availableFrom != null && now.isBefore(availableFrom!)) return false;
    if (availableUntil != null && now.isAfter(availableUntil!)) return false;
    return true;
  }

  /// Check if all conditions are met
  bool get isComplete => conditions.every((c) => c.isMet);

  /// Overall progress percentage (average of all conditions)
  int get progressPercentage {
    if (conditions.isEmpty) return 0;
    final total = conditions.fold<int>(0, (sum, c) => sum + c.progressPercentage);
    return (total / conditions.length).toInt();
  }
}

/// Player-specific quest progress
@freezed
class PlayerQuest with _$PlayerQuest {
  const factory PlayerQuest({
    required String userId,
    required String questId,
    required List<QuestCondition> conditions, // Current progress on each condition
    required bool isCompleted,
    required bool isRewarded,                 // Has player claimed reward?
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? claimedRewardAt,
  }) = _PlayerQuest;

  factory PlayerQuest.fromJson(Map<String, dynamic> json) =>
      _$PlayerQuestFromJson(json);

  /// Can player claim reward (completed but not yet claimed)?
  bool get canClaimReward => isCompleted && !isRewarded;

  /// Quest is active (started but not completed)
  bool get isActive => startedAt != null && !isCompleted;

  /// Time remaining for daily quest (24 hours from start)
  Duration? get timeRemaining {
    if (startedAt == null) return null;
    final expiresAt = startedAt!.add(const Duration(hours: 24));
    final remaining = expiresAt.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }
}

/// Quest category for organization (used in UI)
class QuestCatalog {
  // Daily quests
  static const Quest dailyWin = Quest(
    questId: 'daily_win_1',
    title: '勝利を掴む',
    description: 'バトルに3勝する',
    type: QuestType.combat,
    frequency: QuestFrequency.daily,
    difficulty: QuestDifficulty.normal,
    conditions: [
      QuestCondition(type: QuestConditionType.battleCount, target: 3),
    ],
    reward: QuestReward(currency: 100, experiencePoints: 50),
  );

  static const Quest dailyDamage = Quest(
    questId: 'daily_damage_1',
    title: 'ダメージマスター',
    description: 'バトル中に500ダメージ与える',
    type: QuestType.combat,
    frequency: QuestFrequency.daily,
    difficulty: QuestDifficulty.normal,
    conditions: [
      QuestCondition(type: QuestConditionType.damageDealt, target: 500),
    ],
    reward: QuestReward(currency: 100, experiencePoints: 50),
  );

  static const Quest dailyPlaytime = Quest(
    questId: 'daily_playtime_1',
    title: 'プレイマラソン',
    description: '15分間プレイする',
    type: QuestType.daily,
    frequency: QuestFrequency.daily,
    difficulty: QuestDifficulty.easy,
    conditions: [
      QuestCondition(type: QuestConditionType.playtime, target: 15),
    ],
    reward: QuestReward(currency: 50, experiencePoints: 25),
  );

  // Weekly quests
  static const Quest weeklyConsecutiveWins = Quest(
    questId: 'weekly_streak_1',
    title: '連勝記録',
    description: '5連勝する',
    type: QuestType.combat,
    frequency: QuestFrequency.weekly,
    difficulty: QuestDifficulty.hard,
    conditions: [
      QuestCondition(type: QuestConditionType.consecutiveWins, target: 5),
    ],
    reward: QuestReward(currency: 300, experiencePoints: 150, achievementBadges: 1),
  );

  static const Quest weeklyAchievements = Quest(
    questId: 'weekly_achieve_1',
    title: 'アチーバー',
    description: '5個の成果を解除する',
    type: QuestType.achievement,
    frequency: QuestFrequency.weekly,
    difficulty: QuestDifficulty.hard,
    conditions: [
      QuestCondition(type: QuestConditionType.achievementUnlock, target: 5),
    ],
    reward: QuestReward(currency: 250, experiencePoints: 100),
  );

  // All quests
  static const List<Quest> all = [
    dailyWin,
    dailyDamage,
    dailyPlaytime,
    weeklyConsecutiveWins,
    weeklyAchievements,
  ];

  /// Get quests by frequency
  static List<Quest> getByFrequency(QuestFrequency frequency) {
    return all.where((q) => q.frequency == frequency).toList();
  }

  /// Get quests by type
  static List<Quest> getByType(QuestType type) {
    return all.where((q) => q.type == type).toList();
  }

  /// Get quest by ID
  static Quest? getById(String questId) {
    try {
      return all.firstWhere((q) => q.questId == questId);
    } catch (e) {
      return null;
    }
  }
}
