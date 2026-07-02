import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../controls/authenticate.dart';
import '../../../controls/challenge_control.dart';
import '../../../controls/follow_user.dart';
import '../../../controls/social_feed.dart';
import '../../../controls/social_interactions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../entities/challenge.dart';
import '../../../entities/enums.dart';
import '../../../boundaries/gateways/social_share_gateway.dart';
import '../../../boundaries/gateways/workout_gateway.dart';
import '../../../entities/workout_type.dart';
import 'challenge_detail_screen.dart';
import 'post_detail_screen.dart';
import 'user_profile_screen.dart';

// ── Main tab ──────────────────────────────────────────────────────────────────

/// BOUNDARY (#11 Social). Community feed + Challenges.
/// US22 — share workouts, US23 — like/comment, US24 — follow/unfollow friends,
/// US25 — join/create challenges, US26 — view public challenge feed.
class SocialTab extends ConsumerStatefulWidget {
  const SocialTab({super.key});

  @override
  ConsumerState<SocialTab> createState() => _SocialTabState();
}

enum _SocialSection { community, challenges }

class _SocialTabState extends ConsumerState<SocialTab> {
  _SocialSection _section = _SocialSection.community;
  final _searchCtrl = TextEditingController();
  bool _searchFocused = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        titleSpacing: 20,
        title: const Text('SOCIAL', style: AppTypography.title1),
        actions: [
          if (_section == _SocialSection.challenges)
            IconButton(
              icon: const Icon(Icons.add_circle_outline,
                  color: AppColors.accent, size: 26),
              tooltip: 'Create challenge',
              onPressed: () => _showCreateChallenge(context),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _SectionPills(
            current: _section,
            onTap: (s) => setState(() => _section = s),
          ),
          const Divider(color: AppColors.faint, height: 1),
          Expanded(
            child: _section == _SocialSection.community
                ? _CommunitySection(
                    searchCtrl: _searchCtrl,
                    onFocusChanged: (v) => setState(() => _searchFocused = v),
                    isFocused: _searchFocused,
                    onFriendsPressed: () => _showFriends(context),
                  )
                : const _ChallengesSection(),
          ),
        ],
      ),
    );
  }

  void _showFriends(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const _FriendsModal(),
    );
  }

  void _showCreateChallenge(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const _CreateChallengeModal(),
    );
  }
}

// ── Section pills ─────────────────────────────────────────────────────────────

class _SectionPills extends StatelessWidget {
  const _SectionPills({required this.current, required this.onTap});

