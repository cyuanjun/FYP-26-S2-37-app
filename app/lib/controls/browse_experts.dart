import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../boundaries/gateways/expert_gateway.dart';
import '../core/seq_log.dart';
import '../entities/expert_category.dart';
import '../entities/expert_summary.dart';
import 'authenticate.dart';

// (#) This file covers browsing the expert marketplace: the category list, the
// (#) expert directory, the service listings, and the follow-heart bookmark.

// (#) Loads the list of expert categories for the browse screen.
final expertCategoriesProvider = FutureProvider<List<ExpertCategory>>((ref) {
  SeqLog.msg('browse-experts', 'BrowseExperts', 'ExpertGateway',
      'listCategories');
  return ref.watch(expertGatewayProvider).listCategories();
});

// (#) Loads the directory of experts to browse.
final expertsProvider = FutureProvider<List<ExpertSummary>>((ref) {
  SeqLog.msg('browse-experts', 'BrowseExperts', 'ExpertGateway', 'listExperts');
  return ref.watch(expertGatewayProvider).listExperts();
});

// (#) Loads all the sellable service listings.
final serviceListingsProvider = FutureProvider<List<ServiceListing>>((ref) {
  SeqLog.msg('browse-experts', 'BrowseExperts', 'ExpertGateway',
      'listServices');
  return ref.watch(expertGatewayProvider).listServices();
});

// (#) Picks one expert out of the already-loaded directory by id, so no extra
// (#) round-trip is needed for the detail screen.
final expertSummaryProvider =
    FutureProvider.family<ExpertSummary?, String>((ref, expertId) async {
  final all = await ref.watch(expertsProvider.future);
  return all.where((e) => e.identity.id == expertId).firstOrNull;
});

// (#) Picks one service listing from the loaded set by id, same no-extra-fetch trick.
final serviceListingProvider =
    FutureProvider.family<ServiceListing?, String>((ref, serviceId) async {
  final all = await ref.watch(serviceListingsProvider.future);
  return all.where((l) => l.service.id == serviceId).firstOrNull;
});

// (#) Bookmarks or un-bookmarks an expert. It adds or drops the expert id on the
// (#) user's followed list through the gateway, then reloads the profile so the
// (#) heart flips.
class ToggleFollowExpert {
  ToggleFollowExpert(this._ref);

  final Ref _ref; // (#) Riverpod handle used to read gateways and providers

  // (#) Toggles the given expert id in the caller's followed list and saves it.
  Future<void> call(String expertId) async {
    final userId = _ref.read(currentUserIdProvider);
    final profile = _ref.read(currentProfileProvider).value;
    if (userId == null || profile == null) return;
    SeqLog.msg('toggle-follow-expert', 'ExpertCard', 'ToggleFollowExpert',
        'toggle($expertId)');
    final current = profile.followedExpertIds;
    final next = current.contains(expertId)
        ? current.where((id) => id != expertId).toList()
        : [...current, expertId];
    SeqLog.msg('toggle-follow-expert', 'ToggleFollowExpert', 'ExpertGateway',
        'setFollowedExperts(${next.length})');
    await _ref.read(expertGatewayProvider).setFollowedExperts(userId, next);
    _ref.invalidate(currentProfileProvider);
  }
}

// (#) Hands the expert cards the ToggleFollowExpert control.
final toggleFollowExpertProvider =
    Provider<ToggleFollowExpert>(ToggleFollowExpert.new);
