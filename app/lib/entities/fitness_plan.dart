import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';

part 'fitness_plan.freezed.dart';
part 'fitness_plan.g.dart';

// (#) A training plan built for a goal. Says how many weeks it runs and how many
// (#) workouts a week, and whether it was the basic rule-based plan or the AI
// (#) personalised one. Only one plan is active per user at a time.
@freezed
abstract class FitnessPlan with _$FitnessPlan {
  const FitnessPlan._();

  const factory FitnessPlan({
    required String id,
    required String userId,
    required String fitnessGoalId, // (#) the goal this plan serves
    required String name,
    String? description,
    required int durationWeeks,
    required int workoutsPerWeek,
    @Default(GenerationStrategy.basic) GenerationStrategy generationStrategy, // (#) basic rule-based vs AI-personalised
    @Default(0) int regeneratedCount, // (#) how many times it's been regenerated
    DateTime? startedAt,
    @Default(true) bool isActive,
  }) = _FitnessPlan;

  factory FitnessPlan.fromJson(Map<String, dynamic> json) => _$FitnessPlanFromJson(json);

  // (#) true when the AI made a personalised plan rather than the basic skeleton
  bool get isPersonalised => generationStrategy == GenerationStrategy.personalised;
}
