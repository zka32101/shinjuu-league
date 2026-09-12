import 'package:shinjuu_league/data/models/seasonal_reward.dart';
import 'package:shinjuu_league/services/firestore_service.dart';

/// Service for managing seasonal reward distribution and claiming
class SeasonRewardService {
  final FirestoreService _firestoreService;

  /// Tier thresholds and their associated rewards (configurable)
  static const Map<String, List<SeasonalReward>> tierRewardMap = {
    'Bronze': [
      SeasonalReward(
        rewardId: 'bronze_currency_100',
        tier: 'Bronze',
        rewardType: RewardType.currency,
        quantity: 100,
        displayName: 'Bronze Reward',
        iconUrl: 'assets/icons/bronze_coins.png',
      ),
    ],
    'Silver': [
      SeasonalReward(
        rewardId: 'silver_currency_250',
        tier: 'Silver',
        rewardType: RewardType.currency,
        quantity: 250,
        displayName: 'Silver Reward',
        iconUrl: 'assets/icons/silver_coins.png',
      ),
      SeasonalReward(
        rewardId: 'silver_bp_item_1',
        tier: 'Silver',
        rewardType: RewardType.battle_pass_item,
        quantity: 1,
        displayName: 'Silver Emote',
        iconUrl: 'assets/icons/emote_silver.png',
      ),
    ],
    'Gold': [
      SeasonalReward(
        rewardId: 'gold_currency_500',
        tier: 'Gold',
        rewardType: RewardType.currency,
        quantity: 500,
        displayName: 'Gold Reward',
        iconUrl: 'assets/icons/gold_coins.png',
      ),
      SeasonalReward(
        rewardId: 'gold_skin_1',
        tier: 'Gold',
        rewardType: RewardType.cosmetic_skin,
        quantity: 1,
        displayName: 'Gold Skin',
        iconUrl: 'assets/icons/skin_gold.png',
      ),
    ],
    'Platinum': [
      SeasonalReward(
        rewardId: 'platinum_currency_1000',
        tier: 'Platinum',
        rewardType: RewardType.currency,
        quantity: 1000,
        displayName: 'Platinum Reward',
        iconUrl: 'assets/icons/platinum_coins.png',
      ),
      SeasonalReward(
        rewardId: 'platinum_skin_1',
        tier: 'Platinum',
        rewardType: RewardType.cosmetic_skin,
        quantity: 1,
        displayName: 'Platinum Skin',
        iconUrl: 'assets/icons/skin_platinum.png',
      ),
      SeasonalReward(
        rewardId: 'platinum_bp_item_2',
        tier: 'Platinum',
        rewardType: RewardType.battle_pass_item,
        quantity: 2,
        displayName: 'Platinum Bundle',
        iconUrl: 'assets/icons/bp_platinum.png',
      ),
    ],
    'Diamond': [
      SeasonalReward(
        rewardId: 'diamond_currency_2000',
        tier: 'Diamond',
        rewardType: RewardType.currency,
        quantity: 2000,
        displayName: 'Diamond Reward',
        iconUrl: 'assets/icons/diamond_coins.png',
      ),
      SeasonalReward(
        rewardId: 'diamond_skin_2',
        tier: 'Diamond',
        rewardType: RewardType.cosmetic_skin,
        quantity: 2,
        displayName: 'Diamond Skin Bundle',
        iconUrl: 'assets/icons/skin_diamond.png',
      ),
      SeasonalReward(
        rewardId: 'diamond_bp_item_3',
        tier: 'Diamond',
        rewardType: RewardType.battle_pass_item,
        quantity: 3,
        displayName: 'Diamond Premium Bundle',
        iconUrl: 'assets/icons/bp_diamond.png',
      ),
    ],
  };

  SeasonRewardService(this._firestoreService);

  /// Get all rewards for a specific tier
  Future<List<SeasonalReward>> getRewardsForTier(String tier) async {
    return tierRewardMap[tier] ?? [];
  }

  /// Distribute rewards to a player based on final tier
  /// Should be called at end of season
  Future<void> distributeSeasonRewards(
    String seasonId,
    String userId,
    String finalTier,
  ) async {
    final rewards = tierRewardMap[finalTier] ?? [];
    if (rewards.isEmpty) {
      throw Exception('Invalid tier: $finalTier');
    }

    final now = DateTime.now();
    final expiresAt = now.add(const Duration(days: 30)); // 30-day claim window

    final distribution = SeasonRewardDistribution(
      seasonId: seasonId,
      userId: userId,
      finalTier: finalTier,
      rewards: rewards,
      distributedAt: now,
      claimedAt: null,
      expiresAt: expiresAt,
    );

    // Save to Firestore: /users/{userId}/season_rewards/{rewardId}
    await _firestoreService.set(
      'users/$userId/season_rewards/$seasonId',
      distribution,
    );
  }

  /// Claim rewards for a player
  /// Can only be claimed once, within the expiration window
  Future<bool> claimRewards(String userId, String seasonId) async {
    // Fetch current distribution
    final doc = await _firestoreService.get(
      'users/$userId/season_rewards/$seasonId',
    );

    if (doc == null) {
      throw Exception('No rewards found for season: $seasonId');
    }

    final distribution = SeasonRewardDistribution.fromJson(doc);

    // Check if already claimed
    if (distribution.isClaimed) {
      throw Exception('Rewards already claimed');
    }

    // Check if claim window expired
    if (distribution.isExpired) {
      throw Exception('Claim window has expired');
    }

    // Update with claim timestamp
    final updated = distribution.copyWith(claimedAt: DateTime.now());

    await _firestoreService.update(
      'users/$userId/season_rewards/$seasonId',
      updated,
    );

    return true;
  }

  /// Get all season rewards for a player
  Future<List<SeasonRewardDistribution>> getPlayerSeasonRewards(
    String userId,
  ) async {
    final docs = await _firestoreService.getCollection(
      'users/$userId/season_rewards',
    );

    return docs
        .map((doc) => SeasonRewardDistribution.fromJson(doc))
        .toList();
  }

  /// Get unclaimed rewards for a player
  Future<List<SeasonRewardDistribution>> getUnclaimedRewards(
    String userId,
  ) async {
    final allRewards = await getPlayerSeasonRewards(userId);
    return allRewards.where((r) => r.isClaimableWindow).toList();
  }

  /// Get rewards status (claimed/unclaimed/expired)
  Future<SeasonRewardStatus> getRewardStatus(
    String userId,
    String seasonId,
  ) async {
    final doc = await _firestoreService.get(
      'users/$userId/season_rewards/$seasonId',
    );

    if (doc == null) {
      return SeasonRewardStatus.notFound;
    }

    final distribution = SeasonRewardDistribution.fromJson(doc);

    if (distribution.isClaimed) {
      return SeasonRewardStatus.claimed;
    }

    if (distribution.isExpired) {
      return SeasonRewardStatus.expired;
    }

    return SeasonRewardStatus.pending;
  }
}

/// Reward claim status enum
enum SeasonRewardStatus {
  notFound,   // No rewards for this season
  pending,    // Available to claim
  claimed,    // Already claimed
  expired,    // Claim window closed
}
