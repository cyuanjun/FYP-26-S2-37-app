import 'package:freezed_annotation/freezed_annotation.dart';

import 'expert_profile.dart';
import 'expert_service.dart';
import 'public_profile.dart';

part 'expert_summary.freezed.dart';

// (#) An expert bundled the way the marketplace directory shows them: their
// (#) public identity, expert profile and the services they currently offer,
// (#) plus little helpers for search and price filtering. Built by BrowseExperts.
@freezed
abstract class ExpertSummary with _$ExpertSummary {
  const ExpertSummary._();

  const factory ExpertSummary({
    required PublicProfile identity, // (#) name and avatar
    required ExpertProfile profile, // (#) title, rating, specialties
    @Default(<ExpertService>[]) List<ExpertService> services, // (#) their live offerings
  }) = _ExpertSummary;

  // (#) how many services they list
  int get serviceCount => services.length;

  // (#) cheapest service price, null when they list nothing
  int? get minPriceCents => services.isEmpty
      ? null
      : services.map((s) => s.priceCents).reduce((a, b) => a < b ? a : b);

  // (#) "from $X" badge text, blank when there's no price to show
  String get fromPriceLabel => minPriceCents == null
      ? ''
      : 'from ${ExpertService.formatCents(minPriceCents!)}';

  // (#) true when the search box text matches their name, title or bio
  bool matchesQuery(String q) {
    if (q.trim().isEmpty) return true;
    final needle = q.trim().toLowerCase();
    return identity.displayName.toLowerCase().contains(needle) ||
        profile.title.toLowerCase().contains(needle) ||
        profile.about.toLowerCase().contains(needle);
  }

  // (#) true when they specialise in the picked category, or no filter is set
  bool matchesCategory(String? categoryId) =>
      categoryId == null || profile.specialties.contains(categoryId);
}

// (#) One row of the Service Listings sub-tab: a single live service plus who offers it
@freezed
abstract class ServiceListing with _$ServiceListing {
  const ServiceListing._();

  const factory ServiceListing({
    required ExpertService service,
    required PublicProfile expertIdentity, // (#) name and avatar of the seller
    required ExpertProfile expertProfile, // (#) the seller's expert details
  }) = _ServiceListing;

  // (#) true when the search text matches the service name, blurb or seller name
  bool matchesQuery(String q) {
    if (q.trim().isEmpty) return true;
    final needle = q.trim().toLowerCase();
    return service.name.toLowerCase().contains(needle) ||
        (service.description ?? '').toLowerCase().contains(needle) ||
        expertIdentity.displayName.toLowerCase().contains(needle);
  }

  // (#) true when the service is in the picked category, or no filter is set
  bool matchesCategory(String? categoryId) =>
      categoryId == null || service.category == categoryId;
}
