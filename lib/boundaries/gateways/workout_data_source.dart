import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pedometer/pedometer.dart';

/// Live metrics emitted during a workout. Distance is GPS-derived; steps are
/// best-effort from the pedometer (absent on most simulators/emulators).
class LiveMetrics {
  const LiveMetrics({this.distanceMeters = 0, this.steps = 0, this.lastElevation});

  final double distanceMeters;
  final int steps;
  final double? lastElevation;
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
    await _posSub?.cancel();
    await _stepSub?.cancel();
    await _controller.close();
  }
}

/// Factory so each session gets a fresh data source (vs a cached singleton).
final workoutDataSourceFactoryProvider = Provider<WorkoutDataSource Function()>(
  (ref) => PhoneSensorSource.new,
);
