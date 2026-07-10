import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wise_workout/boundaries/gateways/social_gateway.dart';
import 'package:wise_workout/controls/authenticate.dart';
import 'package:wise_workout/controls/social_feed.dart';

import '../helpers/fakes.dart';

// (#) Tests sessionSharePostProvider, which links a session to its feed share post (#12.1).

void main() {
  // (#) Builds a ProviderContainer wired to the fake social gateway and a user.
  ProviderContainer container(FakeSocialGateway gateway, {String? userId}) {
    final c = ProviderContainer(overrides: [
      currentUserIdProvider.overrideWithValue(userId),
      socialGatewayProvider.overrideWithValue(gateway),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  // (#) (+) Check if a shared session resolves to its share post id.
  test('resolves the share post for a shared session (#12.1 link)', () async {
    final gateway = FakeSocialGateway()..sharePostIds['sess-1'] = 'post-9';
    final c = container(gateway, userId: 'u1');
    expect(await c.read(sessionSharePostProvider('sess-1').future), 'post-9');
  });

  // (#) (-) Check if an unshared session resolves to null so no link renders.
  test('unshared session resolves null — no link rendered (negative)',
      () async {
    final c = container(FakeSocialGateway(), userId: 'u1');
    expect(await c.read(sessionSharePostProvider('sess-1').future), isNull);
  });

  // (#) (-) Check if a signed-out user resolves to null without querying the gateway.
  test('signed-out resolves null without a fetch (negative)', () async {
    final gateway = FakeSocialGateway()..sharePostIds['sess-1'] = 'post-9';
    final c = container(gateway, userId: null);
    expect(await c.read(sessionSharePostProvider('sess-1').future), isNull);
  });
}
