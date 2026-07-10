import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../controls/authenticate.dart';
import '../../../controls/set_fitness_goal.dart';
import '../../../controls/view_profile.dart';
import '../../../core/format.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../entities/enums.dart';
import '../../../entities/fitness_goal.dart';
import '../common/app_card.dart';
import 'profile_widgets.dart';

// (#) Fitness goals screen. Pick a primary goal, set the target, weekly days
// and timeline, then SAVE GOAL stores the one active goal through the
// SetFitnessGoal control.
class FitnessGoalsScreen extends ConsumerStatefulWidget {
  const FitnessGoalsScreen({super.key});

  // (#) Creates the state that holds the goal being edited.
  @override
  ConsumerState<FitnessGoalsScreen> createState() => _FitnessGoalsScreenState();
}

// (#) Live state: the chosen goal and its target, weekly days and timeline.
class _FitnessGoalsScreenState extends ConsumerState<FitnessGoalsScreen> {
  bool _seeded = false; // (#) so we only copy the saved goal into the form once
  PrimaryGoal _goal = PrimaryGoal.maintainFitness; // (#) currently selected goal
  double? _target; // (#) the target value (weight or minutes) for the goal
  int _weeklyDays = 3; // (#) how many days a week they plan to train
  int _timelineWeeks = 12; // (#) how many weeks to hit the goal in

  // (#) Copies an existing saved goal into the form fields, once, or falls back
  // to a sensible default target.
  void _seed(FitnessGoal? existing, double? weightKg) {
    if (_seeded) return;
    _seeded = true;
    if (existing != null) {
      _goal = existing.primaryGoal;
      _target = existing.targetValue ??
          FitnessGoal.defaultTargetFor(_goal, currentWeightKg: weightKg);
      _weeklyDays = existing.weeklyCommitmentDays ?? 3;
      _timelineWeeks = existing.timelineWeeks ?? 12;
    } else {
      _target = FitnessGoal.defaultTargetFor(_goal, currentWeightKg: weightKg);
    }
  }

  // (#) Switches the active goal and resets the target to that goal's default.
  void _selectGoal(PrimaryGoal g, double? weightKg) {
    setState(() {
      _goal = g;
      // Stale cross-unit targets mislead — reset on goal change.
      _target = FitnessGoal.defaultTargetFor(g, currentWeightKg: weightKg);
    });
  }

