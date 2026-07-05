import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../controls/authenticate.dart';
import '../../../controls/social_feed.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../entities/feed_post.dart';
import '../../../entities/post_comment.dart';
import '../../gateways/workout_gateway.dart';
import '../common/app_card.dart';
import '../common/workout_list_card.dart';
import '../workout/history_detail_screen.dart';
import 'author_row.dart';
import 'share_post_sheet.dart';

/// BOUNDARY (#11.1 Post Detail). A single polymorphic post in full: wrapped
/// content, like toggle, flat comment thread (oldest first) and a pinned
/// reply input. The owner gets an inline caption editor.
class PostDetailScreen extends ConsumerStatefulWidget {
  const PostDetailScreen({super.key, required this.postId});

  final String postId;

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final _reply = TextEditingController();
  final _caption = TextEditingController();
  bool _editingCaption = false;
  bool _sending = false;

  @override
  void dispose() {
    _reply.dispose();
    _caption.dispose();
    super.dispose();
  }

  Future<void> _sendReply() async {
    if (_reply.text.trim().isEmpty || _sending) return;
    setState(() => _sending = true);
    final ok = await ref
        .read(addPostCommentProvider)
        .call(postId: widget.postId, body: _reply.text);
    if (!mounted) return;
    if (ok) _reply.clear();
    setState(() => _sending = false);
  }

  Future<void> _saveCaption() async {
    await ref
        .read(updatePostBodyProvider)
        .call(postId: widget.postId, body: _caption.text);
    if (mounted) setState(() => _editingCaption = false);
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(currentUserIdProvider);
    final postAsync = ref.watch(postDetailProvider(widget.postId));
    final commentsAsync = ref.watch(postCommentsProvider(widget.postId));

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('POST', style: AppTypography.caption2)),
      bottomNavigationBar: _replyBar(),
      body: postAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
            child: Text('Could not load post.', style: AppTypography.subheadline)),
        data: (feedPost) {
          if (feedPost == null) {
            return Center(
                child: Text('Post not found.', style: AppTypography.subheadline));
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              _postCard(feedPost, isOwner: feedPost.post.userId == me),
              const SizedBox(height: 16),
              Text('COMMENTS', style: AppTypography.caption2),
              const SizedBox(height: 8),
              commentsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Text('Could not load comments.',
                    style: AppTypography.footnote),
                data: (comments) => comments.isEmpty
                    ? Text('No comments yet — be the first.',
                        style: AppTypography.subheadline)
                    : Column(
                        children: [
                          for (final c in comments) _commentCard(c, me: me),
                        ],
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _postCard(FeedPost feedPost, {required bool isOwner}) {
    final post = feedPost.post;
    final types = ref.watch(workoutTypesProvider).value ?? [];
    final type = feedPost.session == null
        ? null
        : types.where((t) => t.id == feedPost.session!.workoutTypeId).firstOrNull;
    final liked = feedPost.likedByMe;

    return AppCard(
      borderColor: AppColors.faint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AuthorRow(
            author: feedPost.author,
            when: post.createdAt,
            trailing: isOwner && !_editingCaption
                ? IconButton(
                    icon: const Icon(Icons.edit_outlined,
                        size: 20, color: AppColors.muted),
                    onPressed: () {
                      _caption.text = post.body ?? '';
                      setState(() => _editingCaption = true);
                    },
                  )
                : null,
          ),
          if (_editingCaption) ...[
            const SizedBox(height: 10),
            TextField(
              controller: _caption,
              maxLines: 2,
              decoration: const InputDecoration(hintText: 'Caption (public)'),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                    onPressed: () => setState(() => _editingCaption = false),
                    child: const Text('Cancel')),
                TextButton(onPressed: _saveCaption, child: const Text('Save')),
              ],
            ),
          ] else if (post.body != null) ...[
            const SizedBox(height: 10),
            Text(post.body!, style: AppTypography.body),
          ],
          const SizedBox(height: 10),
          if (post.isWorkoutShare && feedPost.session != null)
            WorkoutListCard(
              session: feedPost.session!,
              type: type,
              chevron: isOwner,
              margin: EdgeInsets.zero,
              // Session detail (#12.1) reads own history only — and another
              // user's notes are private — so only the owner taps through.
              onTap: isOwner
                  ? () => Navigator.of(context, rootNavigator: true).push(
                        MaterialPageRoute(
                            builder: (_) => HistoryDetailScreen(
                                sessionId: feedPost.session!.id)),
                      )
                  : null,
            ),
          if (post.isLevelUp)
            Text('⚡ Reached Level ${post.level}',
                style: AppTypography.title3.copyWith(color: AppColors.accent)),
          const SizedBox(height: 4),
          Row(
            children: [
              IconButton(
                onPressed: () => ref
                    .read(togglePostLikeProvider)
                    .call(post.id, currentlyLiked: liked),
                icon: Icon(liked ? Icons.favorite : Icons.favorite_border,
                    color: liked ? AppColors.danger : AppColors.muted),
              ),
              Text('${feedPost.likeCount} likes', style: AppTypography.footnote),
              const Spacer(),
              IconButton(
                onPressed: () => showSharePostSheet(context, feedPost),
                icon: const Icon(Icons.ios_share, color: AppColors.muted, size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _commentCard(PostComment c, {required String? me}) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      shadow: false,
      borderColor: AppColors.faint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (c.author != null)
            AuthorRow(
              author: c.author!,
              when: c.createdAt,
              size: 32,
              trailing: c.userId == me
                  ? IconButton(
                      icon: const Icon(Icons.close, size: 18, color: AppColors.muted),
                      onPressed: () => ref
                          .read(deletePostCommentProvider)
                          .call(postId: widget.postId, commentId: c.id),
                    )
                  : null,
            ),
          const SizedBox(height: 6),
          Text(c.body, style: AppTypography.body),
        ],
      ),
    );
  }

  Widget _replyBar() {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 8,
          bottom: 8 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _reply,
                onSubmitted: (_) => _sendReply(),
                decoration: const InputDecoration(hintText: 'Add a comment…'),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: _sending ? null : _sendReply,
              child: const Text('Post'),
            ),
          ],
        ),
      ),
    );
  }
}
