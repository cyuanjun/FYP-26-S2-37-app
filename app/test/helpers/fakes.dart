import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wise_workout/boundaries/gateways/ai_gateway.dart';
import 'package:wise_workout/boundaries/gateways/auth_gateway.dart';
import 'package:wise_workout/boundaries/gateways/device_gateway.dart';
import 'package:wise_workout/boundaries/gateways/feedback_gateway.dart';
import 'package:wise_workout/boundaries/gateways/fitness_gateway.dart';
import 'package:wise_workout/boundaries/gateways/plan_gateway.dart';
import 'package:wise_workout/boundaries/gateways/profile_gateway.dart';
import 'package:wise_workout/boundaries/gateways/social_gateway.dart';
import 'package:wise_workout/boundaries/gateways/social_share_gateway.dart';
import 'package:wise_workout/boundaries/gateways/workout_data_source.dart';
import 'package:wise_workout/boundaries/gateways/workout_gateway.dart';
import 'package:wise_workout/entities/connected_device.dart';
import 'package:wise_workout/entities/challenge.dart';
import 'package:wise_workout/entities/enums.dart';
import 'package:wise_workout/entities/feed_post.dart';
import 'package:wise_workout/entities/post_comment.dart';
import 'package:wise_workout/entities/public_profile.dart';
import 'package:wise_workout/entities/fitness_goal.dart';
import 'package:wise_workout/entities/fitness_plan.dart';
import 'package:wise_workout/entities/fitness_profile.dart';
import 'package:wise_workout/entities/planned_workout.dart';
import 'package:wise_workout/entities/health_tag.dart';
import 'package:wise_workout/entities/profile.dart';
import 'package:wise_workout/entities/workout_session.dart';
import 'package:wise_workout/entities/workout_type.dart';

/// Fake AuthGateway — no Supabase. Drives Authenticate success/failure paths.
class FakeAuthGateway implements AuthGateway {
  FakeAuthGateway({this.throwOnSignIn = false});

  bool throwOnSignIn;
  int signInCount = 0;
  int signOutCount = 0;

  @override
  Session? get currentSession => null;
  @override
  User? get currentUser => null;
  @override
  bool get isSignedIn => false;
  @override
  Stream<AuthState> get onAuthStateChange => const Stream.empty();

  @override
  Future<AuthResponse> signInWithPassword({required String email, required String password}) async {
    signInCount++;
    if (throwOnSignIn) {
      throw const AuthException('Invalid login credentials');
    }
    return AuthResponse(session: null, user: null);
  }

  @override
  Future<void> signOut() async => signOutCount++;

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    resetEmails.add(email);
    if (throwOnReset) throw const AuthException('rate limited');
  }

  bool throwOnReset = false;
  final resetEmails = <String>[];
}

class StartSessionCall {
  StartSessionCall(this.userId, this.workoutTypeId, [this.connectedDeviceId]);
  final String userId;
  final String workoutTypeId;
  final String? connectedDeviceId;
}

class EndSessionCall {
  EndSessionCall(this.sessionId, this.metrics);
  final String sessionId;
  final Map<String, dynamic> metrics;
}

/// Fake WorkoutGateway — records calls, returns canned entities/maps.
class FakeWorkoutGateway implements WorkoutGateway {
  FakeWorkoutGateway({
    this.types = const [],
    this.endResult = const {'xp_gained': 20, 'new_level': 1, 'leveled_up': false, 'current_streak': 1},
    this.ended = const [],
  });

  List<WorkoutType> types;
  Map<String, dynamic> endResult;
  List<WorkoutSession> ended;

  final startSessionCalls = <StartSessionCall>[];
  final endSessionCalls = <EndSessionCall>[];
  final deletedIds = <String>[];
  final updateCalls = <String>[];

  @override
  Future<List<WorkoutType>> listWorkoutTypes() async => types;

  @override
  Future<WorkoutType> addCustomWorkoutType(
      {required String userId, required String name}) async {
    final t = WorkoutType(
        id: 'wt-custom-${types.length + 1}',
        name: name.trim(),
        slug: name.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-'),
        isCustom: true);
    types = [...types, t];
    return t;
  }

  @override
  Future<WorkoutSession> startSession(
      {required String userId, required String workoutTypeId, String? connectedDeviceId}) async {
    startSessionCalls.add(StartSessionCall(userId, workoutTypeId, connectedDeviceId));
    return WorkoutSession(
      id: 'session-${startSessionCalls.length}',
      userId: userId,
      workoutTypeId: workoutTypeId,
      startedAt: DateTime(2026, 6, 10, 10),
    );
  }

