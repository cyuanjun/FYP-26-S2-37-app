import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// The house single-select pill row (accent fill when selected, hairline
/// otherwise) — used for ranges, billing models, workout types, feel
/// ratings, listing status. [onTap] receives the tapped value; the caller
/// decides toggling/deselection semantics.
class SelectorPills<T> extends StatelessWidget {
  const SelectorPills({
    super.key,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onTap,
  });

  final List<T> values;
  final T? selected;
  final String Function(T) labelOf;
  final void Function(T) onTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final v in values)
          GestureDetector(
            onTap: () => onTap(v),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: v == selected ? AppColors.accent : AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                    color:
                        v == selected ? AppColors.accent : AppColors.faint),
              ),
              child: Text(labelOf(v),
                  style: AppTypography.footnote.copyWith(
                      color: v == selected ? AppColors.bg : AppColors.ink,
                      fontWeight: FontWeight.w700)),
            ),
          ),
      ],
    );
  }
}
