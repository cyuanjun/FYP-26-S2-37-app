import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../boundaries/gateways/workout_data_source.dart';
import '../boundaries/gateways/workout_gateway.dart';
import '../core/seq_log.dart';
import '../entities/workout_type.dart';
import 'authenticate.dart';
import 'workout_history.dart';

enum WorkoutStatus { idle, running, paused }

/// Live state the ActiveWorkoutScreen watches.
class ActiveWorkoutState {
  const ActiveWorkoutState({
    this.status = WorkoutStatus.idle,
    this.type,
    this.sessionId,
    this.elapsed = Duration.zero,
    this.distanceMeters = 0,
    this.steps = 0,
  });

  final WorkoutStatus status;
  final WorkoutType? type;
  final String? sessionId;
  final Duration elapsed;
  final double distanceMeters;
  final int steps;

  bool get isActive => status != WorkoutStatus.idle;

  ActiveWorkoutState copyWith({
    WorkoutStatus? status,
    WorkoutType? type,
    String? sessionId,
    Duration? elapsed,
    double? distanceMeters,
    int? steps,
  }) =>
      ActiveWorkoutState(
        status: status ?? this.status,
        type: type ?? this.type,
        sessionId: sessionId ?? this.sessionId,
        elapsed: elapsed ?? this.elapsed,
        distanceMeters: distanceMeters ?? this.distanceMeters,
        steps: steps ?? this.steps,
      );
}

/// CONTROL — orchestrates the StartWorkoutSession + EndWorkoutSession use cases
/// and the live timer/sensor aggregation for one recording session.
class ActiveWorkout extends Notifier<ActiveWorkoutState> {
  Timer? _timer;
  WorkoutDataSource? _source;
  StreamSubscription<LiveMetrics>? _metricsSub;
  Duration _accumulated = Duration.zero;
  DateTime? _segmentStart;

  @override
  ActiveWorkoutState build() {
    ref.onDispose(_teardown);
    return const ActiveWorkoutState();
  }

  Future<void> start(WorkoutType type) async {
    final userId = ref.read(currentUserIdProvider)!;
    SeqLog.msg('start-workout', 'ActiveWorkoutScreen', 'ActiveWorkout', 'start(${type.slug})');
    SeqLog.msg('start-workout', 'ActiveWorkout', 'WorkoutGateway', 'startSession');
    final session = await ref
        .read(workoutGatewayProvider)
        .startSession(userId: userId, workoutTypeId: type.id);

    _source = ref.read(workoutDataSourceFactoryProvider)();
    SeqLog.msg('start-workout', 'ActiveWorkout', 'WorkoutDataSource', 'start()');
    await _source!.start();
    _metricsSub = _source!.metrics.listen((m) {
      state = state.copyWith(distanceMeters: m.distanceMeters, steps: m.steps);
    });

    _accumulated = Duration.zero;
    _segmentStart = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.status == WorkoutStatus.running) {
        state = state.copyWith(elapsed: _elapsed());
      }
    });

    state = ActiveWorkoutState(
      status: WorkoutStatus.running,
      type: type,
      sessionId: session.id,
    );
  }

  void pause() {
    if (state.status != WorkoutStatus.running) return;
    _accumulated = _elapsed();
    _segmentStart = null;
    state = state.copyWith(status: WorkoutStatus.paused);
  }

  void resume() {
    if (state.status != WorkoutStatus.paused) return;
    _segmentStart = DateTime.now();
    state = state.copyWith(status: WorkoutStatus.running);
  }

  /// Stops capture and finalizes via the RPC. Returns the RPC result map
  /// (xp_gained, new_level, leveled_up, current_streak) for the summary screen.
  Future<Map<String, dynamic>> end() async {
    final sessionId = state.sessionId!;
    final type = state.type!;
    final elapsed = _elapsed();
    SeqLog.msg('end-workout', 'ActiveWorkoutScreen', 'ActiveWorkout', 'end($sessionId)');

    await _source?.stop();
    _timer?.cancel();
    await _metricsSub?.cancel();

    final metrics = <String, dynamic>{
      'duration_seconds': elapsed.inSeconds,
      if (type.isCardio) 'distance_meters': state.distanceMeters.round(),
      if (_source != null && _source!.trackPoints.isNotEmpty)
        'track_points': _source!.trackPoints,
    };

    SeqLog.msg('end-workout', 'ActiveWorkout', 'WorkoutGateway', 'endSession(rpc)');
    final result = await ref
        .read(workoutGatewayProvider)
        .endSession(sessionId: sessionId, metrics: metrics);

    _source = null;
    state = const ActiveWorkoutState();
    ref.invalidate(historyProvider);
    return result;
  }

  Duration _elapsed() {
    if (_segmentStart == null) return _accumulated;
    return _accumulated + DateTime.now().difference(_segmentStart!);
  }

  void _teardown() {
    _timer?.cancel();
    _metricsSub?.cancel();
    _source?.stop();
  }
}

final activeWorkoutProvider =
    NotifierProvider<ActiveWorkout, ActiveWorkoutState>(ActiveWorkout.new);
