import 'package:flutter_test/flutter_test.dart';
import 'package:wise_workout/entities/enums.dart';
import 'package:wise_workout/entities/fitness_goal.dart';
import 'package:wise_workout/entities/fitness_profile.dart';

// (#) Tests the fitness profile and goal entity rules: XP/level maths, age, unit mapping, JSON decoding.
void main() {
  // (#) Group covering the XP-to-level and age helpers.
  group('FitnessProfile level/XP rules', () {
    // (#) (+) Check if level is floor(XP/200)+1 and the bar shows XP mod 200.
    test('level = floor(XP/200)+1; bar = XP mod 200', () {
      const fp = FitnessProfile(id: 'u', totalXp: 719);
      expect(fp.level, 4);
      expect(fp.xpIntoLevel, 119);
    });

    // (#) (-) Check if zero XP is level 1 with an empty bar.
    test('0 XP is level 1 with an empty bar', () {
      const fp = FitnessProfile(id: 'u');
      expect(fp.level, 1);
      expect(fp.xpIntoLevel, 0);
    });

    // (#) (+) Check if ageAt counts correctly the day before and on the birthday.
    test('ageAt handles pre/post birthday correctly', () {
      final fp = FitnessProfile(id: 'u', dateOfBirth: DateTime(2002, 3, 12));
      expect(fp.ageAt(DateTime(2026, 3, 11)), 23); // day before birthday
      expect(fp.ageAt(DateTime(2026, 3, 12)), 24); // on the birthday
    });

    // (#) (-) Check if ageAt is null when no date of birth is set.
    test('ageAt is null without a DOB (negative)', () {
      const fp = FitnessProfile(id: 'u');
      expect(fp.ageAt(DateTime(2026, 6, 11)), isNull);
    });

    // (#) (+) Check if fromJson maps a snake_case row into enums and fields.
    test('fromJson maps snake_case row', () {
      final fp = FitnessProfile.fromJson({
        'id': 'u1',
        'date_of_birth': '2002-03-12',
        'sex': 'female',
        'height_cm': 168,
        'weight_kg': 62.0,
        'activity_level': 'moderate',
        'training_experience': 'intermediate',
        'health_tag_ids': ['t1'],
        'preferred_workout_type_ids': ['w1', 'w2'],
        'total_xp': 719,
        'current_streak': 4,
      });
      expect(fp.sex, Sex.female);
      expect(fp.activityLevel, ActivityLevel.moderate);
      expect(fp.preferredWorkoutTypeIds, hasLength(2));
      expect(fp.currentStreak, 4);
    });
  });

  // (#) Group covering the goal unit, defaults, and stepper rules.
  group('FitnessGoal rules', () {
    // (#) (+) Check if each primary goal maps to the right target unit.
    test('unit mapping per goal', () {
      expect(FitnessGoal.unitFor(PrimaryGoal.loseWeight), TargetUnit.kg);
      expect(FitnessGoal.unitFor(PrimaryGoal.buildMuscle), TargetUnit.kg);
      expect(FitnessGoal.unitFor(PrimaryGoal.improveEndurance), TargetUnit.minutes);
      expect(FitnessGoal.unitFor(PrimaryGoal.maintainFitness), isNull);
    });

    // (#) (+) Check if default targets are derived from the current weight.
    test('defaults derive from current weight', () {
      expect(FitnessGoal.defaultTargetFor(PrimaryGoal.loseWeight, currentWeightKg: 70), 65);
      expect(FitnessGoal.defaultTargetFor(PrimaryGoal.buildMuscle, currentWeightKg: 70), 74);
      expect(FitnessGoal.defaultTargetFor(PrimaryGoal.improveEndurance), 60);
      expect(FitnessGoal.defaultTargetFor(PrimaryGoal.maintainFitness), isNull);
    });

    // (#) (+) Check if the stepper increments by 1 kg or 5 minutes per unit.
    test('stepper increments: ±1 kg, ±5 minutes', () {
      expect(FitnessGoal.stepFor(TargetUnit.kg), 1);
      expect(FitnessGoal.stepFor(TargetUnit.minutes), 5);
    });

    // (#) (+) Check if fromJson maps an active lose_weight goal with its target.
    test('fromJson maps an active lose_weight goal', () {
      final g = FitnessGoal.fromJson({
        'id': 'g1',
        'user_id': 'u1',
        'primary_goal': 'lose_weight',
        'target_value': 57.0,
        'target_unit': 'kg',
        'starting_value': 62.0,
        'timeline_weeks': 12,
        'weekly_commitment_days': 4,
        'created_at': '2026-06-01T00:00:00Z',
        'achieved_at': null,
      });
      expect(g.primaryGoal, PrimaryGoal.loseWeight);
      expect(g.isActive, isTrue);
      expect(g.hasTarget, isTrue);
    });
  });
}
