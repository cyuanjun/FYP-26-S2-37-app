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

// (#) The three states a recording can be in: not started, ticking, or on hold.
enum WorkoutStatus { idle, running, paused }

// (#) The snapshot of a live workout the screen watches: status, type, timer,
// (#) distance, steps, heart rate and the paired wearable's name. Immutable, so
// (#) any change makes a fresh copy via copyWith.
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

  final WorkoutStatus status; // (#) idle, running or paused
  final WorkoutType? type; // (#) what kind of workout is being recorded
  final String? sessionId; // (#) the DB row id once the session is started
  final Duration elapsed; // (#) time counted so far
  final double distanceMeters; // (#) distance from the phone GPS
  final int steps; // (#) step count from the pedometer
  final int? heartRate; // (#) latest HR reading, null if no wearable
  final String? wearableName; // (#) name of the paired HR device, if any

  // (#) True when a workout is going (running or paused), false when idle.
  bool get isActive => status != WorkoutStatus.idle;

  // (#) Makes a new state with only the given fields changed, rest kept as-is.
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

// (#) Runs one live workout recording start to finish. It starts the timer and
// (#) the phone/wearable sensor streams, keeps the state's numbers fresh as
// (#) readings arrive, and on stop hands the totals to the workout gateway. The
// (#) screen only watches; it never touches sensors or the DB itself.
class ActiveWorkout extends Notifier<ActiveWorkoutState> {
  Timer? _timer; // (#) fires every second to update the elapsed clock
  WorkoutDataSource? _source; // (#) the sensor feed (phone, or phone + wearable)
  ConnectedDevice? _wearable; // (#) the paired HR device for this session, if any
  StreamSubscription<LiveMetrics>? _metricsSub; // (#) listens to sensor readings
  Duration _accumulated = Duration.zero; // (#) time banked before the current run segment
  DateTime? _segmentStart; // (#) when the current running segment began, null if paused

  // (#) Sets up teardown on dispose and starts idle.
  @override
  ActiveWorkoutState build() {
    ref.onDispose(_teardown);
    return const ActiveWorkoutState();
  }

  // (#) Begins a recording: looks up devices, asks the gateway to open a session
  // (#) row, wires up the phone (and wearable HR) sensor streams, and starts the
  // (#) per-second timer. Flips state to running.
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

  // (#) Puts the recording on hold: banks the elapsed time and stops the clock.
  void pause() {
    if (state.status != WorkoutStatus.running) return;
    _accumulated = _elapsed();
    _segmentStart = null;
    state = state.copyWith(status: WorkoutStatus.paused);
  }

  // (#) Restarts a paused recording: opens a fresh segment and ticks again.
  void resume() {
    if (state.status != WorkoutStatus.paused) return;
    _segmentStart = DateTime.now();
    state = state.copyWith(status: WorkoutStatus.running);
  }

  // (#) Ends the recording: reads body weight for the calorie estimate, tears
  // (#) down the sensors and timer, builds the metrics map and calls the endSession
  // (#) RPC. Returns the RPC result (xp gained, new level, leveled up, streak) for
  // (#) the summary screen, bumps the wearable's synced stamp, and resets to idle.
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

  // (#) Total time so far: banked time plus the current segment if still running.
  Duration _elapsed() {
    if (_segmentStart == null) return _accumulated;
    return _accumulated + DateTime.now().difference(_segmentStart!);
  }

  // (#) Cleanup on dispose: stop the timer and shut down the sensor streams.
  void _teardown() {
    _timer?.cancel();
    _metricsSub?.cancel();
    _source?.stop();
  }
}

// (#) Hands the screen the ActiveWorkout control and its live state.
final activeWorkoutProvider =
    NotifierProvider<ActiveWorkout, ActiveWorkoutState>(ActiveWorkout.new);
