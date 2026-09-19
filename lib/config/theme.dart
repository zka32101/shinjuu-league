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

  // UI colors
  static const background = Color(0xFF121212);
  static const cardBackground = Color(0xFF1E1E1E);
  static const borderColor = Color(0xFF404040);
  static const accentBlue = Color(0xFF3D7FE0);
  static const text = Color(0xFFFFFFFF);

  // Manual dark/light mode color pairs (for screens that switch by hand
  // instead of relying on ThemeData.brightness)
  static const darkBg = background;
  static const darkCard = cardBackground;
  static const darkText = Color(0xFF121212);
  static const lightBg = Color(0xFFF5F5F5);
  static const lightCard = Color(0xFFFFFFFF);
  static const lightText = Color(0xFFFFFFFF);
  static const mutedText = Color(0xFF9E9E9E);

  // Additional aliases some screens reference directly
  static const darkBackground = background;
  static const lightBackground = lightBg;
  static const primary = seed;
  static const textSecondary = mutedText;

  // Dark-mode elevation scale (progressively lighter surfaces)
  static const dark1 = Color(0xFF1A1A1A);
  static const dark2 = Color(0xFF242424);
  static const dark3 = Color(0xFF2E2E2E);
}

class AppTheme {
  static ThemeData light() => _base(Brightness.light);
  static ThemeData dark() => _base(Brightness.dark);

  static ThemeData _base(Brightness brightness) {
    return ThemeData(
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.seed,
        brightness: brightness,
      ),
      useMaterial3: true,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
