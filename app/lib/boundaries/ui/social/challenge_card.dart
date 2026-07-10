import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../controls/authenticate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../entities/challenge_summary.dart';
import '../common/app_card.dart';
import 'challenge_detail_screen.dart';

// (#) One challenge's card in the list. Shows the time window, how many joined,
// (#) a progress bar and a small leaderboard preview. Tapping anywhere on it
// (#) opens the challenge detail screen.
class ChallengeCard extends ConsumerWidget {
  const ChallengeCard({super.key, required this.summary});

  final ChallengeSummary summary; // (#) the challenge plus its standings and my progress

  // (#) Builds the card: header row, name, description, progress bar and top-3 preview.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(currentUserIdProvider);
    final c = summary.challenge;
    final now = DateTime.now();
    final (x, y) = c.dayXofY(now);
    final windowLabel = c.isPast(now) ? 'Ended' : 'Day $x/$y';

    // Top 3 + my row if I'm ranked below the preview.
    final preview = summary.standings.take(3).toList();
    final mine =
        summary.standings.where((s) => s.userId == me).firstOrNull;
    if (mine != null && !preview.any((s) => s.userId == me)) {
      preview.add(mine);
    }

    return GestureDetector(
      onTap: () => Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute(
              builder: (_) => ChallengeDetailScreen(challengeId: c.id))),
      child: AppCard(
        margin: const EdgeInsets.only(bottom: 12),
        borderColor: AppColors.faint,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(c.icon, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(c.shortName,
                      style: AppTypography.caption2.copyWith(
                          letterSpacing: 1.2, fontWeight: FontWeight.w800)),
                ),
                Text('$windowLabel · ${summary.participantCount} joined',
                    style: AppTypography.caption2),
              ],
            ),
            const SizedBox(height: 6),
            Text(c.name, style: AppTypography.headline),
            if (c.description != null) ...[
              const SizedBox(height: 2),
              Text(c.description!,
                  style: AppTypography.footnote,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],
            if (summary.joined && c.isAccumulator) ...[
              const SizedBox(height: 10),
              _progressBar(),
            ],
            if (preview.isNotEmpty) ...[
              const Divider(color: AppColors.faint, height: 20),
              for (final s in preview) _standingRow(s, isMe: s.userId == me),
            ],
          ],
        ),
      ),
    );
  }

  // (#) Builds the accumulator bar showing my value against the target.
  Widget _progressBar() {
    final c = summary.challenge;
    final progress = summary.progressToTarget();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: AppColors.surface2,
            valueColor: const AlwaysStoppedAnimation(AppColors.accent),
          ),
        ),
        const SizedBox(height: 4),
        Text(
            '${c.formatValue(summary.myValue)} of '
            '${c.formatValue(c.targetValue ?? 0)}',
            style: AppTypography.caption2),
      ],
    );
  }

  // (#) Builds one leaderboard line: medal or rank number, name, and value.
  Widget _standingRow(ChallengeStanding s, {required bool isMe}) {
    final medal = switch (s.rank) {
      1 => '🥇',
      2 => '🥈',
      3 => '🥉',
      _ => ' ${s.rank}.',
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 28, child: Text(medal, style: AppTypography.footnote)),
          Expanded(
            child: Text(isMe ? 'You' : s.user?.displayName ?? 'Member',
                style: AppTypography.footnote.copyWith(
                    color: isMe ? AppColors.accent : AppColors.ink,
                    fontWeight: isMe ? FontWeight.w700 : FontWeight.w500)),
          ),
          Text(summary.challenge.formatValue(s.value),
              style: AppTypography.footnote),
        ],
      ),
    );
  }
}
