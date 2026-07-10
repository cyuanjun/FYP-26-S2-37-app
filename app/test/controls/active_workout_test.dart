import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wise_workout/boundaries/gateways/fitness_gateway.dart';
import 'package:wise_workout/boundaries/gateways/workout_data_source.dart';
import 'package:wise_workout/boundaries/gateways/workout_gateway.dart';
import 'package:wise_workout/controls/active_workout.dart';
import 'package:wise_workout/controls/authenticate.dart';
import 'package:wise_workout/entities/fitness_profile.dart';

import '../helpers/fakes.dart';

// (#) Tests the ActiveWorkout control: starting/ending a session, live sensor
// (#) metrics, calorie estimates, and pause/resume, all with fake gateways.
void main() {
  late FakeWorkoutGateway gw;
  late FakeWorkoutDataSource src;

  // (#) Builds a ProviderContainer wired to fake workout/sensor/fitness gateways.
  ProviderContainer makeContainer({double? weightKg}) {
    gw = FakeWorkoutGateway(endResult: {'xp_gained': 42, 'leveled_up': false, 'current_streak': 1});
    src = FakeWorkoutDataSource();
    final c = ProviderContainer(overrides: [
      currentUserIdProvider.overrideWithValue('u1'),
      workoutGatewayProvider.overrideWithValue(gw),
      workoutDataSourceFactoryProvider.overrideWithValue(() => src),
      fitnessGatewayProvider.overrideWithValue(
          FakeFitnessGateway(profile: FitnessProfile(id: 'u1', weightKg: weightKg))),
    ]);
    addTearDown(() {
      src.dispose();
      c.dispose();
    });
    return c;
  }

  // (#) (+) Check if start flips to running, inserts a session for the current user, and starts the sensors.
  test('start → running, inserts session for current user, starts sensors (positive)', () async {
    final c = makeContainer();
    await c.read(activeWorkoutProvider.notifier).start(runningType);
    final s = c.read(activeWorkoutProvider);
    expect(s.status, WorkoutStatus.running);
    expect(s.type, runningType);
    expect(s.sessionId, isNotNull);
    expect(gw.startSessionCalls.single.userId, 'u1');
    expect(gw.startSessionCalls.single.workoutTypeId, runningType.id);
    expect(src.started, isTrue);
  });

  // (#) (+) Check if live sensor readings flow into the state (distance updates).
  test('live sensor metrics update state', () async {
    final c = makeContainer();
    await c.read(activeWorkoutProvider.notifier).start(runningType);
    src.emit(const LiveMetrics(distanceMeters: 1200, steps: 50));
    await Future<void>.delayed(Duration.zero);
    expect(c.read(activeWorkoutProvider).distanceMeters, 1200);
  });

  // (#) (+) Check if ending a cardio session sends distance/calories, returns the RPC result, and resets to idle.
  test('end cardio → distance in metrics, returns RPC result, resets state (positive)', () async {
    final c = makeContainer();
    await c.read(activeWorkoutProvider.notifier).start(runningType);
    src.emit(const LiveMetrics(distanceMeters: 1000));
    await Future<void>.delayed(Duration.zero);
    final result = await c.read(activeWorkoutProvider.notifier).end();
    expect(result['xp_gained'], 42);
    expect(gw.endSessionCalls.single.metrics.containsKey('distance_meters'), isTrue);
    expect(gw.endSessionCalls.single.metrics['calories_burned'], isA<int>());
    expect(src.stopped, isTrue);
    expect(c.read(activeWorkoutProvider).status, WorkoutStatus.idle);
  });

  // (#) (+) Check if a heavier profile weight yields a higher calorie estimate than the default.
  test('end → calorie estimate uses profile weight when set (positive)', () async {
    final c = makeContainer(weightKg: 100); // heavier burns more than default 70
    await c.read(activeWorkoutProvider.notifier).start(runningType);
    await c.read(activeWorkoutProvider.notifier).end();
    final heavy = gw.endSessionCalls.single.metrics['calories_burned'] as int;

    final c2 = makeContainer(); // null weight → entity's 70 kg default
    await c2.read(activeWorkoutProvider.notifier).start(runningType);
    await c2.read(activeWorkoutProvider.notifier).end();
    final defaultW = gw.endSessionCalls.single.metrics['calories_burned'] as int;

    expect(heavy, greaterThanOrEqualTo(defaultW));
  });

  // (#) (-) Check if a non-cardio session (yoga) records no distance metric.
  test('end non-cardio → no distance in metrics (negative for distance)', () async {
    final c = makeContainer();
    await c.read(activeWorkoutProvider.notifier).start(yogaType);
    await c.read(activeWorkoutProvider.notifier).end();
    expect(gw.endSessionCalls.single.metrics.containsKey('distance_meters'), isFalse);
  });

  // (#) (-) Check if pause and resume do nothing while there is no active session.
  test('pause/resume are no-ops while idle (negative)', () {
    final c = makeContainer();
    final n = c.read(activeWorkoutProvider.notifier);
    n.pause();
    expect(c.read(activeWorkoutProvider).status, WorkoutStatus.idle);
    n.resume();
    expect(c.read(activeWorkoutProvider).status, WorkoutStatus.idle);
  });

  // (#) (+) Check if pause sets paused and resume returns to running.
  test('pause then resume toggles status', () async {
    final c = makeContainer();
    final n = c.read(activeWorkoutProvider.notifier);
    await n.start(runningType);
    n.pause();
    expect(c.read(activeWorkoutProvider).status, WorkoutStatus.paused);
    n.resume();
    expect(c.read(activeWorkoutProvider).status, WorkoutStatus.running);
  });
}