  // (#) Sends the goal to the control, then shows a snackbar and pops on success.
  Future<void> _save(double? weightKg) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    final ok = await ref.read(setFitnessGoalProvider.notifier).save(
          userId: userId,
          primaryGoal: _goal,
          targetValue: _target,
          startingValue: weightKg,
          timelineWeeks: _timelineWeeks,
          weeklyCommitmentDays: _weeklyDays,
        );
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Goal saved.')));
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Could not save goal.')));
    }
  }

  // (#) Builds the screen: goal cards, target stepper, weekly-days stepper,
  // timeline chips and the save button.
  @override
  Widget build(BuildContext context) {
    final goalAsync = ref.watch(activeGoalProvider);
    final weightKg = ref.watch(fitnessProfileProvider).value?.weightKg;
    final saving = ref.watch(setFitnessGoalProvider).isLoading;
    final unit = FitnessGoal.unitFor(_goal);
    final hasTarget = _goal != PrimaryGoal.maintainFitness;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: const Text('FITNESS GOALS',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.ink)),
      ),
      body: goalAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            Center(child: Text('Could not load goal.', style: AppTypography.subheadline)),
        data: (existing) {
          _seed(existing, weightKg);
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              const SectionLabel(label: 'Primary Goal'),
              const SizedBox(height: 8),
              for (final g in PrimaryGoal.values) ...[
                _GoalCard(
                  goal: g,
                  selected: _goal == g,
                  onTap: () => _selectGoal(g, weightKg),
                ),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 14),

              if (hasTarget) ...[
                const SectionLabel(label: 'Goal Target'),
                const SizedBox(height: 8),
                _Stepper(
                  value: _target ?? 0,
                  unit: unit == TargetUnit.minutes ? 'MINS' : 'KG',
                  subtitle: switch (_goal) {
                    PrimaryGoal.loseWeight when weightKg != null =>
                      '${(_target! - weightKg).toStringAsFixed(0)} kg from current weight',
                    PrimaryGoal.buildMuscle when weightKg != null =>
                      '+${(_target! - weightKg).toStringAsFixed(0)} kg lean mass',
                    PrimaryGoal.improveEndurance => 'Sustained activity',
                    _ => '',
                  },
                  onMinus: () => setState(
                      () => _target = (_target ?? 0) - FitnessGoal.stepFor(unit!)),
                  onPlus: () => setState(
                      () => _target = (_target ?? 0) + FitnessGoal.stepFor(unit!)),
                ),
                const SizedBox(height: 24),
              ],

              const SectionLabel(label: 'Weekly Commitment'),
              const SizedBox(height: 8),
              _Stepper(
                value: _weeklyDays.toDouble(),
                unit: 'DAYS',
                subtitle: 'per week',
                onMinus: () =>
                    setState(() => _weeklyDays = (_weeklyDays - 1).clamp(1, 7)),
                onPlus: () =>
                    setState(() => _weeklyDays = (_weeklyDays + 1).clamp(1, 7)),
              ),
              const SizedBox(height: 24),

              if (hasTarget) ...[
                const SectionLabel(label: 'Timeline (weeks)'),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (final w in FitnessGoal.timelineOptions)
                      GestureDetector(
                        onTap: () => setState(() => _timelineWeeks = w),
                        child: Container(
                          width: 48,
                          height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _timelineWeeks == w
                                ? AppColors.accent
                                : Colors.transparent,
                            border: Border.all(
                                color: _timelineWeeks == w
                                    ? AppColors.accent
                                    : AppColors.faint),
                          ),
                          child: Text('$w',
                              style: AppTypography.headline.copyWith(
                                  color: _timelineWeeks == w
                                      ? AppColors.bg
                                      : AppColors.muted)),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
              ],

              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: saving ? null : () => _save(weightKg),
                child: saving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.bg))
                    : const Text('SAVE GOAL'),
              ),
            ],
          );
        },
      ),
    );
  }
}

// (#) A tappable card for one goal option, with a tick when it's selected.
class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.goal, required this.selected, required this.onTap});

  final PrimaryGoal goal; // (#) the goal this card represents
  final bool selected; // (#) whether this is the chosen goal
  final VoidCallback onTap; // (#) called when the card is tapped

  // (#) Builds the card: label, descriptor and a check circle when selected.
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AppCard(
        borderColor: selected ? AppColors.accent : AppColors.faint,
        borderWidth: selected ? 1.5 : 1,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(goal.label,
                      style: AppTypography.body.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(goal.descriptor, style: AppTypography.footnote),
                ],
              ),
            ),
            if (selected)
              Container(
                width: 28,
                height: 28,
                decoration:
                    const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                child: const Icon(Icons.check, size: 18, color: AppColors.bg),
              ),
          ],
        ),
      ),
    );
  }
}

// (#) A big minus/value/plus stepper for a numeric field like target or days.
class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.value,
    required this.unit,
    required this.subtitle,
    required this.onMinus,
    required this.onPlus,
  });

  final double value; // (#) the number to show in the middle
  final String unit; // (#) unit label shown after the number, like KG or MINS
  final String subtitle; // (#) small helper line under the number
  final VoidCallback onMinus; // (#) called when the minus button is tapped
  final VoidCallback onPlus; // (#) called when the plus button is tapped

  // (#) Builds the row: minus button, value with unit and subtitle, plus button.
  @override
  Widget build(BuildContext context) {
    final display = fmtCompactNum(value);
    return AppCard(
      child: Row(
        children: [
          _btn(Icons.remove, onMinus),
          Expanded(
            child: Column(
              children: [
                Text('$display $unit',
                    style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: AppColors.metricColor(unit))),
                if (subtitle.isNotEmpty)
                  Text(subtitle, style: AppTypography.caption1),
              ],
            ),
          ),
          _btn(Icons.add, onPlus),
        ],
      ),
    );
  }

  // (#) One rounded square icon button used for the minus and plus.
  Widget _btn(IconData icon, VoidCallback onTap) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
              color: AppColors.surface2, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: AppColors.ink),
        ),
      );
}
