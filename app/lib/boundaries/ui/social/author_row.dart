import 'package:flutter/material.dart';

import '../../../core/format.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../entities/public_profile.dart';

// (#) Small strip that shows who wrote a post or comment: avatar, name and
// (#) @handle plus a timestamp. Tapping it opens their profile. Pure display,
// (#) it holds no data of its own.
class AuthorRow extends StatelessWidget {
  const AuthorRow({
    super.key,
    required this.author,
    required this.when,
    this.onTap,
    this.size = 40,
    this.trailing,
  });

  final PublicProfile author; // (#) the person who made the post or comment
  final DateTime when; // (#) when it was posted, shown as a relative day
  final VoidCallback? onTap; // (#) what to run when the row is tapped, usually open profile
  final double size; // (#) avatar diameter in pixels
  final Widget? trailing; // (#) optional extra widget pinned to the right

  // (#) Builds the avatar, name and the "handle · when" meta line in a row.
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
