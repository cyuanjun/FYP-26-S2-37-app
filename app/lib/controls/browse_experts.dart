import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../boundaries/gateways/expert_gateway.dart';
import '../core/seq_log.dart';
import '../entities/expert_category.dart';
import '../entities/expert_summary.dart';
import 'authenticate.dart';

/// CONTROLs — Browse Experts (US27) + Browse Categories (US28) + the
/// follow-heart bookmark (#6/#6.1).

final expertCategoriesProvider = FutureProvider<List<ExpertCategory>>((ref) {
  SeqLog.msg('browse-experts', 'BrowseExperts', 'ExpertGateway',
      'listCategories');
  return ref.watch(expertGatewayProvider).listCategories();
});

final expertsProvider = FutureProvider<List<ExpertSummary>>((ref) {
  SeqLog.msg('browse-experts', 'BrowseExperts', 'ExpertGateway', 'listExperts');
  return ref.watch(expertGatewayProvider).listExperts();
});

final serviceListingsProvider = FutureProvider<List<ServiceListing>>((ref) {
  SeqLog.msg('browse-experts', 'BrowseExperts', 'ExpertGateway',
      'listServices');
  return ref.watch(expertGatewayProvider).listServices();
});

/// One expert by id — derived from the directory fetch (no extra query).
final expertSummaryProvider =
    FutureProvider.family<ExpertSummary?, String>((ref, expertId) async {
  final all = await ref.watch(expertsProvider.future);
  return all.where((e) => e.identity.id == expertId).firstOrNull;
});

/// One listing by service id — derived likewise.
final serviceListingProvider =
    FutureProvider.family<ServiceListing?, String>((ref, serviceId) async {
  final all = await ref.watch(serviceListingsProvider.future);
  return all.where((l) => l.service.id == serviceId).firstOrNull;
});

/// CONTROL — Toggle Follow Expert (bookmark array on the caller's profile).
class ToggleFollowExpert {
  ToggleFollowExpert(this._ref);

  final Ref _ref;

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

final toggleFollowExpertProvider =
    Provider<ToggleFollowExpert>(ToggleFollowExpert.new);
