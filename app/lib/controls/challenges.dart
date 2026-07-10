import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../boundaries/gateways/social_gateway.dart';
import '../core/seq_log.dart';
import '../entities/challenge.dart';
import '../entities/challenge_summary.dart';
import '../entities/validators.dart';
import 'authenticate.dart';

// (#) Loads everything the Challenges tab needs in one go: the challenges, their
// (#) participants, the batched leaderboard RPC, and the public profiles of the
// (#) people on each board. Builds a ChallengeSummary per challenge with the
// (#) caller's own value and the standings; the UI splits Joined/Active/Past.
final challengesProvider =
    FutureProvider<List<ChallengeSummary>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const <ChallengeSummary>[];
  final gateway = ref.watch(socialGatewayProvider);

  SeqLog.msg('view-challenges', 'ViewChallenges', 'SocialGateway',
      'listChallenges');
  final rows = await gateway.listChallenges();

  SeqLog.msg('view-challenges', 'ViewChallenges', 'SocialGateway',
      'challenge_leaderboards(rpc, ${rows.length} ids)');
  final boards =
      await gateway.leaderboards([for (final (c, _) in rows) c.id]);

  final profileIds = boards.map((b) => b.userId).toSet().toList();
  final profiles = {
    for (final p in await gateway.profilesByIds(profileIds)) p.id: p,
  };

  return [
    for (final (challenge, participants) in rows)
      ChallengeSummary(
        challenge: challenge,
        participantCount: participants.length,
        joined: participants.contains(userId),
        myValue: boards
                .where((b) =>
                    b.challengeId == challenge.id && b.userId == userId)
                .firstOrNull
                ?.value ??
            0,
        standings: [
          for (final b in boards.where((b) => b.challengeId == challenge.id))
            ChallengeStanding(
                userId: b.userId,
                value: b.value,
                rank: b.rank,
                user: profiles[b.userId]),
        ],
      ),
  ];
});

// (#) Pulls one challenge's summary out of the loaded list by id for the detail
// (#) screen; no extra fetch.
final challengeSummaryProvider =
    FutureProvider.family<ChallengeSummary?, String>((ref, id) async {
  final all = await ref.watch(challengesProvider.future);
  return all.where((s) => s.challenge.id == id).firstOrNull;
});

// (#) Signs the current user up for a challenge. Reads their id, calls the social
// (#) gateway to join, then reloads the challenge list so the card flips.
class JoinChallenge {
  JoinChallenge(this._ref);

  final Ref _ref; // (#) Riverpod handle for reading the gateway and user id

  // (#) Joins the given challenge for the signed-in user.
  Future<void> call(String challengeId) async {
    final userId = _ref.read(currentUserIdProvider);
    if (userId == null) return;
    SeqLog.msg('join-challenge', 'ChallengeDetailScreen', 'JoinChallenge',
        'join($challengeId)');
    SeqLog.msg('join-challenge', 'JoinChallenge', 'SocialGateway',
        'joinChallenge');
    await _ref.read(socialGatewayProvider).joinChallenge(challengeId, userId);
    _ref.invalidate(challengesProvider);
  }
}

// (#) Undoes a join. Calls the gateway to drop the user from the challenge, then
// (#) reloads the list so the card flips back to not-joined.
class LeaveChallenge {
  LeaveChallenge(this._ref);

  final Ref _ref; // (#) Riverpod handle for reading the gateway and user id

  // (#) Removes the signed-in user from the given challenge.
  Future<void> call(String challengeId) async {
    final userId = _ref.read(currentUserIdProvider);
    if (userId == null) return;
    SeqLog.msg('leave-challenge', 'ChallengeDetailScreen', 'LeaveChallenge',
        'leave($challengeId)');
    await _ref
        .read(socialGatewayProvider)
        .leaveChallenge(challengeId, userId);
    _ref.invalidate(challengesProvider);
  }
}

// (#) Creates a brand-new challenge. For accumulator challenges it first checks
// (#) the target is positive, then saves it through the gateway (which auto-joins
// (#) the creator) and reloads the list. Returns the new challenge, or null if
// (#) not signed in or the target failed validation.
class CreateChallenge {
  CreateChallenge(this._ref);

  final Ref _ref; // (#) Riverpod handle for reading the gateway and user id

  // (#) Validates then persists a new challenge from the sheet's field map.
  Future<Challenge?> call(Map<String, dynamic> fields) async {
    final userId = _ref.read(currentUserIdProvider);
    if (userId == null) return null;
    // An accumulator challenge races a positive target — reject otherwise.
    if (fields['metric_kind'] == 'accumulator' &&
        !Validators.validPositiveTarget(fields['target_value'] as num?)) {
      return null;
    }
    SeqLog.msg('create-challenge', 'CreateChallengeSheet', 'CreateChallenge',
        'create(${fields['short_name']})');
    SeqLog.msg('create-challenge', 'CreateChallenge', 'SocialGateway',
        'createChallenge');
    final challenge = await _ref
        .read(socialGatewayProvider)
        .createChallenge(userId: userId, fields: fields);
    _ref.invalidate(challengesProvider);
    return challenge;
  }
}

// (#) Resolves a shared join code to a challenge so the UI can open its detail
// (#) before the user joins. Codes are stored uppercase, so the typed input is
// (#) trimmed and upper-cased here first.
class FindChallengeByCode {
  FindChallengeByCode(this._ref);

  final Ref _ref; // (#) Riverpod handle for reading the gateway

  // (#) Normalises the code and asks the gateway to find the matching challenge.
  Future<Challenge?> call(String code) async {
    final normalised = code.trim().toUpperCase();
    if (normalised.isEmpty) return null;
    SeqLog.msg('find-challenge-by-code', 'ChallengesTab', 'FindChallengeByCode',
        'find($normalised)');
    SeqLog.msg('find-challenge-by-code', 'FindChallengeByCode', 'SocialGateway',
        'findChallengeByCode');
    return _ref.read(socialGatewayProvider).findChallengeByCode(normalised);
  }
}

// (#) Providers that hand the challenge screens each of the four controls above.
final joinChallengeProvider = Provider<JoinChallenge>(JoinChallenge.new);
final leaveChallengeProvider = Provider<LeaveChallenge>(LeaveChallenge.new);
final createChallengeProvider = Provider<CreateChallenge>(CreateChallenge.new);
final findChallengeByCodeProvider =
    Provider<FindChallengeByCode>(FindChallengeByCode.new);
