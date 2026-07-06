import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../boundaries/gateways/profile_gateway.dart';
import '../core/seq_log.dart';
import '../entities/enums.dart';
import '../entities/subscription.dart';
import 'authenticate.dart';

/// CONTROLs — the premium tier's account lifecycle: the simulated Free→Premium
/// upgrade (#16, `start_premium` RPC) and subscription management (#13.6,
/// owner-scoped cancel/resume). Payment is simulated throughout.

/// The caller's subscription row; null while Free.
final subscriptionProvider = FutureProvider<Subscription?>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;
  SeqLog.msg('view-subscription', 'SubscriptionManagementScreen',
      'ProfileGateway', 'fetchSubscription');
  return ref.watch(profileGatewayProvider).fetchSubscription(userId);
});

class StartPremium {
  StartPremium(this._ref);

  final Ref _ref;

  /// Flips the caller Free→Premium via the RPC, then refetches everything
  /// role-gated so the app updates live (no re-login).
  Future<void> call() async {
    SeqLog.msg('start-premium', 'UpgradeScreen', 'StartPremium', 'upgrade()');
    SeqLog.msg(
        'start-premium', 'StartPremium', 'ProfileGateway', 'start_premium(rpc)');
    await _ref.read(profileGatewayProvider).startPremium();
    _ref.invalidate(currentProfileProvider);
    _ref.invalidate(subscriptionProvider);
  }
}

final startPremiumProvider = Provider<StartPremium>(StartPremium.new);

class ManageSubscription {
  ManageSubscription(this._ref);

  final Ref _ref;

  Future<void> cancel() => _set(SubscriptionStatus.cancelled);
  Future<void> resume() => _set(SubscriptionStatus.active);

  Future<void> _set(SubscriptionStatus status) async {
    final userId = _ref.read(currentUserIdProvider);
    if (userId == null) return;
    SeqLog.msg('manage-subscription', 'SubscriptionManagementScreen',
        'ManageSubscription', status.name);
    SeqLog.msg('manage-subscription', 'ManageSubscription', 'ProfileGateway',
        'setSubscriptionStatus(${status.name})');
    await _ref.read(profileGatewayProvider).setSubscriptionStatus(userId, status);
    _ref.invalidate(subscriptionProvider);
  }
}

final manageSubscriptionProvider =
    Provider<ManageSubscription>(ManageSubscription.new);
