import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../controls/social_feed.dart';
import '../../../core/theme/app_typography.dart';
import 'post_card.dart';

/// BOUNDARY — the Community tab body (#11): the friends+self post feed.
/// The find-friends strip lands in Phase 2.
class CommunityFeed extends ConsumerWidget {
  const CommunityFeed({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
}
