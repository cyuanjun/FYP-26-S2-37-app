import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wise_workout/boundaries/gateways/auth_gateway.dart';
import 'package:wise_workout/controls/authenticate.dart';

import '../helpers/fakes.dart';

// (#) Tests the Authenticate control: sign in success/failure and sign out,
// (#) using a fake auth gateway.
void main() {
  // (#) Builds a ProviderContainer wired to the given fake auth gateway.
  ProviderContainer containerWith(FakeAuthGateway fake) {
    final c = ProviderContainer(overrides: [authGatewayProvider.overrideWithValue(fake)]);
    addTearDown(c.dispose);
    return c;
  }

  // (#) (+) Check if a successful sign in leaves no error state and hits the gateway once.
  test('signIn success → no error state (positive)', () async {
    final fake = FakeAuthGateway();
    final c = containerWith(fake);
    await c.read(authenticateProvider.notifier).signIn(email: 'a@b.c', password: 'pw');
    expect(c.read(authenticateProvider).hasError, isFalse);
    expect(fake.signInCount, 1);
  });

  // (#) (-) Check if a failing sign in lands the control in an error state.
  test('signIn failure → AsyncError (negative)', () async {
    final fake = FakeAuthGateway(throwOnSignIn: true);
    final c = containerWith(fake);
    await c.read(authenticateProvider.notifier).signIn(email: 'a@b.c', password: 'bad');
    expect(c.read(authenticateProvider).hasError, isTrue);
  });

  // (#) (+) Check if signOut calls through to the gateway.
  test('signOut delegates to the gateway', () async {
    final fake = FakeAuthGateway();
    final c = containerWith(fake);
    await c.read(authenticateProvider.notifier).signOut();
    expect(fake.signOutCount, 1);
  });
}
