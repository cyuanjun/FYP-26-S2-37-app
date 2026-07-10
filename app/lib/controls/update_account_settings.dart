import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../boundaries/gateways/auth_gateway.dart';
import '../boundaries/gateways/profile_gateway.dart';
import '../core/seq_log.dart';
import '../entities/enums.dart';
import 'authenticate.dart';
import '../core/strings.dart';

// (#) The Update Account Settings use case (#13.3). Everything commits inline, there
// (#) is no save button: the units toggle saves right away, and Change Password just
// (#) reuses the password-reset email flow against the user's own address.
class UpdateAccountSettings extends AsyncNotifier<void> {
  // (#) Nothing to preload.
  @override
  Future<void> build() async {}

  // (#) Saves the metric/imperial choice through the profile gateway and refreshes
  // (#) the profile so the rest of the app picks up the new units.
  Future<void> setPreferredUnits(PreferredUnits units) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    SeqLog.msg('account-settings', 'AccountSettingsScreen', 'UpdateAccountSettings',
        'setPreferredUnits(${units.name})');
    await ref.read(profileGatewayProvider).updatePreferredUnits(userId, units);
    ref.invalidate(currentProfileProvider);
  }

  // (#) Saves the user's name via the gateway. Used both as an onboarding fallback
  // (#) when signup metadata was missing and for later #13.3 name editing. Rejects a
  // (#) blank first name and returns whether it saved.
  Future<bool> saveName({required String firstName, String? lastName}) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null || firstName.isBlank) return false;
    SeqLog.msg('account-settings', 'UpdateAccountSettings', 'ProfileGateway',
        'updateName($firstName)');
    await ref
        .read(profileGatewayProvider)
        .updateName(userId, firstName: firstName, lastName: lastName);
    ref.invalidate(currentProfileProvider);
    return true;
  }

  // (#) The Change Password action: emails the signed-in user a reset link through
  // (#) the auth gateway, tracking loading/error state. Returns whether it sent.
  Future<bool> sendChangePasswordEmail(String email) async {
    SeqLog.msg('account-settings', 'UpdateAccountSettings', 'AuthGateway',
        'sendPasswordResetEmail');
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => ref.read(authGatewayProvider).sendPasswordResetEmail(email));
    return !state.hasError;
  }
}

// (#) Provider the account settings screen watches for these actions and their state.
final updateAccountSettingsProvider =
    AsyncNotifierProvider<UpdateAccountSettings, void>(UpdateAccountSettings.new);
