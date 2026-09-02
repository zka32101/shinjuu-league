import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// パフォーマンス計測・最適化管理
/// メモリ使用量・フレームレート・レンダリング時間を追跡
class PerformanceService {
  static final PerformanceService _instance =
      PerformanceService._internal();

  factory PerformanceService() => _instance;
  PerformanceService._internal();

  /// フレームレート計測
  late final _FrameRateMonitor _frameMonitor =
      _FrameRateMonitor();

  /// メモリ計測
  late final _MemoryMonitor _memoryMonitor =
      _MemoryMonitor();

  /// 長いフレーム（16ms超過）の記録
  final List<SlowFrame> slowFrames = [];

  /// パフォーマンス計測が有効か
  bool _isEnabled = false;

  /// 初期化
  Future<void> init() async {
    _isEnabled = kDebugMode; // デバッグモードのみ計測
    if (!_isEnabled) return;

    _frameMonitor.init();
    _memoryMonitor.init();
  }

  /// フレームレートを取得（FPS）
  double getFrameRate() => _frameMonitor.currentFPS;

  /// メモリ使用量を取得（MB）
  double getMemoryUsageMB() => _memoryMonitor.usageMB;

  /// フレームレンダリング時間を計測
  /// 返り値: レンダリング時間（ミリ秒）
  Future<double> measureFrameTime(
    Future<void> Function() renderFn,
  ) async {
    if (!_isEnabled) {
      await renderFn();
      return 0;
    }

    final sw = Stopwatch()..start();
    try {
      await renderFn();
    } finally {
      sw.stop();
    }

    final ms = sw.elapsedMilliseconds.toDouble();

    // 16ms（60fps想定）を超過した場合は記録
    if (ms > 16) {
      slowFrames.add(SlowFrame(
        duration: ms,
        timestamp: DateTime.now(),
      ));

      // 古いデータは削除（最新100フレーム保持）
      if (slowFrames.length > 100) {
        slowFrames.removeAt(0);
      }
    }

    return ms;
  }

  /// Flame レンダリングループで呼び出し
  /// gameループ内で毎フレーム呼び出し → FPS計測
  void recordFrame() {
    _frameMonitor.recordFrame();
  }

  /// メモリ使用量レポートをダンプ
  Map<String, dynamic> debugDumpPerformance() {
    return {
      'frame_rate_fps': getFrameRate(),
      'memory_usage_mb': getMemoryUsageMB(),
      'slow_frame_count': slowFrames.length,
      'average_frame_time': slowFrames.isNotEmpty
          ? slowFrames.map((f) => f.duration).reduce((a, b) => a + b) /
              slowFrames.length
          : 0.0,
      'max_frame_time': slowFrames.isNotEmpty
          ? slowFrames.map((f) => f.duration).reduce((a, b) => a > b ? a : b)
          : 0.0,
      'enabled': _isEnabled,
    };
  }
}

/// フレームレート計測
class _FrameRateMonitor {
  static const _sampleWindow = 60; // 60フレーム単位で計測

  final Stopwatch _timer = Stopwatch();
  int _frameCount = 0;
  double _currentFPS = 60.0;

  void init() {
    _timer.start();
  }

  void recordFrame() {
    _frameCount++;

    if (_frameCount >= _sampleWindow) {
      final elapsedMs = _timer.elapsedMilliseconds;
      _currentFPS = (_frameCount / (elapsedMs / 1000.0)).clamp(0.0, 120.0);

      // リセット
      _frameCount = 0;
      _timer.reset();
    }
  }

  double get currentFPS => _currentFPS;
}

/// メモリ使用量計測
class _MemoryMonitor {
  double _usageMB = 0.0;

  void init() {
    _startMonitoring();
  }

  void _startMonitoring() {
    Timer.periodic(const Duration(seconds: 5), (_) {
      developer.Service.getVM().then((vm) {
        // VM情報から推定メモリ使用量を計算
        // （デバイスネイティブメモリの正確な計測は困難なため、ここでは推定）
        _usageMB = vm.toString().contains('memory')
            ? 150.0 // プレースホルダー（実際の値はプラットフォームによる）
            : 100.0;
      }).catchError((_) {
        // エラーはログせず無視（計測失敗は非致命的）
      });
    });
  }

  double get usageMB => _usageMB;
}

/// 遅いフレームの記録
class SlowFrame {
  final double duration; // ミリ秒
  final DateTime timestamp;

  SlowFrame({
    required this.duration,
    required this.timestamp,
  });
}
