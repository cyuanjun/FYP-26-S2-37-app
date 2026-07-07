import 'package:flutter/material.dart';

import '../../../core/theme/app_typography.dart';

/// The house form-field caption: uppercase caption2 OUTSIDE the input box
/// (project convention — boxes hold hints only, never their own labels).
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: AppTypography.caption2),
      );
}
