import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

// (#) The gold "go Premium" button or banner used to nudge people to upgrade.
// Draws as a pill by default or a full-width bar. Leave onTap null and it's just
// an info banner you can't tap.
class PremiumCta extends StatelessWidget {
  const PremiumCta(
    this.text, { // (#) the label shown on the pill or banner
    super.key,
    this.onTap, // (#) what to do on tap, null makes it a plain banner
    this.icon, // (#) optional small leading icon, like the star
    this.fullWidth = false, // (#) stretch to fill the row as a bar
    this.radius = 20, // (#) corner roundness
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 10), // (#) inner spacing
    this.style, // (#) override the text style, defaults to footnote ink bold
  });

  final String text;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool fullWidth;
  final double radius;
  final EdgeInsetsGeometry padding;
  final TextStyle? style;

  // (#) Builds the CTA: gold rounded box holding the text (and icon if given),
  // wrapped in a tap handler only when onTap was provided.
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
