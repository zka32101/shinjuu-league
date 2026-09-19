import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

/// 資産（Lottie・SE・BGM）の一元管理
/// 実アセットが無い場合でも安全に動作する設計
class AssetService {
  static final AssetService _instance = AssetService._internal();

  factory AssetService() => _instance;
  AssetService._internal();

  /// プリロード済み資産のキャッシュ
  final Map<String, dynamic> _assetCache = {};

  /// 資産ロード状態
  final ValueNotifier<AssetLoadState> loadState =
      ValueNotifier<AssetLoadState>(AssetLoadState.idle);

  /// ロード済み資産数のトラッキング
  int _loadedCount = 0;
  int _totalCount = 0;

  /// 初期化（アプリ起動時に一度だけ呼び出し）
  /// 実アセットが無い場合は silent に skip する
  Future<void> init() async {
    try {
      loadState.value = AssetLoadState.loading;
      // 再実行時にカウンターが誤って積み上がらないようリセット
      _loadedCount = 0;
      _totalCount = 0;

      // 「実ファイルが無くても動く」設計のため、
      // プリロードは段階的に試行し、失敗は握りつぶす
      await _preloadAnimations();
      await _preloadSoundEffects();
      await _preloadBGM();

      loadState.value = AssetLoadState.complete;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AssetService.init error (non-fatal): $e');
      }
      // エラーが発生してもアプリは起動し続ける
      loadState.value = AssetLoadState.complete;
    }
  }

  /// Lottie アニメーションのプリロード
  Future<void> _preloadAnimations() async {
    final animations = [
      'kill_burst.json',
      'win_celebration.json',
      'lose_fade.json',
      'aha_moment.json',
      'level_up.json',
    ];
    _totalCount += animations.length;

    for (final name in animations) {
      final path = 'assets/animations/$name';
      try {
        // 実ファイルの有無を確認（アセットマニフェスト経由）
        // 無い場合は rootBundle.load が例外を投げる
        await rootBundle.load(path);
        _assetCache['animation_$name'] = path;
        _loadedCount++;
      } catch (_) {
        // ファイルが無い → キャッシュに登録しない（getAnimation で null を返す）
        if (kDebugMode) {
          debugPrint('Animation asset not found: $name (expected during development)');
        }
      }
    }
  }

  /// SE（効果音）のプリロード
  Future<void> _preloadSoundEffects() async {
    final effects = [
      'kill.mp3',
      'aha_moment.mp3',
      'win.mp3',
      'lose.mp3',
      'button_tap.mp3',
      'level_up.mp3',
      'evolution_select.mp3',
      'skill_activate.mp3',
      'critical_hit.mp3',
      'heal.mp3',
      'item_pickup.mp3',
      'error.mp3',
    ];
    _totalCount += effects.length;

    for (final name in effects) {
      final path = 'assets/sounds/$name';
      try {
        await rootBundle.load(path);
        _assetCache['sound_$name'] = path;
        _loadedCount++;
      } catch (_) {
        if (kDebugMode) {
          debugPrint('Sound effect not found: $name (expected during development)');
        }
      }
    }
  }

  /// BGM（背景音楽）のプリロード
  Future<void> _preloadBGM() async {
    final bgmTracks = [
      'lobby.mp3',
      'matching.mp3',
      'battle.mp3',
      'result_win.mp3',
    ];
    _totalCount += bgmTracks.length;

    for (final name in bgmTracks) {
      final path = 'assets/sounds/$name';
      try {
        await rootBundle.load(path);
        _assetCache['bgm_$name'] = path;
        _loadedCount++;
      } catch (_) {
        if (kDebugMode) {
          debugPrint('BGM track not found: $name (expected during development)');
        }
      }
    }
  }

  /// Lottie アニメーション JSON パスを取得
  /// キャッシュに無い場合は null（表示側で fallback 対応）
  String? getAnimationPath(String name) {
    return _assetCache['animation_$name'] as String?;
  }

  /// SE ファイルパスを取得
  String? getSoundEffectPath(String name) {
    return _assetCache['sound_$name'] as String?;
  }

  /// BGM ファイルパスを取得
  String? getBGMPath(String name) {
    return _assetCache['bgm_$name'] as String?;
  }

  /// キャッシュにあるか確認
  bool hasAnimation(String name) => _assetCache.containsKey('animation_$name');
  bool hasSoundEffect(String name) => _assetCache.containsKey('sound_$name');
  bool hasBGM(String name) => _assetCache.containsKey('bgm_$name');

  /// ロード進度を取得（0.0〜1.0）
  double getLoadProgress() {
    if (_totalCount == 0) return 0.0;
    return (_loadedCount / _totalCount).clamp(0.0, 1.0);
  }

  /// デバッグ用: キャッシュ状態をダンプ
  Map<String, dynamic> debugDumpAssets() {
    return {
      'loaded_count': _loadedCount,
      'total_count': _totalCount,
      'cache_size': _assetCache.length,
      'animations': _assetCache.keys
          .where((k) => k.startsWith('animation_'))
          .toList(),
      'sounds': _assetCache.keys
          .where((k) => k.startsWith('sound_'))
          .toList(),
      'bgm_tracks': _assetCache.keys
          .where((k) => k.startsWith('bgm_'))
          .toList(),
      'load_state': loadState.value.toString(),
    };
  }

  /// キャッシュをクリア（メモリ圧迫時）
  void clearCache() {
    _assetCache.clear();
    _loadedCount = 0;
    _totalCount = 0;
  }

  /// テスト専用: シングルトンの状態を完全に初期状態へ戻す。
  /// 本番の `clearCache()` は意図的に `loadState` を変えない
  /// （メモリ解放してもロード済み扱いは維持したいため）が、
  /// テストではケース間の汚染を避けるためロード状態も含めて戻す必要がある。
  @visibleForTesting
  void resetForTesting() {
    clearCache();
    loadState.value = AssetLoadState.idle;
  }
}

/// アセットロード状態
enum AssetLoadState {
  idle('待機中'),
  loading('ロード中'),
  complete('完了');

  const AssetLoadState(this.label);
  final String label;
}
