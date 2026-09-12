import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shinjuu_league/data/models/achievement.dart';
import 'package:shinjuu_league/services/achievement_analytics_integration.dart';
import 'package:shinjuu_league/services/achievement_service.dart';
import 'package:shinjuu_league/services/analytics_service.dart';

class MockAchievementService extends Mock implements AchievementService {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

void main() {
  group('AchievementAnalyticsIntegration', () {
    late AchievementAnalyticsIntegration integration;
    late MockAchievementService mockAchievementService;
    late MockAnalyticsService mockAnalyticsService;
    const String userId = 'user_123';

    final testAchievement = Achievement(
      achievementId: 'rising_star',
      category: AchievementCategory.progression,
      name: '新星',
      description: 'シルバーティアに到達',
      iconUrl: 'assets/achievements/rising_star.png',
      rewardTier: AchievementRewardTier.bronze,
      maxProgress: 1,
      isProgressBased: false,
    );

    final testPlayerAchievement = PlayerAchievement(
      userId: userId,
      achievementId: 'rising_star',
      unlockedAt: DateTime.now(),
    );

    setUp(() {
      mockAchievementService = MockAchievementService();
      mockAnalyticsService = MockAnalyticsService();
      integration = AchievementAnalyticsIntegration(
        achievementService: mockAchievementService,
        analyticsService: mockAnalyticsService,
      );
    });

    group('trackAchievementUnlock', () {
      test('emits achievement_unlocked event with correct parameters', () async {
        await integration.trackAchievementUnlock(
          userId,
          testAchievement,
          testPlayerAchievement,
        );

        verify(mockAnalyticsService.logAchievementUnlocked(
          userId,
          'rising_star',
          'common',
        )).called(1);
      });

      test('emits reward_claimed event for instant unlock achievements', () async {
        await integration.trackAchievementUnlock(
          userId,
          testAchievement,
          testPlayerAchievement,
        );

        verify(mockAnalyticsService.logAchievementRewardClaimed(
          userId,
          'rising_star',
          'bronze',
          testAchievement.getRewardCurrency(),
          testAchievement.getRewardBadges(),
        )).called(1);
      });

      test('does not emit reward_claimed for progress-based achievements', () async {
        final progressAchievement = Achievement(
          achievementId: 'stat_master',
          category: AchievementCategory.skill,
          name: 'ステータスマスター',
          description: 'Test',
          iconUrl: 'test.png',
          rewardTier: AchievementRewardTier.silver,
          maxProgress: 50,
          isProgressBased: true,
        );

        final progressPlayerAchievement = PlayerAchievement(
          userId: userId,
          achievementId: 'stat_master',
          unlockedAt: DateTime.now(),
          progress: AchievementProgress(current: 50, target: 50),
        );

        await integration.trackAchievementUnlock(
          userId,
          progressAchievement,
          progressPlayerAchievement,
        );

        verify(mockAnalyticsService.logAchievementUnlocked(
          userId,
          'stat_master',
          'uncommon',
        )).called(1);

        // Should NOT call logAchievementRewardClaimed for progress-based
        verifyNever(mockAnalyticsService.logAchievementRewardClaimed(
          any,
          any,
          any,
          any,
          any,
        ));
      });

      test('handles errors gracefully', () async {
        when(mockAnalyticsService.logAchievementUnlocked(
          any,
          any,
          any,
        )).thenThrow(Exception('Analytics error'));

        // Should not throw
        await integration.trackAchievementUnlock(
          userId,
          testAchievement,
          testPlayerAchievement,
        );

        // Should record error
        verify(mockAnalyticsService.recordError(
          any,
          any,
          reason: anyNamed('reason'),
          information: anyNamed('information'),
        )).called(1);
      });

      test('maps all reward tiers to correct rarity', () async {
        final tiers = [
          (AchievementRewardTier.bronze, 'common'),
          (AchievementRewardTier.silver, 'uncommon'),
          (AchievementRewardTier.gold, 'rare'),
          (AchievementRewardTier.platinum, 'legendary'),
        ];

        for (final (tier, rarity) in tiers) {
          final achievement = testAchievement.copyWith(rewardTier: tier);
          await integration.trackAchievementUnlock(
            userId,
            achievement,
            testPlayerAchievement,
          );

          verify(mockAnalyticsService.logAchievementUnlocked(
            userId,
            'rising_star',
            rarity,
          )).called(1);
        }
      });
    });

    group('trackAchievementProgress', () {
      test('emits progress event with correct values', () async {
        final progressAchievement = Achievement(
          achievementId: 'stat_master',
          category: AchievementCategory.skill,
          name: 'ステータスマスター',
          description: 'Test',
          iconUrl: 'test.png',
          rewardTier: AchievementRewardTier.silver,
          maxProgress: 50,
          isProgressBased: true,
        );

        final progressPlayerAchievement = PlayerAchievement(
          userId: userId,
          achievementId: 'stat_master',
          unlockedAt: DateTime.now(),
          progress: AchievementProgress(current: 25, target: 50),
        );

        await integration.trackAchievementProgress(
          userId,
          progressAchievement,
          progressPlayerAchievement,
        );

        verify(mockAnalyticsService.logAchievementProgress(
          userId,
          'stat_master',
          25,
          50,
        )).called(1);
      });

      test('skips non-progress-based achievements', () async {
        await integration.trackAchievementProgress(
          userId,
          testAchievement,
          testPlayerAchievement,
        );

        verifyNever(mockAnalyticsService.logAchievementProgress(
          any,
          any,
          any,
          any,
        ));
      });

      test('skips when progress is null', () async {
        final progressAchievement = Achievement(
          achievementId: 'stat_master',
          category: AchievementCategory.skill,
          name: 'ステータスマスター',
          description: 'Test',
          iconUrl: 'test.png',
          rewardTier: AchievementRewardTier.silver,
          maxProgress: 50,
          isProgressBased: true,
        );

        await integration.trackAchievementProgress(
          userId,
          progressAchievement,
          null,
        );

        verifyNever(mockAnalyticsService.logAchievementProgress(
          any,
          any,
          any,
          any,
        ));
      });
    });

    group('trackCompletionStats', () {
      test('emits completion event with correct stats', () async {
        when(mockAchievementService.getCompletionPercentage(userId))
            .thenAnswer((_) async => 75.0);
        when(mockAchievementService.getUnlockCount(userId))
            .thenAnswer((_) async => 5);

        await integration.trackCompletionStats(userId);

        verify(mockAnalyticsService.logAchievementCompletion(
          userId,
          75.0,
          5,
        )).called(1);
      });

      test('handles zero completion', () async {
        when(mockAchievementService.getCompletionPercentage(userId))
            .thenAnswer((_) async => 0.0);
        when(mockAchievementService.getUnlockCount(userId))
            .thenAnswer((_) async => 0);

        await integration.trackCompletionStats(userId);

        verify(mockAnalyticsService.logAchievementCompletion(
          userId,
          0.0,
          0,
        )).called(1);
      });

      test('handles 100% completion', () async {
        when(mockAchievementService.getCompletionPercentage(userId))
            .thenAnswer((_) async => 100.0);
        when(mockAchievementService.getUnlockCount(userId))
            .thenAnswer((_) async => 7);

        await integration.trackCompletionStats(userId);

        verify(mockAnalyticsService.logAchievementCompletion(
          userId,
          100.0,
          7,
        )).called(1);
      });
    });

    group('trackCategoryProgress', () {
      test('emits category progress event', () async {
        final achievements = [
          PlayerAchievement(
            userId: userId,
            achievementId: 'ach_1',
            unlockedAt: DateTime.now(),
          ),
          PlayerAchievement(
            userId: userId,
            achievementId: 'ach_2',
            unlockedAt: DateTime.now(),
          ),
        ];

        when(mockAchievementService.getAchievementsByCategory(
          userId,
          AchievementCategory.progression,
        )).thenAnswer((_) async => achievements);

        await integration.trackCategoryProgress(
          userId,
          AchievementCategory.progression,
        );

        verify(mockAnalyticsService.logAchievementCategoryProgress(
          userId,
          'progression',
          2,
          2,
        )).called(1);
      });

      test('handles empty category', () async {
        when(mockAchievementService.getAchievementsByCategory(
          userId,
          AchievementCategory.special,
        )).thenAnswer((_) async => []);

        await integration.trackCategoryProgress(
          userId,
          AchievementCategory.special,
        );

        verifyNever(mockAnalyticsService.logAchievementCategoryProgress(
          any,
          any,
          any,
          any,
        ));
      });

      test('handles partial completion in category', () async {
        final achievements = [
          PlayerAchievement(
            userId: userId,
            achievementId: 'ach_1',
            unlockedAt: DateTime.now(),
          ),
          PlayerAchievement(
            userId: userId,
            achievementId: 'ach_2',
            unlockedAt: DateTime.now(),
          ),
          PlayerAchievement(
            userId: userId,
            achievementId: 'ach_3',
            unlockedAt: DateTime.now(),
          ),
        ];

        when(mockAchievementService.getAchievementsByCategory(
          userId,
          AchievementCategory.milestone,
        )).thenAnswer((_) async => achievements);

        await integration.trackCategoryProgress(
          userId,
          AchievementCategory.milestone,
        );

        verify(mockAnalyticsService.logAchievementCategoryProgress(
          userId,
          'milestone',
          3,
          3,
        )).called(1);
      });
    });

    group('trackAllCategoriesProgress', () {
      test('tracks progress for all categories', () async {
        when(mockAchievementService.getAchievementsByCategory(
          userId,
          any,
        )).thenAnswer((_) async => []);

        await integration.trackAllCategoriesProgress(userId);

        // Should be called for each category
        verify(mockAchievementService.getAchievementsByCategory(
          userId,
          any,
        )).called(greaterThanOrEqualTo(AchievementCategory.values.length));
      });
    });

    group('trackRewardClaim', () {
      test('emits reward_claimed event', () async {
        await integration.trackRewardClaim(userId, testAchievement);

        verify(mockAnalyticsService.logAchievementRewardClaimed(
          userId,
          'rising_star',
          'bronze',
          testAchievement.getRewardCurrency(),
          testAchievement.getRewardBadges(),
        )).called(1);
      });

      test('handles all reward tiers', () async {
        final tiers = [
          AchievementRewardTier.bronze,
          AchievementRewardTier.silver,
          AchievementRewardTier.gold,
          AchievementRewardTier.platinum,
        ];

        for (final tier in tiers) {
          final achievement = testAchievement.copyWith(rewardTier: tier);
          await integration.trackRewardClaim(userId, achievement);
        }

        verify(mockAnalyticsService.logAchievementRewardClaimed(
          any,
          any,
          any,
          any,
          any,
        )).called(tiers.length);
      });
    });
  });
}
