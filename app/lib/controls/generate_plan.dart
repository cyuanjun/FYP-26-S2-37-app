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

// (#) One planned workout in a draft plan, before it is saved to the DB.
class PlannedSlot {
  const PlannedSlot({
    required this.slug,
    required this.week,
    required this.dayOfWeek,
    required this.durationMinutes,
    required this.name,
    required this.descriptor,
  });

  final String slug; // (#) which workout type, e.g. running
  final int week; // (#) which week in the timeline, 1..durationWeeks
  final int dayOfWeek; // (#) day of the week, 1=Mon .. 7=Sun
  final int durationMinutes; // (#) how long this session should run
  final String name; // (#) short label shown on the plan
  final String descriptor; // (#) one-line coaching note for the session
}

// (#) A whole drafted plan (title, length, and every slot) before it is saved.
class PlanDraft {
  const PlanDraft({
    required this.name,
    required this.description,
    required this.durationWeeks,
    required this.workoutsPerWeek,
    required this.strategy,
    required this.slots,
  });

  final String name; // (#) plan title
  final String description; // (#) plan summary line
  final int durationWeeks; // (#) total weeks the plan spans
  final int workoutsPerWeek; // (#) sessions scheduled each week
  final GenerationStrategy strategy; // (#) basic (rule) or personalised (AI)
  final List<PlannedSlot> slots; // (#) every scheduled workout across the timeline
}

// (#) Which weekdays to use for n workouts a week (1=Mon .. 7=Sun); kept in step
// (#) with the Edge Function so the app and server schedule days the same way.
const _daySpread = <int, List<int>>{
  1: [3], 2: [2, 5], 3: [1, 3, 5], 4: [1, 3, 5, 6],
  5: [1, 2, 4, 5, 6], 6: [1, 2, 3, 4, 5, 6], 7: [1, 2, 3, 4, 5, 6, 7],
};

// (#) The rule-based plan builder, used offline or when the AI is down. It makes
// (#) a fixed, repeatable plan from the goal, experience and preferences. If the
// (#) user gave preferred types, only those get scheduled. No network needed.
PlanDraft buildPlanSkeleton({
  required PrimaryGoal goal,
  TrainingExperience? experience,
  List<String> preferredSlugs = const [],
  int? weeklyCommitmentDays,
  int? timelineWeeks,
}) {
  final days = (weeklyCommitmentDays ?? 3).clamp(1, 7);
  final weeks = (timelineWeeks ?? 4).clamp(1, 52).toInt();
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
  final rotation =
      preferredSlugs.isNotEmpty ? preferredSlugs.toSet().toList() : fillers;
  final title = switch (goal) {
    PrimaryGoal.loseWeight => 'Lean & Consistent',
    PrimaryGoal.buildMuscle => 'Progressive Strength',
    PrimaryGoal.improveEndurance => 'Endurance Builder',
    PrimaryGoal.maintainFitness => 'Balanced Week',
  };

  final slots = <PlannedSlot>[];
  final spread = _daySpread[days]!;
  for (var wk = 1; wk <= weeks; wk++) {
    final phase = _timelinePhase(wk, weeks);
    final bump = _weekBump(wk, weeks, phase);
    for (var i = 0; i < spread.length; i++) {
      final slug = rotation[i % rotation.length];
      final hard = i % 3 == 2;
      slots.add(PlannedSlot(
        slug: slug,
        week: wk,
        dayOfWeek: spread[i],
        durationMinutes:
            ((hard ? base + 10 : base) + bump).clamp(15, 120),
        name: '${slug[0].toUpperCase()}${slug.substring(1)} ${hard ? 'push' : 'base'}',
        descriptor: phase == _PlanPhase.recovery
            ? 'Recovery week — keep it comfortable'
            : hard ? 'Slightly harder effort — finish strong' : 'Comfortable, repeatable effort',
      ));
    }
  }

  return PlanDraft(
    name: '$title — $weeks-week plan',
    description: 'A $days-day week across your full $weeks-week timeline '
        'toward your ${goal.label.toLowerCase()} goal.',
    durationWeeks: weeks,
    workoutsPerWeek: days,
    strategy: GenerationStrategy.basic,
    slots: slots,
  );
}

