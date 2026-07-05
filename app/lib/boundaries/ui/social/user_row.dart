import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../controls/manage_friends.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../entities/public_profile.dart';
import 'user_profile_screen.dart';

/// BOUNDARY widget — one user in search results / friends list: identity +
/// the action-first **Add Friend / Unfriend** toggle (the label says what
/// tapping does — project convention).
class UserRow extends ConsumerWidget {
  const UserRow({super.key, required this.user});

  final PublicProfile user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFriend = ref.watch(isFriendProvider(user.id)).value ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute(
                      builder: (_) => UserProfileScreen(userId: user.id))),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                        color: AppColors.accent, shape: BoxShape.circle),
                    child: Text(user.initials,
                        style: const TextStyle(
                            color: AppColors.bg,
                            fontWeight: FontWeight.w800,
                            fontSize: 16)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.displayName,
                            style: AppTypography.headline,
                            overflow: TextOverflow.ellipsis),
                        if (user.handle.isNotEmpty)
                          Text(user.handle, style: AppTypography.caption2),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () => isFriend
                ? ref.read(unfollowUserProvider).call(user.id)
                : ref.read(followUserProvider).call(user.id),
            style: OutlinedButton.styleFrom(
              foregroundColor: isFriend ? AppColors.muted : AppColors.accent,
              side: BorderSide(
                  color: isFriend ? AppColors.faint : AppColors.accent),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              visualDensity: VisualDensity.compact,
            ),
            child: Text(isFriend ? 'Unfriend' : 'Add Friend'),
          ),
        ],
      ),
    );
  }
}
