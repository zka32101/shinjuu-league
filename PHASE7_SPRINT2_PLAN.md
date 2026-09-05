# Phase 7 Sprint 2: Asset Integration + Performance Optimization

**Status**: In Progress  
**Branch**: `claude/shinjuu-league-phase7-sprint2`  
**Target**: Complete all Sprint 2 implementations and prepare for Step 16 (Release)

---

## Overview

After Phase 7 Sprint 1 (Seasonal Progression System) is merged, Sprint 2 focuses on:
1. **Asset Management Infrastructure** — Lottie/SE/BGM service layer
2. **Performance Optimization** — Frame rate monitoring, memory management, rendering optimization
3. **BGM/Audio Enhancement** — Automatic fade transitions, volume management
4. **Test Infrastructure** — Asset/Performance/Rendering tests (50+ tests)

---

## Implementation Checklist

### Sprint 2: Asset Integration + Performance Optimization

#### Phase 1: Asset Services (Days 1-2)
- [ ] `lib/services/asset_service.dart` (280 lines)
  - Lottie animation preloading
  - SE effect sound management
  - BGM track definitions
  - Graceful fallback for missing assets
  - Asset caching and clearance

- [ ] `lib/services/bgm_service.dart` (180 lines)
  - BGM auto-loop management
  - Fade in/fade out transitions
  - Volume control mastering
  - Track-to-track transitions

- [ ] Update `lib/data/providers/service_providers.dart`
  - Add `bgmServiceProvider`
  - Wire asset dependencies

#### Phase 2: Performance Monitoring (Days 2-3)
- [ ] `lib/services/performance_service.dart` (290 lines)
  - FPS measurement and tracking
  - Memory usage monitoring
  - Frame time analysis
  - Slow frame history (100-frame buffer)
  - Performance statistics dump

- [ ] `lib/game/rendering_optimization.dart` (360 lines)
  - `ComponentPool<T>` for object reuse
  - `FrustumCuller` for view frustum culling
  - `DepthSorter` for Y-coordinate sorting
  - `RenderingStats` for draw call tracking
  - `OptimizedGameConfig` for tuning
  - `RenderQuality` enum for device adaptation

#### Phase 3: Main App Initialization (Day 3)
- [ ] Update `lib/main.dart`
  - Firebase initialization → `AssetService().init()`
  - Asset preloading on app start
  - Performance monitoring hooks

#### Phase 4: Test Implementation (Days 4-5)
- [ ] `test/asset_service_test.dart` (170 lines, 14 tests)
  - Initialization flow
  - Asset loading states
  - Null-safety (graceful fallback)
  - Cache management

- [ ] `test/performance_service_test.dart` (170 lines, 12 tests)
  - FPS calculation (0-120 range)
  - Memory measurement
  - Frame time tracking
  - Statistics validation

- [ ] `test/rendering_optimization_test.dart` (310 lines, 23 tests)
  - ComponentPool lifecycle
  - Frustum culling logic
  - Depth sorting
  - Rendering stats
  - Quality tiers

---

## Detailed Implementation

### Phase 1: Asset Services

**`lib/services/asset_service.dart`**
```dart
enum AssetLoadState { idle, loading, complete }

class AssetService {
  static final _instance = AssetService._();
  
  factory AssetService() => _instance;
  AssetService._();
  
  late AssetLoadState _state;
  final _animations = <String, String>{}; // name → path
  final _sounds = <String, String>{};
  final _bgms = <String, String>{};
  
  Future<void> init() async {
    _state = AssetLoadState.loading;
    try {
      // Preload Lottie animations
      _animations['kill_burst'] = 'assets/animations/kill_burst.json';
      _animations['win_celebration'] = 'assets/animations/win_celebration.json';
      // ... 5 animations total
      
      // Preload SEs (12 sounds)
      _sounds['kill'] = 'assets/sounds/kill.mp3';
      _sounds['aha_moment'] = 'assets/sounds/aha_moment.mp3';
      // ... 12 sounds total
      
      // Preload BGMs (4 tracks)
      _bgms['lobby'] = 'assets/music/lobby.mp3';
      _bgms['battle'] = 'assets/music/battle.mp3';
      // ... 4 tracks total
      
      _state = AssetLoadState.complete;
    } catch (e) {
      _state = AssetLoadState.idle;
      rethrow;
    }
  }
  
  String? getAnimationPath(String name) => _animations[name];
  String? getSoundEffectPath(String name) => _sounds[name];
  String? getBGMPath(String name) => _bgms[name];
  
  void clearCache() { /* ... */ }
  void debugDumpAssets() { /* ... */ }
}
```

