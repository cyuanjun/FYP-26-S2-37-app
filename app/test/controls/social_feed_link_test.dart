import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wise_workout/boundaries/gateways/social_gateway.dart';
import 'package:wise_workout/controls/authenticate.dart';
import 'package:wise_workout/controls/social_feed.dart';

import '../helpers/fakes.dart';

void main() {
  ProviderContainer container(FakeSocialGateway gateway, {String? userId}) {
    final c = ProviderContainer(overrides: [
      currentUserIdProvider.overrideWithValue(userId),
      socialGatewayProvider.overrideWithValue(gateway),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  test('resolves the share post for a shared session (#12.1 link)', () async {
    final gateway = FakeSocialGateway()..sharePostIds['sess-1'] = 'post-9';
    final c = container(gateway, userId: 'u1');
    expect(await c.read(sessionSharePostProvider('sess-1').future), 'post-9');
  });

  test('unshared session resolves null — no link rendered (negative)',
      () async {
    final c = container(FakeSocialGateway(), userId: 'u1');
    expect(await c.read(sessionSharePostProvider('sess-1').future), isNull);
  });

  test('signed-out resolves null without a fetch (negative)', () async {
    final gateway = FakeSocialGateway()..sharePostIds['sess-1'] = 'post-9';
    final c = container(gateway, userId: null);
    expect(await c.read(sessionSharePostProvider('sess-1').future), isNull);
  });
}
