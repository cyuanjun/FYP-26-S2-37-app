import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../controls/browse_experts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../entities/enums.dart';
import '../common/app_card.dart';
import 'expert_detail_screen.dart';

/// BOUNDARY (#6.2 Service Detail). One service in full: hero, what's
/// included, who offers it. The pinned request/review footer state machine
/// arrives with the transact phase.
class ServiceDetailScreen extends ConsumerWidget {
  const ServiceDetailScreen({super.key, required this.serviceId});

  final String serviceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingAsync = ref.watch(serviceListingProvider(serviceId));

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
          title: const Text('SERVICE', style: AppTypography.caption2),
          centerTitle: true),
      body: listingAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
            child: Text('Could not load service.',
                style: AppTypography.subheadline)),
        data: (listing) {
          if (listing == null) {
            return Center(
                child: Text('Service not found.',
                    style: AppTypography.subheadline));
          }
          final service = listing.service;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              Text(
                  '${service.category.toUpperCase()} · '
                  '${service.fulfillment.label.toUpperCase()}',
                  style: AppTypography.caption2.copyWith(letterSpacing: 1.2)),
              const SizedBox(height: 6),
              Text(service.name, style: AppTypography.title2),
              const SizedBox(height: 4),
              Text(
                  '${service.priceWithModel}'
                  '${service.durationWeeks != null ? ' · ${service.durationWeeks} weeks' : ''}'
                  ' · ${service.responseTime.label}',
                  style: AppTypography.subheadline
                      .copyWith(color: AppColors.accent)),
              if (service.description != null) ...[
                const SizedBox(height: 10),
                Text(service.description!,
                    style: AppTypography.body.copyWith(height: 1.4)),
              ],
              const SizedBox(height: 20),
              Text("WHAT'S INCLUDED", style: AppTypography.caption2),
              const SizedBox(height: 8),
              for (final bullet in service.detailBullets)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check, size: 18, color: AppColors.success),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(bullet, style: AppTypography.footnote)),
                    ],
                  ),
                ),
              const SizedBox(height: 14),
              Text('OFFERED BY', style: AppTypography.caption2),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute(
                        builder: (_) => ExpertDetailScreen(
                            expertId: listing.expertIdentity.id))),
                child: AppCard(
                  borderColor: AppColors.faint,
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                            color: AppColors.accent, shape: BoxShape.circle),
                        child: Text(listing.expertIdentity.initials,
                            style: const TextStyle(
                                color: AppColors.bg,
                                fontWeight: FontWeight.w800)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(listing.expertIdentity.displayName,
                                style: AppTypography.headline),
                            Text(
                                '★ ${listing.expertProfile.ratingAvg} · '
                                '${listing.expertProfile.reviewCount} reviews',
                                style: AppTypography.caption2),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: AppColors.faint),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
