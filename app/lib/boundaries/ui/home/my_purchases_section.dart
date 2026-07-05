import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../controls/service_requests.dart';
import '../../../core/format.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../common/app_card.dart';
import '../common/status_badge.dart';
import '../experts/service_detail_screen.dart';

/// BOUNDARY widget — the Dashboard "MY PURCHASES" strip (#5): the user's
/// service requests, newest first, linking back to each service (#6.2).
/// Renders nothing when the user has never requested a service.
class MyPurchasesSection extends ConsumerWidget {
  const MyPurchasesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(myServiceRequestsProvider).value ?? [];
    if (requests.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text('MY PURCHASES', style: AppTypography.caption2),
        const SizedBox(height: 8),
        for (final summary in requests)
          GestureDetector(
            onTap: () => Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute(
                    builder: (_) => ServiceDetailScreen(
                        serviceId: summary.request.expertServiceId))),
            child: AppCard(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              shadow: false,
              borderColor: AppColors.faint,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(summary.service?.name ?? 'Service',
                            style: AppTypography.headline,
                            overflow: TextOverflow.ellipsis),
                        Text(
                            '${summary.otherParty?.displayName ?? 'Expert'} · '
                            '${relativeDay(summary.request.requestedAt)}',
                            style: AppTypography.caption2),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(summary.request.quotedPriceLabel,
                      style: AppTypography.headline),
                  const SizedBox(width: 8),
                  if (summary.request.isPending)
                    const StatusBadge('PENDING',
                        bg: AppColors.premium, fg: AppColors.ink)
                  else if (summary.request.isCancelled)
                    const StatusBadge('DECLINED', borderColor: AppColors.faint)
                  else if (summary.request.isCompleted)
                    const StatusBadge('DONE',
                        bg: AppColors.successBright, fg: AppColors.ink)
                  else
                    const StatusBadge('ACTIVE', borderColor: AppColors.faint),
                  const Icon(Icons.chevron_right,
                      color: AppColors.faint, size: 18),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
