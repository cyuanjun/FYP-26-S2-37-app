import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wise_workout/boundaries/gateways/workout_gateway.dart';
import 'package:wise_workout/controls/authenticate.dart';
import 'package:wise_workout/controls/workout_history.dart';
import 'package:wise_workout/entities/workout_session.dart';

import '../helpers/fakes.dart';

void main() {
  test('historyProvider is empty when signed out (negative)', () async {
    final c = ProviderContainer(overrides: [
      currentUserIdProvider.overrideWithValue(null),
      workoutGatewayProvider.overrideWithValue(FakeWorkoutGateway()),
    ]);
    addTearDown(c.dispose);
    expect(await c.read(historyProvider.future), isEmpty);
  });

  test('historyProvider returns the user\'s ended sessions (positive)', () async {
    final sessions = [
      WorkoutSession(
        id: 's1',
        userId: 'u1',
        workoutTypeId: 't',
        startedAt: DateTime(2026, 6, 10, 10),
        endedAt: DateTime(2026, 6, 10, 10, 30),
      ),
    ];
    final c = ProviderContainer(overrides: [
      currentUserIdProvider.overrideWithValue('u1'),
      workoutGatewayProvider.overrideWithValue(FakeWorkoutGateway(ended: sessions)),
    ]);
    addTearDown(c.dispose);
    final list = await c.read(historyProvider.future);
    expect(list, hasLength(1));
    expect(list.first.id, 's1');
  });

  test('DeleteWorkoutSession delegates to the gateway', () async {
    final gw = FakeWorkoutGateway();
    final c = ProviderContainer(overrides: [
      currentUserIdProvider.overrideWithValue('u1'),
      workoutGatewayProvider.overrideWithValue(gw),
    ]);
    addTearDown(c.dispose);
    await c.read(deleteWorkoutSessionProvider).call('s1');
    expect(gw.deletedIds, ['s1']);
  });
}
