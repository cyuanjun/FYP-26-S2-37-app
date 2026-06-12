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
import 'package:wise_workout/entities/profile.dart';

import '../helpers/fakes.dart';

void main() {
  // ---- BuildPlanSkeleton (pure rule) ----
  group('buildPlanSkeleton rule', () {
    test('honours commitment days and timeline (positive)', () {
      final d = buildPlanSkeleton(
        goal: PrimaryGoal.loseWeight,
        experience: TrainingExperience.intermediate,
        weeklyCommitmentDays: 4,
        timelineWeeks: 12,
      );
      expect(d.workoutsPerWeek, 4);
      expect(d.durationWeeks, 12);
      expect(d.slots, hasLength(4));
      expect(d.strategy, GenerationStrategy.basic);
      expect(d.slots.map((s) => s.dayOfWeek), [1, 3, 5, 6]); // spread, no clumping
    });

    test('preferred workouts lead the rotation', () {
      final d = buildPlanSkeleton(
        goal: PrimaryGoal.maintainFitness,
        preferredSlugs: ['yoga'],
        weeklyCommitmentDays: 3,
      );
      expect(d.slots.first.slug, 'yoga');
    });

    test('experience scales duration (beginner < advanced)', () {
      final beginner = buildPlanSkeleton(
          goal: PrimaryGoal.buildMuscle, experience: TrainingExperience.beginner);
      final advanced = buildPlanSkeleton(
          goal: PrimaryGoal.buildMuscle, experience: TrainingExperience.advanced);
      expect(beginner.slots.first.durationMinutes,
          lessThan(advanced.slots.first.durationMinutes));
    });

    test('commitment days clamp to 1–7 (negative input)', () {
      expect(buildPlanSkeleton(goal: PrimaryGoal.loseWeight, weeklyCommitmentDays: 99)
          .workoutsPerWeek, 7);
      expect(buildPlanSkeleton(goal: PrimaryGoal.loseWeight, weeklyCommitmentDays: 0)
          .workoutsPerWeek, 1);
    });
  });

  // ---- GeneratePlan control ----
  group('GeneratePlan', () {
    const goal = FitnessGoal(
      id: 'g1',
      userId: 'u1',
      primaryGoal: PrimaryGoal.loseWeight,
      weeklyCommitmentDays: 3,
      timelineWeeks: 8,
    );

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

    test('premium user → AI-personalised plan (positive)', () async {
      final plans = FakePlanGateway();
      final ai = FakeAiGateway()..planResult['strategy'] = 'personalised';
      final c = makeContainer(role: UserRole.premium, plans: plans, ai: ai);
      final plan = await c.read(generatePlanProvider.notifier).generate();
      expect(plan, isNotNull);
      expect(ai.planCalls, 1);
      expect(plans.insertedPlans.single['generation_strategy'], 'personalised');
    });

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

    test('no active goal → error, nothing persisted (negative)', () async {
      final plans = FakePlanGateway();
      final c = makeContainer(role: UserRole.free, activeGoal: null, plans: plans);
      final plan = await c.read(generatePlanProvider.notifier).generate();
      expect(plan, isNull);
      expect(c.read(generatePlanProvider).hasError, isTrue);
      expect(plans.insertedPlans, isEmpty);
    });
  });

  // ---- CompleteOnboarding ----
  group('CompleteOnboarding', () {
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
  group('Profile.needsOnboarding', () {
    test('null onboardingCompletedAt → wizard required', () {
      const p = Profile(id: 'u', email: 'x@test', role: UserRole.free);
      expect(p.needsOnboarding, isTrue);
    });

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
