import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wise_workout/boundaries/gateways/workout_gateway.dart';
import 'package:wise_workout/controls/authenticate.dart';
import 'package:wise_workout/controls/workout_history.dart';
import 'package:wise_workout/entities/enums.dart';
import 'package:wise_workout/entities/profile.dart';
import 'package:wise_workout/entities/workout_session.dart';

import '../helpers/fakes.dart';

void main() {
  Profile profileWith(UserRole role) =>
      Profile(id: 'u1', email: 'u@test', role: role);

  ProviderContainer container(FakeWorkoutGateway gw,
      {String? userId = 'u1', UserRole role = UserRole.free}) {
    final c = ProviderContainer(overrides: [
      currentUserIdProvider.overrideWithValue(userId),
      currentProfileProvider.overrideWith((ref) async => profileWith(role)),
      workoutGatewayProvider.overrideWithValue(gw),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  WorkoutSession sessionOn(String id, DateTime start) => WorkoutSession(
        id: id,
        userId: 'u1',
        workoutTypeId: 't',
        startedAt: start,
        endedAt: start.add(const Duration(minutes: 30)),
      );

  test('historyProvider is empty when signed out (negative)', () async {
    final c = container(FakeWorkoutGateway(), userId: null);
    expect(await c.read(historyProvider.future), isEmpty);
  });

  test('historyProvider returns the user\'s ended sessions (positive)', () async {
    final now = DateTime.now();
    final c = container(FakeWorkoutGateway(ended: [sessionOn('s1', now)]));
    final list = await c.read(historyProvider.future);
    expect(list, hasLength(1));
    expect(list.first.id, 's1');
  });

  test('Free history is capped at the current calendar month (positive)', () async {
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month, 1, 9);
    final lastMonth = DateTime(now.year, now.month - 1, 15, 9);
    final gw = FakeWorkoutGateway(
        ended: [sessionOn('cur', thisMonth), sessionOn('old', lastMonth)]);
    final c = container(gw, role: UserRole.free);
    final list = await c.read(historyProvider.future);
    expect(list.map((s) => s.id), ['cur']); // last month's session hidden
    expect(gw.listFroms.single, DateTime(now.year, now.month)); // query-level bound
  });

  test('Premium history is lifetime — no cap (positive)', () async {
    final now = DateTime.now();
    final gw = FakeWorkoutGateway(ended: [
      sessionOn('cur', DateTime(now.year, now.month, 1, 9)),
      sessionOn('old', DateTime(now.year, now.month - 1, 15, 9)),
    ]);
    final c = container(gw, role: UserRole.premium);
    final list = await c.read(historyProvider.future);
    expect(list, hasLength(2));
    expect(gw.listFroms.single, isNull); // lifetime query
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