  @override
  Future<Map<String, dynamic>> endSession({
    required String sessionId,
    required Map<String, dynamic> metrics,
  }) async {
    endSessionCalls.add(EndSessionCall(sessionId, metrics));
    return endResult;
  }

  @override
  Future<void> updateSummary({
    required String sessionId,
    String? customName,
    FeelRating? feelRating,
    String? notes,
  }) async {
    updateCalls.add(sessionId);
  }

  @override
  Future<List<WorkoutSession>> listEndedSessions(String userId, {DateTime? from}) async {
    listFroms.add(from);
    if (from == null) return ended;
    return ended.where((s) => !s.startedAt.isBefore(from)).toList();
  }

  /// The `from` bound of each list call (null = lifetime) — asserts the cap.
  final listFroms = <DateTime?>[];

  @override
  Future<bool> hasEndedSessionsBefore(String userId, DateTime before) async =>
      ended.any((s) => s.startedAt.isBefore(before));

  @override
  Future<void> deleteSession(String sessionId) async => deletedIds.add(sessionId);
}

/// Fake WorkoutDataSource — manually pump metrics, no real sensors.
class FakeWorkoutDataSource implements WorkoutDataSource {
  final _controller = StreamController<LiveMetrics>.broadcast();
  bool started = false;
  bool stopped = false;

  @override
  final List<Map<String, dynamic>> trackPoints = [];

  @override
  Stream<LiveMetrics> get metrics => _controller.stream;

  @override
  Future<void> start() async => started = true;

  @override
  Future<void> stop() async => stopped = true;

  void emit(LiveMetrics m) => _controller.add(m);

  void dispose() => _controller.close();
}

/// Fake AiGateway — returns a canned summary or throws.
class FakeAiGateway implements AiGateway {
  FakeAiGateway({this.result = const ProgressSummary(text: 'You trained 2x this week.', model: 'stub'), this.throwOnCall = false});

  ProgressSummary result;
  bool throwOnCall;
  int calls = 0;

  @override
  Future<ProgressSummary> summariseProgress({String range = 'week'}) async {
    calls++;
    if (throwOnCall) throw Exception('AI unavailable');
    return result;
  }

  Map<String, dynamic> planResult = {
    'name': 'Personalised plan',
    'description': 'stub plan',
    'duration_weeks': 4,
    'workouts_per_week': 3,
    'model': 'stub',
    'workouts': [
      {'slug': 'running', 'day_of_week': 1, 'duration_minutes': 30, 'name': 'Run', 'descriptor': ''},
    ],
  };
  int planCalls = 0;

  @override
  Future<Map<String, dynamic>> suggestPlan() async {
    planCalls++;
    if (throwOnCall) throw Exception('AI unavailable');
    return planResult;
  }
}

/// Fake SocialGateway — in-memory posts/likes/comments/friends with recorded
/// call lists, enough to drive the feed + post-detail controls.
class FakeSocialGateway implements SocialGateway {
  final createdPosts = <Map<String, String?>>[];
  final deletedIds = <String>[];

  /// Canned feed rows returned by [fetchFeed] / [fetchFeedPost].
  var feed = <FeedPost>[];
  var friends = <String>[];
  var comments = <PostComment>[];

  final likeCalls = <(String, String)>[];
  final unlikeCalls = <(String, String)>[];
  final addedComments = <Map<String, String>>[];
  final deletedCommentIds = <String>[];
  final bodyUpdates = <(String, String?)>[];
  int fetchFeedCalls = 0;
  List<String>? lastFeedScope;

  @override
  Future<List<FeedPost>> fetchFeed({
    required String userId,
    required List<String> friendIds,
    int limit = 50,
  }) async {
    fetchFeedCalls++;
    lastFeedScope = [userId, ...friendIds];
    return feed;
  }

  @override
  Future<FeedPost?> fetchFeedPost(String postId, {required String me}) async =>
      feed.where((f) => f.post.id == postId).firstOrNull;

  @override
  Future<List<PostComment>> listComments(String postId) async =>
      comments.where((c) => c.postId == postId).toList();

  @override
  Future<void> likePost(String postId, String userId) async =>
      likeCalls.add((postId, userId));

  @override
  Future<void> unlikePost(String postId, String userId) async =>
      unlikeCalls.add((postId, userId));

