import 'package:flutter/material.dart';

import '../../../core/theme/app_typography.dart';

/// Matched 44px single-line action pair for expert cards — same height/
/// radius/type for the filled and outlined halves.
final ButtonStyle expertCompactFilled = ElevatedButton.styleFrom(
  minimumSize: const Size(0, 44),
  padding: const EdgeInsets.symmetric(horizontal: 12),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  textStyle: AppTypography.footnote.copyWith(fontWeight: FontWeight.w700),
);

ButtonStyle expertCompactOutlined(Color color) => OutlinedButton.styleFrom(
      foregroundColor: color,
      side: BorderSide(color: color),
      minimumSize: const Size(0, 44),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: AppTypography.footnote.copyWith(fontWeight: FontWeight.w700),
    );
