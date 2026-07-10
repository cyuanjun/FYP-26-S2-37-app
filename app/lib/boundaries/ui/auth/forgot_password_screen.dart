import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../controls/request_password_reset.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/strings.dart';
import '../common/app_card.dart';

// (#) The forgot password screen. User types their email and taps send, which
// hands it to the RequestPasswordReset control. It always shows the same sent
// message so nobody can tell which emails are actually registered.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  // (#) Makes the state object that holds this screen's changing data.
  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

// (#) Holds the live state: the email box and whether the link was already sent.
class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _email = TextEditingController(); // (#) what the user typed as their email
  bool _sent = false; // (#) flips to true once we've fired the reset request

  // (#) Frees the email text box when the screen closes so it doesn't leak.
  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  // (#) Runs on send. Ignores a blank email, asks the control to send the reset
  // link, then flips the view over to the sent confirmation.
  Future<void> _submit() async {
    if (_email.text.isBlank) return;
    await ref.read(requestPasswordResetProvider.notifier).send(_email.text);
    if (mounted) setState(() => _sent = true);
  }

  // (#) Builds the screen: the eyebrow, big heading, a line of help text, then
  // either the email field and send button or the sent card, plus a back link.
  @override
  Widget build(BuildContext context) {
    final sending = ref.watch(requestPasswordResetProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Eyebrow
                Row(
                  children: [
                    Container(width: 24, height: 2, color: AppColors.muted),
                    const SizedBox(width: 8),
                    Text('ACCOUNT RECOVERY',
                        style: AppTypography.caption2.copyWith(
                            color: AppColors.muted, letterSpacing: 2.2)),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('FORGOT\nPASSWORD.',
                    style: TextStyle(
                        fontSize: 48,
                        height: 0.95,
                        fontWeight: FontWeight.w900,
                        color: AppColors.ink)),
                const SizedBox(height: 12),
                Text(
                  _sent
                      ? 'If that email is registered, a reset link is on its way — check your inbox. The link is valid for 30 minutes.'
                      : "Enter your registered email — we'll send a secure reset link valid for 30 minutes.",
                  style: AppTypography.subheadline,
                ),
                const SizedBox(height: 28),
                if (!_sent) ...[
                  TextField(
                    controller: _email,
                    enabled: !sending,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    onSubmitted: (_) => _submit(),
                    decoration:
                        const InputDecoration(labelText: 'EMAIL', hintText: 'you@example.com'),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: sending ? null : _submit,
                    child: sending
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.bg))
                        : const Text('SEND RESET LINK'),
                  ),
                ] else
                  AppCard(
                    borderColor: AppColors.faint,
                    shadow: false,
                    child: Row(
                      children: [
                        const Icon(Icons.mark_email_read_outlined,
                            color: AppColors.success),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text('Reset link sent. You can close this screen.',
                              style: AppTypography.subheadline),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),
                Center(
                  child: TextButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back, size: 14, color: AppColors.muted),
                    label: Text('Back to log in',
                        style: AppTypography.subheadline
                            .copyWith(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
