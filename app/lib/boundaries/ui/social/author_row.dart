import 'package:flutter/material.dart';

import '../../../core/format.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../entities/public_profile.dart';

/// BOUNDARY widget — post/comment author strip: initials avatar + name +
/// `@handle · when`. [onTap] links to the user profile (wired in Phase 2).
class AuthorRow extends StatelessWidget {
  const AuthorRow({
    super.key,
    required this.author,
    required this.when,
    this.onTap,
    this.size = 40,
    this.trailing,
  });

  final PublicProfile author;
  final DateTime when;
  final VoidCallback? onTap;
  final double size;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final meta = [
      if (author.handle.isNotEmpty) author.handle,
      relativeDay(when),
    ].join(' · ');

    return Row(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
            ),
            child: Text(author.initials,
                style: TextStyle(
                    color: AppColors.bg,
                    fontWeight: FontWeight.w800,
                    fontSize: size * 0.4)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(author.displayName,
                    style: AppTypography.headline, overflow: TextOverflow.ellipsis),
                Text(meta, style: AppTypography.caption2),
              ],
            ),
          ),
        ),
        ?trailing,
      ],
    );
  }
}
