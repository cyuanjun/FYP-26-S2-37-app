import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wise_workout/boundaries/gateways/fitness_gateway.dart';
import 'package:wise_workout/boundaries/gateways/workout_gateway.dart';
import 'package:wise_workout/controls/authenticate.dart';
import 'package:wise_workout/controls/log_manual_workout.dart';
import 'package:wise_workout/entities/enums.dart';
import 'package:wise_workout/entities/workout_type.dart';

import '../helpers/fakes.dart';

const _run = WorkoutType(id: 'wt-run', name: 'Running', slug: 'running');
const _yoga = WorkoutType(id: 'wt-yoga', name: 'Yoga', slug: 'yoga');

ProviderContainer _container(FakeWorkoutGateway gateway) {
  final c = ProviderContainer(overrides: [
    currentUserIdProvider.overrideWithValue('u1'),
    workoutGatewayProvider.overrideWithValue(gateway),
    fitnessGatewayProvider.overrideWithValue(FakeFitnessGateway()),
  ]);
  addTearDown(c.dispose);
  return c;
}

void main() {
  test('manual entry: no device, backdated start, distance for cardio',
      () async {
    final gateway = FakeWorkoutGateway();
    final c = _container(gateway);
    final startedAt = DateTime(2026, 7, 6, 7, 30);

    final result = await c.read(logManualWorkoutProvider).call(
          type: _run,
          startedAt: startedAt,
          duration: const Duration(minutes: 30),
          distanceMeters: 5000,
          feelRating: FeelRating.good,
          notes: 'easy pace',
        );

    final start = gateway.startSessionCalls.single;
    expect(start.connectedDeviceId, isNull); // manual = no source device

    final end = gateway.endSessionCalls.single;
    expect(end.metrics['started_at'],
        startedAt.toUtc().toIso8601String()); // backdate reaches the RPC
    expect(end.metrics['duration_seconds'], 1800);
    expect(end.metrics['distance_meters'], 5000);
    expect(end.metrics['calories_burned'], isPositive); // MET estimate

    expect(gateway.updateCalls, hasLength(1)); // feel + notes persisted
    expect(result['xp_gained'], 20); // RPC result surfaces to the UI
  });

  test('non-cardio entries never send distance (negative)', () async {
    final gateway = FakeWorkoutGateway();
    final c = _container(gateway);

    await c.read(logManualWorkoutProvider).call(
          type: _yoga,
          startedAt: DateTime(2026, 7, 6, 7, 30),
          duration: const Duration(minutes: 60),
          distanceMeters: 4000, // UI shouldn't allow it, control drops it too
        );

    expect(
        gateway.endSessionCalls.single.metrics.containsKey('distance_meters'),
        isFalse);
    expect(gateway.updateCalls, isEmpty); // nothing to summarise
  });
}