  final _SocialSection current;
  final ValueChanged<_SocialSection> onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: _SocialSection.values
            .map((s) => _pill(s))
            .expand((w) => [w, const SizedBox(width: 8)])
            .toList(),
      ),
    );
  }

  Widget _pill(_SocialSection s) {
    final selected = s == current;
    final label = s == _SocialSection.community ? 'Community' : 'Challenges';
    return GestureDetector(
      onTap: () => onTap(s),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: AppTypography.subheadline.copyWith(
            color: selected ? AppColors.bg : AppColors.ink,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ── Community section ─────────────────────────────────────────────────────────

class _CommunitySection extends ConsumerWidget {
  const _CommunitySection({
    required this.searchCtrl,
    required this.onFocusChanged,
    required this.isFocused,
    required this.onFriendsPressed,
  });

  final TextEditingController searchCtrl;
  final ValueChanged<bool> onFocusChanged;
  final bool isFocused;
  final VoidCallback onFriendsPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendsAsync = ref.watch(friendsProvider);
    final friendCount = friendsAsync.value?.length ?? 0;
    final query = ref.watch(userSearchQueryProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Focus(
                  onFocusChange: onFocusChanged,
                  child: TextField(
                    controller: searchCtrl,
                    onChanged: (v) =>
                        ref.read(userSearchQueryProvider.notifier).set(v),
                    decoration: InputDecoration(
                      hintText: 'Find friends…',
                      hintStyle: AppTypography.subheadline,
                      prefixIcon: const Icon(Icons.search, color: AppColors.muted),
                      suffixIcon: query.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close,
                                  color: AppColors.muted, size: 18),
                              onPressed: () {
                                searchCtrl.clear();
                                ref
                                    .read(userSearchQueryProvider.notifier)
                                    .set('');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    style: AppTypography.body,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Friends count badge button
              GestureDetector(
                onTap: onFriendsPressed,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.people_outline,
                          color: AppColors.muted, size: 20),
                      const SizedBox(width: 6),
                      Text('$friendCount',
                          style: AppTypography.subheadline
                              .copyWith(color: AppColors.ink)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: query.trim().isNotEmpty
              ? _UserSearchResults(query: query)
              : const _FeedList(),
        ),
      ],
    );
  }
}

// ── User search results ───────────────────────────────────────────────────────

class _UserSearchResults extends ConsumerWidget {
  const _UserSearchResults({required this.query});

  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(userSearchResultsProvider);
    return results.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(color: AppColors.accent)),
      error: (e, _) => Center(child: Text('Search error: $e')),
      data: (users) {
        if (users.isEmpty) {
          return Center(
            child: Text('No users found for "$query"',
                style: AppTypography.subheadline),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          itemCount: users.length,
          separatorBuilder: (_, _) =>
              const Divider(color: AppColors.faint, height: 1),
          itemBuilder: (context, i) {
            final u = users[i];
            return _UserRow(
              id: u.id,
              displayName: u.displayName,
              handle: u.handle,
              avatarUrl: u.avatarUrl,
              isFriend: u.isFriend,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => UserProfileScreen(userId: u.id))),
            );
          },
        );
      },
    );
  }
}

// ── Feed list ─────────────────────────────────────────────────────────────────

class _FeedList extends ConsumerWidget {
  const _FeedList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(feedProvider);
    return feedAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(color: AppColors.accent)),
      error: (e, _) =>
          Center(child: Text('Could not load feed: $e', style: AppTypography.subheadline)),
      data: (posts) {
        if (posts.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.groups_outlined,
                      size: 56, color: AppColors.faint),
                  const SizedBox(height: 16),
                  Text('Your feed is empty',
                      style: AppTypography.headline),
                  const SizedBox(height: 8),
                  Text('Add friends and share workouts to see posts here.',
                      style: AppTypography.subheadline,
                      textAlign: TextAlign.center),
                ],
              ),
            ),
          );
        }
        return RefreshIndicator(
          color: AppColors.accent,
          backgroundColor: AppColors.surface,
          onRefresh: () async => ref.invalidate(feedProvider),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: posts.length,
            itemBuilder: (context, i) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _PostCard(post: posts[i]),
            ),
          ),
        );
      },
    );
  }
}

// ── Post card ─────────────────────────────────────────────────────────────────

class _PostCard extends ConsumerWidget {
  const _PostCard({required this.post});

