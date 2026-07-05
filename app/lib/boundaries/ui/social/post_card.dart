import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../controls/social_feed.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../entities/feed_post.dart';
import '../../gateways/workout_gateway.dart';
import '../common/app_card.dart';
import '../common/workout_list_card.dart';
import 'author_row.dart';
import 'post_detail_screen.dart';
import 'user_profile_screen.dart';
import 'share_post_sheet.dart';

/// BOUNDARY widget — one polymorphic feed card (#11). The whole card is the
/// tap target → Post Detail; the action-row buttons intercept their own taps.
class PostCard extends ConsumerWidget {
  const PostCard({super.key, required this.feedPost});

  final FeedPost feedPost;

  void _openDetail(BuildContext context) {
    Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(
        builder: (_) => PostDetailScreen(postId: feedPost.post.id)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final post = feedPost.post;
    final types = ref.watch(workoutTypesProvider).value ?? [];
    // Another user's private custom type is unreadable — fall back gracefully.
    final type = feedPost.session == null
        ? null
        : types.where((t) => t.id == feedPost.session!.workoutTypeId).firstOrNull;

    return GestureDetector(
      onTap: () => _openDetail(context),
      child: AppCard(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
        borderColor: AppColors.faint,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AuthorRow(
              author: feedPost.author,
              when: post.createdAt,
              onTap: () => Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute(
                      builder: (_) =>
                          UserProfileScreen(userId: feedPost.author.id))),
            ),
            if (post.body != null) ...[
              const SizedBox(height: 10),
              Text(post.body!, style: AppTypography.body),
            ],
            const SizedBox(height: 10),
            if (post.isWorkoutShare && feedPost.session != null)
              WorkoutListCard(
                  session: feedPost.session!,
                  type: type,
                  chevron: false,
                  margin: EdgeInsets.zero),
            if (post.isLevelUp) _LevelUpPanel(level: post.level ?? 1),
            if (post.isChallengeResult) const _ChallengeResultPanel(),
            _ActionRow(feedPost: feedPost),
          ],
        ),
      ),
    );
  }
}

class _LevelUpPanel extends StatelessWidget {
  const _LevelUpPanel({required this.level});

  final int level;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Text('⚡', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 10),
          Text('Reached Level $level',
              style: AppTypography.headline.copyWith(color: AppColors.accent)),
        ],
      ),
    );
  }
}

/// challenge_result posts are auto-created at a challenge deadline — that job
/// is deferred, but seeded/manual rows must still render (11-social.md).
class _ChallengeResultPanel extends StatelessWidget {
  const _ChallengeResultPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Text('🏆', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 10),
          Text('Challenge result', style: AppTypography.headline),
        ],
      ),
    );
  }
}

class _ActionRow extends ConsumerWidget {
  const _ActionRow({required this.feedPost});

  final FeedPost feedPost;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liked = feedPost.likedByMe;
    return Row(
      children: [
        IconButton(
          onPressed: () => ref
              .read(togglePostLikeProvider)
              .call(feedPost.post.id, currentlyLiked: liked),
          icon: Icon(liked ? Icons.favorite : Icons.favorite_border,
              color: liked ? AppColors.danger : AppColors.muted, size: 22),
        ),
        Text('${feedPost.likeCount}', style: AppTypography.footnote),
        const SizedBox(width: 16),
        const Icon(Icons.mode_comment_outlined, color: AppColors.muted, size: 20),
        const SizedBox(width: 4),
        Text('${feedPost.commentCount}', style: AppTypography.footnote),
        const Spacer(),
        IconButton(
          onPressed: () => showSharePostSheet(context, feedPost),
          icon: const Icon(Icons.ios_share, color: AppColors.muted, size: 20),
        ),
      ],
    );
  }
}
