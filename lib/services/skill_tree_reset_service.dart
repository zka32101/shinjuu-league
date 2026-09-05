import 'package:shinjuu_league/data/models/skill_model.dart';
import 'package:shinjuu_league/data/models/skill_tree_reset.dart';
import 'package:shinjuu_league/services/firestore_service.dart';

/// Service for managing skill tree resets at season boundaries
class SkillTreeResetService {
  final FirestoreService _firestoreService;

  /// Carryover calculation constants
  static const double partialCarryoverPercentage = 0.5; // 50% carryover for partial mode

  SkillTreeResetService(this._firestoreService);

  /// Reset skill tree for new season with specified carryover mode
  /// Returns the new skill tree after reset
  Future<SkillTree> resetForNewSeason(
    String userId,
    String currentSeasonId,
    String nextSeasonId,
    String finalTier,
    CarryoverMode carryoverMode,
  ) async {
    // Get current skill tree
    final previousTree = await _getSkillTree(userId);
    if (previousTree == null) {
      throw Exception('No skill tree found for user: $userId');
    }

    // Create snapshot of previous season
    final snapshot = SkillTreeSnapshot(
      seasonId: currentSeasonId,
      snapshotAt: DateTime.now(),
      treeState: previousTree,
      finalTier: finalTier,
      totalPointsAllocated: previousTree.totalAllocatedPoints,
      treePointsBreakdown: {
        'atk': previousTree.trees[0].allocatedTiers,
        'def': previousTree.trees[1].allocatedTiers,
        'spd': previousTree.trees[2].allocatedTiers,
      },
    );

    // Create new tree with carryover
    final newTree = SkillTree.create();
    int pointsCarriedOver = 0;

    switch (carryoverMode) {
      case CarryoverMode.none:
        // Complete reset: start fresh with 0 points
        pointsCarriedOver = 0;
        break;

      case CarryoverMode.partial:
        // 50% carryover with round-down
        pointsCarriedOver = (previousTree.totalAllocatedPoints * partialCarryoverPercentage).floor();
        _applyCarryoverPoints(newTree, pointsCarriedOver);
        break;

      case CarryoverMode.full:
        // Keep all points from previous season
        pointsCarriedOver = previousTree.totalAllocatedPoints;
        _copyTreeState(previousTree, newTree);
        break;
    }

    // Create reset record
    final reset = SkillTreeReset(
      seasonId: currentSeasonId,
      nextSeasonId: nextSeasonId,
      userId: userId,
      previousTree: previousTree,
      currentTree: newTree,
      resetAt: DateTime.now(),
      carryoverMode: carryoverMode,
      pointsCarriedOver: pointsCarriedOver,
    );

    // Save to Firestore
    await _firestoreService.set(
      'users/$userId/season_resets/$nextSeasonId',
      reset,
    );

    // Save season snapshot
    await _firestoreService.set(
      'users/$userId/season_snapshots/$currentSeasonId',
      snapshot,
    );

    // Update user's current skill tree
    await _firestoreService.update(
      'users/$userId',
      {'skillTree': newTree.toJson()},
    );

    return newTree;
  }

  /// Apply carried-over points to new tree (partial carryover)
  void _applyCarryoverPoints(SkillTree newTree, int pointsToAllocate) {
    int remaining = pointsToAllocate;

    // Allocate to trees in order: ATK → DEF → SPD
    for (int treeIdx = 0; treeIdx < 3 && remaining > 0; treeIdx++) {
      while (newTree.trees[treeIdx].allocatedTiers < 5 && remaining > 0) {
        newTree.trees[treeIdx].allocatedTiers += 1;
        remaining--;
      }
    }
  }

  /// Full copy of tree state from previous to new
  void _copyTreeState(SkillTree source, SkillTree dest) {
    for (int i = 0; i < 3; i++) {
      dest.trees[i].allocatedTiers = source.trees[i].allocatedTiers;
    }
    dest.totalAllocatedPoints = source.totalAllocatedPoints;
    dest.availablePoints = source.availablePoints;
  }

  /// Get all season snapshots for a user (progression history)
  Future<List<SkillTreeSnapshot>> getSeasonHistory(String userId) async {
    final docs = await _firestoreService.getCollection(
      'users/$userId/season_snapshots',
    );

    return docs
        .map((doc) => SkillTreeSnapshot.fromJson(doc))
        .toList()
      ..sort((a, b) => a.snapshotAt.compareTo(b.snapshotAt));
  }

