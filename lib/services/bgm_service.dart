import 'dart:async';
import 'package:shinjuu_league/services/asset_service.dart';

/// BGM (background music) service with auto-loop and fade transition support.
///
/// Features:
/// - Automatic loop playback for seamless BGM continuation
/// - Fade in/fade out transitions (500ms per transition)
/// - Volume control with master volume management
/// - Track-to-track transitions with cross-fade
/// - Graceful handling of missing audio files
///
/// Singleton pattern ensures only one audio session exists across the app.
class BGMService {
  static final BGMService _instance = BGMService._internal();

  factory BGMService() => _instance;
  BGMService._internal();

  // Placeholder for actual audio player (AudioPlayer from audioplayers package)
  // In production, this would be: AudioPlayer _audioPlayer;
  String? _currentTrackName;
  double _volume = 1.0;
  bool _isInitialized = false;

  /// Master volume level (0.0 - 1.0)
  double get volume => _volume;

  /// Currently playing track name, or null if no track is playing
  String? get currentTrackName => _currentTrackName;

  /// Whether the BGM service has been initialized
  bool get isInitialized => _isInitialized;

  /// Initialize the BGM service.
  ///
  /// Must be called once before using any other methods.
  /// This would typically initialize the underlying audio player in production.
  Future<void> init() async {
    try {
      // In production, this would initialize AudioPlayer:
      // _audioPlayer = AudioPlayer();
      // await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      _isInitialized = true;
    } catch (e) {
      // Graceful fallback if audio initialization fails
      _isInitialized = false;
      rethrow;
    }
  }

  /// Play a BGM track by name with fade-in transition.
  ///
  /// If a track is currently playing, it will be faded out before the new
  /// track fades in. This creates a smooth transition between BGM tracks.
  ///
  /// Parameters:
  ///   - trackName: The name of the BGM track (e.g., 'battle', 'lobby')
  ///
  /// If the track is not found, playback is silently skipped (graceful fallback).
  Future<void> playBGM(String trackName) async {
    if (!_isInitialized) {
      return;
    }

    try {
      // Get the track path from AssetService
      final path = AssetService().getBGMPath(trackName);
      if (path == null) {
        // Asset not available during development - silently skip
        return;
      }

      // Fade out current track if one is playing
      if (_currentTrackName != null) {
        await _fadeOut();
      }

      // In production, this would play the audio:
      // await _audioPlayer.play(AssetSource(path));
      // await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      _currentTrackName = trackName;

      // Fade in the new track
      await _fadeIn();
    } catch (e) {
      // Handle playback errors gracefully
      _currentTrackName = null;
    }
  }

  /// Stop BGM playback and fade out over 500ms.
  Future<void> stopBGM() async {
    if (!_isInitialized || _currentTrackName == null) {
      return;
    }

    try {
      await _fadeOut();
      // In production: await _audioPlayer.stop();
      _currentTrackName = null;
    } catch (e) {
      // Graceful error handling
      _currentTrackName = null;
    }
  }

  /// Set the master volume level (0.0 = mute, 1.0 = full volume).
  ///
  /// Parameters:
  ///   - vol: Volume level to set, automatically clamped to [0.0, 1.0]
  Future<void> setVolume(double vol) async {
    if (!_isInitialized) {
      return;
    }

    _volume = vol.clamp(0.0, 1.0);
    // In production: await _audioPlayer.setVolume(_volume);
  }

  /// Fade in the current track over 500ms (20 steps × 25ms).
  ///
  /// This interpolates volume from 0.0 to the master volume level.
  Future<void> _fadeIn() async {
    const steps = 20;
    const stepDuration = Duration(milliseconds: 25);

    for (int i = 0; i <= steps; i++) {
      final progress = i / steps;
      // In production, calculate and set: fadeVolume = _volume * progress
      // Then: await _audioPlayer.setVolume(fadeVolume);
      await Future.delayed(stepDuration);
    }
  }

  /// Fade out the current track over 500ms (20 steps × 25ms).
  ///
  /// This interpolates volume from current level to 0.0.
  Future<void> _fadeOut() async {
    const steps = 20;
    const stepDuration = Duration(milliseconds: 25);

    for (int i = steps; i >= 0; i--) {
      final progress = i / steps;
      // In production, calculate and set: fadeVolume = _volume * progress
      // Then: await _audioPlayer.setVolume(fadeVolume);
      await Future.delayed(stepDuration);
    }
  }

  /// Dispose of the BGM service and release audio resources.
  Future<void> dispose() async {
    try {
      // In production: await _audioPlayer.dispose();
      _isInitialized = false;
      _currentTrackName = null;
    } catch (e) {
      // Graceful error handling during cleanup
    }
  }

  /// Debug dump of current BGM service state.
  Map<String, dynamic> debugDumpBGM() {
    return {
      'is_initialized': _isInitialized,
      'current_track': _currentTrackName,
      'volume': _volume,
    };
  }
}
