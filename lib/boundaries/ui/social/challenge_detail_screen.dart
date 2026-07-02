import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../controls/authenticate.dart';
import '../../../controls/challenge_control.dart';
import '../../../boundaries/gateways/social_gateway.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../entities/enums.dart';
import 'user_profile_screen.dart';

/// BOUNDARY (#11.3 Challenge Detail). Hero header, accumulator progress bar,
/// leaderboard, and a pinned Join / Leave footer (US25 / US26).
class ChallengeDetailScreen extends ConsumerWidget {
  const ChallengeDetailScreen({super.key, required this.challengeId});

  final String challengeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challengeAsync = ref.watch(
      FutureProvider.autoDispose((ref) =>
          ref.read(socialGatewayProvider).fetchChallengeById(challengeId)),
    );
    final participantIdsAsync =
        ref.watch(challengeParticipantIdsProvider(challengeId));
    final leaderboardAsync =
        ref.watch(challengeLeaderboardProvider(challengeId));
    final myProgressAsync =
        ref.watch(myProgressProvider(challengeId));
    final currentUserId = ref.watch(currentUserIdProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: challengeAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.accent)),
        error: (e, _) => Center(
            child: Text('Could not load challenge: $e',
                style: AppTypography.subheadline)),
        data: (challenge) {
          final hasJoined =
              participantIdsAsync.value?.contains(currentUserId) ?? false;
          final participantCount =
              participantIdsAsync.value?.length ?? 0;

          return Stack(
            children: [
              CustomScrollView(
                slivers: [
                  // ── Hero header ─────────────────────────────────────────
                  SliverAppBar(
                    expandedHeight: 200,
                    pinned: true,
                    backgroundColor: AppColors.surface,
                    leading: const BackButton(color: AppColors.ink),
                    flexibleSpace: FlexibleSpaceBar(
                      titlePadding:
                          const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      title: Text(
                        challenge.name,
                        style: AppTypography.headline,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      background: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [AppColors.surface2, AppColors.surface],
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.emoji_events_outlined,
                            size: 72,
                            color: AppColors.accent.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding:
                          const EdgeInsets.fromLTRB(20, 16, 20, 100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Status chips ───────────────────────────────
                          Wrap(
                            spacing: 8,
                            children: [
                              _Chip(
                                label: challenge.isActive
                                    ? 'LIVE'
                                    : challenge.isEnded
                                        ? 'ENDED'
                                        : 'UPCOMING',
                                color: challenge.isActive
                                    ? AppColors.accent
                                    : AppColors.muted,
                              ),
                              _Chip(
                                label: challenge.visibility ==
                                        ChallengeVisibility.public
                                    ? 'PUBLIC'
                                    : 'INVITE ONLY',
                                color: AppColors.muted,
                              ),
                              _Chip(
                                label:
                                    '$participantCount JOINED',
                                color: AppColors.muted,
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // ── Date range ─────────────────────────────────
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                    child: _DateBlock(
                                  label: 'START',
                                  date: challenge.startedAt,
                                )),
                                const Icon(Icons.arrow_forward,
                                    color: AppColors.muted, size: 18),
                                Expanded(
                                    child: _DateBlock(
                                  label: 'END',
                                  date: challenge.endedAt,
                                  align: TextAlign.right,
                                )),
                              ],
                            ),
                          ),

                          if (challenge.description != null &&
                              challenge.description!.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Text(challenge.description!,
                                style: AppTypography.body),
                          ],

                          // ── Metric info ────────────────────────────────
                          const SizedBox(height: 20),
                          Text('METRIC', style: AppTypography.caption2),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.bar_chart_outlined,
                                    color: AppColors.accent, size: 22),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(challenge.metric.label,
                                          style: AppTypography.headline),
                                      Text(
                                        '${_kindLabel(challenge.metricKind)} · ${challenge.metric.unit}',
                                        style: AppTypography.footnote,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // ── My progress bar (accumulator only) ─────────
                          if (hasJoined &&
                              challenge.metricKind ==
                                  ChallengeMetricKind.accumulator) ...[
                            const SizedBox(height: 20),
                            Text('MY PROGRESS',
                                style: AppTypography.caption2),
                            const SizedBox(height: 8),
                            myProgressAsync.when(
                              loading: () =>
                                  const LinearProgressIndicator(),
                              error: (_, _) => const SizedBox.shrink(),
                              data: (progress) {
                                final topValue = leaderboardAsync.value
                                        ?.isNotEmpty ==
                                    true
                                    ? leaderboardAsync.value!.first.value
                                    : 0.0;
                                final ratio = topValue > 0
                                    ? (progress / topValue)
                                        .clamp(0.0, 1.0)
                                    : 0.0;
                                return _ProgressBar(
                                  value: progress,
                                  ratio: ratio,
                                  metric: challenge.metric,
                                  days: challenge.totalDays,
                                  currentDay:
                                      challenge.isEnded
                                          ? challenge.totalDays
                                          : challenge
                                              .currentDayNumber,
                                );
                              },
                            ),
                          ],

                          // ── Leaderboard ────────────────────────────────
                          const SizedBox(height: 24),
                          Text('LEADERBOARD',
                              style: AppTypography.caption2),
                          const SizedBox(height: 8),
                          leaderboardAsync.when(
                            loading: () => const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Center(
                                  child: CircularProgressIndicator(
                                      color: AppColors.accent)),
                            ),
                            error: (e, _) => Text('$e',
                                style: AppTypography.subheadline),
                            data: (ranks) {
                              if (ranks.isEmpty) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 24),
                                  child: Center(
                                    child: Text(
                                      'No activity yet. '
                                      'Complete workouts to appear here.',
                                      style: AppTypography.subheadline,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                );
                              }
                              return Column(
                                children: ranks
                                    .map((r) => _LeaderboardRow(
                                          rank: r,
                                          metric: challenge.metric,
                                        ))
                                    .toList(),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // ── Pinned footer ────────────────────────────────────────────
              if (!challenge.isEnded)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _JoinLeaveFooter(
                    challengeId: challengeId,
                    hasJoined: hasJoined,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  static String _kindLabel(ChallengeMetricKind k) => switch (k) {
        ChallengeMetricKind.accumulator => 'Accumulator',
        ChallengeMetricKind.bestOf => 'Best Of',
      };
}

// ── Progress bar ──────────────────────────────────────────────────────────────

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({
    required this.value,
    required this.ratio,
    required this.metric,
    required this.days,
    required this.currentDay,
  });

  final double value;
  final double ratio;
  final ChallengeMetric metric;
  final int days;
  final int currentDay;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                ParticipantRank(
                  userId: '',
                  displayName: '',
                  value: value,
                  rank: 0,
                ).formattedValue(metric),
                style: AppTypography.title3
                    .copyWith(color: AppColors.accent),
              ),
              Text('Day $currentDay / $days',
                  style: AppTypography.footnote),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              backgroundColor: AppColors.surface2,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.accent),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            ratio >= 1.0
                ? 'You\'re in the lead!'
                : '${(ratio * 100).toStringAsFixed(0)}% of the top score',
            style: AppTypography.caption1,
          ),
        ],
      ),
    );
  }
}

// ── Leaderboard row ───────────────────────────────────────────────────────────

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({required this.rank, required this.metric});

  final ParticipantRank rank;
  final ChallengeMetric metric;

  @override
  Widget build(BuildContext context) {
    final isTop3 = rank.rank <= 3;
    final medals = {1: '🥇', 2: '🥈', 3: '🥉'};

    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => UserProfileScreen(userId: rank.userId))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: rank.isCurrentUser
              ? AppColors.accent.withValues(alpha: 0.1)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: rank.isCurrentUser
              ? Border.all(
                  color: AppColors.accent.withValues(alpha: 0.4))
              : null,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 32,
              child: isTop3
                  ? Text(medals[rank.rank]!,
                      style: const TextStyle(fontSize: 20),
                      textAlign: TextAlign.center)
                  : Text(
                      '#${rank.rank}',
                      style: AppTypography.subheadline,
                      textAlign: TextAlign.center,
                    ),
            ),
            const SizedBox(width: 10),
            _Avatar(
                url: rank.avatarUrl,
                name: rank.displayName,
                radius: 16),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                rank.isCurrentUser ? 'You' : rank.displayName,
                style: AppTypography.subheadline.copyWith(
                    color: rank.isCurrentUser
                        ? AppColors.accent
                        : AppColors.ink),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              rank.formattedValue(metric),
              style: AppTypography.headline
                  .copyWith(color: AppColors.ink),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Join / Leave footer ───────────────────────────────────────────────────────

