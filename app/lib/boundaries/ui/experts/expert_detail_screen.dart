import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../controls/authenticate.dart';
import '../../../controls/browse_experts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../entities/expert_summary.dart';
import '../common/app_card.dart';
import '../common/stat_tile.dart';
import 'service_card.dart';

/// BOUNDARY (#6.1 Expert Detail). One expert in full: identity, stored
/// aggregates (Rating / Reviews / Clients), about, credentials, specialties,
/// and their live service listings.
class ExpertDetailScreen extends ConsumerWidget {
  const ExpertDetailScreen({super.key, required this.expertId});

  final String expertId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expertAsync = ref.watch(expertSummaryProvider(expertId));
    final profile = ref.watch(currentProfileProvider).value;
    final followed = profile?.followedExpertIds.contains(expertId) ?? false;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('EXPERT', style: AppTypography.caption2),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () =>
                ref.read(toggleFollowExpertProvider).call(expertId),
            icon: Icon(followed ? Icons.favorite : Icons.favorite_border,
                color: followed ? AppColors.danger : AppColors.muted),
          ),
        ],
      ),
      body: expertAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
            child: Text('Could not load expert.',
                style: AppTypography.subheadline)),
        data: (expert) {
          if (expert == null) {
            return Center(
                child: Text('Expert not found.',
                    style: AppTypography.subheadline));
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              _identity(expert),
              const SizedBox(height: 16),
              AppCard(
                child: Row(
                  children: [
                    StatTile('RATING', '★ ${expert.profile.ratingAvg}',
                        valueFirst: true),
                    StatTile('REVIEWS', '${expert.profile.reviewCount}',
                        valueFirst: true),
                    StatTile('CLIENTS', '${expert.profile.clientCount}',
                        valueFirst: true),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text('ABOUT', style: AppTypography.caption2),
              const SizedBox(height: 8),
              Text(expert.profile.about,
                  style: AppTypography.body.copyWith(height: 1.4)),
              const SizedBox(height: 20),
              Text('CREDENTIALS', style: AppTypography.caption2),
              const SizedBox(height: 8),
              for (final c in expert.profile.credentials)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_outlined,
                          size: 18, color: AppColors.success),
                      const SizedBox(width: 8),
                      Expanded(child: Text(c, style: AppTypography.footnote)),
                    ],
                  ),
                ),
              const SizedBox(height: 14),
              Text('SPECIALTIES', style: AppTypography.caption2),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final s in expert.profile.specialties)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.faint),
                      ),
                      child: Text(s[0].toUpperCase() + s.substring(1),
                          style: AppTypography.caption2),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Text('SERVICE LISTINGS', style: AppTypography.caption2),
              const SizedBox(height: 8),
              for (final service in expert.services)
                ServiceCard(
                    listing: ServiceListing(
                        service: service,
                        expertIdentity: expert.identity,
                        expertProfile: expert.profile)),
            ],
          );
        },
      ),
    );
  }

  Widget _identity(ExpertSummary expert) {
    return Column(
      children: [
        Container(
          width: 88,
          height: 88,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
              color: AppColors.accent, shape: BoxShape.circle),
          child: Text(expert.identity.initials,
              style: const TextStyle(
                  color: AppColors.bg,
                  fontWeight: FontWeight.w800,
                  fontSize: 30)),
        ),
        const SizedBox(height: 10),
        Text(expert.identity.displayName, style: AppTypography.title2),
        const SizedBox(height: 2),
        Text(
            '${expert.profile.title} · '
            '${expert.profile.yearsCoaching} yrs coaching'
            '${expert.profile.isVerified ? ' · ✓ Verified' : ''}',
            style: AppTypography.caption2),
      ],
    );
  }
}
