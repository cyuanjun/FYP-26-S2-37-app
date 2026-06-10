import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wise_workout/boundaries/gateways/ai_gateway.dart';
import 'package:wise_workout/boundaries/gateways/auth_gateway.dart';
import 'package:wise_workout/boundaries/gateways/workout_data_source.dart';
import 'package:wise_workout/boundaries/gateways/workout_gateway.dart';
import 'package:wise_workout/entities/enums.dart';
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
  Future<List<WorkoutSession>> listEndedSessions(String userId) async => ended;

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

/// Common test fixtures.
const runningType = WorkoutType(id: 'wt-run', name: 'Running', slug: 'running');
const yogaType = WorkoutType(id: 'wt-yoga', name: 'Yoga', slug: 'yoga');
