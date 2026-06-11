import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wise_workout/boundaries/gateways/ai_gateway.dart';
import 'package:wise_workout/boundaries/gateways/auth_gateway.dart';
import 'package:wise_workout/boundaries/gateways/feedback_gateway.dart';
import 'package:wise_workout/boundaries/gateways/fitness_gateway.dart';
import 'package:wise_workout/boundaries/gateways/profile_gateway.dart';
import 'package:wise_workout/boundaries/gateways/social_gateway.dart';
import 'package:wise_workout/boundaries/gateways/social_share_gateway.dart';
import 'package:wise_workout/boundaries/gateways/workout_data_source.dart';
import 'package:wise_workout/boundaries/gateways/workout_gateway.dart';
import 'package:wise_workout/entities/enums.dart';
import 'package:wise_workout/entities/fitness_goal.dart';
import 'package:wise_workout/entities/fitness_profile.dart';
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
  StartSessionCall(this.userId, this.workoutTypeId);
  final String userId;
  final String workoutTypeId;
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
  Future<WorkoutSession> startSession({required String userId, required String workoutTypeId}) async {
    startSessionCalls.add(StartSessionCall(userId, workoutTypeId));
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
}

/// Fake SocialGateway — records created/deleted posts.
class FakeSocialGateway implements SocialGateway {
  final createdPosts = <Map<String, String?>>[];
  final deletedIds = <String>[];

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

/// Common test fixtures.
const runningType = WorkoutType(id: 'wt-run', name: 'Running', slug: 'running');
const yogaType = WorkoutType(id: 'wt-yoga', name: 'Yoga', slug: 'yoga');
