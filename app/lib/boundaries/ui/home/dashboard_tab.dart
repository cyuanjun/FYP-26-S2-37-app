import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../controls/authenticate.dart';
import '../../../core/theme/app_typography.dart';
import '../common/app_card.dart';
import '../common/avatar_button.dart';
import '../common/premium_cta.dart';
import '../premium/upgrade_screen.dart';
import 'my_purchases_section.dart';

// (#) The Home tab you land on after login. Says hi to the user, pushes Free
// members toward Premium, and shows the stuff they've bought. Reads the profile
// via the Authenticate control.
class DashboardTab extends ConsumerWidget {
  const DashboardTab({super.key});

  // (#) Builds the tab: app bar with avatar, greeting, member line, a Premium
  // nudge for Free users, a "get moving" card, and the purchases strip.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wise Workout'),
        actions: const [AvatarButton()],
      ),
      body: profile.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            'Could not load profile.\n$e',
            style: AppTypography.footnote,
          ),
        ),
        data: (p) => ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Hi, ${p?.firstName ?? 'there'} 👋',
              style: AppTypography.title1,
            ),
            const SizedBox(height: 8),
            Text(
              p?.isPremium ?? false ? 'Premium member' : 'Free member',
              style: AppTypography.subheadline,
            ),
            if (p?.isFree ?? false) ...[
              const SizedBox(height: 12),
              PremiumCta('⚡ Go Premium — personalised AI plans & more',
                  fullWidth: true,
                  radius: 12,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  onTap: () => Navigator.of(context, rootNavigator: true)
                      .push(MaterialPageRoute(
                          builder: (_) => const UpgradeScreen()))),
            ],
            const SizedBox(height: 24),
            AppCard(
              width: double.infinity,
              radius: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Get moving', style: AppTypography.headline),
                  const SizedBox(height: 8),
                  Text(
                    'Head to Train to record a workout, then check History for your stats and AI summary.',
                    style: AppTypography.subheadline,
                  ),
                ],
              ),
            ),
            const MyPurchasesSection(),
          ],
        ),
      ),
    );
  }
}
