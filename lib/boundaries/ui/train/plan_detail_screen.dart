import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../controls/authenticate.dart';
import '../../../controls/generate_plan.dart';
import '../../../controls/view_profile.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../entities/fitness_plan.dart';
import '../../../entities/planned_workout.dart';
import '../../../entities/workout_type.dart';
import '../../gateways/workout_gateway.dart';
import '../workout/active_workout_screen.dart';

/// BOUNDARY (#8 Plan Detail). Read-only view of an active or saved plan:
/// header + meta, week schedule, and active-plan actions.
class PlanDetailScreen extends ConsumerStatefulWidget {
  const PlanDetailScreen({super.key, this.planId});

  final String? planId;

  @override
  ConsumerState<PlanDetailScreen> createState() => _PlanDetailScreenState();
}

class _PlanDetailScreenState extends ConsumerState<PlanDetailScreen> {
  int? _selectedWeek; // null = current active week, or week 1 for inactive plans

  @override
  Widget build(BuildContext context) {
    final planAsync = widget.planId == null
        ? ref.watch(activePlanProvider)
        : ref.watch(planByIdProvider(widget.planId!));
    final workouts = widget.planId == null
        ? ref.watch(plannedWorkoutsProvider).value ?? []
        : ref.watch(plannedWorkoutsForPlanProvider(widget.planId!)).value ?? [];
    final types = ref.watch(workoutTypesProvider).value ?? [];
    final profile = ref.watch(currentProfileProvider).value;
    final experience =
        ref.watch(fitnessProfileProvider).value?.trainingExperience;
    final byId = {for (final t in types) t.id: t};
    final isPremium = profile?.isPremium ?? false;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Text('YOUR PLAN',
            style: AppTypography.subheadline.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w700,
                letterSpacing: 2)),
      ),
      body: planAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            Center(child: Text('Could not load plan.', style: AppTypography.subheadline)),
        data: (plan) {
          if (plan == null) {
            return Center(
                child: Text('No active plan yet.', style: AppTypography.subheadline));
          }
          final today = DateTime.now().weekday;
          final cycleWeek = _cycleWeek(plan);
          final shownWeek = _selectedWeek ?? cycleWeek;
          final weekWorkouts =
              workouts.where((w) => w.weekNumber == shownWeek).toList();
          final todays = workouts
              .where((w) => w.weekNumber == cycleWeek && w.dayOfWeek == today)
              .toList();

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  children: [
                    // ---- Header ----
                    Text(plan.name.toUpperCase(),
                        style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                            color: AppColors.ink)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${plan.durationWeeks} WEEKS · ${plan.workoutsPerWeek}X/WEEK'
                            '${experience != null ? ' · ${experience.name.toUpperCase()}' : ''}',
                            style: AppTypography.caption2.copyWith(letterSpacing: 1.4),
                          ),
                        ),
                        if (plan.isPersonalised)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.muted),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text('PERSONALISED',
                                style: AppTypography.caption2
                                    .copyWith(color: AppColors.muted)),
                          ),
                      ],
                    ),
                    if (plan.description != null) ...[
                      const SizedBox(height: 12),
                      Text(plan.description!,
                          style: AppTypography.footnote.copyWith(height: 1.4)),
                    ],
                    const SizedBox(height: 24),

                    // ---- Full timeline: week selector ----
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (var wk = 1; wk <= plan.durationWeeks; wk++) ...[
                            GestureDetector(
                              onTap: () => setState(() => _selectedWeek = wk),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: shownWeek == wk
                                      ? AppColors.accent
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                      color: shownWeek == wk
                                          ? AppColors.accent
                                          : AppColors.faint),
                                ),
                                child: Text('W$wk',
                                    style: AppTypography.caption2.copyWith(
                                        color: shownWeek == wk
                                            ? AppColors.bg
                                            : AppColors.muted,
                                        fontWeight: FontWeight.w800)),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text('WEEK $shownWeek',
                            style: AppTypography.caption2.copyWith(letterSpacing: 1.4)),
                        if (shownWeek == cycleWeek)
                          Text(' · CURRENT',
                              style: AppTypography.caption2
                                  .copyWith(color: AppColors.muted, letterSpacing: 1.4)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          for (var i = 0; i < weekWorkouts.length; i++) ...[
                            if (i > 0)
                              const Divider(color: AppColors.faint, height: 1),
                            _scheduleRow(context, weekWorkouts[i], byId,
                                isToday: shownWeek == cycleWeek &&
                                    weekWorkouts[i].dayOfWeek == today,
                                currentWeek: shownWeek,
                                isPremium: isPremium),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Full ${plan.durationWeeks}-week timeline: foundation → build → peak → recovery.',
                      style: AppTypography.caption1,
                    ),
                    const SizedBox(height: 16),
                    if (plan.isActive) ...[
                      const SizedBox(height: 16),
                      Center(
                        child: _RegenerateLink(plan: plan, isPremium: isPremium),
                      ),
                    ],
                  ],
                ),
              ),

              // ---- Sticky primary action ----
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: plan.isActive
                    ? ElevatedButton.icon(
                        onPressed: todays.isEmpty
                            ? null
                            : () => Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => ActiveWorkoutScreen(
                                    initialTypeId: todays.first.workoutTypeId))),
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: Text(todays.isEmpty
                            ? 'NO WORKOUT SCHEDULED TODAY'
                            : "START TODAY'S WORKOUT"),
                      )
                    : _UsePlanButton(plan: plan),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Week within the generated full timeline.
  int _cycleWeek(FitnessPlan plan) {
    final started = plan.startedAt;
    if (!plan.isActive || started == null) return 1;
    return ((DateTime.now().difference(started).inDays ~/ 7) + 1)
        .clamp(1, plan.durationWeeks)
        .toInt();
  }

  Widget _scheduleRow(BuildContext context, PlannedWorkout w,
      Map<String, WorkoutType> byId,
      {required bool isToday, required int currentWeek, required bool isPremium}) {
    final dayStyle = AppTypography.caption2.copyWith(
        color: isToday ? AppColors.accent : AppColors.muted,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2);
    return Material(
      color: isToday ? AppColors.accent.withValues(alpha: 0.08) : Colors.transparent,
      child: InkWell(
        onTap: () => _showWorkoutModal(context, w, byId[w.workoutTypeId],
            isToday: isToday, currentWeek: currentWeek, isPremium: isPremium),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              SizedBox(width: 44, child: Text(w.dayName.toUpperCase(), style: dayStyle)),
              Expanded(
                child: Text(w.name ?? byId[w.workoutTypeId]?.name ?? 'Workout',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.subheadline
                        .copyWith(color: AppColors.ink, fontWeight: FontWeight.w600)),
              ),
              Text('${w.durationMinutes}m',
                  style: AppTypography.footnote.copyWith(
                      color: AppColors.metricColor('MIN'))),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right, size: 18, color: AppColors.faint),
            ],
          ),
        ),
      ),
    );
  }

  void _showWorkoutModal(BuildContext context, PlannedWorkout w, WorkoutType? type,
      {required bool isToday, required int currentWeek, required bool isPremium}) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('WEEK $currentWeek · ${w.dayName.toUpperCase()}',
                      style: AppTypography.caption2.copyWith(letterSpacing: 1.4)),
                  if (isToday)
                    Text(' · TODAY',
                        style: AppTypography.caption2
                            .copyWith(color: AppColors.muted, letterSpacing: 1.4)),
                ],
              ),
              const SizedBox(height: 8),
              Text((w.name ?? 'Workout').toUpperCase(),
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.ink)),
              const SizedBox(height: 4),
              Text('${type?.name ?? 'Workout'} · ${w.durationMinutes} min',
                  style: AppTypography.footnote),
              if (w.descriptor != null && w.descriptor!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(w.descriptor!,
                    style: AppTypography.subheadline.copyWith(color: AppColors.ink)),
              ],
              if (!isPremium) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.premium.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '⚡ Upgrade to Premium for sets, reps, target zones, and coaching cues.',
                    style: AppTypography.footnote.copyWith(color: AppColors.premiumText),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              if (isToday)
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) =>
                            ActiveWorkoutScreen(initialTypeId: w.workoutTypeId)));
                  },
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('START WORKOUT'),
                ),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text('Close',
                      style: AppTypography.subheadline.copyWith(color: AppColors.muted)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RegenerateLink extends ConsumerWidget {
  const _RegenerateLink({required this.plan, required this.isPremium});

  final FitnessPlan plan;
  final bool isPremium;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final generating = ref.watch(generatePlanProvider).isLoading;
    final blocked = !isPremium && plan.regeneratedCount >= 1;

    return Column(
      children: [
        TextButton(
          onPressed: blocked || generating
              ? null
              : () async {
                  final go = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: AppColors.surface,
                      title: const Text('Generate a new plan?'),
                      content: Text(isPremium
                          ? 'Your current plan will be replaced. Workout history stays.'
                          : 'Your current plan will be replaced. Workout history stays.\n\n'
                              '${1 - plan.regeneratedCount} regeneration left this month.'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Text('Cancel')),
                        TextButton(
                            onPressed: () => Navigator.of(ctx).pop(true),
                            child: const Text('Generate')),
                      ],
                    ),
                  );
                  if (go != true) return;
                  final newPlan =
                      await ref.read(generatePlanProvider.notifier).generate();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(newPlan == null
                            ? 'Could not regenerate. Try again.'
                            : 'New plan generated.')));
                  }
                },
          child: generating
              ? const SizedBox(
                  height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : Text('Regenerate plan',
                  style: AppTypography.subheadline.copyWith(
                      color: blocked ? AppColors.faint : AppColors.info,
                      fontWeight: FontWeight.w600)),
        ),
        if (blocked)
          Text('Upgrade for unlimited regenerations',
              style: AppTypography.caption2.copyWith(color: AppColors.premiumText)),
      ],
    );
  }
}

class _UsePlanButton extends ConsumerWidget {
  const _UsePlanButton({required this.plan});

  final FitnessPlan plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selecting = ref.watch(selectFitnessPlanProvider).isLoading;
    return ElevatedButton.icon(
      onPressed: selecting
          ? null
          : () async {
              final ok =
                  await ref.read(selectFitnessPlanProvider.notifier).select(plan.id);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(ok
                    ? 'Plan is now active.'
                    : 'Could not activate this plan. Try again.'),
              ));
            },
      icon: selecting
          ? const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.check_circle_outline),
      label: const Text('USE THIS PLAN'),
    );
  }
}
