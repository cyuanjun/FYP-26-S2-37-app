import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

/// The app's light Material 3 theme (white base), built from the brand palette + iOS type scale.
ThemeData buildAppTheme() {
  final base = ThemeData.light(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: const ColorScheme.light(
      surface: AppColors.surface,
      onSurface: AppColors.ink,
      primary: AppColors.accent,
      onPrimary: AppColors.bg, // accent-on-accent text is illegal; CTA text is bg (white on violet)
      secondary: AppColors.info,
      onSecondary: AppColors.bg,
      error: AppColors.danger,
    ),
    textTheme: AppTypography.textTheme,
    dividerColor: AppColors.faint,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bg,
      foregroundColor: AppColors.ink,
      elevation: 0,
      centerTitle: false,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.bg,
        textStyle: AppTypography.headline,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      // A visible hairline so fields read as boxes even on surface-coloured
      // sheets (surface-on-surface fill was invisible — expert composer).
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.faint),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.faint),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
      ),
      labelStyle: AppTypography.caption2.copyWith(color: AppColors.muted),
    ),
  );
}
