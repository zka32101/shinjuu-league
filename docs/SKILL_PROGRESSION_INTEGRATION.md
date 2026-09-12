# Skill Progression System Integration Guide

## Overview

The skill progression system enables level-up mechanics (Lv1-8), evolution selection (Lv3/Lv6), and real-time skill management during battles. This guide covers integrating the system into `BattleScreen` and `BattleViewModel`.

## Architecture Layers

```
┌─────────────────────────────────────────────────────┐
│ BattleScreen (UI Layer)                             │
│ - Display skill progression with SkillProgressionPanel
│ - Show level-up animations with CharacterLevelDisplay
│ - Display evolution selection screens               │
└──────────────────┬──────────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────────┐
│ BattleSkillProgressionCoordinator                    │
│ - Manages game ticks and skill cooldown updates    │
│ - Emits events (LevelUp, EvolutionRequired, etc)   │
│ - Validates skill usage and applies bonuses        │
└──────────────────┬──────────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────────┐
│ BattleSkillProgressionService                       │
│ - Tracks all players' skill progression            │
│ - Manages Lv1-8 state and evolution choices        │
│ - Calculates skill damage with evolution bonuses   │
└──────────────────┬──────────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────────┐
│ SkillProgressionService                             │
│ - Immutable state machine for single player        │
│ - Pure logic: level-up, skill use, cooldown calc   │
└─────────────────────────────────────────────────────┘
```

## Integration Steps

### Step 1: Add BattleSkillProgressionCoordinator to BattleViewModel

```dart
// lib/viewmodels/battle_viewmodel.dart

class BattleViewModel extends StateNotifier<BattleState> {
  // ... existing fields ...
  
  late BattleSkillProgressionCoordinator _skillCoordinator;
  StreamSubscription<BattleSkillEvent>? _skillEventSub;

  BattleViewModel({
    // ... existing params ...
  }) : super(BattleState.initial()) {
    _skillCoordinator = BattleSkillProgressionCoordinator();
  }

  /// バトル開始時に呼び出す
  Future<void> beginCombat(List<String> participantIds, List<String> mechaIds) async {
    // Initialize skill progression for each participant
    for (int i = 0; i < participantIds.length; i++) {
      _skillCoordinator.initializePlayer(
        playerId: participantIds[i],
        mechaId: mechaIds[i],
      );
    }

    // Subscribe to skill events
    _skillEventSub = _skillCoordinator.skillEvents.listen(_onSkillEvent);

    // Start the engine
    state.engine?.start();
  }

  /// スキルイベント処理
  void _onSkillEvent(BattleSkillEvent event) {
    if (event is PlayerLevelUpEvent) {
      // Handle level-up (show animation)
      _handleLevelUp(event);
    } else if (event is EvolutionSelectionRequiredEvent) {
      // Show evolution selection screen
      _handleEvolutionRequired(event);
    } else if (event is SkillUsedEvent) {
      // Show skill effect (animation, particles)
      _handleSkillUsed(event);
    }
  }

  void _handleLevelUp(PlayerLevelUpEvent event) {
    // Trigger level-up animation UI
    print('${event.playerId} reached Lv${event.newLevel}');
  }

  void _handleEvolutionRequired(EvolutionRequiredEvent event) {
    // Trigger evolution selection screen modal
    print('${event.playerId} must choose evolution at Lv${event.level}');
  }

  void _handleSkillUsed(SkillUsedEvent event) {
    // Trigger skill effect visualization
    print('${event.playerId} used ${event.slot} for ${event.damageDealt} damage');
  }

  @override
  void dispose() {
    _skillEventSub?.cancel();
    _skillCoordinator.dispose();
    super.dispose();
  }
}
```

### Step 2: Update BattleScreen to Display Skill Progression

```dart
// lib/ui/screens/battle_screen.dart

class BattleScreen extends ConsumerStatefulWidget {
  // ... existing fields ...

  @override
  ConsumerState<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends ConsumerState<BattleScreen> {
  @override
  Widget build(BuildContext context) {
    final battleState = ref.watch(battleViewModelProvider);

    // Get self player skill state
    final selfSkillState = _getPlayerSkillState(battleState.battle?.selfUserId);

    return Scaffold(
      body: Stack(
        children: [
          // Battle field (existing)
          _buildBattleField(battleState),

          // Skill progression panel (new)
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: SkillProgressionPanel(
              currentLevel: selfSkillState?.currentLevel ?? 1,
              skillCooldowns: selfSkillState?.skillCooldowns ?? {},
              skillDamages: {
                // Map skill slots to current damage values
                SkillSlot.q: selfSkillState?.currentLevel ?? 0,
                SkillSlot.r: selfSkillState?.currentLevel ?? 0,
                SkillSlot.e: selfSkillState?.currentLevel ?? 0,
                SkillSlot.ult: selfSkillState?.currentLevel ?? 0,
              },
              currentEvolution: selfSkillState?.currentEvolution,
              evolutionBonuses: selfSkillState?.evolutionBonuses ?? {},
              isUltAvailable: selfSkillState?.isUltUnlocked ?? false,
              isUltCharging: selfSkillState?.isUltCharging ?? false,
              onSkillTap: (slot) => _attemptSkillUse(slot),
            ),
          ),

          // Level-up indicator (new)
          if (_showLevelUpIndicator)
            Positioned(
              top: 100,
              left: 0,
              right: 0,
              child: CharacterLevelDisplay(
                currentLevel: selfSkillState?.currentLevel ?? 1,
                showAnimation: true,
                currentEvolution: selfSkillState?.currentEvolution,
              ),
            ),
        ],
      ),
    );
  }

  BattleSkillProgressionUIState? _getPlayerSkillState(String? playerId) {
    if (playerId == null) return null;
    // Retrieve from ViewModel (implementation depends on state management)
    return null;
  }

  void _attemptSkillUse(SkillSlot slot) {
    // Coordinate with BattleViewModel to use skill
    print('Attempting to use $slot');
  }
}
```

