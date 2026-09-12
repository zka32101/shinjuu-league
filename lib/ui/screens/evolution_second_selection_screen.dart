// Lv6進化選択画面（第二選択 - 進化維持 or 切り替え）

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shinjuu_league/config/theme.dart';
import 'package:shinjuu_league/data/models/skill_catalog.dart';
import 'package:shinjuu_league/viewmodels/skill_evolution_viewmodel.dart';

/// Lv6進化選択画面
/// 現在の進化を維持するか、別の進化に切り替えるか選択
class EvolutionSecondSelectionScreen extends ConsumerStatefulWidget {
  final String mechaId;
  final EvolutionType currentEvolution;
  final int currentLevel;
  final Function(EvolutionType) onEvolutionConfirmed;

  const EvolutionSecondSelectionScreen({
    required this.mechaId,
    required this.currentEvolution,
    required this.currentLevel,
    required this.onEvolutionConfirmed,
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<EvolutionSecondSelectionScreen> createState() =>
      _EvolutionSecondSelectionScreenState();
}

class _EvolutionSecondSelectionScreenState
    extends ConsumerState<EvolutionSecondSelectionScreen> {
  bool _userSelected = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 画面表示後にカウントダウン開始
      ref.read(evolutionSelectionProvider.notifier).showSelection();
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectionState = ref.watch(evolutionSelectionProvider);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // タイムアウト判定（Lv3の選択をそのまま維持）
    if (selectionState.isTimedOut() && !_userSelected) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_userSelected) {
          widget.onEvolutionConfirmed(widget.currentEvolution);
        }
      });
    }

    return WillPopScope(
      onWillPop: () async => false, // 戻るボタン無効化
      child: Scaffold(
        backgroundColor: isDarkMode
            ? AppColors.darkBackground
            : AppColors.lightBackground,
        body: SafeArea(
          child: Column(
            children: [
              // ヘッダー
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      'レベル6 - 進化強化',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '現在の進化を強化するか、方針を切り替えるか',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isDarkMode
                                ? Colors.grey[400]
                                : Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ),

              // カウントダウンバー
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '自動選択まで',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          '${selectionState.remainingSeconds}秒',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: selectionState.remainingSeconds <= 3
                                    ? Colors.red
                                    : null,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value:
                            selectionState.remainingSeconds /
                            10, // 10秒スケール
                        minHeight: 8,
                        backgroundColor: isDarkMode
                            ? Colors.grey[800]
                            : Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation(
                          selectionState.remainingSeconds <= 3
                              ? Colors.red
                              : Colors.blue[400],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // 現在の進化状態表示
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.amber[400]!,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: isDarkMode
                        ? Colors.amber.withOpacity(0.1)
                        : Colors.amber[50],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Text(
                        _getEmojiForType(widget.currentEvolution),
                        style: const TextStyle(fontSize: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '現在: ${_getTitleForType(widget.currentEvolution)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Lv3 で選択済み',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Colors.amber[700],
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // 選択肢
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    // 進化維持カード
                    _buildChoiceCard(
                      context,
                      title: '進化を強化',
                      subtitle: '現在の${_getTitleForType(widget.currentEvolution)}をさらに強化',
                      emoji: '🔥',
                      description:
                          'ダメージ / HP / 味方効果がさらに +40% 増加。現在の方針を貫く。',
                      isSelected:
                          selectionState.selectedChoice ==
                          widget.currentEvolution,
                      isDarkMode: isDarkMode,
                      onTap: () {
                        _userSelected = true;
                        ref
                            .read(evolutionSelectionProvider.notifier)
                            .selectEvolution(widget.currentEvolution);
                        widget.onEvolutionConfirmed(widget.currentEvolution);
                      },
                    ),

                    const SizedBox(height: 16),

                    // 進化切り替えカード
                    Column(
                      children: [
                        Text(
                          'または進化を切り替える',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),

                    // 他の進化オプション
                    ..._buildOtherEvolutionOptions(
                      context,
                      currentType: widget.currentEvolution,
                      selectionState: selectionState,
                      isDarkMode: isDarkMode,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildOtherEvolutionOptions(
    BuildContext context, {
    required EvolutionType currentType,
    required EvolutionSelectionState selectionState,
    required bool isDarkMode,
  }) {
    final allTypes = [
      EvolutionType.offensive,
      EvolutionType.defensive,
      EvolutionType.support,
    ];

    final otherTypes = allTypes.where((t) => t != currentType).toList();

    return otherTypes.map((type) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: _buildChoiceCard(
          context,
          title: '${_getTitleForType(type)}に変更',
          subtitle: '敵チームに対応する',
          emoji: _getEmojiForType(type),
          description: _getDescriptionForSecondEvolution(type),
          isSelected: selectionState.selectedChoice == type,
          isDarkMode: isDarkMode,
          onTap: () {
            _userSelected = true;
            ref
                .read(evolutionSelectionProvider.notifier)
                .selectEvolution(type);
            widget.onEvolutionConfirmed(type);
          },
        ),
      );
    }).toList();
  }

  Widget _buildChoiceCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String emoji,
    required String description,
    required bool isSelected,
    required bool isDarkMode,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[400]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? (isDarkMode ? Colors.blue.withOpacity(0.2) : Colors.blue[50])
              : (isDarkMode ? Colors.grey[900] : Colors.white),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 2,
                  )
                ]
              : null,
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  emoji,
                  style: const TextStyle(fontSize: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(
                              color: Colors.blue[400],
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                    height: 1.5,
                  ),
            ),
            if (isSelected) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.blue[400],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '選択済み',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.blue[400],
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getEmojiForType(EvolutionType type) {
    switch (type) {
      case EvolutionType.offensive:
        return '⚔️';
      case EvolutionType.defensive:
        return '🛡️';
      case EvolutionType.support:
        return '🤝';
    }
  }

  String _getTitleForType(EvolutionType type) {
    switch (type) {
      case EvolutionType.offensive:
        return '攻撃型';
      case EvolutionType.defensive:
        return '防御型';
      case EvolutionType.support:
        return '支援型';
    }
  }

  String _getDescriptionForSecondEvolution(EvolutionType type) {
    switch (type) {
      case EvolutionType.offensive:
        return 'ダメージ型に専念。敵をより速く倒す道を選ぶ。';
      case EvolutionType.defensive:
        return '防御型に専念。敵の猛攻から完全に身を守る。';
      case EvolutionType.support:
        return '支援型に専念。チーム全体のサポートに特化。';
    }
  }
}
