import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../boundaries/gateways/social_gateway.dart';
import '../core/seq_log.dart';
import '../entities/feed_post.dart';
import '../entities/public_profile.dart';
import 'authenticate.dart';
import 'social_feed.dart';

// (#) This file covers managing friends and viewing another user's profile.
// (#) Friendship is a mutual pair, so there's one "Friends" count and no
// (#) follower/following split.

// (#) How many friends the signed-in user has.
final friendCountProvider = FutureProvider<int>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return 0;
  SeqLog.msg('view-friends', 'ManageFriends', 'SocialGateway', 'friendIds');
  return (await ref.watch(socialGatewayProvider).friendIds(userId)).length;
});

// (#) The signed-in user's friends as public profiles, for the friends list.
final friendsProvider = FutureProvider<List<PublicProfile>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Future.value(const <PublicProfile>[]);
  SeqLog.msg('view-friends', 'ManageFriends', 'SocialGateway', 'listFriends');
  return ref.watch(socialGatewayProvider).listFriends(userId);
});

// (#) Whether the given user is already a friend; false for yourself.
final isFriendProvider = FutureProvider.family<bool, String>((ref, otherId) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null || userId == otherId) return Future.value(false);
  return ref.watch(socialGatewayProvider).isFriend(userId, otherId);
});

// (#) Searches users by name for the find-friends strip, minus yourself; empty
// (#) query gives nothing.
final searchUsersProvider =
    FutureProvider.family<List<PublicProfile>, String>((ref, query) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null || query.trim().isEmpty) {
    return Future.value(const <PublicProfile>[]);
  }
  SeqLog.msg('find-friends', 'FindFriendsStrip', 'SocialGateway',
      'searchUsers("$query")');
  return ref
      .watch(socialGatewayProvider)
      .searchUsers(query, excludeId: userId);
});

// (#) Another user's public profile by id, for their profile screen.
final publicProfileProvider =
    FutureProvider.family<PublicProfile?, String>((ref, userId) {
  SeqLog.msg('view-user', 'ViewUserProfile', 'SocialGateway',
      'fetchPublicProfile($userId)');
  return ref.watch(socialGatewayProvider).fetchPublicProfile(userId);
});

// (#) Shape of the stats row on a user profile: workouts, friends, active days.
typedef UserProfileStats = ({int workouts, int friends, int activeDays});

// (#) Builds that stats row for a user by combining their session stats with
// (#) their friend count.
final userProfileStatsProvider =
    FutureProvider.family<UserProfileStats, String>((ref, userId) async {
  final gateway = ref.watch(socialGatewayProvider);
  SeqLog.msg('view-user', 'ViewUserProfile', 'SocialGateway',
      'userStats($userId)');
  final stats = await gateway.userStats(userId);
  final friends = (await gateway.friendIds(userId)).length;
  return (
    workouts: stats.workouts,
    friends: friends,
    activeDays: stats.activeDays,
  );
});

// (#) A user's own posts for their profile screen.
final userPostsProvider =
    FutureProvider.family<List<FeedPost>, String>((ref, userId) {
  final me = ref.watch(currentUserIdProvider);
  if (me == null) return Future.value(const <FeedPost>[]);
  SeqLog.msg('view-user', 'ViewUserProfile', 'SocialGateway',
      'listUserPosts($userId)');
  return ref.watch(socialGatewayProvider).listUserPosts(userId, me: me);
});

// (#) Adds a friend (spec label "Add Friend"). Writes the mutual pair through
// (#) the gateway, then refreshes the counts, lists and feed that just changed.
class FollowUser {
  FollowUser(this._ref);

  final Ref _ref; // (#) Riverpod handle for reading the gateway

  // (#) Befriends the given user.
  Future<void> call(String targetId) async {
    SeqLog.msg('follow-user', 'UserRow', 'FollowUser', 'add($targetId)');
    SeqLog.msg('follow-user', 'FollowUser', 'SocialGateway', 'addFriend(rpc)');
    await _ref.read(socialGatewayProvider).addFriend(targetId);
    _invalidate(_ref, targetId);
  }
}

// (#) Unfriends someone. Removes both sides of the pair via the gateway and
// (#) refreshes the same friend and feed providers.
class UnfollowUser {
  UnfollowUser(this._ref);

  final Ref _ref; // (#) Riverpod handle for reading the gateway

  // (#) Removes the given user as a friend.
  Future<void> call(String targetId) async {
    SeqLog.msg('unfollow-user', 'UserRow', 'UnfollowUser', 'remove($targetId)');
    SeqLog.msg('unfollow-user', 'UnfollowUser', 'SocialGateway',
        'removeFriend(rpc)');
    await _ref.read(socialGatewayProvider).removeFriend(targetId);
    _invalidate(_ref, targetId);
  }
}

// (#) Shared helper: refreshes every provider that a friend change affects.
void _invalidate(Ref ref, String targetId) {
  ref.invalidate(isFriendProvider(targetId));
  ref.invalidate(friendCountProvider);
  ref.invalidate(friendsProvider);
  ref.invalidate(userProfileStatsProvider(targetId));
  ref.invalidate(feedProvider); // the feed's scope just changed
}

// (#) Hand the user rows the add-friend and unfriend controls.
final followUserProvider = Provider<FollowUser>(FollowUser.new);
final unfollowUserProvider = Provider<UnfollowUser>(UnfollowUser.new);
