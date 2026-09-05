import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shinjuu_league/data/models/achievement_model.dart';
import 'firestore_service.dart';

/// 実績進捗の永続化とFirestore同期を担当する拡張Service
class AchievementPersistenceService {
  static final AchievementPersistenceService _instance =
      AchievementPersistenceService._internal();

  factory AchievementPersistenceService() => _instance;
  AchievementPersistenceService._internal();

  final FirestoreService _firestoreService = FirestoreService();
  late SharedPreferences _prefs;
  bool _initialized = false;

  /// 初期化（アプリ起動時に一度だけ呼び出し）
  Future<void> init() async {
    if (_initialized) return;

    try {
      _prefs = await SharedPreferences.getInstance();
      _initialized = true;

      if (kDebugMode) {
        debugPrint('AchievementPersistenceService initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error initializing AchievementPersistenceService: $e');
      }
    }
  }

  /// ユーザーの全実績進捗をFirestoreから読み込み（オンライン優先）
  /// Firestore読み込み失敗時はSharedPrefsにフォールバック
  Future<List<AchievementProgress>> loadAchievements(String userId) async {
    try {
      // Firestore から読み込み試行
      return await _loadFromFirestore(userId);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to load from Firestore, falling back to SharedPrefs: $e');
      }
      // フォールバック: SharedPrefs
      return _loadFromSharedPrefs(userId);
    }
  }

  /// Firestore から実績進捗を読み込み
  Future<List<AchievementProgress>> _loadFromFirestore(String userId) async {
    try {
      final doc = await _firestoreService.db
          .collection('users')
          .doc(userId)
          .collection('achievements')
          .get();

      final progresses = doc.docs
          .map((d) => AchievementProgress.fromJson(d.data()))
          .toList();

      // ローカルキャッシュに保存
      await _cacheAchievements(userId, progresses);

      if (kDebugMode) {
        debugPrint(
          'Loaded ${progresses.length} achievements from Firestore for user $userId',
        );
      }

      return progresses;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading from Firestore: $e');
      }
      rethrow;
    }
  }

  /// SharedPrefs からキャッシュされた実績進捗を読み込み
  List<AchievementProgress> _loadFromSharedPrefs(String userId) {
    try {
      final cached = _prefs.getStringList('achievements_$userId') ?? [];
      if (cached.isEmpty) {
        // キャッシュが無い場合は初期化
        return _initializeDefaultAchievements();
      }

      final progresses = cached
          .map((jsonString) {
            try {
              final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
              return AchievementProgress.fromJson(decoded);
            } catch (e) {
              if (kDebugMode) {
                debugPrint('Error decoding cached achievement JSON: $e');
              }
              return null;
            }
          })
          .whereType<AchievementProgress>()
          .toList();

      if (kDebugMode) {
        debugPrint(
          'Loaded ${progresses.length} achievements from SharedPrefs cache for user $userId',
        );
      }

      return progresses;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading from SharedPrefs: $e');
      }
      // 最後の手段: 初期状態を返す
      return _initializeDefaultAchievements();
    }
  }

  /// デフォルト実績リスト（すべてロック）を初期化
  List<AchievementProgress> _initializeDefaultAchievements() {
    final defaultProgresses = <AchievementProgress>[];

    for (final achievement in AchievementCatalog.allAchievements) {
      defaultProgresses.add(
        AchievementProgress(
          achievementId: achievement.achievementId,
          isUnlocked: false,
          currentProgress: 0,
          lastUpdatedAt: DateTime.now(),
        ),
      );
    }

    if (kDebugMode) {
      debugPrint(
        'Initialized ${defaultProgresses.length} default achievements',
      );
    }

    return defaultProgresses;
  }

  /// 実績進捗を更新し、アンロック条件をチェック
  /// 返り値: 新規アンロックされた実績ID列
  Future<List<String>> updateAchievementProgress(
    String userId,
    String achievementId,
    int newProgress,
  ) async {
    try {
      // Firestore に更新
      await _firestoreService.db
          .collection('users')
          .doc(userId)
          .collection('achievements')
          .doc(achievementId)
          .update({
        'currentProgress': newProgress,
        'lastUpdatedAt': DateTime.now().toIso8601String(),
      });

      // ローカルキャッシュ更新
      final achievement = AchievementCatalog.achievementById(achievementId);
      if (achievement != null && _shouldUnlock(achievement, newProgress)) {
        // アンロック
        await _firestoreService.db
            .collection('users')
            .doc(userId)
            .collection('achievements')
            .doc(achievementId)
            .update({
          'isUnlocked': true,
          'unlockedAt': DateTime.now().toIso8601String(),
        });

        if (kDebugMode) {
          debugPrint('Achievement unlocked: $achievementId for user $userId');
        }

        return [achievementId];
      }

      return [];
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error updating achievement progress: $e');
      }
      return [];
    }
  }

  /// アンロック条件を確認
  bool _shouldUnlock(Achievement achievement, int currentProgress) {
    if (achievement.type == AchievementType.milestone) {
      // Milestone は 1回達成でアンロック
      return currentProgress >= 1;
    } else if (achievement.type == AchievementType.progress) {
      // Progress 型は targetCount に達したらアンロック
      return achievement.targetCount != null &&
          currentProgress >= achievement.targetCount!;
    }
    // Challenge 型は別途条件（期間限定など）
    return false;
  }

  /// ローカルキャッシュに実績進捗を保存
  Future<void> _cacheAchievements(
    String userId,
    List<AchievementProgress> progresses,
  ) async {
    try {
      // すべての実績進捗をJSON文字列としてキャッシュ
      final jsonStrings = progresses
          .map((p) => jsonEncode(p.toJson()))
          .toList();

      await _prefs.setStringList('achievements_$userId', jsonStrings);

      if (kDebugMode) {
        debugPrint('Cached ${progresses.length} achievements for user $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error caching achievements: $e');
      }
    }
  }

  /// 定期的な同期タスク（30秒ごと）
  /// バックグラウンドで Firestore と SharedPrefs を同期
  Future<void> syncToFirestore(String userId) async {
    try {
      // Firestore から最新データを取得
      final latestProgresses = await _loadFromFirestore(userId);

      if (kDebugMode) {
        debugPrint('Synced ${latestProgresses.length} achievements to Firestore');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Sync to Firestore failed (will retry): $e');
      }
      // 次のリトライまで待機
      // 呼び出し側で Timer.periodic で定期呼び出し
    }
  }

  /// ユーザーの実績統計を計算
  Future<AchievementStats> getAchievementStats(String userId) async {
    try {
      final progresses = await loadAchievements(userId);

      final unlockedCount = progresses.where((p) => p.isUnlocked).length;
      final totalCount = progresses.length;
      final totalPoints = progresses
          .where((p) => p.isUnlocked)
          .map((p) {
            final def = AchievementCatalog.achievementById(p.achievementId);
            return def?.rewardPoints ?? 0;
          })
          .fold<int>(0, (a, b) => a + b);

      return AchievementStats(
        totalUnlocked: unlockedCount,
        totalCount: totalCount,
        completionPercentage: totalCount > 0 ? (unlockedCount / totalCount) * 100 : 0,
        totalPoints: totalPoints,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting achievement stats: $e');
      }
      return AchievementStats(
        totalUnlocked: 0,
        totalCount: AchievementCatalog.allAchievements.length,
        completionPercentage: 0,
        totalPoints: 0,
      );
    }
  }

  /// デバッグ用: 実績情報をダンプ
  Future<Map<String, dynamic>> debugDumpAchievements(String userId) async {
    try {
      final progresses = await loadAchievements(userId);
      final stats = await getAchievementStats(userId);

      return {
        'user_id': userId,
        'total_unlocked': stats.totalUnlocked,
        'total_count': stats.totalCount,
        'completion_percent': stats.completionPercentage.toStringAsFixed(1),
        'total_points': stats.totalPoints,
        'achievements': progresses
            .map((p) => {
                  'id': p.achievementId,
                  'unlocked': p.unlocked,
                  'progress': p.currentProgress,
                  'unlocked_at': p.unlockedAt?.toIso8601String(),
                })
            .toList(),
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}

/// 実績統計データ
class AchievementStats {
  final int totalUnlocked;
  final int totalCount;
  final double completionPercentage;
  final int totalPoints;

  AchievementStats({
    required this.totalUnlocked,
    required this.totalCount,
    required this.completionPercentage,
    required this.totalPoints,
  });

  bool get isComplete => completionPercentage >= 100;

  @override
  String toString() {
    return 'AchievementStats(unlocked: $totalUnlocked/$totalCount, '
        'completion: ${completionPercentage.toStringAsFixed(1)}%, points: $totalPoints)';
  }
}

// 拡張property
extension on AchievementProgress {
  bool get unlocked => isUnlocked;
}