  final FeedPost post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = ref.watch(currentUserIdProvider);

    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => PostDetailScreen(postId: post.id))),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author row
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) =>
                        UserProfileScreen(userId: post.author.id))),
                child: Row(
                  children: [
                    _Avatar(
                      url: post.author.avatarUrl,
                      name: post.author.displayName,
                      radius: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(post.author.displayName,
                              style: AppTypography.headline,
                              overflow: TextOverflow.ellipsis),
                          if (post.author.handle != null)
                            Text('@${post.author.handle}',
                                style: AppTypography.caption1),
                        ],
                      ),
                    ),
                    Text(_relativeTime(post.createdAt),
                        style: AppTypography.caption1),
                  ],
                ),
              ),
            ),

            // Optional caption
            if (post.body != null && post.body!.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                child: Text(post.body!,
                    style: AppTypography.body,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis),
              ),

            // Content payload
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: switch (post.kind) {
                PostKind.workoutShare => _WorkoutShareBody(post: post),
                PostKind.challengeResult => _ChallengeResultBody(post: post),
                PostKind.levelUp => _LevelUpBody(post: post),
              },
            ),

            const SizedBox(height: 10),
            const Divider(color: AppColors.faint, height: 1),

            // Action row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Row(
                children: [
                  // Like
                  _ActionBtn(
                    icon: post.likedByMe
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: post.likedByMe
                        ? AppColors.danger
                        : AppColors.muted,
                    label: '${post.likeCount}',
                    onTap: () => ref
                        .read(togglePostLikeProvider)
                        .call(post.id, currentlyLiked: post.likedByMe),
                  ),
                  // Comment
                  _ActionBtn(
                    icon: Icons.chat_bubble_outline,
                    color: AppColors.muted,
                    label: '${post.commentCount}',
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => PostDetailScreen(postId: post.id))),
                  ),
                  // Share (only if own post or workout_share)
                  if (post.author.id == currentUserId ||
                      post.kind == PostKind.workoutShare)
                    _ActionBtn(
                      icon: Icons.ios_share_outlined,
                      color: AppColors.muted,
                      label: 'Share',
                      onTap: () => _showShareSheet(context, ref),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showShareSheet(BuildContext context, WidgetRef ref) {
    final gw = ref.read(socialShareGatewayProvider);
    final text = post.body ?? '${post.author.displayName} shared a workout.';
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SHARE TO', style: AppTypography.caption2),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: SocialPlatform.values
                  .map((p) => OutlinedButton.icon(
                        icon: Icon(_platformIcon(p), size: 18),
                        label: Text(p.label),
                        onPressed: () {
                          Navigator.pop(context);
                          gw.shareTo(p, text: text);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.ink,
                          side: const BorderSide(color: AppColors.faint),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  IconData _platformIcon(SocialPlatform p) => switch (p) {
        SocialPlatform.facebook => Icons.facebook,
        SocialPlatform.instagram => Icons.camera_alt_outlined,
        SocialPlatform.twitter => Icons.alternate_email,
        SocialPlatform.tiktok => Icons.music_note_outlined,
      };

  static String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: color),
      label: Text(label,
          style: AppTypography.footnote.copyWith(color: color)),
      style: TextButton.styleFrom(foregroundColor: color),
    );
  }
}

// ── Post body widgets ─────────────────────────────────────────────────────────

class _WorkoutShareBody extends StatelessWidget {
  const _WorkoutShareBody({required this.post});

  final FeedPost post;

  @override
  Widget build(BuildContext context) {
    final name = post.sessionCustomName ??
        post.sessionTypeName ??
        'Workout';
    final dur = _formatDuration(post.sessionDurationSeconds ?? 0);
    final dist = post.sessionDistanceMeters != null
        ? '${(post.sessionDistanceMeters! / 1000).toStringAsFixed(1)} km'
        : null;
    final cal = post.sessionCaloriesBurned != null
        ? '${post.sessionCaloriesBurned} kcal'
        : null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name,
              style: AppTypography.headline,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          Row(
            children: [
              _StatChip(icon: Icons.timer_outlined, label: dur),
              if (dist != null) ...[
                const SizedBox(width: 10),
                _StatChip(icon: Icons.route_outlined, label: dist),
              ],
              if (cal != null) ...[
                const SizedBox(width: 10),
                _StatChip(icon: Icons.local_fire_department_outlined, label: cal),
              ],
            ],
          ),
        ],
      ),
    );
  }

  static String _formatDuration(int secs) {
    final m = secs ~/ 60;
    final s = secs % 60;
    if (m >= 60) {
      return '${m ~/ 60}h ${m % 60}m';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

class _ChallengeResultBody extends StatelessWidget {
  const _ChallengeResultBody({required this.post});

  final FeedPost post;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha:0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withValues(alpha:0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.emoji_events_outlined,
              color: AppColors.accent, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              post.challenge != null
                  ? 'Completed: ${post.challenge!.name}'
                  : 'Challenge completed!',
              style: AppTypography.headline
                  .copyWith(color: AppColors.accent),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelUpBody extends StatelessWidget {
  const _LevelUpBody({required this.post});

  final FeedPost post;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.gold.withValues(alpha:0.18),
            AppColors.accent.withValues(alpha:0.08)
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gold.withValues(alpha:0.35)),
      ),
      child: Row(
        children: [
          const Text('🏆', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Reached Level ${post.level ?? '?'}',
                    style: AppTypography.headline
                        .copyWith(color: AppColors.gold)),
                Text('Keep it up!', style: AppTypography.footnote),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.muted),
        const SizedBox(width: 4),
        Text(label, style: AppTypography.footnote),
      ],
    );
  }
}

