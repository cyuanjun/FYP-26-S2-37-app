import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../controls/authenticate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../auth/login_screen.dart';
import '../home/home_shell.dart';

/// BOUNDARY (#1 Splash). Brand entry point; routes to Home or Login based on session.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  static const path = '/';

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
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
