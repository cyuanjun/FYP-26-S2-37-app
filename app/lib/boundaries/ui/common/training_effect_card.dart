import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../controls/authenticate.dart';
import '../../../controls/view_profile.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../entities/training_effect.dart';
import '../../../entities/workout_session.dart';
import '../premium/upgrade_screen.dart';
import 'app_card.dart';

// (#) The Training Effect card shown after a workout and on history detail. Free
// members see the band and score; Premium also gets the aerobic/anaerobic split
// and a recovery estimate. The numbers come from an entity via controls, so
// there's no database work in here.
class TrainingEffectCard extends ConsumerWidget {
  const TrainingEffectCard({super.key, required this.session});

  final WorkoutSession session; // (#) the workout we're describing the effect of

  // (#) The colour for each effect band, low blue through to very high red.
  static const _bandColors = {
    TeBand.low: Color(0xFF0284C7), // info blue
    TeBand.moderate: AppColors.accent,
    TeBand.high: AppColors.premiumText,
    TeBand.veryHigh: AppColors.danger,
  };

  // (#) Builds the card: computes the effect from the session, shows the
  // unavailable note if there's no HR, else the band and score plus either the
  // Premium breakdown or the upsell link for Free members.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium =
        ref.watch(currentProfileProvider).value?.isPremium ?? false;
    final fitness = ref.watch(fitnessProfileProvider).value;
    final effect =
        computeTrainingEffect(session, age: fitness?.ageAt(DateTime.now()));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('TRAINING EFFECT', style: AppTypography.caption2),
        const SizedBox(height: 8),
        AppCard(
          borderColor: AppColors.faint,
          child: effect == null
              ? Text(
                  "Heart rate wasn't captured for this session — effect "
                  'estimate unavailable.',
                  style: AppTypography.footnote)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(effect.band.label,
                            style: AppTypography.title1.copyWith(
                                fontWeight: FontWeight.w900,
                                color: _bandColors[effect.band])),
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 5),
                          child: Text('· ${effect.score} / 10',
                              style: AppTypography.footnote),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(effect.band.advice,
                        style: AppTypography.subheadline
                            .copyWith(color: AppColors.ink)),
                    if (isPremium) ...[
                      const Divider(color: AppColors.faint, height: 20),
                      _effectBar('AEROBIC', effect.aerobic),
                      const SizedBox(height: 8),
                      _effectBar('ANAEROBIC', effect.anaerobic),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Expanded(
                              child: Text('Indicative recovery window',
                                  style: AppTypography.footnote)),
                          Text('~${effect.recoveryHours} h',
                              style: AppTypography.headline),
                        ],
                      ),
                    ] else ...[
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () => Navigator.of(context,
                                rootNavigator: true)
                            .push(MaterialPageRoute(
                                builder: (_) => const UpgradeScreen())),
                        child: Text('⚡ See full breakdown with Premium →',
                            style: AppTypography.footnote.copyWith(
                                color: AppColors.premiumText,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  // (#) One labelled progress bar for the aerobic/anaerobic split, out of 5.
  Widget _effectBar(String label, double value) {
    return Row(
      children: [
        SizedBox(
            width: 92, child: Text(label, style: AppTypography.caption2)),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value / 5,
              minHeight: 8,
              backgroundColor: AppColors.surface2,
              valueColor: const AlwaysStoppedAnimation(AppColors.accent),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
            width: 34,
            child: Text('${value.toStringAsFixed(1)}/5',
                textAlign: TextAlign.right, style: AppTypography.caption2)),
      ],
    );
  }
}
