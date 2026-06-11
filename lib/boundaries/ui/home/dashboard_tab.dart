import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../controls/authenticate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// BOUNDARY (#5 Dashboard — minimal slice version). Greets the signed-in user
/// and offers sign-out; the full digest (today card, weekly stats, goal) lands later.
class DashboardTab extends ConsumerWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wise Workout'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authenticateProvider.notifier).signOut(),
          ),
        ],
      ),
      body: profile.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load profile.\n$e', style: AppTypography.footnote)),
        data: (p) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hi, ${p?.firstName ?? 'there'} 👋', style: AppTypography.title1),
              const SizedBox(height: 8),
              Text(p?.isPremium ?? false ? 'Premium member' : 'Free member',
                  style: AppTypography.subheadline),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Get moving', style: AppTypography.headline),
                    const SizedBox(height: 8),
                    Text('Head to Train to record a workout, then check History for your stats and AI summary.',
                        style: AppTypography.subheadline),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
