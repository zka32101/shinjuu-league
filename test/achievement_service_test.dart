import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shinjuu_league/data/models/achievement.dart';
import 'package:shinjuu_league/services/achievement_service.dart';
import 'package:shinjuu_league/services/firestore_service.dart';

class MockFirestoreService extends Mock implements FirestoreService {
  @override
  Future<void> markAchievementUnlocked(
    String? userId,
    String? achievementId, {
    String? achievementName,
  }) {
    return super.noSuchMethod(
          Invocation.method(
            #markAchievementUnlocked,
            [userId, achievementId],
            {#achievementName: achievementName},
          ),
          returnValue: Future<void>.value(),
          returnValueForMissingStub: Future<void>.value(),
        )
        as Future<void>;
  }

  @override
  Future<List<Map<String, dynamic>>> getCollection(String? path) {
    return super.noSuchMethod(
          Invocation.method(#getCollection, [path]),
          returnValue: Future<List<Map<String, dynamic>>>.value(
            <Map<String, dynamic>>[],
          ),
          returnValueForMissingStub: Future<List<Map<String, dynamic>>>.value(
            <Map<String, dynamic>>[],
          ),
        )
        as Future<List<Map<String, dynamic>>>;
  }
}

/// A doc shaped exactly like FirestoreService.markAchievementUnlocked()
/// actually writes - {achievementId, name?, unlockedAt, isHidden} - the
/// only shape ever found in users/{userId}/achievements/{achievementId}
/// now (see AchievementService.getPlayerAchievements's doc comment: a
/// document here always represents a genuine unlock, never partial
/// progress).
Map<String, dynamic> _unlockedDoc(
  String achievementId, {
  String? name,
  bool isHidden = false,
}) {
  return {
    'achievementId': achievementId,
    if (name != null) 'name': name,
    'unlockedAt': Timestamp.now(),
    'isHidden': isHidden,
  };
}

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
        when(
          mockFirestore.getCollection('users/user_123/achievements'),
        ).thenAnswer((_) async => []);

        final achievements = await service.getPlayerAchievements('user_123');
        expect(achievements, isEmpty);
      });

      // Real regression guard: this used to do
      // `PlayerAchievement.fromJson(doc)`, which throws on the actual shape
      // FirestoreService.markAchievementUnlocked() writes (no `userId` key,
      // `unlockedAt` as a Firestore Timestamp rather than an ISO string).
      test('parses the real unlock doc shape without throwing', () async {
        final docs = [_unlockedDoc('stat_master', name: 'ステータスマスター')];

        when(
          mockFirestore.getCollection('users/user_123/achievements'),
        ).thenAnswer((_) async => docs);

        final achievements = await service.getPlayerAchievements('user_123');
        expect(achievements.length, equals(1));
        expect(achievements.first.achievementId, equals('stat_master'));
        expect(achievements.first.userId, equals('user_123'));
        expect(achievements.first.isUnlocked, isTrue);
      });

      test('skips a doc missing achievementId rather than throwing', () async {
        when(
          mockFirestore.getCollection('users/user_123/achievements'),
        ).thenAnswer(
          (_) async => [
            {'unlockedAt': Timestamp.now()},
          ],
        );

        final achievements = await service.getPlayerAchievements('user_123');
        expect(achievements, isEmpty);
      });
    });

    group('unlockAchievement', () {
      // Real regression guard: this used to write a full
      // PlayerAchievement.toJson() directly via a bare `_firestoreService.set()`
      // call - a different, incompatible shape from every other unlock path
      // in the app (AchievementRewardService.processUnlock(), used by both
      // the kill-detection and battle-trigger-detection systems, which both
      // go through FirestoreService.markAchievementUnlocked()). It now
      // delegates to that same method, so every unlock in the app writes
      // one consistent shape.
      test('delegates to FirestoreService.markAchievementUnlocked', () async {
        await service.unlockAchievement('user_123', 'rising_star');

        verify(
          mockFirestore.markAchievementUnlocked(
            'user_123',
            'rising_star',
            achievementName: AchievementsCatalog.risingStar.name,
          ),
        ).called(1);
      });

      test('throws for invalid achievement ID', () {
        expect(
          () => service.unlockAchievement('user_123', 'invalid_id'),
          throwsException,
        );
      });
    });

    group('getUnlockedAchievements', () {
      test(
        'returns every doc in the achievements collection (all are unlocks)',
        () async {
          final docs = [
            _unlockedDoc('rising_star'),
            _unlockedDoc('stat_master'),
          ];

          when(
            mockFirestore.getCollection('users/user_123/achievements'),
          ).thenAnswer((_) async => docs);

          final unlocked = await service.getUnlockedAchievements('user_123');
          expect(unlocked.length, equals(2));
          expect(
            unlocked.map((a) => a.achievementId),
            containsAll(['rising_star', 'stat_master']),
          );
        },
      );
    });

    group('getAchievementsByCategory', () {
      test('filters achievements by category', () async {
        final docs = [
          _unlockedDoc('rising_star'), // progression
          _unlockedDoc('stat_master'), // skill
        ];

        when(
          mockFirestore.getCollection('users/user_123/achievements'),
        ).thenAnswer((_) async => docs);

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
        final docs = [_unlockedDoc('rising_star')];

        when(
          mockFirestore.getCollection('users/user_123/achievements'),
        ).thenAnswer((_) async => docs);

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
        final docs = [_unlockedDoc('rising_star')];

        when(
          mockFirestore.getCollection('users/user_123/achievements'),
        ).thenAnswer((_) async => docs);

        final percentage = await service.getCompletionPercentage('user_123');
        expect(percentage, greaterThan(0.0));
        expect(percentage, lessThanOrEqualTo(100.0));
      });
    });

    group('getProgress', () {
      // Progress toward a not-yet-unlocked achievement is never persisted
      // (see getPlayerAchievements's doc comment) - it's computed
      // transiently from live game state (skill tree, season history)
      // wherever it's needed for display, e.g. AchievementsScreen.
      test('always returns null', () async {
        final progress = await service.getProgress('user_123', 'stat_master');
        expect(progress, isNull);
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

      // Real regression guard: maxProgress used to be 50, far beyond the
      // real skill tree's 5-tier-per-branch cap - this achievement could
      // never actually be unlocked. It's 5 now, matching that real cap.
      test('stat_master is progress-based with an achievable threshold', () {
        expect(AchievementsCatalog.statMaster.isProgressBased, isTrue);
        expect(AchievementsCatalog.statMaster.maxProgress, equals(5));
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
          progress: AchievementProgress(current: 2, target: 5),
        );

        expect(ach.isUnlocked, isFalse);
        expect(ach.getProgressPercentage(), equals(40));
      });
    });
  });
}
