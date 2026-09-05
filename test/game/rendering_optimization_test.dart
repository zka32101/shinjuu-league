import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shinjuu_league/game/rendering_optimization.dart';

class _MockComponent {
  int id;
  double screenY;

  _MockComponent({required this.id, required this.screenY});
}

void main() {
  group('ComponentPool', () {
    late ComponentPool<_MockComponent> pool;
    int factoryCalls = 0;
    int resetCalls = 0;

    setUp(() {
      factoryCalls = 0;
      resetCalls = 0;
      pool = ComponentPool<_MockComponent>(
        factory: () {
          factoryCalls++;
          return _MockComponent(id: factoryCalls, screenY: 0.0);
        },
        reset: (_) {
          resetCalls++;
        },
        poolSize: 5,
      );
    });

    test('constructor creates initial pool items', () {
      expect(factoryCalls, 5); // Constructor creates 5 items
    });

    test('acquire returns available item without creating new one', () {
      factoryCalls = 0;
      final item = pool.acquire();

      expect(item, isNotNull);
      expect(factoryCalls, 0); // No new factory calls
    });

    test('acquire creates new item when pool is empty', () {
      factoryCalls = 0;
      // Acquire all 5 available items
      final items = <_MockComponent>[];
      for (int i = 0; i < 5; i++) {
        items.add(pool.acquire());
      }
      expect(factoryCalls, 0);

      // Next acquire should create a new one
      final newItem = pool.acquire();
      expect(factoryCalls, 1);
      expect(newItem.id, 6); // ID from factory call counter
    });

    test('release returns item to pool and calls reset', () {
      resetCalls = 0;
      final item = pool.acquire();
      pool.release(item);

      expect(resetCalls, 1);
    });

    test('release makes item available for reuse', () {
      factoryCalls = 0;
      final item1 = pool.acquire();
      pool.release(item1);

      factoryCalls = 0;
      final item2 = pool.acquire();

      expect(identical(item1, item2), true); // Same object
      expect(factoryCalls, 0); // No new factory call
    });

    test('releaseAll returns all in-use items to pool', () {
      resetCalls = 0;
      pool.acquire();
      pool.acquire();
      pool.acquire();

      pool.releaseAll();

      expect(resetCalls, 3);
    });

    test('debug returns accurate pool state', () {
      final item = pool.acquire();
      final debug = pool.debug();

      expect(debug['available'], 4); // 5 - 1 acquired
      expect(debug['in_use'], 1);
      expect(debug['total'], 5);

      pool.release(item);
      final debugAfterRelease = pool.debug();

      expect(debugAfterRelease['available'], 5);
      expect(debugAfterRelease['in_use'], 0);
    });
  });

  group('FrustumCuller', () {
    late FrustumCuller culler;

    setUp(() {
      culler = FrustumCuller();
      culler.setViewport(Rect.fromLTWH(0, 0, 800, 600));
    });

    test('isVisible returns true for objects within viewport', () {
      final bounds = Rect.fromLTWH(100, 100, 50, 50);
      expect(culler.isVisible(bounds), true);
    });

    test('isVisible returns true for partially visible objects', () {
      final bounds = Rect.fromLTWH(750, 100, 100, 50);
      expect(culler.isVisible(bounds), true);
    });

    test('isVisible returns true for objects in culling margin', () {
      // Object is 50px outside viewport (within 100px margin)
      final bounds = Rect.fromLTWH(800, 100, 50, 50);
      expect(culler.isVisible(bounds), true);
    });

    test('isVisible returns false for objects far outside viewport', () {
      // Object is 200px outside viewport (beyond 100px margin)
      final bounds = Rect.fromLTWH(1000, 100, 50, 50);
      expect(culler.isVisible(bounds), false);
    });

    test('filterVisible returns only visible objects', () {
      final objects = [
        _MockComponent(id: 1, screenY: 100.0),
        _MockComponent(id: 2, screenY: 1000.0), // Outside
        _MockComponent(id: 3, screenY: 300.0),
      ];

      final visible = culler.filterVisible<_MockComponent>(
        objects,
        (obj) => Rect.fromLTWH(0, obj.screenY, 50, 50),
      );

      expect(visible.length, 2);
      expect(visible[0].id, 1);
      expect(visible[1].id, 3);
    });

    test('filterVisible returns empty list when nothing is visible', () {
      final objects = [
        _MockComponent(id: 1, screenY: 1000.0),
        _MockComponent(id: 2, screenY: 2000.0),
      ];

      final visible = culler.filterVisible<_MockComponent>(
        objects,
        (obj) => Rect.fromLTWH(0, obj.screenY, 50, 50),
      );

      expect(visible, isEmpty);
    });
  });

  group('DepthSorter', () {
    test('sortByDepth returns objects in ascending Y order', () {
      final objects = [
        _MockComponent(id: 1, screenY: 300.0),
        _MockComponent(id: 2, screenY: 100.0),
        _MockComponent(id: 3, screenY: 200.0),
      ];

      final sorted = DepthSorter.sortByDepth<_MockComponent>(
        objects,
        (obj) => obj.screenY,
      );

      expect(sorted[0].id, 2); // Y=100
      expect(sorted[1].id, 3); // Y=200
      expect(sorted[2].id, 1); // Y=300
    });

    test('sortByDepth maintains stability for equal Y values', () {
      final objects = [
        _MockComponent(id: 1, screenY: 100.0),
        _MockComponent(id: 2, screenY: 100.0),
        _MockComponent(id: 3, screenY: 100.0),
      ];

      final sorted = DepthSorter.sortByDepth<_MockComponent>(
        objects,
        (obj) => obj.screenY,
      );

      expect(sorted.length, 3);
      expect(sorted.every((obj) => obj.screenY == 100.0), true);
    });

    test('sortByDepth handles single object', () {
      final objects = [_MockComponent(id: 1, screenY: 150.0)];

      final sorted = DepthSorter.sortByDepth<_MockComponent>(
        objects,
        (obj) => obj.screenY,
      );

      expect(sorted.length, 1);
      expect(sorted[0].id, 1);
    });

    test('sortByDepth handles empty list', () {
      final sorted = DepthSorter.sortByDepth<_MockComponent>(
        [],
        (obj) => obj.screenY,
      );

      expect(sorted, isEmpty);
    });
  });

  group('RenderingStats', () {
    late RenderingStats stats;

    setUp(() {
      stats = RenderingStats();
    });

    test('initial state is all zeros', () {
      expect(stats.triangleCount, 0);
      expect(stats.culledObjectCount, 0);
      expect(stats.visibleObjectCount, 0);
      expect(stats.drawCallCount, 0);
      expect(stats.textureBindCount, 0);
    });

    test('reset clears all counters', () {
      stats.triangleCount = 100;
      stats.culledObjectCount = 50;
      stats.visibleObjectCount = 30;
      stats.drawCallCount = 20;
      stats.textureBindCount = 10;

      stats.reset();

      expect(stats.triangleCount, 0);
      expect(stats.culledObjectCount, 0);
      expect(stats.visibleObjectCount, 0);
      expect(stats.drawCallCount, 0);
      expect(stats.textureBindCount, 0);
    });

    test('debug returns all counter values', () {
      stats.triangleCount = 100;
      stats.culledObjectCount = 50;
      stats.visibleObjectCount = 30;

      final debug = stats.debug();

      expect(debug['triangles'], 100);
      expect(debug['culled_objects'], 50);
      expect(debug['visible_objects'], 30);
    });

    test('cullingRatio calculates percentage correctly', () {
      stats.culledObjectCount = 60;
      stats.visibleObjectCount = 40;

      expect(stats.cullingRatio, 0.6);
    });

    test('cullingRatio returns 0 when no objects', () {
      expect(stats.cullingRatio, 0.0);
    });

    test('cullingRatio returns 1.0 when all culled', () {
      stats.culledObjectCount = 100;
      stats.visibleObjectCount = 0;

      expect(stats.cullingRatio, 1.0);
    });
  });

  group('OptimizedGameConfig', () {
    test('default constructor has reasonable values', () {
      final config = OptimizedGameConfig();

      expect(config.tickRate, 60.0);
      expect(config.allowFrameSkip, true);
      expect(config.vsync, true);
      expect(config.renderWhenPaused, false);
      expect(config.enableCulling, true);
      expect(config.enablePooling, true);
    });

    test('debug factory disables frame skip', () {
      final config = OptimizedGameConfig.debug();

      expect(config.allowFrameSkip, false);
      expect(config.vsync, false);
      expect(config.renderWhenPaused, true);
    });

    test('custom values can be provided', () {
      final config = OptimizedGameConfig(
        tickRate: 120.0,
        allowFrameSkip: false,
        vsync: false,
      );

      expect(config.tickRate, 120.0);
      expect(config.allowFrameSkip, false);
      expect(config.vsync, false);
    });
  });

  group('RenderQuality', () {
    test('fromMemory returns low for <512MB', () {
      expect(RenderQuality.fromMemory(256), RenderQuality.low);
      expect(RenderQuality.fromMemory(511), RenderQuality.low);
    });

    test('fromMemory returns medium for 512-1024MB', () {
      expect(RenderQuality.fromMemory(512), RenderQuality.medium);
      expect(RenderQuality.fromMemory(1000), RenderQuality.medium);
    });

    test('fromMemory returns high for 1024-2048MB', () {
      expect(RenderQuality.fromMemory(1024), RenderQuality.high);
      expect(RenderQuality.fromMemory(2000), RenderQuality.high);
    });

    test('fromMemory returns ultra for >=2048MB', () {
      expect(RenderQuality.fromMemory(2048), RenderQuality.ultra);
      expect(RenderQuality.fromMemory(4096), RenderQuality.ultra);
    });

    test('maxDrawCalls increases with quality tier', () {
      expect(RenderQuality.low.maxDrawCalls, 50);
      expect(RenderQuality.medium.maxDrawCalls, 150);
      expect(RenderQuality.high.maxDrawCalls, 300);
      expect(RenderQuality.ultra.maxDrawCalls, 1000);
    });

    test('maxVisibleObjects increases with quality tier', () {
      expect(RenderQuality.low.maxVisibleObjects, 100);
      expect(RenderQuality.medium.maxVisibleObjects, 300);
      expect(RenderQuality.high.maxVisibleObjects, 600);
      expect(RenderQuality.ultra.maxVisibleObjects, 2000);
    });

    test('enableEffects is true for medium and above', () {
      expect(RenderQuality.low.enableEffects, false);
      expect(RenderQuality.medium.enableEffects, true);
      expect(RenderQuality.high.enableEffects, true);
      expect(RenderQuality.ultra.enableEffects, true);
    });
  });
}
