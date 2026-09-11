// Lv3進化選択画面（v2 - Phase 13 システム対応版）

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shinjuu_league/config/theme.dart';
import 'package:shinjuu_league/data/models/skill_catalog.dart';
import 'package:shinjuu_league/viewmodels/skill_evolution_viewmodel.dart';

/// Lv3進化選択画面
/// 画面表示時に自動でカウントダウン開始、10秒でタイムアウト→デフォルト（攻撃型）を自動選択
class EvolutionSelectionV2Screen extends ConsumerStatefulWidget {
  final String mechaId;
  final int currentLevel;
  final Function(EvolutionType) onEvolutionSelected;

  const EvolutionSelectionV2Screen({
    required this.mechaId,
    required this.currentLevel,
    required this.onEvolutionSelected,
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<EvolutionSelectionV2Screen> createState() =>
      _EvolutionSelectionV2ScreenState();
}

class _EvolutionSelectionV2ScreenState
    extends ConsumerState<EvolutionSelectionV2Screen> {
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

    // タイムアウト判定
    if (selectionState.isTimedOut() && !_userSelected) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_userSelected) {
          widget.onEvolutionSelected(
            EvolutionType.offensive, // デフォルト（攻撃型）
          );
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
                      'レベル3 - 進化選択',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '神獣の力を目覚めさせよう',
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

              // 進化選択肢
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildEvolutionCard(
                      context,
                      type: EvolutionType.offensive,
                      emoji: '⚔️',
                      viewModelNotifier: ref.read(
                        evolutionSelectionProvider.notifier,
                      ),
                      isSelected:
                          selectionState.selectedChoice ==
                          EvolutionType.offensive,
                      isDarkMode: isDarkMode,
                      onTap: () {
                        _userSelected = true;
                        ref
                            .read(evolutionSelectionProvider.notifier)
                            .selectEvolution(EvolutionType.offensive);
                        widget.onEvolutionSelected(EvolutionType.offensive);
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildEvolutionCard(
                      context,
                      type: EvolutionType.defensive,
                      emoji: '🛡️',
                      viewModelNotifier: ref.read(
                        evolutionSelectionProvider.notifier,
                      ),
                      isSelected:
                          selectionState.selectedChoice ==
                          EvolutionType.defensive,
                      isDarkMode: isDarkMode,
                      onTap: () {
                        _userSelected = true;
                        ref
                            .read(evolutionSelectionProvider.notifier)
                            .selectEvolution(EvolutionType.defensive);
                        widget.onEvolutionSelected(EvolutionType.defensive);
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildEvolutionCard(
                      context,
                      type: EvolutionType.support,
                      emoji: '🤝',
                      viewModelNotifier: ref.read(
                        evolutionSelectionProvider.notifier,
                      ),
                      isSelected:
                          selectionState.selectedChoice ==
                          EvolutionType.support,
                      isDarkMode: isDarkMode,
                      onTap: () {
                        _userSelected = true;
                        ref
                            .read(evolutionSelectionProvider.notifier)
                            .selectEvolution(EvolutionType.support);
                        widget.onEvolutionSelected(EvolutionType.support);
                      },
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

  Widget _buildEvolutionCard(
    BuildContext context, {
    required EvolutionType type,
    required String emoji,
    required EvolutionSelectionViewModel viewModelNotifier,
    required bool isSelected,
    required bool isDarkMode,
    required VoidCallback onTap,
  }) {
    final description = viewModelNotifier.getDescription(type);

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
            // タイトルと絵文字
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  emoji,
                  style: const TextStyle(fontSize: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getEvolutionTitle(type),
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getEvolutionBonus(type),
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(
                              color: Colors.blue[400],
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 説明文
            Text(
              description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                    height: 1.5,
                  ),
            ),

            const SizedBox(height: 12),

            // チェックマーク（選択時）
            if (isSelected)
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
        ),
      ),
    );
  }

  String _getEvolutionTitle(EvolutionType type) {
    switch (type) {
      case EvolutionType.offensive:
        return '攻撃型進化';
      case EvolutionType.defensive:
        return '防御型進化';
      case EvolutionType.support:
        return '支援型進化';
    }
  }

  String _getEvolutionBonus(EvolutionType type) {
    switch (type) {
      case EvolutionType.offensive:
        return 'ダメージ +60%';
      case EvolutionType.defensive:
        return 'HP +30% / 軽減 +20%';
      case EvolutionType.support:
        return '味方効果 +50%';
    }
  }
}
