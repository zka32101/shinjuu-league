import 'dart:async';
import 'package:shinjuu_league/data/models/achievement.dart';
import 'package:shinjuu_league/data/models/battle_model.dart';
import 'package:shinjuu_league/services/battle_engine_service.dart';

/// Detects when achievements should unlock based on game events
/// Listens to BattleEngine streams and emits AchievementUnlockEvent when conditions are met
class AchievementDetectorService {
  final BattleEngineService _battleEngine;
  final Map<String, bool> _unlockedThisSession = {}; // Track unlocked achievements per session

  late StreamController<AchievementUnlockEvent> _unlockController;
  StreamSubscription? _combatSubscription;
  StreamSubscription? _damageSubscription;
  StreamSubscription? _tickSubscription;

  AchievementDetectorService({
    required BattleEngineService battleEngine,
  }) : _battleEngine = battleEngine {
    _unlockController = StreamController<AchievementUnlockEvent>.broadcast();
    _resetSessionState();
  }

  /// Stream of achievement unlock events
  Stream<AchievementUnlockEvent> get unlockEvents => _unlockController.stream;

  /// Start listening to battle engine events
  void startDetecting(String userId) {
    _resetSessionState();

    // Listen for combat events (kills)
    _combatSubscription = _battleEngine.combatEvents.listen((event) {
      _onCombatEvent(userId, event);
    });

    // Listen for damage events (for progression)
    _damageSubscription = _battleEngine.damageEvents.listen((event) {
      _onDamageEvent(userId, event);
    });

    // Listen for ticks (for time-based achievements)
    _tickSubscription = _battleEngine.onTick.listen((tickCount) {
      _onTick(userId, tickCount);
    });
  }

  /// Stop listening to battle engine events
  void stopDetecting() {
    _combatSubscription?.cancel();
    _damageSubscription?.cancel();
    _tickSubscription?.cancel();
    _resetSessionState();
  }

  /// Check for achievements triggered by combat events (kills)
  void _onCombatEvent(String userId, CombatEvent event) {
    // Check if this kill triggers any achievements
    // Examples:
    // - firstBlood: first kill of the battle
    // - tripleKill: 3 kills in one battle
    // - warKill: participate in a kill

    // First kill detection
    if (!_unlockedThisSession.containsKey('first_kill') &&
        event.killerId == userId) {
      _unlockedThisSession['first_kill'] = true;
      _emitUnlock(
        userId,
        AchievementsCatalog.getById('first_blood') ?? AchievementsCatalog.risingStar,
      );
    }
  }

  /// Check for achievements triggered by damage events
  void _onDamageEvent(String userId, DamageEvent event) {
    // Check for damage-based achievements
    // Examples:
    // - highDamage: deal X damage in a battle
    // - criticalStrike: land a critical hit
  }

  /// Check for achievements triggered by ticks (time-based)
  void _onTick(String userId, int tickCount) {
    // Check for time-based achievements
    // Examples:
    // - speedRunnerTick: complete battle in X ticks
    // - survival: survive X ticks in battle
  }

  /// Emit an achievement unlock event
  void _emitUnlock(String userId, Achievement achievement) {
    final event = AchievementUnlockEvent(
      userId: userId,
      achievement: achievement,
      unlockedAt: DateTime.now(),
      isNewUnlock: true,
    );
    _unlockController.add(event);
  }

  /// Reset session-specific tracking state
  void _resetSessionState() {
    _unlockedThisSession.clear();
  }

  /// Get debug info about detected achievements this session
  Map<String, dynamic> debugGetStats() {
    return {
      'detected_count': _unlockedThisSession.length,
      'achievements': _unlockedThisSession.keys.toList(),
    };
  }

  void dispose() {
    _combatSubscription?.cancel();
    _damageSubscription?.cancel();
    _tickSubscription?.cancel();
    _unlockController.close();
    _resetSessionState();
  }
}
