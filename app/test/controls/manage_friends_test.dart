import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wise_workout/boundaries/gateways/social_gateway.dart';
import 'package:wise_workout/controls/authenticate.dart';
import 'package:wise_workout/controls/manage_friends.dart';
import 'package:wise_workout/controls/social_feed.dart';
import 'package:wise_workout/entities/enums.dart';
import 'package:wise_workout/entities/feed_post.dart';
import 'package:wise_workout/entities/post.dart';
import 'package:wise_workout/entities/public_profile.dart';

import '../helpers/fakes.dart';

// (#) Tests the friend/social controls: follow/unfollow, user search, profile
// (#) stats, the self-friend guard, and per-author post scoping.

// (#) Builds a container with the given signed-in user and fake social gateway.
ProviderContainer _container(FakeSocialGateway social, {String? userId = 'u1'}) {
  final c = ProviderContainer(overrides: [
    currentUserIdProvider.overrideWithValue(userId),
    socialGatewayProvider.overrideWithValue(social),
  ]);
  addTearDown(c.dispose);
  return c;
}

// (#) Sample public profiles used across the tests.
const _alex = PublicProfile(id: 'u2', firstName: 'Alex', lastName: 'Tan', username: 'alex');
const _sam = PublicProfile(id: 'u3', firstName: 'Sam', lastName: 'Lee', username: 'sam');

void main() {
  // (#) The follow and unfollow user controls.
  group('FollowUser / UnfollowUser', () {
    // (#) (+) Check if following calls addFriend and the friend state/count refresh.
    test('FollowUser calls addFriend and refreshes friend state (positive)', () async {
      final social = FakeSocialGateway()..profiles = [_alex];
      final c = _container(social);
      expect(await c.read(isFriendProvider('u2').future), isFalse);

      await c.read(followUserProvider).call('u2');
      expect(social.addFriendCalls.single, 'u2');
      expect(await c.read(isFriendProvider('u2').future), isTrue);
      expect(await c.read(friendCountProvider.future), 1);
    });

    // (#) (+) Check if unfollowing removes the friend and the feed refetches for the new scope.
    test('UnfollowUser removes and the feed refetches (scope changed)', () async {
      final social = FakeSocialGateway()
        ..friends = ['u2']
        ..profiles = [_alex];
      final c = _container(social);
      await c.read(feedProvider.future);
      final before = social.fetchFeedCalls;

      await c.read(unfollowUserProvider).call('u2');
      expect(social.removeFriendCalls.single, 'u2');
      expect(await c.read(isFriendProvider('u2').future), isFalse);
      await c.read(feedProvider.future);
      expect(social.fetchFeedCalls, before + 1);
    });
  });

  // (#) The user-search provider.
  group('searchUsersProvider', () {
    // (#) (+) Check if it passes the query to the gateway and returns the matches.
    test('passes the query and returns matches (positive)', () async {
      final social = FakeSocialGateway()..profiles = [_alex, _sam];
      final c = _container(social);

      final hits = await c.read(searchUsersProvider('alex').future);
      expect(hits.single.id, 'u2');
      expect(social.searchQueries.single, 'alex');
    });

    // (#) (-) Check if a blank query returns empty without hitting the gateway.
    test('blank query short-circuits (negative)', () async {
      final social = FakeSocialGateway();
      final c = _container(social);

      expect(await c.read(searchUsersProvider('   ').future), isEmpty);
      expect(social.searchQueries, isEmpty);
    });
  });

  // (#) The provider that assembles a user's public profile stats.
  group('userProfileStatsProvider', () {
    // (#) (+) Check if it combines workout count, friend count, and active days.
    test('assembles workouts / friends / activeDays', () async {
      final social = FakeSocialGateway()
        ..friends = ['u2', 'u3']
        ..userStatsResult = (workouts: 12, activeDays: 8);
      final c = _container(social);

      final stats = await c.read(userProfileStatsProvider('u1').future);
      expect(stats.workouts, 12);
      expect(stats.friends, 2);
      expect(stats.activeDays, 8);
    });
  });

  // (#) The provider that reports whether a user is a friend.
  group('isFriendProvider', () {
    // (#) (-) Check if your own id is never reported as a friend.
    test('self is never a friend (guard)', () async {
      final social = FakeSocialGateway()..friends = ['u1'];
      final c = _container(social);
      expect(await c.read(isFriendProvider('u1').future), isFalse);
    });
  });

  // (#) The provider that lists one author's posts.
  group('userPostsProvider', () {
    // (#) (+) Check if it returns only the requested author's posts.
    test('scoped to the requested author', () async {
      final social = FakeSocialGateway()
        ..feed = [
          FeedPost(
            post: Post(
                id: 'p1',
                userId: 'u2',
                kind: PostKind.workoutShare,
                workoutSessionId: 's1',
                createdAt: DateTime.utc(2026, 7, 1)),
            author: _alex,
          ),
          FeedPost(
            post: Post(
                id: 'p2',
                userId: 'u3',
                kind: PostKind.levelUp,
                level: 2,
                createdAt: DateTime.utc(2026, 7, 2)),
            author: _sam,
          ),
        ];
      final c = _container(social);

      final posts = await c.read(userPostsProvider('u2').future);
      expect(posts.single.post.id, 'p1');
    });
  });
}
