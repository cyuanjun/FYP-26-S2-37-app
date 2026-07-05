import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../controls/authenticate.dart';
import '../../../controls/browse_experts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../entities/expert_summary.dart';
import '../common/app_card.dart';
import 'expert_detail_screen.dart';

/// BOUNDARY widget — one directory expert (#6): identity + rating, the
/// follow-heart (which intercepts card navigation), title, two-line about,
/// and the "N services · from $X" footer.
class ExpertCard extends ConsumerWidget {
  const ExpertCard({super.key, required this.expert});

  final ExpertSummary expert;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).value;
    final followed =
        profile?.followedExpertIds.contains(expert.identity.id) ?? false;

    return GestureDetector(
      onTap: () => Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute(
              builder: (_) =>
                  ExpertDetailScreen(expertId: expert.identity.id))),
      child: AppCard(
        margin: const EdgeInsets.only(bottom: 12),
        borderColor: AppColors.faint,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                      color: AppColors.accent, shape: BoxShape.circle),
                  child: Text(expert.identity.initials,
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
                      Text(expert.identity.displayName,
                          style: AppTypography.headline,
                          overflow: TextOverflow.ellipsis),
                      Text(
                          '★ ${expert.profile.ratingAvg} · '
                          '${expert.profile.reviewCount} reviews',
                          style: AppTypography.caption2),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => ref
                      .read(toggleFollowExpertProvider)
                      .call(expert.identity.id),
                  icon: Icon(followed ? Icons.favorite : Icons.favorite_border,
                      color: followed ? AppColors.danger : AppColors.muted),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(expert.profile.title,
                style: AppTypography.footnote
                    .copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(expert.profile.about,
                style: AppTypography.footnote,
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            Text(
                '${expert.serviceCount} service'
                '${expert.serviceCount == 1 ? '' : 's'}'
                '${expert.fromPriceLabel.isEmpty ? '' : ' · ${expert.fromPriceLabel}'}',
                style: AppTypography.caption2.copyWith(color: AppColors.accent)),
          ],
        ),
      ),
    );
  }
}
