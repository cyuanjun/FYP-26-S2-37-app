import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../controls/expert_requests.dart';
import '../../../core/format.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../entities/service_request_summary.dart';
import '../common/app_card.dart';
import '../common/status_badge.dart';
import 'expert_buttons.dart';
import 'expert_client_detail_screen.dart';

// (#) The expert's request inbox. Groups requests into new, active and history. Accept and decline
// (#) call their controls, and active rows jump to the client detail page.
class ExpertRequestsView extends ConsumerWidget {
  const ExpertRequestsView({super.key});

  // (#) Watches incoming requests, buckets them into pending, active and done, and lists each bucket.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(incomingRequestsProvider);

    return requests.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
          child: Text('Could not load requests.\n$e',
              style: AppTypography.footnote, textAlign: TextAlign.center)),
      data: (all) {
        final pending = all.where((r) => r.request.isPending).toList();
        final active = all.where((r) => r.request.isAccepted).toList();
        final done = all
            .where((r) => r.request.isCompleted || r.request.isCancelled)
            .toList();

        if (all.isEmpty) {
          return Center(
              child: Text('No service requests yet.',
                  style: AppTypography.subheadline));
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(incomingRequestsProvider),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              if (pending.isNotEmpty) ...[
                Text('NEW REQUESTS', style: AppTypography.caption2),
                const SizedBox(height: 8),
                for (final r in pending) _RequestCard(summary: r),
              ],
              if (active.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('ACTIVE', style: AppTypography.caption2),
                const SizedBox(height: 8),
                for (final r in active) _RequestCard(summary: r),
              ],
              if (done.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('HISTORY', style: AppTypography.caption2),
                const SizedBox(height: 8),
                for (final r in done) _RequestCard(summary: r, muted: true),
              ],
            ],
          ),
        );
      },
    );
  }
}

// (#) One request card. Shows the service, price, client and message, plus buttons that fit its state.
class _RequestCard extends ConsumerWidget {
  const _RequestCard({required this.summary, this.muted = false});

  final ServiceRequestSummary summary; // (#) the request this card shows
  final bool muted; // (#) dims the card for history rows

  // (#) Builds the card and picks the footer: accept/decline if pending, a manage link if active, else a badge.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final request = summary.request;
    final client = summary.otherParty?.displayName ?? 'Client';

    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      borderColor: AppColors.faint,
      shadow: !muted,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(summary.service?.name ?? 'Service',
                    style: AppTypography.headline,
                    overflow: TextOverflow.ellipsis),
              ),
              Text(request.quotedPriceLabel, style: AppTypography.headline),
            ],
          ),
          const SizedBox(height: 2),
          Text('$client · ${relativeDay(request.requestedAt)}',
              style: AppTypography.caption2),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surface2,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('“${request.requestMessage}”',
                style: AppTypography.footnote.copyWith(height: 1.3)),
          ),
          const SizedBox(height: 10),
          if (request.isPending)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => ref
                        .read(acceptServiceRequestProvider)
                        .call(request.id),
                    style: expertCompactFilled,
                    child: const Text('Accept'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => ref
                        .read(declineServiceRequestProvider)
                        .call(request.id),
                    style: expertCompactOutlined(AppColors.danger),
                    child: const Text('Decline'),
                  ),
                ),
              ],
            )
          else if (request.isAccepted)
            OutlinedButton(
              onPressed: summary.otherParty == null
                  ? null
                  : () => Navigator.of(context, rootNavigator: true).push(
                      MaterialPageRoute(
                          builder: (_) => ExpertClientDetailScreen(
                              clientId: summary.otherParty!.id))),
              style: expertCompactOutlined(AppColors.accent),
              child: const Text('In progress — manage under Clients'),
            )
          else if (request.isCompleted)
            const StatusBadge('COMPLETED',
                bg: AppColors.successBright, fg: AppColors.ink)
          else
            const StatusBadge('DECLINED', borderColor: AppColors.faint),
        ],
      ),
    );
  }

}
