import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../boundaries/gateways/social_gateway.dart';
import '../core/seq_log.dart';
import '../entities/challenge.dart';
import '../entities/enums.dart';
import '../entities/workout_session.dart';
import 'authenticate.dart';

// ── Progress helpers ──────────────────────────────────────────────────────────

/// Computed progress for one participant on a challenge.
class ParticipantRank {
  const ParticipantRank({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    required this.value,
    required this.rank,
    this.isCurrentUser = false,
  });

  final String userId;
  final String displayName;
  final String? avatarUrl;

  /// The metric value — distance in metres, seconds, calorie count, or count.
  final double value;

  /// 1-indexed rank on the leaderboard.
  final int rank;
  final bool isCurrentUser;

  String formattedValue(ChallengeMetric metric) {
    switch (metric) {
      case ChallengeMetric.totalDistance:
      case ChallengeMetric.longestDistance:
        return '${(value / 1000).toStringAsFixed(1)} km';
      case ChallengeMetric.fastestTime:
        final secs = value.toInt();
        final m = secs ~/ 60;
        final s = secs % 60;
        return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
      case ChallengeMetric.totalCalories:
      case ChallengeMetric.mostCalories:
        return '${value.toInt()} kcal';
      case ChallengeMetric.totalSessions:
      case ChallengeMetric.activeDays:
        return '${value.toInt()}';
    }
  }
}

/// Ranks [participants] for a given [challenge] using their sessions in the window.
/// Returns only participants with at least one qualifying session.
List<ParticipantRank> rankParticipants({
  required Challenge challenge,
  required List<Map<String, dynamic>> participants, // from fetchParticipantsWithProfiles
  required Map<String, List<WorkoutSession>> sessionsByUser,
  required String currentUserId,
}) {
  final entries = <({String userId, String name, String? avatar, double value})>[];

  for (final p in participants) {
    final userId = p['user_id'] as String;
    final profile = p['profile'] as Map<String, dynamic>?;
    final first = profile?['first_name'] as String? ?? '';
    final last = profile?['last_name'] as String? ?? '';
    final name = '$first $last'.trim().isNotEmpty
        ? '$first $last'.trim()
        : (profile?['username'] as String? ?? 'User');
    final avatar = profile?['avatar_url'] as String?;
    final sessions = sessionsByUser[userId] ?? const [];
    if (sessions.isEmpty) continue;

    double value;
    if (challenge.metricKind == ChallengeMetricKind.accumulator) {
      value = _accumulate(challenge.metric, sessions);
    } else {
      value = _bestOf(challenge.metric, sessions);
    }
    if (value <= 0) continue;
    entries.add((userId: userId, name: name, avatar: avatar, value: value));
  }

  final ascending = challenge.metric == ChallengeMetric.fastestTime;
  entries.sort((a, b) =>
      ascending ? a.value.compareTo(b.value) : b.value.compareTo(a.value));

  return entries.indexed
      .map((e) => ParticipantRank(
            userId: e.$2.userId,
            displayName: e.$2.name,
            avatarUrl: e.$2.avatar,
            value: e.$2.value,
            rank: e.$1 + 1,
            isCurrentUser: e.$2.userId == currentUserId,
          ))
      .toList();
}

double _accumulate(ChallengeMetric metric, List<WorkoutSession> sessions) {
  return switch (metric) {
    ChallengeMetric.totalDistance =>
      sessions.fold(0.0, (s, w) => s + (w.distanceMeters ?? 0)),
    ChallengeMetric.totalSessions => sessions.length.toDouble(),
    ChallengeMetric.totalCalories =>
      sessions.fold(0.0, (s, w) => s + (w.caloriesBurned ?? 0)),
    ChallengeMetric.activeDays => sessions
        .map((w) => w.startedAt.toUtc().toString().substring(0, 10))
        .toSet()
        .length
        .toDouble(),
    _ => 0,
  };
}

double _bestOf(ChallengeMetric metric, List<WorkoutSession> sessions) {
  if (sessions.isEmpty) return 0;
  return switch (metric) {
    ChallengeMetric.fastestTime => sessions
        .map((s) => s.durationSeconds.toDouble())
        .where((v) => v > 0)
        .fold(double.infinity, (a, b) => a < b ? a : b)
        .clamp(0, double.infinity),
    ChallengeMetric.longestDistance => sessions
        .map((s) => (s.distanceMeters ?? 0).toDouble())
        .fold(0.0, (a, b) => a > b ? a : b),
    ChallengeMetric.mostCalories => sessions
        .map((s) => (s.caloriesBurned ?? 0).toDouble())
        .fold(0.0, (a, b) => a > b ? a : b),
    ChallengeMetric.totalSessions => sessions.length.toDouble(),
    _ => 0,
  };
}

// ── Controls ──────────────────────────────────────────────────────────────────

/// CONTROL — CreateChallenge: inserts a new challenge row and auto-joins the
/// creator as a participant (US25). Invalidates all challenge providers.
class CreateChallenge {
  CreateChallenge(this._ref);

  final Ref _ref;

  Future<Challenge> call(Map<String, dynamic> formData) async {
    final userId = _ref.read(currentUserIdProvider)!;
    SeqLog.msg('create-challenge', 'SocialTab', 'CreateChallenge',
        'create(${formData['name']})');
    SeqLog.msg('create-challenge', 'CreateChallenge', 'SocialGateway',
        'createChallenge(creatorId=$userId)');
    final challenge =
        await _ref.read(socialGatewayProvider).createChallenge(
              creatorId: userId,
              data: formData,
            );
    _ref.invalidate(joinedChallengesProvider);
    _ref.invalidate(activeChallengesProvider);
    return challenge;
  }
}

