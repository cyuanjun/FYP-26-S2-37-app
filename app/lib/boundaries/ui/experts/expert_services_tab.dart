import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../controls/authenticate.dart';
import '../../../controls/browse_experts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../entities/enums.dart';
import '../common/app_card.dart';
import '../common/status_badge.dart';

/// BOUNDARY (#21 Expert Services). The expert's own listings, including
/// drafts/archived (owner-visible via RLS). Read-only in this realization —
/// PublishService / Create-Edit (#21.2) remain deferred.
class ExpertServicesTab extends ConsumerWidget {
  const ExpertServicesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(currentUserIdProvider);
    final summary =
        me == null ? null : ref.watch(expertSummaryProvider(me)).value;
    final services = summary?.services ?? [];

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        titleSpacing: 20,
        title: const Text('SERVICES', style: AppTypography.title1),
      ),
      body: services.isEmpty
          ? Center(
              child: Text('No services yet.', style: AppTypography.subheadline))
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                for (final s in services)
                  AppCard(
                    margin: const EdgeInsets.only(bottom: 12),
                    borderColor: AppColors.faint,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            StatusBadge(s.category.toUpperCase(),
                                borderColor: AppColors.faint),
                            const SizedBox(width: 8),
                            if (s.status == ServiceStatus.live)
                              const StatusBadge('LIVE',
                                  bg: AppColors.successBright,
                                  fg: AppColors.ink)
                            else
                              StatusBadge(s.status.name.toUpperCase(),
                                  borderColor: AppColors.faint),
                            const Spacer(),
                            Text(s.priceWithModel,
                                style: AppTypography.headline
                                    .copyWith(color: AppColors.accent)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(s.name, style: AppTypography.headline),
                        if (s.description != null) ...[
                          const SizedBox(height: 2),
                          Text(s.description!,
                              style: AppTypography.footnote,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                        ],
                        const SizedBox(height: 6),
                        Text('${s.fulfillment.label} · ${s.responseTime.label}',
                            style: AppTypography.caption2),
                      ],
                    ),
                  ),
                Text(
                    'Editing listings arrives with the full expert portal '
                    '(later sprint) — services are provisioned with your '
                    'account for now.',
                    style: AppTypography.footnote),
              ],
            ),
    );
  }
}
