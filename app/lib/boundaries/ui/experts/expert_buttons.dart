import 'package:flutter/material.dart';

import '../../../core/theme/app_typography.dart';

// (#) Shared style for the filled half of the little action pair on expert cards, fixed 44px tall.
final ButtonStyle expertCompactFilled = ElevatedButton.styleFrom(
  minimumSize: const Size(0, 44),
  padding: const EdgeInsets.symmetric(horizontal: 12),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  textStyle: AppTypography.footnote.copyWith(fontWeight: FontWeight.w700),
);

// (#) Matching outlined half in the colour you pass in, same height and shape as the filled one.
ButtonStyle expertCompactOutlined(Color color) => OutlinedButton.styleFrom(
      foregroundColor: color,
      side: BorderSide(color: color),
      minimumSize: const Size(0, 44),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: AppTypography.footnote.copyWith(fontWeight: FontWeight.w700),
    );
