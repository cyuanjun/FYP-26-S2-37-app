import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../boundaries/gateways/auth_gateway.dart';
import '../boundaries/gateways/profile_gateway.dart';
import '../core/seq_log.dart';
import '../entities/enums.dart';
import 'authenticate.dart';

/// CONTROL — Update Account Settings (#13.3). Inline commits, no save button:
/// the units toggle persists instantly; Change Password reuses the reset-link
/// machinery against the signed-in user's own email.
class UpdateAccountSettings extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> setPreferredUnits(PreferredUnits units) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    SeqLog.msg('account-settings', 'AccountSettingsScreen', 'UpdateAccountSettings',
        'setPreferredUnits(${units.name})');
    await ref.read(profileGatewayProvider).updatePreferredUnits(userId, units);
    ref.invalidate(currentProfileProvider);
  }

  /// Emails the signed-in user a password-reset link.
  Future<bool> sendChangePasswordEmail(String email) async {
    SeqLog.msg('account-settings', 'UpdateAccountSettings', 'AuthGateway',
        'sendPasswordResetEmail');
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => ref.read(authGatewayProvider).sendPasswordResetEmail(email));
    return !state.hasError;
  }
}

final updateAccountSettingsProvider =
    AsyncNotifierProvider<UpdateAccountSettings, void>(UpdateAccountSettings.new);
