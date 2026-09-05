import 'package:json_annotation/json_annotation.dart';

part 'achievement_model.g.dart';

/// 実績の種類
enum AchievementType {
  milestone, // マイルストーン（一度限り）
  progress, // 進捗型（カウント可能）
  challenge, // チャレンジ（期間限定）
}

/// 実績の難易度
enum AchievementDifficulty {
  easy,
  normal,
  hard,
  legendary,
}

/// 実績定義（ゲーム内で実装される実績テンプレート）
@JsonSerializable()
class Achievement {
  final String achievementId;
  final String name;
  final String description;
  final AchievementType type;
  final AchievementDifficulty difficulty;
  final int? targetCount; // progress型の場合のターゲット数
  final int rewardPoints; // 実績報酬ポイント
  final String? rewardIcon; // 実績アイコン絵文字またはパス

  Achievement({
    required this.achievementId,
    required this.name,
    required this.description,
    required this.type,
    required this.difficulty,
    this.targetCount,
    required this.rewardPoints,
    this.rewardIcon,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) =>
      _$AchievementFromJson(json);
  Map<String, dynamic> toJson() => _$AchievementToJson(this);

  Achievement copyWith({
    String? achievementId,
    String? name,
    String? description,
    AchievementType? type,
    AchievementDifficulty? difficulty,
    int? targetCount,
    int? rewardPoints,
    String? rewardIcon,
  }) {
    return Achievement(
      achievementId: achievementId ?? this.achievementId,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      difficulty: difficulty ?? this.difficulty,
      targetCount: targetCount ?? this.targetCount,
      rewardPoints: rewardPoints ?? this.rewardPoints,
      rewardIcon: rewardIcon ?? this.rewardIcon,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Achievement &&
          runtimeType == other.runtimeType &&
          achievementId == other.achievementId &&
          name == other.name &&
          description == other.description &&
          type == other.type &&
          difficulty == other.difficulty &&
          targetCount == other.targetCount &&
          rewardPoints == other.rewardPoints &&
          rewardIcon == other.rewardIcon;

  @override
  int get hashCode =>
      achievementId.hashCode ^
      name.hashCode ^
      description.hashCode ^
      type.hashCode ^
      difficulty.hashCode ^
      targetCount.hashCode ^
      rewardPoints.hashCode ^
      rewardIcon.hashCode;
}

/// ユーザーの実績進捗（進捗の記録）
@JsonSerializable()
class AchievementProgress {
  final String achievementId;
  final bool isUnlocked;
  final int currentProgress; // progress型: 現在のカウント
  final DateTime? unlockedAt;
  final DateTime lastUpdatedAt;

  AchievementProgress({
    required this.achievementId,
    required this.isUnlocked,
    this.currentProgress = 0,
    this.unlockedAt,
    required this.lastUpdatedAt,
  });

  factory AchievementProgress.fromJson(Map<String, dynamic> json) =>
      _$AchievementProgressFromJson(json);
  Map<String, dynamic> toJson() => _$AchievementProgressToJson(this);

  AchievementProgress copyWith({
    String? achievementId,
    bool? isUnlocked,
    int? currentProgress,
    DateTime? unlockedAt,
    DateTime? lastUpdatedAt,
  }) {
    return AchievementProgress(
      achievementId: achievementId ?? this.achievementId,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      currentProgress: currentProgress ?? this.currentProgress,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AchievementProgress &&
          runtimeType == other.runtimeType &&
          achievementId == other.achievementId &&
          isUnlocked == other.isUnlocked &&
          currentProgress == other.currentProgress &&
          unlockedAt == other.unlockedAt &&
          lastUpdatedAt == other.lastUpdatedAt;

  @override
  int get hashCode =>
      achievementId.hashCode ^
      isUnlocked.hashCode ^
      currentProgress.hashCode ^
      unlockedAt.hashCode ^
      lastUpdatedAt.hashCode;
}

/// 実績カタログ（ゲーム内で実装される15の実績）
class AchievementCatalog {
  static const List<Achievement> allAchievements = [
    // === チュートリアル ===
    Achievement(
      achievementId: 'tutorial_complete',
      name: 'チュートリアル完了',
      description: '初心者向けチュートリアルを完了した',
      type: AchievementType.milestone,
      difficulty: AchievementDifficulty.easy,
      rewardPoints: 10,
      rewardIcon: '🎓',
    ),

    // === 初期キル ===
    Achievement(
      achievementId: 'first_kill',
      name: '初キル！',
      description: '初めての敵撃破を達成した',
      type: AchievementType.milestone,
      difficulty: AchievementDifficulty.easy,
      rewardPoints: 25,
      rewardIcon: '⚔️',
    ),

    // === キル数 ===
    Achievement(
      achievementId: 'ten_kills',
      name: '連続キラー',
      description: '合計10体の敵を撃破した',
      type: AchievementType.progress,
      difficulty: AchievementDifficulty.normal,
      targetCount: 10,
      rewardPoints: 50,
      rewardIcon: '💀',
    ),

    // === キルストリーク ===
    Achievement(
      achievementId: 'kill_streak_3',
      name: 'キルストリーク：3',
      description: '1バトル中に3連続で敵を撃破した',
      type: AchievementType.milestone,
      difficulty: AchievementDifficulty.normal,
      rewardPoints: 40,
      rewardIcon: '🔥',
    ),

    // === ランク戦 ===
    Achievement(
      achievementId: 'first_ranked_match',
      name: 'ランク戦デビュー',
      description: '初めてランク戦に参加した',
      type: AchievementType.milestone,
      difficulty: AchievementDifficulty.normal,
      rewardPoints: 30,
      rewardIcon: '🏆',
    ),

    // === 連勝 ===
    Achievement(
      achievementId: 'win_streak_5',
      name: '連勝5',
      description: 'ランク戦で5連勝を達成した',
      type: AchievementType.progress,
      difficulty: AchievementDifficulty.hard,
      targetCount: 5,
      rewardPoints: 100,
      rewardIcon: '⭐',
    ),

    // === バトルパス ===
    Achievement(
      achievementId: 'first_battlepass',
      name: 'バトルパス購入',
      description: '初めてバトルパスを購入した',
      type: AchievementType.milestone,
      difficulty: AchievementDifficulty.easy,
      rewardPoints: 20,
      rewardIcon: '💳',
    ),

    // === スキン収集 ===
    Achievement(
      achievementId: 'skin_collector',
      name: 'スキンコレクター',
      description: '3体以上のスキンを所有した',
      type: AchievementType.progress,
      difficulty: AchievementDifficulty.hard,
      targetCount: 3,
      rewardPoints: 75,
      rewardIcon: '🎨',
    ),

    // === フレンド ===
    Achievement(
      achievementId: 'make_friends',
      name: 'フレンド作成',
      description: '初めてフレンドを追加した',
      type: AchievementType.milestone,
      difficulty: AchievementDifficulty.easy,
      rewardPoints: 15,
      rewardIcon: '👥',
    ),

    // === ギルド ===
    Achievement(
      achievementId: 'join_guild',
      name: 'ギルド加入',
      description: 'ギルドに加入した',
      type: AchievementType.milestone,
      difficulty: AchievementDifficulty.normal,
      rewardPoints: 25,
      rewardIcon: '🏰',
    ),

    // === レベル ===
    Achievement(
      achievementId: 'level_10',
      name: 'レベル10到達',
      description: 'ユーザーレベルが10に達した',
      type: AchievementType.milestone,
      difficulty: AchievementDifficulty.normal,
      rewardPoints: 60,
      rewardIcon: '📈',
    ),

    // === ウィンレート ===
    Achievement(
      achievementId: 'fifty_percent_winrate',
      name: '安定した勝利',
      description: '勝率50%以上を維持した',
      type: AchievementType.challenge,
      difficulty: AchievementDifficulty.hard,
      rewardPoints: 80,
      rewardIcon: '📊',
    ),

    // === 金ぴか ===
    Achievement(
      achievementId: 'legendary_skin',
      name: '伝説のスキン',
      description: 'レジェンドレアリティのスキンを入手した',
      type: AchievementType.milestone,
      difficulty: AchievementDifficulty.legendary,
      rewardPoints: 150,
      rewardIcon: '👑',
    ),

    // === グローバル ===
    Achievement(
      achievementId: 'thousand_points',
      name: '1000ポイント達成',
      description: '実績ポイントを1000獲得した',
      type: AchievementType.progress,
      difficulty: AchievementDifficulty.legendary,
      targetCount: 1000,
      rewardPoints: 200,
      rewardIcon: '✨',
    ),

    // === 秘密の実績 ===
    Achievement(
      achievementId: 'mystery_unlocked',
      name: 'ミステリー',
      description: '秘密の実績をアンロック',
      type: AchievementType.milestone,
      difficulty: AchievementDifficulty.legendary,
      rewardPoints: 300,
      rewardIcon: '❓',
    ),
  ];

  /// ID から実績定義を取得
  static Achievement? achievementById(String achievementId) {
    try {
      return allAchievements
          .firstWhere((a) => a.achievementId == achievementId);
    } catch (e) {
      return null;
    }
  }

  /// 難易度でフィルタ
  static List<Achievement> byDifficulty(AchievementDifficulty difficulty) {
    return allAchievements
        .where((a) => a.difficulty == difficulty)
        .toList();
  }

  /// 型でフィルタ
  static List<Achievement> byType(AchievementType type) {
    return allAchievements.where((a) => a.type == type).toList();
  }
}
