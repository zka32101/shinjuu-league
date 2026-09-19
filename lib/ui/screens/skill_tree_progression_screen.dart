import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shinjuu_league/data/models/skill_model.dart';
import 'package:shinjuu_league/services/skill_tree_service.dart';
import 'package:shinjuu_league/data/providers/service_providers.dart';
import 'package:shinjuu_league/ui/widgets/custom_button.dart';

/// スキルツリー進行画面
/// ユーザーがスキルポイントを割り当てて、ツリーを成長させる画面
class SkillTreeProgressionScreen extends ConsumerStatefulWidget {
  const SkillTreeProgressionScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SkillTreeProgressionScreen> createState() =>
      _SkillTreeProgressionScreenState();
}

class _SkillTreeProgressionScreenState
    extends ConsumerState<SkillTreeProgressionScreen> {
  late PageController _pageController;
  int _currentTreeIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final skillTreeAsync = ref.watch(skillTreeViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('スキルツリー'),
        centerTitle: true,
        elevation: 0,
      ),
      body: skillTreeAsync.when(
        loading: () => const _LoadingState(),
        error: (error, st) => _ErrorState(error: error),
        data: (skillTree) => _SkillTreeContent(
          skillTree: skillTree,
          pageController: _pageController,
          currentTreeIndex: _currentTreeIndex,
          onPageChanged: (index) {
            setState(() => _currentTreeIndex = index);
          },
        ),
      ),
    );
  }
}

/// コンテンツウィジェット
class _SkillTreeContent extends ConsumerWidget {
  final SkillTree? skillTree;
  final PageController pageController;
  final int currentTreeIndex;
  final ValueChanged<int> onPageChanged;

  const _SkillTreeContent({
    required this.skillTree,
    required this.pageController,
    required this.currentTreeIndex,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (skillTree == null) {
      return const Center(
        child: Text('スキルツリーの読み込みに失敗しました'),
      );
    }

    final viewModel = ref.read(skillTreeViewModelProvider.notifier);

    return Column(
      children: [
        // ツリータブ
        _TreeTabBar(
          currentIndex: currentTreeIndex,
          onTabSelected: (index) {
            pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
        ),

        // スキルポイント表示
        _PointsDisplay(
          availablePoints: skillTree!.availablePoints,
          totalAllocatedPoints: skillTree!.totalAllocatedPoints,
        ),

        // プログレスバー
        _ProgressBar(skillTree: skillTree!),

        // ツリーページビュー
        Expanded(
          child: PageView.builder(
            controller: pageController,
            onPageChanged: onPageChanged,
            itemCount: SkillTreeService.maxTrees,
            itemBuilder: (context, treeIndex) {
              final tree = skillTree!.trees[treeIndex];
              return _TreeView(
                tree: tree,
                treeIndex: treeIndex,
                treeName: SkillTreeService.treeNames[treeIndex],
                skillTree: skillTree!,
                onAllocate: () async {
                  // 最初の未割り当てティアを探す
                  for (int tierIndex = 0;
                      tierIndex < SkillTreeService.maxTiersPerTree;
                      tierIndex++) {
                    if (!tree.isAllocated(tierIndex)) {
                      await viewModel.allocateSkillPoint(treeIndex, tierIndex);
                      break;
                    }
                  }
                },
              );
            },
          ),
        ),

        // 統計情報とプレビュー
        _StatsPreview(
          skillTree: skillTree!,
          treeIndex: currentTreeIndex,
        ),

        // コントロールボタン
        _ControlButtons(
          skillTree: skillTree!,
          onReset: () => _showResetDialog(context, ref),
        ),
      ],
    );
  }

  void _showResetDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('スキルリセット'),
        content: const Text('すべてのスキルポイントをリセットしますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Reset functionality
            },
            child: const Text('リセット'),
          ),
        ],
      ),
    );
  }
}

