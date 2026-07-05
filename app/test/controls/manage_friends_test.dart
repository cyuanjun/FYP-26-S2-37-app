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

ProviderContainer _container(FakeSocialGateway social, {String? userId = 'u1'}) {
  final c = ProviderContainer(overrides: [
    currentUserIdProvider.overrideWithValue(userId),
    socialGatewayProvider.overrideWithValue(social),
  ]);
  addTearDown(c.dispose);
  return c;
}

const _alex = PublicProfile(id: 'u2', firstName: 'Alex', lastName: 'Tan', username: 'alex');
const _sam = PublicProfile(id: 'u3', firstName: 'Sam', lastName: 'Lee', username: 'sam');

void main() {
  group('FollowUser / UnfollowUser', () {
    test('FollowUser calls addFriend and refreshes friend state (positive)', () async {
      final social = FakeSocialGateway()..profiles = [_alex];
      final c = _container(social);
      expect(await c.read(isFriendProvider('u2').future), isFalse);

      await c.read(followUserProvider).call('u2');
      expect(social.addFriendCalls.single, 'u2');
      expect(await c.read(isFriendProvider('u2').future), isTrue);
      expect(await c.read(friendCountProvider.future), 1);
    });

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

  group('searchUsersProvider', () {
    test('passes the query and returns matches (positive)', () async {
      final social = FakeSocialGateway()..profiles = [_alex, _sam];
      final c = _container(social);

      final hits = await c.read(searchUsersProvider('alex').future);
      expect(hits.single.id, 'u2');
      expect(social.searchQueries.single, 'alex');
    });

    test('blank query short-circuits (negative)', () async {
      final social = FakeSocialGateway();
      final c = _container(social);

      expect(await c.read(searchUsersProvider('   ').future), isEmpty);
      expect(social.searchQueries, isEmpty);
    });
  });

  group('userProfileStatsProvider', () {
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

  group('isFriendProvider', () {
    test('self is never a friend (guard)', () async {
      final social = FakeSocialGateway()..friends = ['u1'];
      final c = _container(social);
      expect(await c.read(isFriendProvider('u1').future), isFalse);
    });
  });

  group('userPostsProvider', () {
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