// (#) The four stages a plan moves through as the weeks progress.
enum _PlanPhase { foundation, build, peak, recovery }

// (#) Works out which phase a given week falls in: last week is recovery, the
// (#) rest split into foundation, build and peak by how far through you are.
_PlanPhase _timelinePhase(int week, int totalWeeks) {
  if (week == totalWeeks && totalWeeks > 1) return _PlanPhase.recovery;
  final progress = week / totalWeeks;
  if (progress <= 0.25) return _PlanPhase.foundation;
  if (progress <= 0.75) return _PlanPhase.build;
  return _PlanPhase.peak;
}

// (#) Extra minutes to add for a week: ramps up through build and peak, drops a
// (#) little on the recovery week, so effort climbs then eases.
int _weekBump(int week, int totalWeeks, _PlanPhase phase) {
  if (phase == _PlanPhase.recovery) return -5;
  final ramp = totalWeeks <= 1 ? 0 : ((week - 1) / (totalWeeks - 1) * 15).round();
  return switch (phase) {
    _PlanPhase.foundation => ramp.clamp(0, 5).toInt(),
    _PlanPhase.build => ramp.clamp(5, 12).toInt(),
    _PlanPhase.peak => ramp.clamp(10, 18).toInt(),
    _PlanPhase.recovery => -5,
  };
}

// (#) The user's currently active plan, shown on the Train card; null if none.
final activePlanProvider = FutureProvider<FitnessPlan?>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Future.value(null);
  return ref.watch(planGatewayProvider).fetchActivePlan(userId);
});

// (#) The scheduled workouts of the active plan.
final plannedWorkoutsProvider = FutureProvider<List<PlannedWorkout>>((ref) async {
  final plan = await ref.watch(activePlanProvider.future);
  if (plan == null) return const <PlannedWorkout>[];
  return ref.watch(planGatewayProvider).listPlannedWorkouts(plan.id);
});

// (#) Every plan the user has saved, for the plans list.
final plansProvider = FutureProvider<List<FitnessPlan>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Future.value(const <FitnessPlan>[]);
  return ref.watch(planGatewayProvider).listPlans(userId);
});

// (#) One plan by id, for the plan detail screen.
final planByIdProvider = FutureProvider.family<FitnessPlan?, String>((ref, planId) {
  return ref.watch(planGatewayProvider).fetchPlan(planId);
});

// (#) The scheduled workouts of any plan by id.
final plannedWorkoutsForPlanProvider =
    FutureProvider.family<List<PlannedWorkout>, String>((ref, planId) {
  return ref.watch(planGatewayProvider).listPlannedWorkouts(planId);
});

// (#) Builds a training plan for the user. It asks the AI gateway for a suggestion
// (#) (Free gets basic depth, Premium personalised), falls back to the rule-based
// (#) skeleton if the AI fails, then saves the plan plus its weekly workouts and
// (#) refreshes the plan providers. Loading and errors show through its AsyncValue.
class GeneratePlan extends AsyncNotifier<void> {
  // (#) Nothing to load up front; sits idle until generate() is called.
  @override
  Future<void> build() async {}

  // (#) Runs the whole generate flow and returns the created plan, or null on error.
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

