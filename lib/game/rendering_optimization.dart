import 'package:flutter/material.dart';

/// Flame レンダリング最適化ユーティリティ
/// オブジェクトプーリング・空間カリング・バッチ処理を統一管理

/// コンポーネント再利用プール
/// メモリ割当の最小化とガベージコレクション圧力削減
class ComponentPool<T> {
  final T Function() _factory;
  final void Function(T) _reset;
  final List<T> _available = [];
  final List<T> _inUse = [];

  /// poolSize: 初期プール サイズ
  ComponentPool({
    required this._factory,
    required this._reset,
    int poolSize = 10,
  }) {
    for (int i = 0; i < poolSize; i++) {
      _available.add(_factory());
    }
  }

  /// プールから取得（無い場合は新規作成）
  T acquire() {
    if (_available.isNotEmpty) {
      final item = _available.removeLast();
      _inUse.add(item);
      return item;
    }

    // プール枯渇時は新規作成
    final item = _factory();
    _inUse.add(item);
    return item;
  }

  /// プールに返却（次回再利用のため初期化）
  void release(T item) {
    if (_inUse.remove(item)) {
      _reset(item);
      _available.add(item);
    }
  }

  /// 全て返却
  void releaseAll() {
    for (final item in _inUse.toList()) {
      release(item);
    }
  }

  /// デバッグ情報
  Map<String, int> debug() => {
    'available': _available.length,
    'in_use': _inUse.length,
    'total': _available.length + _inUse.length,
  };
}

/// 視錐台カリング（Frustum Culling）
/// 画面外のオブジェクトをレンダリングしない最適化
class FrustumCuller {
  late Rect _viewportBounds;
  final double _cullingMargin = 100; // 画面外100pxまで余裕を持たせる

  /// ビューポート（カメラ表示範囲）を設定
  void setViewport(Rect bounds) {
    _viewportBounds = bounds.inflate(_cullingMargin);
  }

  /// オブジェクト矩形が画面内にあるか判定
  bool isVisible(Rect objectBounds) {
    return _viewportBounds.overlaps(objectBounds);
  }

  /// 複数オブジェクトをフィルタ（画面内のみ抽出）
  List<T> filterVisible<T>(
    List<T> objects,
    Rect Function(T) getBounds,
  ) {
    return objects.where((obj) {
      final bounds = getBounds(obj);
      return isVisible(bounds);
    }).toList();
  }
}

/// スクリーンスペース・オブジェクト・ソーティング
/// 奥行き関係を正しく描画するためのZ-sort
class DepthSorter {
  /// Y座標（スクリーン空間）に基づいてオブジェクトをソート
  /// 奥のオブジェクト → 手前のオブジェクト の順で返す
  static List<T> sortByDepth<T>(
    List<T> objects,
    double Function(T) getScreenY,
  ) {
    final sorted = List<T>.from(objects);
    sorted.sort((a, b) {
      final yA = getScreenY(a);
      final yB = getScreenY(b);
      return yA.compareTo(yB); // 昇順（奥から手前）
    });
    return sorted;
  }
}

/// レンダリング統計追跡
class RenderingStats {
  int triangleCount = 0;
  int culledObjectCount = 0;
  int visibleObjectCount = 0;
  int drawCallCount = 0;
  int textureBindCount = 0;

  /// 統計をリセット（フレーム開始時に呼び出し）
  void reset() {
    triangleCount = 0;
    culledObjectCount = 0;
    visibleObjectCount = 0;
    drawCallCount = 0;
    textureBindCount = 0;
  }

  /// デバッグ出力
  Map<String, int> debug() => {
    'triangles': triangleCount,
    'culled_objects': culledObjectCount,
    'visible_objects': visibleObjectCount,
    'draw_calls': drawCallCount,
    'texture_binds': textureBindCount,
  };

  /// 削減率を計算（カリング効果）
  double get cullingRatio {
    final total = culledObjectCount + visibleObjectCount;
    if (total == 0) return 0.0;
    return culledObjectCount / total;
  }
}

/// Flameゲームの最適化設定
class OptimizedGameConfig {
  /// ティック率（デフォルト: 60fps）
  final double tickRate;

  /// フレームスキップを許可（フレームドロップ時）
  final bool allowFrameSkip;

  /// VSync同期
  final bool vsync;

  /// 背景レンダリング（他のアプリが前面の時は最適化）
  final bool renderWhenPaused;

  /// カリング有効化
  final bool enableCulling;

  /// オブジェクトプーリング有効化
  final bool enablePooling;

  OptimizedGameConfig({
    this.tickRate = 60.0,
    this.allowFrameSkip = true,
    this.vsync = true,
    this.renderWhenPaused = false,
    this.enableCulling = true,
    this.enablePooling = true,
  });

  /// デバッグモード用設定（詳細ログ出力）
  factory OptimizedGameConfig.debug() {
    return OptimizedGameConfig(
      tickRate: 60.0,
      allowFrameSkip: false, // フレームドロップを即座に検知
      vsync: false,
      renderWhenPaused: true,
      enableCulling: true,
      enablePooling: true,
    );
  }
}

/// 段階的レンダリング品質（デバイス性能に応じた自動調整）
enum RenderQuality {
  low('低'),
  medium('中'),
  high('高'),
  ultra('最高');

  const RenderQuality(this.label);
  final String label;

  /// デバイスメモリ（MB）から推奨品質を決定
  static RenderQuality fromMemory(double memoryMB) {
    if (memoryMB < 512) return RenderQuality.low;
    if (memoryMB < 1024) return RenderQuality.medium;
    if (memoryMB < 2048) return RenderQuality.high;
    return RenderQuality.ultra;
  }

  /// 品質に応じた最大ドローコール数を返す
  int get maxDrawCalls {
    switch (this) {
      case RenderQuality.low:
        return 50;
      case RenderQuality.medium:
        return 150;
      case RenderQuality.high:
        return 300;
      case RenderQuality.ultra:
        return 1000;
    }
  }

  /// 品質に応じた最大オブジェクト数
  int get maxVisibleObjects {
    switch (this) {
      case RenderQuality.low:
        return 100;
      case RenderQuality.medium:
        return 300;
      case RenderQuality.high:
        return 600;
      case RenderQuality.ultra:
        return 2000;
    }
  }

  /// シャドウ・パーティクル等の演出を有効にするか
  bool get enableEffects {
    return this != RenderQuality.low;
  }
}
