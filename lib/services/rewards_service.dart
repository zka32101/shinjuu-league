import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/season_model.dart';

/// Service for managing seasonal rewards
///
/// Responsibilities:
/// - Create and catalog seasonal rewards
/// - Track earned rewards per user/season
/// - Handle reward claiming
class RewardsService {
  final FirebaseFirestore _firestore;

  RewardsService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Create seasonal rewards for a season
  ///
  /// Maps tiers to reward items
  Future<void> createSeasonalRewards({
    required String seasonId,
    required Map<String, List<RewardTemplate>> rewardsByTier,
  }) async {
    try {
      final batch = _firestore.batch();

      for (final tier in rewardsByTier.keys) {
        final rewards = rewardsByTier[tier]!;

        for (final template in rewards) {
          final rewardRef = _firestore.collection('rewards').doc();
          final reward = SeasonalReward(
            rewardId: rewardRef.id,
            seasonId: seasonId,
            tier: tier,
            type: template.type,
            displayName: template.displayName,
            description: template.description,
            iconUrl: template.iconUrl,
            currencyAmount: template.currencyAmount,
            isLimited: template.isLimited,
            createdAt: DateTime.now(),
          );

          batch.set(rewardRef, reward.toJson());
        }
      }

      await batch.commit();
      print('[RewardsService] Created rewards for season $seasonId');
    } catch (e) {
      print('[RewardsService] Error creating rewards: $e');
      rethrow;
    }
  }

  /// Get rewards for a tier in a season
  Future<List<SeasonalReward>> getTierRewards(
    String seasonId,
    String tier,
  ) async {
    try {
      final query = await _firestore
          .collection('rewards')
          .where('seasonId', isEqualTo: seasonId)
          .where('tier', isEqualTo: tier)
          .get();

      return query.docs
          .map((doc) => SeasonalReward.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('[RewardsService] Error fetching tier rewards: $e');
      return [];
    }
  }

  /// Award rewards to a user for reaching a tier
  Future<void> awardRewards({
    required String userId,
    required String seasonId,
    required String tier,
    required List<String> rewardIds,
  }) async {
    try {
      final userSeasonRef =
          _firestore.doc('users/$userId/season_data/$seasonId');

      await userSeasonRef.update({
        'earnedRewards': FieldValue.arrayUnion(rewardIds),
      });

      print(
        '[RewardsService] Awarded ${rewardIds.length} '
        'rewards to $userId for tier $tier',
      );
    } catch (e) {
      print('[RewardsService] Error awarding rewards: $e');
      rethrow;
    }
  }

  /// Claim earned rewards (mark as claimed)
  Future<void> claimRewards({
    required String userId,
    required String seasonId,
  }) async {
    try {
      await _firestore
          .doc('users/$userId/season_data/$seasonId')
          .update({'rewardsClaimed': true});

      print('[RewardsService] Marked rewards as claimed for $userId');
    } catch (e) {
      print('[RewardsService] Error claiming rewards: $e');
      rethrow;
    }
  }

  /// Get earned but unclaimed rewards
  Future<List<SeasonalReward>> getUnclaimedRewards(
    String userId,
    String seasonId,
  ) async {
    try {
      final seasonalDoc = await _firestore
          .doc('users/$userId/season_data/$seasonId')
          .get();

      if (!seasonalDoc.exists) return [];

      final data = seasonalDoc.data() as Map<String, dynamic>;
      final earnedRewardIds =
          (data['earnedRewards'] as List<dynamic>? ?? []).cast<String>();

      if (earnedRewardIds.isEmpty) return [];

      final rewards = <SeasonalReward>[];
      for (final rewardId in earnedRewardIds) {
        final doc = await _firestore.collection('rewards').doc(rewardId).get();
        if (doc.exists) {
          rewards.add(SeasonalReward.fromJson(doc.data()!));
        }
      }

      return rewards;
    } catch (e) {
      print('[RewardsService] Error fetching unclaimed rewards: $e');
      return [];
    }
  }

  /// Distribute rewards at end of season (Cloud Function should call this)
  Future<void> distributeSeasonRewards({
    required String seasonId,
    required Map<String, List<String>> usersByTier,
  }) async {
    try {
      final batch = _firestore.batch();

      for (final tier in usersByTier.keys) {
        final userIds = usersByTier[tier]!;
        final tierRewards = await getTierRewards(seasonId, tier);
        final rewardIds =
            tierRewards.map((r) => r.rewardId).toList();

        for (final userId in userIds) {
          final userSeasonRef =
              _firestore.doc('users/$userId/season_data/$seasonId');

          batch.update(userSeasonRef, {
            'earnedRewards': FieldValue.arrayUnion(rewardIds),
          });
        }
      }

      await batch.commit();
      print('[RewardsService] Distributed seasonal rewards for season $seasonId');
    } catch (e) {
      print('[RewardsService] Error distributing rewards: $e');
      rethrow;
    }
  }

  /// Get reward by ID
  Future<SeasonalReward?> getRewardById(String rewardId) async {
    try {
      final doc = await _firestore.collection('rewards').doc(rewardId).get();
      return doc.exists ? SeasonalReward.fromJson(doc.data()!) : null;
    } catch (e) {
      print('[RewardsService] Error fetching reward: $e');
      return null;
    }
  }
}

/// Template for creating seasonal rewards
class RewardTemplate {
  final String type; // 'cosmetic_skin', 'currency', 'badge', 'emote'
  final String displayName;
  final String description;
  final String? iconUrl;
  final int? currencyAmount;
  final bool isLimited;

  RewardTemplate({
    required this.type,
    required this.displayName,
    required this.description,
    this.iconUrl,
    this.currencyAmount,
    this.isLimited = false,
  });
}
