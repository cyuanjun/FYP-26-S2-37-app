import 'package:flutter_test/flutter_test.dart';
import 'package:wise_workout/entities/enums.dart';
import 'package:wise_workout/entities/fitness_goal.dart';
import 'package:wise_workout/entities/fitness_profile.dart';

void main() {
  group('FitnessProfile level/XP rules', () {
    test('level = floor(XP/200)+1; bar = XP mod 200', () {
      const fp = FitnessProfile(id: 'u', totalXp: 719);
      expect(fp.level, 4);
      expect(fp.xpIntoLevel, 119);
    });

    test('0 XP is level 1 with an empty bar', () {
      const fp = FitnessProfile(id: 'u');
      expect(fp.level, 1);
      expect(fp.xpIntoLevel, 0);
    });

    test('ageAt handles pre/post birthday correctly', () {
      final fp = FitnessProfile(id: 'u', dateOfBirth: DateTime(2002, 3, 12));
      expect(fp.ageAt(DateTime(2026, 3, 11)), 23); // day before birthday
      expect(fp.ageAt(DateTime(2026, 3, 12)), 24); // on the birthday
    });

    test('ageAt is null without a DOB (negative)', () {
      const fp = FitnessProfile(id: 'u');
      expect(fp.ageAt(DateTime(2026, 6, 11)), isNull);
    });

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

  group('FitnessGoal rules', () {
    test('unit mapping per goal', () {
      expect(FitnessGoal.unitFor(PrimaryGoal.loseWeight), TargetUnit.kg);
      expect(FitnessGoal.unitFor(PrimaryGoal.buildMuscle), TargetUnit.kg);
      expect(FitnessGoal.unitFor(PrimaryGoal.improveEndurance), TargetUnit.minutes);
      expect(FitnessGoal.unitFor(PrimaryGoal.maintainFitness), isNull);
    });

    test('defaults derive from current weight', () {
      expect(FitnessGoal.defaultTargetFor(PrimaryGoal.loseWeight, currentWeightKg: 70), 65);
      expect(FitnessGoal.defaultTargetFor(PrimaryGoal.buildMuscle, currentWeightKg: 70), 74);
      expect(FitnessGoal.defaultTargetFor(PrimaryGoal.improveEndurance), 60);
      expect(FitnessGoal.defaultTargetFor(PrimaryGoal.maintainFitness), isNull);
    });

    test('stepper increments: ±1 kg, ±5 minutes', () {
      expect(FitnessGoal.stepFor(TargetUnit.kg), 1);
      expect(FitnessGoal.stepFor(TargetUnit.minutes), 5);
    });

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