class _JoinLeaveFooter extends ConsumerWidget {
  const _JoinLeaveFooter(
      {required this.challengeId, required this.hasJoined});

  final String challengeId;
  final bool hasJoined;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(
            top: BorderSide(color: AppColors.faint)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: hasJoined
            ? OutlinedButton(
                onPressed: () => _confirmLeave(context, ref),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: AppColors.danger),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('LEAVE CHALLENGE'),
              )
            : ElevatedButton(
                onPressed: () =>
                    ref.read(joinChallengeProvider).call(challengeId),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.bg,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('JOIN CHALLENGE'),
              ),
      ),
    );
  }

  void _confirmLeave(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Leave challenge?',
            style: AppTypography.headline),
        content: const Text(
            'Your progress will be removed from the leaderboard.',
            style: AppTypography.subheadline),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () {
                Navigator.pop(context);
                ref.read(leaveChallengeProvider).call(challengeId);
              },
              child: const Text('Leave',
                  style: TextStyle(color: AppColors.danger))),
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: AppTypography.caption2.copyWith(color: color)),
    );
  }
}

class _DateBlock extends StatelessWidget {
  const _DateBlock(
      {required this.label, required this.date, this.align = TextAlign.left});

  final String label;
  final DateTime date;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: align == TextAlign.right
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.caption2),
        const SizedBox(height: 4),
        Text('${date.day}/${date.month}/${date.year}',
            style:
                AppTypography.subheadline.copyWith(color: AppColors.ink)),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar(
      {required this.url, required this.name, required this.radius});

  final String? url;
  final String name;
  final double radius;

  @override
  Widget build(BuildContext context) {
    if (url != null && url!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(url!),
        backgroundColor: AppColors.surface2,
      );
    }
    final init = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.surface2,
      child: Text(init,
          style: AppTypography.caption1
              .copyWith(color: AppColors.ink, fontWeight: FontWeight.w600)),
    );
  }
}
