import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../controls/authenticate.dart';
import '../../../controls/follow_user.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../entities/enums.dart';
import 'post_detail_screen.dart';

/// BOUNDARY (#11.2 User Profile). Public view of another user's identity,
/// stats, and recent posts. Friend / Unfriend toggle inline (US24).
class UserProfileScreen extends ConsumerWidget {
  const UserProfileScreen({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider(userId));
    final workoutCountAsync = ref.watch(userWorkoutCountProvider(userId));
    final activeDaysAsync = ref.watch(userActiveDaysProvider(userId));
    final friendCountAsync = ref.watch(userFriendCountProvider(userId));
    final postsAsync = ref.watch(userPostsProvider(userId));
    final currentUserId = ref.watch(currentUserIdProvider);
    final isOwnProfile = currentUserId == userId;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        leading: const BackButton(color: AppColors.ink),
        title: profileAsync.when(
          data: (u) => Text('@${u.handle ?? u.displayName}',
              style: AppTypography.headline),
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.accent,
        backgroundColor: AppColors.surface,
        onRefresh: () async {
          ref.invalidate(userProfileProvider(userId));
          ref.invalidate(userWorkoutCountProvider(userId));
          ref.invalidate(userActiveDaysProvider(userId));
          ref.invalidate(userFriendCountProvider(userId));
          ref.invalidate(userPostsProvider(userId));
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          children: [
            const SizedBox(height: 20),

            // ── Identity block ───────────────────────────────────────────────
            profileAsync.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.accent)),
              error: (e, _) => Center(
                  child: Text('Failed to load profile: $e',
                      style: AppTypography.subheadline)),
              data: (user) => Column(
                children: [
                  // Avatar
                  _Avatar(
                      url: user.avatarUrl,
                      name: user.displayName,
                      radius: 40),
                  const SizedBox(height: 12),
                  Text(user.displayName, style: AppTypography.title2),
                  if (user.handle != null) ...[
                    const SizedBox(height: 4),
                    Text('@${user.handle}', style: AppTypography.subheadline),
                  ],
                  if (user.bio != null && user.bio!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      user.bio!,
                      style: AppTypography.subheadline,
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Friend toggle (not shown on own profile)
                  if (!isOwnProfile)
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: user.isFriend
                          ? OutlinedButton.icon(
                              key: const ValueKey('unfriend'),
                              onPressed: () => _confirmUnfriend(
                                  context, ref, userId, user.displayName),
                              icon: const Icon(Icons.person_remove_outlined,
                                  size: 18),
                              label: const Text('Unfriend'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.muted,
                                side:
                                    const BorderSide(color: AppColors.faint),
                              ),
                            )
                          : ElevatedButton.icon(
                              key: const ValueKey('add'),
                              onPressed: () =>
                                  ref.read(followUserProvider).call(userId),
                              icon: const Icon(Icons.person_add_outlined,
                                  size: 18),
                              label: const Text('Add Friend'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accent,
                                foregroundColor: AppColors.bg,
                              ),
                            ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Stats tile ───────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatPill(
                    label: 'WORKOUTS',
                    value: workoutCountAsync.when(
                        data: (n) => '$n',
                        loading: () => '—',
                        error: (_, _) => '—'),
                  ),
                  Container(
                      width: 1, height: 36, color: AppColors.faint),
                  _StatPill(
                    label: 'ACTIVE DAYS',
                    value: activeDaysAsync.when(
                        data: (n) => '$n',
                        loading: () => '—',
                        error: (_, _) => '—'),
                  ),
                  Container(
                      width: 1, height: 36, color: AppColors.faint),
                  _StatPill(
                    label: 'FRIENDS',
                    value: friendCountAsync.when(
                        data: (n) => '$n',
                        loading: () => '—',
                        error: (_, _) => '—'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── Recent posts ─────────────────────────────────────────────────
            Text('Recent Posts', style: AppTypography.headline),
            const SizedBox(height: 12),
            postsAsync.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.accent)),
              error: (e, _) => Text('Could not load posts: $e',
                  style: AppTypography.subheadline),
              data: (posts) {
                if (posts.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text('No posts yet.',
                          style: AppTypography.subheadline),
                    ),
                  );
                }
                return Column(
                  children: posts
                      .map((raw) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _MiniPostCard(raw: raw),
                          ))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmUnfriend(
      BuildContext context, WidgetRef ref, String id, String name) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Unfriend $name?', style: AppTypography.headline),
        content: const Text(
            'You will no longer see each other\'s posts in your feed.',
            style: AppTypography.subheadline),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () {
                Navigator.pop(context);
                ref.read(unfollowUserProvider).call(id);
              },
              child: const Text('Unfriend',
                  style: TextStyle(color: AppColors.danger))),
        ],
      ),
    );
  }
}

// ── Mini post card (recent posts list) ───────────────────────────────────────

class _MiniPostCard extends StatelessWidget {
  const _MiniPostCard({required this.raw});

  final Map<String, dynamic> raw;

  @override
  Widget build(BuildContext context) {
    final kindStr = raw['kind'] as String? ?? 'workout_share';
    final kind = PostKind.values.byName(_camel(kindStr));
    final body = raw['body'] as String?;
    final sessionMap = raw['session'] as Map<String, dynamic>?;
    final typeMap = sessionMap?['type'] as Map<String, dynamic>?;
    final postName = sessionMap?['custom_name'] as String? ??
        typeMap?['name'] as String? ??
        _kindLabel(kind);

    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => PostDetailScreen(postId: raw['id'] as String))),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _kindColor(kind).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_kindIcon(kind),
                  color: _kindColor(kind), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(postName,
                      style: AppTypography.subheadline
                          .copyWith(color: AppColors.ink),
                      overflow: TextOverflow.ellipsis),
                  if (body != null && body.isNotEmpty)
                    Text(body,
                        style: AppTypography.footnote,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Text(
              _relativeTime(DateTime.parse(raw['created_at'] as String)),
              style: AppTypography.caption1,
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

  static String _kindLabel(PostKind k) => switch (k) {
        PostKind.workoutShare => 'Workout',
        PostKind.challengeResult => 'Challenge',
        PostKind.levelUp => 'Level Up',
      };

  static IconData _kindIcon(PostKind k) => switch (k) {
        PostKind.workoutShare => Icons.fitness_center_outlined,
        PostKind.challengeResult => Icons.emoji_events_outlined,
        PostKind.levelUp => Icons.trending_up_outlined,
      };

  static Color _kindColor(PostKind k) => switch (k) {
        PostKind.workoutShare => AppColors.accent,
        PostKind.challengeResult => AppColors.gold,
        PostKind.levelUp => AppColors.info,
      };

  static String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 6) return '${dt.day}/${dt.month}';
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    return '${diff.inMinutes}m';
  }
}

// ── Stat pill ─────────────────────────────────────────────────────────────────

class _StatPill extends StatelessWidget {
  const _StatPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: AppTypography.title2.copyWith(color: AppColors.accent)),
        const SizedBox(height: 4),
        Text(label, style: AppTypography.caption2),
      ],
    );
  }
}

// ── Avatar ────────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  const _Avatar(
      {required this.url, required this.name, required this.radius});

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
          style: AppTypography.title3
              .copyWith(color: AppColors.ink)),
    );
  }
}
