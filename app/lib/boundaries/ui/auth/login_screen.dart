import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../controls/authenticate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import 'forgot_password_screen.dart';

// (#) The login screen. Shows the email and password form and, when the user
// taps log in, asks the Authenticate control to sign them in. Signup is on the website.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  static const path = '/login'; // (#) route address the router uses for this screen

  // (#) Creates the state object that holds this screen's changing data.
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

// (#) Holds the login screen's live state: the two text boxes and what is typed in them.
class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();    // (#) what the user typed as their email
  final _password = TextEditingController(); // (#) what the user typed as their password

  // (#) Frees the two text boxes when the screen closes so they don't leak memory.
  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  // (#) Runs when the user taps log in. Passes the typed email and password to
  // the Authenticate control, which does the real sign in.
  void _submit() {
    ref.read(authenticateProvider.notifier).signIn(
          email: _email.text,
          password: _password.text,
        );
  }

  // (#) Builds the screen: the title, the email and password boxes, the log in
  // button (a spinner while it works), an error line, and the links below.
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

  // (#) Turns a raw sign in error into a simple message the user can read.
  String _message(Object error) {
    final s = error.toString();
    if (s.contains('Invalid login credentials')) return 'Incorrect email or password.';
    return 'Sign-in failed. Please try again.';
  }
}
