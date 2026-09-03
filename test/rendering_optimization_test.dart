import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shinjuu_league/game/rendering_optimization.dart';

void main() {
  group('ComponentPool', () {
    late ComponentPool<_MockComponent> pool;

    setUp(() {
      pool = ComponentPool(
        factory: () => _MockComponent(),
        reset: (comp) => comp.reset(),
        poolSize: 5,
      );
    });

    test('pool initializes with specified size', () {
      final debug = pool.debug();
      expect(debug['available'], equals(5));
      expect(debug['in_use'], equals(0));
      expect(debug['total'], equals(5));
    });

    test('acquire returns component and moves to in_use', () {
      final comp = pool.acquire();
      expect(comp, isA<_MockComponent>());

      final debug = pool.debug();
      expect(debug['available'], equals(4));
      expect(debug['in_use'], equals(1));
    });

    test('release returns component to available pool', () {
      final comp = pool.acquire();
      pool.release(comp);

      final debug = pool.debug();
      expect(debug['available'], equals(5));
      expect(debug['in_use'], equals(0));
    });

    test('acquire beyond pool size creates new components', () {
      for (int i = 0; i < 10; i++) {
        pool.acquire();
      }

      final debug = pool.debug();
      expect(debug['total'], equals(10));
      expect(debug['in_use'], equals(10));
    });

    test('release calls reset function', () {
      final comp = pool.acquire();
      comp.id = 'test_id';

      pool.release(comp);

      // reset() が呼ばれたため id は リセット
      expect(comp.id, isNull);
    });

    test('releaseAll returns all components to pool', () {
      pool.acquire();
      pool.acquire();
      pool.acquire();

      pool.releaseAll();

      final debug = pool.debug();
      expect(debug['in_use'], equals(0));
      expect(debug['available'], equals(8)); // 5 + 3
    });
  });

  group('FrustumCuller', () {
    late FrustumCuller culler;

    setUp(() {
      culler = FrustumCuller();
      culler.setViewport(const Rect.fromLTWH(0, 0, 800, 600));
    });

    test('object inside viewport is visible', () {
      final bounds = const Rect.fromLTWH(100, 100, 50, 50);
      expect(culler.isVisible(bounds), isTrue);
    });

    test('object outside viewport is not visible', () {
      final bounds = const Rect.fromLTWH(1000, 1000, 50, 50);
      expect(culler.isVisible(bounds), isFalse);
    });

    test('object at viewport boundary is visible', () {
      final bounds = const Rect.fromLTWH(0, 0, 10, 10);
      expect(culler.isVisible(bounds), isTrue);
    });

    test('object just outside viewport with margin is visible', () {
      // ビューポートは 0-800x0-600、margin 100
      // つまり -100-900x-100-700 が visible range
      final bounds = const Rect.fromLTWH(-50, 300, 50, 50);
      expect(culler.isVisible(bounds), isTrue);
    });

    test('filterVisible removes off-screen objects', () {
      final filtered = culler.filterVisible<_MockObject>(
        [
          _MockObject('inside', const Rect.fromLTWH(100, 100, 50, 50)),
          _MockObject('outside', const Rect.fromLTWH(1000, 1000, 50, 50)),
          _MockObject('inside2', const Rect.fromLTWH(200, 200, 50, 50)),
        ],
        (obj) => obj.bounds,
      );

      expect(filtered.length, equals(2));
      expect(filtered.map((o) => o.name), containsAll(['inside', 'inside2']));
    });
  });

  group('DepthSorter', () {
    test('sorts objects by Y position (depth)', () {
      final objects = [
        _MockObject('first', const Rect.fromLTWH(0, 100, 10, 10)),
        _MockObject('third', const Rect.fromLTWH(0, 300, 10, 10)),
        _MockObject('second', const Rect.fromLTWH(0, 200, 10, 10)),
      ];

      final sorted = DepthSorter.sortByDepth(
        objects,
        (obj) => obj.bounds.top,
      );

      expect(sorted[0].name, equals('first'));
      expect(sorted[1].name, equals('second'));
      expect(sorted[2].name, equals('third'));
    });

    test('objects with same Y maintain relative order', () {
      final objects = [
        _MockObject('a', const Rect.fromLTWH(0, 100, 10, 10)),
        _MockObject('b', const Rect.fromLTWH(50, 100, 10, 10)),
        _MockObject('c', const Rect.fromLTWH(100, 100, 10, 10)),
      ];

      final sorted = DepthSorter.sortByDepth(
        objects,
        (obj) => obj.bounds.top,
      );

      // Y座標が同じため、相対順序は保持される（stable sort）
      expect(sorted.map((o) => o.name).toList(), ['a', 'b', 'c']);
    });

    test('empty list returns empty', () {
      final sorted = DepthSorter.sortByDepth<_MockObject>(
        [],
        (obj) => obj.bounds.top,
      );

      expect(sorted, isEmpty);
    });
  });

  group('RenderingStats', () {
    late RenderingStats stats;

    setUp(() {
      stats = RenderingStats();
    });

    test('initial values are zero', () {
      expect(stats.triangleCount, equals(0));
      expect(stats.culledObjectCount, equals(0));
      expect(stats.visibleObjectCount, equals(0));
      expect(stats.drawCallCount, equals(0));
      expect(stats.textureBindCount, equals(0));
    });

    test('can set individual counters', () {
      stats.triangleCount = 100;
      stats.visibleObjectCount = 50;

      expect(stats.triangleCount, equals(100));
      expect(stats.visibleObjectCount, equals(50));
    });

    test('reset clears all counters', () {
      stats.triangleCount = 100;
      stats.culledObjectCount = 50;
      stats.visibleObjectCount = 50;

      stats.reset();

      expect(stats.triangleCount, equals(0));
      expect(stats.culledObjectCount, equals(0));
      expect(stats.visibleObjectCount, equals(0));
    });

    test('cullingRatio is 0 when no objects', () {
      expect(stats.cullingRatio, equals(0.0));
    });

    test('cullingRatio calculates correctly', () {
      stats.culledObjectCount = 30;
      stats.visibleObjectCount = 70;

      expect(stats.cullingRatio, equals(0.3));
    });

    test('debug returns valid structure', () {
      stats.triangleCount = 1000;
      stats.drawCallCount = 50;

      final debug = stats.debug();

      expect(debug, containsPair('triangles', 1000));
      expect(debug, containsPair('draw_calls', 50));
      expect(debug, containsPair('culled_objects', isA<int>()));
    });
  });

  group('OptimizedGameConfig', () {
    test('default config has reasonable values', () {
      final config = OptimizedGameConfig();

      expect(config.tickRate, equals(60.0));
      expect(config.allowFrameSkip, isTrue);
      expect(config.vsync, isTrue);
      expect(config.renderWhenPaused, isFalse);
      expect(config.enableCulling, isTrue);
      expect(config.enablePooling, isTrue);
    });

    test('debug config disables frame skip', () {
      final config = OptimizedGameConfig.debug();

      expect(config.allowFrameSkip, isFalse);
      expect(config.vsync, isFalse);
      expect(config.renderWhenPaused, isTrue);
    });

    test('custom config can override values', () {
      final config = OptimizedGameConfig(
        tickRate: 30.0,
        allowFrameSkip: false,
      );

      expect(config.tickRate, equals(30.0));
      expect(config.allowFrameSkip, isFalse);
    });
  });

  group('RenderQuality', () {
    test('fromMemory selects correct quality', () {
      expect(RenderQuality.fromMemory(256), equals(RenderQuality.low));
      expect(RenderQuality.fromMemory(768), equals(RenderQuality.medium));
      expect(RenderQuality.fromMemory(1536), equals(RenderQuality.high));
      expect(RenderQuality.fromMemory(3000), equals(RenderQuality.ultra));
    });

    test('max draw calls increases with quality', () {
      expect(RenderQuality.low.maxDrawCalls, lessThan(RenderQuality.medium.maxDrawCalls));
      expect(RenderQuality.medium.maxDrawCalls, lessThan(RenderQuality.high.maxDrawCalls));
      expect(RenderQuality.high.maxDrawCalls, lessThan(RenderQuality.ultra.maxDrawCalls));
    });

    test('max visible objects increases with quality', () {
      expect(RenderQuality.low.maxVisibleObjects, lessThan(RenderQuality.medium.maxVisibleObjects));
      expect(RenderQuality.medium.maxVisibleObjects, lessThan(RenderQuality.high.maxVisibleObjects));
      expect(RenderQuality.high.maxVisibleObjects, lessThan(RenderQuality.ultra.maxVisibleObjects));
    });

    test('effects disabled on low quality', () {
      expect(RenderQuality.low.enableEffects, isFalse);
      expect(RenderQuality.medium.enableEffects, isTrue);
      expect(RenderQuality.high.enableEffects, isTrue);
      expect(RenderQuality.ultra.enableEffects, isTrue);
    });
  });
}

/// テスト用ダミーコンポーネント
class _MockComponent {
  String? id;

  void reset() {
    id = null;
  }
}

/// テスト用ダミーオブジェクト
class _MockObject {
  final String name;
  final Rect bounds;

  _MockObject(this.name, this.bounds);
}
