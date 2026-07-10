import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../controls/browse_experts.dart';
import '../../../controls/service_requests.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../entities/deliverable.dart';
import '../../../entities/enums.dart';
import '../../../entities/expert_summary.dart';
import '../../../entities/service_request_summary.dart';
import '../common/app_card.dart';
import 'expert_detail_screen.dart';

// (#) Full page for one service. Shows the details, any deliverables so far, and a footer that changes
// (#) with the engagement state. From it the client can request the service or leave a review, each via a control.
class ServiceDetailScreen extends ConsumerWidget {
  const ServiceDetailScreen({super.key, required this.serviceId});

  final String serviceId; // (#) id of the service being shown

  // (#) Watches the listing and any active engagement, then builds the details, deliverables, includes and footer.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingAsync = ref.watch(serviceListingProvider(serviceId));
    final engagement =
        ref.watch(activeRequestForServiceProvider(serviceId)).value;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
          title: const Text('SERVICE', style: AppTypography.caption2),
          centerTitle: true),
      bottomNavigationBar: listingAsync.value == null
          ? null
          : _Footer(
              listing: listingAsync.value!,
              engagement: engagement,
            ),
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
              if (engagement != null &&
                  engagement.request.deliverablesVisible &&
                  engagement.deliverables.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                    'FROM ${listing.expertIdentity.firstName?.toUpperCase() ?? 'YOUR EXPERT'}',
                    style: AppTypography.caption2),
                const SizedBox(height: 8),
                for (final d in engagement.deliverables) _DeliverableCard(d),
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

// (#) One deliverable card the expert sent: title, note, and each section with its list of items.
class _DeliverableCard extends StatelessWidget {
  const _DeliverableCard(this.deliverable);

  final Deliverable deliverable; // (#) the deliverable to render

  // (#) Builds the card with the title, optional note, and the section headings and their items.
  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 10),
      borderColor: AppColors.faint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(deliverable.title, style: AppTypography.headline),
          if (deliverable.note != null) ...[
            const SizedBox(height: 4),
            Text(deliverable.note!, style: AppTypography.footnote),
          ],
          for (final section in deliverable.sections) ...[
            const SizedBox(height: 10),
            Text(section.heading.toUpperCase(),
                style: AppTypography.caption2.copyWith(letterSpacing: 1.1)),
            const SizedBox(height: 4),
            for (final item in section.items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Expanded(child: Text(item.label, style: AppTypography.body)),
                    if (item.detail != null)
                      Text(item.detail!,
                          style: AppTypography.headline
                              .copyWith(color: AppColors.accent)),
                    if (item.sub != null) ...[
                      const SizedBox(width: 6),
                      Text(item.sub!, style: AppTypography.caption2),
                    ],
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

// (#) The pinned bottom footer that shows the right action for the engagement state.
class _Footer extends ConsumerWidget {
  const _Footer({required this.listing, required this.engagement});

  final ServiceListing listing; // (#) the service this footer acts on
  final ServiceRequestSummary? engagement; // (#) the current engagement, null if none yet

  // (#) Picks the footer content: request button, pending note, in progress note, review button, or thanks line.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final request = engagement?.request;
    final Widget child;
    if (request == null) {
      child = ElevatedButton(
        onPressed: () => _openRequestSheet(context, ref),
        child: Text('Request · ${listing.service.priceLabel}'),
      );
    } else if (request.isPending) {
      child = Text('Request pending — ${listing.expertIdentity.displayName} '
          'usually replies within ${_replyWindow()}.',
          textAlign: TextAlign.center,
          style: AppTypography.footnote.copyWith(color: AppColors.premiumText));
    } else if (request.isAccepted) {
      child = Text('In progress — deliverables appear above as they arrive.',
          textAlign: TextAlign.center, style: AppTypography.footnote);
    } else if (engagement!.reviewUnlocked) {
      child = ElevatedButton(
        onPressed: () => _openReviewSheet(context, ref, request.id),
        child: const Text('Leave a review'),
      );
    } else {
      child = Text('✓ Reviewed — thanks for the feedback!',
          textAlign: TextAlign.center,
          style: AppTypography.footnote.copyWith(color: AppColors.success));
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: child,
      ),
    );
  }

  // (#) Turns the service response time into a friendly "24 hours" style phrase.
  String _replyWindow() => switch (listing.service.responseTime) {
        ResponseTime.h24 => '24 hours',
        ResponseTime.h48 => '48 hours',
        ResponseTime.h72 => '72 hours',
      };

  // (#) Opens the request sheet where the client types their goal and RequestService fires it off.
  void _openRequestSheet(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: 20 + MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('REQUEST ${listing.service.name.toUpperCase()}',
                  style: AppTypography.caption2),
              const SizedBox(height: 4),
              Text(
                  '${listing.service.priceLabel} · simulated payment — '
                  'no card is charged.',
                  style: AppTypography.footnote),
              const SizedBox(height: 12),
              Text('YOUR GOAL', style: AppTypography.caption2),
              const SizedBox(height: 6),
              TextField(
                controller: controller,
                maxLines: 4,
                maxLength: 400,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                    hintText:
                        'Tell the expert what you want to achieve (required)'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: controller.text.trim().isEmpty
                    ? null
                    : () async {
                        final ok = await ref.read(requestServiceProvider).call(
                            service: listing.service,
                            message: controller.text);
                        if (ok && sheetContext.mounted) {
                          Navigator.of(sheetContext).pop();
                        }
                      },
                child: const Text('SEND REQUEST'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // (#) Opens the review sheet with a star picker and text box, then sends it through SubmitReview.
  void _openReviewSheet(BuildContext context, WidgetRef ref, String requestId) {
    final controller = TextEditingController();
    var rating = 5;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: 20 + MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('REVIEW ${listing.expertIdentity.displayName.toUpperCase()}',
                  style: AppTypography.caption2),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 1; i <= 5; i++)
                    IconButton(
                      onPressed: () => setState(() => rating = i),
                      icon: Icon(i <= rating ? Icons.star : Icons.star_border,
                          color: AppColors.premium, size: 32),
                    ),
                ],
              ),
              Text('YOUR REVIEW', style: AppTypography.caption2),
              const SizedBox(height: 6),
              TextField(
                controller: controller,
                maxLines: 3,
                maxLength: 400,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                    hintText: 'How was the engagement? (required)'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: controller.text.trim().isEmpty
                    ? null
                    : () async {
                        final ok = await ref.read(submitReviewProvider).call(
                            requestId: requestId,
                            rating: rating,
                            body: controller.text);
                        if (ok && sheetContext.mounted) {
                          Navigator.of(sheetContext).pop();
                        }
                      },
                child: const Text('SUBMIT REVIEW'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
