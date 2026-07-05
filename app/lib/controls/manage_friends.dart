import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../boundaries/gateways/social_gateway.dart';
import '../core/seq_log.dart';
import '../entities/feed_post.dart';
import '../entities/public_profile.dart';
import 'authenticate.dart';
import 'social_feed.dart';

/// CONTROLs — Manage Friends (US24) + View User Profile (#11.2). Friendship
/// is a mutual pair (one "Friends" count, no follower/following split).

final friendCountProvider = FutureProvider<int>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return 0;
  SeqLog.msg('view-friends', 'ManageFriends', 'SocialGateway', 'friendIds');
  return (await ref.watch(socialGatewayProvider).friendIds(userId)).length;
});

final friendsProvider = FutureProvider<List<PublicProfile>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Future.value(const <PublicProfile>[]);
  SeqLog.msg('view-friends', 'ManageFriends', 'SocialGateway', 'listFriends');
  return ref.watch(socialGatewayProvider).listFriends(userId);
});

final isFriendProvider = FutureProvider.family<bool, String>((ref, otherId) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null || userId == otherId) return Future.value(false);
  return ref.watch(socialGatewayProvider).isFriend(userId, otherId);
});

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

final publicProfileProvider =
    FutureProvider.family<PublicProfile?, String>((ref, userId) {
  SeqLog.msg('view-user', 'ViewUserProfile', 'SocialGateway',
      'fetchPublicProfile($userId)');
  return ref.watch(socialGatewayProvider).fetchPublicProfile(userId);
});

/// #11.2 stats row: Workouts / Friends / Active days (mutual graph — no
/// follower/following split). Assembled control-side (ProfileStats precedent).
typedef UserProfileStats = ({int workouts, int friends, int activeDays});

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

final userPostsProvider =
    FutureProvider.family<List<FeedPost>, String>((ref, userId) {
  final me = ref.watch(currentUserIdProvider);
  if (me == null) return Future.value(const <FeedPost>[]);
  SeqLog.msg('view-user', 'ViewUserProfile', 'SocialGateway',
      'listUserPosts($userId)');
  return ref.watch(socialGatewayProvider).listUserPosts(userId, me: me);
});

/// CONTROL — Follow User (spec verb: "Add Friend"; writes the mutual pair).
class FollowUser {
  FollowUser(this._ref);

  final Ref _ref;

  Future<void> call(String targetId) async {
    SeqLog.msg('follow-user', 'UserRow', 'FollowUser', 'add($targetId)');
    SeqLog.msg('follow-user', 'FollowUser', 'SocialGateway', 'addFriend(rpc)');
    await _ref.read(socialGatewayProvider).addFriend(targetId);
    _invalidate(_ref, targetId);
  }
}

/// CONTROL — Unfollow User ("Unfriend"; removes both rows).
class UnfollowUser {
  UnfollowUser(this._ref);

  final Ref _ref;

  Future<void> call(String targetId) async {
    SeqLog.msg('unfollow-user', 'UserRow', 'UnfollowUser', 'remove($targetId)');
    SeqLog.msg('unfollow-user', 'UnfollowUser', 'SocialGateway',
        'removeFriend(rpc)');
    await _ref.read(socialGatewayProvider).removeFriend(targetId);
    _invalidate(_ref, targetId);
  }
}

void _invalidate(Ref ref, String targetId) {
  ref.invalidate(isFriendProvider(targetId));
  ref.invalidate(friendCountProvider);
  ref.invalidate(friendsProvider);
  ref.invalidate(userProfileStatsProvider(targetId));
  ref.invalidate(feedProvider); // the feed's scope just changed
}

final followUserProvider = Provider<FollowUser>(FollowUser.new);
final unfollowUserProvider = Provider<UnfollowUser>(UnfollowUser.new);
