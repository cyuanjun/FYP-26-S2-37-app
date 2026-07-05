import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// Shared "label + value" stat tile — the one widget behind every stats row
/// (history analytics/cards, profile lifetime stats, live capture metrics,
/// workout summary and history detail).
///
/// The value is coloured by [AppColors.metricColor] from the label, so the
/// same metric is always the same colour app-wide.
class StatTile extends StatelessWidget {
  const StatTile(
    this.label,
    this.value, {
    super.key,
    this.delta,
    this.dim = false,
    this.valueFirst = false,
    this.boxed = false,
    this.valueStyle,
    this.labelStyle,
    this.gap = 2,
  });

  final String label;
  final String value;

  /// vs-prior-period change: renders an ↑/↓ arrow next to the value
  /// (green up / red down). Hidden when null or 0.
  final int? delta;

  /// Fade the value to [AppColors.faint] (paused live capture).
  final bool dim;

  /// Render the value above the label instead of below it.
  final bool valueFirst;

  /// Fixed-width tile on its own surface card instead of expanding into the
  /// enclosing Row.
  final bool boxed;

  final TextStyle? valueStyle;
  final TextStyle? labelStyle;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final labelText = Text(label, style: labelStyle ?? AppTypography.caption2);
    Widget valueText = Text(
      value,
      style: (valueStyle ?? AppTypography.title3)
          .copyWith(color: dim ? AppColors.faint : AppColors.metricColor(label)),
    );

    if (delta != null && delta != 0) {
      final d = delta!;
      valueText = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          valueText,
          const SizedBox(width: 4),
          Text('${d > 0 ? '↑' : '↓'}${d.abs()}',
              style: AppTypography.caption2.copyWith(
                  color: d > 0 ? AppColors.success : AppColors.danger)),
        ],
      );
    }

    if (boxed) {
      return Container(
        width: 150,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [labelText, const SizedBox(height: 4), valueText],
        ),
      );
    }

    return Expanded(
      child: Column(
        children: valueFirst
            ? [valueText, if (gap > 0) SizedBox(height: gap), labelText]
            : [labelText, SizedBox(height: gap), valueText],
      ),
    );
  }
}
