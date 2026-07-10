import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wise_workout/boundaries/gateways/social_gateway.dart';
import 'package:wise_workout/controls/authenticate.dart';
import 'package:wise_workout/controls/social_feed.dart';
import 'package:wise_workout/entities/enums.dart';
import 'package:wise_workout/entities/feed_post.dart';
import 'package:wise_workout/entities/post.dart';
import 'package:wise_workout/entities/public_profile.dart';

import '../helpers/fakes.dart';

// (#) Tests the social feed controls: viewing, liking, commenting, and editing posts.

// (#) Makes a feed post from the given author for use in the fake feed.
FeedPost _post(String id, {String userId = 'u2', PostKind kind = PostKind.workoutShare, bool likedByMe = false}) {
  return FeedPost(
    post: Post(
      id: id,
      userId: userId,
      kind: kind,
      workoutSessionId: kind == PostKind.workoutShare ? 's-$id' : null,
      level: kind == PostKind.levelUp ? 3 : null,
      createdAt: DateTime.utc(2026, 7, 1),
    ),
    author: const PublicProfile(id: 'u2', firstName: 'Alex', lastName: 'Tan', username: 'alex'),
    likeCount: likedByMe ? 1 : 0,
    likedByMe: likedByMe,
  );
}

// (#) Builds a ProviderContainer wired to the fake social gateway and a signed-in user.
ProviderContainer _container(FakeSocialGateway social, {String? userId = 'u1'}) {
  final c = ProviderContainer(overrides: [
    currentUserIdProvider.overrideWithValue(userId),
    socialGatewayProvider.overrideWithValue(social),
  ]);
  addTearDown(c.dispose);
  return c;
}

void main() {
  // (#) Loading the feed.
  group('ViewSocialFeed (feedProvider)', () {
    // (#) (+) Check if the feed query is scoped to the current user plus their friends.
    test('scopes the feed to self + friends (positive)', () async {
      final social = FakeSocialGateway()
        ..friends = ['u2', 'u3']
        ..feed = [_post('p1'), _post('p2')];
      final c = _container(social);

      final posts = await c.read(feedProvider.future);
      expect(posts, hasLength(2));
      expect(social.lastFeedScope, ['u1', 'u2', 'u3']);
    });

    // (#) (-) Check if a signed-out user gets an empty feed without touching the gateway.
    test('signed out → empty feed, gateway untouched (negative)', () async {
      final social = FakeSocialGateway();
      final c = _container(social, userId: null);

      expect(await c.read(feedProvider.future), isEmpty);
      expect(social.fetchFeedCalls, 0);
    });
  });

  // (#) Liking and unliking posts.
  group('TogglePostLike', () {
    // (#) (+) Check if toggling an unliked post calls likePost and refetches the feed.
    test('not liked → likePost, and the feed refetches', () async {
      final social = FakeSocialGateway()..feed = [_post('p1')];
      final c = _container(social);
      await c.read(feedProvider.future);

      await c.read(togglePostLikeProvider).call('p1', currentlyLiked: false);
      expect(social.likeCalls.single, ('p1', 'u1'));
      expect(social.unlikeCalls, isEmpty);
      await c.read(feedProvider.future);
      expect(social.fetchFeedCalls, 2); // invalidate → refetch
    });

    // (#) (-) Check if toggling an already-liked post calls unlikePost instead of likePost.
    test('already liked → unlikePost (negative path of the toggle)', () async {
      final social = FakeSocialGateway()..feed = [_post('p1', likedByMe: true)];
      final c = _container(social);

      await c.read(togglePostLikeProvider).call('p1', currentlyLiked: true);
      expect(social.unlikeCalls.single, ('p1', 'u1'));
      expect(social.likeCalls, isEmpty);
    });
  });

  // (#) Commenting on a post.
  group('AddPostComment', () {
    // (#) (+) Check if a comment is added for the current user.
    test('adds a comment for the current user (positive)', () async {
      final social = FakeSocialGateway();
      final c = _container(social);

      final ok = await c.read(addPostCommentProvider).call(postId: 'p1', body: 'Nice run!');
      expect(ok, isTrue);
      expect(social.addedComments.single,
          {'postId': 'p1', 'userId': 'u1', 'body': 'Nice run!'});
    });

    // (#) (-) Check if a blank comment body is rejected before the gateway.
    test('blank body is rejected before the gateway (negative)', () async {
      final social = FakeSocialGateway();
      final c = _container(social);

      final ok = await c.read(addPostCommentProvider).call(postId: 'p1', body: '   ');
      expect(ok, isFalse);
      expect(social.addedComments, isEmpty);
    });
  });

  // (#) Removing a comment.
  group('DeletePostComment', () {
    // (#) (+) Check if the comment is deleted by its id.
    test('deletes by comment id', () async {
      final social = FakeSocialGateway();
      final c = _container(social);

      await c.read(deletePostCommentProvider).call(postId: 'p1', commentId: 'c9');
      expect(social.deletedCommentIds.single, 'c9');
    });
  });

  // (#) Editing a post's caption.
  group('UpdatePostBody', () {
    // (#) (+) Check if the new caption is passed through to the gateway.
    test('passes the new caption through', () async {
      final social = FakeSocialGateway();
      final c = _container(social);

      await c.read(updatePostBodyProvider).call(postId: 'p1', body: 'Updated!');
      expect(social.bodyUpdates.single, ('p1', 'Updated!'));
    });
  });

  // (#) Listing comments for one post.
  group('ListPostComments (postCommentsProvider)', () {
    // (#) (+) Check if only the requested post's comments come back.
    test('scoped to the requested post', () async {
      final social = FakeSocialGateway();
      final c = _container(social);
      await c.read(addPostCommentProvider).call(postId: 'p1', body: 'One');
      await c.read(addPostCommentProvider).call(postId: 'p2', body: 'Other');

      final comments = await c.read(postCommentsProvider('p1').future);
      expect(comments.single.body, 'One');
    });
  });
}
