import 'package:audioplayers/audioplayers.dart';

/// SE/BGMファイル本体（mp3等）は別途アセット追加が必要（`assets/sounds/`）。
/// ファイル未配置でもアプリがクラッシュしないよう再生失敗は握りつぶす。
///
/// 注意: audioplayers の AssetSource は `assets/` プレフィックスを内部で
/// 補完するため、ここでは `AppConfig.soundsPath`（Lottie.asset 等が使う
/// フルパス）ではなく `sounds/` からの相対パスを使う。
class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final _sePlayer = AudioPlayer();

  Future<void> playButtonTapSe() => _playSafe('button_tap.mp3');
  Future<void> playKillSe() => _playSafe('kill.mp3');
  Future<void> playAhaMomentSe() => _playSafe('aha_moment.mp3');
  Future<void> playWinSe() => _playSafe('win.mp3');
  Future<void> playLossSe() => _playSafe('loss.mp3');

  Future<void> _playSafe(String fileName) async {
    try {
      await _sePlayer.stop();
      await _sePlayer.play(AssetSource('sounds/$fileName'));
    } catch (_) {
      // Step 8 時点ではSEファイル本体は未同梱のため無音でスキップ
    }
  }

  void dispose() => _sePlayer.dispose();
}
