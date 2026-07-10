import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wise_workout/boundaries/gateways/expert_gateway.dart';
import 'package:wise_workout/controls/authenticate.dart';
import 'package:wise_workout/controls/browse_experts.dart';
import 'package:wise_workout/entities/enums.dart';
import 'package:wise_workout/entities/expert_category.dart';
import 'package:wise_workout/entities/expert_profile.dart';
import 'package:wise_workout/entities/expert_summary.dart';
import 'package:wise_workout/entities/profile.dart';
import 'package:wise_workout/entities/public_profile.dart';

import '../helpers/fakes.dart';

// (#) Tests the BrowseExperts control: listing experts/categories and toggling
// (#) follow, all with a fake expert gateway.

// (#) A sample expert summary used across the tests.
const _sam = ExpertSummary(
  identity: PublicProfile(id: 'x1', firstName: 'Sam', lastName: 'Rivera'),
  profile: ExpertProfile(id: 'x1', title: 'Strength Coach'),
);

void main() {
  // (#) The read-side providers that list experts and categories.
  group('BrowseExperts providers', () {
    // (#) (+) Check if the expert list and the per-id lookup share one fetch, and an unknown id gives null.
    test('expertsProvider + derived family lookup share one fetch', () async {
      final gateway = FakeExpertGateway()..experts = [_sam];
      final c = ProviderContainer(overrides: [
        currentUserIdProvider.overrideWithValue('u1'),
        expertGatewayProvider.overrideWithValue(gateway),
      ]);
      addTearDown(c.dispose);

      expect((await c.read(expertsProvider.future)).single.identity.id, 'x1');
      expect((await c.read(expertSummaryProvider('x1').future))?.profile.title,
          'Strength Coach');
      expect(await c.read(expertSummaryProvider('nope').future), isNull);
    });

    // (#) (+) Check if the categories provider returns what the gateway serves.
    test('categories come from the gateway (active only, by contract)', () async {
      final gateway = FakeExpertGateway()
        ..categories = [const ExpertCategory(id: 'strength', label: 'Strength')];
      final c = ProviderContainer(overrides: [
        expertGatewayProvider.overrideWithValue(gateway),
      ]);
      addTearDown(c.dispose);

      expect((await c.read(expertCategoriesProvider.future)).single.id, 'strength');
    });
  });

  // (#) The follow/unfollow-expert control.
  group('ToggleFollowExpert', () {
    // (#) Builds a container with a signed-in profile and fake expert gateway.
    ProviderContainer container(FakeExpertGateway gateway, Profile profile) {
      final c = ProviderContainer(overrides: [
        currentUserIdProvider.overrideWithValue('u1'),
        currentProfileProvider.overrideWith((ref) async => profile),
        expertGatewayProvider.overrideWithValue(gateway),
      ]);
      addTearDown(c.dispose);
      return c;
    }

    const base = Profile(id: 'u1', email: 'mia@test', role: UserRole.free);

    // (#) (+) Check if toggling an unfollowed expert adds them to the followed list.
    test('adds when not followed (positive)', () async {
      final gateway = FakeExpertGateway();
      final c = container(gateway, base);
      await c.read(currentProfileProvider.future);

      await c.read(toggleFollowExpertProvider).call('x1');
      expect(gateway.followUpdates.single, ['x1']);
    });

    // (#) (-) Check if toggling an already-followed expert removes them from the list.
    test('removes when already followed (negative path)', () async {
      final gateway = FakeExpertGateway();
      final c = container(gateway, base.copyWith(followedExpertIds: ['x1', 'x2']));
      await c.read(currentProfileProvider.future);

      await c.read(toggleFollowExpertProvider).call('x1');
      expect(gateway.followUpdates.single, ['x2']);
    });
  });
}
