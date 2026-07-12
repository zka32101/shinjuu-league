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
}
