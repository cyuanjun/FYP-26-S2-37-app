import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../boundaries/gateways/profile_gateway.dart';
import '../core/seq_log.dart';
import '../entities/enums.dart';
import '../entities/subscription.dart';
import 'authenticate.dart';

// (#) The premium tier's account lifecycle: the simulated Free-to-Premium upgrade
// (#) (#16) and managing the subscription afterwards (#13.6 cancel/resume). No real
// (#) money changes hands anywhere here.

// (#) Read provider for the user's subscription row; null while they are still Free.
final subscriptionProvider = FutureProvider<Subscription?>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;
  SeqLog.msg('view-subscription', 'SubscriptionManagementScreen',
      'ProfileGateway', 'fetchSubscription');
  return ref.watch(profileGatewayProvider).fetchSubscription(userId);
});

// (#) The Start Premium use case (#16). Runs the start_premium RPC via the gateway
// (#) (payment simulated) so the account flips to Premium without needing a re-login.
class StartPremium {
  StartPremium(this._ref);

  final Ref _ref;

  // (#) Calls the RPC, then invalidates the profile and subscription so the role
  // (#) flip shows through the app straight away.
  Future<void> call() async {
    SeqLog.msg('start-premium', 'UpgradeScreen', 'StartPremium', 'upgrade()');
    SeqLog.msg(
        'start-premium', 'StartPremium', 'ProfileGateway', 'start_premium(rpc)');
    await _ref.read(profileGatewayProvider).startPremium();
    _ref.invalidate(currentProfileProvider);
    _ref.invalidate(subscriptionProvider);
  }
}

// (#) Provider the upgrade screen uses to go Premium.
final startPremiumProvider = Provider<StartPremium>(StartPremium.new);

// (#) The Manage Subscription use case (#13.6). Lets an owner cancel or resume their
// (#) subscription by flipping its status through the gateway.
class ManageSubscription {
  ManageSubscription(this._ref);

  final Ref _ref;

  // (#) Cancel marks the subscription cancelled.
  Future<void> cancel() => _set(SubscriptionStatus.cancelled);
  // (#) Resume sets it back to active.
  Future<void> resume() => _set(SubscriptionStatus.active);

  // (#) Shared helper: writes the chosen status via the gateway, then reloads the row.
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

// (#) Provider the subscription management screen uses to cancel/resume.
final manageSubscriptionProvider =
    Provider<ManageSubscription>(ManageSubscription.new);
