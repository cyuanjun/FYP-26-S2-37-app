import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pedometer/pedometer.dart';

/// Live metrics emitted during a workout. Distance is GPS-derived; steps are
/// best-effort from the pedometer (absent on most simulators/emulators);
/// heart rate streams from a paired wearable source when one is active.
class LiveMetrics {
  const LiveMetrics(
      {this.distanceMeters = 0, this.steps = 0, this.lastElevation, this.heartRate});

  final double distanceMeters;
  final int steps;
  final double? lastElevation;
  final int? heartRate;
}

/// BOUNDARY (gateway) — the one capture interface. `PhoneSensorSource` today;
/// `HealthSource` / `BleHeartRateSource` are additive later (new classes, no refactor).
abstract class WorkoutDataSource {
  Stream<LiveMetrics> get metrics;
  Future<void> start();
  Future<void> stop();

  /// Time-series for WorkoutSession.track_points ({t, elev?, pace?}).
  List<Map<String, dynamic>> get trackPoints;
}

/// Captures distance/pace from `geolocator` and steps from `pedometer`.
class PhoneSensorSource implements WorkoutDataSource {
  final _controller = StreamController<LiveMetrics>.broadcast();
  final _track = <Map<String, dynamic>>[];

  StreamSubscription<Position>? _posSub;
  StreamSubscription<StepCount>? _stepSub;
  Position? _last;
  double _distance = 0;
  int _steps = 0;
  int? _baseSteps;
  DateTime? _startedAt;

  @override
  Stream<LiveMetrics> get metrics => _controller.stream;

  @override
  List<Map<String, dynamic>> get trackPoints => _track;

  @override
  Future<void> start() async {
    _startedAt = DateTime.now();

    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    final granted =
        perm == LocationPermission.always || perm == LocationPermission.whileInUse;
    if (granted) {
      _posSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        ),
      ).listen(_onPosition, onError: (_) {});
    }

    // Pedometer is best-effort: unavailable on most emulators/simulators.
    try {
      _stepSub = Pedometer.stepCountStream.listen((s) {
        _baseSteps ??= s.steps;
        _steps = s.steps - _baseSteps!;
        _emit();
      }, onError: (_) {});
    } catch (_) {}
  }

  void _onPosition(Position p) {
    if (_last != null) {
      _distance += Geolocator.distanceBetween(
          _last!.latitude, _last!.longitude, p.latitude, p.longitude);
    }
    _last = p;
    final t = _startedAt == null ? 0 : DateTime.now().difference(_startedAt!).inSeconds;
    _track.add({
      't': t,
      'elev': p.altitude,
      if (p.speed > 0) 'pace': (1000 / p.speed).round(), // sec per km
    });
    _emit();
  }

  void _emit() => _controller.add(
        LiveMetrics(distanceMeters: _distance, steps: _steps, lastElevation: _last?.altitude),
      );

  @override
  Future<void> stop() async {
    // Platform-channel cancels can wedge when a stale engine holds the
    // location service (seen after hot redeploys) — never block end() on them.
    unawaited(_posSub?.cancel());
    unawaited(_stepSub?.cancel());
    await _controller.close();
  }
}

/// Wearable heart-rate stream. SIMULATED for the FYP (the #7.1 spec's mock
/// pairing) — stands in for the future `BleHeartRateSource` (flutter_blue_plus)
/// behind the same interface, so swapping in real hardware is additive.
/// Deterministic: warm-up ramp to a working zone plus a gentle wave.
class WearableHrSource implements WorkoutDataSource {
  final _controller = StreamController<LiveMetrics>.broadcast();
  final samples = <int>[];
  Timer? _timer;
  int _t = 0;

  @override
  Stream<LiveMetrics> get metrics => _controller.stream;

  @override
  List<Map<String, dynamic>> get trackPoints => const [];

  /// bpm at [seconds] into the session — pure so tests can verify the curve.
  static int hrAt(int seconds) {
    final ramp = seconds >= 300 ? 60.0 : seconds / 300 * 60.0; // 70 → ~130 over 5 min
    final wave = 8 * math.sin(seconds / 20);
    return (70 + ramp + wave).round();
  }

  @visibleForTesting
  void recordTick(int seconds) {
    final hr = hrAt(seconds);
    samples.add(hr);
    if (!_controller.isClosed) _controller.add(LiveMetrics(heartRate: hr));
  }

  int? get avgHeartRate => samples.isEmpty
      ? null
      : (samples.reduce((a, b) => a + b) / samples.length).round();

  int? get maxHeartRate =>
      samples.isEmpty ? null : samples.reduce((a, b) => a > b ? a : b);

  @override
  Future<void> start() async {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => recordTick(_t++));
  }

  @override
  Future<void> stop() async {
    _timer?.cancel();
    await _controller.close();
  }
}

/// Merges the phone source (distance/steps/track) with an optional wearable
/// HR source into one stream — the Control still sees a single
/// WorkoutDataSource regardless of how many physical sources feed it.
class CompositeWorkoutDataSource implements WorkoutDataSource {
  CompositeWorkoutDataSource(this.phone, this.wearable);

  final WorkoutDataSource phone;
  final WearableHrSource? wearable;

  final _controller = StreamController<LiveMetrics>.broadcast();
  StreamSubscription<LiveMetrics>? _phoneSub;
  StreamSubscription<LiveMetrics>? _hrSub;
  LiveMetrics _phoneLast = const LiveMetrics();
  int? _hrLast;

  @override
  Stream<LiveMetrics> get metrics => _controller.stream;

  @override
  List<Map<String, dynamic>> get trackPoints => phone.trackPoints;

  int? get avgHeartRate => wearable?.avgHeartRate;
  int? get maxHeartRate => wearable?.maxHeartRate;

  void _emit() {
    if (_controller.isClosed) return;
    _controller.add(LiveMetrics(
      distanceMeters: _phoneLast.distanceMeters,
      steps: _phoneLast.steps,
      lastElevation: _phoneLast.lastElevation,
      heartRate: _hrLast,
    ));
  }

  @override
  Future<void> start() async {
    _phoneSub = phone.metrics.listen((m) {
      _phoneLast = m;
      _emit();
    });
    if (wearable != null) {
      _hrSub = wearable!.metrics.listen((m) {
        _hrLast = m.heartRate;
        _emit();
      });
    }
    await phone.start();
    await wearable?.start();
  }

  @override
  Future<void> stop() async {
    await _phoneSub?.cancel();
    await _hrSub?.cancel();
    await phone.stop();
    await wearable?.stop();
    await _controller.close();
  }
}

/// Factory so each session gets a fresh data source (vs a cached singleton).
final workoutDataSourceFactoryProvider = Provider<WorkoutDataSource Function()>(
  (ref) => PhoneSensorSource.new,
);
