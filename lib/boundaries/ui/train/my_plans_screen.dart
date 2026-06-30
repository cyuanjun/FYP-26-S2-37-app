import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../controls/generate_plan.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../entities/fitness_plan.dart';
import '../profile/fitness_goals_screen.dart';
import 'plan_detail_screen.dart';

/// BOUNDARY — saved training plans. Users can inspect prior generated plans
/// and choose which one is active.
class MyPlansScreen extends ConsumerWidget {
  const MyPlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(plansProvider);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Text('MY PLANS',
            style: AppTypography.subheadline.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w700,
                letterSpacing: 2)),
      ),
      body: plansAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            Center(child: Text('Could not load plans.', style: AppTypography.subheadline)),
        data: (plans) {
          if (plans.isEmpty) {
            return _EmptyPlans(
              onSetGoal: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const FitnessGoalsScreen()),
              ),
            );
          }

          final active = plans.where((p) => p.isActive).toList();
          final inactive = plans.where((p) => !p.isActive).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              if (active.isNotEmpty) ...[
                const _SectionLabel('ACTIVE'),
                const SizedBox(height: 8),
                for (final plan in active) _PlanCard(plan: plan),
                const SizedBox(height: 22),
              ],
              if (inactive.isNotEmpty) ...[
                const _SectionLabel('SAVED'),
                const SizedBox(height: 8),
                for (final plan in inactive) ...[
                  _PlanCard(plan: plan),
                  const SizedBox(height: 10),
                ],
              ],
            ],
          );
        },
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(text, style: AppTypography.caption2);
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan});

  final FitnessPlan plan;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => PlanDetailScreen(planId: plan.id),
        )),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: plan.isActive
                  ? AppColors.success.withValues(alpha: 0.6)
                  : AppColors.faint,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: Text(plan.name, style: AppTypography.headline)),
                  if (plan.isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('ACTIVE',
                          style: AppTypography.caption2.copyWith(
                              color: AppColors.success, fontWeight: FontWeight.w800)),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${plan.durationWeeks} weeks · ${plan.workoutsPerWeek}x/week · '
                '${plan.isPersonalised ? 'Personalised' : 'Basic'}',
                style: AppTypography.caption1,
              ),
              if (plan.startedAt != null) ...[
                const SizedBox(height: 6),
                Text('Started ${_dateLabel(plan.startedAt!)}',
                    style: AppTypography.caption2.copyWith(color: AppColors.muted)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _dateLabel(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _EmptyPlans extends StatelessWidget {
  const _EmptyPlans({required this.onSetGoal});

  final VoidCallback onSetGoal;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('No saved plans yet', style: AppTypography.title3),
            const SizedBox(height: 8),
            Text('Set a goal to generate your first AI training plan.',
                textAlign: TextAlign.center, style: AppTypography.subheadline),
            const SizedBox(height: 18),
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
      ),
    );
  }
}
