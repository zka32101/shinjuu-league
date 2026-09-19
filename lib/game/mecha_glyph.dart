import 'dart:math';
import 'dart:ui';

import 'package:shinjuu_league/data/mecha_catalog.dart';
import 'package:shinjuu_league/data/models/mecha_model.dart';

/// 神獣の見た目を「実アート素材なしで」自動生成するためのシルエット生成器。
///
/// 各神獣のステータス（HP/ATK/SPD）・属性（EAST/WEST）・レアリティを元に、
/// 決定的（同じmechaIdなら常に同じ形）な幾何学アクセントを算出する。
/// 手描きアートの代わりに「データそのものが見た目になる」設計で、
/// バランス調整やカタログ拡張時も自動的にキャラごとの個性が出る。
///
/// - 装甲プレート vs 疾風フィン：HP比とSPD比の相対的な高さで選択（耐久型/速度型）
/// - エネルギースパイク数：ATK比に応じて増減（攻撃力の視覚的な強さ）
/// - 色相：EAST=暖色（緋色）、WEST=寒色（蒼銀）
/// - 装飾の密度・グロー強度：レアリティ（COMMON〜LEGEND）が高いほど豪華に
class MechaGlyph {
  const MechaGlyph._({
    required this.isArmored,
    required this.spikeCount,
    required this.accentCount,
    required this.accentColor,
    required this.glowStrength,
    required this.rotationOffset,
  });

  /// true=装甲プレート型（耐久寄り）、false=疾風フィン型（速度寄り）
  final bool isArmored;

  /// ATK比に応じたエネルギースパイクの本数（2〜6）
  final int spikeCount;

  /// レアリティに応じたプレート/フィンの枚数（3〜6）
  final int accentCount;

  /// 属性（EAST/WEST）から決まるアクセントカラー
  final Color accentColor;

  /// レアリティに応じたグローの強さ（0.0〜1.0）
  final double glowStrength;

  /// mechaIdから決定的に算出される回転オフセット（個体ごとに向きをずらす）
  final double rotationOffset;

  static const _eastColor = Color(0xFFFF7A45); // 緋色（暖色）
  static const _westColor = Color(0xFF4FC3F7); // 蒼銀（寒色）

  /// カタログ全体の平均ステータスに対する相対比で形状を決めるため、
  /// 個々のバランス調整（数値だけの変更）でも見た目が自動的に追従する。
  static double _averageOf(int Function(Mecha) selector) {
    final total = mechaCatalog.fold<int>(0, (sum, m) => sum + selector(m));
    return total / mechaCatalog.length;
  }

  factory MechaGlyph.forMecha(Mecha mecha) {
    final hpAvg = _averageOf((m) => m.baseStats.hp);
    final atkAvg = _averageOf((m) => m.baseStats.atk);
    final spdAvg = _averageOf((m) => m.baseStats.spd);

    final hpRatio = mecha.baseStats.hp / hpAvg;
    final atkRatio = mecha.baseStats.atk / atkAvg;
    final spdRatio = mecha.baseStats.spd / spdAvg;

    final accentCount = switch (mecha.rarity) {
      'LEGEND' => 6,
      'EPIC' => 5,
      'RARE' => 4,
      _ => 3,
    };
    final glowStrength = switch (mecha.rarity) {
      'LEGEND' => 1.0,
      'EPIC' => 0.75,
      'RARE' => 0.5,
      _ => 0.3,
    };

    return MechaGlyph._(
      isArmored: hpRatio >= spdRatio,
      spikeCount: (atkRatio * 3).round().clamp(2, 6),
      accentCount: accentCount,
      accentColor: mecha.origin == 'EAST' ? _eastColor : _westColor,
      glowStrength: glowStrength,
      rotationOffset: (mecha.mechaId.hashCode % 360) * pi / 180,
    );
  }

  /// [center]・[radius] を中心とした本体スプライトの周囲にシルエットを描画する。
  /// 呼び出し側（バトルトークン・キャラ選択カード等）のスケールに追従できるよう、
  /// すべての座標を radius に対する比率で計算する。
  void paint(Canvas canvas, Offset center, double radius, double opacity) {
    if (isArmored) {
      _paintPlates(canvas, center, radius, opacity);
    } else {
      _paintFins(canvas, center, radius, opacity);
    }
    _paintSpikes(canvas, center, radius, opacity);
  }

