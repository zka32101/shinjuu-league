import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:shinjuu_league/data/models/achievement.dart';
import 'package:shinjuu_league/data/models/battle_model.dart';
import 'package:shinjuu_league/services/achievement_detector_service.dart';
import 'package:shinjuu_league/services/battle_engine_service.dart';

// Mock BattleEngineService for testing
class MockBattleEngineService extends BattleEngineService {
  final _testCombatController = StreamController<CombatEvent>.broadcast();
  final _testDamageController = StreamController<DamageEvent>.broadcast();
  final _testTickController = StreamController<int>.broadcast();

  @override
  Stream<CombatEvent> get combatEvents => _testCombatController.stream;

  @override
  Stream<DamageEvent> get damageEvents => _testDamageController.stream;

  @override
  Stream<int> get onTick => _testTickController.stream;

  void testEmitCombatEvent(CombatEvent event) {
    _testCombatController.add(event);
  }

  void testEmitDamageEvent(DamageEvent event) {
    _testDamageController.add(event);
  }

  void testEmitTick(int tick) {
    _testTickController.add(tick);
  }

  @override
  void dispose() {
    _testCombatController.close();
    _testDamageController.close();
    _testTickController.close();
  }
}

void main() {
  group('AchievementDetectorService', () {
    late AchievementDetectorService service;
    late MockBattleEngineService battleEngine;

    final testUserId = 'user_123';

    setUp(() {
      battleEngine = MockBattleEngineService();
      service = AchievementDetectorService(battleEngine: battleEngine);
    });

    tearDown(() {
      service.dispose();
      battleEngine.dispose();
    });

    test('emits unlock event on combat event', () async {
      final unlocks = <AchievementUnlockEvent>[];
      service.unlockEvents.listen(unlocks.add);

      service.startDetecting(testUserId);

      // Simulate a combat event
      battleEngine.testEmitCombatEvent(
        CombatEvent(
          killerId: testUserId,
          victimId: 'enemy_123',
          timestamp: DateTime.now(),
          damageDealt: 100,
        ),
      );

      await Future.delayed(const Duration(milliseconds: 100));

      expect(unlocks.isNotEmpty, isTrue);
      expect(unlocks.first.userId, equals(testUserId));
    });

    test('tracks unlocked achievements in session', () async {
      service.startDetecting(testUserId);

      // Simulate multiple combat events
      battleEngine.testEmitCombatEvent(
        CombatEvent(
          killerId: testUserId,
          victimId: 'enemy_1',
          timestamp: DateTime.now(),
          damageDealt: 100,
        ),
      );

      await Future.delayed(const Duration(milliseconds: 50));

      final stats = service.debugGetStats();
      expect(stats['detected_count'], greaterThan(0));
    });

    test('stops detecting on stopDetecting call', () async {
      final unlocks = <AchievementUnlockEvent>[];
      service.unlockEvents.listen(unlocks.add);

      service.startDetecting(testUserId);
      service.stopDetecting();

      battleEngine.testEmitCombatEvent(
        CombatEvent(
          killerId: testUserId,
          victimId: 'enemy_123',
          timestamp: DateTime.now(),
          damageDealt: 100,
        ),
      );

      await Future.delayed(const Duration(milliseconds: 100));

      // No events should be emitted after stopDetecting
      expect(unlocks.isEmpty, isTrue);
    });

    test('only counts each achievement once per session', () async {
      final unlocks = <AchievementUnlockEvent>[];
      service.unlockEvents.listen(unlocks.add);

      service.startDetecting(testUserId);

      // Emit same achievement multiple times
      for (int i = 0; i < 3; i++) {
        battleEngine.testEmitCombatEvent(
          CombatEvent(
            killerId: testUserId,
            victimId: 'enemy_$i',
            timestamp: DateTime.now(),
            damageDealt: 100,
          ),
        );
        await Future.delayed(const Duration(milliseconds: 50));
      }

      // Only first_blood should be emitted once
      final firstBloodUnlocks = unlocks.where((u) => u.achievement.achievementId == 'first_blood');
      expect(firstBloodUnlocks.length, equals(1));
    });

    test('resets session state on startDetecting', () async {
      service.startDetecting(testUserId);

      battleEngine.testEmitCombatEvent(
        CombatEvent(
          killerId: testUserId,
          victimId: 'enemy_1',
          timestamp: DateTime.now(),
          damageDealt: 100,
        ),
      );

      await Future.delayed(const Duration(milliseconds: 50));

      var stats = service.debugGetStats();
      final firstCount = stats['detected_count'] as int;

      // Start detecting again (reset session)
      service.startDetecting(testUserId);
      stats = service.debugGetStats();

      expect(stats['detected_count'], equals(0));
    });

    test('debug stats returns valid data structure', () {
      service.startDetecting(testUserId);

      final stats = service.debugGetStats();

      expect(stats.containsKey('detected_count'), isTrue);
      expect(stats.containsKey('achievements'), isTrue);
      expect(stats['detected_count'] is int, isTrue);
      expect(stats['achievements'] is List, isTrue);
    });

    test('achievement unlock event has correct fields', () async {
      final unlocks = <AchievementUnlockEvent>[];
      service.unlockEvents.listen(unlocks.add);

      service.startDetecting(testUserId);

      battleEngine.testEmitCombatEvent(
        CombatEvent(
          killerId: testUserId,
          victimId: 'enemy_123',
          timestamp: DateTime.now(),
          damageDealt: 100,
        ),
      );

      await Future.delayed(const Duration(milliseconds: 100));

      expect(unlocks.isNotEmpty, isTrue);
      final event = unlocks.first;

      expect(event.userId, equals(testUserId));
      expect(event.achievement.achievementId, isNotEmpty);
      expect(event.unlockedAt, isNotNull);
      expect(event.isNewUnlock, isTrue);
    });

    test('disposes streams properly', () async {
      service.startDetecting(testUserId);
      service.dispose();

      // Should not throw when disposing
      expect(() => service.dispose(), returnsNormally);
    });

    test('different users can have separate detection', () async {
      final unlocks1 = <AchievementUnlockEvent>[];
      final unlocks2 = <AchievementUnlockEvent>[];

      service.unlockEvents.listen(unlocks1.add);

      service.startDetecting('user_1');

      battleEngine.testEmitCombatEvent(
        CombatEvent(
          killerId: 'user_1',
          victimId: 'enemy_1',
          timestamp: DateTime.now(),
          damageDealt: 100,
        ),
      );

      await Future.delayed(const Duration(milliseconds: 50));

      expect(unlocks1.isNotEmpty, isTrue);
      expect(unlocks1.first.userId, equals('user_1'));
    });
  });
}