// ── Challenges section ────────────────────────────────────────────────────────

enum _ChallengeTab { joined, active, past }

class _ChallengesSection extends ConsumerStatefulWidget {
  const _ChallengesSection();

  @override
  ConsumerState<_ChallengesSection> createState() => _ChallengesSectionState();
}

class _ChallengesSectionState extends ConsumerState<_ChallengesSection> {
  _ChallengeTab _tab = _ChallengeTab.joined;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Sub-tab pills
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: _ChallengeTab.values.map((t) {
              final selected = t == _tab;
              const labels = {
                _ChallengeTab.joined: 'Joined',
                _ChallengeTab.active: 'Active',
                _ChallengeTab.past: 'Past',
              };
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _tab = t),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.surface2 : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selected ? AppColors.faint : Colors.transparent,
                      ),
                    ),
                    child: Text(
                      labels[t]!,
                      style: AppTypography.subheadline.copyWith(
                        color:
                            selected ? AppColors.ink : AppColors.muted,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(child: _challengeList()),
      ],
    );
  }

  Widget _challengeList() {
    final provider = switch (_tab) {
      _ChallengeTab.joined => ref.watch(joinedChallengesProvider),
      _ChallengeTab.active => ref.watch(activeChallengesProvider),
      _ChallengeTab.past => ref.watch(pastChallengesProvider),
    };
    final emptyMsg = switch (_tab) {
      _ChallengeTab.joined => 'You haven\'t joined any challenges yet.',
      _ChallengeTab.active => 'No active challenges at the moment.',
      _ChallengeTab.past => 'No past challenges.',
    };

    return provider.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(color: AppColors.accent)),
      error: (e, _) => Center(
          child: Text('Error: $e', style: AppTypography.subheadline)),
      data: (challenges) {
        if (challenges.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.emoji_events_outlined,
                      size: 56, color: AppColors.faint),
                  const SizedBox(height: 16),
                  Text(emptyMsg,
                      style: AppTypography.subheadline,
                      textAlign: TextAlign.center),
                  if (_tab == _ChallengeTab.active) ...[
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => setState(
                          () => _tab = _ChallengeTab.active),
                      child: const Text('BROWSE CHALLENGES'),
                    ),
                  ],
                ],
              ),
            ),
          );
        }
        return RefreshIndicator(
          color: AppColors.accent,
          backgroundColor: AppColors.surface,
          onRefresh: () async {
            ref.invalidate(joinedChallengesProvider);
            ref.invalidate(activeChallengesProvider);
            ref.invalidate(pastChallengesProvider);
          },
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            itemCount: challenges.length,
            itemBuilder: (context, i) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ChallengeCard(challenge: challenges[i]),
            ),
          ),
        );
      },
    );
  }
}

class _ChallengeCard extends ConsumerWidget {
  const _ChallengeCard({required this.challenge});

