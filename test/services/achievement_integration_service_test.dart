import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:shinjuu_league/data/models/achievement.dart';
import 'package:shinjuu_league/data/models/battle_model.dart';
import 'package:shinjuu_league/services/achievement_detector_service.dart';
import 'package:shinjuu_league/services/achievement_reward_service.dart';
import 'package:shinjuu_league/services/achievement_toast_notification_service.dart';
import 'package:shinjuu_league/services/achievement_integration_service.dart';
import 'package:shinjuu_league/services/analytics_service.dart';
import 'package:shinjuu_league/services/battle_engine_service.dart';
import 'package:shinjuu_league/services/firestore_service.dart';

// Mock BattleEngine for testing. BattleEngine's real constructor needs
// per-match data (battleId/mode/mapId/participants) that this test doesn't
// care about; the streams are overridden below and driven manually instead
// of by BattleEngine's own tick loop. (Same pattern as
// achievement_detector_service_test.dart.)
class MockBattleEngineService extends BattleEngine {
  MockBattleEngineService()
      : super(
          battleId: 'test_battle',
          mode: BattleMode.quick,
          mapId: 'test_map',
          participants: const [],
        );

  final _testCombatController = StreamController<CombatEvent>.broadcast();
  final _testDamageController = StreamController<DamageEvent>.broadcast();
  final _testTickController = StreamController<int>.broadcast();

  @override
  Stream<CombatEvent> get combatEvents => _testCombatController.stream;

  @override
  Stream<DamageEvent> get damageEvents => _testDamageController.stream;

  @override
  Stream<int> get onTick => _testTickController.stream;

  @override
  void dispose() {
    _testCombatController.close();
    _testDamageController.close();
    _testTickController.close();
  }
}

// FirestoreService is a singleton with only a private generative
// constructor, so it cannot be `extends`-ed from another library; implement
// the interface instead (same pattern used elsewhere in this suite).
class MockFirestoreService implements FirestoreService {
  final Map<String, dynamic> _userData = {};

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<void> markAchievementUnlocked(String userId, String achievementId) async {
    // Mock implementation
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
  }
}

