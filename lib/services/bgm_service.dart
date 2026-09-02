import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shinjuu_league/services/asset_service.dart';

/// 背景音楽（BGM）一元管理
/// ループ再生・フェードイン/アウト対応
class BGMService {
  static final BGMService _instance = BGMService._internal();

  factory BGMService() => _instance;
  BGMService._internal();

  late final AssetService _assetService = AssetService();
  late final AudioPlayer _player = AudioPlayer();

  /// 現在再生中のBGM
  String? _currentBGM;

  /// 音量（0.0～1.0）
  double _volume = 0.6;

  /// フェードイン/アウト中フラグ
  bool _isFading = false;

  /// 初期化
  Future<void> init() async {
    try {
      // AudioPlayerの設定
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.setVolume(_volume);

      // 初期状態
      _currentBGM = null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('BGMService.init error (non-fatal): $e');
      }
    }
  }

  /// BGMを再生（自動ループ）
  Future<void> playBGM(String name) async {
    try {
      // 既に同じBGMが再生中なら何もしない
      if (_currentBGM == name) return;

      // 前のBGMをフェードアウト
      if (_currentBGM != null) {
        await _fadeOut(duration: const Duration(milliseconds: 500));
      }

      final path = _assetService.getBGMPath(name);
      if (path == null) {
        if (kDebugMode) {
          debugPrint('BGM not found: $name (playing silently)');
        }
        _currentBGM = name;
        return; // ファイルが無い場合は無音で進行
      }

      // 新しいBGMをフェードイン
      await _player.play(AssetSource(path));
      _currentBGM = name;
      await _fadeIn(duration: const Duration(milliseconds: 500));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('BGMService.playBGM error: $e');
      }
    }
  }

  /// BGMを停止
  Future<void> stopBGM() async {
    try {
      if (_currentBGM == null) return;

      await _fadeOut(duration: const Duration(milliseconds: 300));
      await _player.stop();
      _currentBGM = null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('BGMService.stopBGM error: $e');
      }
    }
  }

  /// フェードイン
  Future<void> _fadeIn({required Duration duration}) async {
    if (_isFading) return;
    _isFading = true;

    try {
      await _player.setVolume(0.0);
      final stepCount = 20;
      final stepDuration = duration.inMilliseconds ~/ stepCount;

      for (int i = 0; i < stepCount; i++) {
        await Future.delayed(Duration(milliseconds: stepDuration));
        final progress = (i + 1) / stepCount;
        await _player.setVolume(_volume * progress);
      }

      await _player.setVolume(_volume);
    } finally {
      _isFading = false;
    }
  }

  /// フェードアウト
  Future<void> _fadeOut({required Duration duration}) async {
    if (_isFading) return;
    _isFading = true;

    try {
      final stepCount = 20;
      final stepDuration = duration.inMilliseconds ~/ stepCount;
      final currentVol = await _player.getVolume();

      for (int i = 0; i < stepCount; i++) {
        await Future.delayed(Duration(milliseconds: stepDuration));
        final progress = 1.0 - ((i + 1) / stepCount);
        await _player.setVolume(currentVol * progress);
      }

      await _player.setVolume(0.0);
    } finally {
      _isFading = false;
    }
  }

  /// 音量を変更
  Future<void> setVolume(double vol) async {
    _volume = vol.clamp(0.0, 1.0);
    try {
      await _player.setVolume(_volume);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('BGMService.setVolume error: $e');
      }
    }
  }

  /// 現在再生中のBGMを取得
  String? get currentBGM => _currentBGM;

  /// 音量を取得
  double get volume => _volume;

  /// デバッグ用
  Map<String, dynamic> debugDumpBGM() {
    return {
      'current_bgm': _currentBGM ?? 'none',
      'volume': _volume,
      'is_playing': _currentBGM != null,
      'is_fading': _isFading,
    };
  }
}
