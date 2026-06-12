import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../controls/generate_plan.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../entities/fitness_plan.dart';
import '../../../entities/planned_workout.dart';
import '../common/avatar_button.dart';
import '../profile/fitness_goals_screen.dart';
import '../workout/active_workout_screen.dart';

/// BOUNDARY (#7 Train). Active-plan card + device status + a sticky
/// "Start Freeform Workout" CTA. Plans aren't built in the slice, so the plan
/// card shows the no-plan variant; the free-form path is the live one.
class TrainScreen extends ConsumerWidget {
  const TrainScreen({super.key});

  void _soon(BuildContext context, String what) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$what arrives in a later sprint.')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: const Text('TRAIN', style: AppTypography.title1),
        actions: const [AvatarButton()],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              children: [
                _SectionHeader(
                  label: 'AI SUGGESTED PLAN',
                  action: 'VIEW FULL PLAN ›',
                  onAction: () => _soon(context, 'Plan detail'),
                ),
                const SizedBox(height: 8),
                Consumer(builder: (context, ref, _) {
                  final plan = ref.watch(activePlanProvider).value;
                  final workouts = ref.watch(plannedWorkoutsProvider).value ?? [];
                  if (plan == null) {
                    return _NoPlanCard(
                      onSetGoal: () => Navigator.of(context, rootNavigator: true).push(
                        MaterialPageRoute(builder: (_) => const FitnessGoalsScreen()),
                      ),
                    );
                  }
                  return _ActivePlanCard(plan: plan, workouts: workouts);
                }),
                const SizedBox(height: 24),
                const _SectionHeader(label: 'DEVICES'),
                const SizedBox(height: 8),
                const _PhoneDeviceCard(),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => _soon(context, 'Add device'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.muted,
                    side: const BorderSide(color: AppColors.faint),
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: const Text('+ ADD DEVICE'),
                ),
              ],
            ),
          ),
          // Sticky free-form CTA, always visible above the bottom nav.
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: ElevatedButton.icon(
              onPressed: () => Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute(builder: (_) => const ActiveWorkoutScreen()),
              ),
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('START FREEFORM WORKOUT'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, this.action, this.onAction});

  final String label;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.caption2),
        if (action != null)
          GestureDetector(
            onTap: onAction,
            child: Text(action!, style: AppTypography.caption2.copyWith(color: AppColors.accent)),
          ),
      ],
    );
  }
}

class _NoPlanCard extends StatelessWidget {
  const _NoPlanCard({required this.onSetGoal});

  final VoidCallback onSetGoal;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.faint),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('No active plan', style: AppTypography.title3),
          const SizedBox(height: 6),
          Text('Set a fitness goal to generate your AI plan.', style: AppTypography.subheadline),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: onSetGoal,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.accent,
              side: const BorderSide(color: AppColors.accent),
            ),
            child: const Text('Set a goal'),
          ),
        ],
      ),
    );
  }
}

class _PhoneDeviceCard extends StatelessWidget {
  const _PhoneDeviceCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Text('📱', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Phone sensors', style: AppTypography.headline),
                Text('GPS + steps ready', style: AppTypography.caption1),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.accent),
            ),
            child: Text('CONNECTED',
                style: AppTypography.caption2.copyWith(color: AppColors.accent)),
          ),
        ],
      ),
    );
  }
}

class _ActivePlanCard extends StatelessWidget {
  const _ActivePlanCard({required this.plan, required this.workouts});

  final FitnessPlan plan;
  final List<PlannedWorkout> workouts;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now().weekday;
    final next = workouts.isEmpty
        ? null
        : workouts.firstWhere((w) => w.dayOfWeek >= today, orElse: () => workouts.first);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(plan.name, style: AppTypography.headline),
          const SizedBox(height: 4),
          Text(
            '${plan.workoutsPerWeek}x per week · ${plan.durationWeeks} weeks · '
            '${plan.isPersonalised ? 'AI-assisted' : 'rule-based'}',
            style: AppTypography.caption2.copyWith(color: AppColors.accent),
          ),
          if (next != null) ...[
            const SizedBox(height: 12),
            const Divider(color: AppColors.faint, height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(next.dayOfWeek == today ? 'TODAY' : next.dayName.toUpperCase(),
                    style: AppTypography.caption2.copyWith(
                        color: AppColors.accent, fontWeight: FontWeight.w800)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('${next.name ?? 'Workout'} · ${next.durationMinutes} min',
                      style: AppTypography.subheadline.copyWith(color: AppColors.ink)),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final w in workouts)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.bg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.faint),
                  ),
                  child: Text('${w.dayName} · ${w.name ?? ''}',
                      style: AppTypography.caption2),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
