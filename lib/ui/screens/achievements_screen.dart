import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shinjuu_league/config/theme.dart';
import 'package:shinjuu_league/data/models/achievement.dart';
import 'package:shinjuu_league/services/achievement_trigger_detector.dart'
    show tierAtLeast;
import 'package:shinjuu_league/services/auth_service.dart';
import 'package:shinjuu_league/services/ranking_service.dart';
import 'package:shinjuu_league/services/skill_tree_service.dart';
import 'package:shinjuu_league/viewmodels/achievement_viewmodel.dart';

/// Achievement collection/gallery screen showing all available achievements
/// Displays achievement status, progress, rewards, and unlock dates
///
/// Previously this screen's grid was entirely backed by a hard-coded sample
/// list (with a literal `// TODO: Fetch actual achievements from
/// AchievementService`), and the route to reach it (AppRoutes.achievements)
/// was defined in app_routes.dart but never linked from anywhere in the
/// app's navigation - nothing ever pushed it. Both are fixed here: the grid
/// now reflects real per-player unlock state via AchievementViewModel, and
/// lobby_screen.dart links to this route.
class AchievementsScreen extends ConsumerStatefulWidget {
  const AchievementsScreen({super.key, this.userIdOverride});

  /// Test-only seam: supplies the user ID directly instead of resolving it
  /// from AuthService()/FirebaseAuth (which requires Firebase.initializeApp()
  /// to have run - not something most widget tests in this suite do).
  final String? userIdOverride;

