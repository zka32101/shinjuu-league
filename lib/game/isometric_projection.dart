import 'package:flame/game.dart';

/// グリッド座標を等角投影（2.5D）のスクリーン座標へ変換する。
/// gridX: レーンの奥行き方向（-側=自陣、+側=敵陣）
/// gridY: レーン内の横方向オフセット（複数参加者の並び用）
class IsometricProjection {
  const IsometricProjection({this.tileWidth = 96, this.tileHeight = 48});

  final double tileWidth;
  final double tileHeight;

  Vector2 toScreen(double gridX, double gridY) {
    final screenX = (gridX - gridY) * (tileWidth / 2);
    final screenY = (gridX + gridY) * (tileHeight / 2);
    return Vector2(screenX, screenY);
  }

  /// toScreen の逆変換。tileWidth != tileHeight のため画面座標上の距離は
  /// 縦横で伸縮する（等方ではない）。真の間合い判定にはこちらでグリッド空間に
  /// 戻してから距離を測る必要がある（射程判定が歪んだ楕円になる問題の対策）。
  Vector2 toGrid(Vector2 screen) {
    final a = screen.x / (tileWidth / 2);
    final b = screen.y / (tileHeight / 2);
    final gridX = (a + b) / 2;
    final gridY = (b - a) / 2;
    return Vector2(gridX, gridY);
  }
}
