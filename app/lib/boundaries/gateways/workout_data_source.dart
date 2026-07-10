import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pedometer/pedometer.dart';

// (#) A snapshot of live numbers sent out while a workout runs: distance from
// (#) GPS, steps from the pedometer, elevation, and heart rate if a strap is on.
class LiveMetrics {
  // (#) Builds one reading, everything defaulting to zero or null.
  const LiveMetrics(
      {this.distanceMeters = 0, this.steps = 0, this.lastElevation, this.heartRate});

  final double distanceMeters; // (#) metres covered so far
  final int steps; // (#) step count so far
  final double? lastElevation; // (#) last known altitude, if any
  final int? heartRate; // (#) latest bpm, if a strap is on
}

// (#) The one capture interface the workout controls read from. Different
// (#) implementations feed live metrics from the phone GPS, pedometer, or a strap.
abstract class WorkoutDataSource {
  Stream<LiveMetrics> get metrics; // (#) the live readings stream
  Future<void> start(); // (#) begins capturing
  Future<void> stop(); // (#) stops capturing and cleans up

  // (#) The route trace saved with the session (time, elevation, pace points).
  List<Map<String, dynamic>> get trackPoints;
}

// (#) Real phone capture: distance and pace from GPS, steps from the pedometer.
class PhoneSensorSource implements WorkoutDataSource {
  final _controller = StreamController<LiveMetrics>.broadcast(); // (#) pushes each reading out
  final _track = <Map<String, dynamic>>[]; // (#) collected route trace points

  StreamSubscription<Position>? _posSub; // (#) listener on GPS updates
  StreamSubscription<StepCount>? _stepSub; // (#) listener on step-count updates
  Position? _last; // (#) previous GPS fix, for measuring the gap
  double _distance = 0; // (#) running total distance in metres
  int _steps = 0; // (#) steps counted since the session began
  int? _baseSteps; // (#) pedometer's lifetime count at the start, to subtract off
  DateTime? _startedAt; // (#) when the session began, for timestamps

  // (#) The live readings stream the workout control listens to.
  @override
  Stream<LiveMetrics> get metrics => _controller.stream;

  // (#) The route trace gathered so far.
  @override
  List<Map<String, dynamic>> get trackPoints => _track;

  // (#) Asks for location permission, then starts listening to GPS and steps.
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

  // (#) Handles each new GPS fix: adds the distance since the last one and
  // (#) records a trace point.
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

  // (#) Pushes the current distance, steps, and elevation out on the stream.
  void _emit() => _controller.add(
        LiveMetrics(distanceMeters: _distance, steps: _steps, lastElevation: _last?.altitude),
      );

  // (#) Stops the GPS and step listeners and closes the stream.
  @override
  Future<void> stop() async {
    // Platform-channel cancels can wedge when a stale engine holds the
    // location service (seen after hot redeploys) — never block end() on them.
    unawaited(_posSub?.cancel());
    unawaited(_stepSub?.cancel());
    await _controller.close();
  }
}

// (#) A source that can report heart rate. Both the simulated wearable and the
// (#) real BLE strap satisfy this, so callers don't care which one fed the session.
abstract class HrSource implements WorkoutDataSource {
  int? get avgHeartRate; // (#) average bpm over the session
  int? get maxHeartRate; // (#) highest bpm over the session
}

// (#) A fake heart-rate source used when no real strap is paired. Follows a set
// (#) curve: a warm-up ramp plus a gentle wave, so demos look believable.
class WearableHrSource implements HrSource {
  final _controller = StreamController<LiveMetrics>.broadcast(); // (#) pushes each fake bpm out
  final samples = <int>[]; // (#) every bpm produced, for avg and max
  Timer? _timer; // (#) ticks once a second to make a new reading
  int _t = 0; // (#) seconds elapsed, feeds the curve

  // (#) The live readings stream the workout control listens to.
  @override
  Stream<LiveMetrics> get metrics => _controller.stream;

  // (#) No route trace from a heart-rate source, so this is always empty.
  @override
  List<Map<String, dynamic>> get trackPoints => const [];

  // (#) The bpm value at a given second into the session. Pure, so tests can check it.
  static int hrAt(int seconds) {
    final ramp = seconds >= 300 ? 60.0 : seconds / 300 * 60.0; // 70 → ~130 over 5 min
    final wave = 8 * math.sin(seconds / 20);
    return (70 + ramp + wave).round();
  }

  // (#) Works out and stores the bpm for one second, exposed only for tests.
  @visibleForTesting
  void recordTick(int seconds) {
    final hr = hrAt(seconds);
    samples.add(hr);
    if (!_controller.isClosed) _controller.add(LiveMetrics(heartRate: hr));
  }

  // (#) Average bpm over the session, or null if nothing was produced.
  @override
  int? get avgHeartRate => samples.isEmpty
      ? null
      : (samples.reduce((a, b) => a + b) / samples.length).round();

  // (#) Highest bpm over the session, or null if nothing was produced.
  @override
  int? get maxHeartRate =>
      samples.isEmpty ? null : samples.reduce((a, b) => a > b ? a : b);

  // (#) Starts the once-a-second timer that feeds the fake readings.
  @override
  Future<void> start() async {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => recordTick(_t++));
  }

  // (#) Stops the timer and closes the stream.
  @override
  Future<void> stop() async {
    _timer?.cancel();
    await _controller.close();
  }
}

// (#) Ties the phone source and an optional heart-rate source into one stream,
// (#) so the control sees a single data source no matter how many feed it.
class CompositeWorkoutDataSource implements WorkoutDataSource {
  // (#) Builds the combined source from the phone source and an optional strap.
  CompositeWorkoutDataSource(this.phone, this.wearable);

  final WorkoutDataSource phone; // (#) the phone GPS/steps source
  final HrSource? wearable; // (#) the heart-rate source, or null if none

  final _controller = StreamController<LiveMetrics>.broadcast(); // (#) the merged output stream
  StreamSubscription<LiveMetrics>? _phoneSub; // (#) listener on the phone source
  StreamSubscription<LiveMetrics>? _hrSub; // (#) listener on the heart-rate source
  LiveMetrics _phoneLast = const LiveMetrics(); // (#) latest phone reading, kept to merge
  int? _hrLast; // (#) latest bpm, kept to merge

  // (#) The merged live readings stream the control listens to.
  @override
  Stream<LiveMetrics> get metrics => _controller.stream;

  // (#) The route trace comes straight from the phone source.
  @override
  List<Map<String, dynamic>> get trackPoints => phone.trackPoints;

  int? get avgHeartRate => wearable?.avgHeartRate; // (#) average bpm, from the strap
  int? get maxHeartRate => wearable?.maxHeartRate; // (#) highest bpm, from the strap

  // (#) Merges the newest phone and heart-rate values into one reading and emits it.
  void _emit() {
    if (_controller.isClosed) return;
    _controller.add(LiveMetrics(
      distanceMeters: _phoneLast.distanceMeters,
      steps: _phoneLast.steps,
      lastElevation: _phoneLast.lastElevation,
      heartRate: _hrLast,
    ));
  }

  // (#) Subscribes to both sources and starts them capturing.
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

  // (#) Stops both sources, cancels the listeners, and closes the stream.
  @override
  Future<void> stop() async {
    await _phoneSub?.cancel();
    await _hrSub?.cancel();
    await phone.stop();
    await wearable?.stop();
    await _controller.close();
  }
}

// (#) Provider that makes a fresh phone source per session instead of sharing one.
final workoutDataSourceFactoryProvider = Provider<WorkoutDataSource Function()>(
  (ref) => PhoneSensorSource.new,
);