  final Challenge challenge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = ref.watch(currentUserIdProvider);
    final participantIdsAsync =
        ref.watch(challengeParticipantIdsProvider(challenge.id));
    final hasJoined = participantIdsAsync.value?.contains(currentUserId) ?? false;

    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) =>
              ChallengeDetailScreen(challengeId: challenge.id))),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: challenge.isActive
              ? Border.all(color: AppColors.accent.withValues(alpha:0.3))
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(challenge.name,
                      style: AppTypography.headline,
                      overflow: TextOverflow.ellipsis),
                ),
                if (challenge.isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha:0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('LIVE',
                        style: AppTypography.caption2
                            .copyWith(color: AppColors.accent)),
                  )
                else if (challenge.isEnded)
                  Text('Ended',
                      style: AppTypography.caption1
                          .copyWith(color: AppColors.muted)),
              ],
            ),
            const SizedBox(height: 6),
            if (challenge.description != null && challenge.description!.isNotEmpty)
              Text(challenge.description!,
                  style: AppTypography.footnote,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            Row(
              children: [
                _StatChip(
                    icon: Icons.calendar_today_outlined,
                    label:
                        '${challenge.totalDays}d · Day ${challenge.isEnded ? challenge.totalDays : challenge.currentDayNumber}'),
                const SizedBox(width: 12),
                _StatChip(
                    icon: Icons.bar_chart_outlined,
                    label: challenge.metric.label),
                const Spacer(),
                if (!challenge.isEnded)
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: hasJoined
                        ? OutlinedButton(
                            key: const ValueKey('joined'),
                            onPressed: () =>
                                ref.read(leaveChallengeProvider).call(challenge.id),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.muted,
                              side:
                                  const BorderSide(color: AppColors.faint),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 0),
                              minimumSize: const Size(0, 32),
                              textStyle: AppTypography.footnote,
                            ),
                            child: const Text('Leave'),
                          )
                        : ElevatedButton(
                            key: const ValueKey('join'),
                            onPressed: () => ref
                                .read(joinChallengeProvider)
                                .call(challenge.id),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              foregroundColor: AppColors.bg,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 0),
                              minimumSize: const Size(0, 32),
                              textStyle: AppTypography.footnote,
                            ),
                            child: const Text('Join'),
                          ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Friends modal ─────────────────────────────────────────────────────────────

