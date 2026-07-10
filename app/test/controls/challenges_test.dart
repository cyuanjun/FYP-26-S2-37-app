import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wise_workout/boundaries/gateways/social_gateway.dart';
import 'package:wise_workout/controls/authenticate.dart';
import 'package:wise_workout/controls/challenges.dart';
import 'package:wise_workout/entities/challenge.dart';
import 'package:wise_workout/entities/enums.dart';
import 'package:wise_workout/entities/public_profile.dart';

import '../helpers/fakes.dart';

// (#) Tests the challenges controls: viewing, joining/leaving, creating, and
// (#) finding challenges by code, all with a fake social gateway.

// (#) Builds a sample Challenge entity for the tests.
Challenge _challenge(String id, {int? target = 20, String code = ''}) =>
    Challenge(
      id: id,
      name: 'Challenge $id',
      shortName: id.toUpperCase(),
      icon: '⚡',
      joinCode: code,
      metricKind: ChallengeMetricKind.accumulator,
      metric: ChallengeMetric.totalSessions,
      targetValue: target,
      startedAt: DateTime.utc(2026, 7, 1),
      endedAt: DateTime.utc(2026, 7, 30),
    );

// (#) Builds a container with the given signed-in user and fake social gateway.
ProviderContainer _container(FakeSocialGateway social, {String? userId = 'u1'}) {
  final c = ProviderContainer(overrides: [
    currentUserIdProvider.overrideWithValue(userId),
    socialGatewayProvider.overrideWithValue(social),
  ]);
  addTearDown(c.dispose);
  return c;
}

