import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wise_workout/boundaries/gateways/social_gateway.dart';
import 'package:wise_workout/boundaries/gateways/social_share_gateway.dart';
import 'package:wise_workout/controls/authenticate.dart';
import 'package:wise_workout/controls/share_workout.dart';
import 'package:wise_workout/entities/enums.dart';

import '../helpers/fakes.dart';

// (#) Tests the CreateWorkoutSharePost and ShareWorkoutToSocial controls plus platform labels.

void main() {
  // (#) Posting a shared workout to the in-app feed.
  group('CreateWorkoutSharePost', () {
    // (#) (+) Check if a workout_share post is inserted with the caption for the current user.
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

    // (#) (+) Check if omitting the caption stores a null body.
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

  // (#) Sharing out to an external social platform.
  group('ShareWorkoutToSocial', () {
    // (#) (+) Check if the given text is shared to the chosen platform.
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

  // (#) (+) Check if the platform labels are the four named platforms in order.
  test('SocialPlatform labels are the named platforms', () {
    expect(SocialPlatform.values.map((p) => p.label).toList(),
        ['Facebook', 'Instagram', 'Twitter', 'TikTok']);
  });
}
