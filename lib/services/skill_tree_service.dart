import 'package:shinjuu_league/data/models/skill_model.dart';
import 'package:shinjuu_league/services/firestore_service.dart';

/// スキルツリーの管理・進行を行うService
/// 3本のツリー × 5階層（ティア）= 15スキルポイント
class SkillTreeService {
  static final SkillTreeService _instance = SkillTreeService._internal();

  factory SkillTreeService() {
    return _instance;
  }

  SkillTreeService._internal();

  final FirestoreService _firestoreService = FirestoreService();

  // スキルツリーの定義
  static const List<String> treeNames = ['攻撃', '防御', '速度'];
  static const int maxTiersPerTree = 5;
  static const int maxTrees = 3;
  static const int totalSkillPoints = maxTiersPerTree * maxTrees;

  // 各ツリーの階層ごとのステータス修正倍率
  static const Map<String, List<double>> tierModifiers = {
    '攻撃': [1.05, 1.10, 1.15, 1.20, 1.25], // ATK +5% per tier
    '防御': [1.08, 1.16, 1.24, 1.32, 1.40], // DEF +8% per tier
    '速度': [1.03, 1.06, 1.09, 1.12, 1.15], // SPD +3% per tier
  };

  /// ユーザーのスキルツリーを取得
  Future<SkillTree?> getSkillTree(String userId) async {
    try {
      final docSnapshot = await _firestoreService.collection('users').doc(userId).get();
      if (!docSnapshot.exists) {
        return null;
      }

      final skillTreeData = docSnapshot.data()?['skillTree'];
      if (skillTreeData == null) {
        return _initializeSkillTree(userId);
      }

      return SkillTree.fromJson(skillTreeData as Map<String, dynamic>);
    } catch (e) {
      if (e.toString().contains('Firebase not initialized')) {
        // オフライン状態での動作を回避
        return SkillTree.create();
      }
      rethrow;
    }
  }

  /// スキルツリーを初期化（新規ユーザー）
  Future<SkillTree> _initializeSkillTree(String userId) async {
    final skillTree = SkillTree.create();
    await _firestoreService.updateUser(userId, {
      'skillTree': skillTree.toJson(),
    });
    return skillTree;
  }

  /// スキルポイントを割り当て
  /// treeIndex: 0=攻撃, 1=防御, 2=速度
  /// tierIndex: 0-4（ティア）
  Future<bool> allocateSkillPoint(
    String userId,
    int treeIndex,
    int tierIndex,
  ) async {
    if (treeIndex < 0 || treeIndex >= maxTrees) return false;
    if (tierIndex < 0 || tierIndex >= maxTiersPerTree) return false;

    try {
      final skillTree = await getSkillTree(userId);
      if (skillTree == null) return false;

      // 利用可能なポイントを確認
      if (skillTree.availablePoints <= 0) return false;

      // ツリーの階層を確認
      final tree = skillTree.trees[treeIndex];
      if (tree.allocatedTiers > tierIndex) {
        // 既に割り当て済み
        return false;
      }

      if (tree.allocatedTiers != tierIndex) {
        // スキップは不可（順序を守る必要がある）
        return false;
      }

      // スキルポイントを割り当て
      tree.allocatedTiers = tierIndex + 1;
      skillTree.totalAllocatedPoints += 1;
      skillTree.availablePoints -= 1;

      // Firestoreに保存
      await _firestoreService.updateUser(userId, {
        'skillTree': skillTree.toJson(),
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  /// スキルツリーのステータス修正倍率を計算
  /// 例: 攻撃ツリーで2ティア割り当て → 1.10倍
  Map<String, double> calculateStatModifiers(SkillTree skillTree) {
    double atkMultiplier = 1.0;
    double defMultiplier = 1.0;
    double spdMultiplier = 1.0;

    for (int i = 0; i < maxTrees; i++) {
      final tree = skillTree.trees[i];
      final treeName = treeNames[i];
      final modifiers = tierModifiers[treeName]!;

      if (tree.allocatedTiers > 0) {
        final tierIndex = tree.allocatedTiers - 1;
        final modifier = modifiers[tierIndex];

        switch (i) {
          case 0: // 攻撃
            atkMultiplier *= modifier;
            break;
          case 1: // 防御
            defMultiplier *= modifier;
            break;
          case 2: // 速度
            spdMultiplier *= modifier;
            break;
        }
      }
    }

    return {
      'atk': atkMultiplier,
      'def': defMultiplier,
      'spd': spdMultiplier,
    };
  }

  /// レベルアップ時にスキルポイントを付与
  Future<void> awardSkillPointOnLevelUp(String userId) async {
    try {
      final skillTree = await getSkillTree(userId);
      if (skillTree == null) return;

      // 利用可能なポイントを1増加（最大値に達していない場合）
      if (skillTree.totalAllocatedPoints < totalSkillPoints) {
        skillTree.availablePoints += 1;
        await _firestoreService.updateUser(userId, {
          'skillTree': skillTree.toJson(),
        });
      }
    } catch (e) {
      // スキルポイント付与失敗時も他の処理を妨げない
    }
  }

  /// スキルツリーの統計情報を取得
  Map<String, dynamic> getSkillTreeStats(SkillTree skillTree) {
    final progress = (skillTree.totalAllocatedPoints / totalSkillPoints * 100).toInt();
    final modifiers = calculateStatModifiers(skillTree);

    return {
      'total_points': totalSkillPoints,
      'allocated_points': skillTree.totalAllocatedPoints,
      'available_points': skillTree.availablePoints,
      'progress_percentage': progress,
      'atk_multiplier': (modifiers['atk']! * 100).toStringAsFixed(1),
      'def_multiplier': (modifiers['def']! * 100).toStringAsFixed(1),
      'spd_multiplier': (modifiers['spd']! * 100).toStringAsFixed(1),
      'trees': [
        {
          'name': '攻撃',
          'allocated_tiers': skillTree.trees[0].allocatedTiers,
          'max_tiers': maxTiersPerTree,
        },
        {
          'name': '防御',
          'allocated_tiers': skillTree.trees[1].allocatedTiers,
          'max_tiers': maxTiersPerTree,
        },
        {
          'name': '速度',
          'allocated_tiers': skillTree.trees[2].allocatedTiers,
          'max_tiers': maxTiersPerTree,
        },
      ],
    };
  }
}
