import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Shared surface card — the white rounded container behind every card in the
/// app (train/plan cards, analytics, goal cards, settings groups, …).
///
/// Defaults match the house style: surface colour, radius 16, uniform
/// [AppColors.cardShadow], padding 16. Pass [borderColor] for a hairline
/// ([AppColors.faint]) or emphasis (e.g. accent on a selected card).
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.radius = 16,
    this.borderColor,
    this.borderWidth = 1,
    this.shadow = true,
    this.width,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double radius;

  /// Hairline/emphasis border; no border when null.
  final Color? borderColor;
  final double borderWidth;

  final bool shadow;

  /// e.g. `double.infinity` to fill the parent.
  final double? width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: shadow ? AppColors.cardShadow : null,
        border: borderColor != null
            ? Border.all(color: borderColor!, width: borderWidth)
            : null,
      ),
      child: child,
    );
  }
}
