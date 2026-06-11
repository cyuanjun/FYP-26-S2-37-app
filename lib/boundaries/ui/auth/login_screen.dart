import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../controls/authenticate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import 'forgot_password_screen.dart';

/// BOUNDARY (#2 Login). Authenticates an existing user. Signup is external
/// (marketing website) — the app is login-only by design.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  static const path = '/login';

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    ref.read(authenticateProvider.notifier).signIn(
          email: _email.text,
          password: _password.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authenticateProvider);
    final isLoading = state.isLoading;
    final error = state.hasError ? state.error : null;

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
                const Text('WISE', style: AppTypography.largeTitle, textAlign: TextAlign.center),
                Text('WORKOUT',
                    style: AppTypography.largeTitle.copyWith(color: AppColors.accent),
                    textAlign: TextAlign.center),
                const SizedBox(height: 40),
                TextField(
                  controller: _email,
                  enabled: !isLoading,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: const InputDecoration(labelText: 'EMAIL', hintText: 'you@example.com'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _password,
                  enabled: !isLoading,
                  obscureText: true,
                  onSubmitted: (_) => _submit(),
                  decoration: const InputDecoration(labelText: 'PASSWORD'),
                ),
                if (error != null) ...[
                  const SizedBox(height: 16),
                  Text(_message(error),
                      style: AppTypography.footnote.copyWith(color: AppColors.danger)),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: isLoading ? null : _submit,
                  child: isLoading
                      ? const SizedBox(
                          height: 22, width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.bg))
                      : const Text('LOG IN'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
                  child: Text('Forgot password?',
                      style: AppTypography.subheadline
                          .copyWith(fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 4),
                Text('No account? Sign up on the Wise Workout website.',
                    style: AppTypography.footnote, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _message(Object error) {
    final s = error.toString();
    if (s.contains('Invalid login credentials')) return 'Incorrect email or password.';
    return 'Sign-in failed. Please try again.';
  }
}
