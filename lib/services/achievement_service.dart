import 'package:flutter/foundation.dart';

/// 実績（Achievement）システム
/// 15の実績を管理、アンロック条件を追跡
class AchievementService {
  static final AchievementService _instance =
      AchievementService._internal();

  factory AchievementService() => _instance;
  AchievementService._internal();

  /// ユーザーがアンロック済みの実績
  final Set<String> _unlockedAchievements = {};

  /// 実績の進捗（例: killCount = 3 / 10）
  final Map<String, int> _progressMap = {};

  /// アンロック済みの実績一覧を取得
  Set<String> get unlockedAchievements => Set.unmodifiable(_unlockedAchievements);

  /// 初期化
  Future<void> init() async {
    try {
      // TODO: SharedPrefs / Firestore から既存のアンロック実績を読み込み
      // for now, 空で開始
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AchievementService.init error: $e');
      }
    }
  }

  /// 進捗を更新してアンロック条件を確認
  /// 返り値: 新たにアンロックされた実績の ID リスト
  List<String> updateProgress(AchievementProgressEvent event) {
    final newlyUnlocked = <String>[];

    switch (event.type) {
      case AchievementEventType.tutorialComplete:
        _progressMap['tutorial_complete'] = 1;
        if (_checkUnlock('tutorial_complete')) {
          newlyUnlocked.add('tutorial_complete');
        }

      case AchievementEventType.firstKill:
        _progressMap['first_kill'] = 1;
        if (_checkUnlock('first_kill')) {
          newlyUnlocked.add('first_kill');
        }

      case AchievementEventType.killCountIncrement:
        final current = _progressMap['total_kills'] ?? 0;
        _progressMap['total_kills'] = current + 1;

        if (_checkUnlock('ten_kills') && !_unlockedAchievements.contains('ten_kills')) {
          newlyUnlocked.add('ten_kills');
        }

      case AchievementEventType.killStreakIncrement:
        final streak = event.data['streak'] as int? ?? 1;
        _progressMap['kill_streak'] = streak;

        if (streak >= 3 && _checkUnlock('kill_streak_3')) {
          newlyUnlocked.add('kill_streak_3');
        }

      case AchievementEventType.battleCompleted:
        // パラメータで勝敗・ランク戦か確認
        final isRanked = event.data['is_ranked'] as bool? ?? false;
        final isWin = event.data['is_win'] as bool? ?? false;

        if (isRanked && !_unlockedAchievements.contains('first_ranked_match')) {
          newlyUnlocked.add('first_ranked_match');
        }

        if (isWin) {
          final currentWins = _progressMap['ranked_wins'] ?? 0;
          _progressMap['ranked_wins'] = currentWins + 1;

          if (currentWins + 1 >= 5 && _checkUnlock('win_streak_5')) {
            newlyUnlocked.add('win_streak_5');
          }
        }

      case AchievementEventType.battlePassPurchased:
        if (_checkUnlock('first_battlepass')) {
          newlyUnlocked.add('first_battlepass');
        }

      case AchievementEventType.skinPurchased:
        final ownedSkinCount = (event.data['owned_skins'] as int?) ?? 0;
        _progressMap['owned_skins'] = ownedSkinCount;

        if (ownedSkinCount >= 3 && _checkUnlock('skin_collector')) {
          newlyUnlocked.add('skin_collector');
        }

      case AchievementEventType.friendAdded:
        final friendCount = (event.data['friend_count'] as int?) ?? 0;
        _progressMap['friend_count'] = friendCount;

        if (friendCount >= 3 && _checkUnlock('social_butterfly')) {
          newlyUnlocked.add('social_butterfly');
        }

      case AchievementEventType.guildCreated:
        if (_checkUnlock('guild_founder')) {
          newlyUnlocked.add('guild_founder');
        }

      case AchievementEventType.levelUp:
        final level = event.data['level'] as int? ?? 1;
        _progressMap['player_level'] = level;

        if (level >= 10 && _checkUnlock('level_10')) {
          newlyUnlocked.add('level_10');
        }
    }

    // 新規アンロック実績をセットに追加
    for (final id in newlyUnlocked) {
      _unlockedAchievements.add(id);
    }

    if (newlyUnlocked.isNotEmpty && kDebugMode) {
      debugPrint('Achievements unlocked: $newlyUnlocked');
    }

    return newlyUnlocked;
  }

  /// アンロック条件を確認
  bool _checkUnlock(String achievementId) {
    if (_unlockedAchievements.contains(achievementId)) {
      return false; // 既にアンロック済み
    }

    final progress = _progressMap[achievementId] ?? 0;

    switch (achievementId) {
      case 'tutorial_complete':
        return progress >= 1;
      case 'first_kill':
        return progress >= 1;
      case 'ten_kills':
        return (_progressMap['total_kills'] ?? 0) >= 10;
      case 'kill_streak_3':
        return (_progressMap['kill_streak'] ?? 0) >= 3;
      case 'first_ranked_match':
        return progress >= 1;
      case 'level_10':
        return (_progressMap['player_level'] ?? 0) >= 10;
      case 'win_streak_5':
        return (_progressMap['ranked_wins'] ?? 0) >= 5;
      case 'first_battlepass':
        return progress >= 1;
      case 'skin_collector':
        return (_progressMap['owned_skins'] ?? 0) >= 3;
      case 'social_butterfly':
        return (_progressMap['friend_count'] ?? 0) >= 3;
      case 'guild_founder':
        return progress >= 1;
      default:
        return false;
    }
  }

  /// 特定の実績の進捗を取得
  int getProgress(String achievementId) => _progressMap[achievementId] ?? 0;

  /// 実績の詳細情報を取得
  Achievement? getAchievementDetails(String id) {
    return _achievementCatalog[id];
  }

  /// すべての実績を取得
  List<Achievement> getAllAchievements() {
    return _achievementCatalog.values.toList();
  }

  /// デバッグ用: 実績状態をダンプ
  Map<String, dynamic> debugDumpAchievements() {
    return {
      'unlocked_count': _unlockedAchievements.length,
      'total_count': _achievementCatalog.length,
      'unlocked_list': _unlockedAchievements.toList(),
      'progress': Map.from(_progressMap),
    };
  }

  /// デバッグ用: 実績を強制アンロック
  void debugUnlockAchievement(String id) {
    _unlockedAchievements.add(id);
    if (kDebugMode) {
      debugPrint('Debug: Unlocked achievement $id');
    }
  }
}

