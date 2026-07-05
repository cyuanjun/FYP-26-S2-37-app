import 'package:flutter/material.dart';

import '../../../core/theme/app_typography.dart';

/// Shared status pill (PREMIUM / ACTIVE / CONNECTED / EDITING / CUSTOM / …) —
/// a small rounded tag in caption2. Filled ([bg]) or outlined ([borderColor]);
/// [fg]/[weight] default to caption2's muted w700.
class StatusBadge extends StatelessWidget {
  const StatusBadge(
    this.text, {
    super.key,
    this.bg,
    this.fg,
    this.borderColor,
    this.weight,
    this.radius = 6,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
  });

  final String text;
  final Color? bg;
  final Color? fg;
  final Color? borderColor;
  final FontWeight? weight;
  final double radius;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
        border: borderColor != null ? Border.all(color: borderColor!) : null,
      ),
      child: Text(text,
          style: AppTypography.caption2.copyWith(color: fg, fontWeight: weight)),
    );
  }
}
