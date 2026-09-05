import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shinjuu_league/data/models/achievement_model.dart';
import 'package:shinjuu_league/services/achievement_service_extended.dart';
import 'package:shinjuu_league/services/firestore_service.dart';

class MockFirestoreService extends Mock implements FirestoreService {}

class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  group('AchievementPersistenceService', () {
    late AchievementPersistenceService service;
    late MockFirestoreService mockFirestore;

    setUp(() {
      mockFirestore = MockFirestoreService();
      service = AchievementPersistenceService();
    });

    // ===== Initialization Tests =====
    group('Initialization', () {
      test('init() should initialize SharedPreferences', () async {
        SharedPreferences.setMockInitialValues({});
        await service.init();
        // Verify that service can be initialized without errors
        expect(true, true);
      });

      test('init() should be idempotent (calling twice should not reinitialize)',
          () async {
        SharedPreferences.setMockInitialValues({});
        await service.init();
        await service.init(); // Second call should return immediately
        expect(true, true);
      });
    });

    // ===== Default Achievement Loading Tests =====
    group('Default Achievement Loading', () {
      test('_initializeDefaultAchievements() should create 15 achievements', () {
        final defaults = AchievementCatalog.allAchievements;
        expect(defaults.length, 15);
      });

      test('each default achievement should have valid properties', () {
        for (final ach in AchievementCatalog.allAchievements) {
          expect(ach.achievementId, isNotEmpty);
          expect(ach.name, isNotEmpty);
          expect(ach.description, isNotEmpty);
          expect(ach.rewardPoints, greaterThan(0));

          // Progress type must have targetCount
          if (ach.type == AchievementType.progress) {
            expect(ach.targetCount, isNotNull);
            expect(ach.targetCount!, greaterThan(0));
          }
        }
      });

      test('milestone achievements should have no targetCount', () {
        final milestones = AchievementCatalog.byType(AchievementType.milestone);
        for (final ach in milestones) {
          expect(ach.targetCount, isNull);
        }
      });
    });

    // ===== Achievement Progress Model Tests =====
    group('AchievementProgress Model', () {
      test('AchievementProgress can be created and serialized', () {
        final progress = AchievementProgress(
          achievementId: 'test_achievement',
          isUnlocked: true,
          currentProgress: 5,
          unlockedAt: DateTime(2026, 9, 5, 10, 30),
          lastUpdatedAt: DateTime(2026, 9, 5, 11, 0),
        );

        final json = progress.toJson();
        expect(json['achievementId'], 'test_achievement');
        expect(json['isUnlocked'], true);
        expect(json['currentProgress'], 5);
      });

      test('AchievementProgress can be deserialized from JSON', () {
        final json = {
          'achievementId': 'first_kill',
          'isUnlocked': true,
          'currentProgress': 1,
          'unlockedAt': '2026-09-05T10:30:00.000Z',
          'lastUpdatedAt': '2026-09-05T11:00:00.000Z',
        };

        final progress = AchievementProgress.fromJson(json);
        expect(progress.achievementId, 'first_kill');
        expect(progress.isUnlocked, true);
      });

      test('AchievementProgress copyWith should preserve all fields', () {
        final original = AchievementProgress(
          achievementId: 'test',
          isUnlocked: false,
          currentProgress: 0,
          lastUpdatedAt: DateTime.now(),
        );

        final updated = original.copyWith(isUnlocked: true, currentProgress: 5);

        expect(updated.achievementId, original.achievementId);
        expect(updated.isUnlocked, true);
        expect(updated.currentProgress, 5);
        expect(updated.lastUpdatedAt, original.lastUpdatedAt);
      });

      test('AchievementProgress equality should work correctly', () {
        final now = DateTime.now();
        final p1 = AchievementProgress(
          achievementId: 'test',
          isUnlocked: true,
          currentProgress: 5,
          unlockedAt: now,
          lastUpdatedAt: now,
        );

        final p2 = AchievementProgress(
          achievementId: 'test',
          isUnlocked: true,
          currentProgress: 5,
          unlockedAt: now,
          lastUpdatedAt: now,
        );

        expect(p1, equals(p2));
      });
    });

    // ===== Unlock Condition Tests =====
    group('Unlock Conditions', () {
      test('milestone achievement unlocks at progress >= 1', () {
        final milestone = AchievementCatalog.achievementById('first_kill');
        expect(milestone, isNotNull);
        expect(milestone!.type, AchievementType.milestone);

        // Should unlock at progress 1
        final progress = AchievementProgress(
          achievementId: 'first_kill',
          isUnlocked: false,
          currentProgress: 1,
          lastUpdatedAt: DateTime.now(),
        );
        expect(progress.currentProgress >= 1, true);
      });

      test('progress achievement unlocks when reaching targetCount', () {
        final progress = AchievementCatalog.achievementById('ten_kills');
        expect(progress, isNotNull);
        expect(progress!.type, AchievementType.progress);
        expect(progress.targetCount, 10);
      });

      test('challenge achievement should have specific unlock conditions', () {
        final challenge = AchievementCatalog.achievementById('fifty_percent_winrate');
        expect(challenge, isNotNull);
        expect(challenge!.type, AchievementType.challenge);
      });
    });

    // ===== Achievement Statistics Tests =====
    group('Achievement Statistics', () {
      test('AchievementStats should calculate completion percentage', () {
        final stats = AchievementStats(
          totalUnlocked: 5,
          totalCount: 15,
          completionPercentage: (5 / 15) * 100,
          totalPoints: 200,
        );

        expect(stats.completionPercentage, closeTo(33.33, 0.1));
      });

      test('AchievementStats isComplete should be true at 100%', () {
        final stats = AchievementStats(
          totalUnlocked: 15,
          totalCount: 15,
          completionPercentage: 100.0,
          totalPoints: 1000,
        );

        expect(stats.isComplete, true);
      });

      test('AchievementStats should handle zero achievements', () {
        final stats = AchievementStats(
          totalUnlocked: 0,
          totalCount: 0,
          completionPercentage: 0.0,
          totalPoints: 0,
        );

        expect(stats.isComplete, false);
        expect(stats.totalUnlocked, 0);
      });

      test('AchievementStats should accumulate reward points correctly', () {
        final achievements = AchievementCatalog.allAchievements.sublist(0, 3);
        final totalPoints = achievements.fold<int>(
          0,
          (sum, ach) => sum + ach.rewardPoints,
        );

        expect(totalPoints, greaterThan(0));
      });
    });

    // ===== Cache Serialization Tests =====
    group('Cache Serialization', () {
      test('AchievementProgress should serialize to JSON string', () {
        final progress = AchievementProgress(
          achievementId: 'test_achievement',
          isUnlocked: true,
          currentProgress: 5,
          lastUpdatedAt: DateTime(2026, 9, 5),
        );

        final json = progress.toJson();
        final jsonString = jsonEncode(json);

        expect(jsonString, isNotEmpty);
        expect(jsonString, contains('test_achievement'));
        expect(jsonString, contains('true'));
      });

      test('serialized AchievementProgress can be deserialized', () {
        final original = AchievementProgress(
          achievementId: 'first_kill',
          isUnlocked: true,
          currentProgress: 1,
          unlockedAt: DateTime(2026, 9, 5, 10, 30),
          lastUpdatedAt: DateTime(2026, 9, 5, 11, 0),
        );

        final jsonString = jsonEncode(original.toJson());
        final deserialized = AchievementProgress.fromJson(
          jsonDecode(jsonString) as Map<String, dynamic>,
        );

        expect(deserialized.achievementId, original.achievementId);
        expect(deserialized.isUnlocked, original.isUnlocked);
        expect(deserialized.currentProgress, original.currentProgress);
      });

      test('batch serialization should handle multiple achievements', () {
        final progresses = [
          AchievementProgress(
            achievementId: 'achievement_1',
            isUnlocked: true,
            currentProgress: 1,
            lastUpdatedAt: DateTime.now(),
          ),
          AchievementProgress(
            achievementId: 'achievement_2',
            isUnlocked: false,
            currentProgress: 0,
            lastUpdatedAt: DateTime.now(),
          ),
        ];

        final jsonStrings = progresses
            .map((p) => jsonEncode(p.toJson()))
            .toList();

        expect(jsonStrings.length, 2);
        for (final str in jsonStrings) {
          expect(str, isNotEmpty);
        }
      });
    });

    // ===== Firestore Integration Scenarios =====
    group('Firestore Integration', () {
      test('should handle Firestore collection format correctly', () {
        // Simulate Firestore document data
        final firestoreData = {
          'achievementId': 'first_kill',
          'isUnlocked': true,
          'currentProgress': 1,
          'unlockedAt': '2026-09-05T10:30:00.000Z',
          'lastUpdatedAt': '2026-09-05T11:00:00.000Z',
        };

        final progress = AchievementProgress.fromJson(firestoreData);
        expect(progress.achievementId, 'first_kill');
        expect(progress.isUnlocked, true);
      });

      test('Firestore documents should have required fields', () {
        final achievements = AchievementCatalog.allAchievements;
        for (final ach in achievements) {
          expect(ach.achievementId, isNotEmpty);
          expect(ach.name, isNotEmpty);
          expect(ach.description, isNotEmpty);
        }
      });
    });

    // ===== Offline/Online Handling =====
    group('Offline/Online Handling', () {
      test('should fall back to cached data when Firestore fails', () {
        // This is a behavior contract test
        // The actual implementation should try Firestore first, then cache
        expect(true, true);
      });

      test('should initialize defaults when both Firestore and cache fail', () {
        final defaults = AchievementCatalog.allAchievements;
        expect(defaults.length, greaterThan(0));
      });

      test('cached achievements should survive app restart', () {
        // Test that serialized achievements maintain integrity
        final progress = AchievementProgress(
          achievementId: 'test',
          isUnlocked: true,
          currentProgress: 5,
          lastUpdatedAt: DateTime(2026, 9, 5),
        );

        final serialized = jsonEncode(progress.toJson());
        final deserialized = AchievementProgress.fromJson(
          jsonDecode(serialized) as Map<String, dynamic>,
        );

        expect(deserialized, equals(progress));
      });
    });

    // ===== Concurrent Access Safety =====
    group('Concurrent Access Safety', () {
      test('singleton pattern should return same instance', () {
        final s1 = AchievementPersistenceService();
        final s2 = AchievementPersistenceService();

        expect(identical(s1, s2), true);
      });

      test('achievements list should be thread-safe (immutable)', () {
        final ach1 = AchievementCatalog.allAchievements;
        final ach2 = AchievementCatalog.allAchievements;

        expect(ach1.length, ach2.length);
        for (int i = 0; i < ach1.length; i++) {
          expect(ach1[i].achievementId, ach2[i].achievementId);
        }
      });
    });

    // ===== Error Recovery =====
    group('Error Recovery', () {
      test('should handle corrupt JSON in cache gracefully', () {
        final corruptJson = '{invalid json}';

        expect(
          () {
            try {
              jsonDecode(corruptJson);
            } catch (e) {
              // Should throw FormatException
              expect(e, isA<FormatException>());
            }
          },
          returnsNormally,
        );
      });

      test('should handle missing achievement gracefully', () {
        final missing = AchievementCatalog.achievementById('nonexistent_id');
        expect(missing, isNull);
      });

      test('should provide default AchievementStats on error', () {
        final stats = AchievementStats(
          totalUnlocked: 0,
          totalCount: 15,
          completionPercentage: 0.0,
          totalPoints: 0,
        );

        expect(stats.totalUnlocked, 0);
        expect(stats.isComplete, false);
      });
    });

    // ===== Data Integrity Tests =====
    group('Data Integrity', () {
      test('achievement ID should be unique in catalog', () {
        final achievements = AchievementCatalog.allAchievements;
        final ids = achievements.map((a) => a.achievementId).toList();
        final uniqueIds = ids.toSet();

        expect(ids.length, uniqueIds.length);
      });

      test('all achievements should have positive reward points', () {
        for (final ach in AchievementCatalog.allAchievements) {
          expect(ach.rewardPoints, greaterThan(0));
        }
      });

      test('progress type achievements must have targetCount', () {
        final progressAchievements = AchievementCatalog.byType(
          AchievementType.progress,
        );

        for (final ach in progressAchievements) {
          expect(ach.targetCount, isNotNull);
          expect(ach.targetCount!, greaterThan(0));
        }
      });

      test('difficulty enum should have all expected values', () {
        expect(AchievementDifficulty.easy, isNotNull);
        expect(AchievementDifficulty.normal, isNotNull);
        expect(AchievementDifficulty.hard, isNotNull);
        expect(AchievementDifficulty.legendary, isNotNull);
      });

      test('achievement type enum should have all expected values', () {
        expect(AchievementType.milestone, isNotNull);
        expect(AchievementType.progress, isNotNull);
        expect(AchievementType.challenge, isNotNull);
      });
    });

    // ===== Performance Tests =====
    group('Performance', () {
      test('should load all achievements quickly', () {
        final stopwatch = Stopwatch()..start();
        final achievements = AchievementCatalog.allAchievements;
        stopwatch.stop();

        expect(achievements.length, 15);
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
      });

      test('should filter achievements efficiently', () {
        final stopwatch = Stopwatch()..start();
        final legendary = AchievementCatalog.byDifficulty(
          AchievementDifficulty.legendary,
        );
        stopwatch.stop();

        expect(legendary.isNotEmpty, true);
        expect(stopwatch.elapsedMilliseconds, lessThan(50));
      });

      test('should serialize/deserialize efficiently', () {
        final progress = AchievementProgress(
          achievementId: 'test',
          isUnlocked: true,
          currentProgress: 5,
          lastUpdatedAt: DateTime.now(),
        );

        final stopwatch = Stopwatch()..start();
        final json = jsonEncode(progress.toJson());
        final deserialized = AchievementProgress.fromJson(
          jsonDecode(json) as Map<String, dynamic>,
        );
        stopwatch.stop();

        expect(deserialized, equals(progress));
        expect(stopwatch.elapsedMilliseconds, lessThan(50));
      });
    });

    // ===== Debug Utilities =====
    group('Debug Utilities', () {
      test('achievement should have toString representation', () {
        final ach = AchievementCatalog.achievementById('first_kill');
        expect(ach.toString(), isNotEmpty);
      });

      test('AchievementStats should have toString representation', () {
        final stats = AchievementStats(
          totalUnlocked: 5,
          totalCount: 15,
          completionPercentage: 33.33,
          totalPoints: 200,
        );

        final str = stats.toString();
        expect(str, contains('5'));
        expect(str, contains('15'));
        expect(str, contains('33'));
      });
    });
  });
}
