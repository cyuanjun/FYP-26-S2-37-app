import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../gateways/auth_gateway.dart';

/// BOUNDARY — placeholder home. Confirms Supabase init + the BCE wiring is live.
/// Replaced by the Dashboard (#5) as the vertical slice lands.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const path = '/home';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authGatewayProvider);
    final email = auth.currentUser?.email;

    return Scaffold(
      appBar: AppBar(title: const Text('Wise Workout')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Scaffold is live ✓', style: AppTypography.title2),
            const SizedBox(height: 12),
            Text(
              'Supabase initialized · BCE structure in place.',
              style: AppTypography.subheadline,
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                auth.isSignedIn ? 'Signed in as $email' : 'Not signed in (login arrives with the vertical slice)',
                style: AppTypography.body,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