/// ツリータブバー
class _TreeTabBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const _TreeTabBar({
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final treeEmojis = ['⚔️', '🛡️', '⚡'];
    final treeNames = SkillTreeService.treeNames;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(
          SkillTreeService.maxTrees,
          (index) {
            final isSelected = currentIndex == index;
            return GestureDetector(
              onTap: () => onTabSelected(index),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(
                    color: Theme.of(context).primaryColor,
                    width: 2.0,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      treeEmojis[index],
                      style: const TextStyle(fontSize: 24.0),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      treeNames[index],
                      style: TextStyle(
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isSelected
                            ? Colors.white
                            : Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// スキルポイント表示
class _PointsDisplay extends StatelessWidget {
  final int availablePoints;
  final int totalAllocatedPoints;

  const _PointsDisplay({
    required this.availablePoints,
    required this.totalAllocatedPoints,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _PointCard(
            label: '利用可能',
            value: availablePoints,
            color: Colors.amber,
          ),
          _PointCard(
            label: '割り当て済み',
            value: totalAllocatedPoints,
            color: Colors.green,
          ),
          _PointCard(
            label: '合計',
            value: availablePoints + totalAllocatedPoints,
            color: Colors.blue,
          ),
        ],
      ),
    );
  }
}

/// ポイントカード
class _PointCard extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _PointCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 4.0),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12.0,
            vertical: 6.0,
          ),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: color, width: 1.5),
          ),
          child: Text(
            '$value',
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

/// プログレスバー
class _ProgressBar extends StatelessWidget {
  final SkillTree skillTree;

  const _ProgressBar({required this.skillTree});

  @override
  Widget build(BuildContext context) {
    final progress = skillTree.totalAllocatedPoints / 15.0;
    final progressPercent = (progress * 100).toStringAsFixed(0);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ツリー進行度: $progressPercent%',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8.0),
          ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 16.0,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                progress > 0.66 ? Colors.green :
                progress > 0.33 ? Colors.amber :
                Colors.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ツリービュー
class _TreeView extends StatelessWidget {
  final SkillTreeData tree;
  final int treeIndex;
  final String treeName;
  final SkillTree skillTree;
  final VoidCallback onAllocate;

  const _TreeView({
    required this.tree,
    required this.treeIndex,
    required this.treeName,
    required this.skillTree,
    required this.onAllocate,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // ツリータイトルと説明
          Text(
            treeName,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8.0),
          Text(
            _getTreeDescription(),
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24.0),

          // ティアリスト
          Column(
            children: List.generate(
              SkillTreeService.maxTiersPerTree,
              (tierIndex) => _TierCard(
                tierIndex: tierIndex,
                isAllocated: tree.isAllocated(tierIndex),
                modifier: SkillTreeService.tierModifiers[treeIndex][tierIndex],
                onAllocate: skillTree.availablePoints > 0 &&
                        !tree.isAllocated(tierIndex) &&
                        (tierIndex == 0 || tree.isAllocated(tierIndex - 1))
                    ? onAllocate
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getTreeDescription() {
    switch (treeIndex) {
      case 0:
        return '攻撃力を強化するツリー\n各ティアで+5%の攻撃力ボーナス';
      case 1:
        return '防御力を強化するツリー\n各ティアで+8%の防御力ボーナス';
      case 2:
        return '素早さを強化するツリー\n各ティアで+3%の素早さボーナス';
      default:
        return '';
    }
  }
}

/// ティアカード
class _TierCard extends StatelessWidget {
  final int tierIndex;
  final bool isAllocated;
  final double modifier;
  final VoidCallback? onAllocate;

  const _TierCard({
    required this.tierIndex,
    required this.isAllocated,
    required this.modifier,
    required this.onAllocate,
  });

  @override
  Widget build(BuildContext context) {
    final isLocked = onAllocate == null && !isAllocated;
    final canAllocate = onAllocate != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: isAllocated
            ? Theme.of(context).primaryColor.withOpacity(0.2)
            : isLocked
                ? Colors.grey.withOpacity(0.1)
                : Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: isAllocated
              ? Theme.of(context).primaryColor
              : isLocked
                  ? Colors.grey
                  : Colors.blue,
          width: 2.0,
        ),
      ),
      child: Row(
        children: [
          // ティアインジケーター
          Container(
            width: 48.0,
            height: 48.0,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isAllocated
                  ? Theme.of(context).primaryColor
                  : isLocked
                      ? Colors.grey
                      : Colors.blue,
            ),
            child: Center(
              child: Text(
                'T${tierIndex + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12.0,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12.0),

          // ボーナス情報
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAllocated ? '✓ 割り当て済み' : isLocked ? 'ロック中' : '割り当て可能',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isAllocated
                        ? Colors.green
                        : isLocked
                            ? Colors.grey
                            : Colors.blue,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  '+${((modifier - 1.0) * 100).toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),

          // アクションボタン
          if (canAllocate)
            CustomButton(
              label: '割り当て',
              onPressed: onAllocate!,
              small: true,
            )
          else if (isAllocated)
            Icon(
              Icons.check_circle,
              color: Theme.of(context).primaryColor,
            )
          else
            Icon(
              Icons.lock,
              color: Colors.grey[400],
            ),
        ],
      ),
    );
  }
}

/// 統計情報プレビュー
class _StatsPreview extends StatelessWidget {
  final SkillTree skillTree;
  final int treeIndex;

  const _StatsPreview({
    required this.skillTree,
    required this.treeIndex,
  });

  @override
  Widget build(BuildContext context) {
    final skillTreeService = SkillTreeService();
    final modifiers = skillTreeService.calculateStatModifiers(skillTree);

    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ステータス修正',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12.0),
          _StatModifierRow(
            stat: '攻撃',
            emoji: '⚔️',
            modifier: modifiers['atk'] ?? 1.0,
          ),
          const SizedBox(height: 8.0),
          _StatModifierRow(
            stat: '防御',
            emoji: '🛡️',
            modifier: modifiers['def'] ?? 1.0,
          ),
          const SizedBox(height: 8.0),
          _StatModifierRow(
            stat: '素早さ',
            emoji: '⚡',
            modifier: modifiers['spd'] ?? 1.0,
          ),
        ],
      ),
    );
  }
}

/// ステータス修正行
class _StatModifierRow extends StatelessWidget {
  final String stat;
  final String emoji;
  final double modifier;

  const _StatModifierRow({
    required this.stat,
    required this.emoji,
    required this.modifier,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = ((modifier - 1.0) * 100).toStringAsFixed(1);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18.0)),
            const SizedBox(width: 8.0),
            Text(stat),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 8.0,
            vertical: 4.0,
          ),
          decoration: BoxDecoration(
            color: modifier > 1.0 ? Colors.green.withOpacity(0.2) : null,
            borderRadius: BorderRadius.circular(6.0),
            border: Border.all(
              color: modifier > 1.0 ? Colors.green : Colors.grey,
              width: 1.0,
            ),
          ),
          child: Text(
            modifier > 1.0 ? '+$percentage%' : '×${modifier.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: modifier > 1.0 ? Colors.green : Colors.grey,
            ),
          ),
        ),
      ],
    );
  }
}

/// コントロールボタン
class _ControlButtons extends StatelessWidget {
  final SkillTree skillTree;
  final VoidCallback onReset;

  const _ControlButtons({
    required this.skillTree,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: CustomButton(
              label: 'リセット',
              onPressed: onReset,
              secondary: true,
            ),
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: CustomButton(
              label: '完了',
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}

/// ローディング状態
class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}

/// エラー状態
class _ErrorState extends StatelessWidget {
  final Object error;

  const _ErrorState({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48.0,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16.0),
          Text(
            'エラーが発生しました',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8.0),
          Text(
            error.toString(),
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
