import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../boundaries/gateways/ai_gateway.dart';
import '../boundaries/gateways/fitness_gateway.dart';
import '../boundaries/gateways/plan_gateway.dart';
import '../boundaries/gateways/profile_gateway.dart';
import '../boundaries/gateways/workout_gateway.dart';
import '../core/seq_log.dart';
import '../entities/enums.dart';
import '../entities/fitness_goal.dart';
import '../entities/fitness_plan.dart';
import '../entities/planned_workout.dart';
import 'authenticate.dart';
import 'view_profile.dart';

/// One scheduled slot in a drafted weekly template (pre-persistence).
class PlannedSlot {
  const PlannedSlot({
    required this.slug,
    required this.dayOfWeek,
    required this.durationMinutes,
    required this.name,
    required this.descriptor,
  });

  final String slug;
  final int dayOfWeek;
  final int durationMinutes;
  final String name;
  final String descriptor;
}

class PlanDraft {
  const PlanDraft({
    required this.name,
    required this.description,
    required this.durationWeeks,
    required this.workoutsPerWeek,
    required this.strategy,
    required this.slots,
  });

  final String name;
  final String description;
  final int durationWeeks;
  final int workoutsPerWeek;
  final GenerationStrategy strategy;
  final List<PlannedSlot> slots;
}

/// Day spread for n workouts/week (1=Mon … 7=Sun) — matches the Edge Function.
const _daySpread = <int, List<int>>{
  1: [3], 2: [2, 5], 3: [1, 3, 5], 4: [1, 3, 5, 6],
  5: [1, 2, 4, 5, 6], 6: [1, 2, 3, 4, 5, 6], 7: [1, 2, 3, 4, 5, 6, 7],
};

/// CONTROL (rule-based) — BuildPlanSkeleton. The basic plan for all tiers:
/// deterministic weekly template from the goal + experience + preferences.
/// No AI involved (build-plan §5).
PlanDraft buildPlanSkeleton({
  required PrimaryGoal goal,
  TrainingExperience? experience,
  List<String> preferredSlugs = const [],
  int? weeklyCommitmentDays,
  int? timelineWeeks,
}) {
  final days = (weeklyCommitmentDays ?? 3).clamp(1, 7);
  final weeks = timelineWeeks ?? 4;
  final base = switch (experience) {
    TrainingExperience.advanced => 50,
    TrainingExperience.intermediate => 40,
    _ => 30,
  };
  final fillers = switch (goal) {
    PrimaryGoal.loseWeight => ['running', 'cycling', 'hiit'],
    PrimaryGoal.buildMuscle => ['strength', 'strength', 'hiit'],
    PrimaryGoal.improveEndurance => ['running', 'cycling', 'rowing'],
    PrimaryGoal.maintainFitness => ['running', 'strength', 'yoga'],
  };
  final rotation = {...preferredSlugs, ...fillers}.toList();
  final title = switch (goal) {
    PrimaryGoal.loseWeight => 'Lean & Consistent',
    PrimaryGoal.buildMuscle => 'Progressive Strength',
    PrimaryGoal.improveEndurance => 'Endurance Builder',
    PrimaryGoal.maintainFitness => 'Balanced Week',
  };

  final slots = <PlannedSlot>[];
  final spread = _daySpread[days]!;
  for (var i = 0; i < spread.length; i++) {
    final slug = rotation[i % rotation.length];
    final hard = i % 3 == 2;
    slots.add(PlannedSlot(
      slug: slug,
      dayOfWeek: spread[i],
      durationMinutes: hard ? base + 10 : base,
      name: '${slug[0].toUpperCase()}${slug.substring(1)} ${hard ? 'push' : 'base'}',
      descriptor: hard ? 'Slightly harder effort — finish strong' : 'Comfortable, repeatable effort',
    ));
  }

  return PlanDraft(
    name: '$title — $weeks-week plan',
    description: 'A simple $days-day week, repeating for $weeks weeks '
        'toward your ${goal.label.toLowerCase()} goal.',
    durationWeeks: weeks,
    workoutsPerWeek: days,
    strategy: GenerationStrategy.basic,
    slots: slots,
  );
}

/// The user's active plan (Train card) and its weekly template.
final activePlanProvider = FutureProvider<FitnessPlan?>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Future.value(null);
  return ref.watch(planGatewayProvider).fetchActivePlan(userId);
});

final plannedWorkoutsProvider = FutureProvider<List<PlannedWorkout>>((ref) async {
  final plan = await ref.watch(activePlanProvider.future);
  if (plan == null) return const <PlannedWorkout>[];
  return ref.watch(planGatewayProvider).listPlannedWorkouts(plan.id);
});

