import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../boundaries/gateways/ble_heart_rate_source.dart';
import '../boundaries/gateways/workout_data_source.dart';
import '../boundaries/gateways/workout_gateway.dart';
import '../core/seq_log.dart';
import '../entities/connected_device.dart';
import '../entities/enums.dart';
import '../entities/workout_type.dart';
import 'authenticate.dart';
import 'manage_connected_device.dart';
import 'view_profile.dart';
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
    this.heartRate,
    this.wearableName,
  });

  final WorkoutStatus status;
  final WorkoutType? type;
  final String? sessionId;
  final Duration elapsed;
  final double distanceMeters;
  final int steps;
  final int? heartRate;
  final String? wearableName;

  bool get isActive => status != WorkoutStatus.idle;

  ActiveWorkoutState copyWith({
    WorkoutStatus? status,
    WorkoutType? type,
    String? sessionId,
    Duration? elapsed,
    double? distanceMeters,
    int? steps,
    int? heartRate,
    String? wearableName,
  }) =>
      ActiveWorkoutState(
        status: status ?? this.status,
        type: type ?? this.type,
        sessionId: sessionId ?? this.sessionId,
        elapsed: elapsed ?? this.elapsed,
        distanceMeters: distanceMeters ?? this.distanceMeters,
        steps: steps ?? this.steps,
        heartRate: heartRate ?? this.heartRate,
        wearableName: wearableName ?? this.wearableName,
      );
}

/// CONTROL — orchestrates the StartWorkoutSession + EndWorkoutSession use cases
/// and the live timer/sensor aggregation for one recording session.
class ActiveWorkout extends Notifier<ActiveWorkoutState> {
  Timer? _timer;
  WorkoutDataSource? _source;
  ConnectedDevice? _wearable;
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

    // Capture source: phone sensors, plus the active wearable's HR stream
    // when one is paired (#7.1). The session records its source device.
    ConnectedDevice? wearable;
    ConnectedDevice? phone;
    try {
      wearable = await ref.read(activeWearableProvider.future);
      phone = await ref.read(phoneSensorsDeviceProvider.future);
    } catch (_) {} // device lookup is best-effort; capture works regardless
    _wearable = wearable;

    SeqLog.msg('start-workout', 'ActiveWorkout', 'WorkoutGateway', 'startSession');
    final session = await ref.read(workoutGatewayProvider).startSession(
          userId: userId,
          workoutTypeId: type.id,
          connectedDeviceId: wearable?.id ?? phone?.id,
        );

    final phoneSource = ref.read(workoutDataSourceFactoryProvider)();
    // Real BLE pairing → live GATT heart rate; mock pairing → simulated
    // stream. Same HrSource interface either way (class swap, no refactor).
    final hrSource = wearable == null
        ? null
        : wearable.isRealBle
            ? BleHeartRateSource(wearable.bleRemoteId!)
            : WearableHrSource();
    _source = hrSource != null
        ? CompositeWorkoutDataSource(phoneSource, hrSource)
        : phoneSource;
    SeqLog.msg('start-workout', 'ActiveWorkout', 'WorkoutDataSource',
        'start(${wearable != null ? 'phone+${wearable.deviceName}${hrSource is BleHeartRateSource ? ' (BLE)' : ' (sim)'}' : 'phone'})');
    try {
      await _source!.start();
    } catch (e) {
      // A real device out of range shouldn't cost the session — fall back
      // to the simulated HR stream and keep recording.
      if (hrSource is BleHeartRateSource) {
        SeqLog.msg('start-workout', 'ActiveWorkout', 'WorkoutDataSource',
            'BLE connect failed ($e) — falling back to simulated HR');
        _source = CompositeWorkoutDataSource(
            ref.read(workoutDataSourceFactoryProvider)(), WearableHrSource());
        await _source!.start();
      } else {
        rethrow;
      }
    }
    _metricsSub = _source!.metrics.listen((m) {
      state = state.copyWith(
          distanceMeters: m.distanceMeters, steps: m.steps, heartRate: m.heartRate);
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
      wearableName: wearable?.deviceName,
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

    // Fetch the calorie weight (and sex, for the weight fallback) BEFORE
    // tearing down sensors — keeps the network round-trip clear of any
    // platform-channel teardown stalls.
    double? weightKg;
    Sex? sex;
    try {
      final profile = await ref.read(fitnessProfileProvider.future);
      weightKg = profile?.weightKg;
      sex = profile?.sex;
    } catch (_) {} // profile unavailable → entity falls back to a sex-based default

    _timer?.cancel();
    await _metricsSub?.cancel();
    await _source?.stop();
    final calories =
        type.estimateCalories(durationSeconds: elapsed.inSeconds, weightKg: weightKg, sex: sex);

    final metrics = <String, dynamic>{
      'duration_seconds': elapsed.inSeconds,
      'calories_burned': calories,
      if (type.isCardio) 'distance_meters': state.distanceMeters.round(),
      if (_source != null && _source!.trackPoints.isNotEmpty)
        'track_points': _source!.trackPoints,
      // Wearable HR (simulated stream for the FYP) → avg/max persisted by the RPC.
      if (_source is CompositeWorkoutDataSource &&
          (_source as CompositeWorkoutDataSource).avgHeartRate != null) ...{
        'avg_heart_rate': (_source as CompositeWorkoutDataSource).avgHeartRate,
        'max_heart_rate': (_source as CompositeWorkoutDataSource).maxHeartRate,
      },
    };

    SeqLog.msg('end-workout', 'ActiveWorkout', 'WorkoutGateway', 'endSession(rpc)');
    final result = await ref
        .read(workoutGatewayProvider)
        .endSession(sessionId: sessionId, metrics: metrics);

    // Wearable contributed data → bump its last-synced stamp (#7.1).
    final syncedWearable = _wearable;
    if (syncedWearable != null) {
      try {
        await ref.read(manageConnectedDeviceProvider).markSynced(syncedWearable.id);
      } catch (_) {}
    }

    _source = null;
    _wearable = null;
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
