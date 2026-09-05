import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shinjuu_league/data/models/achievement.dart';
import 'package:shinjuu_league/viewmodels/achievement_viewmodel.dart';
import 'package:shinjuu_league/viewmodels/user_viewmodel.dart';

/// Screen displaying all achievements
class AchievementsScreen extends ConsumerStatefulWidget {
  const AchievementsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends ConsumerState<AchievementsScreen> {
  AchievementCategory _selectedCategory = AchievementCategory.progression;

  @override
  void initState() {
    super.initState();
    // Load achievements on screen load
    Future.microtask(() {
      final userId = ref.read(userViewModelProvider).userId ?? '';
      if (userId.isNotEmpty) {
        ref
            .read(achievementViewModelProvider(userId).notifier)
            .loadPlayerAchievements();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userViewModelProvider);
    final userId = userState.userId ?? '';

    if (userId.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('成果'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final achievementState = ref.watch(achievementViewModelProvider(userId));
    final achievementNotifier =
        ref.read(achievementViewModelProvider(userId).notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('成果'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Category tabs
          SizedBox(
            height: 60,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: AchievementCategory.values
                  .map((category) => _buildCategoryTab(category))
                  .toList(),
            ),
          ),

          // Achievements grid
          Expanded(
            child: achievementState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : achievementState.error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 48),
                            const SizedBox(height: 12),
                            Text(achievementState.error ?? 'エラーが発生しました'),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () {
                                achievementNotifier.loadPlayerAchievements();
                              },
                              child: const Text('再読み込み'),
                            ),
                          ],
                        ),
                      )
                    : _buildAchievementsGrid(
                        achievementNotifier,
                        userId,
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTab(AchievementCategory category) {
    final categoryNames = {
      AchievementCategory.progression: '進行',
      AchievementCategory.milestone: 'マイルストーン',
      AchievementCategory.skill: 'スキル',
      AchievementCategory.seasonal: 'シーズン',
      AchievementCategory.special: 'スペシャル',
    };

    final isSelected = _selectedCategory == category;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: FilterChip(
        label: Text(categoryNames[category] ?? ''),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            setState(() {
              _selectedCategory = category;
            });
          }
        },
        backgroundColor: Theme.of(context).colorScheme.surface,
        selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
      ),
    );
  }

  Widget _buildAchievementsGrid(
    AchievementViewModel viewModel,
    String userId,
  ) {
    return FutureBuilder<List<(Achievement, PlayerAchievement?)>>(
      future: viewModel.getAchievementsWithProgress(_selectedCategory),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('エラー: ${snapshot.error}'));
        }

        final achievements = snapshot.data ?? [];

        if (achievements.isEmpty) {
          return Center(
            child: Text(
              'この カテゴリの成果はまだありません',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.8,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: achievements.length,
          itemBuilder: (context, index) {
            final (achievement, playerAchievement) = achievements[index];
            return _buildAchievementCard(achievement, playerAchievement);
          },
        );
      },
    );
  }

  Widget _buildAchievementCard(
    Achievement achievement,
    PlayerAchievement? playerAchievement,
  ) {
    final isUnlocked = playerAchievement?.isUnlocked ?? false;
    final progress = playerAchievement?.progress;

    final tierColors = {
      AchievementRewardTier.bronze: const Color(0xFFCD7F32),
      AchievementRewardTier.silver: const Color(0xFFC0C0C0),
      AchievementRewardTier.gold: const Color(0xFFFFD700),
      AchievementRewardTier.platinum: const Color(0xFFE5E4E2),
    };

    return Card(
      elevation: isUnlocked ? 4 : 1,
      color: isUnlocked
          ? Theme.of(context).colorScheme.surface
          : Theme.of(context).colorScheme.surface.withOpacity(0.5),
      child: InkWell(
        onTap: () => _showAchievementDetail(achievement, playerAchievement),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon/Badge area
              Expanded(
                child: Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: tierColors[achievement.rewardTier]?.withOpacity(
                            isUnlocked ? 1.0 : 0.3,
                          ) ??
                          Colors.grey.withOpacity(0.3),
                      border: Border.all(
                        color: tierColors[achievement.rewardTier] ?? Colors.grey,
                        width: isUnlocked ? 2 : 1,
                      ),
                    ),
                    child: isUnlocked
                        ? const Icon(Icons.check_circle, size: 40, color: Colors.white)
                        : Icon(
                            Icons.lock_outline,
                            size: 40,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Achievement name
              Text(
                achievement.name,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isUnlocked
                          ? Theme.of(context).colorScheme.onSurface
                          : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 4),

              // Progress bar (if progress-based)
              if (achievement.isProgressBased && progress != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: progress.percentage / 100,
                    minHeight: 4,
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      tierColors[achievement.rewardTier] ?? Colors.blue,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${progress.current}/${progress.target}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                      ),
                ),
              ] else if (!isUnlocked && achievement.unlockedAfter != null)
                Text(
                  '後でロック解除',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        color: Colors.orange,
                      ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAchievementDetail(
    Achievement achievement,
    PlayerAchievement? playerAchievement,
  ) {
    final tierColors = {
      AchievementRewardTier.bronze: const Color(0xFFCD7F32),
      AchievementRewardTier.silver: const Color(0xFFC0C0C0),
      AchievementRewardTier.gold: const Color(0xFFFFD700),
      AchievementRewardTier.platinum: const Color(0xFFE5E4E2),
    };

    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: tierColors[achievement.rewardTier],
                  ),
                  child: const Center(
                    child: Icon(Icons.star, color: Colors.white, size: 28),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        achievement.name,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        achievement.description,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Status
            if (playerAchievement != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      playerAchievement.isUnlocked ? '✅ ロック解除済み' : '🔒 ロック済み',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    if (playerAchievement.progress != null)
                      Text(
                        '${playerAchievement.progress!.percentage}%',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // Rewards
            Text(
              '報酬',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text('💰'),
                    const SizedBox(height: 4),
                    Text(
                      '+${achievement.getRewardCurrency()}',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    const Text('🏅'),
                    const SizedBox(height: 4),
                    Text(
                      '+${achievement.getRewardBadges()}',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