/// CONTROL — GeneratePlan. Free tier → rule-based BuildPlanSkeleton;
/// Premium → SuggestPlan via the AiGateway (falls back to the skeleton if the
/// AI is unavailable). Persists the plan + weekly template and refreshes the
/// active-plan providers.
class GeneratePlan extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<FitnessPlan?> generate() async {
    SeqLog.msg('generate-plan', 'OnboardingFlow', 'GeneratePlan', 'generate()');
    state = const AsyncLoading();
    FitnessPlan? created;
    state = await AsyncValue.guard(() async {
      final userId = ref.read(currentUserIdProvider);
      if (userId == null) throw StateError('Not signed in');
      final goal = await ref.read(fitnessGatewayProvider).fetchActiveGoal(userId);
      if (goal == null) throw StateError('Set a fitness goal first');

      final profile = await ref.read(currentProfileProvider.future);
      final fitness = await ref.read(fitnessProfileProvider.future);
      final types = await ref.read(workoutGatewayProvider).listWorkoutTypes();
      final bySlug = {for (final t in types) t.slug: t};
      final preferredSlugs = [
        for (final t in types)
          if (fitness?.preferredWorkoutTypeIds.contains(t.id) ?? false) t.slug,
      ];

      // Both tiers use AI (decided 12 Jun, per WBS/SRS): Free = basic depth,
      // Premium = personalised — the Edge Function decides from the role.
      // BuildPlanSkeleton remains the offline/rule fallback for either tier.
      PlanDraft draft;
      SeqLog.msg('generate-plan', 'GeneratePlan', 'AiGateway',
          'suggestPlan(${(profile?.isPremium ?? false) ? 'personalised' : 'basic'})');
      try {
        draft = _draftFromAi(await ref.read(aiGatewayProvider).suggestPlan());
      } catch (_) {
        SeqLog.msg('generate-plan', 'GeneratePlan', 'BuildPlanSkeleton', 'AI down → rule fallback');
        draft = _skeleton(goal, fitness?.trainingExperience, preferredSlugs);
      }

      SeqLog.msg('generate-plan', 'GeneratePlan', 'PlanGateway', 'insertPlan');
      created = await ref.read(planGatewayProvider).insertPlan(
        userId: userId,
        fitnessGoalId: goal.id,
        plan: {
          'name': draft.name,
          'description': draft.description,
          'duration_weeks': draft.durationWeeks,
          'workouts_per_week': draft.workoutsPerWeek,
          'generation_strategy': draft.strategy.name,
        },
        workouts: [
          for (var i = 0; i < draft.slots.length; i++)
            if (bySlug.containsKey(draft.slots[i].slug))
              {
                'workout_type_id': bySlug[draft.slots[i].slug]!.id,
                'week_number': 1, // weekly template; repeats for durationWeeks
                'day_of_week': draft.slots[i].dayOfWeek,
                'duration_minutes': draft.slots[i].durationMinutes,
                'name': draft.slots[i].name,
                'descriptor': draft.slots[i].descriptor,
                'order_index': i,
              },
        ],
      );
      ref.invalidate(activePlanProvider);
    });
    return state.hasError ? null : created;
  }

  PlanDraft _skeleton(FitnessGoal goal, TrainingExperience? exp, List<String> slugs) =>
      buildPlanSkeleton(
        goal: goal.primaryGoal,
        experience: exp,
        preferredSlugs: slugs,
        weeklyCommitmentDays: goal.weeklyCommitmentDays,
        timelineWeeks: goal.timelineWeeks,
      );

  PlanDraft _draftFromAi(Map<String, dynamic> data) {
    final workouts = (data['workouts'] as List? ?? const [])
        .whereType<Map>()
        .map((w) => PlannedSlot(
              slug: w['slug'] as String? ?? 'running',
              dayOfWeek: (w['day_of_week'] as num?)?.toInt() ?? 1,
              durationMinutes: (w['duration_minutes'] as num?)?.toInt() ?? 30,
              name: w['name'] as String? ?? 'Workout',
              descriptor: w['descriptor'] as String? ?? '',
            ))
        .toList();
    if (workouts.isEmpty) throw Exception('AI returned no workouts');
    return PlanDraft(
      name: data['name'] as String? ?? 'Suggested plan',
      description: data['description'] as String? ?? '',
      durationWeeks: (data['duration_weeks'] as num?)?.toInt() ?? 4,
      workoutsPerWeek: (data['workouts_per_week'] as num?)?.toInt() ?? workouts.length,
      strategy: data['strategy'] == 'personalised'
          ? GenerationStrategy.personalised
          : GenerationStrategy.basic,
      slots: workouts,
    );
  }
}

final generatePlanProvider = AsyncNotifierProvider<GeneratePlan, void>(GeneratePlan.new);

/// CONTROL — CompleteOnboarding. Marks the wizard done; Splash/Login stop
/// routing here (profiles.onboarding_completed_at).
class CompleteOnboarding {
  CompleteOnboarding(this._ref);

  final Ref _ref;

  Future<void> call() async {
    final userId = _ref.read(currentUserIdProvider);
    if (userId == null) return;
    SeqLog.msg('onboarding', 'OnboardingFlow', 'CompleteOnboarding', 'complete()');
    await _ref.read(profileGatewayProvider).completeOnboarding(userId);
    _ref.invalidate(currentProfileProvider);
  }
}

final completeOnboardingProvider = Provider<CompleteOnboarding>(CompleteOnboarding.new);
