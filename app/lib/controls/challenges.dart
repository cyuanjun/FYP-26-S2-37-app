import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../boundaries/gateways/social_gateway.dart';
import '../core/seq_log.dart';
import '../entities/challenge.dart';
import '../entities/challenge_summary.dart';
import 'authenticate.dart';

/// CONTROL — View Challenges (US25, #11 Challenges tab + #11.3 detail).
/// One fetch assembles every card: challenges + participants + the batched
/// leaderboard RPC + the standings' public profiles. The UI partitions
/// Joined / Active / Past with the entity's window rules.
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

/// One challenge's summary, for #11.3 (derived — no extra fetch).
final challengeSummaryProvider =
    FutureProvider.family<ChallengeSummary?, String>((ref, id) async {
  final all = await ref.watch(challengesProvider.future);
  return all.where((s) => s.challenge.id == id).firstOrNull;
});

/// CONTROL — Join Challenge (bce-design §5.5).
class JoinChallenge {
  JoinChallenge(this._ref);

  final Ref _ref;

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

/// CONTROL — Leave Challenge.
class LeaveChallenge {
  LeaveChallenge(this._ref);

  final Ref _ref;

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

/// CONTROL — Create Challenge (creator auto-joins in the gateway).
class CreateChallenge {
  CreateChallenge(this._ref);

  final Ref _ref;

  Future<Challenge?> call(Map<String, dynamic> fields) async {
    final userId = _ref.read(currentUserIdProvider);
    if (userId == null) return null;
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

/// CONTROL — Find Challenge by Code (#11). Resolves a shared join code to a
/// challenge so the UI can open its detail before the user joins. Codes are
/// stored uppercase; input is trimmed + upper-cased here.
class FindChallengeByCode {
  FindChallengeByCode(this._ref);

  final Ref _ref;

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

final joinChallengeProvider = Provider<JoinChallenge>(JoinChallenge.new);
final leaveChallengeProvider = Provider<LeaveChallenge>(LeaveChallenge.new);
final createChallengeProvider = Provider<CreateChallenge>(CreateChallenge.new);
final findChallengeByCodeProvider =
    Provider<FindChallengeByCode>(FindChallengeByCode.new);
