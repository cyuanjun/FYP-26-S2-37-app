# Wise Workout — Database (v1)

> ⚠️ **The schema of record is the TDM v5 §8 ERD** (team-approved, 5 Jun 2026). This file is the **working source** that predates it (built from the React mock). **Aligned to the TDM §8 ERD on 10 Jun 2026** — the rosters match at **26 entities** ([reconciliation log](../../deliverables/doc-reconciliation-log.md) §D); the TDM settled the open questions (`ExpertReview` kept; expert layer = `ExpertService → ServiceRequest → Deliverable`; payment simulated via price fields). The generated Postgres DDL + RLS + seed now live in [`/supabase/`](../../../app/supabase/) (`supabase/migrations/` + `supabase/seed.sql`) — regenerate those from this file, not by hand.

Schema built up incrementally as we walk through screens in [screens-v1.md](screens-v1.md). Each entity records which screen first required it, so every column traces back to a UI need.

> **Server-side functions (as-built, 6 Jul 2026)** — beyond the DDL, three Postgres function groups ship with the schema: `end_workout_session(uuid, jsonb)` (SECURITY DEFINER; atomically finalizes a session, computes XP/streak/level and auto-inserts `level_up` Posts), `add_friend(uuid)` / `remove_friend(uuid)` (SECURITY DEFINER; write/delete the mutual Follow pair atomically — `follows` RLS only permits `follower_id = auth.uid()`, so the reciprocal row cannot be a client write), `challenge_leaderboards(uuid[])` (SECURITY INVOKER, reads `public_workout_sessions`; live-aggregates each participant's qualifying sessions per the challenge metric and ranks them — no stored progress column), and the **service-request lifecycle set** (7 Jul): `accept_service_request` / `decline_service_request` / `complete_service_request` (expert-only, status-guarded; complete stamps `CompletedAt`, bumps `ClientCount` and adds `QuotedPriceCents` to `TotalEarnedCents`) and `submit_expert_review` (client-only, completed-only, once per engagement; atomically recomputes `RatingAvg`/`ReviewCount`). Direct UPDATEs on `service_requests` and all client writes on `expert_reviews` are revoked — the RPCs are the only transition/review path. **`end_workout_session` backdate (9 Jul, removed 14 Jul):** a `started_at` in the metrics jsonb once backdated the session (added for manual entry US13); when US13 was descoped the field was left honored-but-unused, so it was **removed from the RPC (14 Jul)** to close a streak-backfill vector — the RPC now ignores any client start time and always sets ended_at = now(). **`start_premium()`** (8 Jul): the simulated Free→Premium upgrade — caller must be role `free`; flips `Role` to `premium` (authorized past the role-guard trigger via a transaction-local flag) and upserts the `Subscription` row (`active`, `RenewsAt = now()+1 month`, 999¢). Cancel/resume on #13.6 are plain owner-scoped `Subscription.Status` updates (no cross-party rules), per the RLS `subscriptions_owner` policy.

Final output is an ER diagram in the style of the FYP sample (entity boxes with PK/FK markers; relationships labelled with verbs and multiplicities like `1 — *`). This Markdown is the working source; the diagram is generated from it at the end.

## Conventions

- **PK** = primary key — exactly one per entity
- **FK → X** = foreign key referencing entity X
- **UQ** = unique constraint (non-PK)
- All `*ID` columns are UUIDs unless noted
- All timestamps are UTC
- `nullable` is called out; otherwise the column is NOT NULL

---

## Implementation status

Most entities are read by a product screen. As of the schema-v2 simplification (26 entities total — matches the TDM §8 ERD roster):

- **Surfaced — read by product screens:** all but the one below. The `HealthTag` + `WorkoutType` catalogs are read **and** written on **#13.1 Fitness Profile** — multi-select chips backed by the catalogs, persisted into `FitnessProfile.healthTagIds` / `FitnessProfile.preferredWorkoutTypeIds` (folded from the former `UserHealthTag` / `UserWorkoutPreference` junctions in schema-v2).
- **Write-only (intentional):** `Feedback` — created on #13.5 Submit Feedback (fire-and-forget per the "honest" note); never read back in-app.

A built-out **Onboarding (#3, built 12 Jun — wizard + AI plan generation)** would additionally *capture* the #13.1 tags at signup; custom-tag creation (the catalogs' `isCustom` / `createdByUserId`) is a possible follow-on.

---

## Entities

### User
Base account record for every role. Role-conditional data lives in **specialization tables** (`FitnessProfile` for athlete roles, `ExpertProfile` for experts) rather than as nullable columns here — admins need no specialization. This keeps `User` lean and lets the ER diagram show role-specific data clearly. (Universal per-user settings now live on `User` directly — e.g. `notificationPrefs`, merged from the old NotificationPreference table.)

*Introduced by: #1 Splash · extended by: #5 Dashboard (FirstName, AvatarUrl) · #13 Profile (LastName, Username) · #14 Account Settings (PreferredUnits) · #13.1 Fitness Profile (introduced `FitnessProfile` specialization; moved DateOfBirth / Sex / HeightCm / WeightKg / ActivityLevel / TrainingExperience there) · #13.2 Fitness Goals (introduced `FitnessGoal` entity) · #11.2 User Profile (added Bio)*

| Attribute | Type | Key | Notes |
|---|---|---|---|
| UserID | UUID | PK | |
| Email | varchar(255) | UQ | login identifier; editable from #14 |
| Role | enum |  | `free` \| `premium` \| `expert` \| `admin` |
| Status | enum | nullable | `active` \| `suspended`; null = active. Admins suspend / unsuspend accounts on #26.1 (`setUserStatus`) |
| FirstName | varchar(100) |  | rendered in the Dashboard greeting ("Hi, Mia") |
| LastName | varchar(100) |  | composed with FirstName for the Profile name "MIA PATEL" |
| Username | varchar(50) | UQ | the `@handle`, shown on Profile and (later) in Social |
| AvatarUrl | varchar(500) |  | nullable; falls back to initials when null |
| PreferredUnits | enum |  | `metric` \| `imperial`; default `metric`. UI preference for all roles. |
| Bio | text |  | nullable. Free-form short paragraph rendered in the About section of #11.2 User Profile and the 2-line preview on each Expert marketplace card (#6). |

### FitnessProfile
**1-to-1 specialization of `User`** for athlete roles (Free / Premium / Expert-who-trains). Admin users do not have a row here. Uses the **shared-key pattern**: `UserID` is both PK and FK to `User`, so the same identifier flows through.

*Introduced by: #13.1 Fitness Profile (moved out of User)*

| Attribute | Type | Key | Notes |
|---|---|---|---|
| UserID | UUID | PK, FK → User | shared key; one fitness profile per user |
| DateOfBirth | date |  | nullable; feeds age display + BMR / calorie calc |
| Sex | enum |  | `female` \| `male` \| `other`; biological for BMR / calorie / HR zone calc (separate from identity) |
| HeightCm | int |  | nullable; metric source of truth. Display converts to imperial via `User.PreferredUnits`. |
| WeightKg | decimal(5,2) |  | nullable; metric source of truth |
| ActivityLevel | enum |  | nullable; `sedentary` \| `light` \| `moderate` \| `active` |
| TrainingExperience | enum |  | nullable; `beginner` \| `intermediate` \| `advanced` |
| RestingHeartRate | int |  | nullable; bpm. Karvonen HRR baseline for **Training Effect** (`lib/effectEstimate.computeTrainingEffect`) and **#12.2 HR zone breakdown** (`lib/advancedAnalytics.computeHrZones`). null = use the population default 60. Wearables (Apple Watch / Garmin) auto-populate this in production; for the mock the user self-reports on #13.1. |
| TotalXp | int |  | nullable; lifetime XP. Bumped by `endWorkoutSession` via `lib/levelXp.xpForSession` (base 20 + 1/min duration + 5/km for cardio + 10 for planned). Level = `floor(TotalXp / 200) + 1`. |
| CurrentStreak | int |  | nullable; consecutive Mon–Sun weeks with ≥1 ended workout, recomputed live on each session end. Weekly (not daily) so rest days don't break the streak. |

Future specializations (planned, not yet built): `ExpertProfile` (certifications, bio, hourly rate) and `AdminProfile` (permissions, audit scope) — same 1-to-1 pattern, gated by `User.Role`.

**Replaces the old Badge / UserBadge system** (dropped in schema-v2). Level + XP + streak appear on #5 Dashboard (Level/Streak tile), #10 WorkoutSummary (`+N XP` line), #13 Profile (level bar + Streak stat), #11.2 UserProfile (Level + Streak pills). Crossing a level threshold auto-emits a `level_up` Post to the #11 Social feed.

### WorkoutType
Catalog of selectable workout disciplines (Running, Strength, Cycling, Yoga, etc.). Seeded at app install. Users can also **add custom entries** via the search+add affordance in `PickerModal` — those rows are marked `IsCustom = true` with `CreatedByUserID` set.

*Introduced by: #13.1 Fitness Profile (Preferred Workouts chips + picker)*

| Attribute | Type | Key | Notes |
|---|---|---|---|
| WorkoutTypeID | UUID | PK | |
| Name | varchar(60) | UQ | display name |
| Slug | varchar(60) | UQ | url-safe identifier; drives the rendered glyph via `iconForSlug(slug)` in [components/WorkoutListCard.tsx](../../app/src/components/WorkoutListCard.tsx) (running → 🏃, cycling → 🚴, …) |
| IsCustom | boolean |  | default `false`; `true` for user-added entries |
| CreatedByUserID | UUID | FK → User | nullable; set when `IsCustom = true`. Enables future "popular custom entries" / moderation flows. |

### HealthTag
One catalog for the three profile-tag kinds — **diet** (Vegetarian, Keto…), **allergy** (Nuts, Dairy…), and **injury** (Knee pain, Lower back…) — discriminated by `Kind`. Collapsed from three structurally-identical entities (`DietaryPreference` / `Allergy` / `Injury`); `#13.1` filters by `Kind` to render the separate Diet / Allergies / Injuries chip rows. Custom entries supported (see WorkoutType notes). Names are unique **within a kind**.

*Introduced by: #13.1 Fitness Profile (Diet / Allergies / Injuries chips)*

| Attribute | Type | Key | Notes |
|---|---|---|---|
| HealthTagID | UUID | PK | |
| Kind | enum |  | `diet` \| `allergy` \| `injury` |
| Name | varchar(60) |  | unique within a kind |
| IsCustom | boolean |  | default `false` |
| CreatedByUserID | UUID | FK → User | nullable; set when `IsCustom = true` |

> **The `UserHealthTag` + `UserWorkoutPreference` junctions were merged onto `FitnessProfile` in schema-v2** as `healthTagIds: string[]` and `preferredWorkoutTypeIds: string[]`. The app only ever asks "what tags does THIS user have?" (#13.1) — never the reverse — so a junction wasn't earning its keep. The `HealthTag` + `WorkoutType` *catalogs* stay; only the junctions are gone. A production schema would still M:N if it needed reverse lookups.

### Notification preferences — `User.notificationPrefs`
Notification on/off toggles are stored as a `notificationPrefs` JSON map (`NotificationTypeKey → bool`) **on `User`**, not as their own table. Merged from the former `NotificationPreference` entity in schema-v2: a handful of settings switches didn't justify a relational table, and they apply to every role. A missing key reads as off. Edited on #13.4 (the screen filters which types to show by audience). Display metadata (label/description/category per type) lives in code (`NOTIFICATION_TYPES`, `NOTIFICATION_CATEGORY_LABELS`), not the DB.

### FitnessPlan
A training plan for an athlete. 1-to-many with `FitnessProfile`. Generated when the user sets a `FitnessGoal`, and on manual "Regenerate" tap. Per the locked AI scope (build-plan §5, bce-design §2.1), the **base week skeleton is rule-based** (`BuildPlanSkeleton`, all tiers); AI only *personalises* it (`SuggestPlan`, Premium). `GenerationStrategy` records which path: Free users get **basic** plans (rule-based skeleton from goal + activity level, capped at 1 regeneration per month); Premium users get **personalised** plans (AI refinement driven by their full profile — allergies, injuries, preferred workouts, training experience).

*Introduced by: #7 Train · #8 Plan Detail · planned for AI-generation flow*

| Attribute | Type | Key | Notes |
|---|---|---|---|
| FitnessPlanID | UUID | PK | |
| UserID | UUID | FK → FitnessProfile | athlete-only |
| FitnessGoalID | UUID | FK → FitnessGoal | required — the goal this plan targets (a plan can't exist without something to optimise for) |
| Name | varchar(120) |  | e.g. "8-Week Lose Weight Plan" |
| Description | varchar(500) |  | nullable; AI-generated summary shown on Plan Detail |
| DurationWeeks | int |  | mirrors `FitnessGoal.TimelineWeeks` when goal-linked |
| WorkoutsPerWeek | int |  | mirrors `FitnessGoal.WeeklyCommitmentDays` when goal-linked |
| GenerationStrategy | enum |  | `basic` (Free, goal-only) \| `personalised` (Premium, uses full profile). The Premium ✓ on #8 keys off this; future-proofs for new strategies (e.g. `coach_authored`) |
| RegeneratedCount | int |  | default 0; for enforcing free-user regen limits (1 per month) |
| StartedAt | timestamp |  | nullable; set when user begins executing |
| IsActive | boolean |  | one active plan at a time per user; flipped to `false` when a new plan is generated. |

### PlannedWorkout
A workout slot within a `FitnessPlan` — week N, day M, type, duration, plus the **Premium "detailed breakdown"** fields (target HR zone, coaching cues, and a prescribed exercise list). Free sees only Name + Descriptor + Duration (the rest is a Premium upsell teaser in the Workout Detail modal); Premium sees the full breakdown.

*Introduced by: #8 Plan Detail · referenced by #9 Active Workout when plan-based*

| Attribute | Type | Key | Notes |
|---|---|---|---|
| PlannedWorkoutID | UUID | PK | |
| FitnessPlanID | UUID | FK → FitnessPlan | |
| WorkoutTypeID | UUID | FK → WorkoutType | catalog reference |
| WeekNumber | int |  | 1..`FitnessPlan.DurationWeeks` |
| DayOfWeek | int |  | 1–7 (Mon–Sun) |
| DurationMinutes | int |  | target session length |
| Name | varchar(60) |  | nullable; AI-generated session name ("Easy Run", "Power Session"). Surfaced as the Train tab's today-card headline. |
| Descriptor | varchar(120) |  | nullable; AI-generated coaching line ("Zone 2 · recovery pace", "Compound lifts · 4×8"). Adds context next to duration. |
| OrderIndex | int |  | tie-breaker if multiple workouts on the same day; usually 0 |
| Segments | WorkoutSegment[] |  | **Premium**; generic prescription rows `{label, detail, sub?}` — one universal shape for every activity (strength sets×reps, cardio zones/distance, HIIT intervals, yoga holds…). `sub` is an optional 2nd line (intensity / rest / HR range). Cardio HR ranges are derived from the user's age (≈220−age); strength uses RPE not absolute kg. Reused by the Expert "Create Workout Plan" flow. |
| CoachingCues | string[] |  | **Premium**; short cues shown in the detail modal (any activity) |

### WorkoutSession
A recorded session — what the user actually did. Can be tied to a `PlannedWorkout` (executing a plan) or free-form (`PlannedWorkoutID = null`, "Quick Start"). Optionally sourced from a `ConnectedDevice`.

*Introduced by: #9 Active Workout · finalized by #10 Workout Summary*

| Attribute | Type | Key | Notes |
|---|---|---|---|
| WorkoutSessionID | UUID | PK | |
| UserID | UUID | FK → FitnessProfile | |
| WorkoutTypeID | UUID | FK → WorkoutType | |
| PlannedWorkoutID | UUID | FK → PlannedWorkout | nullable; null = free-form session |
| ConnectedDeviceID | UUID | FK → ConnectedDevice | nullable. **Null = no connected device recorded** (phone-only / freeform; originally denoted manual entry, US13, since descoped); non-null points at the capture device — `ConnectedDevice.deviceType` disambiguates phone-sensor vs wearable capture without a parallel `dataSource` enum (dropped in v84) |
| StartedAt | timestamp |  | set when user taps "Start" |
| EndedAt | timestamp |  | nullable until session finishes |
| DurationSeconds | int |  | computed `EndedAt − StartedAt` |
| CaloriesBurned | int |  | nullable; from device or estimated |
| AvgHeartRate | int |  | nullable |
| MaxHeartRate | int |  | nullable |
| DistanceMeters | int |  | nullable; for running/cycling/swimming |
| FeelRating | enum |  | nullable; `great` \| `good` \| `okay` \| `tough` (captured on #10 Summary) |
| Notes | varchar(500) |  | nullable; **always private** — never displayed on Social, never readable by anyone but the owner |
| CustomName | varchar(120) |  | nullable; user-set override for the display name (editable from #12.1). Null = derive from `PlannedWorkout.name ?? WorkoutType.name`. Lets users rename historical sessions without losing the underlying plan/type linkage. |

Earlier iterations had `IsShared` + `Description` columns on this table. Both were removed when Social grew beyond workout-only sharing (the `Challenge` entity arrived, requiring a polymorphic feed entry). Sharing now means a `Post` row exists for the session (`Post.kind = 'workout_share'`, `Post.workoutSessionId = this`); the public caption lives on `Post.Body`. See `Post` below.

> **Track time-series merged onto `WorkoutSession` in schema-v2.** The former 1:1 `WorkoutSessionTrack` is now two columns on `WorkoutSession`: `trackPoints` (a `TrackPoint[]` json series — `{ t, hr?, cad?, elev?, pace? }`; null = no track; cardio gets the full payload, non-cardio is HR-only) and `trackSource` (`'live' | 'gpx'`). A separate table for a strict 1:1 blob wasn't earning its keep — #12.1 reads `session.trackPoints` directly for the graphs. (For a production relational schema you'd still promote `TrackPoint` into its own child table; the mock keeps it inline so one store read returns the whole chart payload.)

### ExerciseLog
A single exercise the user logs post-session for non-cardio workouts (strength, yoga, etc.). One `WorkoutSession` → many `ExerciseLog` rows. Captured on **#10 Workout Summary** via the Exercises section. Cardio sessions don't use this entity — their detail is in `DistanceMeters` + the derived pace.

*Introduced by: #10 Workout Summary (non-cardio exercise logging)*

| Attribute | Type | Key | Notes |
|---|---|---|---|
| ExerciseLogID | UUID | PK | |
| WorkoutSessionID | UUID | FK → WorkoutSession | |
| ExerciseName | varchar(80) |  | free text — "Back squat", "Goblet press"; not a catalog yet |
| Sets | int |  | ≥ 1 |
| Reps | int |  | reps per set; assumed uniform across sets (simplification — drop-sets/AMRAP can come later) |
| WeightKg | decimal(5,2) |  | nullable; null = bodyweight |
| OrderIndex | int |  | display order within the session |

### ConnectedDevice
A paired wearable / sensor. 1-to-many with `User` (FK directly, not via `FitnessProfile` — devices are user-level; future admin/expert flows might also use them).

*Introduced by: #7.1 Connected Devices*

| Attribute | Type | Key | Notes |
|---|---|---|---|
| ConnectedDeviceID | UUID | PK | |
| UserID | UUID | FK → User | |
| DeviceType | enum |  | `apple_watch` \| `fitbit` \| `garmin` \| `polar` \| `oura` \| `phone_sensors` \| `other` |
| DeviceName | varchar(80) |  | display name, e.g. "Mia's Apple Watch" |
| LastSyncedAt | timestamp |  | nullable |
| IsActive | boolean |  | whether the device is currently usable as a data source |
| BleRemoteId | text |  | nullable (added 9 Jul). The Bluetooth remote id captured when the device was paired via a **real BLE scan** — sessions with it stream live heart rate through `BleHeartRateSource`; null = mock/demo pairing (simulated HR stream) |

### FitnessGoal
Per-athlete fitness target — the structured "what is the user trying to achieve" record. 1-to-many with `FitnessProfile` (only athletes have goals). The **active goal** is the row where `AchievedAt IS NULL`; achieving sets the timestamp and the user picks a new one.

*Introduced by: #13.2 Fitness Goals · supersedes the old `User.FitnessGoal` varchar column*

| Attribute | Type | Key | Notes |
|---|---|---|---|
| FitnessGoalID | UUID | PK | |
| UserID | UUID | FK → FitnessProfile | enforces athlete-only |
| PrimaryGoal | enum |  | `lose_weight` \| `build_muscle` \| `improve_endurance` \| `maintain_fitness` |
| TargetValue | decimal(8,2) |  | nullable; **polymorphic** — meaning depends on `TargetUnit`. App formats based on unit. |
| TargetUnit | enum |  | nullable; `kg` \| `minutes` \| `reps` \| `km` \| `steps_per_day`. Determines how `TargetValue` is interpreted and displayed. `maintain_fitness` has no target (both null). |
| StartingValue | decimal(8,2) |  | nullable; starting point captured at goal-set time. Used to show progress deltas ("-5 kg from current weight") without recomputing from snapshots. |
| TimelineWeeks | int |  | nullable; UI-enforced to 4 / 8 / 12 / 16 / 24. Replaces a fixed deadline date with a relative duration. **Null for `maintain_fitness`** (ongoing, no duration). |
| WeeklyCommitmentDays | int |  | nullable; 1–7. Required for every goal type — frequency commitment applies even to `maintain_fitness`. |
| CreatedAt | timestamp |  | goal start date = CreatedAt; deadline = CreatedAt + TimelineWeeks if needed. |
| AchievedAt | timestamp |  | nullable; `null` ⇒ active goal |

**Schema design choice — polymorphic target:** Instead of separate `TargetWeightKg` / `TargetDurationMins` / etc. columns (one per goal type), we use a single `TargetValue` + `TargetUnit` pair. Adding new goal types (e.g. "Run 10K") only requires a new enum value, not a schema migration. Trade-off: queries lose column-level type info, so any aggregation needs to filter by `TargetUnit` first.

> **Auth tables (`Session`, `PasswordResetToken`) dropped in schema-v2.** They were backend/auth plumbing with no screen — login + password reset are handled server-side / externally. "Remember me" still sets token expiry at issue time in the real app; it's documented in the login spec, not modelled here.

### Post
A polymorphic feed entry on Social. Three kinds today; more can be added (PR celebrations, milestones) without changing the shape of likes / comments. Exactly one of `WorkoutSessionID` / `ChallengeID` / `Level` is non-null based on `Kind`.

*Introduced by: #11 Social — replaced the earlier "workouts-are-posts" model once Social grew beyond a single content type. The earlier `Post` entity (workout-only) was dropped during the workouts-are-posts refactor and then reintroduced here with polymorphic content fields. The `competition_result` kind was renamed to `challenge_result` when the Competition entity merged into Challenge. The `badge_earned` kind was replaced by `level_up` in schema-v2 when the Badge / UserBadge entities were removed in favour of an XP-based leveling system on FitnessProfile.*

| Attribute | Type | Key | Notes |
|---|---|---|---|
| PostID | UUID | PK | |
| UserID | UUID | FK → User | author / triggering user |
| Kind | enum |  | `workout_share` \| `challenge_result` \| `level_up` |
| WorkoutSessionID | UUID | FK → WorkoutSession; nullable | populated when `Kind = workout_share` |
| ChallengeID | UUID | FK → Challenge; nullable | populated when `Kind = challenge_result` (auto-created when a `best_of` Challenge ends; not generated for `accumulator` Challenges) |
| Level | int | nullable | populated when `Kind = level_up` — the level the user just reached. Auto-emitted by `endWorkoutSession` whenever the XP delta crosses one or more level thresholds. |
| Body | varchar(500) |  | nullable; optional caption. For workout shares this is the public description. For challenge results it's an optional comment from the challenge's creator. |
| CreatedAt | timestamp |  | sort key for the feed |

### PostLike
One like per (`Post`, `User`) pair. Composite PK enforces uniqueness; toggling re-uses the same row.

*Introduced by: #11 Social*

| Attribute | Type | Key | Notes |
|---|---|---|---|
| PostID | UUID | PK + FK → Post | |
| UserID | UUID | PK + FK → User | the liker |

### PostComment
Flat comment thread under a `Post`. No threading in v1.

*Introduced by: #11 Social — comments now live on #11.1 Post Detail (works for both `workout_share` and `challenge_result` post kinds)*

| Attribute | Type | Key | Notes |
|---|---|---|---|
| CommentID | UUID | PK | |
| PostID | UUID | FK → Post | |
| UserID | UUID | FK → User | comment author |
| Body | varchar(300) |  | required, non-empty after trim |
| CreatedAt | timestamp |  | sort key within the thread |

### Challenge
Unified group-activity entity. Two orthogonal axes drive behaviour:

| Axis | Values | Drives |
|---|---|---|
| **Visibility** | `public` \| `invite_only` | Whether the challenge appears on the Active sub-tab for browsing; invite-only ones surface only via friend invites (Phase 1B). |
| **MetricKind** | `accumulator` \| `best_of` | Whether progress fills toward a target (progress bar) or each participant's best single session is ranked head-to-head (no target). |

Earlier iterations had this split as two entities: **Challenge** (public/accumulator only) and **Competition** (invite-only/best-of only). After the card chrome, leaderboard preview, sub-tab placement, and ranking logic all unified, the split stopped earning its keep — both halves had 90%+ overlapping columns. Collapsing into one entity with orthogonal axes also unlocks combos the split couldn't model: *public race* ("anyone, fastest 5K this month") and *private goal* ("just my running club, hit 500 km collectively").

*Introduced by: #11 Social (Challenges tab) — extended in [merge commit] with `Visibility` + `MetricKind` when Competition merged in.*

| Attribute | Type | Key | Notes |
|---|---|---|---|
| ChallengeID | UUID | PK | |
| CreatedByUserID | UUID | FK → User; nullable | null = system / curator-seeded. Set when a user creates a Challenge via the + button on #11 Social. |
| Name | varchar(120) |  | e.g. "Run 100km in May", "Weekend 5K Challenge" |
| ShortName | varchar(20) |  | compact pill text above the title (e.g. "MAY 100K") |
| Description | varchar(500) |  | tagline / reward hint; nullable |
| Icon | varchar(8) |  | emoji glyph rendered on the card / row |
| Visibility | enum |  | `public` \| `invite_only` |
| MetricKind | enum |  | `accumulator` \| `best_of` |
| Metric | enum |  | `total_distance` \| `total_sessions` \| `total_calories` \| `active_days` \| `fastest_time` \| `longest_distance` \| `most_calories`. `MetricKind` decides fill-vs-rank; `total_sessions` + `best_of` is the "most sessions" race. |
| TargetValue | int | nullable | Required when `MetricKind = accumulator` (distance in metres; sessions/days as counts; calories as kcal). null when `MetricKind = best_of` (no target — ranking is the point). |
| WorkoutTypeID | UUID | FK → WorkoutType; nullable | null = any workout type qualifies |
| StartedAt | timestamp |  | window opens |
| EndedAt | timestamp |  | deadline |

### ChallengeParticipant
Junction table: which users have joined which Challenge. Two participation modes share the same row shape:

| MetricKind | WorkoutSessionID behaviour |
|---|---|
| `accumulator` | Stays null forever. Progress is summed live from every qualifying session in the window — no explicit submission step. |
| `best_of` | The participant's chosen entry. Null until they pick one. Active best_of challenges auto-rank from each participant's best in-window qualifying session in the meantime; on deadline that selection would be locked in by a backend scheduler. |

| Attribute | Type | Key | Notes |
|---|---|---|---|
| ChallengeID | UUID | PK + FK → Challenge | |
| UserID | UUID | PK + FK → User | |
| WorkoutSessionID | UUID | FK → WorkoutSession; nullable | Only meaningful when `challenge.metricKind = 'best_of'`; see table above. |

### Follow
Stores a mutual **friendship** between two users (no separate "following" / "followers" concept in this app — the user-facing label is **Friends**). Despite the directional row shape, every friendship is materialised as a **pair** of rows (A→B + B→A) so the existing follow-graph queries (e.g. "is X a friend of Y?") keep working without a schema rewrite. The store's `followUser` / `unfollowUser` actions enforce the mutual invariant — they always touch both rows atomically.

*Introduced by: #11 Social*

| Attribute | Type | Key | Notes |
|---|---|---|---|
| FollowerID | UUID | PK + FK → User | one side of the pair |
| FollowingID | UUID | PK + FK → User | the other side of the pair |

**Constraints:**
- `FollowerID != FollowingID` (no self-follow — enforced at write time)
- For every row `(A, B)` there must also exist `(B, A)` — enforced by the store actions, not at the DB level in the mock

Earlier iterations used directional follow (Twitter-style). The model changed to mutual at the user's request once Social shipped; the data shape stayed identical to minimise the diff.

> **Badge / UserBadge dropped in schema-v2.** The achievement-catalog system was replaced by a numeric XP + level system stored on `FitnessProfile` (`TotalXp`, `CurrentStreak`). Earning posts become `level_up` Posts on the feed; the level + XP bar shows under the handle on #13 Profile and on #11.2 User Profile; #5 Dashboard surfaces a Level/Streak tile; #10 Workout Summary shows `+N XP` earned for the session. XP / streak math lives in `lib/levelXp.ts` and is invoked by `endWorkoutSession`.

### ExpertCategory
The marketplace **category catalog** — the topics experts tag services + specialties with. Started as a fixed `ExpertSpecialty` enum; **converted to a CRUD-able entity** so an admin can curate it on **#29 Categories**. `CategoryID` is a stable slug (the original enum values: `strength`, `endurance`, `mobility`, `nutrition`, `running`, `recovery`), referenced by `ExpertProfile.Specialties` + `ExpertService.Category`. **Never hard-deleted** — retired via `Active = false` (consistent with user-suspend / service-archive), which hides it from new selection (#21.2 picker, #24.1 multi-select, #6 filter) while still resolving labels for data that already uses it.

*Introduced by: #29 Categories*

| Attribute | Type | Key | Notes |
|---|---|---|---|
| CategoryID | slug | PK | stable id, e.g. `strength`; auto-slugified from the label on create |
| Label | varchar(60) |  | display name on chips / filters / pickers |
| Description | varchar(200) |  | what the category covers — admin-authored on #29 |
| IsActive | bool |  | `false` = suspended — hidden from new selection, still resolves labels |

### ExpertProfile
**1-to-1 specialization of `User`** for `role = 'expert'`. Uses the **shared-key pattern**: `UserID` is both PK and FK to `User`, so the same identifier flows through. Stores the public-facing profile content surfaced on #6 + #6.1 plus the stat tiles (rating, reviews, clients).

*Introduced by: #6 Experts*

| Attribute | Type | Key | Notes |
|---|---|---|---|
| UserID | UUID | PK + FK → User | shared key with `User` where `Role = 'expert'` |
| Title | varchar(100) |  | rendered above the name on #6.1, e.g. "Strength Coach" |
| YearsCoaching | int |  | drives the "{N} years coaching" tagline under the name |
| About | text |  | longer paragraph for the About section on #6.1 |
| Credentials | text[] |  | checklist items on #6.1, e.g. `["CSCS certified", "8 years coaching experience"]` |
| Specialties | slug[] | FK → ExpertCategory | multi-tag of `categoryId`s; drives the chips on #6.1 + category filter on #6 |
| RatingAvg | numeric(2,1) |  | 0–5, one decimal; stored lifetime aggregate (recomputed from `ExpertReview` server-side in production) |
| ReviewCount | int |  | stored lifetime count; bumped when an `ExpertReview` is submitted |
| ClientCount | int |  | lifetime client count (reputation stat); mock-only — computed from `ServiceRequest` aggregation in production. Distinct from #20's "Active" tile, which counts *current* accepted requests |
| TotalEarnedCents | int |  | lifetime simulated earnings (7 Jul): `complete_service_request` adds the engagement's `QuotedPriceCents` on completion. An aggregate, not a ledger — the per-engagement amounts remain the `ServiceRequest.QuotedPriceCents` snapshots. Seeded mock-scale like the other aggregates |
| VerificationStatus | enum |  | `pending` \| `verified` \| `rejected` — admin review workflow (#27); `verified` drives the ✓ Verified badge on #20/#24 |

### ExpertReview
A client's rating + written review of an expert, left after a **completed** engagement (gated to a `completed` `ServiceRequest`, one review per engagement). Surfaced in the Reviews list on **#6.1 Expert Detail**; submitted from **#6.2** once the client's request is accepted. `ExpertProfile.RatingAvg` / `ReviewCount` stay the stored lifetime aggregate — submitting a review prepends to the list + bumps `ReviewCount` (full recompute is a production concern).

*Introduced by: #6.1 Expert Detail*

| Attribute | Type | Key | Notes |
|---|---|---|---|
| ExpertReviewID | UUID | PK | |
| ExpertUserID | UUID | FK → User | the expert being reviewed |
| UserID | UUID | FK → User | the reviewer (client) |
| ServiceRequestID | UUID | FK → ServiceRequest | the completed engagement; one review per |
| Rating | int |  | 1–5 stars |
| Body | text |  | written review |
| CreatedAt | timestamp |  | |

### ExpertVerificationDocument
Proof an expert submits at **(external) signup** to verify their identity + achievements. An admin reads these on **#27.1** before flipping `ExpertProfile.VerificationStatus` to `verified`. Many per expert (one identity doc + N certifications). No real file blob in the mock — `FileName` is metadata; production would store an uploaded-file URL.

*Introduced by: #27.1 Expert Review*

| Attribute | Type | Key | Notes |
|---|---|---|---|
| ExpertVerificationDocumentID | UUID | PK | |
| UserID | UUID | FK → ExpertProfile | the expert who submitted |
| DocType | enum |  | `identity` (gov ID / passport) \| `certification` (certs backing the `Credentials` claims) |
| Title | varchar(120) |  | e.g. "Passport", "CSCS Level 1 Certificate" |
| FileName | varchar(160) |  | mock metadata, e.g. `passport.pdf` — production stores a URL |
| UploadedAt | timestamp |  | |

### ExpertService
A marketplace **listing** an expert offers (coaching package, prep plan, video review, call). Authored + managed by the expert on #21 Services / #21.1 Create/Edit Service. This is the storefront; `Fulfillment` tags *what it delivers*, and the actual content is sent per-client as `Deliverable` documents (#23.1) once a request is accepted. Browsable on the Service Listings sub-tab of #6 and listed on #6.1 once `Status = live`. Requestable from #6.2.

*Introduced by: #6 Experts*

| Attribute | Type | Key | Notes |
|---|---|---|---|
| ExpertServiceID | UUID | PK | |
| ExpertUserID | UUID | FK → User | the expert offering the service |
| Status | enum |  | `draft` \| `live` \| `archived` — new listings start `draft` (expert-only on #21); `live` makes them browsable + purchasable on #6 (#21 labels these "Active"); `archived` retires them (hidden from the marketplace) |
| Name | varchar(120) |  | e.g. "1:1 Strength Programming" |
| Description | varchar(200) |  | short summary on the card subtitle + #6.2 |
| DetailBullets | text[] |  | "What's included" list on #6.2 |
| Category | slug | FK → ExpertCategory | topic/domain (a `categoryId`); drives the category-chip filter on the Service Listings sub-tab |
| Fulfillment | enum |  | `workout_plan` \| `nutrition` \| `review` \| `session` \| `coaching` — what the deliverable *is*; independent of Category. Drives the #23.1 composer's section labels |
| PricingModel | enum |  | `one_time` \| `recurring` |
| PriceCents | int |  | stored in cents to avoid float-money rounding; `0` = unset (draft) |
| DurationWeeks | int | nullable | plan/programme length; null for one-off calls/reviews |
| AcceptingBookings | bool |  | master switch — off pauses new bookings without archiving |
| AvailableDays | int[] |  | days 1–7 (Mon–Sun) the expert takes sessions; empty = none set yet |
| MaxConcurrentClients | int | nullable | cap on simultaneous active clients; null = uncapped / n-a |
| ResponseTime | enum |  | `24h` \| `48h` \| `72h` booking response SLA |
| CreatedAt | timestamp |  | |

> **SavedExpert merged onto `User.followedExpertIds` in schema-v2.** The follow-expert heart (#6 / #6.1) is now a `followedExpertIds: string[]` (expert userIds) on `User`, not a junction table. Only the current user's follows are surfaced in the mock, so a plain id list is enough (the `followedAt` timestamp wasn't shown anywhere). A production relational schema would still use a `(userId, expertUserId)` junction. **Distinct from the user-to-user `Follow` entity in Social** (which is mutual friendship) — this is a one-way bookmark of marketplace experts.

### ServiceRequest
A client's request for an `ExpertService`. Lifecycle: lands as `pending` when the client sends it from #6.2 with a goal message → expert reads it on #22 Requests and either accepts (`accepted` — engagement is now ongoing on #23 Clients / #14 My Plans) or declines (`cancelled`) → expert marks the engagement done on #23.1 (`completed` — stamps `CompletedAt`; unlocks the client's Submit Review CTA on #6.2). The `accepted → completed` transition is expert-only (real coaching platforms do this so a client can't rage-quit out to leave a bad review). No payment integration in the mock.

*Introduced by: #6.2 Service Detail*

| Attribute | Type | Key | Notes |
|---|---|---|---|
| ServiceRequestID | UUID | PK | |
| UserID | UUID | FK → User | the requester (client) |
| ExpertServiceID | UUID | FK → ExpertService | |
| ExpertUserID | UUID | FK → User | denormalised — fast "who did I request from?" lookup |
| QuotedPriceCents | int |  | the service's price snapshotted at request time so later price changes don't backfill (no payment in the mock) |
| Status | enum |  | `pending` (awaiting expert) \| `accepted` (ongoing engagement) \| `completed` (wrapped up; review unlocked) \| `cancelled` (declined) |
| RequestMessage | text | required | the client's goal note sent with the request (enforced on #6.2); the expert reads it on #22 before accepting |
| RequestedAt | timestamp |  | |
| CompletedAt | timestamp | nullable | stamped when the expert marks the engagement complete on #23.1; null otherwise |

### Deliverable
A document an expert sends a client in reply to their request — the "info handover". Generic **sections → items** shape so one form fits every `Fulfillment` (a workout plan = Week/Day → exercises, a diet = Day → meals, a review = Lift → feedback, a coaching outline, etc.). Authored by the expert on #23.1 Client Detail; the client reads it on #6.2. Many per engagement (follow-ups over time).

*Introduced by: #23.1 Client Detail*

| Attribute | Type | Key | Notes |
|---|---|---|---|
| DeliverableID | UUID | PK | |
| ServiceRequestID | UUID | FK → ServiceRequest | the engagement it belongs to |
| Title | varchar(120) |  | e.g. "8-Week Strength Plan", "Week 3 adjustment" |
| Note | text | nullable | optional cover note shown above the sections |
| Sections | json |  | `DeliverableSection[]` — `{ heading, items: WorkoutSegment[] }`; reuses the `label / detail / sub` shape |
| CreatedAt | timestamp |  | |

---

### Feedback
User-submitted feedback from #13.5 Submit Feedback. The admin reads + triages it on **#28 Platform Monitoring** (`Status` flips `new` → `reviewed`). One-way — no reply back to the user (that's what `ContactMessage` is for).

*Introduced by: #13.5 Submit Feedback*

| Attribute | Type | Key | Notes |
|---|---|---|---|
| FeedbackID | UUID | PK | |
| UserID | UUID | FK → User | the submitter |
| Category | enum |  | `bug` \| `feature_request` \| `general` |
| Body | text |  | required, non-empty after `trim()`, **≥10 chars** enforced client-side |
| Status | enum |  | `new` \| `reviewed` — admin triage state (#28); `new` on submit |
| CreatedAt | timestamp |  | wall-clock at submit |

---

### ContactMessage
A message submitted via the **Contact form on the external marketing website** (open to anyone — registered users *and* visitors). The form collects only name, email, and the message itself, so there's no `UserID` FK linking the submitter to a `User` row. Rows arrive for the admin to read + answer on **#28 Platform Monitoring / #28.1**: the admin records a `Response` and flips `Status` `open` → `resolved`. Unlike `Feedback`, this is two-way (the response is the reply emailed back to the submitter).

*Introduced by: #28 Platform Monitoring*

| Attribute | Type | Key | Notes |
|---|---|---|---|
| ContactMessageID | UUID | PK | |
| SubmitterName | varchar(120) |  | captured by the marketing-site form |
| SubmitterEmail | varchar(254) |  | captured by the marketing-site form |
| Message | text |  | the body of the contact form |
| Status | enum |  | `open` \| `resolved` — `open` until the admin resolves it |
| Response | text | nullable | the admin's reply, recorded on #28.1; null while open |
| CreatedAt | timestamp |  | |

---

### Subscription
**1-to-1 specialization of `User`** for the premium role — analogous to `FitnessProfile` (athletes) and `ExpertProfile` (experts). `UserID` is both PK and FK to `User` (shared-key pattern), so the schema enforces "one Subscription per user, ever" at the type level. Premium users have a row; Free users don't. Created when #16 Upgrade's "Start Premium" runs (mock — production gates on a real payment webhook); managed on #13.6 Subscription Management. `startPremium` upserts; cancel/resume toggle `status`. Single product in v1 (a `Tier` column would matter once additional plans exist — annual / family / student).

*Introduced by: #13.6 Subscription Management*

| Attribute | Type | Key | Notes |
|---|---|---|---|
| UserID | UUID | PK, FK → User | shared key (1:1 specialization for premium role) |
| Status | enum |  | `active` \| `cancelled` \| `past_due` |
| StartedAt | timestamp |  | feeds the mock billing-history list on #13.6 |
| RenewsAt | timestamp |  | next billing date; after cancel, the access-until date shown on #13.6 |
| PriceCents | int |  | 999 = $9.99 |

---

## Relationships

| From | Verb | To | Multiplicity |
|---|---|---|---|
| User | Has | ConnectedDevice | 1 — * |
| User | Has | FitnessProfile | 1 — 0..1 (specialization; athletes only) |
| FitnessProfile | Sets | FitnessGoal | 1 — * |
| FitnessProfile | Prefers | WorkoutType (id list on `preferredWorkoutTypeIds`) | * — * |
| FitnessProfile | Has | HealthTag (id list on `healthTagIds`; diet / allergy / injury split by HealthTag.Kind) | * — * |
| FitnessProfile | Has | FitnessPlan | 1 — * |
| FitnessPlan | Targets | FitnessGoal | * — 1 (required — plan must target a goal) |
| FitnessPlan | Contains | PlannedWorkout | 1 — * |
| PlannedWorkout | OfType | WorkoutType | * — 1 |
| FitnessProfile | Records | WorkoutSession | 1 — * |
| WorkoutSession | OfType | WorkoutType | * — 1 |
| WorkoutSession | Executes | PlannedWorkout | * — 1 (optional; null for free-form) |
| WorkoutSession | SourcedFrom | ConnectedDevice | * — 1 (optional) |
| WorkoutSession | Logs | ExerciseLog | 1 — * (non-cardio sessions log exercises per set) |
| User | Authors | Post | 1 — * (workout-share, challenge-result + level-up kinds) |
| Post | Wraps | WorkoutSession | * — 0..1 (when `kind = 'workout_share'`) |
| Post | Wraps | Challenge | * — 0..1 (when `kind = 'challenge_result'`; auto-created when a `best_of` Challenge's deadline passes) |
| Post | Has | PostLike | 1 — * |
| Post | Has | PostComment | 1 — * |
| User | Likes | Post (via PostLike) | * — * |
| User | Comments | Post (via PostComment) | * — * |
| User | Friends | User (via Follow) | * — * (mutual; stored as a pair of A→B + B→A rows) |
| User | Creates | Challenge | 1 — * (CreatedByUserID; null = system / curator-seeded) |
| Challenge | Has | ChallengeParticipant | 1 — * |
| User | JoinsAs | Challenge (via ChallengeParticipant) | * — * |
| ChallengeParticipant | Submits | WorkoutSession | * — 0..1 (null for accumulator challenges; for best_of: the participant's chosen entry, null until picked) |
| Challenge | OfType | WorkoutType | * — 0..1 (optional filter; null = any type qualifies) |
| User | Has | ExpertProfile | 1 — 0..1 (specialization for `role = 'expert'`) |
| ExpertProfile | TaggedWith | ExpertCategory (via Specialties) | * — * (slug refs; admin curates the catalog on #29) |
| ExpertService | InCategory | ExpertCategory | * — 1 (slug ref) |
| ExpertProfile | SubmitsForVerification | ExpertVerificationDocument | 1 — * (identity + certifications reviewed on #27.1) |
| ExpertProfile | ReceivesReviews | ExpertReview | 1 — * (client reviews shown on #6.1) |
| ServiceRequest | RatedBy | ExpertReview | 1 — 0..1 (one review per completed engagement) |
| ExpertProfile | Offers | ExpertService | 1 — * |
| User | Requests | ExpertService (via ServiceRequest) | * — * |
| ServiceRequest | OfferedBy | User | * — 1 (denormalised expertUserId; same user as ExpertService.ExpertUserID at request time) |
| ServiceRequest | Has | Deliverable | 1 — * (the expert's reply docs for that engagement) |
| User | Submits | Feedback | 1 — * |
| — | — | ContactMessage | (submitted on the external marketing-site form; no User link — admin answers on #28.1) |
| User | Has | Subscription | 1 — 0..1 (specialization for premium role; shared-key on UserID) |

---

## Screen → data map

Quick lookup for which screens touch which entities. Grows as we add screens.

| # | Screen | Reads | Writes |
|---|---|---|---|
| 1 | Splash | server-side session check (not modelled), `User.Role` | none modelled in-app |
| 2 | Login | `User` by `Email` → password check server-side (not modelled) | server issues a session (Remember-me sets its expiry; not modelled in-app) |
| 4 | Forgot password | `User` by `Email` (silently succeed if no match) | reset link handled server-side / via email — no token modelled in-app |
| 5 | Dashboard | `User.FirstName` + `User.AvatarUrl` (header); active `FitnessPlan` + today's `PlannedWorkout` + joined `WorkoutType` (Today card — same derivation as #7); current-user `WorkoutSession` rows in the Mon-Sun window (This Week stats); active `FitnessGoal` (`AchievedAt IS NULL`) + `FitnessProfile.weightKg` (Active Goal card); current-user `ServiceRequest` rows joined to `ExpertService` + `User` (My Purchases list) | none — read-only digest; navigation hands writes off to #9 / #13.2 / #6.2 |
| 13 | Profile | `User.FirstName`, `User.LastName`, `User.Username`, `User.AvatarUrl`, `User.Role` (for Go Premium visibility) | Log out clears the server session (not modelled) |
| 14 | Account Settings | `User.FirstName`, `User.LastName`, `User.Username`, `User.Email`, `User.PreferredUnits` | `User.PreferredUnits` (instant on Segmented change); triggers Change Password → reset-link flow |
| 13.1 | Fitness Profile | `FitnessProfile` (by UserID): DateOfBirth, Sex, HeightCm, WeightKg, ActivityLevel, TrainingExperience, `healthTagIds`, `preferredWorkoutTypeIds`; `User.PreferredUnits`; the `WorkoutType` + `HealthTag` catalogs (`HealthTag` filtered by `Kind` into Diet / Allergies / Injuries) | Training Experience writes via `upsertFitnessProfile`; each Preferred-Workouts / Diet / Allergies / Injuries chip toggles its id in the matching array on FitnessProfile via `toggleUserWorkoutPreference` / `toggleUserHealthTag` (no Save step). Body-metrics rows are display-only for now. |
| 13.2 | Fitness Goals | `User.PreferredUnits` (for weight display); active `FitnessGoal` for current user (`AchievedAt IS NULL`) | on Save: upserts active `FitnessGoal` row — patches if one exists, inserts new with the form's values if not |
| 15 | Notifications | `User.notificationPrefs` (type → enabled map), grouped by category + filtered by audience | each toggle flip writes `notificationPrefs[typeKey]` on `User` |
| 7 | Train | active `FitnessPlan` (`IsActive = true`) for current user; today's `PlannedWorkout` derived from it; `ConnectedDevice` rows for status chip | none directly |
| 7.1 | Connected Devices | all `ConnectedDevice` for user | add / rename / remove / toggle `IsActive` |
| 8 | Plan Detail | one `FitnessPlan` + all its `PlannedWorkout` rows (ordered by week, day, OrderIndex) | on Regenerate: replaces the active plan (insert new + soft-deactivate old); increments `RegeneratedCount` |
| 9 | Active Workout | active `WorkoutSession` (created on Start); pulls live data from associated `ConnectedDevice` if set | updates session metrics in real time; sets `EndedAt` on Finish |
| 10 | Workout Summary | the just-ended `WorkoutSession` | sets `FeelRating`, `Notes`; on Share-to-Social toggle: `createWorkoutSharePost` inserts a `Post` of kind `workout_share` |
| 12 | History | current user's ended `WorkoutSession` rows (Free monthly cap applied); joined `WorkoutType` + `ExerciseLog` for the metric strips | none directly |
| 12.1 | History Detail | one `WorkoutSession` (incl. its `trackPoints` for the cardio graphs) + joined `WorkoutType` + `PlannedWorkout` + `FitnessPlan` + all its `ExerciseLog`; the `Post` of kind `workout_share` for this session if shared | edit mode: updates `WorkoutSession.{customName, feelRating, notes, ...}`; `Post` toggle calls `createWorkoutSharePost` / `deletePost`; description textarea calls `updatePostBody` |
| 11 | Social | **Community tab**: `Post` rows filtered by follow graph + current user (ordered `CreatedAt DESC`), `User` for author lookup, `Follow` for feed scoping, `WorkoutSession` + `WorkoutType` + `ExerciseLog` for workout-share posts, `Challenge` + `ChallengeParticipant` for challenge-result posts, `PostLike` count + own-like check, `PostComment` count. **Challenges tab**: `Challenge` + `ChallengeParticipant` (for joined set, participant counts, leaderboard — covers both accumulator and best_of via the unified entity); all `WorkoutSession` rows in each challenge's window (live progress + ranking); `WorkoutType` for type filter + creation modal. | `togglePostLike` on heart tap; `followUser` / `unfollowUser` on Add Friend / Unfriend; `joinChallenge` / `leaveChallenge` from Challenge Detail; `createChallenge` from + button modal (any visibility × any metricKind) |
| 11.1 | Post Detail | one `Post` (by `PostID`); its author via `findUserById`; all `PostLike` + `PostComment` rows for the post; for `workout_share`: linked `WorkoutSession` + `WorkoutType` + `ExerciseLog`; for `challenge_result`: linked `Challenge` + `ChallengeParticipant` + each participant's submitted `WorkoutSession` (for best_of ranking) | `togglePostLike` heart; `addPostComment` reply; `deletePostComment` own-comment ×; `updatePostBody` author-row pencil; share button is fire-and-forget (no DB write) |
| 11.2 | User Profile | one `User` (by `UserID`); `User.bio` for the About section; all `WorkoutSession` rows for that user with `EndedAt IS NOT NULL` (Workouts + Active-days counts; bypasses Free monthly cap on purpose, like #13); all `Follow` rows (for `isFriend` + Friends count); their `Post` rows (Recent Posts list) + per-post `PostLike`/`PostComment` counts; for each post's title: linked `WorkoutSession` + `WorkoutType` OR `Challenge` | `followUser` / `unfollowUser` on the toggle |
| 11.3 | Challenge Detail | one `Challenge`; all `ChallengeParticipant` rows for it; every participant's `WorkoutSession` rows in the window (full leaderboard + user's progress); `WorkoutType` for the auto-derived "How it works" copy | `joinChallenge` / `leaveChallenge` from the pinned footer button |
| 6 | Experts | all `User` rows with `role = 'expert'` joined to `ExpertProfile` (shared-key); all `ExpertService` rows for the Service Listings sub-tab + the per-expert `N services · from $X` footer; `User.followedExpertIds` (drives the heart-toggle state on each card) | `toggleFollowExpert(currentUserId, expertUserId)` — heart tap on any ExpertCard |
| 6.1 | Expert Detail | one `User` + their `ExpertProfile` (by `UserID` route param); all `ExpertService` rows for `expertUserId = target.userId`; `User.followedExpertIds` (for the `isFollowed` heart state) | `toggleFollowExpert(currentUserId, expertUserId)` on the heart toggle |
| 6.2 | Service Detail | one `ExpertService` (by `ExpertServiceID` route param); the joined expert `User` + `ExpertProfile` for the mini card; the current user's `ServiceRequest` rows (to find an existing non-cancelled request) + their `Deliverable` rows for it | `requestService({userId, expertServiceId, message})` on Send in the request modal — inserts a `pending` `ServiceRequest` row with the required goal message |
| 13.5 | Submit Feedback | `User.UserID` (attached to the new row as FK) | on Submit: inserts a new `Feedback` row via `submitFeedback({ userId, category, body })` — trimmed body, fresh `feedbackId` + `createdAt` |
| 16 | Upgrade to Premium | `User.Role` | `startPremium` (mock): sets `User.Role = 'premium'` + creates an active `Subscription` |
| 13.6 | Subscription Management | current user's `Subscription` (status, renewsAt, priceCents, startedAt for mock billing history) | `cancelSubscription` / `resubscribe` — toggle `Subscription.status` |

---

## Deferred / open questions

These get resolved as their owning screens come up — listed here so we don't forget:

- **Role-specific extension tables** — `PremiumSubscription`, `AdminProfile` etc. Introduced when their screens land. ~~`ExpertProfile`~~ landed with #6 Experts ✓
- ~~**`UserProfile`** (height, weight, fitness goal, DOB, gender)~~ — resolved: the fitness-side fields landed on `FitnessProfile` (#13.1); the public Bio paragraph lives on `User` (#11.2) ✓
- **OAuth / 2FA** — out of scope for v1.
- **First-run detection scope** — currently modelled on `User` (per-account). If the team wants per-device first-run, we'd add a `Device` table or rely on client-side storage. Going server-side for now to honour "everything in the database."