  /// Get all reset records for a user
  Future<List<SkillTreeReset>> getResetHistory(String userId) async {
    final docs = await _firestoreService.getCollection(
      'users/$userId/season_resets',
    );

    return docs
        .map((doc) => SkillTreeReset.fromJson(doc))
        .toList()
      ..sort((a, b) => a.resetAt.compareTo(b.resetAt));
  }

  /// Compare two seasons' progression
  Future<ProgressDelta> compareSeasons(
    String userId,
    String season1Id,
    String season2Id,
  ) async {
    final snapshot1 = await _getSeasonSnapshot(userId, season1Id);
    final snapshot2 = await _getSeasonSnapshot(userId, season2Id);

    if (snapshot1 == null || snapshot2 == null) {
      throw Exception('Cannot compare: missing snapshot data');
    }

    final pointsGained = snapshot2.totalPointsAllocated - snapshot1.totalPointsAllocated;
    final pointsLost = snapshot1.totalPointsAllocated -
        snapshot2.totalPointsAllocated.clamp(0, snapshot1.totalPointsAllocated);

    final carryoverPercentage = snapshot1.totalPointsAllocated > 0
        ? (snapshot2.totalPointsAllocated / snapshot1.totalPointsAllocated) * 100
        : 0.0;

    // Calculate per-tree deltas
    final treeDeltas = {
      'atk': (snapshot2.treePointsBreakdown['atk'] ?? 0) -
          (snapshot1.treePointsBreakdown['atk'] ?? 0),
      'def': (snapshot2.treePointsBreakdown['def'] ?? 0) -
          (snapshot1.treePointsBreakdown['def'] ?? 0),
      'spd': (snapshot2.treePointsBreakdown['spd'] ?? 0) -
          (snapshot1.treePointsBreakdown['spd'] ?? 0),
    };

    final isPromotion = _isTierPromotion(snapshot1.finalTier, snapshot2.finalTier);

    return ProgressDelta(
      fromSeasonId: season1Id,
      toSeasonId: season2Id,
      pointsGained: pointsGained.clamp(0, 15),
      pointsLost: pointsLost.clamp(0, 15),
      carryoverPercentage: carryoverPercentage,
      treeDeltas: treeDeltas,
      fromTier: snapshot1.finalTier,
      toTier: snapshot2.finalTier,
      isPromotion: isPromotion,
    );
  }

  /// Get snapshot for a specific season
  Future<SkillTreeSnapshot?> _getSeasonSnapshot(
    String userId,
    String seasonId,
  ) async {
    final doc = await _firestoreService.get(
      'users/$userId/season_snapshots/$seasonId',
    );

    if (doc == null) return null;
    return SkillTreeSnapshot.fromJson(doc);
  }

  /// Get reset record for a specific season
  Future<SkillTreeReset?> _getSeasonReset(
    String userId,
    String seasonId,
  ) async {
    final doc = await _firestoreService.get(
      'users/$userId/season_resets/$seasonId',
    );

    if (doc == null) return null;
    return SkillTreeReset.fromJson(doc);
  }

  /// Get current skill tree for user
  Future<SkillTree?> _getSkillTree(String userId) async {
    try {
      final doc = await _firestoreService.get('users/$userId');
      if (doc == null) return null;

      final skillTreeData = doc['skillTree'];
      if (skillTreeData == null) return null;

      return SkillTree.fromJson(skillTreeData as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  /// Tier progression order for promotion detection
  static const List<String> tierProgression = [
    'Bronze',
    'Silver',
    'Gold',
    'Platinum',
    'Diamond',
  ];

  /// Check if tier changed from demotion to promotion
  bool _isTierPromotion(String fromTier, String toTier) {
    final fromIdx = tierProgression.indexOf(fromTier);
    final toIdx = tierProgression.indexOf(toTier);

    if (fromIdx < 0 || toIdx < 0) return false;
    return toIdx > fromIdx;
  }

  /// Validate carryover calculation for integrity
  /// Used for server-side audit/verification
  bool validateCarryover(
    SkillTreeReset reset,
    CarryoverMode expectedMode,
  ) {
    if (reset.carryoverMode != expectedMode) return false;

    final previousTotal = reset.previousTree.totalAllocatedPoints;
    final currentTotal = reset.currentTree.totalAllocatedPoints;

    switch (expectedMode) {
      case CarryoverMode.none:
        return currentTotal == 0;

      case CarryoverMode.partial:
        final expected = (previousTotal * partialCarryoverPercentage).floor();
        return reset.pointsCarriedOver == expected &&
            currentTotal == expected;

      case CarryoverMode.full:
        return reset.pointsCarriedOver == previousTotal &&
            currentTotal == previousTotal;
    }
  }
}
