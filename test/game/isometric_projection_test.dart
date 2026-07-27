import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shinjuu_league/game/isometric_projection.dart';

void main() {
  group('IsometricProjection', () {
    const projection = IsometricProjection();

    test('原点は画面原点に投影される', () {
      final screen = projection.toScreen(0, 0);
      expect(screen.x, 0);
      expect(screen.y, 0);
    });

    test('gridXが正なら画面X座標も正（自陣と敵陣が左右に分かれる）', () {
      final screen = projection.toScreen(1, 0);
      expect(screen.x, greaterThan(0));
    });

    test('gridXが負なら画面X座標も負', () {
      final screen = projection.toScreen(-1, 0);
      expect(screen.x, lessThan(0));
    });

    test('点対称：(x,y)と(-x,-y)の投影は互いに逆符号', () {
      final a = projection.toScreen(1.5, -0.6);
      final b = projection.toScreen(-1.5, 0.6);
      expect(a.x, closeTo(-b.x, 0.0001));
      expect(a.y, closeTo(-b.y, 0.0001));
    });

    test('toGridはtoScreenの逆変換になっている（往復一致）', () {
      const cases = [
        [0.0, 0.0],
        [1.0, 0.0],
        [0.0, 1.0],
        [1.8, -1.8],
        [-2.4, 3.1],
      ];
      for (final c in cases) {
        final screen = projection.toScreen(c[0], c[1]);
        final grid = projection.toGrid(screen);
        expect(grid.x, closeTo(c[0], 0.0001), reason: 'gridX for $c');
        expect(grid.y, closeTo(c[1], 0.0001), reason: 'gridY for $c');
      }
    });

    test('画面座標上で等距離でも、グリッド空間では方向により真の距離が異なる（等角投影の歪みの検証）', () {
      // tileWidth(96) != tileHeight(48) のため、画面上で同じ半径の円は
      // グリッド空間では真円にならない（縦横で伸縮する）ことを確認する。
      final onScreenCircleA = Vector2(46, 0); // 純横方向
      final onScreenCircleB = Vector2(0, 46); // 純縦方向

      final gridA = projection.toGrid(onScreenCircleA);
      final gridB = projection.toGrid(onScreenCircleB);

      // 同じ画面上の距離(46px)でも、グリッド空間での距離は一致しない
      expect(gridA.length, isNot(closeTo(gridB.length, 0.01)));
    });
  });
}
