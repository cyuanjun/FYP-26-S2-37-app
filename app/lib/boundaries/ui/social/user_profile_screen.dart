import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../controls/authenticate.dart';
import '../../../controls/manage_friends.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../entities/public_profile.dart';
import '../common/app_card.dart';
import '../common/stat_tile.dart';
import 'post_detail_screen.dart';

/// BOUNDARY (#11.2 User Profile). Public profile for any user: identity from
/// `public_profiles`, Workouts / Friends / Active-days stats (mutual graph —
/// deliberately not followers/following), the Add Friend / Unfriend toggle
/// (hidden on the self-view), and a compact recent-posts index.
class UserProfileScreen extends ConsumerWidget {
  const UserProfileScreen({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(currentUserIdProvider);
    final profileAsync = ref.watch(publicProfileProvider(userId));
    final isSelf = me == userId;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: profileAsync.value?.handle.isNotEmpty ?? false
            ? Text(profileAsync.value!.handle, style: AppTypography.caption2)
            : const Text('PROFILE', style: AppTypography.caption2),
        centerTitle: true,
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
            child:
                Text('Could not load profile.', style: AppTypography.subheadline)),
        data: (profile) {
          if (profile == null) {
            return Center(
                child: Text('User not found.', style: AppTypography.subheadline));
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              _identity(profile),
              const SizedBox(height: 16),
              _statsCard(ref),
              const SizedBox(height: 16),
              if (!isSelf) _friendToggle(ref),
              if (profile.bio != null && profile.bio!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('ABOUT', style: AppTypography.caption2),
                const SizedBox(height: 8),
                AppCard(
                    borderColor: AppColors.faint,
                    shadow: false,
                    child: Text(profile.bio!, style: AppTypography.body)),
              ],
              const SizedBox(height: 20),
              Text('RECENT POSTS', style: AppTypography.caption2),
              const SizedBox(height: 8),
              _recentPosts(ref, isSelf: isSelf),
            ],
          );
        },
      ),
    );
  }

  Widget _identity(PublicProfile profile) {
    return Column(
      children: [
        Container(
          width: 96,
          height: 96,
          alignment: Alignment.center,
          decoration:
              const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
          child: Text(profile.initials,
              style: const TextStyle(
                  color: AppColors.bg, fontWeight: FontWeight.w800, fontSize: 34)),
        ),
        const SizedBox(height: 10),
        Text(profile.displayName, style: AppTypography.title2),
        const SizedBox(height: 2),
        Text('Level ${profile.level} · 🔥 ${profile.currentStreak}w streak',
            style: AppTypography.caption2),
      ],
    );
  }

  Widget _statsCard(WidgetRef ref) {
    final stats = ref.watch(userProfileStatsProvider(userId)).value;
    return AppCard(
      child: Row(
        children: [
          StatTile('WORKOUTS', '${stats?.workouts ?? '—'}', valueFirst: true),
          StatTile('FRIENDS', '${stats?.friends ?? '—'}', valueFirst: true),
          StatTile('ACTIVE DAYS', '${stats?.activeDays ?? '—'}', valueFirst: true),
        ],
      ),
    );
  }

  Widget _friendToggle(WidgetRef ref) {
    final isFriend = ref.watch(isFriendProvider(userId)).value ?? false;
    return OutlinedButton(
      onPressed: () => isFriend
          ? ref.read(unfollowUserProvider).call(userId)
          : ref.read(followUserProvider).call(userId),
      style: OutlinedButton.styleFrom(
        foregroundColor: isFriend ? AppColors.muted : AppColors.accent,
        side: BorderSide(color: isFriend ? AppColors.faint : AppColors.accent),
        minimumSize: const Size.fromHeight(48),
      ),
      child: Text(isFriend ? 'Unfriend' : 'Add Friend'),
    );
  }

  Widget _recentPosts(WidgetRef ref, {required bool isSelf}) {
    final posts = ref.watch(userPostsProvider(userId));
    return posts.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) =>
          Text('Could not load posts.', style: AppTypography.footnote),
      data: (list) {
        if (list.isEmpty) {
          return Text(
              isSelf
                  ? 'Nothing shared yet — share a workout from a session summary.'
                  : 'Nothing shared yet.',
              style: AppTypography.subheadline);
        }
        return Column(
          children: [
            for (final p in list)
              Builder(builder: (context) {
                final label = switch (true) {
                  _ when p.post.isLevelUp => '⚡ Reached Level ${p.post.level}',
                  _ when p.post.isChallengeResult => '🏆 Challenge result',
                  _ => p.post.body ??
                      (p.session?.customName ?? 'Shared a workout'),
                };
                return AppCard(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  shadow: false,
                  borderColor: AppColors.faint,
                  child: InkWell(
                    onTap: () => Navigator.of(context, rootNavigator: true).push(
                        MaterialPageRoute(
                            builder: (_) =>
                                PostDetailScreen(postId: p.post.id))),
                    child: Row(
                      children: [
                        Expanded(
                            child: Text(label,
                                style: AppTypography.body,
                                overflow: TextOverflow.ellipsis)),
                        Text('❤ ${p.likeCount} · 💬 ${p.commentCount}',
                            style: AppTypography.caption2),
                        const Icon(Icons.chevron_right,
                            color: AppColors.faint, size: 18),
                      ],
                    ),
                  ),
                );
              }),
          ],
        );
      },
    );
  }
}