void main() {
  // (#) The challenges list provider that assembles each challenge summary.
  group('ViewChallenges (challengesProvider)', () {
    // (#) (+) Check if the summary has the right participant count, joined flag, my value, and named leaderboard.
    test('assembles counts, joined state, myValue and named standings', () async {
      final social = FakeSocialGateway()
        ..challenges = [
          (_challenge('c1'), ['u1', 'u2']),
          (_challenge('c2'), ['u2']),
        ]
        ..leaderboardRows = [
          (challengeId: 'c1', userId: 'u2', value: 8, rank: 1),
          (challengeId: 'c1', userId: 'u1', value: 5, rank: 2),
        ]
        ..profiles = [
          const PublicProfile(id: 'u2', firstName: 'Alex', lastName: 'Tan'),
        ];
      final c = _container(social);

      final all = await c.read(challengesProvider.future);
      final c1 = all.firstWhere((s) => s.challenge.id == 'c1');
      expect(c1.participantCount, 2);
      expect(c1.joined, isTrue);
      expect(c1.myValue, 5);
      expect(c1.standings.first.user?.displayName, 'Alex Tan');
      expect(c1.standings.first.rank, 1);

      final c2 = all.firstWhere((s) => s.challenge.id == 'c2');
      expect(c2.joined, isFalse);
      expect(c2.myValue, 0); // not ranked → zero progress
    });

    // (#) (-) Check if a signed-out user gets an empty challenges list.
    test('signed out → empty (negative)', () async {
      final social = FakeSocialGateway();
      final c = _container(social, userId: null);
      expect(await c.read(challengesProvider.future), isEmpty);
    });
  });

  // (#) The join and leave challenge controls.
  group('JoinChallenge / LeaveChallenge', () {
    // (#) (+) Check if joining records (challenge, user) and the list refetches showing joined.
    test('join records (id, user) and the list refetches as joined', () async {
      final social = FakeSocialGateway()
        ..challenges = [(_challenge('c1'), <String>[])];
      final c = _container(social);
      expect((await c.read(challengesProvider.future)).single.joined, isFalse);

      await c.read(joinChallengeProvider).call('c1');
      expect(social.joinCalls.single, ('c1', 'u1'));
      expect((await c.read(challengesProvider.future)).single.joined, isTrue);
    });

    // (#) (+) Check if leaving records (challenge, user) and the list shows not joined.
    test('leave removes participation', () async {
      final social = FakeSocialGateway()
        ..challenges = [
          (_challenge('c1'), ['u1'])
        ];
      final c = _container(social);

      await c.read(leaveChallengeProvider).call('c1');
      expect(social.leaveCalls.single, ('c1', 'u1'));
      expect((await c.read(challengesProvider.future)).single.joined, isFalse);
    });
  });

  // (#) The create challenge control.
  group('CreateChallenge', () {
    // (#) (+) Check if creating forwards the fields and the creator is auto-joined.
    test('forwards fields and the new challenge appears joined (auto-join)', () async {
      final social = FakeSocialGateway();
      final c = _container(social);

      final created = await c.read(createChallengeProvider).call({
        'name': 'My challenge',
        'short_name': 'MINE',
        'icon': '🎯',
        'metric_kind': 'accumulator',
        'metric': 'total_sessions',
        'target_value': 10,
      });
      expect(created, isNotNull);
      expect(social.createdChallenges.single['short_name'], 'MINE');
      final all = await c.read(challengesProvider.future);
      expect(all.single.joined, isTrue); // creator auto-joined
    });

    // (#) (-) Check if a signed-out user cannot create a challenge (nothing written).
    test('signed out → no-op (negative)', () async {
      final social = FakeSocialGateway();
      final c = _container(social, userId: null);
      expect(await c.read(createChallengeProvider).call({'name': 'x'}), isNull);
      expect(social.createdChallenges, isEmpty);
    });

    // (#) (-) Check if an accumulator challenge with a zero/negative target is rejected.
    test('accumulator with a non-positive target is rejected (negative)', () async {
      final social = FakeSocialGateway();
      final c = _container(social);
      final created = await c.read(createChallengeProvider).call({
        'short_name': 'BAD',
        'metric_kind': 'accumulator',
        'target_value': 0, // invalid for an accumulator
      });
      expect(created, isNull);
      expect(social.createdChallenges, isEmpty);
    });
  });

  // (#) The find-challenge-by-join-code control.
  group('FindChallengeByCode', () {
    // (#) (+) Check if a lowercase, space-padded code still resolves to the right challenge.
    test('resolves a code, upper-casing + trimming the input', () async {
      final social = FakeSocialGateway()
        ..challenges = [
          (_challenge('c1', code: 'K7QP2M'), <String>[]),
          (_challenge('c2', code: 'ABC123'), <String>[]),
        ];
      final c = _container(social);

      // typed lowercase with surrounding spaces still matches the stored code
      final found =
          await c.read(findChallengeByCodeProvider).call('  abc123 ');
      expect(found?.id, 'c2');
    });

    // (#) (-) Check if an unknown join code resolves to null.
    test('unknown code → null (negative)', () async {
      final social = FakeSocialGateway()
        ..challenges = [(_challenge('c1', code: 'K7QP2M'), <String>[])];
      final c = _container(social);
      expect(await c.read(findChallengeByCodeProvider).call('ZZZZZZ'), isNull);
    });

    // (#) (-) Check if a blank code returns null without querying the gateway.
    test('blank input → null without hitting the gateway (negative)', () async {
      final social = FakeSocialGateway()
        ..challenges = [(_challenge('c1', code: 'K7QP2M'), <String>[])];
      final c = _container(social);
      expect(await c.read(findChallengeByCodeProvider).call('   '), isNull);
    });
  });

  // (#) The single-challenge-by-id derived provider.
  group('challengeSummaryProvider', () {
    // (#) (+) Check if it pulls one challenge by id from the list, and an unknown id gives null.
    test('derives one challenge by id from the list', () async {
      final social = FakeSocialGateway()
        ..challenges = [
          (_challenge('c1'), ['u1']),
          (_challenge('c2'), <String>[]),
        ];
      final c = _container(social);

      final s = await c.read(challengeSummaryProvider('c2').future);
      expect(s?.challenge.id, 'c2');
      expect(await c.read(challengeSummaryProvider('nope').future), isNull);
    });
  });
}
