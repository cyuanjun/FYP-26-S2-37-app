import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wise_workout/boundaries/gateways/auth_gateway.dart';
import 'package:wise_workout/controls/authenticate.dart';

import '../helpers/fakes.dart';

void main() {
  ProviderContainer containerWith(FakeAuthGateway fake) {
    final c = ProviderContainer(overrides: [authGatewayProvider.overrideWithValue(fake)]);
    addTearDown(c.dispose);
    return c;
  }

  test('signIn success → no error state (positive)', () async {
    final fake = FakeAuthGateway();
    final c = containerWith(fake);
    await c.read(authenticateProvider.notifier).signIn(email: 'a@b.c', password: 'pw');
    expect(c.read(authenticateProvider).hasError, isFalse);
    expect(fake.signInCount, 1);
  });

  test('signIn failure → AsyncError (negative)', () async {
    final fake = FakeAuthGateway(throwOnSignIn: true);
    final c = containerWith(fake);
    await c.read(authenticateProvider.notifier).signIn(email: 'a@b.c', password: 'bad');
    expect(c.read(authenticateProvider).hasError, isTrue);
  });

  test('signOut delegates to the gateway', () async {
    final fake = FakeAuthGateway();
    final c = containerWith(fake);
    await c.read(authenticateProvider.notifier).signOut();
    expect(fake.signOutCount, 1);
  });
}
