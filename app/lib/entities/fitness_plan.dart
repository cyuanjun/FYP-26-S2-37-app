import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';

part 'fitness_plan.freezed.dart';
part 'fitness_plan.g.dart';

/// ENTITY — a training plan tied to a goal. One active plan per user.
/// generationStrategy distinguishes the rule-based skeleton (basic, all tiers)
/// from the AI-personalised plan (Premium SuggestPlan).
@freezed
abstract class FitnessPlan with _$FitnessPlan {
  const FitnessPlan._();

  const factory FitnessPlan({
    required String id,
    required String userId,
    required String fitnessGoalId,
    required String name,
    String? description,
    required int durationWeeks,
    required int workoutsPerWeek,
    @Default(GenerationStrategy.basic) GenerationStrategy generationStrategy,
    @Default(0) int regeneratedCount,
    DateTime? startedAt,
    @Default(true) bool isActive,
  }) = _FitnessPlan;

  factory FitnessPlan.fromJson(Map<String, dynamic> json) => _$FitnessPlanFromJson(json);

  bool get isPersonalised => generationStrategy == GenerationStrategy.personalised;
}
