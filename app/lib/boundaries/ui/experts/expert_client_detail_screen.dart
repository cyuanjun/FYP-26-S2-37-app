import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../controls/expert_requests.dart';
import '../../../core/format.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../entities/public_profile.dart';
import '../../../entities/service_request_summary.dart';
import '../common/app_card.dart';
import '../common/status_badge.dart';
import 'deliverable_composer_sheet.dart';
import 'expert_buttons.dart';

/// BOUNDARY (#23.1 Client Detail). One client's engagements with this
/// expert. Per the fulfillment model, this is where the work happens:
/// send deliverables and mark active engagements complete; past
/// engagements archive below.
class ExpertClientDetailScreen extends ConsumerWidget {
  const ExpertClientDetailScreen({super.key, required this.clientId});

  final String clientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(incomingRequestsProvider).value ?? [];
    final engagements =
        all.where((r) => r.otherParty?.id == clientId).toList();
    final client = engagements.firstOrNull?.otherParty;
    final active = engagements.where((r) => r.request.isAccepted).toList();
    final pending = engagements.where((r) => r.request.isPending).toList();
    final past = engagements
        .where((r) => r.request.isCompleted || r.request.isCancelled)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(client?.handle.isNotEmpty ?? false ? client!.handle : 'CLIENT',
            style: AppTypography.caption2),
        centerTitle: true,
      ),
      body: client == null
          ? Center(
              child:
                  Text('Client not found.', style: AppTypography.subheadline))
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                _identity(client, engagements),
                if (pending.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text('AWAITING YOUR ANSWER', style: AppTypography.caption2),
                  const SizedBox(height: 8),
                  for (final e in pending)
                    _engagementCard(context, ref, e,
                        footer: Text('Accept or decline on the Requests tab.',
                            style: AppTypography.footnote)),
                ],
                if (active.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text('ACTIVE', style: AppTypography.caption2),
                  const SizedBox(height: 8),
                  for (final e in active)
                    _engagementCard(context, ref, e, footer: _actions(context, ref, e)),
                ],
                if (past.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text('PAST', style: AppTypography.caption2),
                  const SizedBox(height: 8),
                  for (final e in past)
                    _engagementCard(context, ref, e,
                        muted: true,
                        footer: e.request.isCompleted
                            ? const StatusBadge('COMPLETED',
                                bg: AppColors.successBright, fg: AppColors.ink)
                            : const StatusBadge('DECLINED',
                                borderColor: AppColors.faint)),
                ],
              ],
            ),
    );
  }

  Widget _identity(PublicProfile client, List<ServiceRequestSummary> all) {
    final completed = all.where((e) => e.request.isCompleted).length;
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
              color: AppColors.accent, shape: BoxShape.circle),
          child: Text(client.initials,
              style: const TextStyle(
                  color: AppColors.bg,
                  fontWeight: FontWeight.w800,
                  fontSize: 26)),
        ),
        const SizedBox(height: 8),
        Text(client.displayName, style: AppTypography.title2),
        const SizedBox(height: 2),
        Text(
            '${all.length} engagement${all.length == 1 ? '' : 's'} · '
            '$completed completed',
            style: AppTypography.caption2),
      ],
    );
  }

  Widget _engagementCard(
      BuildContext context, WidgetRef ref, ServiceRequestSummary summary,
      {Widget? footer, bool muted = false}) {
    final request = summary.request;
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
                    style: AppTypography.headline),
              ),
              Text(request.quotedPriceLabel, style: AppTypography.headline),
            ],
          ),
          const SizedBox(height: 2),
          Text(relativeDay(request.requestedAt), style: AppTypography.caption2),
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
          if (footer != null) ...[
            const SizedBox(height: 10),
            footer,
          ],
        ],
      ),
    );
  }

  Widget _actions(
      BuildContext context, WidgetRef ref, ServiceRequestSummary summary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
            '${summary.deliverables.length} deliverable'
            '${summary.deliverables.length == 1 ? '' : 's'} sent',
            style: AppTypography.caption2),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () =>
                    showDeliverableComposer(context, summary.request.id),
                style: expertCompactOutlined(AppColors.accent),
                child: const Text('Send deliverable'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _confirmComplete(context, ref, summary),
                style: expertCompactFilled,
                child: const Text('Mark complete'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _confirmComplete(
      BuildContext context, WidgetRef ref, ServiceRequestSummary summary) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Mark engagement complete?'),
        content: const Text(
            'The client will be able to leave a review. This can\'t be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              ref
                  .read(completeServiceRequestProvider)
                  .call(summary.request.id);
            },
            child: const Text('Complete'),
          ),
        ],
      ),
    );
  }
}
