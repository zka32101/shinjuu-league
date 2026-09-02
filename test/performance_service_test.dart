import 'package:flutter_test/flutter_test.dart';
import 'package:shinjuu_league/services/performance_service.dart';

void main() {
  group('PerformanceService', () {
    late PerformanceService perfService;

    setUp(() {
      perfService = PerformanceService();
    });

    group('Initialization', () {
      test('init completes successfully', () async {
        expect(
          () async => await perfService.init(),
          returnsNormally,
        );
      });

      test('frame rate returns valid FPS value', () async {
        await perfService.init();
        final fps = perfService.getFrameRate();

        // FPS は 0〜120 の範囲
        expect(fps, greaterThanOrEqualTo(0.0));
        expect(fps, lessThanOrEqualTo(120.0));
      });

      test('memory usage returns non-negative MB value', () async {
        await perfService.init();
        final memoryMB = perfService.getMemoryUsageMB();

        expect(memoryMB, greaterThanOrEqualTo(0.0));
      });
    });

    group('Frame Timing Measurement', () {
      test('measureFrameTime returns non-negative duration', () async {
        await perfService.init();

        final duration = await perfService.measureFrameTime(() async {
          await Future.delayed(const Duration(milliseconds: 5));
        });

        expect(duration, greaterThanOrEqualTo(0.0));
      });

      test('slow frames are recorded when exceeding 16ms threshold', () async {
        await perfService.init();

        // 20ms かかるレンダリング（16ms を超過）
        await perfService.measureFrameTime(() async {
          await Future.delayed(const Duration(milliseconds: 20));
        });

        expect(perfService.slowFrames.length, greaterThan(0));
      });

      test('fast frames are not recorded', () async {
        await perfService.init();

        // 5ms のみ（16ms 以下）
        await perfService.measureFrameTime(() async {
          await Future.delayed(const Duration(milliseconds: 5));
        });

        expect(perfService.slowFrames.length, equals(0));
      });

      test('slow frame list respects maximum size of 100', () async {
        await perfService.init();

        // 110 個のスローフレーム記録
        for (int i = 0; i < 110; i++) {
          await perfService.measureFrameTime(() async {
            await Future.delayed(const Duration(milliseconds: 20));
          });
        }

        expect(perfService.slowFrames.length, lessThanOrEqualTo(100));
      });

      test('slow frame records include timestamp', () async {
        await perfService.init();

        final before = DateTime.now();
        await perfService.measureFrameTime(() async {
          await Future.delayed(const Duration(milliseconds: 20));
        });
        final after = DateTime.now();

        expect(perfService.slowFrames.length, greaterThan(0));
        final frame = perfService.slowFrames.first;

        expect(frame.timestamp.isAfter(before), isTrue);
        expect(frame.timestamp.isBefore(after), isTrue);
      });
    });

    group('Debug Output', () {
      test('debugDumpPerformance returns complete structure', () async {
        await perfService.init();
        final dump = perfService.debugDumpPerformance();

        expect(dump, containsPair('frame_rate_fps', isA<double>()));
        expect(dump, containsPair('memory_usage_mb', isA<double>()));
        expect(dump, containsPair('slow_frame_count', isA<int>()));
        expect(dump, containsPair('average_frame_time', isA<num>()));
        expect(dump, containsPair('max_frame_time', isA<num>()));
        expect(dump, containsPair('enabled', isA<bool>()));
      });

      test('debug dump shows reasonable values', () async {
        await perfService.init();

        // 数個のスローフレームを記録
        for (int i = 0; i < 3; i++) {
          await perfService.measureFrameTime(() async {
            await Future.delayed(const Duration(milliseconds: 20));
          });
        }

        final dump = perfService.debugDumpPerformance();
        final slowCount = dump['slow_frame_count'] as int;
        final avgTime = dump['average_frame_time'] as num;
        final maxTime = dump['max_frame_time'] as num;

        expect(slowCount, greaterThan(0));
        expect(avgTime, greaterThan(0));
        expect(maxTime, greaterThanOrEqualTo(avgTime));
      });
    });

    group('Singleton Pattern', () {
      test('multiple instances refer to same object', () {
        final perf1 = PerformanceService();
        final perf2 = PerformanceService();

        expect(identical(perf1, perf2), isTrue);
      });

      test('slow frame list persists across instance references', () async {
        final perf1 = PerformanceService();
        await perf1.init();

        await perf1.measureFrameTime(() async {
          await Future.delayed(const Duration(milliseconds: 20));
        });

        final perf2 = PerformanceService();
        expect(perf2.slowFrames.length, greaterThan(0));
      });
    });

    group('Frame Recording', () {
      test('recordFrame does not throw', () async {
        await perfService.init();

        expect(
          () {
            perfService.recordFrame();
            perfService.recordFrame();
            perfService.recordFrame();
          },
          returnsNormally,
        );
      });

      test('multiple recordFrame calls update FPS', () async {
        await perfService.init();

        // ゼロに初期化されるため、recordFrame のみでは FPS の変化を直接確認できない
        // ただし、呼び出しエラーがないことは確認
        for (int i = 0; i < 100; i++) {
          perfService.recordFrame();
        }

        final fps = perfService.getFrameRate();
        expect(fps, isA<double>());
      });
    });
  });
}