class _FriendsModal extends ConsumerWidget {
  const _FriendsModal();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendsAsync = ref.watch(friendsProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, controller) => Column(
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.faint,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: Row(
              children: [
                Text('Friends', style: AppTypography.title2),
                const Spacer(),
                friendsAsync.whenOrNull(
                      data: (list) => Text('${list.length}',
                          style: AppTypography.subheadline),
                    ) ??
                    const SizedBox.shrink(),
              ],
            ),
          ),
          Expanded(
            child: friendsAsync.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.accent)),
              error: (e, _) =>
                  Center(child: Text('Error: $e')),
              data: (friends) {
                if (friends.isEmpty) {
                  return Center(
                    child: Text('No friends yet. Find people via search.',
                        style: AppTypography.subheadline,
                        textAlign: TextAlign.center),
                  );
                }
                return ListView.separated(
                  controller: controller,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: friends.length,
                  separatorBuilder: (_, _) =>
                      const Divider(color: AppColors.faint, height: 1),
                  itemBuilder: (context, i) {
                    final f = friends[i];
                    return _UserRow(
                      id: f.id,
                      displayName: f.displayName,
                      handle: f.handle,
                      avatarUrl: f.avatarUrl,
                      isFriend: true,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) =>
                                UserProfileScreen(userId: f.id)));
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Create Challenge modal ────────────────────────────────────────────────────

class _CreateChallengeModal extends ConsumerStatefulWidget {
  const _CreateChallengeModal();

  @override
  ConsumerState<_CreateChallengeModal> createState() =>
      _CreateChallengeModalState();
}

class _CreateChallengeModalState
    extends ConsumerState<_CreateChallengeModal> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  DateTime _startDate = DateTime.now().toUtc();
  DateTime _endDate =
      DateTime.now().toUtc().add(const Duration(days: 7));
  ChallengeMetricKind _metricKind = ChallengeMetricKind.accumulator;
  ChallengeMetric _metric = ChallengeMetric.totalDistance;
  ChallengeVisibility _visibility = ChallengeVisibility.public;
  WorkoutType? _selectedType;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Challenge name is required.');
      return;
    }
    if (_endDate.isBefore(_startDate)) {
      setState(() => _error = 'End date must be after start date.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(createChallengeProvider).call({
        'name': name,
        'description': _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
        'started_at': _startDate.toIso8601String(),
        'ended_at': _endDate.toIso8601String(),
        'metric_kind': _metricKind.name,
        'metric': _metric.name,
        'visibility': _visibility.name,
        'workout_type_id': _selectedType?.id,
      });
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _saving = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final typesAsync = ref.watch(workoutTypesProvider);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, controller) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.faint,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                children: [
                  Text('Create Challenge', style: AppTypography.title2),
                  const Spacer(),
                  TextButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    child: Text('Cancel',
                        style: AppTypography.subheadline
                            .copyWith(color: AppColors.muted)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(
                          labelText: 'CHALLENGE NAME'),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _descCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                          labelText: 'DESCRIPTION (OPTIONAL)'),
                    ),
                    const SizedBox(height: 20),

                    // Date range
                    Text('DATES', style: AppTypography.caption2),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                            child: _DateBtn(
                          label: 'Start',
                          date: _startDate,
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _startDate,
                              firstDate: DateTime.now()
                                  .subtract(const Duration(days: 1)),
                              lastDate: DateTime.now()
                                  .add(const Duration(days: 365)),
                            );
                            if (picked != null) {
                              setState(() => _startDate =
                                  picked.toUtc());
                            }
                          },
                        )),
                        const SizedBox(width: 10),
                        Expanded(
                            child: _DateBtn(
                          label: 'End',
                          date: _endDate,
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _endDate,
                              firstDate: _startDate
                                  .add(const Duration(days: 1)),
                              lastDate: DateTime.now()
                                  .add(const Duration(days: 365)),
                            );
                            if (picked != null) {
                              setState(() =>
                                  _endDate = picked.toUtc());
                            }
                          },
                        )),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Metric kind
                    Text('METRIC TYPE', style: AppTypography.caption2),
                    const SizedBox(height: 8),
                    Row(
                      children: ChallengeMetricKind.values.map((k) {
                        final selected = k == _metricKind;
                        const labels = {
                          ChallengeMetricKind.accumulator: 'Accumulator',
                          ChallengeMetricKind.bestOf: 'Best Of',
                        };
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _metricKind = k;
                                _metric = k ==
                                        ChallengeMetricKind.accumulator
                                    ? ChallengeMetric.totalDistance
                                    : ChallengeMetric.fastestTime;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: selected
                                    ? AppColors.accent
                                    : AppColors.surface2,
                                borderRadius:
                                    BorderRadius.circular(10),
                              ),
                              child: Text(labels[k]!,
                                  style: AppTypography.footnote
                                      .copyWith(
                                          color: selected
                                              ? AppColors.bg
                                              : AppColors.ink)),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),

                    // Metric
                    Text('METRIC', style: AppTypography.caption2),
                    const SizedBox(height: 8),
                    Column(
                      children: _metricsForKind()
                          .map((m) => _MetricOption(
                                metric: m,
                                selected: m == _metric,
                                onTap: () =>
                                    setState(() => _metric = m),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 14),

                    // Workout type filter (optional)
                    Text('WORKOUT TYPE FILTER (OPTIONAL)',
                        style: AppTypography.caption2),
                    const SizedBox(height: 8),
                    typesAsync.when(
                      loading: () =>
                          const LinearProgressIndicator(),
                      error: (_, _) => const SizedBox.shrink(),
                      data: (types) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surface2,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: DropdownButton<WorkoutType?>(
                          value: _selectedType,
                          isExpanded: true,
                          dropdownColor: AppColors.surface2,
                          underline: const SizedBox.shrink(),
                          hint: const Text('Any workout type'),
                          items: [
                            const DropdownMenuItem<WorkoutType?>(
                                value: null,
                                child: Text('Any type')),
                            ...types.map((t) =>
                                DropdownMenuItem<WorkoutType?>(
                                    value: t,
                                    child: Text(t.name))),
                          ],
                          onChanged: (t) =>
                              setState(() => _selectedType = t),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Visibility
                    Text('VISIBILITY', style: AppTypography.caption2),
                    const SizedBox(height: 8),
                    Row(
                      children:
                          ChallengeVisibility.values.map((v) {
                        final selected = v == _visibility;
                        const labels = {
                          ChallengeVisibility.public: 'Public',
                          ChallengeVisibility.inviteOnly:
                              'Invite Only',
                        };
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _visibility = v),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: selected
                                    ? AppColors.accent
                                    : AppColors.surface2,
                                borderRadius:
                                    BorderRadius.circular(10),
                              ),
                              child: Text(labels[v]!,
                                  style: AppTypography.footnote
                                      .copyWith(
                                          color: selected
                                              ? AppColors.bg
                                              : AppColors.ink)),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!,
                          style: AppTypography.footnote
                              .copyWith(color: AppColors.danger)),
                    ],

                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        child: _saving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.bg))
                            : const Text('CREATE CHALLENGE'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<ChallengeMetric> _metricsForKind() {
    return _metricKind == ChallengeMetricKind.accumulator
        ? [
            ChallengeMetric.totalDistance,
            ChallengeMetric.totalSessions,
            ChallengeMetric.totalCalories,
            ChallengeMetric.activeDays,
          ]
        : [
            ChallengeMetric.fastestTime,
            ChallengeMetric.longestDistance,
            ChallengeMetric.mostCalories,
          ];
  }
}

class _MetricOption extends StatelessWidget {
  const _MetricOption({
    required this.metric,
    required this.selected,
    required this.onTap,
  });

  final ChallengeMetric metric;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color:
                      selected ? AppColors.accent : AppColors.faint,
                  width: 2,
                ),
                color: selected
                    ? AppColors.accent
                    : Colors.transparent,
              ),
              child: selected
                  ? const Icon(Icons.check,
                      size: 12, color: AppColors.bg)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(metric.label,
                  style: AppTypography.subheadline
                      .copyWith(color: AppColors.ink)),
            ),
            Text(metric.unit, style: AppTypography.footnote),
          ],
        ),
      ),
    );
  }
}