  @override
  ConsumerState<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends ConsumerState<AchievementsScreen> {
  String _selectedCategory = 'all';
  String? _userId;

  // Live progress toward not-yet-unlocked, progress-based achievements.
  // This is never persisted (see AchievementService.getPlayerAchievements's
  // doc comment - a document in the achievements subcollection only ever
  // exists for a genuine unlock), so it's recomputed here the same way
  // BattleViewModel._checkAchievementTriggers computes it: from the live
  // skill tree and season history, not from any stored "progress" field.
  Map<String, int> _liveProgress = const {};

  @override
  void initState() {
    super.initState();
    final userId = widget.userIdOverride ?? _resolveCurrentUserId();
    _userId = userId;
    if (userId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref
            .read(achievementViewModelProvider(userId).notifier)
            .loadPlayerAchievements();
      });
      _loadLiveProgress(userId);
    }
  }

  /// FirebaseAuth.instance throws (rather than returning null) when
  /// Firebase.initializeApp() hasn't run - true of most widget tests in
  /// this suite. Falling back to null here (rendered as "ログインが必要です")
  /// keeps that a graceful, testable state instead of a crash.
  String? _resolveCurrentUserId() {
    try {
      return AuthService().currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadLiveProgress(String userId) async {
    try {
      final skillTree = await SkillTreeService().getSkillTree(userId);
      final statPoints = skillTree == null
          ? 0
          : skillTree.trees
                .map((branch) => branch.allocatedTiers)
                .reduce((a, b) => a > b ? a : b);
      final pathDiversity =
          skillTree?.trees
              .where((branch) => branch.allocatedTiers > 0)
              .length ??
          0;

      final seasonHistory = await RankingService().getSeasonHistory(userId);
      final seasonsParticipated = seasonHistory.length;
      var consistentSeasons = 0;
      for (final season in seasonHistory.reversed) {
        if (!tierAtLeast(season.peakTier, 'Gold')) break;
        consistentSeasons++;
      }

      if (!mounted) return;
      setState(() {
        _liveProgress = {
          'stat_master': statPoints,
          'balanced_fighter': pathDiversity,
          'season_warrior': seasonsParticipated,
          'consistency': consistentSeasons,
        };
      });
    } catch (e) {
      // Live progress is a display-only nicety - if it fails to load,
      // achievements just show 0 progress rather than breaking the screen.
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = _userId;

    return Scaffold(
      appBar: AppBar(title: const Text('成果'), centerTitle: true),
      body: userId == null
          ? const Center(child: Text('ログインが必要です'))
          : Column(
              children: [
                _buildCategoryTabs(),
                Expanded(child: _buildGrid(userId)),
              ],
            ),
    );
  }

  Widget _buildCategoryTabs() {
    return SingleChildScrollView(
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
    );
  }

  Widget _buildGrid(String userId) {
    final achievementState = ref.watch(achievementViewModelProvider(userId));

    if (achievementState.isLoading &&
        achievementState.playerAchievements.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (achievementState.error != null) {
      return Center(child: Text('エラー: ${achievementState.error}'));
    }

    final unlockedIds = achievementState.playerAchievements
        .where((a) => a.isUnlocked)
        .map((a) => a.achievementId)
        .toSet();

    final achievements = AchievementsCatalog.all
        .where((a) => a.isAvailable)
        .where(
          (a) =>
              _selectedCategory == 'all' ||
              a.category.name == _selectedCategory,
        )
        .toList();

    if (achievements.isEmpty) {
      return const Center(child: Text('成果がありません'));
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
        final isUnlocked = unlockedIds.contains(achievement.achievementId);
        return _AchievementGridCard(
          achievement: achievement,
          isUnlocked: isUnlocked,
          onTap: () {
            _showAchievementDetail(context, achievement, isUnlocked);
          },
        );
      },
    );
  }

  void _showAchievementDetail(
    BuildContext context,
    Achievement achievement,
    bool isUnlocked,
  ) {
    showDialog(
      context: context,
      builder: (context) => _AchievementDetailDialog(
        achievement: achievement,
        isUnlocked: isUnlocked,
        currentProgress: _liveProgress[achievement.achievementId] ?? 0,
      ),
    );
  }

  String _categoryLabel(AchievementCategory category) {
    switch (category) {
      case AchievementCategory.milestone:
        return 'マイルストーン';
      case AchievementCategory.progression:
        return '進行';
      case AchievementCategory.skill:
        return 'スキル';
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
  final bool isUnlocked;
  final VoidCallback onTap;

  const _AchievementGridCard({
    required this.achievement,
    required this.isUnlocked,
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
      case AchievementRewardTier.bronze:
        return const Color(0xFFCD7F32);
      case AchievementRewardTier.silver:
        return const Color(0xFFC0C0C0);
      case AchievementRewardTier.gold:
        return const Color(0xFFFFD700);
      case AchievementRewardTier.platinum:
        return const Color(0xFFE5E4E2);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tierColor = _getRewardTierColor(achievement.rewardTier);
    // Locked achievements render dimmed/grayscale so unlocked ones stand
    // out at a glance, without hiding what's still available to pursue.
    final opacity = isUnlocked ? 1.0 : 0.4;

    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: opacity,
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: tierColor.withValues(alpha: 0.5), width: 2),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  tierColor.withValues(alpha: 0.1),
                  tierColor.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isUnlocked ? '🏆' : '🔒',
                  style: const TextStyle(fontSize: 40),
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
                    color: tierColor.withValues(alpha: 0.2),
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
      case AchievementRewardTier.bronze:
        return 'ブロンズ';
      case AchievementRewardTier.silver:
        return 'シルバー';
      case AchievementRewardTier.gold:
        return 'ゴールド';
      case AchievementRewardTier.platinum:
        return 'プラチナ';
    }
  }
}

/// Achievement detail dialog
class _AchievementDetailDialog extends StatelessWidget {
  final Achievement achievement;
  final bool isUnlocked;
  final int currentProgress;

  const _AchievementDetailDialog({
    required this.achievement,
    required this.isUnlocked,
    required this.currentProgress,
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
      case AchievementRewardTier.bronze:
        return const Color(0xFFCD7F32);
      case AchievementRewardTier.silver:
        return const Color(0xFFC0C0C0);
      case AchievementRewardTier.gold:
        return const Color(0xFFFFD700);
      case AchievementRewardTier.platinum:
        return const Color(0xFFE5E4E2);
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
              tierColor.withValues(alpha: 0.1),
              tierColor.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: tierColor.withValues(alpha: 0.3), width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isUnlocked ? '🏆' : '🔒',
                  style: const TextStyle(fontSize: 56),
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
                    color: tierColor.withValues(alpha: 0.2),
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
                if (achievement.isProgressBased && !isUnlocked) ...[
                  const SizedBox(height: 16),
                  Text(
                    '進捗: $currentProgress/${achievement.maxProgress}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (currentProgress / achievement.maxProgress).clamp(
                        0.0,
                        1.0,
                      ),
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
      case AchievementRewardTier.bronze:
        return 'ブロンズ';
      case AchievementRewardTier.silver:
        return 'シルバー';
      case AchievementRewardTier.gold:
        return 'ゴールド';
      case AchievementRewardTier.platinum:
        return 'プラチナ';
    }
  }
}
