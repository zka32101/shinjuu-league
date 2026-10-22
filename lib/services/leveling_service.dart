import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shinjuu_league/services/firestore_service.dart';

/// 経験値付与の結果。レベルアップが発生したかをUI側が判定できるようにする。
class LevelUpResult {
  final int newLevel;
  final int newExperience;
  final int levelsGained;

  bool get leveledUp => levelsGained > 0;

  LevelUpResult({
    required this.newLevel,
    required this.newExperience,
    required this.levelsGained,
  });
}

/// ユーザーのアカウントレベル（`User.level`/`User.experience`）の進行を管理する。
/// クエスト報酬のXPなど、ゲーム内の様々な経路から経験値を加算する唯一の入口。
class LevelingService {
  static final LevelingService _instance = LevelingService._internal();

  factory LevelingService() {
    return _instance;
  }

  LevelingService._internal();

  /// Test-only seam: builds a standalone (non-singleton) LevelingService
  /// backed by a caller-provided FirestoreService, mirroring the pattern
  /// used by SkillTreeService/QuestService.
  LevelingService.forFirestore(FirestoreService firestoreService)
      : _firestoreServiceOverride = firestoreService;

  FirestoreService? _firestoreServiceOverride;

  FirestoreService get _firestoreService =>
      _firestoreServiceOverride ??= FirestoreService();

  /// レベルNからN+1へ上がるのに必要な経験値。シンプルな線形カーブ
  /// （レベル1→2は100、レベル2→3は200...）。
  static int xpRequiredForLevel(int level) => level * 100;

  /// [userId]に[amount]の経験値を加算し、必要に応じてレベルアップを処理する。
  /// 1回の加算で複数レベル分が一気に上がるケースも正しく扱う（例: 大量XP報酬）。
  Future<LevelUpResult> addExperience(String userId, int amount) async {
    if (amount <= 0) {
      final current = await _getLevelAndExperience(userId);
      return LevelUpResult(
        newLevel: current.$1,
        newExperience: current.$2,
        levelsGained: 0,
      );
    }

    final (currentLevel, currentExperience) =
        await _getLevelAndExperience(userId);

    var level = currentLevel;
    var experience = currentExperience + amount;
    var levelsGained = 0;

    while (experience >= xpRequiredForLevel(level)) {
      experience -= xpRequiredForLevel(level);
      level += 1;
      levelsGained += 1;
    }

    // FirestoreService.update() requires the target document to already
    // exist (plain Firestore `update`), which throws for a user whose
    // document hasn't been created yet. set(..., merge: true) works for
    // both the new-document and existing-document cases, and (unlike a
    // plain set()) doesn't clobber the user's other fields (name, gold,
    // etc.).
    await _firestoreService.db.collection('users').doc(userId).set(
      {'level': level, 'experience': experience},
      SetOptions(merge: true),
    );

    return LevelUpResult(
      newLevel: level,
      newExperience: experience,
      levelsGained: levelsGained,
    );
  }

  Future<(int, int)> _getLevelAndExperience(String userId) async {
    final data = await _firestoreService.get('users/$userId');
    final level = data?['level'] as int? ?? 1;
    final experience = data?['experience'] as int? ?? 0;
    return (level, experience);
  }
}
