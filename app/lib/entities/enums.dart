// Shared enums mirroring the Postgres enum types (lowercase values match by name
// under json_serializable's default enum encoding; multi-word values carry
// @JsonEnum snake renaming). See supabase migrations.

import 'package:freezed_annotation/freezed_annotation.dart';

enum UserRole { free, premium, expert, admin }

enum UserStatus { active, suspended }

enum PreferredUnits { metric, imperial }

enum FeelRating { great, good, okay, tough }

enum Sex { female, male, other }

enum ActivityLevel { sedentary, light, moderate, active }

enum TrainingExperience { beginner, intermediate, advanced }

enum HealthTagKind { diet, allergy, injury }

enum GenerationStrategy { basic, personalised }

@JsonEnum(fieldRename: FieldRename.snake)
enum DeviceType { appleWatch, fitbit, garmin, polar, oura, phoneSensors, other }

extension DeviceTypeLabel on DeviceType {
  String get label => switch (this) {
        DeviceType.appleWatch => 'Apple Watch',
        DeviceType.fitbit => 'Fitbit',
        DeviceType.garmin => 'Garmin',
        DeviceType.polar => 'Polar',
        DeviceType.oura => 'Oura',
        DeviceType.phoneSensors => 'Phone sensors',
        DeviceType.other => 'Other device',
      };

  String get emoji => switch (this) {
        DeviceType.appleWatch => '⌚',
        DeviceType.fitbit => '📟',
        DeviceType.garmin => '⌚',
        DeviceType.polar => '❤️',
        DeviceType.oura => '💍',
        DeviceType.phoneSensors => '📱',
        DeviceType.other => '📡',
      };
}

@JsonEnum(fieldRename: FieldRename.snake)
enum PrimaryGoal { loseWeight, buildMuscle, improveEndurance, maintainFitness }

@JsonEnum(fieldRename: FieldRename.snake)
enum TargetUnit { kg, minutes, reps, km, stepsPerDay }

@JsonEnum(fieldRename: FieldRename.snake)
enum FeedbackCategory { bug, featureRequest, general }

extension ActivityLevelLabel on ActivityLevel {
  String get label => switch (this) {
        ActivityLevel.sedentary => 'Sedentary',
        ActivityLevel.light => 'Lightly Active',
        ActivityLevel.moderate => 'Moderately Active',
        ActivityLevel.active => 'Very Active',
      };

  String get description => switch (this) {
        ActivityLevel.sedentary => 'Little to no exercise',
        ActivityLevel.light => '1-2 workouts per week',
        ActivityLevel.moderate => '3-4 workouts per week',
        ActivityLevel.active => '5+ workouts per week',
      };
}

extension PrimaryGoalLabel on PrimaryGoal {
  String get label => switch (this) {
        PrimaryGoal.loseWeight => 'Lose Weight',
        PrimaryGoal.buildMuscle => 'Build Muscle',
        PrimaryGoal.improveEndurance => 'Improve Endurance',
        PrimaryGoal.maintainFitness => 'Maintain Fitness',
      };

  String get descriptor => switch (this) {
        PrimaryGoal.loseWeight => 'Calorie deficit · cardio focus',
        PrimaryGoal.buildMuscle => 'Strength training · progressive overload',
        PrimaryGoal.improveEndurance => 'Cardio · long sessions',
        PrimaryGoal.maintainFitness => 'Balanced routine',
      };
}

enum TrackSource { live, gpx }

/// Named social share targets (UI value type; no DB counterpart).
enum SocialPlatform { facebook, instagram, twitter, tiktok }

extension SocialPlatformLabel on SocialPlatform {
  String get label => switch (this) {
        SocialPlatform.facebook => 'Facebook',
        SocialPlatform.instagram => 'Instagram',
        SocialPlatform.twitter => 'Twitter',
        SocialPlatform.tiktok => 'TikTok',
      };
}

/// Post feed kinds (#11 Social) — mirrors the `post_kind` Postgres enum.
@JsonEnum(fieldRename: FieldRename.snake)
enum PostKind { workoutShare, challengeResult, levelUp }

/// Challenge axes (#11 Challenges) — mirror the Postgres enums.
@JsonEnum(fieldRename: FieldRename.snake)
enum ChallengeVisibility { public, inviteOnly }

@JsonEnum(fieldRename: FieldRename.snake)
enum ChallengeMetricKind { accumulator, bestOf }

@JsonEnum(fieldRename: FieldRename.snake)
enum ChallengeMetric {
  totalDistance,
  totalSessions,
  totalCalories,
  activeDays,
  fastestTime,
  longestDistance,
  mostCalories,
}

extension ChallengeMetricLabel on ChallengeMetric {
  String get label => switch (this) {
        ChallengeMetric.totalDistance => 'Total distance',
        ChallengeMetric.totalSessions => 'Total sessions',
        ChallengeMetric.totalCalories => 'Total calories',
        ChallengeMetric.activeDays => 'Active days',
        ChallengeMetric.fastestTime => 'Fastest time',
        ChallengeMetric.longestDistance => 'Longest distance',
        ChallengeMetric.mostCalories => 'Most calories',
      };
}

/// Expert marketplace enums (#6 cluster) — mirror the Postgres types.
enum ServiceStatus { draft, live, archived }

@JsonEnum(fieldRename: FieldRename.snake)
enum FulfillmentType { workoutPlan, nutrition, review, session, coaching }

extension FulfillmentTypeLabel on FulfillmentType {
  String get label => switch (this) {
        FulfillmentType.workoutPlan => 'Workout plan',
        FulfillmentType.nutrition => 'Nutrition',
        FulfillmentType.review => 'Review',
        FulfillmentType.session => 'Session',
        FulfillmentType.coaching => 'Coaching',
      };
}

@JsonEnum(fieldRename: FieldRename.snake)
enum PricingModel { oneTime, recurring }

/// Values aren't valid Dart identifiers — explicit wire values required.
enum ResponseTime {
  @JsonValue('24h')
  h24,
  @JsonValue('48h')
  h48,
  @JsonValue('72h')
  h72,
}

extension ResponseTimeLabel on ResponseTime {
  String get label => switch (this) {
        ResponseTime.h24 => 'Replies within 24h',
        ResponseTime.h48 => 'Replies within 48h',
        ResponseTime.h72 => 'Replies within 72h',
      };
}

enum ServiceRequestStatus { pending, accepted, completed, cancelled }

enum VerificationStatus { pending, verified, rejected }
