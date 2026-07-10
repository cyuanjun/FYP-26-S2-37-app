import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../controls/authenticate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../auth/login_screen.dart';
import '../home/home_shell.dart';

// (#) The branded landing screen shown on launch. After a short pause it checks
// (#) whether anyone is signed in and sends them to Home or Login.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  static const path = '/'; // (#) route address for this screen, the app root

  // (#) Creates the state object that runs the launch delay and redirect.
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

// (#) Holds the splash screen state, mainly the startup timer and redirect logic.
class _SplashScreenState extends ConsumerState<SplashScreen> {
  // (#) Waits a moment after first paint, then routes to Home if signed in else Login.
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      final signedIn = ref.read(currentUserIdProvider) != null;
      context.go(signedIn ? HomeShell.path : LoginScreen.path);
    });
  }

  // (#) Draws the centered WISE WORKOUT wordmark and the tagline underneath.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('WISE', style: AppTypography.largeTitle),
            Text('WORKOUT',
                style: AppTypography.largeTitle.copyWith(color: AppColors.accent)),
            const SizedBox(height: 8),
            const Text('Train smart. Move better.', style: AppTypography.subheadline),
          ],
        ),
      ),
    );
  }
}
