# Wise Workout — Module Test Report

**Date:** 10 Jul 2026 · **Milestone:** 11 Jul module testing · **Build:** `main` (feature-complete, 221 automated tests)
**Environment:** Flutter stable · iPhone 17 Pro simulator (iOS 26) + Pixel API 35 emulator · Supabase local stack (ports 55321-9) mirroring hosted
**Reproduce:** `cd app && flutter analyze && flutter test` (all automated cases) · manual procedures in [../prototype-demo-guide.md](../prototype-demo-guide.md) §4

Two evidence streams per module:
- **Automated** — the `flutter test` suite (entity/control/gateway level; controls run against fake gateways so each module is tested in isolation — module testing in the BCE sense).
- **Manual** — the walkthrough procedures executed on the simulator during the July build-out, with results recorded in [../STATUS.md](../../STATUS.md) dated entries and defects in [bug-log.md](bug-log.md).

## Summary

| # | Module | Automated cases | Result | Manual procedure | Result |
|---|---|---|---|---|---|
| ENT | Entity rules (domain logic) | 78 | ✅ 78/78 pass | — (rules exercised via every manual flow) | — |
| AUTH | Auth & profile cluster | 26 | ✅ 26/26 pass | Guide §A, §F, §F2 (login/logout/reset, profile edits, photo upload) | Pass (10 Jul) |
| CAP | Capture & devices | 24 | ✅ 24/24 pass | Guide §B, §B2 + manual-entry flow | Pass (BLE: sim-safe path; hardware pass pending) |
| HIST | History & analytics | 14 | ✅ 14/14 pass | Guide §C, §G + search cases | Pass (9 Jul) |
| PLAN | Plans & AI | 15 | ✅ 15/15 pass | Guide §A2 (onboarding → AI plan), regen cap | Pass (earlier sprints) |
| SOC | Social & challenges | 30 | ✅ 30/30 pass | Guide §E + Social walkthrough + History→post link | Pass (9–10 Jul, 5-athlete feed) |
| MKT | Marketplace & expert portal | 17 | ✅ 17/17 pass | Expert walkthrough: 2-account lifecycle + portal editors | Pass (7–9 Jul, DB checked) |
| PREM | Premium subscription | 6 | ✅ 6/6 pass | Guide §H (upgrade → #13.6 → reset) | Pass (8 Jul, DB checked) |
| NOTIF | Notifications (rule engine) | 11 | ✅ 11/11 pass | #13.4 UPCOMING + pending=1 + push-payload display | Pass (delivery = device pass pending) |
| | **Total** | **221** | **✅ 221/221 pass** | | |

All 221 automated cases pass on the report date (0 failures, `flutter analyze` clean).

## Requirements traceability

| Module | User stories covered |
|---|---|
| ENT — Entity rules (domain logic) | US14–US18, US32–US35 (rules layer) |
| AUTH — Auth & profile cluster | US07–US09, US11, US14, US26, US31 hooks |
| CAP — Capture & devices | US12, US13, wearable scope (#7.1) |
| HIST — History & analytics | US15–US17, US33; #12 §Search |
| PLAN — Plans & AI | US18, US36–US37 |
| SOC — Social & challenges | US22–US25 |
| MKT — Marketplace & expert portal | US27–US29, US45–US51 |
| PREM — Premium subscription | US31, US40 |
| NOTIF — Notifications (rule engine) | US19–US21 |

Full story-level status lives in [../requirements/user-stories.md](../../requirements/user-stories.md) (36 ✅ · 6 🟨 · 22 ⬜; the ⬜ remainder is website/admin-web scope outside this app).

## Known limitations (declared, not defects)

- **Calendar-trigger notification delivery** and **real-BLE pairing** cannot be exercised on the iOS simulator — schedules (OS `pending=1`), banner rendering (`simctl push`), and the sim-safe scan fallback are verified; one physical-device pass remains before the final demo.
- Payment is **simulated by scope** (price fields, no gateway) — asserted in tests as payload snapshots, not charges.
- AI functions degrade to a deterministic stub when keys/models fail — the fallback path is what the automated tests pin.

---

## Automated cases by module

### ENT — Entity rules (domain logic) (78 cases)

*Scope:* XP/level/streak math, MET calories, month-cap windows, ACWR/HR-zone/personal-best analytics, Training Effect formula, price/label formatting, feed/challenge/marketplace entity invariants.

| ID | Test file | Case | Result |
|---|---|---|---|
| ENT-01 | `workout_test` | WorkoutType.isCardio cardio slugs are cardio | ✅ |
| ENT-02 | `workout_test` | WorkoutType.isCardio non-cardio slugs are not cardio | ✅ |
| ENT-03 | `workout_test` | WorkoutType.isCardio unknown slug is not cardio (negative) | ✅ |
| ENT-04 | `workout_test` | WorkoutSession.isEnded false while in progress | ✅ |
| ENT-05 | `workout_test` | WorkoutSession.isEnded true once ended | ✅ |
| ENT-06 | `workout_test` | WorkoutSession.fromJson maps snake_case + nullable metrics | ✅ |
| ENT-07 | `workout_test` | WorkoutType.estimateCalories (MET × kg × hours) 30-min run at 70 kg ≈ 343 kcal (positive) | ✅ |
| ENT-08 | `workout_test` | WorkoutType.estimateCalories (MET × kg × hours) null weight + unknown sex falls back to the 70 kg default | ✅ |
| ENT-09 | `workout_test` | WorkoutType.estimateCalories (MET × kg × hours) null weight uses a sex-based default (male heavier than female) | ✅ |
| ENT-10 | `workout_test` | WorkoutType.estimateCalories (MET × kg × hours) defaultWeightKg: male 70, female 55, other/null 70 | ✅ |
| ENT-11 | `workout_test` | WorkoutType.estimateCalories (MET × kg × hours) explicit weight overrides the sex-based default | ✅ |
| ENT-12 | `workout_test` | WorkoutType.estimateCalories (MET × kg × hours) lower-MET discipline burns less for the same session | ✅ |
| ENT-13 | `workout_test` | WorkoutType.estimateCalories (MET × kg × hours) zero duration → 0 kcal (negative) | ✅ |
| ENT-14 | `workout_test` | WorkoutType.estimateCalories (MET × kg × hours) unknown slug falls back to moderate 4.0 MET | ✅ |
| ENT-15 | `fitness_test` | FitnessProfile level/XP rules level = floor(XP/200)+1; bar = XP mod 200 | ✅ |
| ENT-16 | `fitness_test` | FitnessProfile level/XP rules 0 XP is level 1 with an empty bar | ✅ |
| ENT-17 | `fitness_test` | FitnessProfile level/XP rules ageAt handles pre/post birthday correctly | ✅ |
| ENT-18 | `fitness_test` | FitnessProfile level/XP rules ageAt is null without a DOB (negative) | ✅ |
| ENT-19 | `fitness_test` | FitnessProfile level/XP rules fromJson maps snake_case row | ✅ |
| ENT-20 | `fitness_test` | FitnessGoal rules unit mapping per goal | ✅ |
| ENT-21 | `fitness_test` | FitnessGoal rules defaults derive from current weight | ✅ |
| ENT-22 | `fitness_test` | FitnessGoal rules stepper increments: ±1 kg, ±5 minutes | ✅ |
| ENT-23 | `fitness_test` | FitnessGoal rules fromJson maps an active lose_weight goal | ✅ |
| ENT-24 | `profile_test` | Profile.displayName full name when both present | ✅ |
| ENT-25 | `profile_test` | Profile.displayName first or last alone | ✅ |
| ENT-26 | `profile_test` | Profile.displayName falls back to username then email | ✅ |
| ENT-27 | `profile_test` | Profile.isPremium true only for premium role | ✅ |
| ENT-28 | `profile_test` | Profile.fromJson maps snake_case columns + enums | ✅ |
| ENT-29 | `profile_test` | Profile.fromJson defaults preferred_units to metric when absent | ✅ |
| ENT-30 | `social_test` | FeedPost.fromRow decodes post, author, session and computes counts (positive) | ✅ |
| ENT-31 | `social_test` | FeedPost.fromRow likedByMe false when I have not liked (negative) | ✅ |
| ENT-32 | `social_test` | FeedPost.fromRow level_up rows carry level and no session | ✅ |
| ENT-33 | `social_test` | Post kind helpers exactly one is true per kind | ✅ |
| ENT-34 | `challenge_test` | Challenge window rules isActive inside the window, isPast at/after endedAt (boundaries) | ✅ |
| ENT-35 | `challenge_test` | Challenge window rules dayXofY clamps before start and after end | ✅ |
| ENT-36 | `challenge_test` | Challenge metric rules metricsFor partitions the 7 metrics 4/3 with no overlap | ✅ |
| ENT-37 | `challenge_test` | Challenge metric rules lowerWins only for fastestTime | ✅ |
| ENT-38 | `challenge_test` | Challenge metric rules formatValue renders per metric (m→km, s→mm:ss, counts) | ✅ |
| ENT-39 | `challenge_test` | ChallengeSummary.progressToTarget clamps to 0..1 and handles missing target (negative) | ✅ |
| ENT-40 | `expert_test` | ExpertService price formatting whole dollars drop cents; fractional keep 2dp | ✅ |
| ENT-41 | `expert_test` | ExpertService price formatting recurring services get /mo | ✅ |
| ENT-42 | `expert_test` | ServiceRequest footer rules cancelled frees the footer; everything else blocks (negative) | ✅ |
| ENT-43 | `expert_test` | ServiceRequest footer rules deliverables visible once accepted or completed | ✅ |
| ENT-44 | `expert_test` | ServiceRequest footer rules review unlocks only when completed and not yet reviewed | ✅ |
| ENT-45 | `expert_test` | ExpertSummary directory rules min price + from label | ✅ |
| ENT-46 | `expert_test` | ExpertSummary directory rules query matches name/title; category matches specialties | ✅ |
| ENT-47 | `expert_test` | DeliverableSection.fromLines one trimmed item per non-blank line | ✅ |
| ENT-48 | `advanced_analytics_test` | sessionLoad an hour at moderate effort (no HR) scores 5 | ✅ |
| ENT-49 | `advanced_analytics_test` | sessionLoad higher HR intensity raises the score (Karvonen) | ✅ |
| ENT-50 | `advanced_analytics_test` | sessionLoad clamped to 1–10 | ✅ |
| ENT-51 | `advanced_analytics_test` | computeAcwr thin history yields the not-enough state (negative) | ✅ |
| ENT-52 | `advanced_analytics_test` | computeAcwr steady training lands in the sustainable band | ✅ |
| ENT-53 | `advanced_analytics_test` | computeAcwr an acute spike lands in overreaching | ✅ |
| ENT-54 | `advanced_analytics_test` | weeklyBuckets zero-fills empty weeks so the chart is honest | ✅ |
| ENT-55 | `advanced_analytics_test` | weeklyBuckets aggregates minutes, calories, and avg HR per week | ✅ |
| ENT-56 | `advanced_analytics_test` | hasAcuteSpike flags a >50% week-over-week load jump | ✅ |
| ENT-57 | `advanced_analytics_test` | computeHrZones buckets whole sessions by avg HR and excludes sub-Z1 time | ✅ |
| ENT-58 | `advanced_analytics_test` | computeHrZones no HR data at all yields all-zero shares (negative) | ✅ |
| ENT-59 | `advanced_analytics_test` | computePersonalBests finds distance, pace, duration, and day-streak bests | ✅ |
| ENT-60 | `advanced_analytics_test` | computePersonalBests empty history yields dashes-and-zero (negative) | ✅ |
| ENT-61 | `training_effect_test` | no avg HR → null (the unavailable state, negative) | ✅ |
| ENT-62 | `training_effect_test` | spec formula: 30-min at 133 bpm, no age → Very High boundary check | ✅ |
| ENT-63 | `training_effect_test` | longer duration raises the score at the same HR | ✅ |
| ENT-64 | `training_effect_test` | age tightens estimated max HR (220 − age) | ✅ |
| ENT-65 | `training_effect_test` | bands map 1–3/4–6/7–8/9–10 | ✅ |
| ENT-66 | `training_effect_test` | aerobic/anaerobic split: easy effort is all aerobic | ✅ |
| ENT-67 | `training_effect_test` | near-max effort shifts the split anaerobic | ✅ |
| ENT-68 | `format_test` | fmtDuration mm:ss under an hour | ✅ |
| ENT-69 | `format_test` | fmtDuration h:mm:ss over an hour | ✅ |
| ENT-70 | `format_test` | fmtKm metres to 2dp km | ✅ |
| ENT-71 | `format_test` | fmtPace returns placeholder for ~zero distance (negative path) | ✅ |
| ENT-72 | `format_test` | fmtPace computes mm:ss per km | ✅ |
| ENT-73 | `format_test` | iconForSlug known slugs | ✅ |
| ENT-74 | `format_test` | iconForSlug unknown slug falls back (negative) | ✅ |
| ENT-75 | `format_test` | relativeDay today / yesterday | ✅ |
| ENT-76 | `format_test` | relativeDay older shows weekday d mon | ✅ |
| ENT-77 | `format_test` | relativeDay UTC timestamps compare by LOCAL date (regression: 01:40 SGT bug) | ✅ |
| ENT-78 | `format_test` | startOfWeek returns Monday 00:00 | ✅ |

### AUTH — Auth & profile cluster (26 cases)

*Scope:* Login/logout/reset flows, fitness profile + goals upserts, units & notification prefs, account settings, feedback submission, onboarding completion.

| ID | Test file | Case | Result |
|---|---|---|---|
| AUTH-01 | `authenticate_test` | signIn success → no error state (positive) | ✅ |
| AUTH-02 | `authenticate_test` | signIn failure → AsyncError (negative) | ✅ |
| AUTH-03 | `authenticate_test` | signOut delegates to the gateway | ✅ |
| AUTH-04 | `profile_cluster_test` | UpdateFitnessProfile save commits the patch via the gateway (positive) | ✅ |
| AUTH-05 | `profile_cluster_test` | UpdateFitnessProfile save surfaces gateway failure (negative) | ✅ |
| AUTH-06 | `profile_cluster_test` | UpdateFitnessProfile addCustomTag inserts and returns the tag (positive) | ✅ |
| AUTH-07 | `profile_cluster_test` | UpdateFitnessProfile addCustomTag rejects empty names (negative) | ✅ |
| AUTH-08 | `profile_cluster_test` | SetFitnessGoal lose_weight goal writes kg target + timeline (positive) | ✅ |
| AUTH-09 | `profile_cluster_test` | SetFitnessGoal maintain_fitness nulls target + timeline (positive) | ✅ |
| AUTH-10 | `profile_cluster_test` | SetFitnessGoal weekly commitment out of 1–7 is rejected before the gateway (negative) | ✅ |
| AUTH-11 | `profile_cluster_test` | SetFitnessGoal gateway failure → false + error state (negative) | ✅ |
| AUTH-12 | `profile_cluster_test` | SubmitFeedback valid body submits trimmed (positive) | ✅ |
| AUTH-13 | `profile_cluster_test` | SubmitFeedback under 10 chars after trim never reaches the gateway (negative) | ✅ |
| AUTH-14 | `profile_cluster_test` | SubmitFeedback signed out → false (negative) | ✅ |
| AUTH-15 | `profile_cluster_test` | SubmitFeedback gateway failure → false (negative) | ✅ |
| AUTH-16 | `profile_cluster_test` | ManageNotificationPrefs build merges stored prefs over defaults (positive) | ✅ |
| AUTH-17 | `profile_cluster_test` | ManageNotificationPrefs setEnabled writes the whole map (positive) | ✅ |
| AUTH-18 | `profile_cluster_test` | UpdateAccountSettings setPreferredUnits writes instantly (positive) | ✅ |
| AUTH-19 | `profile_cluster_test` | UpdateAccountSettings setPreferredUnits is a no-op when signed out (negative) | ✅ |
| AUTH-20 | `profile_cluster_test` | UpdateAccountSettings saveName writes the onboarding name fallback (positive) | ✅ |
| AUTH-21 | `profile_cluster_test` | UpdateAccountSettings saveName rejects empty first name (negative) | ✅ |
| AUTH-22 | `profile_cluster_test` | UpdateAccountSettings sendChangePasswordEmail success/failure | ✅ |
| AUTH-23 | `profile_cluster_test` | RequestPasswordReset send delegates to the gateway (positive) | ✅ |
| AUTH-24 | `profile_cluster_test` | RequestPasswordReset gateway failure is swallowed — same "sent" outcome (anti-enumeration) | ✅ |
| AUTH-25 | `profile_cluster_test` | addCustomWorkoutType inserts a custom type and returns it (positive) | ✅ |
| AUTH-26 | `profile_cluster_test` | addCustomWorkoutType rejects empty names (negative) | ✅ |

### CAP — Capture & devices (24 cases)

*Scope:* Start/end session lifecycle (atomic RPC payloads), device pairing incl. BLE remote-id passthrough, GATT heart-rate packet parsing, manual entry (backdate, no-device, cardio-only distance).

| ID | Test file | Case | Result |
|---|---|---|---|
| CAP-01 | `active_workout_test` | start → running, inserts session for current user, starts sensors (positive) | ✅ |
| CAP-02 | `active_workout_test` | live sensor metrics update state | ✅ |
| CAP-03 | `active_workout_test` | end cardio → distance in metrics, returns RPC result, resets state (positive) | ✅ |
| CAP-04 | `active_workout_test` | end → calorie estimate uses profile weight when set (positive) | ✅ |
| CAP-05 | `active_workout_test` | end non-cardio → no distance in metrics (negative for distance) | ✅ |
| CAP-06 | `active_workout_test` | pause/resume are no-ops while idle (negative) | ✅ |
| CAP-07 | `active_workout_test` | pause then resume toggles status | ✅ |
| CAP-08 | `connected_device_test` | connectedDevicesProvider seeds the phone-sensors virtual device once, pinned first (positive) | ✅ |
| CAP-09 | `connected_device_test` | connectedDevicesProvider signed out → empty, nothing seeded (negative) | ✅ |
| CAP-10 | `connected_device_test` | ManageConnectedDevice pair adds a wearable; activeWearableProvider finds it (positive) | ✅ |
| CAP-11 | `connected_device_test` | ManageConnectedDevice pair rejects empty names (negative) | ✅ |
| CAP-12 | `connected_device_test` | ManageConnectedDevice inactive wearable is not selected as the capture source | ✅ |
| CAP-13 | `connected_device_test` | ManageConnectedDevice phone sensors cannot be removed (negative) | ✅ |
| CAP-14 | `connected_device_test` | WearableHrSource (simulated BLE) hr curve: rest at start, working zone after ramp | ✅ |
| CAP-15 | `connected_device_test` | WearableHrSource (simulated BLE) avg/max derive from recorded samples | ✅ |
| CAP-16 | `connected_device_test` | WearableHrSource (simulated BLE) no samples → null stats (negative) | ✅ |
| CAP-17 | `connected_device_test` | ActiveWorkout with a paired wearable session links to wearable, HR lands in end metrics, sync stamped | ✅ |
| CAP-18 | `connected_device_test` | ActiveWorkout with a paired wearable no wearable → session links to phone sensors, no HR in metrics | ✅ |
| CAP-19 | `ble_heart_rate_source_test` | GATT Heart Rate Measurement parsing (0x2A37) uint8 format (flags bit0 = 0) | ✅ |
| CAP-20 | `ble_heart_rate_source_test` | GATT Heart Rate Measurement parsing (0x2A37) uint16 little-endian format (flags bit0 = 1) | ✅ |
| CAP-21 | `ble_heart_rate_source_test` | GATT Heart Rate Measurement parsing (0x2A37) malformed packets return null (negative) | ✅ |
| CAP-22 | `ble_heart_rate_source_test` | GATT Heart Rate Measurement parsing (0x2A37) avg/max derive from collected samples like the simulated source | ✅ |
| CAP-23 | `log_manual_workout_test` | manual entry: no device, backdated start, distance for cardio | ✅ |
| CAP-24 | `log_manual_workout_test` | non-cardio entries never send distance (negative) | ✅ |

### HIST — History & analytics (14 cases)

*Scope:* Month-capped vs lifetime history windows, hidden-earlier detection, Premium search filter, AI summary control (fallback + goal context).

| ID | Test file | Case | Result |
|---|---|---|---|
| HIST-01 | `workout_history_test` | historyProvider is empty when signed out (negative) | ✅ |
| HIST-02 | `workout_history_test` | historyProvider returns the user's ended sessions (positive) | ✅ |
| HIST-03 | `workout_history_test` | Free history is capped at the current calendar month (positive) | ✅ |
| HIST-04 | `workout_history_test` | Premium history is lifetime — no cap (positive) | ✅ |
| HIST-05 | `workout_history_test` | DeleteWorkoutSession delegates to the gateway | ✅ |
| HIST-06 | `history_search_test` | filterSessionsByQuery (#12 Premium search) blank query returns the list untouched | ✅ |
| HIST-07 | `history_search_test` | filterSessionsByQuery (#12 Premium search) matches the resolved workout-type name, case-insensitive | ✅ |
| HIST-08 | `history_search_test` | filterSessionsByQuery (#12 Premium search) matches the custom session name | ✅ |
| HIST-09 | `history_search_test` | filterSessionsByQuery (#12 Premium search) no matches yields an empty list (negative) | ✅ |
| HIST-10 | `summarise_progress_test` | ProgressSummary.fromJson stub model is not AI-generated (negative) | ✅ |
| HIST-11 | `summarise_progress_test` | ProgressSummary.fromJson real model is AI-generated (positive) | ✅ |
| HIST-12 | `summarise_progress_test` | ProgressSummary.fromJson missing fields default safely | ✅ |
| HIST-13 | `summarise_progress_test` | SummariseProgress returns the gateway summary (positive) | ✅ |
| HIST-14 | `summarise_progress_test` | SummariseProgress propagates gateway errors (negative) | ✅ |

### PLAN — Plans & AI (15 cases)

*Scope:* AI plan generation both tiers, strict schema validation, regeneration cap (Free 1/month), plan/plan-detail providers.

| ID | Test file | Case | Result |
|---|---|---|---|
| PLAN-01 | `generate_plan_test` | buildPlanSkeleton rule honours commitment days and generates the full timeline (positive) | ✅ |
| PLAN-02 | `generate_plan_test` | buildPlanSkeleton rule preferences are a contract — only preferred types scheduled | ✅ |
| PLAN-03 | `generate_plan_test` | buildPlanSkeleton rule experience scales duration (beginner < advanced) | ✅ |
| PLAN-04 | `generate_plan_test` | buildPlanSkeleton rule week 4 is a recovery week (lighter than week 3) | ✅ |
| PLAN-05 | `generate_plan_test` | buildPlanSkeleton rule commitment days clamp to 1–7 (negative input) | ✅ |
| PLAN-06 | `generate_plan_test` | GeneratePlan free user → basic AI plan persisted (positive) | ✅ |
| PLAN-07 | `generate_plan_test` | GeneratePlan premium user → AI-personalised plan (positive) | ✅ |
| PLAN-08 | `generate_plan_test` | GeneratePlan AI down → rule-based fallback still delivers a plan (resilience) | ✅ |
| PLAN-09 | `generate_plan_test` | GeneratePlan no active goal → error, nothing persisted (negative) | ✅ |
| PLAN-10 | `generate_plan_test` | Saved plans plansProvider lists the signed-in user plans | ✅ |
| PLAN-11 | `generate_plan_test` | Saved plans SelectFitnessPlan activates a saved plan | ✅ |
| PLAN-12 | `generate_plan_test` | CompleteOnboarding marks onboarding done for the signed-in user (positive) | ✅ |
| PLAN-13 | `generate_plan_test` | CompleteOnboarding no-op when signed out (negative) | ✅ |
| PLAN-14 | `generate_plan_test` | Profile.needsOnboarding null onboardingCompletedAt → wizard required | ✅ |
| PLAN-15 | `generate_plan_test` | Profile.needsOnboarding completed → straight to the shell | ✅ |

### SOC — Social & challenges (30 cases)

*Scope:* Feed assembly (friends+self), likes/comments, mutual-friend RPC pairs, share-post creation + session→post link, challenge join/leave/create + live leaderboards.

| ID | Test file | Case | Result |
|---|---|---|---|
| SOC-01 | `social_feed_test` | ViewSocialFeed (feedProvider) scopes the feed to self + friends (positive) | ✅ |
| SOC-02 | `social_feed_test` | ViewSocialFeed (feedProvider) signed out → empty feed, gateway untouched (negative) | ✅ |
| SOC-03 | `social_feed_test` | TogglePostLike not liked → likePost, and the feed refetches | ✅ |
| SOC-04 | `social_feed_test` | TogglePostLike already liked → unlikePost (negative path of the toggle) | ✅ |
| SOC-05 | `social_feed_test` | AddPostComment adds a comment for the current user (positive) | ✅ |
| SOC-06 | `social_feed_test` | AddPostComment blank body is rejected before the gateway (negative) | ✅ |
| SOC-07 | `social_feed_test` | DeletePostComment deletes by comment id | ✅ |
| SOC-08 | `social_feed_test` | UpdatePostBody passes the new caption through | ✅ |
| SOC-09 | `social_feed_test` | ListPostComments (postCommentsProvider) scoped to the requested post | ✅ |
| SOC-10 | `social_feed_link_test` | resolves the share post for a shared session (#12.1 link) | ✅ |
| SOC-11 | `social_feed_link_test` | unshared session resolves null — no link rendered (negative) | ✅ |
| SOC-12 | `social_feed_link_test` | signed-out resolves null without a fetch (negative) | ✅ |
| SOC-13 | `manage_friends_test` | FollowUser / UnfollowUser FollowUser calls addFriend and refreshes friend state (positive) | ✅ |
| SOC-14 | `manage_friends_test` | FollowUser / UnfollowUser UnfollowUser removes and the feed refetches (scope changed) | ✅ |
| SOC-15 | `manage_friends_test` | searchUsersProvider passes the query and returns matches (positive) | ✅ |
| SOC-16 | `manage_friends_test` | searchUsersProvider blank query short-circuits (negative) | ✅ |
| SOC-17 | `manage_friends_test` | userProfileStatsProvider assembles workouts / friends / activeDays | ✅ |
| SOC-18 | `manage_friends_test` | isFriendProvider self is never a friend (guard) | ✅ |
| SOC-19 | `manage_friends_test` | userPostsProvider scoped to the requested author | ✅ |
| SOC-20 | `share_workout_test` | CreateWorkoutSharePost inserts a workout_share post with caption for current user (positive) | ✅ |
| SOC-21 | `share_workout_test` | CreateWorkoutSharePost caption can be omitted (null body) | ✅ |
| SOC-22 | `share_workout_test` | ShareWorkoutToSocial shares the given text to the chosen platform (positive) | ✅ |
| SOC-23 | `share_workout_test` | SocialPlatform labels are the named platforms | ✅ |
| SOC-24 | `challenges_test` | ViewChallenges (challengesProvider) assembles counts, joined state, myValue and named standings | ✅ |
| SOC-25 | `challenges_test` | ViewChallenges (challengesProvider) signed out → empty (negative) | ✅ |
| SOC-26 | `challenges_test` | JoinChallenge / LeaveChallenge join records (id, user) and the list refetches as joined | ✅ |
| SOC-27 | `challenges_test` | JoinChallenge / LeaveChallenge leave removes participation | ✅ |
| SOC-28 | `challenges_test` | CreateChallenge forwards fields and the new challenge appears joined (auto-join) | ✅ |
| SOC-29 | `challenges_test` | CreateChallenge signed out → no-op (negative) | ✅ |
| SOC-30 | `challenges_test` | challengeSummaryProvider derives one challenge by id from the list | ✅ |

### MKT — Marketplace & expert portal (17 cases)

*Scope:* Browse/search experts, request lifecycle (snapshot price, footer states), expert inbox gating, accept/decline/deliver/complete, service create-vs-update dispatch, professional-info payload.

| ID | Test file | Case | Result |
|---|---|---|---|
| MKT-01 | `browse_experts_test` | BrowseExperts providers expertsProvider + derived family lookup share one fetch | ✅ |
| MKT-02 | `browse_experts_test` | BrowseExperts providers categories come from the gateway (active only, by contract) | ✅ |
| MKT-03 | `browse_experts_test` | ToggleFollowExpert adds when not followed (positive) | ✅ |
| MKT-04 | `browse_experts_test` | ToggleFollowExpert removes when already followed (negative path) | ✅ |
| MKT-05 | `service_requests_test` | RequestService creates a request with the snapshotted price (positive) | ✅ |
| MKT-06 | `service_requests_test` | RequestService blank message rejected before the gateway (negative) | ✅ |
| MKT-07 | `service_requests_test` | activeRequestForServiceProvider (footer selection) cancelled requests free the footer; others occupy it | ✅ |
| MKT-08 | `service_requests_test` | SubmitReview forwards to the RPC and refreshes the directory (positive) | ✅ |
| MKT-09 | `service_requests_test` | SubmitReview invalid rating or blank body rejected (negative) | ✅ |
| MKT-10 | `expert_requests_test` | incomingRequestsProvider expert sees the inbox (positive) | ✅ |
| MKT-11 | `expert_requests_test` | incomingRequestsProvider non-expert gets an empty inbox without a fetch (negative) | ✅ |
| MKT-12 | `expert_requests_test` | transitions accept / decline / complete forward the request id | ✅ |
| MKT-13 | `expert_requests_test` | SendDeliverable builds one section from lines; note optional (positive) | ✅ |
| MKT-14 | `expert_requests_test` | SendDeliverable blank title rejected; empty section omitted (negative) | ✅ |
| MKT-15 | `publish_service_test` | PublishService empty id creates, non-empty id updates | ✅ |
| MKT-16 | `publish_service_test` | UpdateExpertProfile writes the descriptive fields for the current user | ✅ |
| MKT-17 | `publish_service_test` | service enum wire values dbValue matches the Postgres enum spellings | ✅ |

### PREM — Premium subscription (6 cases)

*Scope:* Upgrade RPC invocation + provider refresh, non-free rejection, cancel/resume transitions, synthesised billing-history rules.

| ID | Test file | Case | Result |
|---|---|---|---|
| PREM-01 | `start_premium_test` | StartPremium runs the RPC and refreshes profile + subscription (positive) | ✅ |
| PREM-02 | `start_premium_test` | StartPremium a non-free account cannot upgrade (negative) | ✅ |
| PREM-03 | `start_premium_test` | ManageSubscription cancel then resume writes the status transitions | ✅ |
| PREM-04 | `start_premium_test` | Subscription entity rules priceLabel formats the settled price | ✅ |
| PREM-05 | `start_premium_test` | Subscription entity rules billingDates synthesises one charge per month, most recent first | ✅ |
| PREM-06 | `start_premium_test` | Subscription entity rules billingDates caps at the 12 most recent charges | ✅ |

### NOTIF — Notifications (rule engine) (11 cases)

*Scope:* Plan-day nudges (Free fixed / Premium adaptive hour), late nudge + evening cutoff, missed-workout, inactivity threshold + overdue path, Premium-only rest alert, disabled-prefs negative.

| ID | Test file | Case | Result |
|---|---|---|---|
| NOTIF-01 | `schedule_reminders_test` | daily_reminder (US19) one nudge per plan day in the next week, Free at 08:00 | ✅ |
| NOTIF-02 | `schedule_reminders_test` | daily_reminder (US19) Premium adapts the hour to the median session start (adaptive) | ✅ |
| NOTIF-03 | `schedule_reminders_test` | daily_reminder (US19) no nudge today when a session is already logged (negative) | ✅ |
| NOTIF-04 | `schedule_reminders_test` | daily_reminder (US19) passed hour becomes a near-term late nudge | ✅ |
| NOTIF-05 | `schedule_reminders_test` | missed_workout (US19) fires when yesterday was a plan day with no session | ✅ |
| NOTIF-06 | `schedule_reminders_test` | missed_workout (US19) silent when yesterday was trained (negative) | ✅ |
| NOTIF-07 | `schedule_reminders_test` | inactivity_reminder (US20) fires 3 days after the last session at 10:00 | ✅ |
| NOTIF-08 | `schedule_reminders_test` | inactivity_reminder (US20) an overdue alert moves to a near-term fire | ✅ |
| NOTIF-09 | `schedule_reminders_test` | rest_alert (US21, Premium) 3 sessions in 3 days → recovery alert tomorrow 08:00 | ✅ |
| NOTIF-10 | `schedule_reminders_test` | rest_alert (US21, Premium) Free never gets a rest alert even when toggled on (negative) | ✅ |
| NOTIF-11 | `schedule_reminders_test` | disabled prefs schedule nothing (negative) | ✅ |

---

## Manual procedures (evidence index)

Executed on the iOS simulator against the local stack during the July build-out; each links to the dated STATUS entry that records the run. Step-level "do this → see this" scripts are the demo guide §4 sections.

| ID | Procedure | Evidence (STATUS entry) | Result |
|---|---|---|---|
| MAN-01 | Core loop: login → capture → summary → history → AI summary → share | vertical slice + 6 Jul social entries | ✅ |
| MAN-02 | Wearable pairing → live HR → avg/max persisted (§B2) | capture entries; BLE sheet re-verified 10 Jul | ✅ |
| MAN-03 | Manual entry: backdated run, +75 XP, HR-dash row | 9 Jul manual-entry entry | ✅ |
| MAN-04 | Free caps & locks: month cap, search lock → #16, regen cap | 8–9 Jul entries | ✅ |
| MAN-05 | Premium upgrade → live flip → #13.6 cancel/resume → revert | 8 Jul premium entry (DB checked each step) | ✅ |
| MAN-06 | Premium History search: filter, aggregates narrowing, miss state | 9 Jul search entry | ✅ |
| MAN-07 | #12.2 Advanced Analytics: ACWR band, trends, zones, bests | 9 Jul #12.2 entry | ✅ |
| MAN-08 | Training Effect card: band/score/split on #12.1 | 10 Jul finishing-pass entry | ✅ |
| MAN-09 | Social: 5-voice feed, like/comment, leaderboard, History→post link | 6 Jul + 9–10 Jul entries | ✅ |
| MAN-10 | Marketplace lifecycle (2 accounts): request → accept → deliver → complete → review; aggregates in DB | 7 Jul experts entry | ✅ |
| MAN-11 | Expert portal: triage → #23.1 deliver/complete; service editor publish-live; professional info (column-lock verified in SQL) | 7–9 Jul entries | ✅ |
| MAN-12 | Notifications: permission → schedule (pending=1) → UPCOMING strip; display via push payload | 8 Jul notifications entry | ✅ (delivery = device pass) |
| MAN-13 | Avatar upload: gallery → storage object → renders everywhere | 10 Jul finishing-pass entry | ✅ |

## Sign-off

| Role | Name | Date | Signature |
|---|---|---|---|
| Executed by | | | |
| Reviewed by | | | |
