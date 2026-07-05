import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../entities/enums.dart';
import '../../../entities/expert_summary.dart';
import '../common/app_card.dart';
import '../common/status_badge.dart';
import 'service_detail_screen.dart';

/// BOUNDARY widget — one Service Listings row (#6): category badge + price,
/// name, description, and who offers it.
class ServiceCard extends StatelessWidget {
  const ServiceCard({super.key, required this.listing});

  final ServiceListing listing;

  @override
  Widget build(BuildContext context) {
    final service = listing.service;
    return GestureDetector(
      onTap: () => Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute(
              builder: (_) => ServiceDetailScreen(serviceId: service.id))),
      child: AppCard(
        margin: const EdgeInsets.only(bottom: 12),
        borderColor: AppColors.faint,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                StatusBadge(service.category.toUpperCase(),
                    borderColor: AppColors.faint),
                const SizedBox(width: 8),
                StatusBadge(service.fulfillment.label.toUpperCase(),
                    borderColor: AppColors.faint),
                const Spacer(),
                Text(service.priceWithModel,
                    style: AppTypography.headline
                        .copyWith(color: AppColors.accent)),
              ],
            ),
            const SizedBox(height: 8),
            Text(service.name, style: AppTypography.headline),
            if (service.description != null) ...[
              const SizedBox(height: 2),
              Text(service.description!,
                  style: AppTypography.footnote,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 8),
            Text(
                'By ${listing.expertIdentity.displayName} · '
                '${listing.service.responseTime.label}',
                style: AppTypography.caption2),
          ],
        ),
      ),
    );
  }
}
