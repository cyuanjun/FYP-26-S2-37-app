import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Shared outlined-button styles — accent for actions, danger for
/// destructive ones (LOG OUT, DELETE SESSION).
class AppButtonStyles {
  AppButtonStyles._();

  /// [height] sets a full-width minimum height (the house CTA is 52);
  /// [radius] overrides the Material default corner rounding.
  static ButtonStyle outlinedAccent({double? height, double? radius}) =>
      _outlined(AppColors.accent, height: height, radius: radius);

  static ButtonStyle outlinedDanger({double? height, double? radius}) =>
      _outlined(AppColors.danger, height: height, radius: radius);

  static ButtonStyle _outlined(Color color, {double? height, double? radius}) =>
      OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color),
        minimumSize: height != null ? Size.fromHeight(height) : null,
        shape: radius != null
            ? RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(radius))
            : null,
      );
}