      // Regenerating (an active plan exists) carries the counter forward —
      // Plan Detail gates Free users at 1 regeneration (#8 spec).
      final prior = await ref.read(planGatewayProvider).fetchActivePlan(userId);

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
          'regenerated_count': prior == null ? 0 : prior.regeneratedCount + 1,
        },
        workouts: [
          for (var i = 0; i < draft.slots.length; i++)
            if (bySlug.containsKey(draft.slots[i].slug))
              {
                'workout_type_id': bySlug[draft.slots[i].slug]!.id,
                'week_number': draft.slots[i].week,
                'day_of_week': draft.slots[i].dayOfWeek,
                'duration_minutes': draft.slots[i].durationMinutes,
                'name': draft.slots[i].name,
                'descriptor': draft.slots[i].descriptor,
                'order_index': i,
              },
        ],
      );
      ref.invalidate(activePlanProvider);
      ref.invalidate(plannedWorkoutsProvider);
      ref.invalidate(plansProvider);
    });
    return state.hasError ? null : created;
  }

  // (#) Small wrapper that feeds the goal's settings into buildPlanSkeleton.
  PlanDraft _skeleton(FitnessGoal goal, TrainingExperience? exp, List<String> slugs) =>
      buildPlanSkeleton(
        goal: goal.primaryGoal,
        experience: exp,
        preferredSlugs: slugs,
        weeklyCommitmentDays: goal.weeklyCommitmentDays,
        timelineWeeks: goal.timelineWeeks,
      );

  // (#) Turns the AI gateway's raw JSON into a PlanDraft, clamping odd values and
  // (#) throwing if it came back with no workouts (so the fallback can kick in).
  PlanDraft _draftFromAi(Map<String, dynamic> data) {
    final durationWeeks = ((data['duration_weeks'] as num?)?.toInt() ?? 4).clamp(1, 52).toInt();
    final workouts = (data['workouts'] as List? ?? const [])
        .whereType<Map>()
        .map((w) => PlannedSlot(
              slug: w['slug'] as String? ?? 'running',
              week: ((w['week_number'] as num?)?.toInt() ?? 1).clamp(1, durationWeeks),
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
      durationWeeks: durationWeeks,
      workoutsPerWeek: (data['workouts_per_week'] as num?)?.toInt() ?? workouts.length,
      strategy: data['strategy'] == 'personalised'
          ? GenerationStrategy.personalised
          : GenerationStrategy.basic,
      slots: workouts,
    );
  }
}

// (#) Hands the onboarding and plan screens the GeneratePlan control.
final generatePlanProvider = AsyncNotifierProvider<GeneratePlan, void>(GeneratePlan.new);

// (#) Switches which saved plan is the active one. Tells the gateway to set it
// (#) current and refreshes the plan providers the Train card reads.
class SelectFitnessPlan extends AsyncNotifier<void> {
  // (#) Nothing to load up front; idle until select() is called.
  @override
  Future<void> build() async {}

  // (#) Makes the given plan active; returns true on success, false on error.
  Future<bool> select(String planId) async {
    SeqLog.msg('select-plan', 'PlanDetailScreen', 'SelectFitnessPlan', 'select($planId)');
    state = const AsyncLoading();
    var ok = false;
    state = await AsyncValue.guard(() async {
      final userId = ref.read(currentUserIdProvider);
      if (userId == null) throw StateError('Not signed in');
      SeqLog.msg('select-plan', 'SelectFitnessPlan', 'PlanGateway', 'setActivePlan');
      await ref
          .read(planGatewayProvider)
          .setActivePlan(userId: userId, planId: planId);
      ref.invalidate(activePlanProvider);
      ref.invalidate(plannedWorkoutsProvider);
      ref.invalidate(plansProvider);
      ref.invalidate(planByIdProvider(planId));
      ref.invalidate(plannedWorkoutsForPlanProvider(planId));
      ok = true;
    });
    return ok;
  }
}

// (#) Hands the plan detail screen the SelectFitnessPlan control.
final selectFitnessPlanProvider =
    AsyncNotifierProvider<SelectFitnessPlan, void>(SelectFitnessPlan.new);

// (#) Marks the onboarding wizard finished. Stamps the profile through the gateway
// (#) so Splash and Login stop sending the user back into setup.
class CompleteOnboarding {
  CompleteOnboarding(this._ref);

  final Ref _ref; // (#) Riverpod handle for reading the gateway and user id

  // (#) Records that onboarding is done for the signed-in user.
  Future<void> call() async {
    final userId = _ref.read(currentUserIdProvider);
    if (userId == null) return;
    SeqLog.msg('onboarding', 'OnboardingFlow', 'CompleteOnboarding', 'complete()');
    await _ref.read(profileGatewayProvider).completeOnboarding(userId);
    _ref.invalidate(currentProfileProvider);
  }
}

// (#) Hands the onboarding flow the CompleteOnboarding control.
final completeOnboardingProvider = Provider<CompleteOnboarding>(CompleteOnboarding.new);