### Step 3: Handle Evolution Selection Screen

```dart
// lib/ui/screens/battle_screen.dart (continued)

class _BattleScreenState extends ConsumerState<BattleScreen> {
  // ... existing code ...

  void _showEvolutionSelection(EvolutionSelectionRequiredEvent event) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => EvolutionSelectionV2Screen(
        mechaId: _getCurrentMechaId(),
        currentLevel: event.level,
        onEvolutionSelected: (choice) {
          if (event.evolutionType == EvolutionSelectionType.first) {
            ref.read(battleViewModelProvider.notifier).confirmEvolution(
              event.playerId,
              choice,
            );
          } else {
            ref.read(battleViewModelProvider.notifier).switchEvolution(
              event.playerId,
              choice,
            );
          }
          Navigator.pop(context);
        },
      ),
    );
  }

  String _getCurrentMechaId() {
    // Return current player's mecha ID
    return 'leon'; // Placeholder
  }
}
```

### Step 4: Integrate Game Tick Updates

```dart
// lib/services/battle_engine_service.dart (modify existing tick())

class BattleEngine {
  // ... existing fields ...
  
  BattleSkillProgressionCoordinator? _skillCoordinator;

  void setSkillCoordinator(BattleSkillProgressionCoordinator coordinator) {
    _skillCoordinator = coordinator;
  }

  void tick() {
    _elapsedSeconds++;
    _resolveRespawns();
    _updateResources();
    _resolveEngagements();
    _tickController.add(_elapsedSeconds);

    // NEW: Update skill cooldowns each tick
    _skillCoordinator?.onGameTick(1.0); // 1 second passed

    if (_elapsedSeconds >= durationSeconds) {
      stop();
    }
  }
}
```

### Step 5: Handle Level-Up During Combat

When a participant gets a kill, trigger level-up:

```dart
// lib/services/battle_engine_service.dart

void _resolveEngagements() {
  // ... existing combat logic ...
  
  // When a participant is defeated:
  if (victimIsDefeated) {
    attackerParticipant.kills++;
    victimParticipant.isAlive = false;

    // NEW: Trigger level-up for attacker
    _skillCoordinator?.levelUpPlayer(attackerParticipant.userId);

    _combatController.add(CombatEvent(
      attackerId: attackerParticipant.userId,
      victimId: victimParticipant.userId,
      tickSecond: _elapsedSeconds,
    ));
  }
}
```

## Data Flow Example: Level-Up at Lv3 Evolution

```
1. Combat resolves: Player1 kills opponent
   └─ BattleEngine calls: skillCoordinator.levelUpPlayer('player1')

2. SkillProgressionBattleService.levelUpPlayer()
   └─ Updates state: currentLevel 2 → 3
   └─ Detects nextEvolutionLevel == 3
   └─ Sets isEvolutionLocked = true

3. Emits EvolutionSelectionRequiredEvent
   └─ Event picked up by BattleViewModel
   └─ BattleViewModel emits UI event to BattleScreen

4. BattleScreen receives event
   └─ Shows evolution selection dialog (EvolutionSelectionV2Screen)
   └─ User selects offensive
   └─ Calls confirmEvolution('player1', EvolutionType.offensive)

5. SkillProgressionBattleService.confirmEvolution()
   └─ Updates state: isEvolutionLocked = false
   └─ Applies evolution choice to evolutionState
   └─ From now on, all skill damage includes offensive bonus
```

## UI State Updates

### Level-Up Indicator
- Show `CharacterLevelDisplay` with animation when level changes
- Display level number with evolution emoji if applicable
- Auto-hide after 3 seconds

### Evolution Bonus Display
- Show active bonuses (ダメージ/HP/味方効果 ±XX%)
- Update in real-time as evolution changes
- Color-code by bonus type (red=dmg, green=hp, blue=ally)

### Skill Slot Display
- Q/R/E slots: Show current damage + cooldown timer
- ULT slot: 
  - Red "Ready" badge when available
  - Amber "Charging" badge at Lv5-6
  - Gray "Locked" badge before Lv5

## Testing Checklist

- [ ] Level progression Lv1→3 triggers evolution screen
- [ ] Evolution selection locks/unlocks correctly
- [ ] Skill damage increases with evolution bonuses
- [ ] Cooldown timers display and update properly
- [ ] ULT state transitions work (Locked → Charging → Ready)
- [ ] All 6 characters initialize with correct skills
- [ ] Multi-player states remain independent
- [ ] Evolution screen timeout auto-confirms offensive
- [ ] Skill cooldown prevents repeated usage
- [ ] Game tick properly decrements cooldowns

## Known Limitations

1. **Skill catalog is static**: Future versions should load from Firestore
2. **No animation library yet**: Lottie animations pending (design team task)
3. **No sound effects**: Audio Service configured but files not provided
4. **No visual effects**: Particle effects use Flutter shapes, not advanced VFX
5. **Manual kill-based level-up**: Real multiplayer requires server-side progression tracking

## Future Enhancements

1. **Server-side progression validation** (Cloud Functions)
2. **Skill tree customization** (item builds, stat allocation)
3. **Dynamic difficulty scaling** based on player level
4. **Seasonal battle pass integration** for progression rewards
5. **Replay system** that includes skill usage timeline
