import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../controls/manage_friends.dart';
import '../../../controls/social_feed.dart';
import '../../../core/theme/app_typography.dart';
import 'find_friends_strip.dart';
import 'post_card.dart';
import 'user_row.dart';

/// BOUNDARY — the Community tab body (#11): find-friends strip over the
/// friends+self post feed. A non-empty search query swaps the feed for user
/// search results (list-in-place, not an overlay — approved trim).
class CommunityFeed extends ConsumerStatefulWidget {
  const CommunityFeed({super.key});

  @override
  ConsumerState<CommunityFeed> createState() => _CommunityFeedState();
}

class _CommunityFeedState extends ConsumerState<CommunityFeed> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FindFriendsStrip(onQuery: (q) => setState(() => _query = q)),
        Expanded(
          child: _query.trim().isEmpty ? _feed() : _searchResults(),
        ),
      ],
    );
  }

  Widget _feed() {
    final feed = ref.watch(feedProvider);
    return feed.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
          child: Text('Could not load the feed.\n$e',
              style: AppTypography.footnote, textAlign: TextAlign.center)),
      data: (posts) {
        if (posts.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Your feed is empty. Share a workout from a session summary, '
                'or add friends to see theirs.',
                style: AppTypography.subheadline,
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(feedProvider),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [for (final p in posts) PostCard(feedPost: p)],
          ),
        );
      },
    );
  }

  Widget _searchResults() {
    final results = ref.watch(searchUsersProvider(_query.trim()));
    return results.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
          child: Text('Search failed.', style: AppTypography.footnote)),
      data: (users) {
        if (users.isEmpty) {
          return Center(
              child: Text('No members match "${_query.trim()}".',
                  style: AppTypography.subheadline));
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [for (final u in users) UserRow(user: u)],
        );
      },
    );
  }
}
