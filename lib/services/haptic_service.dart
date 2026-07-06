import 'package:flutter/services.dart';

/// ハプティクス: キル＝軽 / 勝利＝パターン（UI/UXクオリティ基準）
class HapticService {
  static void onButtonTap() => HapticFeedback.selectionClick();

  static void onKill() => HapticFeedback.lightImpact();

  static void onAhaMoment() => HapticFeedback.mediumImpact();

  static Future<void> onWin() async {
    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 150));
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 150));
    HapticFeedback.mediumImpact();
  }

  static void onLoss() => HapticFeedback.vibrate();
}
