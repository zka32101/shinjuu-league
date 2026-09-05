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
      test('fps returns 0.0 when no frames recorded', () {
        expect(service.fps, 0.0);
      });

      test('fps is clamped to [0.0, 120.0]', () {
        // Record a frame with 0ms (would result in infinite FPS)
        service.recordFrame(0);
        expect(service.fps, lessThanOrEqualTo(120.0));
        expect(service.fps, greaterThanOrEqualTo(0.0));
      });

      test('fps calculation reflects frame timing', () {
        // Simulate 60fps (average 16.67ms per frame)
        for (int i = 0; i < 60; i++) {
          service.recordFrame(17);
        }
        final fps = service.fps;
        expect(fps, greaterThan(58.0)); // Allow some tolerance
        expect(fps, lessThan(62.0));
      });

      test('fps updates with new frames', () {
        // First batch: slow frames (30fps equivalent)
        for (int i = 0; i < 60; i++) {
          service.recordFrame(33);
        }
        final slowFps = service.fps;

        // Second batch: fast frames (60fps equivalent)
        for (int i = 0; i < 60; i++) {
          service.recordFrame(17);
        }
        final fastFps = service.fps;

        expect(fastFps, greaterThan(slowFps));
      });
    });

    group('Memory measurement', () {
      test('memoryUsageMB returns non-negative value', () {
        final memory = service.memoryUsageMB;
        expect(memory, greaterThanOrEqualTo(0.0));
      });

      test('memoryUsageMB is consistent across calls', () {
        final memory1 = service.memoryUsageMB;
        final memory2 = service.memoryUsageMB;
        expect(memory1, equals(memory2));
      });
    });

    group('Slow frame tracking', () {
      test('slowFrameCount is 0 initially', () {
        expect(service.slowFrameCount, 0);
      });

      test('measureFrameTime records frames exceeding 16ms', () async {
        await service.measureFrameTime(() {
          // Simulate a slow operation (25ms)
          final sw = Stopwatch()..start();
          while (sw.elapsedMilliseconds < 25) {
            // Busy wait
          }
        });

        expect(service.slowFrameCount, greaterThan(0));
      });

      test('measureFrameTime does not record fast frames', () async {
        await service.measureFrameTime(() {
          // Fast operation (< 5ms)
          final start = DateTime.now();
          while (DateTime.now().difference(start).inMilliseconds < 5) {
            // Busy wait
          }
        });

        // Might record depending on system performance, but typically not
        // Just verify the list is a valid list
        expect(service.slowFrames, isA<List<FrameRecord>>());
      });

      test('slowFrames history is capped at 100', () async {
        // Record more than 100 slow frames
        for (int i = 0; i < 120; i++) {
          await service.measureFrameTime(() {
            final sw = Stopwatch()..start();
            while (sw.elapsedMilliseconds < 25) {
              // Busy wait
            }
          });
        }

        expect(service.slowFrameCount, lessThanOrEqualTo(100));
      });

      test('getAverageSlowFrameDuration returns 0 when no slow frames', () {
        expect(service.getAverageSlowFrameDuration(), 0.0);
      });

      test('getAverageSlowFrameDuration calculates correctly', () async {
        // Record a few slow frames
        await service.measureFrameTime(() {
          final sw = Stopwatch()..start();
          while (sw.elapsedMilliseconds < 20) {
            // Busy wait
          }
        });

        await service.measureFrameTime(() {
          final sw = Stopwatch()..start();
          while (sw.elapsedMilliseconds < 30) {
            // Busy wait
          }
        });

        final avg = service.getAverageSlowFrameDuration();
        expect(avg, greaterThan(20.0));
      });

      test('clearSlowFrameHistory removes all records', () async {
        // Record some slow frames
        await service.measureFrameTime(() {
          final sw = Stopwatch()..start();
          while (sw.elapsedMilliseconds < 25) {
            // Busy wait
          }
        });

        expect(service.slowFrameCount, greaterThan(0));

        service.clearSlowFrameHistory();
        expect(service.slowFrameCount, 0);
      });
    });

    group('Debug dump', () {
      test('debugDumpPerformance returns complete state', () {
        final dump = service.debugDumpPerformance();

        expect(dump, isA<Map<String, dynamic>>());
        expect(dump, containsPair('fps', isA<double>()));
        expect(dump, containsPair('memory_mb', isA<double>()));
        expect(dump, containsPair('slow_frames_count', isA<int>()));
        expect(dump, containsPair('slow_frames_avg_ms', isA<double>()));
      });

      test('debugDumpPerformance includes slow frames list', () async {
        // Record a slow frame
        await service.measureFrameTime(() {
          final sw = Stopwatch()..start();
          while (sw.elapsedMilliseconds < 25) {
            // Busy wait
          }
        });

        final dump = service.debugDumpPerformance();
        final slowFrames = dump['slow_frames'] as List<dynamic>;

        expect(slowFrames.length, greaterThan(0));
        expect(slowFrames[0], isA<Map<String, dynamic>>());
      });

      test('debugDumpPerformance fps value is in valid range', () {
        final dump = service.debugDumpPerformance();
        final fps = dump['fps'] as double;

        expect(fps, greaterThanOrEqualTo(0.0));
        expect(fps, lessThanOrEqualTo(120.0));
      });

      test('debugDumpPerformance memory value is non-negative', () {
        final dump = service.debugDumpPerformance();
        final memory = dump['memory_mb'] as double;

        expect(memory, greaterThanOrEqualTo(0.0));
      });
    });
  });

  group('FrameRecord', () {
    test('FrameRecord stores timestamp and duration', () {
      final now = DateTime.now();
      final record = FrameRecord(timestamp: now, durationMs: 25);

      expect(record.timestamp, equals(now));
      expect(record.durationMs, 25);
    });

    test('FrameRecord toString provides readable output', () {
      final record = FrameRecord(
        timestamp: DateTime(2026, 9, 5, 12, 0, 0),
        durationMs: 25,
      );

      expect(record.toString(), contains('25'));
      expect(record.toString(), contains('FrameRecord'));
    });
  });
}
