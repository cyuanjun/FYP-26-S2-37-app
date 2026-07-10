import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../controls/manage_friends.dart';
import '../../../controls/social_feed.dart';
import '../../../core/theme/app_typography.dart';
import 'find_friends_strip.dart';
import 'post_card.dart';
import 'user_row.dart';

// (#) The Community tab feed. Shows friends' and your own posts with a search
// (#) strip on top. Typing a query swaps the feed for member search results.
// (#) Both lists are watched from controls.
class CommunityFeed extends ConsumerStatefulWidget {
  const CommunityFeed({super.key});

  // (#) Creates the state that tracks the current search text.
  @override
  ConsumerState<CommunityFeed> createState() => _CommunityFeedState();
}

// (#) Holds the feed state, mainly the live search query.
class _CommunityFeedState extends ConsumerState<CommunityFeed> {
  String _query = ''; // (#) what the user typed into the find-friends box

  // (#) Builds the search strip plus either the post feed or search results.
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

  // (#) Builds the friends-plus-self post list, with loading, error and empty states.
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

  // (#) Builds the member search results for the current query.
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
