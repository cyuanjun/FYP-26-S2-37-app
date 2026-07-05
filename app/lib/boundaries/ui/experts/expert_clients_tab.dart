import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../controls/expert_requests.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../entities/public_profile.dart';
import '../../../entities/service_request_summary.dart';
import '../common/app_card.dart';
import '../common/status_badge.dart';

/// BOUNDARY (#23 Expert Clients). Everyone who has engaged this expert,
/// grouped from the request inbox: engagement counts + current state.
/// Deliverable composition happens on Requests (#22) in this realization.
class ExpertClientsTab extends ConsumerWidget {
  const ExpertClientsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(incomingRequestsProvider).value ?? [];

    // Group engagements by client.
    final byClient = <String, List<ServiceRequestSummary>>{};
    final identities = <String, PublicProfile>{};
    for (final r in requests) {
      final client = r.otherParty;
      if (client == null) continue;
      identities[client.id] = client;
      byClient.putIfAbsent(client.id, () => []).add(r);
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        titleSpacing: 20,
        title: const Text('CLIENTS', style: AppTypography.title1),
      ),
      body: byClient.isEmpty
          ? Center(
              child: Text('No clients yet — accepted requests appear here.',
                  style: AppTypography.subheadline))
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                for (final entry in byClient.entries)
                  _clientCard(identities[entry.key]!, entry.value),
              ],
            ),
    );
  }

  Widget _clientCard(
      PublicProfile client, List<ServiceRequestSummary> engagements) {
    final active = engagements.where((e) => e.request.isAccepted).length;
    final completed = engagements.where((e) => e.request.isCompleted).length;

    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      borderColor: AppColors.faint,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
                color: AppColors.accent, shape: BoxShape.circle),
            child: Text(client.initials,
                style: const TextStyle(
                    color: AppColors.bg,
                    fontWeight: FontWeight.w800,
                    fontSize: 16)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(client.displayName, style: AppTypography.headline),
                Text(
                    '${engagements.length} engagement'
                    '${engagements.length == 1 ? '' : 's'}'
                    ' · $completed completed',
                    style: AppTypography.caption2),
              ],
            ),
          ),
          if (active > 0)
            const StatusBadge('ACTIVE',
                bg: AppColors.successBright, fg: AppColors.ink),
        ],
      ),
    );
  }
}
