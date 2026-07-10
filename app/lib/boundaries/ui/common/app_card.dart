import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

// (#) The plain rounded card that most things in the app sit on. Wraps its
// child with the house surface colour, rounded corners and a soft shadow so
// every card looks the same. Used all over: train, analytics, goals, settings.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child, // (#) whatever goes inside the card
    this.padding = const EdgeInsets.all(16), // (#) inner spacing around the child
    this.margin, // (#) optional outer spacing around the card
    this.radius = 16, // (#) how round the corners are
    this.borderColor, // (#) hairline or emphasis border colour, none when null
    this.borderWidth = 1, // (#) thickness of that border
    this.shadow = true, // (#) draw the drop shadow or not
    this.width, // (#) fixed width, e.g. infinity to fill the parent
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final Color? borderColor;
  final double borderWidth;
  final bool shadow;
  final double? width;

  // (#) Builds the container: surface fill, rounded corners, optional shadow
  // and border, with the child placed inside.
  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: shadow ? AppColors.cardShadow : null,
        border: borderColor != null
            ? Border.all(color: borderColor!, width: borderWidth)
            : null,
      ),
      child: child,
    );
  }
}
