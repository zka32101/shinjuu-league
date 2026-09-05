import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shinjuu_league/data/models/achievement.dart';
import 'package:shinjuu_league/services/achievement_service.dart';

/// State for achievement operations
class AchievementState {
  final List<PlayerAchievement> playerAchievements;
  final List<PlayerAchievement> unlockedAchievements;
  final bool isLoading;
  final String? error;
  final String? successMessage;
  final PlayerAchievement? lastUnlockedAchievement;

  AchievementState({
    this.playerAchievements = const [],
    this.unlockedAchievements = const [],
    this.isLoading = false,
    this.error,
    this.successMessage,
    this.lastUnlockedAchievement,
  });

  AchievementState copyWith({
    List<PlayerAchievement>? playerAchievements,
    List<PlayerAchievement>? unlockedAchievements,
    bool? isLoading,
    String? error,
    String? successMessage,
    PlayerAchievement? lastUnlockedAchievement,
  }) {
    return AchievementState(
      playerAchievements: playerAchievements ?? this.playerAchievements,
      unlockedAchievements: unlockedAchievements ?? this.unlockedAchievements,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successMessage: successMessage,
      lastUnlockedAchievement: lastUnlockedAchievement ?? this.lastUnlockedAchievement,
    );
  }
}

/// ViewModel for managing achievements
class AchievementViewModel extends StateNotifier<AchievementState> {
  final AchievementService _achievementService;
  final String _userId;

  AchievementViewModel(
    this._achievementService,
    this._userId,
  ) : super(AchievementState());

  /// Load all achievements for the current player
  Future<void> loadPlayerAchievements() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final achievements = await _achievementService.getPlayerAchievements(_userId);
      final unlocked = await _achievementService.getUnlockedAchievements(_userId);

      state = state.copyWith(
        playerAchievements: achievements,
        unlockedAchievements: unlocked,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Get achievement by ID
  Future<PlayerAchievement?> getAchievementById(String achievementId) async {
    try {
      return await _achievementService.getProgress(_userId, achievementId);
    } catch (e) {
      return null;
    }
  }

  /// Get achievements by category
  Future<List<PlayerAchievement>> getAchievementsByCategory(AchievementCategory category) async {
    try {
      return await _achievementService.getAchievementsByCategory(_userId, category);
    } catch (e) {
      return [];
    }
  }

  /// Get completion percentage
  Future<double> getCompletionPercentage() async {
    try {
      return await _achievementService.getCompletionPercentage(_userId);
    } catch (e) {
      return 0.0;
    }
  }

  /// Get unlock count
  Future<int> getUnlockedCount() async {
    try {
      return await _achievementService.getUnlockCount(_userId);
    } catch (e) {
      return 0;
    }
  }

  /// Get total available achievements
  int getTotalAvailableCount() {
    return _achievementService.getTotalAvailableCount();
  }

  /// Get achievement definition from catalog
  Achievement? getAchievementDefinition(String achievementId) {
    return AchievementsCatalog.getById(achievementId);
  }

  /// Get all achievements from catalog by category
  List<Achievement> getCatalogByCategory(AchievementCategory category) {
    return AchievementsCatalog.getByCategory(category);
  }

  /// Clear success message
  void clearSuccessMessage() {
    state = state.copyWith(successMessage: null);
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Clear last unlocked achievement (for hiding unlock notification)
  void clearLastUnlockedAchievement() {
    state = state.copyWith(lastUnlockedAchievement: null);
  }

  /// Get progress for specific achievement
  Future<int> getProgressPercentage(String achievementId) async {
    try {
      final achievement = await _achievementService.getProgress(_userId, achievementId);
      return achievement?.getProgressPercentage() ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Check if achievement is unlocked
  Future<bool> isAchievementUnlocked(String achievementId) async {
    try {
      final achievement = await _achievementService.getProgress(_userId, achievementId);
      return achievement?.isUnlocked ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Get all achievements by category with progress
  Future<List<(Achievement, PlayerAchievement?)>> getAchievementsWithProgress(
    AchievementCategory category,
  ) async {
    try {
      final catalogAchievements = AchievementsCatalog.getByCategory(category);
      final result = <(Achievement, PlayerAchievement?)>[];

      for (final achievement in catalogAchievements) {
        final playerAchievement = await _achievementService.getProgress(
          _userId,
          achievement.achievementId,
        );
        result.add((achievement, playerAchievement));
      }

      return result;
    } catch (e) {
      return [];
    }
  }
}

/// Riverpod provider for achievement service
final achievementServiceProvider = Provider<AchievementService>((ref) {
  throw UnimplementedError(
    'achievementServiceProvider must be provided by the application',
  );
});

/// Riverpod provider for achievement view model
final achievementViewModelProvider = StateNotifierProvider.family.autoDispose<
    AchievementViewModel,
    AchievementState,
    String>((ref, userId) {
  final achievementService = ref.watch(achievementServiceProvider);
  return AchievementViewModel(achievementService, userId);
});

/// Provider to get all achievements with progress
final achievementsWithProgressProvider =
    FutureProvider.family.autoDispose<
        List<(Achievement, PlayerAchievement?)>,
        (String, AchievementCategory)>((ref, args) async {
  final (userId, category) = args;
  final achievementService = ref.watch(achievementServiceProvider);
  final catalogAchievements = AchievementsCatalog.getByCategory(category);
  final result = <(Achievement, PlayerAchievement?)>[];

  for (final achievement in catalogAchievements) {
    final playerAchievement = await achievementService.getProgress(
      userId,
      achievement.achievementId,
    );
    result.add((achievement, playerAchievement));
  }

  return result;
});

/// Provider to get completion percentage
final achievementCompletionProvider = FutureProvider.family.autoDispose<double, String>(
  (ref, userId) async {
    final achievementService = ref.watch(achievementServiceProvider);
    return achievementService.getCompletionPercentage(userId);
  },
);

/// Provider to get unlock count
final achievementUnlockCountProvider = FutureProvider.family.autoDispose<int, String>(
  (ref, userId) async {
    final achievementService = ref.watch(achievementServiceProvider);
    return achievementService.getUnlockCount(userId);
  },
);
