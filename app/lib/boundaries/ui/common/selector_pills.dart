import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

// (#) A row of pills where one is picked at a time. Used for ranges, workout
// types, feel ratings and the like. It just reports which pill got tapped and
// leaves the caller to decide what selecting actually means.
class SelectorPills<T> extends StatelessWidget {
  const SelectorPills({
    super.key,
    required this.values, // (#) the options to show, one pill each
    required this.selected, // (#) which value is currently picked, if any
    required this.labelOf, // (#) turns a value into its display text
    required this.onTap, // (#) called with the value the user tapped
  });

  final List<T> values;
  final T? selected;
  final String Function(T) labelOf;
  final void Function(T) onTap;

  // (#) Builds the wrap of pills, filling the selected one in accent and
  // outlining the rest, each firing onTap when pressed.
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