class _DateBtn extends StatelessWidget {
  const _DateBtn(
      {required this.label, required this.date, required this.onTap});

  final String label;
  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTypography.caption2),
            const SizedBox(height: 4),
            Text(
              '${date.day}/${date.month}/${date.year}',
              style: AppTypography.subheadline
                  .copyWith(color: AppColors.ink),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared user row ───────────────────────────────────────────────────────────

class _UserRow extends ConsumerWidget {
  const _UserRow({
    required this.id,
    required this.displayName,
    this.handle,
    this.avatarUrl,
    required this.isFriend,
    required this.onTap,
  });

  final String id;
  final String displayName;
  final String? handle;
  final String? avatarUrl;
  final bool isFriend;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: _Avatar(url: avatarUrl, name: displayName, radius: 20),
      title: Text(displayName, style: AppTypography.headline),
      subtitle: handle != null
          ? Text('@$handle', style: AppTypography.footnote)
          : null,
      onTap: onTap,
      trailing: isFriend
          ? OutlinedButton(
              onPressed: () =>
                  ref.read(unfollowUserProvider).call(id),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.muted,
                side: const BorderSide(color: AppColors.faint),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 0),
                minimumSize: const Size(0, 30),
                textStyle: AppTypography.footnote,
              ),
              child: const Text('Unfriend'),
            )
          : ElevatedButton(
              onPressed: () =>
                  ref.read(followUserProvider).call(id),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.bg,
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 0),
                minimumSize: const Size(0, 30),
                textStyle: AppTypography.footnote,
              ),
              child: const Text('Add Friend'),
            ),
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
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.surface2,
      child: Text(initial,
          style: AppTypography.subheadline
              .copyWith(color: AppColors.ink, fontWeight: FontWeight.w600)),
    );
  }
}
