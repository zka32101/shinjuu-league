import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// ダメージ数値を画面上にフローティング表示する
class DamageNumber extends PositionComponent {
  final int damage;
  final bool isCritical;
  final Color color;
  final Vector2 initialPosition;

  late TextComponent textComponent;
  late Vector2 velocity;
  final _random = math.Random();

  DamageNumber({
    required Vector2 position,
    required this.damage,
    this.isCritical = false,
    this.color = Colors.white,
  }) : initialPosition = position,
       super(
         position: position,
         size: Vector2(60, 40),
         anchor: Anchor.center,
       );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final text = isCritical ? damage * 2 : damage;
    textComponent = TextComponent(
      text: '$text',
      textRenderer: TextPaint(
        style: TextStyle(
          color: isCritical ? Colors.red : color,
          fontSize: isCritical ? 28 : 24,
          fontWeight: isCritical ? FontWeight.bold : FontWeight.w600,
          shadows: [
            Shadow(
              offset: const Offset(1, 1),
              blurRadius: 3,
              color: Colors.black54,
            ),
          ],
        ),
      ),
      anchor: Anchor.center,
      position: size / 2,
    );
    add(textComponent);

    // 上方向 + ランダムな横方向への速度
    velocity = Vector2(
      (_random.nextBool() ? 1 : -1) * 30,
      -80,
    );
  }

  @override
  void update(double dt) {
    position += velocity * dt;
    velocity.y -= 120 * dt; // 重力効果（下降加速）

    // 透明度フェードアウト（0.6秒で完全透明）
    if (position.y < -50) {
      removeFromParent();
    }
  }
}

/// コンボカウンター表示（画面中央上部に一時的に出現）
class ComboCounter extends Component {
  int comboCount = 0;
  DateTime? lastComboTime;
  static const Duration comboDuration = Duration(seconds: 3);
  static const int comboThreshold = 3; // 3キル以上でコンボ表示

  late TextComponent textComponent;
  bool isVisible = false;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    textComponent = TextComponent(
      text: 'COMBO x$comboCount',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.amber,
          fontSize: 48,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              offset: Offset(2, 2),
              blurRadius: 4,
              color: Colors.black87,
            ),
          ],
        ),
      ),
      anchor: Anchor.center,
      position: Vector2.zero(),
    );
    add(textComponent);
    textComponent.text = '';
  }

  void addCombo() {
    lastComboTime = DateTime.now();
    comboCount++;

    if (comboCount >= comboThreshold) {
      isVisible = true;
      textComponent.text = 'COMBO x$comboCount';
    }
  }

  void resetCombo() {
    comboCount = 0;
    isVisible = false;
    textComponent.text = '';
  }

  @override
  void update(double dt) {
    if (isVisible && lastComboTime != null) {
      final elapsed = DateTime.now().difference(lastComboTime!);
      if (elapsed > comboDuration) {
        resetCombo();
      }

      // フェードアウト効果
      // (TextComponent opacity fading will be handled by removal at duration end)
    }
  }
}

/// バフ/デバフインジケーター（トークン上部に表示）
class BuffIndicatorUI extends PositionComponent {
  final String buffName;
  final Duration duration;
  final Color color;
  final Vector2 initialPosition;
  late DateTime startTime;

  BuffIndicatorUI({
    required Vector2 position,
    required this.buffName,
    required this.duration,
    this.color = Colors.green,
  }) : initialPosition = position,
       super();

  @override
  Future<void> onLoad() async {
    position = initialPosition;
    size = Vector2(40, 16);
    anchor = Anchor.center;
    startTime = DateTime.now();

    final textComponent = TextComponent(
      text: buffName.substring(0, 1), // 最初の1文字のみ
      textRenderer: TextPaint(
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      anchor: Anchor.center,
      position: size / 2,
    );

    add(
      RectangleComponent(
        size: size,
        paint: Paint()..color = color.withValues(alpha: 0.8),
      ),
    );
    add(textComponent);
  }

  @override
  void update(double dt) {
    final elapsed = DateTime.now().difference(startTime);
    if (elapsed > duration) {
      removeFromParent();
    }
  }
}