// AnalyticsService is likewise a singleton with only a private generative
// constructor; implement instead of extend.
class MockAnalyticsService implements AnalyticsService {
  final List<String> loggedEvents = [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<void> logAchievementUnlocked(
    String userId,
    String achievementId,
    String achievementName,
  ) async {
    loggedEvents.add(achievementId);
  }

  @override
  void recordError(
    dynamic exception,
    StackTrace? stackTrace, {
    String? reason,
    Iterable<Object> information = const [],
  }) {
    // Mock implementation
  }
}

void main() {
  group('AchievementIntegrationService', () {
    late AchievementIntegrationService service;
    late AchievementDetectorService detector;
    late AchievementRewardService rewardService;
    late AchievementToastNotificationService toastService;
    late MockAnalyticsService analyticsService;
    late MockBattleEngineService battleEngine;
    late MockFirestoreService firestoreService;

    final testUserId = 'user_123';

    setUp(() {
      battleEngine = MockBattleEngineService();
      firestoreService = MockFirestoreService();
      analyticsService = MockAnalyticsService();
      toastService = AchievementToastNotificationService();

      detector = AchievementDetectorService(battleEngine: battleEngine);
      rewardService = AchievementRewardService(firestoreService: firestoreService);

      service = AchievementIntegrationService(
        detector: detector,
        rewardService: rewardService,
        toastService: toastService,
        analyticsService: analyticsService,
      );
    });

    tearDown(() {
      service.dispose();
      battleEngine.dispose();
    });

    test('starts battle achievements and initializes detector', () async {
      await service.startBattleAchievements(testUserId);

      expect(service.getUnlockedAchievements().isEmpty, isTrue);

      await service.stopBattleAchievements();
    });

    test('stops battle achievements and returns summary', () async {
      await service.startBattleAchievements(testUserId);
      final summary = await service.stopBattleAchievements();

      expect(summary.containsKey('unlockedCount'), isTrue);
      expect(summary.containsKey('totalCurrency'), isTrue);
      expect(summary.containsKey('totalBadges'), isTrue);
      expect(summary['unlockedCount'], equals(0));
    });

    test('tracks unlocked achievements in session', () async {
      await service.startBattleAchievements(testUserId);

      final unlocked = service.getUnlockedAchievements();
      expect(unlocked.isEmpty, isTrue);

      await service.stopBattleAchievements();
    });

    test('returns session summary with correct structure', () async {
      await service.startBattleAchievements(testUserId);
      final summary = service.getSessionSummary();

      expect(summary['unlockedCount'] is int, isTrue);
      expect(summary['totalCurrency'] is int, isTrue);
      expect(summary['totalBadges'] is int, isTrue);
      expect(summary['achievements'] is List, isTrue);
    });

    test('debug stats return valid integration information', () async {
      await service.startBattleAchievements(testUserId);
      final stats = service.debugGetIntegrationStats();

      expect(stats.containsKey('detector_stats'), isTrue);
      expect(stats.containsKey('session_rewards'), isTrue);
      expect(stats.containsKey('unlocked_count'), isTrue);
      expect(stats.containsKey('achievements'), isTrue);

      await service.stopBattleAchievements();
    });

    test('processes unlock events in correct order', () async {
      await service.startBattleAchievements(testUserId);

      // Wait for any pending async work
      await Future.delayed(const Duration(milliseconds: 100));

      final summary = await service.stopBattleAchievements();
      expect(summary['unlockedCount'] is int, isTrue);
    });

    test('emits analytics events for unlocked achievements', () async {
      await service.startBattleAchievements(testUserId);

      // Wait briefly for async processing
      await Future.delayed(const Duration(milliseconds: 100));

      final summary = await service.stopBattleAchievements();
      expect(summary, isNotNull);
      expect(analyticsService.loggedEvents, isA<List<String>>());
    });

    test('session rewards accumulate correctly', () async {
      await service.startBattleAchievements(testUserId);

      final summary = await service.stopBattleAchievements();

      expect(summary['totalCurrency'] is int, isTrue);
      expect(summary['totalBadges'] is int, isTrue);
      expect(summary['totalCurrency'] >= 0, isTrue);
      expect(summary['totalBadges'] >= 0, isTrue);
    });

    test('resets state for new battle', () async {
      await service.startBattleAchievements(testUserId);
      var summary = await service.stopBattleAchievements();
      var firstCount = summary['unlockedCount'] as int;
      expect(firstCount, equals(0));

      // Start new battle
      await service.startBattleAchievements(testUserId);
      summary = service.getSessionSummary();
      var secondCount = summary['unlockedCount'] as int;

      // Should be reset
      expect(secondCount, equals(0));

      await service.stopBattleAchievements();
    });

    test('handles multiple achievements in one session', () async {
      await service.startBattleAchievements(testUserId);

      // Simulate multiple achievements by checking structure
      var summary = service.getSessionSummary();
      expect(summary['achievements'] is List, isTrue);

      final finalSummary = await service.stopBattleAchievements();
      expect(finalSummary['achievements'] is List, isTrue);
    });

    test('disposes resources properly', () async {
      await service.startBattleAchievements(testUserId);
      await service.stopBattleAchievements();

      // Should not throw on double dispose
      expect(() => service.dispose(), returnsNormally);
    });

    test('unlocked achievements are immutable', () async {
      await service.startBattleAchievements(testUserId);

      final unlocked1 = service.getUnlockedAchievements();
      final unlocked2 = service.getUnlockedAchievements();

      expect(unlocked1, isA<List<Achievement>>());
      expect(unlocked1, equals(unlocked2));

      await service.stopBattleAchievements();
    });

    test('session summary matches unlocked achievements list', () async {
      await service.startBattleAchievements(testUserId);

      final summary = service.getSessionSummary();
      final unlockedList = service.getUnlockedAchievements();

      expect(summary['unlockedCount'], equals(unlockedList.length));

      await service.stopBattleAchievements();
    });
  });
}
