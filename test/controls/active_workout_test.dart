import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wise_workout/boundaries/gateways/workout_data_source.dart';
import 'package:wise_workout/boundaries/gateways/workout_gateway.dart';
import 'package:wise_workout/controls/active_workout.dart';
import 'package:wise_workout/controls/authenticate.dart';

import '../helpers/fakes.dart';

void main() {
  late FakeWorkoutGateway gw;
  late FakeWorkoutDataSource src;

  ProviderContainer makeContainer() {
    gw = FakeWorkoutGateway(endResult: {'xp_gained': 42, 'leveled_up': false, 'current_streak': 1});
    src = FakeWorkoutDataSource();
    final c = ProviderContainer(overrides: [
      currentUserIdProvider.overrideWithValue('u1'),
      workoutGatewayProvider.overrideWithValue(gw),
      workoutDataSourceFactoryProvider.overrideWithValue(() => src),
    ]);
    addTearDown(() {
      src.dispose();
      c.dispose();
    });
    return c;
  }

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

  test('live sensor metrics update state', () async {
    final c = makeContainer();
    await c.read(activeWorkoutProvider.notifier).start(runningType);
    src.emit(const LiveMetrics(distanceMeters: 1200, steps: 50));
    await Future<void>.delayed(Duration.zero);
    expect(c.read(activeWorkoutProvider).distanceMeters, 1200);
  });

  test('end cardio → distance in metrics, returns RPC result, resets state (positive)', () async {
    final c = makeContainer();
    await c.read(activeWorkoutProvider.notifier).start(runningType);
    src.emit(const LiveMetrics(distanceMeters: 1000));
    await Future<void>.delayed(Duration.zero);
    final result = await c.read(activeWorkoutProvider.notifier).end();
    expect(result['xp_gained'], 42);
    expect(gw.endSessionCalls.single.metrics.containsKey('distance_meters'), isTrue);
    expect(src.stopped, isTrue);
    expect(c.read(activeWorkoutProvider).status, WorkoutStatus.idle);
  });

  test('end non-cardio → no distance in metrics (negative for distance)', () async {
    final c = makeContainer();
    await c.read(activeWorkoutProvider.notifier).start(yogaType);
    await c.read(activeWorkoutProvider.notifier).end();
    expect(gw.endSessionCalls.single.metrics.containsKey('distance_meters'), isFalse);
  });

  test('pause/resume are no-ops while idle (negative)', () {
    final c = makeContainer();
    final n = c.read(activeWorkoutProvider.notifier);
    n.pause();
    expect(c.read(activeWorkoutProvider).status, WorkoutStatus.idle);
    n.resume();
    expect(c.read(activeWorkoutProvider).status, WorkoutStatus.idle);
  });

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
