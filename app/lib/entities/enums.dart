// (#) All the app's shared enums in one place. Fixed value sets used everywhere,
// (#) roles, goals, challenge metrics, device types, expert and subscription
// (#) statuses. No behaviour, just the allowed values.
// Shared enums mirroring the Postgres enum types (lowercase values match by name
// under json_serializable's default enum encoding; multi-word values carry
// @JsonEnum snake renaming). See supabase migrations.

import 'package:freezed_annotation/freezed_annotation.dart';

// (#) which tier or power level an account has
enum UserRole { free, premium, expert, admin }

// (#) whether an account is usable or has been suspended
enum UserStatus { active, suspended }

// (#) metric vs imperial display preference
enum PreferredUnits { metric, imperial }

// (#) how a workout felt, asked at the end of a session
enum FeelRating { great, good, okay, tough }

// (#) biological sex used for HR and calorie estimates
enum Sex { female, male, other }

// (#) how active the user says they are day to day
enum ActivityLevel { sedentary, light, moderate, active }

// (#) self-rated training background
enum TrainingExperience { beginner, intermediate, advanced }

// (#) the kinds of health tag a user can flag
enum HealthTagKind { diet, allergy, injury }

// (#) whether a plan was the basic rule-based one or AI-personalised
enum GenerationStrategy { basic, personalised }

// (#) the tracking devices we support
@JsonEnum(fieldRename: FieldRename.snake)
enum DeviceType { appleWatch, fitbit, garmin, polar, oura, phoneSensors, other }

// (#) friendly display name for each device type
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

  // (#) little icon for each device type
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

// (#) the main thing a user is training towards
@JsonEnum(fieldRename: FieldRename.snake)
enum PrimaryGoal { loseWeight, buildMuscle, improveEndurance, maintainFitness }

// (#) unit a goal's target is measured in
@JsonEnum(fieldRename: FieldRename.snake)
enum TargetUnit { kg, minutes, reps, km, stepsPerDay }

// (#) what a piece of user feedback is about
@JsonEnum(fieldRename: FieldRename.snake)
enum FeedbackCategory { bug, featureRequest, general }

// (#) label plus a short description for each activity level
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

// (#) label plus a one-line descriptor for each primary goal
extension PrimaryGoalLabel on PrimaryGoal {
  String get label => switch (this) {
        PrimaryGoal.loseWeight => 'Lose Weight',
        PrimaryGoal.buildMuscle => 'Build Muscle',
        PrimaryGoal.improveEndurance => 'Improve Endurance',
        PrimaryGoal.maintainFitness => 'Maintain Fitness',
      };

  // (#) short "how" caption shown under each goal
  String get descriptor => switch (this) {
        PrimaryGoal.loseWeight => 'Calorie deficit · cardio focus',
        PrimaryGoal.buildMuscle => 'Strength training · progressive overload',
        PrimaryGoal.improveEndurance => 'Cardio · long sessions',
        PrimaryGoal.maintainFitness => 'Balanced routine',
      };
}

// (#) where a workout track came from, live capture or an imported GPX
enum TrackSource { live, gpx }

// (#) the social apps we offer to share to (UI only, no DB column)
enum SocialPlatform { facebook, instagram, twitter, tiktok }

// (#) display name for each share target
extension SocialPlatformLabel on SocialPlatform {
  String get label => switch (this) {
        SocialPlatform.facebook => 'Facebook',
        SocialPlatform.instagram => 'Instagram',
        SocialPlatform.twitter => 'Twitter',
        SocialPlatform.tiktok => 'TikTok',
      };
}

// (#) what kind of thing a feed post is announcing
@JsonEnum(fieldRename: FieldRename.snake)
enum PostKind { workoutShare, challengeResult, levelUp }

// (#) whether a challenge is open to all or invite-only
@JsonEnum(fieldRename: FieldRename.snake)
enum ChallengeVisibility { public, inviteOnly }

// (#) run-up-a-total vs single-best-effort scoring style
@JsonEnum(fieldRename: FieldRename.snake)
enum ChallengeMetricKind { accumulator, bestOf }

// (#) the exact thing a challenge measures
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

// (#) display name for each challenge metric
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

// (#) lifecycle of an expert service listing
enum ServiceStatus { draft, live, archived }

// (#) how an expert service gets delivered
@JsonEnum(fieldRename: FieldRename.snake)
enum FulfillmentType { workoutPlan, nutrition, review, session, coaching }

// (#) display name for each fulfillment type
extension FulfillmentTypeLabel on FulfillmentType {
  String get label => switch (this) {
        FulfillmentType.workoutPlan => 'Workout plan',
        FulfillmentType.nutrition => 'Nutrition',
        FulfillmentType.review => 'Review',
        FulfillmentType.session => 'Session',
        FulfillmentType.coaching => 'Coaching',
      };
}

// (#) whether a service is charged once or on a recurring basis
@JsonEnum(fieldRename: FieldRename.snake)
enum PricingModel { oneTime, recurring }

// (#) exact snake-case string a fulfillment type writes to Postgres
extension FulfillmentTypeDb on FulfillmentType {
  String get dbValue =>
      this == FulfillmentType.workoutPlan ? 'workout_plan' : name;
}

// (#) exact snake-case string a pricing model writes to Postgres
extension PricingModelDb on PricingModel {
  String get dbValue => this == PricingModel.oneTime ? 'one_time' : name;
}

// (#) how quickly an expert promises to reply (values need explicit wire strings)
enum ResponseTime {
  @JsonValue('24h')
  h24,
  @JsonValue('48h')
  h48,
  @JsonValue('72h')
  h72,
}

// (#) display label plus the raw DB value for each response time
extension ResponseTimeLabel on ResponseTime {
  String get label => switch (this) {
        ResponseTime.h24 => 'Replies within 24h',
        ResponseTime.h48 => 'Replies within 48h',
        ResponseTime.h72 => 'Replies within 72h',
      };

  // (#) the '24h'/'48h'/'72h' string Postgres stores
  String get dbValue => switch (this) {
        ResponseTime.h24 => '24h',
        ResponseTime.h48 => '48h',
        ResponseTime.h72 => '72h',
      };
}

// (#) where a booked expert job is in its lifecycle
enum ServiceRequestStatus { pending, accepted, completed, cancelled }

// (#) where an expert application sits in the admin review
enum VerificationStatus { pending, verified, rejected }

// (#) state of a premium subscription
@JsonEnum(fieldRename: FieldRename.snake)
enum SubscriptionStatus { active, cancelled, pastDue }

// (#) display label plus the raw DB value for each subscription status
extension SubscriptionStatusLabel on SubscriptionStatus {
  String get label => switch (this) {
        SubscriptionStatus.active => 'Active',
        SubscriptionStatus.cancelled => 'Cancelled',
        SubscriptionStatus.pastDue => 'Past due',
      };

  // (#) snake-case string for a direct column write
  String get dbValue => switch (this) {
        SubscriptionStatus.pastDue => 'past_due',
        _ => name,
      };
}