  @override
  Future<PostComment> addComment({
    required String postId,
    required String userId,
    required String body,
  }) async {
    addedComments.add({'postId': postId, 'userId': userId, 'body': body});
    final comment = PostComment(
      id: 'comment-${addedComments.length}',
      postId: postId,
      userId: userId,
      body: body.trim(),
      createdAt: DateTime.utc(2026, 7, 6),
    );
    comments = [...comments, comment];
    return comment;
  }

  @override
  Future<void> deleteComment(String commentId) async =>
      deletedCommentIds.add(commentId);

  @override
  Future<void> updatePostBody(String postId, String? body) async =>
      bodyUpdates.add((postId, body));

  @override
  Future<List<String>> friendIds(String userId) async => friends;

  /// Canned profiles for search / profile / friends-list reads.
  var profiles = <PublicProfile>[];
  var userStatsResult = (workouts: 0, activeDays: 0);
  final addFriendCalls = <String>[];
  final removeFriendCalls = <String>[];
  final searchQueries = <String>[];

  @override
  Future<void> addFriend(String targetId) async {
    addFriendCalls.add(targetId);
    if (!friends.contains(targetId)) friends = [...friends, targetId];
  }

  @override
  Future<void> removeFriend(String targetId) async {
    removeFriendCalls.add(targetId);
    friends = friends.where((f) => f != targetId).toList();
  }

  @override
  Future<bool> isFriend(String me, String other) async =>
      friends.contains(other);

  @override
  Future<List<PublicProfile>> listFriends(String userId) async =>
      profiles.where((p) => friends.contains(p.id)).toList();

  @override
  Future<List<PublicProfile>> searchUsers(String query,
      {required String excludeId}) async {
    searchQueries.add(query);
    return profiles
        .where((p) =>
            p.id != excludeId &&
            (p.displayName.toLowerCase().contains(query.toLowerCase()) ||
                (p.username ?? '').toLowerCase().contains(query.toLowerCase())))
        .toList();
  }

  @override
  Future<PublicProfile?> fetchPublicProfile(String userId) async =>
      profiles.where((p) => p.id == userId).firstOrNull;

  @override
  Future<({int workouts, int activeDays})> userStats(String userId) async =>
      userStatsResult;

  @override
  Future<List<FeedPost>> listUserPosts(String userId,
          {required String me, int limit = 20}) async =>
      feed.where((f) => f.post.userId == userId).toList();

  /// Canned challenges: (challenge, participant ids).
  var challenges = <(Challenge, List<String>)>[];
  var leaderboardRows = <LeaderboardRow>[];
  final joinCalls = <(String, String)>[];
  final leaveCalls = <(String, String)>[];
  final createdChallenges = <Map<String, dynamic>>[];

  @override
  Future<List<(Challenge, List<String>)>> listChallenges() async => challenges;

  @override
  Future<List<LeaderboardRow>> leaderboards(List<String> challengeIds) async =>
      leaderboardRows
          .where((r) => challengeIds.contains(r.challengeId))
          .toList();

  @override
  Future<List<PublicProfile>> profilesByIds(List<String> ids) async =>
      profiles.where((p) => ids.contains(p.id)).toList();

  @override
  Future<void> joinChallenge(String challengeId, String userId) async {
    joinCalls.add((challengeId, userId));
    challenges = [
      for (final (c, ps) in challenges)
        c.id == challengeId ? (c, [...ps, userId]) : (c, ps),
    ];
  }

  @override
  Future<void> leaveChallenge(String challengeId, String userId) async {
    leaveCalls.add((challengeId, userId));
    challenges = [
      for (final (c, ps) in challenges)
        c.id == challengeId
            ? (c, ps.where((p) => p != userId).toList())
            : (c, ps),
    ];
  }

  @override
  Future<Challenge> createChallenge({
    required String userId,
    required Map<String, dynamic> fields,
  }) async {
    createdChallenges.add(fields);
    final challenge = Challenge(
      id: 'ch-${createdChallenges.length}',
      createdByUserId: userId,
      name: fields['name'] as String,
      shortName: fields['short_name'] as String,
      icon: fields['icon'] as String? ?? '⚡',
      metricKind: fields['metric_kind'] == 'best_of'
          ? ChallengeMetricKind.bestOf
          : ChallengeMetricKind.accumulator,
      metric: ChallengeMetric.totalSessions,
      targetValue: fields['target_value'] as int?,
      startedAt: DateTime.utc(2026, 7, 1),
      endedAt: DateTime.utc(2026, 7, 31),
    );
    challenges = [...challenges, (challenge, [userId])];
    return challenge;
  }