**`lib/services/bgm_service.dart`**
```dart
class BGMService {
  static final _instance = BGMService._();
  
  factory BGMService() => _instance;
  BGMService._();
  
  late AudioPlayer _audioPlayer;
  double _volume = 1.0;
  
  Future<void> init() async {
    _audioPlayer = AudioPlayer();
  }
  
  Future<void> playBGM(String trackName) async {
    // Fade out current
    await _fadeOut();
    
    // Play new track with fade in
    final path = AssetService().getBGMPath(trackName);
    if (path != null) {
      await _audioPlayer.play(AssetSource(path));
      await _fadeIn();
    }
  }
  
  Future<void> setVolume(double vol) async {
    _volume = vol.clamp(0.0, 1.0);
    await _audioPlayer.setVolume(_volume);
  }
  
  Future<void> _fadeIn() async { /* 500ms fade */ }
  Future<void> _fadeOut() async { /* 500ms fade */ }
}
```

---

### Phase 2: Performance Monitoring

**`lib/services/performance_service.dart`**
```dart
class PerformanceService {
  static final _instance = PerformanceService._();
  
  factory PerformanceService() => _instance;
  PerformanceService._();
  
  final _frameRateMonitor = _FrameRateMonitor();
  final _memoryMonitor = _MemoryMonitor();
  final _slowFrames = <FrameRecord>[];
  
  void recordFrame() {
    _frameRateMonitor.recordFrame();
  }
  
  double get fps => _frameRateMonitor.currentFps;
  double get memoryUsageMB => _memoryMonitor.measureMemory();
  
  void measureFrameTime(VoidCallback callback) {
    final sw = Stopwatch()..start();
    callback();
    sw.stop();
    
    if (sw.elapsedMilliseconds > 16) {
      _slowFrames.add(FrameRecord(
        timestamp: DateTime.now(),
        durationMs: sw.elapsedMilliseconds,
      ));
      if (_slowFrames.length > 100) {
        _slowFrames.removeAt(0);
      }
    }
  }
  
  Map<String, dynamic> debugDumpPerformance() {
    return {
      'fps': fps,
      'memory_mb': memoryUsageMB,
      'slow_frames_count': _slowFrames.length,
      'slow_frames_avg_ms': _slowFrames.isEmpty
          ? 0.0
          : _slowFrames.fold<double>(0, (sum, f) => sum + f.durationMs) /
              _slowFrames.length,
    };
  }
}
```

**`lib/game/rendering_optimization.dart`**
```dart
class ComponentPool<T extends Component> {
  final List<T> _available = [];
  final List<T> _inUse = [];
  final T Function() _factory;
  
  ComponentPool(this._factory);
  
  T acquire() {
    if (_available.isNotEmpty) {
      final component = _available.removeLast();
      _inUse.add(component);
      return component;
    }
    final component = _factory();
    _inUse.add(component);
    return component;
  }
  
  void release(T component) {
    _inUse.remove(component);
    _available.add(component);
    // Reset state
  }
  
  void releaseAll() { /* ... */ }
}

class FrustumCuller {
  final Rect _visibleRect;
  
  FrustumCuller(this._visibleRect);
  
  bool isVisible(Rect bounds) {
    const margin = 100.0;
    final expanded = _visibleRect.inflate(margin);
    return expanded.overlaps(bounds);
  }
  
  List<T> filterVisible<T>(List<T> components, Rect Function(T) getBounds) {
    return components.where((c) => isVisible(getBounds(c))).toList();
  }
}

class DepthSorter {
  static void sortByY(List<Component> components) {
    components.sort((a, b) => a.y.compareTo(b.y));
  }
}

enum RenderQuality { low, medium, high, ultra }
```

---

### Phase 3-5: Integration & Tests

Tests will validate:
- ✅ Asset loading states and fallback
- ✅ FPS calculations within 0-120 range
- ✅ Memory measurements non-negative
- ✅ Frame time tracking accuracy
- ✅ ComponentPool lifecycle
- ✅ FrustumCuller accuracy
- ✅ DepthSorter Y-coordinate ordering
- ✅ RenderQuality device adaptation

---

## Success Criteria

- ✅ 50+ new tests, all passing
- ✅ Asset loading doesn't crash app if files missing
- ✅ 60 FPS maintained during battle (verified via PerformanceService)
- ✅ Memory < 200MB during typical gameplay
- ✅ Rendering culls 50%+ of off-screen objects
- ✅ Smooth BGM transitions with fade in/out

---

## Timeline

| Phase | Task | Days | Owner |
|-------|------|------|-------|
| 1 | Asset Services | 2 | Haiku |
| 2 | Performance Monitoring | 1 | Haiku |
| 3 | Main App Integration | 1 | Haiku |
| 4 | Test Suite | 1 | Haiku |
| 5 | CI & Verification | 1 | Haiku |

**Total: ~6 days**

---

## Next Phases After Sprint 2

- **Step 16**: Release preparation (審査対応・段階公開)
- **Post-Launch**: Live monitoring, crash analytics, player feedback iteration

