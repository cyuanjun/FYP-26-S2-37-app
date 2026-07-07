# ERD Relationship Spec

Relationship list for the TDM ERD, in the sample-document notation:
**Parent  -Verb-  Child**, with cardinality marked at each end.

- Read each line **parent -> child**: e.g. *User `1` -Has- `*` ConnectedDevice*.
- `1` = exactly one, `*` = many, `0..1` = zero or one, `1..*` = one or more.
- Crow's-foot equivalent: the `*` end gets the crow's foot, the `1` end the single bar.
- "via X" means a many-to-many relationship resolved through a junction table or stored id list.

> Source of truth: [database-v1.md](database-v1.md). This is the drawing checklist;
> the live diagram is at `/flow/schema` and the dbdiagram export is [database.dbml](database.dbml).

---

## Identity, Roles & Settings

| Parent | Card | Verb | Card | Child | Notes |
|---|:--:|:--:|:--:|---|---|
| User | 1 | Has | 0..1 | FitnessProfile | shared-PK specialization for athlete roles |
| User | 1 | Has | 0..1 | ExpertProfile | shared-PK specialization for expert role |
| User | 1 | Has | 0..1 | Subscription | shared-PK specialization for premium role |
| User | 1 | Has | * | ConnectedDevice | devices are user-level, not athlete-only |
| User | 1 | Stores | 0..1 | notificationPrefs | JSON map on `User`, not a separate table |
| User | * | Follows | * | ExpertProfile | via `User.followedExpertIds`; one-way marketplace bookmark |

## Catalogs & Athlete Profile

| Parent | Card | Verb | Card | Child | Notes |
|---|:--:|:--:|:--:|---|---|
| FitnessProfile | * | Prefers | * | WorkoutType | via `FitnessProfile.preferredWorkoutTypeIds` |
| FitnessProfile | * | Has | * | HealthTag | via `FitnessProfile.healthTagIds`; diet/allergy/injury split by `HealthTag.kind` |
| User | 1 | Creates | * | WorkoutType | optional `WorkoutType.createdByUserId`; custom catalog rows |
| User | 1 | Creates | * | HealthTag | optional `HealthTag.createdByUserId`; custom catalog rows |

## Training & Activity

| Parent | Card | Verb | Card | Child | Notes |
|---|:--:|:--:|:--:|---|---|
| FitnessProfile | 1 | Sets | * | FitnessGoal | active goal is `AchievedAt IS NULL` |
| FitnessProfile | 1 | Has | * | FitnessPlan | one active plan at a time by `IsActive` |
| FitnessGoal | 1 | Targets | * | FitnessPlan | plan goal is required |
| FitnessPlan | 1 | Contains | * | PlannedWorkout | week/day workout slots |
| WorkoutType | 1 | Classifies | * | PlannedWorkout | planned workout type |
| FitnessProfile | 1 | Records | * | WorkoutSession | completed or in-progress sessions |
| WorkoutType | 1 | Classifies | * | WorkoutSession | actual session type |
| PlannedWorkout | 0..1 | IsExecutedBy | * | WorkoutSession | nullable for free-form sessions |
| ConnectedDevice | 0..1 | Sources | * | WorkoutSession | nullable for manual entry; device type determines phone vs wearable |
| WorkoutSession | 1 | Logs | * | ExerciseLog | mainly non-cardio exercise entries |
| WorkoutSession | 1 | Embeds | 0..1 | trackPoints | inline JSON time-series, not a separate table |

## Social

| Parent | Card | Verb | Card | Child | Notes |
|---|:--:|:--:|:--:|---|---|
| User | 1 | Authors | * | Post | post kinds: workout share, challenge result, level up |
| WorkoutSession | 0..1 | IsWrappedBy | * | Post | when `Post.kind = workout_share` |
| Challenge | 0..1 | IsWrappedBy | * | Post | when `Post.kind = challenge_result` |
| Post | 1 | Has | * | PostLike | composite PK: `PostID + UserID` |
| User | 1 | Gives | * | PostLike | resolves User *-* Post likes |
| Post | 1 | Has | * | PostComment | comments thread |
| User | 1 | Writes | * | PostComment | resolves User *-* Post comments |
| User | 1 | Creates | * | Challenge | `CreatedByUserID` nullable for system-seeded challenges |
| WorkoutType | 0..1 | Filters | * | Challenge | nullable means any workout type qualifies |
| Challenge | 1 | Has | * | ChallengeParticipant | composite PK: `ChallengeID + UserID` |
| User | 1 | JoinsAs | * | ChallengeParticipant | resolves User *-* Challenge participation |
| WorkoutSession | 0..1 | IsSubmittedAs | * | ChallengeParticipant | best-of selected entry; null for accumulator challenges |
| User | * | Friends | * | User | via Follow; mutual pair of A->B and B->A rows |

## Experts

| Parent | Card | Verb | Card | Child | Notes |
|---|:--:|:--:|:--:|---|---|
| ExpertProfile | * | IsTaggedWith | * | ExpertCategory | via `ExpertProfile.specialties` slug list |
| ExpertCategory | 1 | Categorizes | * | ExpertService | service `Category` FK slug |
| ExpertProfile | 1 | Submits | * | ExpertVerificationDocument | identity/certification proof for admin review |
| ExpertProfile | 1 | Receives | * | ExpertReview | client reviews shown on expert detail |
| ServiceRequest | 1 | Receives | 0..1 | ExpertReview | one review per completed engagement |
| ExpertProfile | 1 | Offers | * | ExpertService | marketplace listings |
| User | 1 | Requests | * | ServiceRequest | client/requester |
| ExpertService | 1 | IsRequestedIn | * | ServiceRequest | requested listing |
| User | 1 | Provides | * | ServiceRequest | denormalised `ExpertUserID`; same expert as the service owner at request time |
| ServiceRequest | 1 | Has | * | Deliverable | expert reply documents for the engagement |

## Support & Admin Monitoring

| Parent | Card | Verb | Card | Child | Notes |
|---|:--:|:--:|:--:|---|---|
| User | 1 | Submits | * | Feedback | in-app one-way feedback, triaged by admin |
| ContactMessage | - | ComesFrom | - | Marketing website | no User FK; open visitor contact form |

---

### Current Schema Notes

- `Session` and `PasswordResetToken` are not modelled in this mock schema; auth is server-side/external.
- `NotificationPreference` was merged into `User.notificationPrefs`.
- `DietaryPreference`, `Allergy`, and `Injury` were collapsed into `HealthTag`.
- `UserWorkoutPreference` and `UserHealthTag` were collapsed into id lists on `FitnessProfile`.
- `WorkoutSessionTrack` was merged into inline `WorkoutSession.trackPoints` + `trackSource`.
- The `/flow/schema` canvas draws each FK child -> parent, while this file is written parent-first for TDM readability.
