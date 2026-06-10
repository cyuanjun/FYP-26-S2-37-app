import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wise_workout/boundaries/gateways/social_gateway.dart';
import 'package:wise_workout/boundaries/gateways/social_share_gateway.dart';
import 'package:wise_workout/controls/authenticate.dart';
import 'package:wise_workout/controls/share_workout.dart';
import 'package:wise_workout/entities/enums.dart';

import '../helpers/fakes.dart';

void main() {
  group('CreateWorkoutSharePost', () {
    test('inserts a workout_share post with caption for current user (positive)', () async {
      final social = FakeSocialGateway();
      final c = ProviderContainer(overrides: [
        currentUserIdProvider.overrideWithValue('u1'),
        socialGatewayProvider.overrideWithValue(social),
      ]);
      addTearDown(c.dispose);

      final id = await c.read(createWorkoutSharePostProvider).call(sessionId: 's1', caption: 'Felt great!');
      expect(id, 'post-1');
      expect(social.createdPosts.single, {'userId': 'u1', 'sessionId': 's1', 'body': 'Felt great!'});
    });

    test('caption can be omitted (null body)', () async {
      final social = FakeSocialGateway();
      final c = ProviderContainer(overrides: [
        currentUserIdProvider.overrideWithValue('u1'),
        socialGatewayProvider.overrideWithValue(social),
      ]);
      addTearDown(c.dispose);

      await c.read(createWorkoutSharePostProvider).call(sessionId: 's1');
      expect(social.createdPosts.single['body'], isNull);
    });
  });

  group('ShareWorkoutToSocial', () {
    test('shares the given text to the chosen platform (positive)', () async {
      final share = FakeSocialShareGateway();
      final c = ProviderContainer(overrides: [
        socialShareGatewayProvider.overrideWithValue(share),
      ]);
      addTearDown(c.dispose);

      await c.read(shareWorkoutToSocialProvider).call(SocialPlatform.instagram, text: 'Ran 5k!');
      expect(share.shares.single.$1, SocialPlatform.instagram);
      expect(share.shares.single.$2, 'Ran 5k!');
    });
  });

  test('SocialPlatform labels are the named platforms', () {
    expect(SocialPlatform.values.map((p) => p.label).toList(),
        ['Facebook', 'Instagram', 'Twitter', 'TikTok']);
  });
}
