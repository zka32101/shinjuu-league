import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:shinjuu_league/data/models/skill_tree.dart';

part 'skill_tree_reset.freezed.dart';
part 'skill_tree_reset.g.dart';

/// Carryover mode for skill tree reset at season transition
enum CarryoverMode {
  none,      // Complete reset: all tiers → 0 points
  partial,   // 50% carryover: 5 points → 2-3 points
  full,      // Keep all points: retain tier progress
}

/// Snapshot of skill tree state at a specific season
@freezed
class SkillTreeSnapshot with _$SkillTreeSnapshot {
  const factory SkillTreeSnapshot({
    required String seasonId,
    required DateTime snapshotAt,
    required SkillTree treeState,
    required String finalTier,           // Bronze/Silver/Gold/Platinum/Diamond
    required int totalPointsAllocated,
    required Map<String, int> treePointsBreakdown, // {atkPoints, defPoints, spdPoints}
  }) = _SkillTreeSnapshot;

  factory SkillTreeSnapshot.fromJson(Map<String, dynamic> json) =>
      _$SkillTreeSnapshotFromJson(json);
}

/// Reset record for a skill tree at season boundary
@freezed
class SkillTreeReset with _$SkillTreeReset {
  const factory SkillTreeReset({
    required String seasonId,
    required String nextSeasonId,
    required String userId,
    required SkillTree previousTree,     // Backup of last season
    required SkillTree currentTree,      // Fresh allocation post-reset
    required DateTime resetAt,
    required CarryoverMode carryoverMode,
    required int pointsCarriedOver,      // Total points preserved
  }) = _SkillTreeReset;

  factory SkillTreeReset.fromJson(Map<String, dynamic> json) =>
      _$SkillTreeResetFromJson(json);

  /// Get the delta in points for each tree
  Map<String, int> getPointsDelta() {
    final previous = previousTree;
    final current = currentTree;

    return {
      'atk': current.attackTree.totalPoints - previous.attackTree.totalPoints,
      'def': current.defenseTree.totalPoints - previous.defenseTree.totalPoints,
      'spd': current.speedTree.totalPoints - previous.speedTree.totalPoints,
    };
  }

  /// Calculate carryover efficiency (carried / available)
  double getCarryoverEfficiency() {
    final previousTotal = previousTree.totalPoints;
    if (previousTotal == 0) return 0.0;
    return pointsCarriedOver / previousTotal;
  }
}

/// Comparison between two seasons' skill tree states
@freezed
class ProgressDelta with _$ProgressDelta {
  const factory ProgressDelta({
    required String fromSeasonId,
    required String toSeasonId,
    required int pointsGained,           // Total new points allocated
    required int pointsLost,             // Points lost to reset
    required double carryoverPercentage, // % of previous points kept
    required Map<String, int> treeDeltas, // Per-tree point changes
    required String fromTier,
    required String toTier,
    required bool isPromotion,
  }) = _ProgressDelta;

  factory ProgressDelta.fromJson(Map<String, dynamic> json) =>
      _$ProgressDeltaFromJson(json);
}

/// Season boundaries and reset configuration
@freezed
class SeasonResetConfig with _$SeasonResetConfig {
  const factory SeasonResetConfig({
    required String seasonId,
    required String nextSeasonId,
    required DateTime endDate,
    required DateTime resetDate,        // When resets occur
    required CarryoverMode defaultCarryoverMode,
    required bool allowManualReset,     // Allow player-initiated full reset
  }) = _SeasonResetConfig;

  factory SeasonResetConfig.fromJson(Map<String, dynamic> json) =>
      _$SeasonResetConfigFromJson(json);

  /// Check if season is active
  bool get isActive {
    final now = DateTime.now();
    return now.isBefore(endDate);
  }

  /// Days until season ends
  int get daysUntilEnd {
    return endDate.difference(DateTime.now()).inDays;
  }
}
