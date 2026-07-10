import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../boundaries/gateways/auth_gateway.dart';
import '../core/seq_log.dart';

// (#) The Forgot Password use case (#4). Asks the auth gateway to mail a reset
// (#) link. It always reports success even for unknown emails, so nobody can probe
// (#) which addresses are registered.
class RequestPasswordReset extends AsyncNotifier<void> {
  // (#) Nothing to load up front, so build just returns empty.
  @override
  Future<void> build() async {}

  // (#) Runs when the user submits the forgot-password form. Sets loading, then calls
  // (#) the auth gateway to send the email, always ending in a success state.
  Future<void> send(String email) async {
    SeqLog.msg('password-reset', 'ForgotPasswordScreen', 'RequestPasswordReset',
        'send($email)');
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      SeqLog.msg('password-reset', 'RequestPasswordReset', 'AuthGateway',
          'sendPasswordResetEmail');
      try {
        await ref.read(authGatewayProvider).sendPasswordResetEmail(email);
      } catch (_) {
        // Swallow lookup-ish failures: the boundary shows the same "sent" card
        // either way (anti-enumeration). Rate-limit errors land here too.
      }
    });
  }
}

// (#) The provider the forgot-password screen watches to run and track the reset.
final requestPasswordResetProvider =
    AsyncNotifierProvider<RequestPasswordReset, void>(RequestPasswordReset.new);
