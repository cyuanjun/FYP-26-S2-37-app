import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../controls/manage_friends.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import 'user_row.dart';

// (#) Opens the bottom sheet listing everyone you're friends with. Each row links
// (#) to a profile and carries the Unfriend toggle. It just watches the friends
// (#) list coming from a control.
void showFriendsSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    showDragHandle: true,
    builder: (_) => Consumer(
      builder: (context, ref, _) {
        final friends = ref.watch(friendsProvider);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: friends.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) =>
                  Text('Could not load friends.', style: AppTypography.footnote),
              data: (list) => Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${list.length} FRIENDS', style: AppTypography.caption2),
                  const SizedBox(height: 8),
                  if (list.isEmpty)
                    Text('No friends yet — search above to add some.',
                        style: AppTypography.subheadline)
                  else
                    for (final f in list) UserRow(user: f),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}
