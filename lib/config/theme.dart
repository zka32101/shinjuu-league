import 'package:flutter/material.dart';

/// 神獣リーグ カラーパレット：東（緋色）× 西（蒼銀）のテーマ対比
abstract class AppColors {
  static const seed = Color(0xFF6A3FBF); // deep purple base
  static const eastAccent = Color(0xFFE0533D); // 東：緋色
  static const westAccent = Color(0xFF3D7FE0); // 西：蒼銀
  static const gold = Color(0xFFE0B93D); // ランク・報酬
  static const win = Color(0xFF3DDC84);
  static const loss = Color(0xFFE0533D);

  static const rarityCommon = Color(0xFF9E9E9E);
  static const rarityRare = Color(0xFF3D7FE0);
  static const rarityEpic = Color(0xFFA355E0);
  static const rarityLegend = Color(0xFFE0B93D);
}

class AppTheme {
  static ThemeData light() => _base(Brightness.light);
  static ThemeData dark() => _base(Brightness.dark);

  static ThemeData _base(Brightness brightness) {
    return ThemeData(
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.seed, brightness: brightness),
      useMaterial3: true,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
