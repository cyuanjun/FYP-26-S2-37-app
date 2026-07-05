import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// Gold "go premium" call-to-action — solid [AppColors.premium] fill with ink
/// text, as a pill (default) or full-width banner. Untappable when [onTap] is
/// null (pure info banner).
class PremiumCta extends StatelessWidget {
  const PremiumCta(
    this.text, {
    super.key,
    this.onTap,
    this.icon,
    this.fullWidth = false,
    this.radius = 20,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    this.style,
  });

  final String text;
  final VoidCallback? onTap;

  /// Small leading icon (the Profile pill's star).
  final IconData? icon;

  final bool fullWidth;
  final double radius;
  final EdgeInsetsGeometry padding;

  /// Defaults to footnote · ink · w700.
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final textWidget = Text(
      text,
      style: style ??
          AppTypography.footnote
              .copyWith(color: AppColors.ink, fontWeight: FontWeight.w700),
    );
    final body = Container(
      width: fullWidth ? double.infinity : null,
      padding: padding,
      alignment: fullWidth ? Alignment.center : null,
      decoration: BoxDecoration(
        color: AppColors.premium,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: icon == null
          ? textWidget
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 12, color: AppColors.ink),
                const SizedBox(width: 4),
                textWidget,
              ],
            ),
    );
    return onTap == null ? body : GestureDetector(onTap: onTap, child: body);
  }
}
