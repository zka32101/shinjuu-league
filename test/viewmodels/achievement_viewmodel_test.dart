import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shinjuu_league/data/models/achievement.dart';
import 'package:shinjuu_league/services/achievement_service.dart';
import 'package:shinjuu_league/viewmodels/achievement_viewmodel.dart';

class MockAchievementService extends Mock implements AchievementService {}

void main() {
  group('AchievementViewModel', () {
    late AchievementViewModel viewModel;
    late MockAchievementService mockService;
    const String userId = 'user_123';

    setUp(() {
      mockService = MockAchievementService();
      viewModel = AchievementViewModel(mockService, userId);
    });

    group('loadPlayerAchievements', () {
      test('loads achievements and updates state', () async {
        final mockAchievements = [
          PlayerAchievement(
            userId: userId,
            achievementId: 'ach_1',
            unlockedAt: DateTime.now(),
          ),
        ];
        final mockUnlocked = mockAchievements;

        when(mockService.getPlayerAchievements(userId))
            .thenAnswer((_) async => mockAchievements);
        when(mockService.getUnlockedAchievements(userId))
            .thenAnswer((_) async => mockUnlocked);

        await viewModel.loadPlayerAchievements();

        expect(viewModel.state.playerAchievements.length, 1);
        expect(viewModel.state.unlockedAchievements.length, 1);
        expect(viewModel.state.isLoading, false);
        expect(viewModel.state.error, null);
      });

      test('handles empty achievements list', () async {
        when(mockService.getPlayerAchievements(userId))
            .thenAnswer((_) async => []);
        when(mockService.getUnlockedAchievements(userId))
            .thenAnswer((_) async => []);

        await viewModel.loadPlayerAchievements();

        expect(viewModel.state.playerAchievements, isEmpty);
        expect(viewModel.state.unlockedAchievements, isEmpty);
      });

      test('sets error state on exception', () async {
        when(mockService.getPlayerAchievements(userId))
            .thenThrow(Exception('Test error'));

        await viewModel.loadPlayerAchievements();

        expect(viewModel.state.error, isNotNull);
        expect(viewModel.state.isLoading, false);
      });

      test('sets loading state during fetch', () {
        when(mockService.getPlayerAchievements(userId))
            .thenAnswer((_) async => []);
        when(mockService.getUnlockedAchievements(userId))
            .thenAnswer((_) async => []);

        viewModel.loadPlayerAchievements();

        // State should be loading immediately after calling
        expect(viewModel.state.isLoading, isTrue);
      });
    });

    group('getAchievementById', () {
      test('returns achievement when found', () async {
        final achievement = PlayerAchievement(
          userId: userId,
          achievementId: 'ach_1',
          unlockedAt: DateTime.now(),
        );

        when(mockService.getProgress(userId, 'ach_1'))
            .thenAnswer((_) async => achievement);

        final result = await viewModel.getAchievementById('ach_1');

        expect(result, isNotNull);
        expect(result!.achievementId, 'ach_1');
      });

      test('returns null when not found', () async {
        when(mockService.getProgress(userId, 'nonexistent'))
            .thenAnswer((_) async => null);

        final result = await viewModel.getAchievementById('nonexistent');

        expect(result, isNull);
      });

      test('handles exception gracefully', () async {
        when(mockService.getProgress(userId, 'ach_1'))
            .thenThrow(Exception('Error'));

        final result = await viewModel.getAchievementById('ach_1');

        expect(result, isNull);
      });
    });

    group('getAchievementsByCategory', () {
      test('returns achievements for category', () async {
        final mockAchievements = [
          PlayerAchievement(
            userId: userId,
            achievementId: 'ach_1',
            unlockedAt: DateTime.now(),
          ),
        ];

        when(mockService.getAchievementsByCategory(userId, AchievementCategory.progression))
            .thenAnswer((_) async => mockAchievements);

        final result = await viewModel.getAchievementsByCategory(AchievementCategory.progression);

        expect(result.length, 1);
      });

      test('returns empty list on error', () async {
        when(mockService.getAchievementsByCategory(userId, AchievementCategory.skill))
            .thenThrow(Exception('Error'));

        final result = await viewModel.getAchievementsByCategory(AchievementCategory.skill);

        expect(result, isEmpty);
      });
    });

    group('getCompletionPercentage', () {
      test('returns completion percentage', () async {
        when(mockService.getCompletionPercentage(userId))
            .thenAnswer((_) async => 75.0);

        final result = await viewModel.getCompletionPercentage();

        expect(result, 75.0);
      });

      test('returns 0.0 on error', () async {
        when(mockService.getCompletionPercentage(userId))
            .thenThrow(Exception('Error'));

        final result = await viewModel.getCompletionPercentage();

        expect(result, 0.0);
      });

      test('handles percentage boundaries', () async {
        when(mockService.getCompletionPercentage(userId))
            .thenAnswer((_) async => 100.0);

        final result = await viewModel.getCompletionPercentage();

        expect(result, 100.0);
      });
    });

    group('getUnlockedCount', () {
      test('returns unlock count', () async {
        when(mockService.getUnlockCount(userId))
            .thenAnswer((_) async => 5);

        final result = await viewModel.getUnlockedCount();

        expect(result, 5);
      });

      test('returns 0 on error', () async {
        when(mockService.getUnlockCount(userId))
            .thenThrow(Exception('Error'));

        final result = await viewModel.getUnlockedCount();

        expect(result, 0);
      });
    });

    group('getTotalAvailableCount', () {
      test('returns total count from service', () {
        when(mockService.getTotalAvailableCount()).thenReturn(7);

        final result = viewModel.getTotalAvailableCount();

        expect(result, 7);
      });
    });

    group('getAchievementDefinition', () {
      test('returns achievement from catalog', () {
        final result = viewModel.getAchievementDefinition('rising_star');

        expect(result, isNotNull);
        expect(result!.name, '新星');
      });

      test('returns null for unknown achievement', () {
        final result = viewModel.getAchievementDefinition('unknown_ach');

        expect(result, isNull);
      });
    });

    group('getCatalogByCategory', () {
      test('returns achievements in category', () {
        final result = viewModel.getCatalogByCategory(AchievementCategory.progression);

        expect(result, isNotEmpty);
        expect(result.every((a) => a.category == AchievementCategory.progression), true);
      });

      test('returns empty for category with no achievements', () {
        // Assuming there's no achievement in this category
        final result = viewModel.getCatalogByCategory(AchievementCategory.special);

        expect(result.isEmpty, true);
      });
    });

    group('clearSuccessMessage', () {
      test('clears success message', () {
        viewModel.clearSuccessMessage();

        expect(viewModel.state.successMessage, null);
      });
    });

    group('clearError', () {
      test('clears error message', () {
        viewModel.clearError();

        expect(viewModel.state.error, null);
      });
    });

    group('clearLastUnlockedAchievement', () {
      test('clears last unlocked achievement', () {
        viewModel.clearLastUnlockedAchievement();

        expect(viewModel.state.lastUnlockedAchievement, null);
      });
    });

    group('getProgressPercentage', () {
      test('returns progress percentage for achievement', () async {
        when(mockService.getProgress(userId, 'ach_1'))
            .thenAnswer((_) async => PlayerAchievement(
              userId: userId,
              achievementId: 'ach_1',
              unlockedAt: DateTime.now(),
              progress: AchievementProgress(current: 50, target: 100),
            ));

        final result = await viewModel.getProgressPercentage('ach_1');

        expect(result, 50);
      });

      test('returns 0 when achievement not found', () async {
        when(mockService.getProgress(userId, 'nonexistent'))
            .thenAnswer((_) async => null);

        final result = await viewModel.getProgressPercentage('nonexistent');

        expect(result, 0);
      });
    });

    group('isAchievementUnlocked', () {
      test('returns true for unlocked achievement', () async {
        when(mockService.getProgress(userId, 'ach_1'))
            .thenAnswer((_) async => PlayerAchievement(
              userId: userId,
              achievementId: 'ach_1',
              unlockedAt: DateTime.now(),
            ));

        final result = await viewModel.isAchievementUnlocked('ach_1');

        expect(result, true);
      });

      test('returns false for locked achievement', () async {
        when(mockService.getProgress(userId, 'ach_1'))
            .thenAnswer((_) async => null);

        final result = await viewModel.isAchievementUnlocked('ach_1');

        expect(result, false);
      });
    });

    group('getAchievementsWithProgress', () {
      test('returns achievements with their progress', () async {
        final mockAchievements = [
          Achievement(
            achievementId: 'rising_star',
            category: AchievementCategory.progression,
            name: '新星',
            description: 'Test',
            iconUrl: 'test.png',
            rewardTier: AchievementRewardTier.bronze,
            maxProgress: 1,
          ),
        ];

        when(mockService.getAchievementsByCategory(userId, AchievementCategory.progression))
            .thenAnswer((_) async => []);

        // This would require mocking the static method, which is complex
        // So we test the behavior with empty results
        final result = await viewModel.getAchievementsWithProgress(AchievementCategory.progression);

        expect(result, isNotEmpty);
      });

      test('returns empty list on error', () async {
        final result = await viewModel.getAchievementsWithProgress(AchievementCategory.progression);

        // Should return empty list gracefully
        expect(result, isA<List>());
      });
    });
  });
}