  @override
  Future<String> createWorkoutSharePost({
    required String userId,
    required String workoutSessionId,
    String? body,
  }) async {
    createdPosts.add({'userId': userId, 'sessionId': workoutSessionId, 'body': body});
    return 'post-${createdPosts.length}';
  }

  @override
  Future<void> deletePost(String postId) async => deletedIds.add(postId);
}

/// Fake SocialShareGateway — records platform + text passed to the OS share.
class FakeSocialShareGateway implements SocialShareGateway {
  final shares = <(SocialPlatform, String)>[];

  @override
  Future<void> shareTo(SocialPlatform platform, {required String text}) async {
    shares.add((platform, text));
  }
}

/// Fake FitnessGateway — in-memory fitness profile / goal / tag catalog.
class FakeFitnessGateway implements FitnessGateway {
  FakeFitnessGateway({FitnessProfile? profile, this.activeGoal, List<HealthTag>? tags})
      : profile = profile ?? const FitnessProfile(id: 'user-1'),
        tags = tags ?? [];

  FitnessProfile profile;
  FitnessGoal? activeGoal;
  List<HealthTag> tags;
  bool throwOnWrite = false;

  final profilePatches = <Map<String, dynamic>>[];
  final goalUpserts = <Map<String, dynamic>>[];

  @override
  Future<FitnessProfile> fetchFitnessProfile(String userId) async => profile;

  @override
  Future<void> updateFitnessProfile(String userId, Map<String, dynamic> patch) async {
    if (throwOnWrite) throw Exception('write failed');
    profilePatches.add(patch);
  }

  @override
  Future<List<HealthTag>> listHealthTags() async => tags;

  @override
  Future<HealthTag> addCustomHealthTag({
    required String userId,
    required HealthTagKind kind,
    required String name,
  }) async {
    final tag = HealthTag(
        id: 'tag-${tags.length + 1}', kind: kind, name: name, isCustom: true, createdByUserId: userId);
    tags = [...tags, tag];
    return tag;
  }

  @override
  Future<FitnessGoal?> fetchActiveGoal(String userId) async => activeGoal;

  @override
  Future<FitnessGoal> upsertActiveGoal({
    required String userId,
    required Map<String, dynamic> values,
  }) async {
    if (throwOnWrite) throw Exception('write failed');
    goalUpserts.add(values);
    return FitnessGoal(
      id: activeGoal?.id ?? 'goal-1',
      userId: userId,
      primaryGoal: PrimaryGoal.maintainFitness,
    );
  }
}

/// Fake ProfileGateway — records preference writes.
class FakeProfileGateway implements ProfileGateway {
  FakeProfileGateway({this.profile});

  Profile? profile;
  final unitWrites = <PreferredUnits>[];
  final prefsWrites = <Map<String, dynamic>>[];

  @override
  Future<Profile> fetchProfile(String id) async =>
      profile ?? Profile(id: id, email: 'x@test', role: UserRole.free);

  @override
  Future<void> updatePreferredUnits(String id, PreferredUnits units) async =>
      unitWrites.add(units);

  @override
  Future<void> updateNotificationPrefs(String id, Map<String, dynamic> prefs) async =>
      prefsWrites.add(prefs);

  final onboardingCompletions = <String>[];

  @override
  Future<void> completeOnboarding(String id) async => onboardingCompletions.add(id);

  final nameWrites = <(String, String?)>[];

  @override
  Future<void> updateName(String id, {required String firstName, String? lastName}) async =>
      nameWrites.add((firstName, lastName));
}

/// Fake FeedbackGateway — records submissions, optionally throws.
class FakeFeedbackGateway implements FeedbackGateway {
  bool throwOnSubmit = false;
  final submissions = <(String, FeedbackCategory, String)>[];

  @override
  Future<void> submitFeedback({
    required String userId,
    required FeedbackCategory category,
    required String body,
  }) async {
    if (throwOnSubmit) throw Exception('insert failed');
    submissions.add((userId, category, body));
  }
}

/// Fake PlanGateway — records inserted plans/workouts in memory.
class FakePlanGateway implements PlanGateway {
  FitnessPlan? activePlan;
  List<FitnessPlan> plans = [];
  List<PlannedWorkout> planned = [];
  bool throwOnInsert = false;
  bool throwOnSelect = false;

