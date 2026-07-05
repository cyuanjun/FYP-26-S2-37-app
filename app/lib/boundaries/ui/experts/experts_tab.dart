import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../controls/authenticate.dart';
import '../../../controls/browse_experts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../common/avatar_button.dart';
import 'expert_card.dart';
import 'expert_requests_view.dart';
import 'service_card.dart';

/// BOUNDARY (#6 Experts). For clients: the marketplace directory — Experts /
/// Service Listings sub-tabs over a shared search + category filter. For a
/// role=expert account the tab swaps to their incoming-requests view (the
/// deliberate minimal realization of the #20-24 portal).
class ExpertsTab extends ConsumerStatefulWidget {
  const ExpertsTab({super.key});

  @override
  ConsumerState<ExpertsTab> createState() => _ExpertsTabState();
}

enum _ExpertsSubTab { experts, services }

class _ExpertsTabState extends ConsumerState<ExpertsTab> {
  _ExpertsSubTab _tab = _ExpertsSubTab.experts;
  String _query = '';
  String? _category; // null = All

  @override
  Widget build(BuildContext context) {
    final isExpert =
        ref.watch(currentProfileProvider).value?.isExpert ?? false;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        titleSpacing: 20,
        title: const Text('EXPERTS', style: AppTypography.title1),
        actions: const [AvatarButton()],
      ),
      body: isExpert ? const ExpertRequestsView() : _browse(),
    );
  }

  Widget _browse() {
    final categories = ref.watch(expertCategoriesProvider).value ?? [];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
          child: Row(
            children: [
              _pill('Experts', _ExpertsSubTab.experts),
              const SizedBox(width: 8),
              _pill('Service Listings', _ExpertsSubTab.services),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: TextField(
            onChanged: (q) => setState(() => _query = q),
            decoration: InputDecoration(
              hintText: _tab == _ExpertsSubTab.experts
                  ? 'Search experts'
                  : 'Search services',
              prefixIcon: const Icon(Icons.search, size: 20),
              isDense: true,
            ),
          ),
        ),
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              _chip('All', null),
              for (final c in categories) _chip(c.label, c.id),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: switch (_tab) {
            _ExpertsSubTab.experts => _expertsList(),
            _ExpertsSubTab.services => _servicesList(),
          },
        ),
      ],
    );
  }

  Widget _resultsHeader(int n) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
        child: Row(
          children: [
            Text('Results · $n', style: AppTypography.caption2),
            const Spacer(),
            // Non-interactive in v1 (per spec) — the list is pre-sorted.
            Text('Sort: Top rated', style: AppTypography.caption2),
          ],
        ),
      );

  Widget _expertsList() {
    final experts = ref.watch(expertsProvider);
    return experts.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
          child: Text('Could not load experts.', style: AppTypography.footnote)),
      data: (all) {
        final shown = all
            .where((e) =>
                e.matchesQuery(_query) && e.matchesCategory(_category))
            .toList();
        if (shown.isEmpty) {
          return Center(
              child: Text('No experts match your search.',
                  style: AppTypography.subheadline));
        }
        return Column(
          children: [
            _resultsHeader(shown.length),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => ref.invalidate(expertsProvider),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  children: [for (final e in shown) ExpertCard(expert: e)],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _servicesList() {
    final listings = ref.watch(serviceListingsProvider);
    return listings.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
          child:
              Text('Could not load services.', style: AppTypography.footnote)),
      data: (all) {
        final shown = all
            .where((l) =>
                l.matchesQuery(_query) && l.matchesCategory(_category))
            .toList();
        if (shown.isEmpty) {
          return Center(
              child: Text('No services match your search.',
                  style: AppTypography.subheadline));
        }
        return Column(
          children: [
            _resultsHeader(shown.length),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => ref.invalidate(serviceListingsProvider),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  children: [for (final l in shown) ServiceCard(listing: l)],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _pill(String label, _ExpertsSubTab value) {
    final selected = _tab == value;
    return GestureDetector(
      onTap: () => setState(() => _tab = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : AppColors.bg,
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: selected ? AppColors.accent : AppColors.faint),
        ),
        child: Text(label,
            style: AppTypography.footnote
                .copyWith(color: selected ? AppColors.bg : AppColors.muted)),
      ),
    );
  }

  Widget _chip(String label, String? id) {
    final selected = _category == id;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _category = id),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? AppColors.accent : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: selected ? AppColors.accent : AppColors.faint),
          ),
          child: Text(label,
              style: AppTypography.caption2
                  .copyWith(color: selected ? AppColors.bg : AppColors.muted)),
        ),
      ),
    );
  }
}