  void _paintPlates(Canvas canvas, Offset center, double radius, double opacity) {
    final paint = Paint()
      ..color = accentColor.withValues(alpha: opacity * (0.55 + glowStrength * 0.3))
      ..style = PaintingStyle.fill;
    final rimPaint = Paint()
      ..color = Color.lerp(accentColor, const Color(0xFF000000), 0.4)!
          .withValues(alpha: opacity * 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (var i = 0; i < accentCount; i++) {
      final angle = rotationOffset + (i / accentCount) * pi * 2;
      final plateWidth = 0.42; // ラジアン幅（台形プレートの角度幅）
      final inner = radius * 0.92;
      final outer = radius * 1.28;

      final path = Path()
        ..moveTo(
          center.dx + cos(angle - plateWidth / 2) * inner,
          center.dy + sin(angle - plateWidth / 2) * inner,
        )
        ..lineTo(
          center.dx + cos(angle - plateWidth / 3) * outer,
          center.dy + sin(angle - plateWidth / 3) * outer,
        )
        ..lineTo(
          center.dx + cos(angle + plateWidth / 3) * outer,
          center.dy + sin(angle + plateWidth / 3) * outer,
        )
        ..lineTo(
          center.dx + cos(angle + plateWidth / 2) * inner,
          center.dy + sin(angle + plateWidth / 2) * inner,
        )
        ..close();

      canvas.drawPath(path, paint);
      canvas.drawPath(path, rimPaint);
    }
  }

  void _paintFins(Canvas canvas, Offset center, double radius, double opacity) {
    final paint = Paint()
      ..color = accentColor.withValues(alpha: opacity * (0.5 + glowStrength * 0.3))
      ..style = PaintingStyle.fill;

    for (var i = 0; i < accentCount; i++) {
      final angle = rotationOffset + (i / accentCount) * pi * 2;
      // 後方へ流線形に反り返るフィン（速度感を出すため湾曲させる）
      final baseInner = center + Offset(cos(angle), sin(angle)) * radius * 0.9;
      final sweepAngle = angle + 0.55;
      final tip = center + Offset(cos(sweepAngle), sin(sweepAngle)) * radius * 1.5;
      final controlAngle = angle + 0.15;
      final control =
          center + Offset(cos(controlAngle), sin(controlAngle)) * radius * 1.35;

      final path = Path()
        ..moveTo(baseInner.dx, baseInner.dy)
        ..quadraticBezierTo(control.dx, control.dy, tip.dx, tip.dy)
        ..quadraticBezierTo(
          center.dx + cos(angle + 0.08) * radius * 1.05,
          center.dy + sin(angle + 0.08) * radius * 1.05,
          baseInner.dx,
          baseInner.dy,
        )
        ..close();

      canvas.drawPath(path, paint);
    }
  }

  void _paintSpikes(Canvas canvas, Offset center, double radius, double opacity) {
    final paint = Paint()
      ..color = Color.lerp(accentColor, const Color(0xFFFFFFFF), 0.5)!
          .withValues(alpha: opacity * (0.6 + glowStrength * 0.4));

    for (var i = 0; i < spikeCount; i++) {
      // プレート/フィンの隙間に打ち込むよう、位相を半分ずらして配置する
      final angle =
          rotationOffset + pi / spikeCount + (i / spikeCount) * pi * 2;
      final baseCenter = center + Offset(cos(angle), sin(angle)) * radius * 1.05;
      final tip = center + Offset(cos(angle), sin(angle)) * radius * 1.45;
      final perp = Offset(-sin(angle), cos(angle)) * radius * 0.09;

      final path = Path()
        ..moveTo(baseCenter.dx + perp.dx, baseCenter.dy + perp.dy)
        ..lineTo(tip.dx, tip.dy)
        ..lineTo(baseCenter.dx - perp.dx, baseCenter.dy - perp.dy)
        ..close();

      canvas.drawPath(path, paint);
    }
  }
}
