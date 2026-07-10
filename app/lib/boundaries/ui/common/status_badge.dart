import 'package:flutter/material.dart';

import '../../../core/theme/app_typography.dart';

// (#) Small rounded status tag like PREMIUM, ACTIVE or CONNECTED. It comes out
// filled or outlined depending on the colours you pass in. Reused anywhere the
// app needs a little status pill.
class StatusBadge extends StatelessWidget {
  const StatusBadge(
    this.text, { // (#) the short label inside the tag
    super.key,
    this.bg, // (#) fill colour, leave null for an outlined tag
    this.fg, // (#) text colour
    this.borderColor, // (#) outline colour when there's no fill
    this.weight, // (#) text weight
    this.radius = 6, // (#) corner roundness
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 2), // (#) inner spacing
  });

  final String text;
  final Color? bg;
  final Color? fg;
  final Color? borderColor;
  final FontWeight? weight;
  final double radius;
  final EdgeInsetsGeometry padding;

  // (#) Builds the tag: a rounded box with the fill or border, holding the label text.
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
