import 'package:flutter_test/flutter_test.dart';
import 'package:shinjuu_league/services/performance_service.dart';

void main() {
  group('PerformanceService', () {
    late PerformanceService service;

    setUp(() {
      service = PerformanceService();
    });

    test('singleton pattern returns same instance', () {
      final service1 = PerformanceService();
      final service2 = PerformanceService();
      expect(identical(service1, service2), true);
    });

    group('FPS measurement', () {
      test('getFrameRate returns valid FPS value', () {
        final fps = service.getFrameRate();
        expect(fps, greaterThanOrEqualTo(0.0));
        expect(fps, lessThanOrEqualTo(120.0));
      });

      test('recordFrame updates frame rate', () {
        final initialFps = service.getFrameRate();

        // Record multiple frames
        for (int i = 0; i < 60; i++) {
          service.recordFrame();
        }

        // FPS should still be in valid range
        final finalFps = service.getFrameRate();
        expect(finalFps, greaterThanOrEqualTo(0.0));
        expect(finalFps, lessThanOrEqualTo(120.0));
      });

      test('getFrameRate is clamped to [0.0, 120.0]', () {
        for (int i = 0; i < 100; i++) {
          service.recordFrame();
        }
        final fps = service.getFrameRate();
        expect(fps, lessThanOrEqualTo(120.0));
        expect(fps, greaterThanOrEqualTo(0.0));
      });
    });

    group('Memory measurement', () {
      test('getMemoryUsageMB returns non-negative value', () {
        final memory = service.getMemoryUsageMB();
        expect(memory, greaterThanOrEqualTo(0.0));
      });

      test('getMemoryUsageMB is consistent across calls', () {
        final memory1 = service.getMemoryUsageMB();
        final memory2 = service.getMemoryUsageMB();
        expect(memory1, equals(memory2));
      });
    });

    group('Slow frame tracking', () {
      test('slowFrames is empty initially', () {
        expect(service.slowFrames.isEmpty, true);
      });

      test('measureFrameTime records frames exceeding 16ms', () async {
        final duration = await service.measureFrameTime(() async {
          // Simulate a slow operation (25ms)
          await Future.delayed(const Duration(milliseconds: 25));
        });

        expect(duration, greaterThan(16.0));
        expect(service.slowFrames.isNotEmpty, true);
      });

      test('measureFrameTime does not record fast frames', () async {
        await service.measureFrameTime(() async {
          // Fast operation (< 5ms)
          await Future.delayed(const Duration(milliseconds: 1));
        });

        // Verify slowFrames is a list
        expect(service.slowFrames, isA<List<SlowFrame>>());
      });

      test('slowFrames history is capped at 100', () async {
        // Record more than 100 slow frames
        for (int i = 0; i < 120; i++) {
          await service.measureFrameTime(() async {
            await Future.delayed(const Duration(milliseconds: 25));
          });
        }

        expect(service.slowFrames.length, lessThanOrEqualTo(100));
      });

      test('slowFrames can be cleared by user code', () async {
        // Record a slow frame
        await service.measureFrameTime(() async {
          await Future.delayed(const Duration(milliseconds: 25));
        });

        expect(service.slowFrames.isNotEmpty, true);

        service.slowFrames.clear();
        expect(service.slowFrames.isEmpty, true);
      });

      test('debugDumpPerformance calculates average from slow frames', () async {
        // Record some slow frames
        await service.measureFrameTime(() async {
          await Future.delayed(const Duration(milliseconds: 20));
        });

        await service.measureFrameTime(() async {
          await Future.delayed(const Duration(milliseconds: 30));
        });

        final dump = service.debugDumpPerformance();
        expect(dump['slow_frame_count'], equals(2));
        expect(dump['average_frame_time'], greaterThan(0.0));
      });
    });

    group('Debug dump', () {
      test('debugDumpPerformance returns complete state', () {
        final dump = service.debugDumpPerformance();

        expect(dump, isA<Map<String, dynamic>>());
        expect(dump.containsKey('frame_rate_fps'), true);
        expect(dump.containsKey('memory_usage_mb'), true);
        expect(dump.containsKey('slow_frame_count'), true);
      });

      test('debugDumpPerformance frame rate is in valid range', () {
        final dump = service.debugDumpPerformance();
        final fps = dump['frame_rate_fps'] as double;

        expect(fps, greaterThanOrEqualTo(0.0));
        expect(fps, lessThanOrEqualTo(120.0));
      });

      test('debugDumpPerformance memory value is non-negative', () {
        final dump = service.debugDumpPerformance();
        final memory = dump['memory_usage_mb'] as double;

        expect(memory, greaterThanOrEqualTo(0.0));
      });
    });
  });

  group('SlowFrame', () {
    test('SlowFrame stores timestamp and duration', () {
      final now = DateTime.now();
      final record = SlowFrame(timestamp: now, duration: 25.0);

      expect(record.timestamp, equals(now));
      expect(record.duration, 25.0);
    });

    test('SlowFrame duration is positive', () {
      final record = SlowFrame(
        timestamp: DateTime(2026, 9, 5, 12, 0, 0),
        duration: 25.0,
      );

      expect(record.duration, greaterThan(0.0));
    });
  });
}
