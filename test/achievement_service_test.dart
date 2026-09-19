import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shinjuu_league/data/models/achievement.dart';
import 'package:shinjuu_league/data/models/progression_stats.dart';
import 'package:shinjuu_league/services/achievement_service.dart';
import 'package:shinjuu_league/services/firestore_service.dart';

class MockFirestoreService extends Mock implements FirestoreService {}

void main() {
  group('AchievementService', () {
    late AchievementService service;
    late MockFirestoreService mockFirestore;

    setUp(() {
      mockFirestore = MockFirestoreService();
      service = AchievementService(mockFirestore);
    });

    group('getPlayerAchievements', () {
      test('returns empty list for new player', () async {
        when(mockFirestore.getCollection('users/user_123/achievements'))
            .thenAnswer((_) async => []);

        final achievements = await service.getPlayerAchievements('user_123');
        expect(achievements, isEmpty);
      });

      test('returns player achievements', () async {
        final docs = [
          PlayerAchievement(
            userId: 'user_123',
            achievementId: 'stat_master',
            unlockedAt: DateTime.now(),
            progress: AchievementProgress(current: 50, target: 50),
          ).toJson(),
        ];

        when(mockFirestore.getCollection('users/user_123/achievements'))
            .thenAnswer((_) async => docs);

        final achievements = await service.getPlayerAchievements('user_123');
        expect(achievements.length, equals(1));
        expect(achievements.first.achievementId, equals('stat_master'));
      });
    });

    group('unlockAchievement', () {
      test('unlocks achievement successfully', () async {
        when(mockFirestore.set(any, any)).thenAnswer((_) async {});

        await service.unlockAchievement('user_123', 'rising_star');

        verify(mockFirestore.set(
          'users/user_123/achievements/rising_star',
          any,
        )).called(1);
      });

      test('throws for invalid achievement ID', () {
        expect(
          () => service.unlockAchievement('user_123', 'invalid_id'),
          throwsException,
        );
      });
    });

    group('getUnlockedAchievements', () {
      test('returns only unlocked achievements', () async {
        final docs = [
          PlayerAchievement(
            userId: 'user_123',
            achievementId: 'rising_star',
            unlockedAt: DateTime.now(),
            progress: null,
          ).toJson(),
          PlayerAchievement(
            userId: 'user_123',
            achievementId: 'stat_master',
            unlockedAt: DateTime.now(),
            progress: AchievementProgress(current: 30, target: 50),
          ).toJson(),
        ];

        when(mockFirestore.getCollection('users/user_123/achievements'))
            .thenAnswer((_) async => docs);

        final unlocked = await service.getUnlockedAchievements('user_123');
        expect(unlocked.length, equals(1));
        expect(unlocked.first.achievementId, equals('rising_star'));
      });
    });

    group('getAchievementsByCategory', () {
      test('filters achievements by category', () async {
        final docs = [
          PlayerAchievement(
            userId: 'user_123',
            achievementId: 'rising_star',
            unlockedAt: DateTime.now(),
            progress: null,
          ).toJson(),
          PlayerAchievement(
            userId: 'user_123',
            achievementId: 'stat_master',
            unlockedAt: DateTime.now(),
            progress: AchievementProgress(current: 50, target: 50),
          ).toJson(),
        ];

        when(mockFirestore.getCollection('users/user_123/achievements'))
            .thenAnswer((_) async => docs);

        final skillAch = await service.getAchievementsByCategory(
          'user_123',
          AchievementCategory.skill,
        );

        expect(skillAch.length, equals(1));
        expect(skillAch.first.achievementId, equals('stat_master'));
      });
    });

    group('getUnlockCount', () {
      test('counts unlocked achievements', () async {
        final docs = [
          PlayerAchievement(
            userId: 'user_123',
            achievementId: 'rising_star',
            unlockedAt: DateTime.now(),
          ).toJson(),
          PlayerAchievement(
            userId: 'user_123',
            achievementId: 'stat_master',
            unlockedAt: DateTime.now(),
            progress: AchievementProgress(current: 30, target: 50),
          ).toJson(),
        ];

        when(mockFirestore.getCollection('users/user_123/achievements'))
            .thenAnswer((_) async => docs);

        final count = await service.getUnlockCount('user_123');
        expect(count, equals(1));
      });
    });

    group('getTotalAvailableCount', () {
      test('returns available achievement count', () {
        final total = service.getTotalAvailableCount();
        expect(total, greaterThan(0));
        expect(total, equals(AchievementsCatalog.all.length));
      });
    });

    group('getCompletionPercentage', () {
      test('calculates completion percentage', () async {
        final docs = [
          PlayerAchievement(
            userId: 'user_123',
            achievementId: 'rising_star',
            unlockedAt: DateTime.now(),
          ).toJson(),
        ];

        when(mockFirestore.getCollection('users/user_123/achievements'))
            .thenAnswer((_) async => docs);

        final percentage = await service.getCompletionPercentage('user_123');
        expect(percentage, greaterThan(0.0));
        expect(percentage, lessThanOrEqualTo(100.0));
      });
    });

    group('Achievement catalog', () {
      test('all achievements have required fields', () {
        for (final achievement in AchievementsCatalog.all) {
          expect(achievement.achievementId, isNotEmpty);
          expect(achievement.name, isNotEmpty);
          expect(achievement.description, isNotEmpty);
          expect(achievement.iconUrl, isNotEmpty);
        }
      });

      test('rising_star is progression category', () {
        expect(
          AchievementsCatalog.risingStar.category,
          equals(AchievementCategory.progression),
        );
      });

      test('stat_master is progress-based', () {
        expect(AchievementsCatalog.statMaster.isProgressBased, isTrue);
        expect(AchievementsCatalog.statMaster.maxProgress, equals(50));
      });

      test('getById returns achievement', () {
        final ach = AchievementsCatalog.getById('stat_master');
        expect(ach, isNotNull);
        expect(ach!.name, equals('ステータスマスター'));
      });

      test('getByCategory returns filtered list', () {
        final progAch = AchievementsCatalog.getByCategory(
          AchievementCategory.progression,
        );
        expect(progAch, isNotEmpty);
      });
    });

    group('AchievementProgress', () {
      test('calculates percentage correctly', () {
        final progress = AchievementProgress(current: 5, target: 10);
        expect(progress.percentage, equals(50));
      });

      test('clamps percentage to 100', () {
        final progress = AchievementProgress(current: 15, target: 10);
        expect(progress.percentage, equals(100));
      });

      test('isComplete when current >= target', () {
        final incomplete = AchievementProgress(current: 5, target: 10);
        final complete = AchievementProgress(current: 10, target: 10);

        expect(incomplete.isComplete, isFalse);
        expect(complete.isComplete, isTrue);
      });
    });

    group('PlayerAchievement', () {
      test('instant unlock for non-progress achievements', () {
        final ach = PlayerAchievement(
          userId: 'user_123',
          achievementId: 'rising_star',
          unlockedAt: DateTime.now(),
          progress: null,
        );

        expect(ach.isUnlocked, isTrue);
        expect(ach.getProgressPercentage(), equals(100));
      });

      test('progress-based achievement tracks completion', () {
        final ach = PlayerAchievement(
          userId: 'user_123',
          achievementId: 'stat_master',
          unlockedAt: DateTime.now(),
          progress: AchievementProgress(current: 25, target: 50),
        );

        expect(ach.isUnlocked, isFalse);
        expect(ach.getProgressPercentage(), equals(50));
      });
    });
  });
}