/// 実績オブジェクト
class Achievement {
  final String id;
  final String name;
  final String description;
  final AchievementRarity rarity;
  final String icon; // emoji または asset path
  final int? progressTarget; // null = binary (unlocked or not)

  Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.rarity,
    required this.icon,
    this.progressTarget,
  });
}

enum AchievementRarity {
  common('一般'),
  rare('レア'),
  legendary('伝説');

  const AchievementRarity(this.label);
  final String label;
}

/// 実績進捗イベント
class AchievementProgressEvent {
  final AchievementEventType type;
  final Map<String, dynamic> data;

  AchievementProgressEvent({
    required this.type,
    this.data = const {},
  });
}

enum AchievementEventType {
  tutorialComplete,
  firstKill,
  killCountIncrement,
  killStreakIncrement,
  battleCompleted,
  battlePassPurchased,
  skinPurchased,
  friendAdded,
  guildCreated,
  levelUp,
}

/// 実績カタログ（静的マスタデータ）
final _achievementCatalog = {
  'tutorial_complete': Achievement(
    id: 'tutorial_complete',
    name: 'チュートリアル完了',
    description: '初回チュートリアルを完了した',
    rarity: AchievementRarity.common,
    icon: '🎯',
  ),
  'first_kill': Achievement(
    id: 'first_kill',
    name: '初陣での初キル',
    description: '初めてのバトルで敵を撃破した',
    rarity: AchievementRarity.common,
    icon: '⚔️',
  ),
  'ten_kills': Achievement(
    id: 'ten_kills',
    name: '10キル達成',
    description: '通算 10 体の敵を撃破した',
    rarity: AchievementRarity.rare,
    icon: '💥',
    progressTarget: 10,
  ),
  'kill_streak_3': Achievement(
    id: 'kill_streak_3',
    name: 'トリプルキル',
    description: '1 試合中に連続 3 キルを達成した',
    rarity: AchievementRarity.rare,
    icon: '🔥',
  ),
  'first_ranked_match': Achievement(
    id: 'first_ranked_match',
    name: 'ランク戦デビュー',
    description: 'ランク戦に初参加した',
    rarity: AchievementRarity.common,
    icon: '🏆',
  ),
  'level_10': Achievement(
    id: 'level_10',
    name: 'レベル 10 到達',
    description: 'プレイヤーレベルが 10 に到達した',
    rarity: AchievementRarity.rare,
    icon: '⬆️',
    progressTarget: 10,
  ),
  'win_streak_5': Achievement(
    id: 'win_streak_5',
    name: '5 連勝',
    description: 'ランク戦で 5 連勝を達成した',
    rarity: AchievementRarity.legendary,
    icon: '👑',
  ),
  'first_battlepass': Achievement(
    id: 'first_battlepass',
    name: 'バトルパス購入',
    description: '初めてバトルパスを購入した',
    rarity: AchievementRarity.common,
    icon: '💎',
  ),
  'skin_collector': Achievement(
    id: 'skin_collector',
    name: 'スキンコレクター',
    description: '3 種類以上のスキンを所有した',
    rarity: AchievementRarity.rare,
    icon: '👕',
    progressTarget: 3,
  ),
  'social_butterfly': Achievement(
    id: 'social_butterfly',
    name: '交友関係',
    description: 'フレンドを 3 人以上追加した',
    rarity: AchievementRarity.common,
    icon: '🦋',
    progressTarget: 3,
  ),
  'guild_founder': Achievement(
    id: 'guild_founder',
    name: 'ギルド創設者',
    description: 'ギルドを創設した',
    rarity: AchievementRarity.rare,
    icon: '🏢',
  ),
};
