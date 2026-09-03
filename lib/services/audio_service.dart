import 'package:audioplayers/audioplayers.dart';
import 'package:shinjuu_league/data/models/skill_model.dart';

/// SE/BGMファイル本体（mp3等）は別途アセット追加が必要（`assets/sounds/`）。
/// ファイル未配置でもアプリがクラッシュしないよう再生失敗は握りつぶす。
///
/// Phase 4実装: SE/BGM の完全な音響デザイン管理
/// - スキルタイプ別のSE発音（offensive/defensive/utility）
/// - BGMシステムの平滑な切り替え
/// - ボリューム独立管理（SE/BGM各別）
/// - オーディオプリファレンス（ミュート/音量設定）
///
/// 注意: audioplayers の AssetSource は `assets/` プレフィックスを内部で
/// 補完するため、ここでは `AppConfig.soundsPath`（Lottie.asset 等が使う
/// フルパス）ではなく `sounds/` からの相対パスを使う。
class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _sePlayer = AudioPlayer();
  final AudioPlayer _bgmPlayer = AudioPlayer();

  // ボリューム管理（0.0 ~ 1.0）
  double _seVolume = 0.7;
  double _bgmVolume = 0.5;
  bool _isMuted = false;

  // 現在再生中のBGM
  String? _currentBgm;

  // ゲッター
  double get seVolume => _seVolume;
  double get bgmVolume => _bgmVolume;
  bool get isMuted => _isMuted;
  String? get currentBgm => _currentBgm;

  // === UI 用音声エフェクト ===
  Future<void> playButtonTapSe() => _playSafe(_sePlayer, 'button_tap.mp3');

  // === バトルイベント音声 ===
  Future<void> playKillSe() => _playSafe(_sePlayer, 'kill.mp3');
  Future<void> playAhaMomentSe() => _playSafe(_sePlayer, 'aha_moment.mp3');
  Future<void> playWinSe() => _playSafe(_sePlayer, 'win.mp3');
  Future<void> playLossSe() => _playSafe(_sePlayer, 'loss.mp3');

  // === ダメージ音声 ===
  Future<void> playHitSe() => _playSafe(_sePlayer, 'hit.mp3');
  Future<void> playCriticalHitSe() => _playSafe(_sePlayer, 'critical_hit.mp3');

  // === スキル発動音声（スキルタイプ別） ===
  Future<void> playSkillSe(SkillType skillType) {
    final soundFile = _getSoundFileForSkillType(skillType);
    return _playSafe(_sePlayer, soundFile);
  }

  String _getSoundFileForSkillType(SkillType skillType) {
    switch (skillType) {
      case SkillType.offensive:
        return 'skill_offensive.mp3'; // 派手で短い攻撃音
      case SkillType.defensive:
        return 'skill_defensive.mp3'; // 深く重い防御音
      case SkillType.utility:
        return 'skill_utility.mp3'; // 軽い汎用効果音
    }
  }

  // === BGM管理 ===
  /// BGMをループ再生開始（既存BGMがあれば停止）
  Future<void> playBgm(
    String bgmName, {
    double crossfadeDuration = 0.5,
  }) async {
    if (_currentBgm == bgmName) return; // 同じBGMは重複再生しない

    try {
      if (_currentBgm != null) {
        // クロスフェード: 既存BGMをフェードアウト
        await _fadeOutBgm(
          duration: Duration(
            milliseconds: (crossfadeDuration * 1000).toInt(),
          ),
        );
      }

      _currentBgm = bgmName;
      await _bgmPlayer.stop();
      await _bgmPlayer.play(
        AssetSource('sounds/$bgmName.mp3'),
        volume: _isMuted ? 0 : _bgmVolume,
      );
      // ループ設定
      await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
    } catch (_) {
      // BGM再生失敗は無音で続行
      _currentBgm = null;
    }
  }

  /// BGMをフェードアウトして停止
  Future<void> _fadeOutBgm({
    Duration duration = const Duration(milliseconds: 500),
  }) async {
    try {
      final steps = 10;
      final stepDuration = duration.inMilliseconds ~/ steps;

      for (int i = 0; i < steps; i++) {
        await Future.delayed(Duration(milliseconds: stepDuration));
        final newVolume = _bgmVolume * (1 - (i + 1) / steps);
        await _bgmPlayer.setVolume(newVolume.clamp(0, 1));
      }

      await _bgmPlayer.stop();
    } catch (_) {
      // フェード失敗時は即座に停止
      await _bgmPlayer.stop();
    }
  }

  /// BGMを停止
  Future<void> stopBgm() async {
    try {
      await _bgmPlayer.stop();
      _currentBgm = null;
    } catch (_) {}
  }

  // === ボリューム制御 ===
  /// SE音量を設定（0.0 ~ 1.0）
  Future<void> setSeVolume(double volume) async {
    _seVolume = volume.clamp(0, 1);
    if (!_isMuted) {
      await _sePlayer.setVolume(_seVolume);
    }
  }

  /// BGM音量を設定（0.0 ~ 1.0）
  Future<void> setBgmVolume(double volume) async {
    _bgmVolume = volume.clamp(0, 1);
    if (!_isMuted) {
      await _bgmPlayer.setVolume(_bgmVolume);
    }
  }

  /// 全音声をミュート/ミュート解除
  Future<void> setMuted(bool muted) async {
    _isMuted = muted;
    final seVol = muted ? 0.0 : _seVolume;
    final bgmVol = muted ? 0.0 : _bgmVolume;

    try {
      await _sePlayer.setVolume(seVol);
      await _bgmPlayer.setVolume(bgmVol);
    } catch (_) {}
  }

  // === 内部ヘルパー ===
  Future<void> _playSafe(AudioPlayer player, String fileName) async {
    if (_isMuted) return; // ミュート中は再生しない

    try {
      await player.stop();
      final volume = player == _sePlayer ? _seVolume : _bgmVolume;
      await player.play(AssetSource('sounds/$fileName'), volume: volume);
    } catch (_) {
      // SE/BGM再生失敗は無音でスキップ
    }
  }

  void dispose() {
    _sePlayer.dispose();
    _bgmPlayer.dispose();
  }
}
