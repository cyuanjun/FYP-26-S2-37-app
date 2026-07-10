import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wise_workout/boundaries/gateways/ai_gateway.dart';
import 'package:wise_workout/boundaries/gateways/fitness_gateway.dart';
import 'package:wise_workout/boundaries/gateways/plan_gateway.dart';
import 'package:wise_workout/boundaries/gateways/profile_gateway.dart';
import 'package:wise_workout/boundaries/gateways/workout_gateway.dart';
import 'package:wise_workout/controls/authenticate.dart';
import 'package:wise_workout/controls/generate_plan.dart';
import 'package:wise_workout/entities/enums.dart';
import 'package:wise_workout/entities/fitness_goal.dart';
import 'package:wise_workout/entities/fitness_plan.dart';
import 'package:wise_workout/entities/profile.dart';

import '../helpers/fakes.dart';

// (#) Tests plan generation: the pure rule-based skeleton builder, the GeneratePlan
// (#) control (AI vs fallback, Free vs Premium), saved plans, and onboarding gates.
void main() {
  // ---- BuildPlanSkeleton (pure rule) ----
  // (#) The offline rule-based plan skeleton builder.
  group('buildPlanSkeleton rule', () {
    // (#) (+) Check if it honours the commitment days and lays out the full week-by-week timeline.
    test('honours commitment days and generates the full timeline (positive)', () {
      final d = buildPlanSkeleton(
        goal: PrimaryGoal.loseWeight,
        experience: TrainingExperience.intermediate,
        weeklyCommitmentDays: 4,
        timelineWeeks: 12,
      );
      expect(d.workoutsPerWeek, 4);
      expect(d.durationWeeks, 12);
      expect(d.slots, hasLength(48)); // 4 days x 12 weeks
      expect(d.strategy, GenerationStrategy.basic);
      final week1 = d.slots.where((s) => s.week == 1).toList();
      expect(week1.map((s) => s.dayOfWeek), [1, 3, 5, 6]); // spread, no clumping
      expect(d.slots.map((s) => s.week).toSet(), equals({for (var wk = 1; wk <= 12; wk++) wk}));
    });

    // (#) (+) Check if only the user's preferred workout types get scheduled.
    test('preferences are a contract — only preferred types scheduled', () {
      final d = buildPlanSkeleton(
        goal: PrimaryGoal.maintainFitness,
        preferredSlugs: ['yoga'],
        weeklyCommitmentDays: 3,
      );
      expect(d.slots.map((s) => s.slug).toSet(), {'yoga'});
    });

    // (#) (+) Check if higher experience gives longer session durations.
    test('experience scales duration (beginner < advanced)', () {
      final beginner = buildPlanSkeleton(
          goal: PrimaryGoal.buildMuscle, experience: TrainingExperience.beginner);
      final advanced = buildPlanSkeleton(
          goal: PrimaryGoal.buildMuscle, experience: TrainingExperience.advanced);
      expect(beginner.slots.first.durationMinutes,
          lessThan(advanced.slots.first.durationMinutes));
    });

    // (#) (+) Check if week 4 is a lighter recovery week than week 3.
    test('week 4 is a recovery week (lighter than week 3)', () {
      final d = buildPlanSkeleton(goal: PrimaryGoal.improveEndurance);
      final w3 = d.slots.firstWhere((s) => s.week == 3);
      final w4 = d.slots.firstWhere((s) => s.week == 4);
      expect(w4.durationMinutes, lessThan(w3.durationMinutes));
    });

    // (#) (-) Check if out-of-range commitment days clamp to the 1 to 7 range.
    test('commitment days clamp to 1–7 (negative input)', () {
      expect(buildPlanSkeleton(goal: PrimaryGoal.loseWeight, weeklyCommitmentDays: 99)
          .workoutsPerWeek, 7);
      expect(buildPlanSkeleton(goal: PrimaryGoal.loseWeight, weeklyCommitmentDays: 0)
          .workoutsPerWeek, 1);
    });
  });

  // ---- GeneratePlan control ----
  // (#) The GeneratePlan control that calls AI and persists a plan.
  group('GeneratePlan', () {
    const goal = FitnessGoal(
      id: 'g1',
      userId: 'u1',
      primaryGoal: PrimaryGoal.loseWeight,
      weeklyCommitmentDays: 3,
      timelineWeeks: 8,
    );

    // (#) Builds a container for the given role wired to fake AI/plan/fitness gateways.
    ProviderContainer makeContainer({
      required UserRole role,
      FitnessGoal? activeGoal = goal,
      FakeAiGateway? ai,
      FakePlanGateway? plans,
    }) {
      final c = ProviderContainer(overrides: [
        currentUserIdProvider.overrideWithValue('u1'),
        currentProfileProvider.overrideWith(
            (ref) async => Profile(id: 'u1', email: 'x@test', role: role)),
        fitnessGatewayProvider.overrideWithValue(FakeFitnessGateway(activeGoal: activeGoal)),
        workoutGatewayProvider
            .overrideWithValue(FakeWorkoutGateway(types: [runningType, yogaType])),
        planGatewayProvider.overrideWithValue(plans ?? FakePlanGateway()),
        aiGatewayProvider.overrideWithValue(ai ?? FakeAiGateway()),
        profileGatewayProvider.overrideWithValue(FakeProfileGateway()),
      ]);
      addTearDown(c.dispose);
      return c;
    }

    // (#) (+) Check if a Free user gets a basic AI plan persisted with workouts.
    test('free user → basic AI plan persisted (positive)', () async {
      final plans = FakePlanGateway();
      final ai = FakeAiGateway()..planResult['strategy'] = 'basic';
      final c = makeContainer(role: UserRole.free, plans: plans, ai: ai);
      final plan = await c.read(generatePlanProvider.notifier).generate();
      expect(plan, isNotNull);
      expect(ai.planCalls, 1); // Free uses AI too (basic depth) — WBS/SRS
      expect(plans.insertedPlans.single['generation_strategy'], 'basic');
      expect(plans.insertedWorkouts.single, isNotEmpty);
    });

    // (#) (+) Check if a Premium user gets an AI-personalised plan.
    test('premium user → AI-personalised plan (positive)', () async {
      final plans = FakePlanGateway();
      final ai = FakeAiGateway()..planResult['strategy'] = 'personalised';
      final c = makeContainer(role: UserRole.premium, plans: plans, ai: ai);
      final plan = await c.read(generatePlanProvider.notifier).generate();
      expect(plan, isNotNull);
      expect(ai.planCalls, 1);
      expect(plans.insertedPlans.single['generation_strategy'], 'personalised');
    });

    // (#) (+) Check if, when AI throws, the rule-based fallback still delivers a basic plan for both roles.
    test('AI down → rule-based fallback still delivers a plan (resilience)', () async {
      for (final role in [UserRole.free, UserRole.premium]) {
        final plans = FakePlanGateway();
        final ai = FakeAiGateway(throwOnCall: true);
        final c = makeContainer(role: role, plans: plans, ai: ai);
        final plan = await c.read(generatePlanProvider.notifier).generate();
        expect(plan, isNotNull);
        expect(plans.insertedPlans.single['generation_strategy'], 'basic');
      }
    });

    // (#) (-) Check if generating with no active goal errors and persists nothing.
    test('no active goal → error, nothing persisted (negative)', () async {
      final plans = FakePlanGateway();
      final c = makeContainer(role: UserRole.free, activeGoal: null, plans: plans);
      final plan = await c.read(generatePlanProvider.notifier).generate();
      expect(plan, isNull);
      expect(c.read(generatePlanProvider).hasError, isTrue);
      expect(plans.insertedPlans, isEmpty);
    });
  });

  // ---- My Plans / SelectFitnessPlan ----
  // (#) Listing saved plans and activating one.
  group('Saved plans', () {
    // (#) (+) Check if plansProvider lists only the signed-in user's plans, active first.
    test('plansProvider lists the signed-in user plans', () async {
      final gw = FakePlanGateway()
        ..activePlan = FitnessPlan(
          id: 'p1',
          userId: 'u1',
          fitnessGoalId: 'g1',
          name: 'Active',
          durationWeeks: 8,
          workoutsPerWeek: 3,
        )
        ..plans = const [
          FitnessPlan(
            id: 'p2',
            userId: 'u1',
            fitnessGoalId: 'g1',
            name: 'Saved',
            durationWeeks: 12,
            workoutsPerWeek: 4,
            isActive: false,
          ),
          FitnessPlan(
            id: 'other',
            userId: 'u2',
            fitnessGoalId: 'g2',
            name: 'Other user',
            durationWeeks: 4,
            workoutsPerWeek: 2,
            isActive: false,
          ),
        ];
      final c = ProviderContainer(overrides: [
        currentUserIdProvider.overrideWithValue('u1'),
        planGatewayProvider.overrideWithValue(gw),
      ]);
      addTearDown(c.dispose);

      final plans = await c.read(plansProvider.future);
      expect(plans.map((p) => p.id), ['p1', 'p2']);
    });

    // (#) (+) Check if selecting a saved plan makes it active and deactivates the old one.
    test('SelectFitnessPlan activates a saved plan', () async {
      final gw = FakePlanGateway()
        ..activePlan = FitnessPlan(
          id: 'p1',
          userId: 'u1',
          fitnessGoalId: 'g1',
          name: 'Active',
          durationWeeks: 8,
          workoutsPerWeek: 3,
        )
        ..plans = const [
          FitnessPlan(
            id: 'p2',
            userId: 'u1',
            fitnessGoalId: 'g1',
            name: 'Saved',
            durationWeeks: 12,
            workoutsPerWeek: 4,
            isActive: false,
          ),
        ];
      final c = ProviderContainer(overrides: [
        currentUserIdProvider.overrideWithValue('u1'),
        planGatewayProvider.overrideWithValue(gw),
      ]);
      addTearDown(c.dispose);

      final ok = await c.read(selectFitnessPlanProvider.notifier).select('p2');
      expect(ok, isTrue);
      expect(gw.selectedPlanIds, ['p2']);
      expect(gw.activePlan?.id, 'p2');
      expect(gw.activePlan?.isActive, isTrue);
      expect(gw.plans.single.id, 'p1');
      expect(gw.plans.single.isActive, isFalse);
    });
  });

  // ---- CompleteOnboarding ----
  // (#) The control that marks onboarding finished.
  group('CompleteOnboarding', () {
    // (#) (+) Check if it marks onboarding complete for the signed-in user.
    test('marks onboarding done for the signed-in user (positive)', () async {
      final gw = FakeProfileGateway();
      final c = ProviderContainer(overrides: [
        currentUserIdProvider.overrideWithValue('u1'),
        profileGatewayProvider.overrideWithValue(gw),
      ]);
      addTearDown(c.dispose);
      await c.read(completeOnboardingProvider).call();
      expect(gw.onboardingCompletions, ['u1']);
    });

    // (#) (-) Check if it does nothing when signed out.
    test('no-op when signed out (negative)', () async {
      final gw = FakeProfileGateway();
      final c = ProviderContainer(overrides: [
        currentUserIdProvider.overrideWithValue(null),
        profileGatewayProvider.overrideWithValue(gw),
      ]);
      addTearDown(c.dispose);
      await c.read(completeOnboardingProvider).call();
      expect(gw.onboardingCompletions, isEmpty);
    });
  });

  // ---- Onboarding gate rule ----
  // (#) The Profile entity rule deciding if onboarding is still needed.
  group('Profile.needsOnboarding', () {
    // (#) (+) Check if a null completion timestamp means the wizard is still required.
    test('null onboardingCompletedAt → wizard required', () {
      const p = Profile(id: 'u', email: 'x@test', role: UserRole.free);
      expect(p.needsOnboarding, isTrue);
    });

    // (#) (-) Check if a set completion timestamp means onboarding is not needed.
    test('completed → straight to the shell', () {
      final p = Profile(
          id: 'u',
          email: 'x@test',
          role: UserRole.free,
          onboardingCompletedAt: DateTime(2026, 6, 12));
      expect(p.needsOnboarding, isFalse);
    });
  });
}