  final insertedPlans = <Map<String, dynamic>>[];
  final insertedWorkouts = <List<Map<String, dynamic>>>[];
  final selectedPlanIds = <String>[];

  @override
  Future<FitnessPlan?> fetchActivePlan(String userId) async => activePlan;

  @override
  Future<FitnessPlan?> fetchPlan(String planId) async {
    for (final p in [
      ?activePlan,
      ...plans,
    ]) {
      if (p.id == planId) return p;
    }
    return null;
  }

  @override
  Future<List<FitnessPlan>> listPlans(String userId) async {
    return [
      ?activePlan,
      ...plans,
    ].where((p) => p.userId == userId).toList();
  }

  @override
  Future<List<PlannedWorkout>> listPlannedWorkouts(String planId) async => planned;

  @override
  Future<FitnessPlan> insertPlan({
    required String userId,
    required String fitnessGoalId,
    required Map<String, dynamic> plan,
    required List<Map<String, dynamic>> workouts,
  }) async {
    if (throwOnInsert) throw Exception('insert failed');
    insertedPlans.add(plan);
    insertedWorkouts.add(workouts);
    activePlan = FitnessPlan(
      id: 'plan-${insertedPlans.length}',
      userId: userId,
      fitnessGoalId: fitnessGoalId,
      name: plan['name'] as String? ?? 'Plan',
      description: plan['description'] as String?,
      durationWeeks: plan['duration_weeks'] as int? ?? 4,
      workoutsPerWeek: plan['workouts_per_week'] as int? ?? 3,
      generationStrategy: plan['generation_strategy'] == 'personalised'
          ? GenerationStrategy.personalised
          : GenerationStrategy.basic,
    );
    return activePlan!;
  }

  @override
  Future<void> setActivePlan({required String userId, required String planId}) async {
    if (throwOnSelect) throw Exception('select failed');
    selectedPlanIds.add(planId);
    final all = [
      ?activePlan,
      ...plans,
    ];
    FitnessPlan? selected;
    for (final p in all) {
      if (p.id == planId && p.userId == userId) {
        selected = p;
        break;
      }
    }
    if (selected == null) return;
    activePlan = selected.copyWith(isActive: true, startedAt: DateTime.now());
    plans = all
        .where((p) => p.id != planId)
        .map((p) => p.copyWith(isActive: false))
        .toList();
  }
}

/// Fake DeviceGateway — in-memory connected_devices (#7.1).
class FakeDeviceGateway implements DeviceGateway {
  final devices = <ConnectedDevice>[];
  int ensureCalls = 0;
  final syncedIds = <String>[];

  @override
  Future<List<ConnectedDevice>> listDevices(String userId) async =>
      devices.where((d) => d.userId == userId).toList();

  @override
  Future<ConnectedDevice> ensurePhoneSensors(String userId) async {
    ensureCalls++;
    final existing = devices.where(
        (d) => d.userId == userId && d.deviceType == DeviceType.phoneSensors);
    if (existing.isNotEmpty) return existing.first;
    final d = ConnectedDevice(
        id: 'dev-phone-$userId',
        userId: userId,
        deviceType: DeviceType.phoneSensors,
        deviceName: 'Phone sensors');
    devices.add(d);
    return d;
  }

  @override
  Future<ConnectedDevice> addDevice(
      {required String userId, required DeviceType type, required String name}) async {
    final d = ConnectedDevice(
        id: 'dev-${devices.length + 1}',
        userId: userId,
        deviceType: type,
        deviceName: name.trim(),
        lastSyncedAt: DateTime(2026, 6, 12));
    devices.add(d);
    return d;
  }

  @override
  Future<void> setActive(String deviceId, bool active) async {
    final i = devices.indexWhere((d) => d.id == deviceId);
    if (i >= 0) devices[i] = devices[i].copyWith(isActive: active);
  }

  @override
  Future<void> removeDevice(String deviceId) async =>
      devices.removeWhere((d) => d.id == deviceId);

  @override
  Future<void> touchLastSynced(String deviceId) async => syncedIds.add(deviceId);
}

/// Common test fixtures.
const runningType = WorkoutType(id: 'wt-run', name: 'Running', slug: 'running');
const yogaType = WorkoutType(id: 'wt-yoga', name: 'Yoga', slug: 'yoga');
