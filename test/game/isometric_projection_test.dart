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
  });
}
