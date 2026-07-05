import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../boundaries/gateways/auth_gateway.dart';
import '../core/seq_log.dart';

/// CONTROL — Request Password Reset (#4 Forgot Password). Always reports
/// success to the boundary (silent on unknown emails — never reveal whether
/// an address is registered).
class RequestPasswordReset extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

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

final requestPasswordResetProvider =
    AsyncNotifierProvider<RequestPasswordReset, void>(RequestPasswordReset.new);
