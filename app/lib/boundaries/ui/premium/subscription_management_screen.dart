import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../controls/start_premium.dart';
import '../../../core/format.dart';
import '../../../core/theme/app_buttons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../entities/subscription.dart';
import '../common/app_card.dart';
import '../common/premium_cta.dart';
import '../common/status_badge.dart';
import 'upgrade_screen.dart';

/// BOUNDARY (#13.6 Subscription Management). Premium counterpart to #16:
/// plan + status, mock payment method, synthesised billing history, and
/// cancel / resume. Cancel keeps access until the renewal date (and keeps
/// role = premium in this simulated realization).
class SubscriptionManagementScreen extends ConsumerWidget {
  const SubscriptionManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sub = ref.watch(subscriptionProvider).value;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
          title: const Text('SUBSCRIPTION', style: AppTypography.caption2),
          centerTitle: true),
      body: sub == null ? _empty(context) : _body(context, ref, sub),
    );
  }

  /// Defensive Free-state (#13.6 is premium-gated, but don't crash).
  Widget _empty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('No active subscription', style: AppTypography.subheadline),
          const SizedBox(height: 12),
          PremiumCta('GO PREMIUM',
              icon: Icons.star,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const UpgradeScreen()))),
        ],
      ),
    );
  }

  Widget _body(BuildContext context, WidgetRef ref, Subscription sub) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        // ---- Plan card ----
        AppCard(
          borderColor: AppColors.premium,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                      child: Text('⭐ PREMIUM MONTHLY',
                          style: AppTypography.headline)),
                  if (sub.isActive)
                    const StatusBadge('ACTIVE',
                        bg: AppColors.successBright, fg: AppColors.ink)
                  else if (sub.isCancelled)
                    const StatusBadge('CANCELLED',
                        borderColor: AppColors.faint)
                  else
                    const StatusBadge('PAST DUE',
                        bg: AppColors.premium, fg: AppColors.ink),
                ],
              ),
              const SizedBox(height: 6),
              Text(sub.priceLabel,
                  style: AppTypography.title2
                      .copyWith(color: AppColors.premiumText)),
              const Divider(color: AppColors.faint, height: 20),
              Text(
                  sub.isActive
                      ? 'Renews ${fmtDate(sub.renewsAt)}'
                      : 'Cancelled — access until ${fmtDate(sub.renewsAt)}',
                  style: AppTypography.footnote),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ---- Payment method (mock) ----
        Text('PAYMENT METHOD', style: AppTypography.caption2),
        const SizedBox(height: 8),
        AppCard(
          borderColor: AppColors.faint,
          child: Row(
            children: [
              const Icon(Icons.credit_card, size: 20, color: AppColors.muted),
              const SizedBox(width: 10),
              const Expanded(
                  child: Text('Visa •••• 4242', style: AppTypography.footnote)),
              Text('MOCK', style: AppTypography.caption2),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ---- Billing history (synthesised — no BillingRecord in v1) ----
        Text('BILLING HISTORY', style: AppTypography.caption2),
        const SizedBox(height: 8),
        AppCard(
          borderColor: AppColors.faint,
          child: Column(
            children: [
              for (final (i, d) in sub.billingDates(DateTime.now()).indexed) ...[
                if (i > 0) const Divider(color: AppColors.faint, height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Premium Monthly',
                              style: AppTypography.footnote),
                          Text(fmtDate(d), style: AppTypography.caption2),
                        ],
                      ),
                    ),
                    Text('\$9.99',
                        style: AppTypography.footnote
                            .copyWith(color: AppColors.ink)),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),

        // ---- Manage ----
        if (sub.isActive)
          OutlinedButton(
            onPressed: () => _confirmCancel(context, ref, sub),
            style: AppButtonStyles.outlinedDanger(height: 52, radius: 16),
            child: const Text('CANCEL SUBSCRIPTION',
                style: TextStyle(
                    fontWeight: FontWeight.w900, letterSpacing: 1.2)),
          )
        else
          OutlinedButton(
            onPressed: () => ref.read(manageSubscriptionProvider).resume(),
            style: AppButtonStyles.outlinedAccent(height: 52, radius: 16),
            child: const Text('RESUME SUBSCRIPTION',
                style: TextStyle(
                    fontWeight: FontWeight.w900, letterSpacing: 1.2)),
          ),
      ],
    );
  }

  void _confirmCancel(BuildContext context, WidgetRef ref, Subscription sub) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Cancel subscription?'),
        content: Text(
            "You'll keep Premium access until ${fmtDate(sub.renewsAt)}. "
            'After that you would return to Free.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Keep Premium')),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              ref.read(manageSubscriptionProvider).cancel();
            },
            child: const Text('Cancel subscription',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}
