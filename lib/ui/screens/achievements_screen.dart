import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shinjuu_league/config/theme.dart';
import 'package:shinjuu_league/data/models/achievement.dart';
import 'package:shinjuu_league/services/achievement_service.dart';
import 'package:shinjuu_league/data/providers/service_providers.dart';

/// Achievement collection/gallery screen showing all available achievements
/// Displays achievement status, progress, rewards, and unlock dates
class AchievementsScreen extends ConsumerStatefulWidget {
  const AchievementsScreen({super.key});

  @override
  ConsumerState<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends ConsumerState<AchievementsScreen> {
  late String _selectedCategory = AchievementCategory.milestone.name;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('成果'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Category filter tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _CategoryTab(
                    label: 'すべて',
                    isSelected: _selectedCategory == 'all',
                    onTap: () {
                      setState(() => _selectedCategory = 'all');
                    },
                  ),
                  const SizedBox(width: 8),
                  for (final category in AchievementCategory.values)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _CategoryTab(
                        label: _categoryLabel(category),
                        isSelected: _selectedCategory == category.name,
                        onTap: () {
                          setState(() => _selectedCategory = category.name);
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Achievements grid
          Expanded(
            child: FutureBuilder<List<Achievement>>(
              future: _getAchievements(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('エラー: ${snapshot.error}'),
                  );
                }

                final achievements = snapshot.data ?? [];
                if (achievements.isEmpty) {
                  return const Center(
                    child: Text('成果がありません'),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.0,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: achievements.length,
                  itemBuilder: (context, index) {
                    final achievement = achievements[index];
                    return _AchievementGridCard(
                      achievement: achievement,
                      onTap: () {
                        _showAchievementDetail(context, achievement);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<List<Achievement>> _getAchievements() async {
    // TODO: Fetch actual achievements from AchievementService
    // For now, return sample achievements
    return [
      Achievement(
        achievementId: 'aha_moment',
        category: AchievementCategory.milestone,
        name: 'Aha Moment',
        description: 'Get your first kill',
        iconUrl: 'assets/icons/aha_moment.png',
        rewardTier: AchievementRewardTier.common,
        maxProgress: 1,
        isProgressBased: false,
      ),
      Achievement(
        achievementId: 'rising_star',
        category: AchievementCategory.milestone,
        name: 'Rising Star',
        description: 'Win your first battle',
        iconUrl: 'assets/icons/rising_star.png',
        rewardTier: AchievementRewardTier.uncommon,
        maxProgress: 1,
        isProgressBased: false,
      ),
      Achievement(
        achievementId: 'stat_master',
        category: AchievementCategory.progression,
        name: 'Stat Master',
        description: 'Collect 50 stat points',
        iconUrl: 'assets/icons/stat_master.png',
        rewardTier: AchievementRewardTier.rare,
        maxProgress: 50,
        isProgressBased: true,
      ),
      Achievement(
        achievementId: 'balanced_fighter',
        category: AchievementCategory.progression,
        name: 'Balanced Fighter',
        description: 'Unlock 3 different skill paths',
        iconUrl: 'assets/icons/balanced_fighter.png',
        rewardTier: AchievementRewardTier.rare,
        maxProgress: 3,
        isProgressBased: true,
      ),
      Achievement(
        achievementId: 'season_warrior',
        category: AchievementCategory.seasonal,
        name: 'Season Warrior',
        description: 'Participate in 10 seasons',
        iconUrl: 'assets/icons/season_warrior.png',
        rewardTier: AchievementRewardTier.epic,
        maxProgress: 10,
        isProgressBased: true,
      ),
      Achievement(
        achievementId: 'consistency',
        category: AchievementCategory.seasonal,
        name: 'Consistency',
        description: 'Reach Gold tier for 3 consecutive seasons',
        iconUrl: 'assets/icons/consistency.png',
        rewardTier: AchievementRewardTier.legendary,
        maxProgress: 3,
        isProgressBased: true,
      ),
    ];
  }

  void _showAchievementDetail(
    BuildContext context,
    Achievement achievement,
  ) {
    showDialog(
      context: context,
      builder: (context) => _AchievementDetailDialog(achievement: achievement),
    );
  }

  String _categoryLabel(AchievementCategory category) {
    switch (category) {
      case AchievementCategory.milestone:
        return 'マイルストーン';
      case AchievementCategory.progression:
        return '進行';
      case AchievementCategory.seasonal:
        return 'シーズン';
      case AchievementCategory.special:
        return 'スペシャル';
    }
  }
}

/// Category filter tab widget
class _CategoryTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.gold : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

/// Achievement grid card widget
class _AchievementGridCard extends StatelessWidget {
  final Achievement achievement;
  final VoidCallback onTap;

  const _AchievementGridCard({
    required this.achievement,
    required this.onTap,
  });

  Color _getRewardTierColor(AchievementRewardTier tier) {
    switch (tier) {
      case AchievementRewardTier.common:
        return const Color(0xFF808080);
      case AchievementRewardTier.uncommon:
        return const Color(0xFF00AA00);
      case AchievementRewardTier.rare:
        return const Color(0xFF0099FF);
      case AchievementRewardTier.epic:
        return const Color(0xFF9933FF);
      case AchievementRewardTier.legendary:
        return const Color(0xFFFFAA00);
      case AchievementRewardTier.mythic:
        return const Color(0xFFFF0000);
      case AchievementRewardTier.silver:
        return const Color(0xFFC0C0C0);
      case AchievementRewardTier.gold:
        return const Color(0xFFFFD700);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tierColor = _getRewardTierColor(achievement.rewardTier);

    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: tierColor.withOpacity(0.5),
            width: 2,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                tierColor.withOpacity(0.1),
                tierColor.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '🏆',
                style: TextStyle(fontSize: 40),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  achievement.name,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: tierColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _tierLabel(achievement.rewardTier),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        color: tierColor,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _tierLabel(AchievementRewardTier tier) {
    switch (tier) {
      case AchievementRewardTier.common:
        return 'コモン';
      case AchievementRewardTier.uncommon:
        return 'アンコモン';
      case AchievementRewardTier.rare:
        return 'レア';
      case AchievementRewardTier.epic:
        return 'エピック';
      case AchievementRewardTier.legendary:
        return 'レジェンダリー';
      case AchievementRewardTier.mythic:
        return 'ミシック';
      case AchievementRewardTier.silver:
        return 'シルバー';
      case AchievementRewardTier.gold:
        return 'ゴールド';
    }
  }
}

/// Achievement detail dialog
class _AchievementDetailDialog extends StatelessWidget {
  final Achievement achievement;

  const _AchievementDetailDialog({required this.achievement});

  Color _getRewardTierColor(AchievementRewardTier tier) {
    switch (tier) {
      case AchievementRewardTier.common:
        return const Color(0xFF808080);
      case AchievementRewardTier.uncommon:
        return const Color(0xFF00AA00);
      case AchievementRewardTier.rare:
        return const Color(0xFF0099FF);
      case AchievementRewardTier.epic:
        return const Color(0xFF9933FF);
      case AchievementRewardTier.legendary:
        return const Color(0xFFFFAA00);
      case AchievementRewardTier.mythic:
        return const Color(0xFFFF0000);
      case AchievementRewardTier.silver:
        return const Color(0xFFC0C0C0);
      case AchievementRewardTier.gold:
        return const Color(0xFFFFD700);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tierColor = _getRewardTierColor(achievement.rewardTier);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              tierColor.withOpacity(0.1),
              tierColor.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: tierColor.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '🏆',
                  style: TextStyle(fontSize: 56),
                ),
                const SizedBox(height: 16),
                Text(
                  achievement.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: tierColor,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: tierColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _tierLabel(achievement.rewardTier),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: tierColor,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  achievement.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                if (achievement.isProgressBased) ...[
                  const SizedBox(height: 16),
                  Text(
                    '進捗: 0/${achievement.maxProgress}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: 0,
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation<Color>(tierColor),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('閉じる'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _tierLabel(AchievementRewardTier tier) {
    switch (tier) {
      case AchievementRewardTier.common:
        return 'コモン';
      case AchievementRewardTier.uncommon:
        return 'アンコモン';
      case AchievementRewardTier.rare:
        return 'レア';
      case AchievementRewardTier.epic:
        return 'エピック';
      case AchievementRewardTier.legendary:
        return 'レジェンダリー';
      case AchievementRewardTier.mythic:
        return 'ミシック';
      case AchievementRewardTier.silver:
        return 'シルバー';
      case AchievementRewardTier.gold:
        return 'ゴールド';
    }
  }
}
