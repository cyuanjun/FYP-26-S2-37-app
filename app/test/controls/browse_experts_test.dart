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

const _sam = ExpertSummary(
  identity: PublicProfile(id: 'x1', firstName: 'Sam', lastName: 'Rivera'),
  profile: ExpertProfile(id: 'x1', title: 'Strength Coach'),
);

void main() {
  group('BrowseExperts providers', () {
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

  group('ToggleFollowExpert', () {
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

    test('adds when not followed (positive)', () async {
      final gateway = FakeExpertGateway();
      final c = container(gateway, base);
      await c.read(currentProfileProvider.future);

      await c.read(toggleFollowExpertProvider).call('x1');
      expect(gateway.followUpdates.single, ['x1']);
    });

    test('removes when already followed (negative path)', () async {
      final gateway = FakeExpertGateway();
      final c = container(gateway, base.copyWith(followedExpertIds: ['x1', 'x2']));
      await c.read(currentProfileProvider.future);

      await c.read(toggleFollowExpertProvider).call('x1');
      expect(gateway.followUpdates.single, ['x2']);
    });
  });
}
