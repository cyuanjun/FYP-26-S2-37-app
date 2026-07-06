import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../controls/start_premium.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../common/app_card.dart';
import '../common/premium_cta.dart';

/// BOUNDARY (#16 Upgrade to Premium). Marketing surface pitching the Premium
/// tier — every bullet maps to a real built gate. START PREMIUM opens the
/// simulated-payment sheet; confirming runs the `start_premium` RPC and the
/// whole app flips to Premium live (no re-login).
class UpgradeScreen extends ConsumerWidget {
  const UpgradeScreen({super.key});

  static const _unlocks = [
    (
      'Personalised AI fitness plans',
      'Built from your profile, goals, and injuries — not a generic template.'
    ),
    (
      'Detailed workout breakdowns',
      'Sets, reps, target HR zones, and coaching cues for every planned workout.'
    ),
    (
      'Advanced session insights',
      'Zone time, pace splits, cadence quality, and trends across recent sessions.'
    ),
    (
      'Unlimited workout history',
      'Every session, forever — plus all-time and advanced analytics views.'
    ),
    (
      'Smart reminders',
      'Reminders that adapt to your schedule, plus load-based recovery alerts.'
    ),
    (
      'Unlimited plan regenerations',
      'Adjust your plan as often as you need (Free is capped at 1 per month).'
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
          title: const Text('UPGRADE TO PREMIUM', style: AppTypography.caption2),
          centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        children: [
          // ---- Hero ----
          Row(
            children: [
              Container(width: 24, height: 3, color: AppColors.accent),
              const SizedBox(width: 8),
              Text('GO FURTHER',
                  style: AppTypography.caption2.copyWith(
                      color: AppColors.accent, letterSpacing: 2.2)),
            ],
          ),
          const SizedBox(height: 10),
          const Text('TRAIN',
              style: TextStyle(
                  fontSize: 44,
                  height: 0.95,
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink)),
          const Text('SMARTER.',
              style: TextStyle(
                  fontSize: 44,
                  height: 1.0,
                  fontWeight: FontWeight.w900,
                  color: AppColors.accent)),
          const SizedBox(height: 24),

          // ---- Unlocks ----
          Text('PREMIUM UNLOCKS', style: AppTypography.caption2),
          const SizedBox(height: 4),
          for (final (i, u) in _unlocks.indexed) ...[
            if (i > 0) const Divider(color: AppColors.faint, height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle,
                      size: 20, color: AppColors.accent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(u.$1,
                            style: AppTypography.subheadline
                                .copyWith(color: AppColors.ink)),
                        const SizedBox(height: 2),
                        Text(u.$2,
                            style: AppTypography.caption1
                                .copyWith(fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),

          // ---- Pricing ----
          AppCard(
            borderColor: AppColors.premium,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Premium Monthly',
                          style: AppTypography.headline),
                      Text('Cancel anytime', style: AppTypography.caption2),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('\$9.99',
                        style: AppTypography.title1.copyWith(
                            color: AppColors.premiumText,
                            fontWeight: FontWeight.w900)),
                    Text('/ mo', style: AppTypography.caption2),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          PremiumCta('START PREMIUM',
              fullWidth: true,
              radius: 16,
              padding: const EdgeInsets.symmetric(vertical: 16),
              style: AppTypography.headline.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2),
              onTap: () => _showPaymentSheet(context)),
          const SizedBox(height: 12),
          Center(
              child: Text('Payment is simulated — no real charge.',
                  style: AppTypography.caption2)),
          const SizedBox(height: 4),
          Center(
              child: Text('Expert services billed separately',
                  style: AppTypography.caption2)),
        ],
      ),
    );
  }

  void _showPaymentSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => const _SimulatedPaymentSheet(),
    );
  }
}

/// The simulated checkout: plan summary + mock card + confirm. Confirming
/// calls the StartPremium control; on success both sheet and screen pop so
/// the user lands back on the (now Premium) screen that sent them here.
class _SimulatedPaymentSheet extends ConsumerStatefulWidget {
  const _SimulatedPaymentSheet();

  @override
  ConsumerState<_SimulatedPaymentSheet> createState() =>
      _SimulatedPaymentSheetState();
}

class _SimulatedPaymentSheetState
    extends ConsumerState<_SimulatedPaymentSheet> {
  bool _busy = false;

  Future<void> _confirm() async {
    setState(() => _busy = true);
    try {
      await ref.read(startPremiumProvider).call();
      if (!mounted) return;
      Navigator.pop(context); // sheet
      Navigator.pop(context); // upgrade screen
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Welcome to Premium 🎉')));
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Upgrade failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 0, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SIMULATED PAYMENT', style: AppTypography.caption2),
          const SizedBox(height: 12),
          AppCard(
            borderColor: AppColors.faint,
            child: Row(
              children: [
                const Expanded(
                    child: Text('Premium Monthly',
                        style: AppTypography.headline)),
                Text('\$9.99 / mo',
                    style: AppTypography.headline
                        .copyWith(color: AppColors.premiumText)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          AppCard(
            borderColor: AppColors.faint,
            child: Row(
              children: [
                const Icon(Icons.credit_card,
                    size: 20, color: AppColors.muted),
                const SizedBox(width: 10),
                const Expanded(
                    child:
                        Text('Visa •••• 4242', style: AppTypography.footnote)),
                Text('MOCK', style: AppTypography.caption2),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text('No real card is charged — this checkout is simulated.',
              style: AppTypography.caption2),
          const SizedBox(height: 16),
          PremiumCta(_busy ? 'PROCESSING…' : 'CONFIRM PAYMENT',
              fullWidth: true,
              radius: 16,
              padding: const EdgeInsets.symmetric(vertical: 16),
              style: AppTypography.headline.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2),
              onTap: _busy ? null : _confirm),
        ],
      ),
    );
  }
}
