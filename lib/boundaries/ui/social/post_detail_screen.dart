import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../controls/authenticate.dart';
import '../../../controls/social_interactions.dart';
import '../../../controls/social_feed.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../entities/enums.dart';
import 'user_profile_screen.dart';

/// BOUNDARY (#11.1 Post Detail). Full post body, like strip, and comment thread
/// with reply input. Reached by tapping any post card in the feed (US23).
class PostDetailScreen extends ConsumerStatefulWidget {
  const PostDetailScreen({super.key, required this.postId});

  final String postId;

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final _commentCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    final body = _commentCtrl.text.trim();
    if (body.isEmpty) return;
    setState(() => _submitting = true);
    try {
      await ref.read(addPostCommentProvider).call(widget.postId, body);
      _commentCtrl.clear();
      ref.invalidate(postCommentsProvider(widget.postId));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final postAsync = ref.watch(postDetailProvider(widget.postId));
    final commentsAsync = ref.watch(postCommentsProvider(widget.postId));
    final feedAsync = ref.watch(feedProvider);
    final currentUserId = ref.watch(currentUserIdProvider);

    // Pull like/comment counts from the feed if available.
    final feedPost = feedAsync.value
        ?.where((p) => p.id == widget.postId)
        .firstOrNull;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        title: const Text('Post', style: AppTypography.title1),
        leading: const BackButton(color: AppColors.ink),
        actions: [
          if (feedPost != null && feedPost.author.id == currentUserId)
            PopupMenuButton<String>(
              color: AppColors.surface,
              icon: const Icon(Icons.more_vert, color: AppColors.ink),
              onSelected: (v) {
                if (v == 'edit') _showEditCaption(context, feedPost.body);
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit caption')),
              ],
            ),
        ],
      ),
      body: postAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.accent)),
        error: (e, _) => Center(
            child: Text('Could not load post: $e',
                style: AppTypography.subheadline)),
        data: (raw) {
          final authorMap = raw['author'] as Map<String, dynamic>? ?? {};
          final first = authorMap['first_name'] as String? ?? '';
          final last = authorMap['last_name'] as String? ?? '';
          final authorName = '$first $last'.trim().isNotEmpty
              ? '$first $last'.trim()
              : (authorMap['username'] as String? ?? 'User');
          final authorId = raw['user_id'] as String;
          final authorAvatar = authorMap['avatar_url'] as String?;
          final body = raw['body'] as String?;
          final kindStr = raw['kind'] as String? ?? 'workout_share';
          final kind = PostKind.values.byName(_camel(kindStr));
          final likeCount = feedPost?.likeCount ?? 0;
          final likedByMe = feedPost?.likedByMe ?? false;
          final commentCount = feedPost?.commentCount ?? 0;

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  children: [
                    // Author row
                    GestureDetector(
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) =>
                              UserProfileScreen(userId: authorId))),
                      child: Row(
                        children: [
                          _Avatar(url: authorAvatar, name: authorName, radius: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(authorName, style: AppTypography.headline),
                                if (authorMap['username'] != null)
                                  Text('@${authorMap['username']}',
                                      style: AppTypography.caption1),
                              ],
                            ),
                          ),
                          Text(
                            _relativeTime(
                                DateTime.parse(raw['created_at'] as String)),
                            style: AppTypography.caption1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Caption
                    if (body != null && body.isNotEmpty)
                      Text(body, style: AppTypography.body),
                    if (body != null && body.isNotEmpty)
                      const SizedBox(height: 14),

                    // Payload card
                    _PostPayload(raw: raw, kind: kind),

                    const SizedBox(height: 16),
                    const Divider(color: AppColors.faint, height: 1),

                    // Like / comment strip
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          TextButton.icon(
                            onPressed: () => ref
                                .read(togglePostLikeProvider)
                                .call(widget.postId,
                                    currentlyLiked: likedByMe),
                            icon: Icon(
                              likedByMe
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color:
                                  likedByMe ? AppColors.danger : AppColors.muted,
                              size: 18,
                            ),
                            label: Text('$likeCount',
                                style: AppTypography.footnote.copyWith(
                                    color: likedByMe
                                        ? AppColors.danger
                                        : AppColors.muted)),
                          ),
                          TextButton.icon(
                            onPressed: null,
                            icon: const Icon(Icons.chat_bubble_outline,
                                color: AppColors.muted, size: 18),
                            label: Text('$commentCount',
                                style: AppTypography.footnote),
                          ),
                        ],
                      ),
                    ),

                    const Divider(color: AppColors.faint, height: 1),
                    const SizedBox(height: 12),

                    // Comments
                    Text('Comments', style: AppTypography.headline),
                    const SizedBox(height: 8),
                    commentsAsync.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                            child: CircularProgressIndicator(
                                color: AppColors.accent)),
                      ),
                      error: (e, _) =>
                          Text('Failed to load comments: $e',
                              style: AppTypography.footnote
                                  .copyWith(color: AppColors.danger)),
                      data: (comments) {
                        if (comments.isEmpty) {
                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(vertical: 16),
                            child: Text('No comments yet. Be the first!',
                                style: AppTypography.subheadline,
                                textAlign: TextAlign.center),
                          );
                        }
                        return Column(
                          children: comments
                              .map((c) => _CommentRow(
                                    comment: c,
                                    currentUserId: currentUserId,
                                    onDelete: () async {
                                      await ref
                                          .read(deletePostCommentProvider)
                                          .call(c['id'] as String);
                                      ref.invalidate(
                                          postCommentsProvider(widget.postId));
                                    },
                                  ))
                              .toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Reply input
              const Divider(color: AppColors.faint, height: 1),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  MediaQuery.of(context).viewInsets.bottom + 12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentCtrl,
                        decoration: InputDecoration(
                          hintText: 'Add a comment…',
                          hintStyle: AppTypography.subheadline,
                          filled: true,
                          fillColor: AppColors.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                        ),
                        style: AppTypography.body,
                        maxLines: 3,
                        minLines: 1,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _submitComment(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _submitting
                        ? const SizedBox(
                            width: 36,
                            height: 36,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.accent),
                          )
                        : IconButton(
                            icon: const Icon(Icons.send_rounded,
                                color: AppColors.accent),
                            onPressed: _submitComment,
                          ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditCaption(BuildContext context, String? current) {
    final ctrl = TextEditingController(text: current ?? '');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Edit Caption', style: AppTypography.title2),
            const SizedBox(height: 14),
            TextField(
              controller: ctrl,
              maxLines: 4,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'Caption…'),
              style: AppTypography.body,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await ref
                      .read(updatePostBodyProvider)
                      .call(widget.postId, ctrl.text.trim());
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('SAVE'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _camel(String snake) {
    final parts = snake.split('_');
    return parts.first +
        parts.skip(1).map((p) => p[0].toUpperCase() + p.substring(1)).join();
  }

  static String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

// ── Post payload (workout / challenge / level-up) ─────────────────────────────

class _PostPayload extends StatelessWidget {
  const _PostPayload({required this.raw, required this.kind});

  final Map<String, dynamic> raw;
  final PostKind kind;

  @override
  Widget build(BuildContext context) {
    return switch (kind) {
      PostKind.workoutShare => _WorkoutCard(raw: raw),
      PostKind.challengeResult => _ChallengeResultCard(raw: raw),
      PostKind.levelUp => _LevelUpCard(raw: raw),
    };
  }
}

class _WorkoutCard extends StatelessWidget {
  const _WorkoutCard({required this.raw});

  final Map<String, dynamic> raw;

  @override
  Widget build(BuildContext context) {
    final session = raw['session'] as Map<String, dynamic>?;
    if (session == null) return const SizedBox.shrink();
    final typeMap = session['type'] as Map<String, dynamic>?;
    final name = session['custom_name'] as String? ??
        typeMap?['name'] as String? ??
        'Workout';
    final durSecs = session['duration_seconds'] as int? ?? 0;
    final dist = session['distance_meters'] as int?;
    final cal = session['calories_burned'] as int?;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.faint),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: AppTypography.headline),
          const SizedBox(height: 10),
          Wrap(
            spacing: 20,
            runSpacing: 8,
            children: [
              _Stat(
                  label: 'DURATION',
                  value: _formatDuration(durSecs)),
              if (dist != null)
                _Stat(
                    label: 'DISTANCE',
                    value:
                        '${(dist / 1000).toStringAsFixed(2)} km'),
              if (cal != null)
                _Stat(label: 'CALORIES', value: '$cal kcal'),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatDuration(int secs) {
    final m = secs ~/ 60;
    final s = secs % 60;
    if (m >= 60) return '${m ~/ 60}h ${m % 60}m';
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

class _ChallengeResultCard extends StatelessWidget {
  const _ChallengeResultCard({required this.raw});

  final Map<String, dynamic> raw;

  @override
  Widget build(BuildContext context) {
    final challenge = raw['challenge'] as Map<String, dynamic>?;
    final name = challenge?['name'] as String? ?? 'Challenge';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.emoji_events_outlined,
              color: AppColors.accent, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Challenge completed!',
                    style: AppTypography.headline
                        .copyWith(color: AppColors.accent)),
                const SizedBox(height: 4),
                Text(name, style: AppTypography.subheadline),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelUpCard extends StatelessWidget {
  const _LevelUpCard({required this.raw});

  final Map<String, dynamic> raw;

  @override
  Widget build(BuildContext context) {
    final level = raw['level'] as int?;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Text('🏆', style: TextStyle(fontSize: 32)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Level ${level ?? '?'} reached!',
                  style:
                      AppTypography.headline.copyWith(color: AppColors.gold)),
              const SizedBox(height: 4),
              const Text('Keep crushing it!',
                  style: AppTypography.subheadline),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.caption2),
        const SizedBox(height: 2),
        Text(value,
            style: AppTypography.title3.copyWith(color: AppColors.accent)),
      ],
    );
  }
}

// ── Comment row ───────────────────────────────────────────────────────────────

class _CommentRow extends StatelessWidget {
  const _CommentRow({
    required this.comment,
    required this.currentUserId,
    required this.onDelete,
  });

  final Map<String, dynamic> comment;
  final String? currentUserId;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final profile = comment['profile'] as Map<String, dynamic>? ?? {};
    final first = profile['first_name'] as String? ?? '';
    final last = profile['last_name'] as String? ?? '';
    final name = '$first $last'.trim().isNotEmpty
        ? '$first $last'.trim()
        : (profile['username'] as String? ?? 'User');
    final avatarUrl = profile['avatar_url'] as String?;
    final body = comment['body'] as String? ?? '';
    final commentUserId = comment['user_id'] as String?;
    final isOwn = currentUserId != null && commentUserId == currentUserId;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Avatar(url: avatarUrl, name: name, radius: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: AppTypography.footnote
                        .copyWith(fontWeight: FontWeight.w600, color: AppColors.ink)),
                const SizedBox(height: 2),
                Text(body, style: AppTypography.body),
              ],
            ),
          ),
          if (isOwn)
            GestureDetector(
              onTap: () => showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  backgroundColor: AppColors.surface,
                  title:
                      const Text('Delete comment?', style: AppTypography.headline),
                  content: const Text(
                      'This will permanently remove your comment.',
                      style: AppTypography.subheadline),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel')),
                    TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          onDelete();
                        },
                        child: const Text('Delete',
                            style: TextStyle(color: AppColors.danger))),
                  ],
                ),
              ),
              child: const Icon(Icons.close, size: 16, color: AppColors.muted),
            ),
        ],
      ),
    );
  }
}

// ── Avatar ────────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  const _Avatar({required this.url, required this.name, required this.radius});

  final String? url;
  final String name;
  final double radius;

  @override
  Widget build(BuildContext context) {
    if (url != null && url!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(url!),
        backgroundColor: AppColors.surface2,
      );
    }
    final init = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.surface2,
      child: Text(init,
          style: AppTypography.caption1
              .copyWith(color: AppColors.ink, fontWeight: FontWeight.w600)),
    );
  }
}
