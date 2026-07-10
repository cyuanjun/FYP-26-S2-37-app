import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

// (#) The little "label + number" block behind every stats row in the app. It
// colours the value based on its label, so the same metric always shows up in
// the same colour wherever it appears (history, profile, live capture, summary).
class StatTile extends StatelessWidget {
  const StatTile(
    this.label, // (#) the metric name, also drives the value colour
    this.value, { // (#) the number or text to show big
    super.key,
    this.delta, // (#) change vs last period, draws an up/down arrow
    this.dim = false, // (#) fade the value out, used when capture is paused
    this.valueFirst = false, // (#) put the value above the label instead of below
    this.boxed = false, // (#) fixed width tile on its own little card
    this.valueStyle, // (#) override the value text style
    this.labelStyle, // (#) override the label text style
    this.gap = 2, // (#) space between label and value
  });

  final String label;
  final String value;
  final int? delta;
  final bool dim;
  final bool valueFirst;
  final bool boxed;
  final TextStyle? valueStyle;
  final TextStyle? labelStyle;
  final double gap;

  // (#) Builds the tile: the label and coloured value, an optional delta arrow,
  // and either the boxed card layout or the expanding column.
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