final createChallengeProvider =
    Provider<CreateChallenge>(CreateChallenge.new);

/// CONTROL — JoinChallenge: adds the current user to a challenge (US25).
class JoinChallenge {
  JoinChallenge(this._ref);

  final Ref _ref;

  Future<void> call(String challengeId) async {
    final userId = _ref.read(currentUserIdProvider)!;
    SeqLog.msg('join-challenge', 'ChallengeDetailScreen', 'JoinChallenge',
        'join($challengeId)');
    SeqLog.msg('join-challenge', 'JoinChallenge', 'SocialGateway',
        'joinChallenge($challengeId, $userId)');
    await _ref.read(socialGatewayProvider).joinChallenge(challengeId, userId);
    _ref.invalidate(joinedChallengesProvider);
    _ref.invalidate(challengeParticipantIdsProvider(challengeId));
  }
}

final joinChallengeProvider = Provider<JoinChallenge>(JoinChallenge.new);

/// CONTROL — LeaveChallenge: removes the current user from a challenge (US25).
class LeaveChallenge {
  LeaveChallenge(this._ref);

  final Ref _ref;

  Future<void> call(String challengeId) async {
    final userId = _ref.read(currentUserIdProvider)!;
    SeqLog.msg('leave-challenge', 'ChallengeDetailScreen', 'LeaveChallenge',
        'leave($challengeId)');
    SeqLog.msg('leave-challenge', 'LeaveChallenge', 'SocialGateway',
        'leaveChallenge($challengeId, $userId)');
    await _ref.read(socialGatewayProvider).leaveChallenge(challengeId, userId);
    _ref.invalidate(joinedChallengesProvider);
    _ref.invalidate(challengeParticipantIdsProvider(challengeId));
  }
}

final leaveChallengeProvider = Provider<LeaveChallenge>(LeaveChallenge.new);

// ── Read-side providers ───────────────────────────────────────────────────────

/// Challenges the current user has joined that are still active (Joined tab).
final joinedChallengesProvider = FutureProvider<List<Challenge>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const [];
  SeqLog.msg('view-challenges', 'SocialTab', 'SocialGateway',
      'fetchJoinedChallenges($userId)');
  return ref.read(socialGatewayProvider).fetchJoinedChallenges(userId);
});

/// All public in-progress challenges for the Active sub-tab.
final activeChallengesProvider = FutureProvider<List<Challenge>>((ref) async {
  SeqLog.msg('view-challenges', 'SocialTab', 'SocialGateway',
      'fetchActiveChallenges()');
  return ref.read(socialGatewayProvider).fetchActiveChallenges();
});

/// Challenges the current user joined that have ended (Past tab).
final pastChallengesProvider = FutureProvider<List<Challenge>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const [];
  SeqLog.msg('view-challenges', 'SocialTab', 'SocialGateway',
      'fetchPastChallenges($userId)');
  return ref.read(socialGatewayProvider).fetchPastChallenges(userId);
});

/// Set of user IDs who have joined [challengeId]. Used to show Join/Leave state.
final challengeParticipantIdsProvider =
    FutureProvider.family<Set<String>, String>((ref, challengeId) async {
  return ref.read(socialGatewayProvider).fetchParticipantIds(challengeId);
});

/// Participants with profile data for the leaderboard on #11.3.
final challengeParticipantsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, challengeId) async {
  return ref.read(socialGatewayProvider).fetchParticipantsWithProfiles(challengeId);
});

/// Ranked leaderboard for a challenge. Keyed by challengeId.
/// Fetches all participants' sessions in the challenge window and computes ranks.
final challengeLeaderboardProvider =
    FutureProvider.family<List<ParticipantRank>, String>(
        (ref, challengeId) async {
  final currentUserId = ref.watch(currentUserIdProvider);
  final gw = ref.read(socialGatewayProvider);

  final challenge = await gw.fetchChallengeById(challengeId);
  final participants =
      await ref.watch(challengeParticipantsProvider(challengeId).future);

  final sessionsByUser = <String, List<WorkoutSession>>{};
  await Future.wait(participants.map((p) async {
    final uid = p['user_id'] as String;
    final sessions = await gw.fetchSessionsInWindow(
      userId: uid,
      windowStart: challenge.startedAt,
      windowEnd: challenge.endedAt,
      workoutTypeId: challenge.workoutTypeId,
    );
    sessionsByUser[uid] = sessions;
  }));

  return rankParticipants(
    challenge: challenge,
    participants: participants,
    sessionsByUser: sessionsByUser,
    currentUserId: currentUserId ?? '',
  );
});

/// The current user's personal progress value for an accumulator challenge.
final myProgressProvider =
    FutureProvider.family<double, String>((ref, challengeId) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return 0;
  final gw = ref.read(socialGatewayProvider);
  final challenge = await gw.fetchChallengeById(challengeId);
  if (challenge.metricKind != ChallengeMetricKind.accumulator) return 0;
  final sessions = await gw.fetchSessionsInWindow(
    userId: userId,
    windowStart: challenge.startedAt,
    windowEnd: challenge.endedAt,
    workoutTypeId: challenge.workoutTypeId,
  );
  return _accumulate(challenge.metric, sessions);
});
