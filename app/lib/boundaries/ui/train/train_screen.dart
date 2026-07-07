import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../controls/generate_plan.dart';
import '../../../controls/manage_connected_device.dart';
import '../../../core/theme/app_buttons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../entities/enums.dart';
import '../../../entities/fitness_plan.dart';
import '../../../entities/planned_workout.dart';
import '../common/app_card.dart';
import '../common/avatar_button.dart';
import 'manual_entry_screen.dart';
import '../common/status_badge.dart';
import '../profile/fitness_goals_screen.dart';
import '../workout/active_workout_screen.dart';
import 'connected_devices_screen.dart';
import 'my_plans_screen.dart';

/// BOUNDARY (#7 Train). Active-plan card + device status + a sticky
/// "Start Freeform Workout" CTA. Plans aren't built in the slice, so the plan
/// card shows the no-plan variant; the free-form path is the live one.
class TrainScreen extends ConsumerWidget {
  const TrainScreen({super.key});

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
                  label: 'SELECTED PLAN',
                  action: 'VIEW PLANS ›',
                  onAction: () => Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute(builder: (_) => const MyPlansScreen()),
                  ),
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
                Consumer(builder: (context, ref, _) {
                  final devices =
                      ref.watch(connectedDevicesProvider).value ?? [];
                  final active = devices.where((d) => d.isActive).toList();
                  final wearables =
                      active.where((d) => !d.isPhoneSensors).toList();
                  return InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => Navigator.of(context, rootNavigator: true).push(
                        MaterialPageRoute(
                            builder: (_) => const ConnectedDevicesScreen())),
                    child: _DevicesCard(
                      title: wearables.isEmpty
                          ? 'Phone sensors'
                          : wearables.first.deviceName,
                      subtitle: wearables.isEmpty
                          ? 'GPS + steps ready'
                          : 'HR + phone GPS ready',
                      emoji: wearables.isEmpty ? '📱' : wearables.first.deviceType.emoji,
                      extra: active.length > 1 ? '${active.length} sources' : null,
                    ),
                  );
                }),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => Navigator.of(context, rootNavigator: true).push(
                      MaterialPageRoute(
                          builder: (_) => const ConnectedDevicesScreen())),
                  style: AppButtonStyles.outlinedAccent(height: 48),
                  child: const Text('+ ADD DEVICE'),
                ),
              ],
            ),
          ),
          // Sticky capture CTAs, always visible above the bottom nav.
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton.icon(
                  onPressed: () => Navigator.of(context, rootNavigator: true)
                      .push(MaterialPageRoute(
                          builder: (_) => const ActiveWorkoutScreen())),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('START FREEFORM WORKOUT'),
                ),
                const SizedBox(height: 8),
                // US13 — sessions done without the phone still count.
                TextButton.icon(
                  onPressed: () => Navigator.of(context, rootNavigator: true)
                      .push(MaterialPageRoute(
                          builder: (_) => const ManualEntryScreen())),
                  icon: const Icon(Icons.edit_calendar_outlined, size: 18),
                  label: const Text('Log a workout manually'),
                ),
              ],
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
    return AppCard(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      borderColor: AppColors.faint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('No active plan', style: AppTypography.title3),
          const SizedBox(height: 6),
          Text('Set a fitness goal to generate your AI plan.', style: AppTypography.subheadline),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: onSetGoal,
            style: AppButtonStyles.outlinedAccent(),
            child: const Text('Set a goal'),
          ),
        ],
      ),
    );
  }
}

class _DevicesCard extends StatelessWidget {
  const _DevicesCard(
      {required this.title, required this.subtitle, required this.emoji, this.extra});

  final String title;
  final String subtitle;
  final String emoji;
  final String? extra;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.headline),
                Text(extra == null ? subtitle : '$subtitle · $extra',
                    style: AppTypography.caption1),
              ],
            ),
          ),
          const StatusBadge('CONNECTED',
              bg: AppColors.successBright,
              fg: AppColors.ink,
              weight: FontWeight.w800,
              radius: 20,
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
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
    // Current week within the generated full timeline.
    final started = plan.startedAt;
    final cycleWeek = started == null
        ? 1
        : ((DateTime.now().difference(started).inDays ~/ 7) + 1)
            .clamp(1, plan.durationWeeks)
            .toInt();
    final thisWeek =
        workouts.where((w) => w.weekNumber == cycleWeek).toList();
    // The next session this week: first on/after today, else the week's first.
    final next = thisWeek.isEmpty
        ? null
        : thisWeek.firstWhere((w) => w.dayOfWeek >= today, orElse: () => thisWeek.first);
    // Today's scheduled workout (if any) — start it straight from the card.
    final todaysList = thisWeek.where((w) => w.dayOfWeek == today).toList();
    final todaysWorkout = todaysList.isEmpty ? null : todaysList.first;

    return AppCard(
      borderColor: AppColors.faint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(plan.name, style: AppTypography.headline),
          const SizedBox(height: 4),
          Text(
            '${plan.workoutsPerWeek}x per week · ${plan.durationWeeks} weeks · '
            'AI-assisted (${plan.isPersonalised ? 'personalised' : 'basic'})',
            style: AppTypography.caption2.copyWith(color: AppColors.muted),
          ),
          if (thisWeek.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(color: AppColors.faint, height: 1),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('THIS WEEK', style: AppTypography.caption2),
                  Text('WEEK $cycleWeek/${plan.durationWeeks}', style: AppTypography.caption2),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Divider(color: AppColors.faint, height: 1),
            const SizedBox(height: 4),
            for (final w in thisWeek) _dayRow(w, identical(w, next)),
            const SizedBox(height: 14),
            if (todaysWorkout != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute(
                      builder: (_) => ActiveWorkoutScreen(
                          initialTypeId: todaysWorkout.workoutTypeId),
                    ),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('START PLANNED WORKOUT'),
                ),
              )
            else
              Text('No workout scheduled today.',
                  textAlign: TextAlign.center, style: AppTypography.footnote),
          ],
        ],
      ),
    );
  }

  /// One row of the weekly schedule. The [isNext] session is highlighted with a
  /// green tint + a NEXT tag so the user can see what's coming up.
  Widget _dayRow(PlannedWorkout w, bool isNext) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: isNext
          ? BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            )
          : null,
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Text(w.dayName.toUpperCase(),
                style: AppTypography.caption2
                    .copyWith(color: AppColors.success, fontWeight: FontWeight.w800)),
          ),
          Expanded(
            child: Text(w.name ?? 'Workout',
                style: AppTypography.subheadline.copyWith(
                    color: AppColors.ink,
                    fontWeight: isNext ? FontWeight.w700 : FontWeight.w500)),
          ),
          Text('${w.durationMinutes} min', style: AppTypography.caption2),
        ],
      ),
    );
  }
}
