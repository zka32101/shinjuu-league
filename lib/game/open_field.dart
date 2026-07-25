import 'dart:ui';

import 'package:flame/components.dart';

/// レーン外の開けたエリアを示す背景プレート（マップ全体を自由に歩き回れるようにした際、
/// レーン外が真っ暗な虚空に見えないようにするための簡易的な地面表現）。
class OpenField extends PositionComponent {
  OpenField({required this.halfWidth, required this.halfHeight});

  final double halfWidth;
  final double halfHeight;

  @override
  void render(Canvas canvas) {
    final rect = Rect.fromLTWH(
      -halfWidth,
      -halfHeight,
      halfWidth * 2,
      halfHeight * 2,
    );
    canvas.drawRect(rect, Paint()..color = const Color(0xFF181B24));
  }
}
