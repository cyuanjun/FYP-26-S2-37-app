import 'package:flutter/material.dart';

import '../../../core/theme/app_typography.dart';

// (#) The tiny uppercase caption we sit above an input box. We keep labels
// outside the box so every form field lines up the same way across the app.
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key});

  final String text; // (#) the caption text to show

  // (#) Builds the label: the text in caption2 style with a little gap below it.
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: AppTypography.caption2),
      );
}
