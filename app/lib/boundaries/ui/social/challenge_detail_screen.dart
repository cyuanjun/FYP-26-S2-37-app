import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../controls/authenticate.dart';
import '../../../controls/challenges.dart';
import '../../../core/theme/app_buttons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../entities/challenge_summary.dart';
import '../../../entities/enums.dart';
import '../common/app_card.dart';
import 'user_profile_screen.dart';

/// BOUNDARY (#11.3 Challenge Detail). Hero + your progress + how-it-works +
/// the full leaderboard (You highlighted, others link to #11.2), with the
/// Join / Leave action pinned to a footer band. Ended → caption only.
class ChallengeDetailScreen extends ConsumerWidget {
  const ChallengeDetailScreen({super.key, required this.challengeId});

  final String challengeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(challengeSummaryProvider(challengeId));

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar:
          AppBar(title: const Text('CHALLENGE', style: AppTypography.caption2)),
      bottomNavigationBar: summaryAsync.value == null
          ? null
          : _footer(context, ref, summaryAsync.value!),
      body: summaryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
            child: Text('Could not load challenge.',
                style: AppTypography.subheadline)),
        data: (summary) {
          if (summary == null) {
            return Center(
                child: Text('Challenge not found.',
                    style: AppTypography.subheadline));
          }
          final me = ref.watch(currentUserIdProvider);
          final c = summary.challenge;
          final now = DateTime.now();
          final (x, y) = c.dayXofY(now);

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              Text(
                  '${c.icon} ${c.shortName} · '
                  '${c.isPast(now) ? 'Ended' : 'Day $x/$y'} · '
                  '${summary.participantCount} joined',
                  style: AppTypography.caption2.copyWith(letterSpacing: 1.2)),
              const SizedBox(height: 6),
              Text(c.name, style: AppTypography.title2),
              if (c.description != null) ...[
                const SizedBox(height: 6),
                Text(c.description!,
                    style: AppTypography.subheadline.copyWith(height: 1.4)),
              ],
              if (summary.joined && c.isAccumulator) ...[
                const SizedBox(height: 16),
                Text('YOUR PROGRESS', style: AppTypography.caption2),
                const SizedBox(height: 8),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: summary.progressToTarget(),
                          minHeight: 8,
                          backgroundColor: AppColors.surface2,
                          valueColor:
                              const AlwaysStoppedAnimation(AppColors.accent),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                          '${c.formatValue(summary.myValue)} of '
                          '${c.formatValue(c.targetValue ?? 0)}',
                          style: AppTypography.footnote),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Text('HOW IT WORKS', style: AppTypography.caption2),
              const SizedBox(height: 8),
              Text(_howItWorks(summary), style: AppTypography.footnote),
              const SizedBox(height: 20),
              Text('LEADERBOARD', style: AppTypography.caption2),
              const SizedBox(height: 8),
              if (summary.standings.isEmpty)
                Text('No progress logged yet.', style: AppTypography.subheadline)
              else
                AppCard(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  child: Column(
                    children: [
                      for (final s in summary.standings)
                        _leaderRow(context, summary, s, isMe: s.userId == me),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  String _howItWorks(ChallengeSummary summary) {
    final c = summary.challenge;
    final scope = c.workoutTypeId == null
        ? 'Any workout counts'
        : 'Only matching workouts count';
    return c.isAccumulator
        ? '$scope — your qualifying sessions in the window add up toward '
            '${c.formatValue(c.targetValue ?? 0)}; the leaderboard ranks totals.'
        : '$scope — your single best effort in the window is ranked '
            '(${c.metric.label.toLowerCase()}).';
  }

  Widget _leaderRow(BuildContext context, ChallengeSummary summary,
      ChallengeStanding s,
      {required bool isMe}) {
    final medal = switch (s.rank) {
      1 => '🥇',
      2 => '🥈',
      3 => '🥉',
      _ => ' ${s.rank}.',
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 30, child: Text(medal, style: AppTypography.body)),
          Expanded(
            child: GestureDetector(
              onTap: isMe
                  ? null
                  : () => Navigator.of(context, rootNavigator: true).push(
                      MaterialPageRoute(
                          builder: (_) =>
                              UserProfileScreen(userId: s.userId))),
              child: Text(isMe ? 'You' : s.user?.displayName ?? 'Member',
                  style: AppTypography.body.copyWith(
                      color: isMe ? AppColors.accent : AppColors.ink,
                      fontWeight: isMe ? FontWeight.w700 : FontWeight.w500)),
            ),
          ),
          Text(summary.challenge.formatValue(s.value),
              style: AppTypography.headline),
        ],
      ),
    );
  }

  Widget _footer(BuildContext context, WidgetRef ref, ChallengeSummary summary) {
    final ended = summary.challenge.isPast(DateTime.now());
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: ended
            ? Text('This challenge has ended.',
                textAlign: TextAlign.center, style: AppTypography.footnote)
            : summary.joined
                ? OutlinedButton(
                    onPressed: () =>
                        ref.read(leaveChallengeProvider).call(challengeId),
                    style: AppButtonStyles.outlinedDanger(height: 48),
                    child: const Text('Leave Challenge'),
                  )
                : ElevatedButton(
                    onPressed: () =>
                        ref.read(joinChallengeProvider).call(challengeId),
                    child: const Text('Join Challenge'),
                  ),
      ),
    );
  }
}
