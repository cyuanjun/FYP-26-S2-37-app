import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../controls/request_password_reset.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// BOUNDARY (#4 Forgot Password). Sends a reset link; always shows the
/// "sent" card regardless of whether the email matched (anti-enumeration).
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _email = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_email.text.trim().isEmpty) return;
    await ref.read(requestPasswordResetProvider.notifier).send(_email.text);
    if (mounted) setState(() => _sent = true);
  }

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
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.faint),
                    ),
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
