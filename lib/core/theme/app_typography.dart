import 'package:flutter/material.dart';

import 'app_colors.dart';

/// iOS-faithful type scale, mirrors docs/reference/typography.md
/// (1 iOS pt = 1 logical px). Default to [body] (17px) unless a spec says otherwise.
abstract final class AppTypography {
  static const largeTitle = TextStyle(fontSize: 34, fontWeight: FontWeight.w700, color: AppColors.ink);
  static const title1 = TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.ink);
  static const title2 = TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.ink);
  static const title3 = TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.ink);
  static const body = TextStyle(fontSize: 17, fontWeight: FontWeight.w500, color: AppColors.ink);
  static const headline = TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.ink);
  static const subheadline = TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.muted);
  static const footnote = TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.muted);
  static const caption1 = TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.muted);
  static const caption2 = TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.muted); // uppercase form labels

  /// Maps the iOS scale onto Material's [TextTheme] slots.
  static const textTheme = TextTheme(
    displayLarge: largeTitle,
    headlineLarge: title1,
    headlineMedium: title2,
    headlineSmall: title3,
    titleLarge: headline,
    bodyLarge: body,
    bodyMedium: subheadline,
    bodySmall: footnote,
    labelSmall: caption2,
  );
}
