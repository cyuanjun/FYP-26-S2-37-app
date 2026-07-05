import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../controls/share_workout.dart';
import '../../../core/format.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../entities/enums.dart';
import '../../../entities/feed_post.dart';

/// Share-post sheet (#11) — the four named platforms (a grading requirement),
/// reusing the same ShareWorkoutToSocial control as the workout summary.
void showSharePostSheet(BuildContext context, FeedPost feedPost) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    showDragHandle: true,
    builder: (_) => _SharePostSheet(feedPost: feedPost),
  );
}

class _SharePostSheet extends ConsumerWidget {
  const _SharePostSheet({required this.feedPost});

  final FeedPost feedPost;

  String _shareText() {
    final author = feedPost.author.displayName;
    final session = feedPost.session;
    if (feedPost.post.isLevelUp) {
      return '$author just reached Level ${feedPost.post.level} on Wise Workout!';
    }
    if (session != null) {
      final dur = fmtDuration(Duration(seconds: session.durationSeconds));
      final dist = session.distanceMeters;
      return dist != null && dist > 0
          ? '$author logged ${fmtKm(dist.toDouble())} km in $dur on Wise Workout!'
          : '$author logged a $dur workout on Wise Workout!';
    }
    return feedPost.post.body ?? 'Shared from Wise Workout';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SHARE TO', style: AppTypography.caption2),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: SocialPlatform.values
                  .map((p) => OutlinedButton(
                        onPressed: () {
                          ref
                              .read(shareWorkoutToSocialProvider)
                              .call(p, text: _shareText());
                          Navigator.of(context).pop();
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.accent,
                          side: const BorderSide(color: AppColors.accent),
                        ),
                        child: Text(p.label),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
