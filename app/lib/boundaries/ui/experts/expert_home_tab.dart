import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../controls/authenticate.dart';
import '../../../controls/browse_experts.dart';
import '../../../controls/expert_requests.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../common/app_card.dart';
import '../common/stat_tile.dart';

// (#) The expert dashboard home. A greeting plus reputation stats and today's workload numbers,
// (#) all read from the controls. Nothing is written here.
class ExpertHomeTab extends ConsumerWidget {
  const ExpertHomeTab({super.key});

  // (#) Reads the expert's summary and incoming requests, then shows greeting, stat cards and workload.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(currentUserIdProvider);
    final profile = ref.watch(currentProfileProvider).value;
    final summary =
        me == null ? null : ref.watch(expertSummaryProvider(me)).value;
    final requests = ref.watch(incomingRequestsProvider).value ?? [];
    final pending = requests.where((r) => r.request.isPending).length;
    final active = requests.where((r) => r.request.isAccepted).length;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        titleSpacing: 20,
        title: const Text('Wise Workout — Expert'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Hi, ${profile?.firstName ?? 'Coach'} 👋',
              style: AppTypography.title1),
          const SizedBox(height: 4),
          Text(
              summary?.profile.isVerified ?? false
                  ? '${summary!.profile.title} · ✓ Verified expert'
                  : summary?.profile.title ?? 'Expert',
              style: AppTypography.subheadline),
          const SizedBox(height: 24),
          AppCard(
            child: Row(
              children: [
                StatTile('RATING', '★ ${summary?.profile.ratingAvg ?? '—'}',
                    valueFirst: true),
                StatTile('REVIEWS', '${summary?.profile.reviewCount ?? '—'}',
                    valueFirst: true),
                StatTile('CLIENTS', '${summary?.profile.clientCount ?? '—'}',
                    valueFirst: true),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            borderColor: AppColors.faint,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Your workload', style: AppTypography.headline),
                const SizedBox(height: 10),
                Row(
                  children: [
                    StatTile('NEW REQUESTS', '$pending', valueFirst: true),
                    StatTile('ACTIVE', '$active', valueFirst: true),
                    StatTile('LIVE SERVICES',
                        '${summary?.services.where((s) => s.status.name == 'live').length ?? 0}',
                        valueFirst: true),
                  ],
                ),
                if (pending > 0) ...[
                  const SizedBox(height: 10),
                  Text(
                      pending == 1
                          ? '1 request is waiting for your answer — see Requests.'
                          : '$pending requests are waiting for your answer — see Requests.',
                      style: AppTypography.footnote
                          .copyWith(color: AppColors.premiumText)),
                ],
                const Divider(color: AppColors.faint, height: 24),
                Row(
                  children: [
                    Expanded(
                        child: Text('Earned to date (simulated)',
                            style: AppTypography.footnote)),
                    Text(summary?.profile.earnedLabel ?? r'$0',
                        style: AppTypography.title3
                            .copyWith(color: AppColors.success)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
