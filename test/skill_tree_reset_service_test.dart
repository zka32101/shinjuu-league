import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shinjuu_league/data/models/skill_model.dart';
import 'package:shinjuu_league/data/models/skill_tree_reset.dart';
import 'package:shinjuu_league/services/skill_tree_reset_service.dart';
import 'package:shinjuu_league/services/firestore_service.dart';

class MockFirestoreService extends Mock implements FirestoreService {}

void main() {
  group('SkillTreeResetService', () {
    late SkillTreeResetService service;
    late MockFirestoreService mockFirestore;

    setUp(() {
      mockFirestore = MockFirestoreService();
      service = SkillTreeResetService(mockFirestore);
    });

    group('resetForNewSeason - CarryoverMode.none', () {
      test('complete reset returns tree with 0 points', () async {
        final previousTree = _createSkillTree(5); // 5 points allocated
        when(mockFirestore.get('users/user_123'))
            .thenAnswer((_) async => {'skillTree': previousTree.toJson()});

        when(mockFirestore.set(any, any)).thenAnswer((_) async {});
        when(mockFirestore.update(any, any)).thenAnswer((_) async {});

        final newTree = await service.resetForNewSeason(
          'user_123',
          'season_1',
          'season_2',
          'Gold',
          CarryoverMode.none,
        );

        expect(newTree.totalAllocatedPoints, equals(0));
        expect(newTree.availablePoints, equals(0));
      });

      test('stores reset record with none carryover', () async {
        final previousTree = _createSkillTree(3);
        when(mockFirestore.get('users/user_123'))
            .thenAnswer((_) async => {'skillTree': previousTree.toJson()});

        when(mockFirestore.set(any, any)).thenAnswer((_) async {});
        when(mockFirestore.update(any, any)).thenAnswer((_) async {});

        await service.resetForNewSeason(
          'user_123',
          'season_1',
          'season_2',
          'Silver',
          CarryoverMode.none,
        );

        verify(mockFirestore.set(
          'users/user_123/season_resets/season_2',
          any,
        )).called(1);
      });
    });

    group('resetForNewSeason - CarryoverMode.partial', () {
      test('carries over 50% of points rounded down', () async {
        final previousTree = _createSkillTree(5); // 5 points
        when(mockFirestore.get('users/user_123'))
            .thenAnswer((_) async => {'skillTree': previousTree.toJson()});

        when(mockFirestore.set(any, any)).thenAnswer((_) async {});
        when(mockFirestore.update(any, any)).thenAnswer((_) async {});

        final newTree = await service.resetForNewSeason(
          'user_123',
          'season_1',
          'season_2',
          'Gold',
          CarryoverMode.partial,
        );

        // 5 * 0.5 = 2.5 → 2 points
        expect(newTree.totalAllocatedPoints, equals(2));
      });

      test('partial carryover with 4 points → 2 points', () async {
        final previousTree = _createSkillTree(4);
        when(mockFirestore.get('users/user_123'))
            .thenAnswer((_) async => {'skillTree': previousTree.toJson()});

        when(mockFirestore.set(any, any)).thenAnswer((_) async {});
        when(mockFirestore.update(any, any)).thenAnswer((_) async {});

        final newTree = await service.resetForNewSeason(
          'user_123',
          'season_1',
          'season_2',
          'Silver',
          CarryoverMode.partial,
        );

        expect(newTree.totalAllocatedPoints, equals(2));
      });

      test('partial carryover allocates to trees in order', () async {
        final previousTree = _createSkillTree(5);
        when(mockFirestore.get('users/user_123'))
            .thenAnswer((_) async => {'skillTree': previousTree.toJson()});

        when(mockFirestore.set(any, any)).thenAnswer((_) async {});
        when(mockFirestore.update(any, any)).thenAnswer((_) async {});

        final newTree = await service.resetForNewSeason(
          'user_123',
          'season_1',
          'season_2',
          'Gold',
          CarryoverMode.partial,
        );

        // 5 points → 2 carried over, allocated to ATK(1) + DEF(1)
        expect(newTree.trees[0].allocatedTiers, greaterThan(0)); // ATK
      });
    });

    group('resetForNewSeason - CarryoverMode.full', () {
      test('full carryover keeps all points', () async {
        final previousTree = _createSkillTree(5);
        when(mockFirestore.get('users/user_123'))
            .thenAnswer((_) async => {'skillTree': previousTree.toJson()});

        when(mockFirestore.set(any, any)).thenAnswer((_) async {});
        when(mockFirestore.update(any, any)).thenAnswer((_) async {});

        final newTree = await service.resetForNewSeason(
          'user_123',
          'season_1',
          'season_2',
          'Platinum',
          CarryoverMode.full,
        );

        expect(newTree.totalAllocatedPoints, equals(5));
      });

      test('full carryover copies tree structure', () async {
        final previousTree = _createSkillTree(5);
        previousTree.trees[0].allocatedTiers = 2; // ATK: 2 tiers
        previousTree.trees[1].allocatedTiers = 2; // DEF: 2 tiers
        previousTree.trees[2].allocatedTiers = 1; // SPD: 1 tier

        when(mockFirestore.get('users/user_123'))
            .thenAnswer((_) async => {'skillTree': previousTree.toJson()});

        when(mockFirestore.set(any, any)).thenAnswer((_) async {});
        when(mockFirestore.update(any, any)).thenAnswer((_) async {});

        final newTree = await service.resetForNewSeason(
          'user_123',
          'season_1',
          'season_2',
          'Diamond',
          CarryoverMode.full,
        );

        expect(newTree.trees[0].allocatedTiers, equals(2));
        expect(newTree.trees[1].allocatedTiers, equals(2));
        expect(newTree.trees[2].allocatedTiers, equals(1));
      });
    });

    group('getSeasonHistory', () {
      test('returns snapshots sorted by date', () async {
        final snapshots = [
          _createSnapshot('season_2', DateTime(2024, 1, 20)),
          _createSnapshot('season_1', DateTime(2024, 1, 10)),
          _createSnapshot('season_3', DateTime(2024, 1, 30)),
        ];

        when(mockFirestore.getCollection('users/user_123/season_snapshots'))
            .thenAnswer((_) async =>
                snapshots.map((s) => s.toJson()).toList());

        final result = await service.getSeasonHistory('user_123');

        expect(result.length, equals(3));
        expect(result[0].seasonId, equals('season_1')); // Sorted chronologically
        expect(result[1].seasonId, equals('season_2'));
        expect(result[2].seasonId, equals('season_3'));
      });

      test('returns empty list when no snapshots exist', () async {
        when(mockFirestore.getCollection('users/user_123/season_snapshots'))
            .thenAnswer((_) async => []);

        final result = await service.getSeasonHistory('user_123');
        expect(result, isEmpty);
      });
    });

    group('compareSeasons', () {
      test('calculates points gained between seasons', () async {
        final snapshot1 = _createSnapshot('season_1', DateTime.now(), totalPoints: 3);
        final snapshot2 = _createSnapshot('season_2', DateTime.now(), totalPoints: 5);

        when(mockFirestore.get('users/user_123/season_snapshots/season_1'))
            .thenAnswer((_) async => snapshot1.toJson());

        when(mockFirestore.get('users/user_123/season_snapshots/season_2'))
            .thenAnswer((_) async => snapshot2.toJson());

        final delta = await service.compareSeasons('user_123', 'season_1', 'season_2');

        expect(delta.pointsGained, equals(2));
      });

      test('detects promotion (tier upgrade)', () async {
        final snapshot1 = _createSnapshot('season_1', DateTime.now(), tier: 'Silver');
        final snapshot2 = _createSnapshot('season_2', DateTime.now(), tier: 'Gold');

        when(mockFirestore.get('users/user_123/season_snapshots/season_1'))
            .thenAnswer((_) async => snapshot1.toJson());

        when(mockFirestore.get('users/user_123/season_snapshots/season_2'))
            .thenAnswer((_) async => snapshot2.toJson());

        final delta = await service.compareSeasons('user_123', 'season_1', 'season_2');

        expect(delta.isPromotion, isTrue);
        expect(delta.fromTier, equals('Silver'));
        expect(delta.toTier, equals('Gold'));
      });

      test('detects demotion (tier downgrade)', () async {
        final snapshot1 = _createSnapshot('season_1', DateTime.now(), tier: 'Gold');
        final snapshot2 = _createSnapshot('season_2', DateTime.now(), tier: 'Silver');

        when(mockFirestore.get('users/user_123/season_snapshots/season_1'))
            .thenAnswer((_) async => snapshot1.toJson());

        when(mockFirestore.get('users/user_123/season_snapshots/season_2'))
            .thenAnswer((_) async => snapshot2.toJson());

        final delta = await service.compareSeasons('user_123', 'season_1', 'season_2');

        expect(delta.isPromotion, isFalse);
      });

      test('calculates carryover percentage', () async {
        final snapshot1 = _createSnapshot('season_1', DateTime.now(), totalPoints: 4);
        final snapshot2 = _createSnapshot('season_2', DateTime.now(), totalPoints: 2);

        when(mockFirestore.get('users/user_123/season_snapshots/season_1'))
            .thenAnswer((_) async => snapshot1.toJson());

        when(mockFirestore.get('users/user_123/season_snapshots/season_2'))
            .thenAnswer((_) async => snapshot2.toJson());

        final delta = await service.compareSeasons('user_123', 'season_1', 'season_2');

        // 2 / 4 * 100 = 50%
        expect(delta.carryoverPercentage, equals(50.0));
      });

      test('throws when snapshot missing', () async {
        when(mockFirestore.get('users/user_123/season_snapshots/season_1'))
            .thenAnswer((_) async => null);

        when(mockFirestore.get('users/user_123/season_snapshots/season_2'))
            .thenAnswer((_) async => {});

        expect(
          () => service.compareSeasons('user_123', 'season_1', 'season_2'),
          throwsException,
        );
      });
    });

    group('validateCarryover', () {
      test('validates none carryover with 0 points', () {
        final reset = SkillTreeReset(
          seasonId: 'season_1',
          nextSeasonId: 'season_2',
          userId: 'user_123',
          previousTree: _createSkillTree(5),
          currentTree: _createSkillTree(0),
          resetAt: DateTime.now(),
          carryoverMode: CarryoverMode.none,
          pointsCarriedOver: 0,
        );

        final isValid = service.validateCarryover(reset, CarryoverMode.none);
        expect(isValid, isTrue);
      });

      test('validates partial carryover with correct math', () {
        final previousTree = _createSkillTree(5);
        final currentTree = _createSkillTree(2); // 50% of 5

        final reset = SkillTreeReset(
          seasonId: 'season_1',
          nextSeasonId: 'season_2',
          userId: 'user_123',
          previousTree: previousTree,
          currentTree: currentTree,
          resetAt: DateTime.now(),
          carryoverMode: CarryoverMode.partial,
          pointsCarriedOver: 2,
        );

        final isValid = service.validateCarryover(reset, CarryoverMode.partial);
        expect(isValid, isTrue);
      });

      test('validates full carryover preserves all points', () {
        final previousTree = _createSkillTree(5);
        final currentTree = _createSkillTree(5);

        final reset = SkillTreeReset(
          seasonId: 'season_1',
          nextSeasonId: 'season_2',
          userId: 'user_123',
          previousTree: previousTree,
          currentTree: currentTree,
          resetAt: DateTime.now(),
          carryoverMode: CarryoverMode.full,
          pointsCarriedOver: 5,
        );

        final isValid = service.validateCarryover(reset, CarryoverMode.full);
        expect(isValid, isTrue);
      });

      test('rejects invalid mode mismatch', () {
        final reset = SkillTreeReset(
          seasonId: 'season_1',
          nextSeasonId: 'season_2',
          userId: 'user_123',
          previousTree: _createSkillTree(5),
          currentTree: _createSkillTree(0),
          resetAt: DateTime.now(),
          carryoverMode: CarryoverMode.none,
          pointsCarriedOver: 0,
        );

        final isValid = service.validateCarryover(reset, CarryoverMode.partial);
        expect(isValid, isFalse);
      });
    });
  });
}

// Helper functions

SkillTree _createSkillTree(int pointsToAllocate) {
  final tree = SkillTree.create();
  int remaining = pointsToAllocate;

  for (int treeIdx = 0; treeIdx < 3 && remaining > 0; treeIdx++) {
    while (tree.trees[treeIdx].allocatedTiers < 5 && remaining > 0) {
      tree.trees[treeIdx].allocatedTiers += 1;
      remaining--;
    }
  }

  tree.totalAllocatedPoints = pointsToAllocate;
  tree.availablePoints = 0;

  return tree;
}

SkillTreeSnapshot _createSnapshot(
  String seasonId,
  DateTime snapshotAt, {
  int totalPoints = 3,
  String tier = 'Gold',
}) {
  return SkillTreeSnapshot(
    seasonId: seasonId,
    snapshotAt: snapshotAt,
    treeState: _createSkillTree(totalPoints),
    finalTier: tier,
    totalPointsAllocated: totalPoints,
    treePointsBreakdown: {
      'atk': 1,
      'def': 1,
      'spd': totalPoints - 2,
    },
  );
}
