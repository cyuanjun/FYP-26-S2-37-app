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
import 'package:wise_workout/entities/enums.dart';
import 'package:wise_workout/entities/fitness_goal.dart';
import 'package:wise_workout/entities/fitness_plan.dart';
import 'package:wise_workout/entities/fitness_profile.dart';
import 'package:wise_workout/entities/planned_workout.dart';
import 'package:wise_workout/entities/health_tag.dart';
import 'package:wise_workout/entities/challenge.dart';
import 'package:wise_workout/entities/post.dart';
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

/// Fake SocialGateway — in-memory stub covering all SocialGateway methods.
class FakeSocialGateway implements SocialGateway {
  // ── Posts ────────────────────────────────────────────────────────────────
  final createdPosts = <Map<String, String?>>[];
  final deletedIds = <String>[];
  final updatedBodies = <(String, String?)>[];

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

  @override
  Future<void> updatePostBody(String postId, String? body) async =>
      updatedBodies.add((postId, body));

  // ── Feed ─────────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> feedPosts = [];
  Map<String, dynamic>? postById;

  @override
  Future<List<String>> fetchFriendIds(String userId) async =>
      friends[userId]?.toList() ?? [];

  @override
  Future<List<Map<String, dynamic>>> fetchFeedPosts(
          List<String> feedUserIds) async =>
      feedPosts;

  @override
  Future<Map<String, dynamic>> fetchPostById(String postId) async =>
      postById ?? {'id': postId, 'kind': 'workout_share', 'user_id': 'u1',
                   'created_at': DateTime.now().toIso8601String()};

  // ── Likes ────────────────────────────────────────────────────────────────
  final likes = <String, Set<String>>{}; // postId → Set<userId>

  @override
  Future<void> addLike(String postId, String userId) async =>
      (likes[postId] ??= {}).add(userId);

  @override
  Future<void> removeLike(String postId, String userId) async =>
      likes[postId]?.remove(userId);

  @override
  Future<Set<String>> fetchMyLikedPostIds(
          String userId, List<String> postIds) async =>
      postIds.where((id) => likes[id]?.contains(userId) == true).toSet();

  @override
  Future<Map<String, int>> fetchLikeCounts(List<String> postIds) async =>
      {for (final id in postIds) id: likes[id]?.length ?? 0};

  // ── Comments ─────────────────────────────────────────────────────────────
  final comments = <String, List<Map<String, dynamic>>>{}; // postId → rows
  final deletedCommentIds = <String>[];

  @override
  Future<Map<String, int>> fetchCommentCounts(List<String> postIds) async =>
      {for (final id in postIds) id: comments[id]?.length ?? 0};

  @override
  Future<List<Map<String, dynamic>>> fetchPostComments(String postId) async =>
      comments[postId] ?? [];

  @override
  Future<PostComment> addPostComment({
    required String postId,
    required String userId,
    required String body,
  }) async {
    final commentId = 'comment-${DateTime.now().microsecondsSinceEpoch}';
    final now = DateTime.now();
    final c = PostComment(
      id: commentId,
      postId: postId,
      userId: userId,
      body: body,
      createdAt: now,
    );
    (comments[postId] ??= []).add({
      'id': commentId, 'post_id': postId, 'user_id': userId, 'body': body,
      'created_at': now.toIso8601String(),
    });
    return c;
  }

  @override
  Future<void> deletePostComment(String commentId) async {
    deletedCommentIds.add(commentId);
    for (final list in comments.values) {
      list.removeWhere((m) => m['id'] == commentId);
    }
  }

  // ── Friends ──────────────────────────────────────────────────────────────
  // Bidirectional: friends['a'] contains 'b' AND friends['b'] contains 'a'.
  final friends = <String, Set<String>>{};
  final followCalls = <(String, String)>[];
  final unfollowCalls = <(String, String)>[];

  @override
  Future<void> followUser(String followerId, String followingId) async {
    followCalls.add((followerId, followingId));
    (friends[followerId] ??= {}).add(followingId);
    (friends[followingId] ??= {}).add(followerId);
  }

  @override
  Future<void> unfollowUser(String followerId, String followingId) async {
    unfollowCalls.add((followerId, followingId));
    friends[followerId]?.remove(followingId);
    friends[followingId]?.remove(followerId);
  }

  @override
  Future<bool> isFriend(String userId, String targetId) async =>
      friends[userId]?.contains(targetId) == true;

