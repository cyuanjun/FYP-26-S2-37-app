import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../controls/manage_friends.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import 'friends_sheet.dart';

// (#) The search strip at the top of Community: a find-friends box plus a
// (#) friend-count badge that opens the friends sheet. Typing passes the query
// (#) back up to the feed above.
class FindFriendsStrip extends ConsumerWidget {
  const FindFriendsStrip({super.key, required this.onQuery});

  final ValueChanged<String> onQuery; // (#) callback fired as the search text changes

  // (#) Builds the search field beside the tappable friend-count badge.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendCount = ref.watch(friendCountProvider).value ?? 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: onQuery,
              decoration: const InputDecoration(
                hintText: 'Find friends',
                prefixIcon: Icon(Icons.search, size: 20),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => showFriendsSheet(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.faint),
              ),
              child: Row(
                children: [
                  const Text('👥', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 4),
                  Text('$friendCount', style: AppTypography.footnote),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
