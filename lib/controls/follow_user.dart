import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../boundaries/gateways/social_gateway.dart';
import '../core/seq_log.dart';
import 'authenticate.dart';
import 'social_feed.dart';

// ── View model ────────────────────────────────────────────────────────────────

/// Lightweight user snapshot used in friend lists, search results, and
/// the #11.2 User Profile stats.
class UserSummary {
  const UserSummary({
    required this.id,
    required this.displayName,
    this.handle,
    this.avatarUrl,
    this.bio,
    this.isFriend = false,
  });

  final String id;
  final String displayName;
  final String? handle;
  final String? avatarUrl;
  final String? bio;
  final bool isFriend;

  UserSummary withFriend(bool value) => UserSummary(
        id: id,
        displayName: displayName,
        handle: handle,
        avatarUrl: avatarUrl,
        bio: bio,
        isFriend: value,
      );

  static UserSummary fromMap(Map<String, dynamic> m, {bool isFriend = false}) {
    final first = m['first_name'] as String? ?? '';
    final last = m['last_name'] as String? ?? '';
    final full = '$first $last'.trim();
    return UserSummary(
      id: m['id'] as String,
      displayName: full.isNotEmpty ? full : (m['username'] as String? ?? 'User'),
      handle: m['username'] as String?,
      avatarUrl: m['avatar_url'] as String?,
      bio: m['bio'] as String?,
      isFriend: isFriend,
    );
  }

  String get initials {
    final parts = displayName.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
  }
}

// ── Controls ──────────────────────────────────────────────────────────────────

/// CONTROL — FollowUser: creates a mutual friendship (A→B + B→A rows) (US24).
/// Invalidates friendIds + feed so the new friend's posts appear.
class FollowUser {
  FollowUser(this._ref);

  final Ref _ref;

  Future<void> call(String targetId) async {
    final userId = _ref.read(currentUserIdProvider)!;
    SeqLog.msg('follow-user', 'UserProfileScreen', 'FollowUser',
        'follow($targetId)');
    SeqLog.msg('follow-user', 'FollowUser', 'SocialGateway',
        'followUser($userId, $targetId)');
    await _ref.read(socialGatewayProvider).followUser(userId, targetId);
    _ref.invalidate(friendIdsProvider);
    _ref.invalidate(feedProvider);
    _ref.invalidate(friendsProvider);
  }
}

final followUserProvider = Provider<FollowUser>(FollowUser.new);

/// CONTROL — UnfollowUser: removes both directions of the mutual friendship (US24).
class UnfollowUser {
  UnfollowUser(this._ref);

  final Ref _ref;

  Future<void> call(String targetId) async {
    final userId = _ref.read(currentUserIdProvider)!;
    SeqLog.msg('unfollow-user', 'UserProfileScreen', 'UnfollowUser',
        'unfollow($targetId)');
    SeqLog.msg('unfollow-user', 'UnfollowUser', 'SocialGateway',
        'unfollowUser($userId, $targetId)');
    await _ref.read(socialGatewayProvider).unfollowUser(userId, targetId);
    _ref.invalidate(friendIdsProvider);
    _ref.invalidate(feedProvider);
    _ref.invalidate(friendsProvider);
  }
}

final unfollowUserProvider = Provider<UnfollowUser>(UnfollowUser.new);

// ── Read-side providers ───────────────────────────────────────────────────────

/// Current user's friend list (used by the Friends modal on #11 Social).
final friendsProvider = FutureProvider<List<UserSummary>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const [];
  SeqLog.msg('view-friends', 'SocialTab', 'SocialGateway',
      'fetchFriendProfiles($userId)');
  final rows =
      await ref.read(socialGatewayProvider).fetchFriendProfiles(userId);
  return rows.map((m) => UserSummary.fromMap(m, isFriend: true)).toList();
});

/// Whether the current user is friends with [targetId].
/// Keyed by targetId; invalidated by FollowUser / UnfollowUser.
final isFriendProvider =
    FutureProvider.family<bool, String>((ref, targetId) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return false;
  ref.watch(friendIdsProvider); // re-evaluate when friend list changes
  return ref.read(socialGatewayProvider).isFriend(userId, targetId);
});

/// User search results for the "Find friends" pill on #11 Social.
/// The search query is held in [userSearchQueryProvider].
class UserSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  void set(String q) => state = q;
}

final userSearchQueryProvider =
    NotifierProvider<UserSearchQueryNotifier, String>(UserSearchQueryNotifier.new);

final userSearchResultsProvider =
    FutureProvider<List<UserSummary>>((ref) async {
  final query = ref.watch(userSearchQueryProvider);
  if (query.trim().isEmpty) return const [];
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const [];
  final friendIds = await ref.watch(friendIdsProvider.future);
  final friendSet = friendIds.toSet();
  SeqLog.msg('search-users', 'SocialTab', 'SocialGateway',
      'searchUsers($query)');
  final rows =
      await ref.read(socialGatewayProvider).searchUsers(query, userId);
  return rows
      .map((m) => UserSummary.fromMap(m, isFriend: friendSet.contains(m['id'])))
      .toList();
});

/// Public profile view model for #11.2 User Profile.
/// Keyed by userId.
final userProfileProvider =
    FutureProvider.family<UserSummary, String>((ref, userId) async {
  SeqLog.msg('view-user-profile', 'UserProfileScreen', 'SocialGateway',
      'fetchUserById($userId)');
  final map = await ref.read(socialGatewayProvider).fetchUserById(userId);
  final currentId = ref.watch(currentUserIdProvider);
  bool isFriend = false;
  if (currentId != null && currentId != userId) {
    isFriend =
        await ref.read(socialGatewayProvider).isFriend(currentId, userId);
  }
  return UserSummary.fromMap(map, isFriend: isFriend);
});

/// Workout count for a given user (shown on #11.2 stats tile).
final userWorkoutCountProvider =
    FutureProvider.family<int, String>((ref, userId) async {
  return ref.read(socialGatewayProvider).fetchUserWorkoutCount(userId);
});

/// Active-days count for a given user (shown on #11.2 stats tile).
final userActiveDaysProvider =
    FutureProvider.family<int, String>((ref, userId) async {
  return ref.read(socialGatewayProvider).fetchUserActiveDays(userId);
});

/// Friend count for a given user (shown on #11.2 stats tile).
final userFriendCountProvider =
    FutureProvider.family<int, String>((ref, userId) async {
  return ref.read(socialGatewayProvider).fetchUserFriendCount(userId);
});

/// Posts authored by [userId] (Recent Posts section on #11.2).
final userPostsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, userId) async {
  SeqLog.msg('view-user-profile', 'UserProfileScreen', 'SocialGateway',
      'fetchUserPosts($userId)');
  return ref.read(socialGatewayProvider).fetchUserPosts(userId);
});
