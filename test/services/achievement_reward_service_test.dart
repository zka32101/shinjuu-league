import 'package:flutter_test/flutter_test.dart';
import 'package:shinjuu_league/data/models/achievement.dart';
import 'package:shinjuu_league/services/achievement_reward_service.dart';
import 'package:shinjuu_league/services/firestore_service.dart';

// Mock FirestoreService for testing
class MockFirestoreService extends FirestoreService {
  final Map<String, dynamic> _userData = {};
  final Map<String, Set<String>> _achievements = {};

  @override
  Future<void> markAchievementUnlocked(String userId, String achievementId) async {
    _achievements.putIfAbsent(userId, () => {}).add(achievementId);
  }

  @override
  Future<void> incrementUserCurrency(String userId, int amount) async {
    _userData[userId] ??= {'currency': 0};
    _userData[userId]!['currency'] = (_userData[userId]!['currency'] ?? 0) + amount;
  }

  @override
  Future<void> incrementUserAchievementBadges(String userId, int count) async {
    _userData[userId] ??= {'badges': 0};
    _userData[userId]!['badges'] = (_userData[userId]!['badges'] ?? 0) + count;
  }

  @override
  Future<void> addUserCosmetic(String userId, String cosmeticId) async {
    _userData.putIfAbsent(userId, () => {'cosmetics': []});
    (_userData[userId]!['cosmetics'] as List<String>).add(cosmeticId);
  }

  void resetMockData() {
    _userData.clear();
    _achievements.clear();
  }
}

void main() {
  group('AchievementRewardService', () {
    late AchievementRewardService service;
    late MockFirestoreService firestoreService;

    final testUserId = 'user_123';

    setUp(() {
      firestoreService = MockFirestoreService();
      service = AchievementRewardService(firestoreService: firestoreService);
    });

    tearDown(() {
      firestoreService.resetMockData();
    });

    test('processes unlock and calculates rewards for bronze tier', () async {
      final achievement = AchievementsCatalog.firstBlood;

      final rewards = await service.processUnlock(testUserId, achievement);

      expect(rewards['currency'], equals(50));
      expect(rewards['badges'], equals(1));
      expect(rewards['tier'], equals('bronze'));
    });

    test('processes unlock and calculates rewards for silver tier', () async {
      final achievement = AchievementsCatalog.statMaster;

      final rewards = await service.processUnlock(testUserId, achievement);

      expect(rewards['currency'], equals(100));
      expect(rewards['badges'], equals(1));
      expect((rewards['cosmetics'] as List).length, equals(1));
    });

    test('processes unlock and calculates rewards for gold tier', () async {
      final achievement = AchievementsCatalog.seasonWarrior;

      final rewards = await service.processUnlock(testUserId, achievement);

      expect(rewards['currency'], equals(250));
      expect(rewards['badges'], equals(2));
      expect((rewards['cosmetics'] as List).length, equals(2));
    });

    test('processes unlock and calculates rewards for platinum tier', () async {
      final achievement = AchievementsCatalog.consistency;

      final rewards = await service.processUnlock(testUserId, achievement);

      expect(rewards['currency'], equals(500));
      expect(rewards['badges'], equals(3));
      expect((rewards['cosmetics'] as List).length, equals(3));
    });

    test('applies currency reward correctly', () async {
      final achievement = AchievementsCatalog.firstBlood;

      await service.processUnlock(testUserId, achievement);

      final rewards = await service.getPendingRewards(testUserId);
      expect(rewards['currency'], equals(50));
    });

    test('applies badge reward correctly', () async {
      final achievement = AchievementsCatalog.firstBlood;

      await service.processUnlock(testUserId, achievement);

      final rewards = await service.getPendingRewards(testUserId);
      expect(rewards['badges'], equals(1));
    });

    test('applies cosmetic rewards correctly', () async {
      final achievement = AchievementsCatalog.seasonWarrior;

      await service.processUnlock(testUserId, achievement);

      final rewards = await service.getPendingRewards(testUserId);
      expect((rewards['cosmetics'] as List).isNotEmpty, isTrue);
    });

    test('marks achievement as unlocked in firestore', () async {
      final achievement = AchievementsCatalog.firstBlood;

      await service.processUnlock(testUserId, achievement);

      // Mock tracks achievements via _achievements map
      expect(firestoreService._achievements[testUserId], contains('first_blood'));
    });

    test('accumulates rewards for multiple achievements', () async {
      final achievement1 = AchievementsCatalog.firstBlood;
      final achievement2 = AchievementsCatalog.statMaster;

      await service.processUnlock(testUserId, achievement1);
      await service.processUnlock(testUserId, achievement2);

      final rewards = await service.getPendingRewards(testUserId);
      expect(rewards['currency'], equals(150)); // 50 + 100
      expect(rewards['badges'], equals(2)); // 1 + 1
    });

    test('debug reward info returns correct structure', () {
      final achievement = AchievementsCatalog.firstBlood;

      final debugInfo = service.debugGetRewardInfo(achievement);

      expect(debugInfo.containsKey('currency'), isTrue);
      expect(debugInfo.containsKey('badges'), isTrue);
      expect(debugInfo.containsKey('cosmetics'), isTrue);
      expect(debugInfo.containsKey('tier'), isTrue);
    });

    test('cosmetic rewards vary by tier', () {
      final bronzeRewards = service.debugGetRewardInfo(AchievementsCatalog.firstBlood);
      final silverRewards = service.debugGetRewardInfo(AchievementsCatalog.statMaster);
      final goldRewards = service.debugGetRewardInfo(AchievementsCatalog.seasonWarrior);

      expect((bronzeRewards['cosmetics'] as List).isEmpty, isTrue);
      expect((silverRewards['cosmetics'] as List).length, equals(1));
      expect((goldRewards['cosmetics'] as List).length, equals(2));
    });

    test('handles null user data gracefully', () async {
      final rewards = await service.getPendingRewards('nonexistent_user');

      expect(rewards.isEmpty, isTrue);
    });

    test('achievement unlock event triggered correctly', () async {
      final achievement = AchievementsCatalog.firstBlood;

      final rewards = await service.processUnlock(testUserId, achievement);

      expect(rewards.isNotEmpty, isTrue);
      expect(rewards['currency'], greaterThan(0));
    });

    test('all catalog achievements have valid reward tiers', () {
      for (final achievement in AchievementsCatalog.all) {
        final rewards = service.debugGetRewardInfo(achievement);

        expect(rewards['currency'], greaterThan(0));
        expect(rewards['badges'], greaterThan(0));
        expect(rewards['tier'], isNotEmpty);
      }
    });
  });
}
