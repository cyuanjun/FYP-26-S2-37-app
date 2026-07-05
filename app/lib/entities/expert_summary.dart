import 'package:freezed_annotation/freezed_annotation.dart';

import 'expert_profile.dart';
import 'expert_service.dart';
import 'public_profile.dart';

part 'expert_summary.freezed.dart';

/// ENTITY (read model) — one marketplace expert as the directory renders it:
/// public identity + expert profile + their live services. Assembled by the
/// BrowseExperts control from one embedded gateway query.
@freezed
abstract class ExpertSummary with _$ExpertSummary {
  const ExpertSummary._();

  const factory ExpertSummary({
    required PublicProfile identity,
    required ExpertProfile profile,
    @Default(<ExpertService>[]) List<ExpertService> services,
  }) = _ExpertSummary;

  int get serviceCount => services.length;

  int? get minPriceCents => services.isEmpty
      ? null
      : services.map((s) => s.priceCents).reduce((a, b) => a < b ? a : b);

  String get fromPriceLabel => minPriceCents == null
      ? ''
      : 'from ${ExpertService.formatCents(minPriceCents!)}';

  bool matchesQuery(String q) {
    if (q.trim().isEmpty) return true;
    final needle = q.trim().toLowerCase();
    return identity.displayName.toLowerCase().contains(needle) ||
        profile.title.toLowerCase().contains(needle) ||
        profile.about.toLowerCase().contains(needle);
  }

  bool matchesCategory(String? categoryId) =>
      categoryId == null || profile.specialties.contains(categoryId);
}

/// One row of the Service Listings sub-tab: a live service + who offers it.
@freezed
abstract class ServiceListing with _$ServiceListing {
  const ServiceListing._();

  const factory ServiceListing({
    required ExpertService service,
    required PublicProfile expertIdentity,
    required ExpertProfile expertProfile,
  }) = _ServiceListing;

  bool matchesQuery(String q) {
    if (q.trim().isEmpty) return true;
    final needle = q.trim().toLowerCase();
    return service.name.toLowerCase().contains(needle) ||
        (service.description ?? '').toLowerCase().contains(needle) ||
        expertIdentity.displayName.toLowerCase().contains(needle);
  }

  bool matchesCategory(String? categoryId) =>
      categoryId == null || service.category == categoryId;
}
