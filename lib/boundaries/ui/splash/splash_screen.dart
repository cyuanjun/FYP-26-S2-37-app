import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../home/home_screen.dart';

/// BOUNDARY (#1 Splash). Brand entry point; routes onward once the app is ready.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  static const path = '/';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('WISE', style: AppTypography.largeTitle),
            Text(
              'WORKOUT',
              style: AppTypography.largeTitle.copyWith(color: AppColors.accent),
            ),
            const SizedBox(height: 8),
            const Text('FYP-26-S2-37', style: AppTypography.caption2),
            const SizedBox(height: 48),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: ElevatedButton(
                onPressed: () => context.go(HomeScreen.path),
                child: const Text('Get started'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
