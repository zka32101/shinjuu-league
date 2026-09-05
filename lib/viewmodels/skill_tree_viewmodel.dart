import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shinjuu_league/data/models/skill_model.dart';
import 'package:shinjuu_league/services/auth_service.dart';
import 'package:shinjuu_league/services/skill_tree_service.dart';

/// スキルツリーのUI状態を管理するViewModel
class SkillTreeViewModel extends StateNotifier<AsyncValue<SkillTree>> {
  SkillTreeViewModel({
    SkillTreeService? skillTreeService,
    AuthService? authService,
  })
    : _skillTreeService = skillTreeService ?? SkillTreeService(),
      _authService = authService ?? AuthService(),
      super(const AsyncValue.loading()) {
    _init();
  }

  final SkillTreeService _skillTreeService;
  final AuthService _authService;

  /// 現在のユーザーID
  String? get _currentUserId => _authService.currentUser?.uid;

  /// 初期化
  Future<void> _init() async {
    final userId = _currentUserId;
    if (userId == null) {
      state = const AsyncValue.data(SkillTree.create());
      return;
    }

    await _loadSkillTree(userId);
  }

  /// スキルツリーを読み込み
  Future<void> _loadSkillTree(String userId) async {
    try {
      state = const AsyncValue.loading();
      final skillTree = await _skillTreeService.getSkillTree(userId);
      if (skillTree != null) {
        state = AsyncValue.data(skillTree);
      } else {
        state = AsyncValue.data(SkillTree.create());
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// スキルポイントを割り当て
  Future<bool> allocateSkillPoint(int treeIndex, int tierIndex) async {
    final userId = _currentUserId;
    if (userId == null) return false;

    try {
      final success = await _skillTreeService.allocateSkillPoint(
        userId,
        treeIndex,
        tierIndex,
      );

      if (success) {
        // ツリーをリロード
        await _reloadSkillTree();
      }

      return success;
    } catch (e) {
      return false;
    }
  }

  /// スキルツリーをリロード
  Future<void> _reloadSkillTree() async {
    final userId = _currentUserId;
    if (userId == null) return;

    try {
      final skillTree = await _skillTreeService.getSkillTree(userId);
      if (skillTree != null) {
        state = AsyncValue.data(skillTree);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// 利用可能なポイントを確認
  bool canAllocateSkillPoint(int treeIndex, int tierIndex) {
    final skillTree = state.value;
    if (skillTree == null) return false;

    // ポイントが残っているか確認
    if (skillTree.availablePoints <= 0) return false;

    // ツリーのインデックスが有効か確認
    if (treeIndex < 0 || treeIndex >= SkillTreeService.maxTrees) return false;

    // ティアのインデックスが有効か確認
    if (tierIndex < 0 || tierIndex >= SkillTreeService.maxTiersPerTree) {
      return false;
    }

    // ツリーの進行状況を確認（順序を守る必要がある）
    final tree = skillTree.trees[treeIndex];
    if (tree.allocatedTiers != tierIndex) return false;

    return true;
  }

  /// スキルツリーの進捗パーセンテージを取得
  int getProgressPercentage() {
    final skillTree = state.value;
    if (skillTree == null) return 0;

    final totalPoints = SkillTreeService.maxTiersPerTree * SkillTreeService.maxTrees;
    return (skillTree.totalAllocatedPoints / totalPoints * 100).toInt();
  }

  /// ツリーのステータス修正を計算
  Map<String, double> getStatModifiers() {
    final skillTree = state.value;
    if (skillTree == null) {
      return {'atk': 1.0, 'def': 1.0, 'spd': 1.0};
    }

    return _skillTreeService.calculateStatModifiers(skillTree);
  }

  /// スキルツリーの統計情報を取得
  Map<String, dynamic> getSkillTreeStats() {
    final skillTree = state.value;
    if (skillTree == null) {
      return {
        'total_points': 0,
        'allocated_points': 0,
        'available_points': 0,
        'progress_percentage': 0,
      };
    }

    return _skillTreeService.getSkillTreeStats(skillTree);
  }

  @override
  void dispose() {
    super.dispose();
  }
}

/// Riverpod provider for SkillTreeViewModel
final skillTreeViewModelProvider =
    StateNotifierProvider.autoDispose<SkillTreeViewModel, AsyncValue<SkillTree>>(
  (ref) => SkillTreeViewModel(),
);

/// Stat modifiers provider
final skillTreeModifiersProvider = Provider.autoDispose<Map<String, double>>((ref) {
  final skillTree = ref.watch(skillTreeViewModelProvider);
  return skillTree.whenData((tree) {
    final service = SkillTreeService();
    return service.calculateStatModifiers(tree);
  }).value ?? {'atk': 1.0, 'def': 1.0, 'spd': 1.0};
});

/// Progress percentage provider
final skillTreeProgressProvider = Provider.autoDispose<int>((ref) {
  final skillTree = ref.watch(skillTreeViewModelProvider);
  final value = skillTree.value;
  if (value == null) return 0;

  final totalPoints = SkillTreeService.maxTiersPerTree * SkillTreeService.maxTrees;
  return (value.totalAllocatedPoints / totalPoints * 100).toInt();
});

/// Available points provider
final availableSkillPointsProvider = Provider.autoDispose<int>((ref) {
  final skillTree = ref.watch(skillTreeViewModelProvider);
  return skillTree.value?.availablePoints ?? 0;
});
