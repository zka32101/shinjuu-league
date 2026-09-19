import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shinjuu_league/data/models/quest_model.dart';
import 'package:shinjuu_league/viewmodels/quest_viewmodel.dart';
import 'package:shinjuu_league/config/theme.dart';
import 'package:shinjuu_league/ui/widgets/custom_button.dart';

class QuestsScreen extends ConsumerStatefulWidget {
  const QuestsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<QuestsScreen> createState() => _QuestsScreenState();
}

class _QuestsScreenState extends ConsumerState<QuestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() => _selectedTabIndex = _tabController.index);
    });

    // Load quests on screen enter
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(questViewModelProvider.notifier).loadQuests();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final questState = ref.watch(questViewModelProvider);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('クエスト'),
        centerTitle: true,
        elevation: 0,
        backgroundColor:
            isDarkMode ? AppColors.darkBg : AppColors.lightBg,
        foregroundColor:
            isDarkMode ? AppColors.lightText : AppColors.darkText,
      ),
      body: questState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : questState.error != null
              ? _buildErrorView(questState.error!)
              : Column(
                  children: [
                    // Tab bar
                    Container(
                      color: isDarkMode ? AppColors.darkCard : AppColors.lightCard,
                      child: TabBar(
                        controller: _tabController,
                        indicatorColor: AppColors.gold,
                        indicatorWeight: 3,
                        labelColor: AppColors.gold,
                        unselectedLabelColor:
                            isDarkMode ? AppColors.mutedText : AppColors.darkText,
                        tabs: const [
                          Tab(text: '日次'),
                          Tab(text: '週次'),
                          Tab(text: 'シーズン'),
                          Tab(text: '完了'),
                        ],
                      ),
                    ),
                    // Tab content
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildQuestList(
                            questState.activeQuests
                                .where((q) => q.questId.startsWith('daily_'))
                                .toList(),
                            isDarkMode,
                          ),
                          _buildQuestList(
                            questState.activeQuests
                                .where((q) => q.questId.startsWith('weekly_'))
                                .toList(),
                            isDarkMode,
                          ),
                          _buildQuestList(
                            questState.activeQuests
                                .where((q) => q.questId.startsWith('seasonal_'))
                                .toList(),
                            isDarkMode,
                          ),
                          _buildQuestList(
                            questState.completedQuests,
                            isDarkMode,
                            isCompleted: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildQuestList(List<PlayerQuest> quests, bool isDarkMode,
      {bool isCompleted = false}) {
    if (quests.isEmpty) {
      return Center(
        child: Text(
          isCompleted ? 'クエスト完了なし' : 'アクティブなクエストなし',
          style: TextStyle(
            color: isDarkMode ? AppColors.mutedText : AppColors.darkText,
            fontSize: 16,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: quests.length,
      itemBuilder: (context, index) {
        final quest = quests[index];
        final catalogQuest = QuestCatalog.getById(quest.questId);

        return _QuestCard(
          playerQuest: quest,
          catalogQuest: catalogQuest,
          isDarkMode: isDarkMode,
          onProgressUpdate: () => _handleProgressUpdate(quest.questId),
          onClaimReward: () => _handleClaimReward(quest.questId),
        );
      },
    );
  }

  Widget _buildErrorView(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'エラーが発生しました',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          CustomButton(
            label: '再試行',
            onPressed: () {
              ref.read(questViewModelProvider.notifier).refresh();
            },
          ),
        ],
      ),
    );
  }

  void _handleProgressUpdate(String questId) {
    // This would be called from battle completion
    // For now, just show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('クエスト進行: $questId'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handleClaimReward(String questId) async {
    final reward =
        await ref.read(questViewModelProvider.notifier).claimQuestReward(questId);

    if (reward != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '報酬獲得: ${reward.currency}通貨 + ${reward.achievementBadges}バッジ'),
          duration: const Duration(seconds: 3),
          backgroundColor: AppColors.gold,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('報酬獲得に失敗しました'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}

class _QuestCard extends ConsumerWidget {
  final PlayerQuest playerQuest;
  final Quest? catalogQuest;
  final bool isDarkMode;
  final VoidCallback onProgressUpdate;
  final VoidCallback onClaimReward;

  const _QuestCard({
    required this.playerQuest,
    required this.catalogQuest,
    required this.isDarkMode,
    required this.onProgressUpdate,
    required this.onClaimReward,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (catalogQuest == null) {
      return const SizedBox.shrink();
    }

    final progress = playerQuest.conditions.isEmpty
        ? 0
        : ((playerQuest.conditions
                    .fold<int>(0, (sum, c) => sum + c.progressPercentage) /
                playerQuest.conditions.length) as double)
            .toInt();

    final cardBg = isDarkMode ? AppColors.darkCard : AppColors.lightCard;
    final textColor = isDarkMode ? AppColors.lightText : AppColors.darkText;
    final difficulty = catalogQuest!.difficulty;
    final difficultyColor = _getDifficultyColor(difficulty);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: cardBg,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Title + Difficulty
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        catalogQuest!.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        catalogQuest!.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode
                              ? AppColors.mutedText
                              : AppColors.darkText.withOpacity(0.7),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: difficultyColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _getDifficultyText(difficulty),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: difficultyColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Progress bar
            _buildProgressBar(progress, isDarkMode),
            const SizedBox(height: 8),

            // Progress text + Time remaining (for daily)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '進捗: $progress%',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? AppColors.mutedText : AppColors.darkText,
                  ),
                ),
                if (playerQuest.timeRemaining != null)
                  Text(
                    '残り: ${_formatTimeRemaining(playerQuest.timeRemaining!)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? AppColors.mutedText : AppColors.darkText,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Reward preview
            _buildRewardPreview(catalogQuest!.reward, isDarkMode),
            const SizedBox(height: 12),

            // Claim button (only if claimable)
            if (playerQuest.canClaimReward)
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  label: '報酬を受け取る',
                  onPressed: onClaimReward,
                ),
              )
            else if (playerQuest.isRewarded)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '報酬受取済み',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.gold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(int progress, bool isDarkMode) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: LinearProgressIndicator(
        value: progress / 100,
        minHeight: 8,
        backgroundColor: isDarkMode
            ? AppColors.darkBg.withOpacity(0.5)
            : AppColors.lightBg.withOpacity(0.5),
        valueColor: AlwaysStoppedAnimation<Color>(
          _getProgressColor(progress),
        ),
      ),
    );
  }

  Widget _buildRewardPreview(QuestReward reward, bool isDarkMode) {
    final textColor = isDarkMode ? AppColors.lightText : AppColors.darkText;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDarkMode
            ? AppColors.darkBg.withOpacity(0.3)
            : AppColors.lightCard.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.gold.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          if (reward.currency > 0)
            _buildRewardItem('💰', '${reward.currency}', textColor),
          if (reward.experiencePoints > 0)
            _buildRewardItem('⭐', '${reward.experiencePoints}', textColor),
          if (reward.achievementBadges > 0)
            _buildRewardItem('🏆', '${reward.achievementBadges}', textColor),
          if (reward.cosmetics.isNotEmpty)
            _buildRewardItem('🎨', '${reward.cosmetics.length}', textColor),
        ],
      ),
    );
  }

  Widget _buildRewardItem(String emoji, String value, Color textColor) {
    return Column(
      children: [
        Text(
          emoji,
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ],
    );
  }

  Color _getDifficultyColor(QuestDifficulty difficulty) {
    switch (difficulty) {
      case QuestDifficulty.easy:
        return Colors.green;
      case QuestDifficulty.normal:
        return Colors.blue;
      case QuestDifficulty.hard:
        return Colors.orange;
      case QuestDifficulty.extreme:
        return Colors.red;
    }
  }

  String _getDifficultyText(QuestDifficulty difficulty) {
    switch (difficulty) {
      case QuestDifficulty.easy:
        return '簡単';
      case QuestDifficulty.normal:
        return '普通';
      case QuestDifficulty.hard:
        return '難';
      case QuestDifficulty.extreme:
        return '極難';
    }
  }

  Color _getProgressColor(int progress) {
    if (progress < 25) return Colors.red;
    if (progress < 50) return Colors.orange;
    if (progress < 75) return Colors.yellow;
    if (progress < 100) return Colors.lightGreen;
    return AppColors.gold;
  }

  String _formatTimeRemaining(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    return '$hours時間${minutes}分';
  }
}