  @override
  Future<List<Map<String, dynamic>>> fetchFriendProfiles(
      String userId) async {
    final ids = friends[userId] ?? {};
    return ids
        .map((id) => {'id': id, 'username': id, 'first_name': id,
                      'last_name': '', 'avatar_url': null})
        .toList();
  }

  List<Map<String, dynamic>> searchResults = [];

  @override
  Future<List<Map<String, dynamic>>> searchUsers(
          String query, String excludeUserId) async =>
      searchResults;

  // ── User profile ─────────────────────────────────────────────────────────
  Map<String, dynamic> userById = {
    'id': 'u1', 'username': 'test', 'first_name': 'Test',
    'last_name': 'User', 'avatar_url': null, 'bio': null,
  };
  int workoutCount = 0;
  int activeDays = 0;
  List<Map<String, dynamic>> userPosts = [];

  @override
  Future<Map<String, dynamic>> fetchUserById(String userId) async => userById;

  @override
  Future<int> fetchUserWorkoutCount(String userId) async => workoutCount;

  @override
  Future<int> fetchUserActiveDays(String userId) async => activeDays;

  @override
  Future<int> fetchUserFriendCount(String userId) async =>
      friends[userId]?.length ?? 0;

  @override
  Future<List<Map<String, dynamic>>> fetchUserPosts(String userId) async =>
      userPosts;

  // ── Challenges ───────────────────────────────────────────────────────────
  final challengeStore = <String, Challenge>{};
  final participantStore = <String, Set<String>>{}; // challengeId → userIds
  final joinCalls = <(String, String)>[];
  final leaveCalls = <(String, String)>[];
  List<WorkoutSession> sessionWindow = [];

  @override
  Future<List<Challenge>> fetchJoinedChallenges(String userId) async =>
      challengeStore.entries
          .where((e) => participantStore[e.key]?.contains(userId) == true)
          .map((e) => e.value)
          .toList();

  @override
  Future<List<Challenge>> fetchActiveChallenges() async =>
      challengeStore.values.toList(); // all stored challenges count as active in tests

  @override
  Future<List<Challenge>> fetchPastChallenges(String userId) async =>
      challengeStore.entries
          .where((e) => participantStore[e.key]?.contains(userId) == true)
          .map((e) => e.value)
          .toList();

  @override
  Future<Challenge> fetchChallengeById(String challengeId) async =>
      challengeStore[challengeId]!;

  @override
  Future<Challenge> createChallenge({
    required String creatorId,
    required Map<String, dynamic> data,
  }) async {
    final id = 'chal-${challengeStore.length + 1}';
    final c = Challenge(
      id: id,
      createdByUserId: creatorId,
      name: data['name'] as String,
      shortName: (data['name'] as String).substring(0, 3).toUpperCase(),
      description: data['description'] as String?,
      icon: '🏆',
      startedAt: DateTime.parse(data['started_at'] as String),
      endedAt: DateTime.parse(data['ended_at'] as String),
      metricKind: ChallengeMetricKind.accumulator,
      metric: ChallengeMetric.totalDistance,
      visibility: ChallengeVisibility.public,
    );
    challengeStore[id] = c;
    await joinChallenge(id, creatorId);
    return c;
  }

  @override
  Future<void> joinChallenge(String challengeId, String userId) async {
    joinCalls.add((challengeId, userId));
    (participantStore[challengeId] ??= {}).add(userId);
  }

  @override
  Future<void> leaveChallenge(String challengeId, String userId) async {
    leaveCalls.add((challengeId, userId));
    participantStore[challengeId]?.remove(userId);
  }

  @override
  Future<Set<String>> fetchParticipantIds(String challengeId) async =>
      Set.of(participantStore[challengeId] ?? {});

  @override
  Future<List<Map<String, dynamic>>> fetchParticipantsWithProfiles(
          String challengeId) async =>
      (participantStore[challengeId] ?? {})
          .map((uid) => {
                'user_id': uid,
                'profile': {
                  'id': uid, 'username': uid, 'first_name': uid,
                  'last_name': '', 'avatar_url': null,
                },
              })
          .toList();

  @override
  Future<List<WorkoutSession>> fetchSessionsInWindow({
    required String userId,
    required DateTime windowStart,
    required DateTime windowEnd,
    String? workoutTypeId,
  }) async =>
      sessionWindow
          .where((s) =>
              s.userId == userId &&
              !s.startedAt.isBefore(windowStart) &&
              !s.startedAt.isAfter(windowEnd))
          .toList();
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
