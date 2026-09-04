import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/season_model.dart';

/// Service for managing ranked seasons
///
/// Responsibilities:
/// - Create and manage season lifecycle
/// - Query active/past seasons
/// - Distribute seasonal rewards
class SeasonService {
  final FirebaseFirestore _firestore;

  SeasonService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get currently active season
  ///
  /// Only one season should be active at a time
  Future<RankedSeason?> getActiveSeason() async {
    try {
      final query = await _firestore
          .collection('seasons')
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (query.docs.isEmpty) return null;

      return RankedSeason.fromJson(query.docs.first.data());
    } catch (e) {
      print('[SeasonService] Error fetching active season: $e');
      return null;
    }
  }

  /// Get season by ID
  Future<RankedSeason?> getSeasonById(String seasonId) async {
    try {
      final doc =
          await _firestore.collection('seasons').doc(seasonId).get();
      if (!doc.exists) return null;
      return RankedSeason.fromJson(doc.data()!);
    } catch (e) {
      print('[SeasonService] Error fetching season $seasonId: $e');
      return null;
    }
  }

  /// Create a new season
  ///
  /// First deactivates any existing active season
  Future<String> createSeason({
    required String name,
    required DateTime startedAt,
    required DateTime endsAt,
    required Map<String, int> tierThresholds,
    required Map<String, List<String>> rewardsByTier,
    required SeasonRules rules,
  }) async {
    try {
      // Deactivate current active season
      final activeSeasons = await _firestore
          .collection('seasons')
          .where('isActive', isEqualTo: true)
          .get();

      final batch = _firestore.batch();
      for (final doc in activeSeasons.docs) {
        batch.update(doc.reference, {'isActive': false});
      }

      // Create new season
      final newSeasonRef = _firestore.collection('seasons').doc();
      final season = RankedSeason(
        seasonId: newSeasonRef.id,
        name: name,
        startedAt: startedAt,
        endsAt: endsAt,
        isActive: true,
        tierThresholds: tierThresholds,
        rewardsByTier: rewardsByTier,
        rules: rules,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      batch.set(newSeasonRef, season.toJson());
      await batch.commit();

      print('[SeasonService] Created season: ${newSeasonRef.id}');
      return newSeasonRef.id;
    } catch (e) {
      print('[SeasonService] Error creating season: $e');
      rethrow;
    }
  }

  /// Check if a season is currently active
  Future<bool> isSeasonActive(String seasonId) async {
    try {
      final doc =
          await _firestore.collection('seasons').doc(seasonId).get();
      if (!doc.exists) return false;

      final now = DateTime.now();
      final data = doc.data()!;
      final startedAt = (data['startedAt'] as Timestamp).toDate();
      final endsAt = (data['endsAt'] as Timestamp).toDate();

      return now.isAfter(startedAt) &&
          now.isBefore(endsAt) &&
          (data['isActive'] as bool? ?? false);
    } catch (e) {
      print('[SeasonService] Error checking season active status: $e');
      return false;
    }
  }

  /// End season and distribute rewards
  ///
  /// This should be called via Cloud Function on season end
  Future<void> endSeason(String seasonId) async {
    try {
      await _firestore
          .collection('seasons')
          .doc(seasonId)
          .update({'isActive': false});

      print('[SeasonService] Season $seasonId ended');
      // Reward distribution is handled by Cloud Function
    } catch (e) {
      print('[SeasonService] Error ending season: $e');
      rethrow;
    }
  }

  /// Get all past seasons
  Future<List<RankedSeason>> getPastSeasons({int limit = 10}) async {
    try {
      final query = await _firestore
          .collection('seasons')
          .where('isActive', isEqualTo: false)
          .orderBy('endsAt', descending: true)
          .limit(limit)
          .get();

      return query.docs
          .map((doc) => RankedSeason.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('[SeasonService] Error fetching past seasons: $e');
      return [];
    }
  }

  /// Get tier thresholds for current season
  Future<Map<String, int>> getCurrentTierThresholds() async {
    try {
      final season = await getActiveSeason();
      return season?.tierThresholds ?? _defaultTierThresholds();
    } catch (e) {
      print('[SeasonService] Error fetching tier thresholds: $e');
      return _defaultTierThresholds();
    }
  }

  /// Default tier thresholds (fallback)
  Map<String, int> _defaultTierThresholds() {
    return {
      'Bronze': 400,
      'Silver': 1400,
      'Gold': 1800,
      'Platinum': 2200,
      'Legend': 2800,
    };
  }
}
