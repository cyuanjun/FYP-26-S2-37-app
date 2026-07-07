# Bug Log

Every defect found while building the prototype — symptom, root cause, fix, and where it landed.
Feeds the PTD testing section and the module-testing evidence (11 Jul). Severity: **H**igh
(blocks a core flow / data integrity), **M**edium (feature wrong but workaround exists),
**L**ow (cosmetic/dev-experience). Last updated **10 Jul 2026** (+ BUG-018–021, July build-out; OPEN-004 resolved).

## Fixed — application code

| ID | Found | Sev | Area | Symptom | Root cause | Fix | Commit |
|---|---|---|---|---|---|---|---|
| BUG-001 | 10 Jun | H | Backend/auth | Login returned GoTrue 500 "Database error querying schema" for seeded test users | Manually-inserted `auth.users` rows had NULL token columns; GoTrue expects empty strings | Seed scripts write `''` (not NULL) for all token columns | seed scripts |
| BUG-002 | 10 Jun | H | Backend/RPC | `end_workout_session` failed: `operator does not exist: date - bigint` | Postgres can't subtract a bigint from a date; week-offset arithmetic untyped | Cast: `((rn - 1) * 7)::int` | `20260610120000` migration |
| BUG-003 | 10 Jun | M | Capture UI | Activity pill on Active Workout showed "—" instead of the default type | Selected-type read before the default assignment ran | Compute default inside the data callback | `bb11530` |
| BUG-004 | 10 Jun | M | Train UI | Train screen didn't match spec #7 (type picker placement, missing cards) — user-reported | Screen built from memory instead of the spec file | Rebuilt strictly to 07-train.md / 09-active-workout.md | `bb11530` |
| BUG-005 | 10 Jun | **H** | Backend/signup | **Fresh signups could not record workouts** (FK violation) | `handle_new_user` trigger created `profiles` but not the `fitness_profiles` row that `workout_sessions.user_id` references | Trigger extended + backfill migration; verified with throwaway signup | `20260610130000` migration |
| BUG-006 | 10 Jun | L | Architecture | Splash screen read the auth gateway directly (BCE violation) | Shortcut during phase 1 | Route through `currentUserIdProvider` (Control seam) | `65aa1b9` |
| BUG-007 | 10 Jun | L | Architecture | `SocialPlatform` enum defined inside a gateway (entity-layer type in a boundary) | Layering slip | Moved to `lib/entities/enums.dart` | `65aa1b9` |
| BUG-008 | 11 Jun | L | History UI | SESSIONS tile sat higher than its neighbours when it had no delta row | Delta occupied its own line only when present | Delta rendered inline beside the value | `1177cb5` |
| BUG-009 | 12 Jun | **H** | History/tiering | **Free monthly history cap was not enforced** — banner claimed "June only" but the query returned everything (audit finding) | `listEndedSessions` had no date bound; banner was cosmetic | Query-level `from = 1st of month` for Free; Premium unbounded; Profile lifetime stats use a separate uncapped query (per #13 spec) | `bfe1018` |
| BUG-010 | 12 Jun | M | Capture/data | Calories were never computed for live sessions — History showed "—"; only seeded rows had values (audit finding) | Client never sent `calories_burned`; RPC field went unused | MET-based `WorkoutType.estimateCalories` (entity rule) wired into `end()` | `d589826` |
| BUG-011 | 12 Jun | L | Plans UI | Weekly plan chips rendered Fri→Wed→Mon (reversed) | supabase-dart `.order()` defaults to **descending** — not ascending like supabase-js | Explicit `ascending: true` on all plan/catalog orderings | `41c7b90` |
| BUG-012 | 12 Jun | L | Onboarding UI | Height/weight dialog showed a bare floating cursor — input field invisible until typed (user-reported) | Default `TextField` on a dark theme with no decoration | Shared boxed dialog: filled background, focus outline, unit suffix | `aa69c51` |
| BUG-013 | 12 Jun | M | Privacy/RLS | Custom workout types and custom health tags (allergies/injuries) were visible to **all** users | Catalog read policies were `using (true)` | RLS: `not is_custom or created_by_user_id = auth.uid()`; proven with two-user token probe | `55242af` |
| BUG-014 | 12 Jun | L | Devices UI | Mock-pairing sheet overflowed by 1.7px (debug stripe) | Fixed-height column on small sheet | Wrapped in `SingleChildScrollView` | `7e8ede1` |
| BUG-015 | 12 Jun | **H** | Capture/stability | **App ANR'd ("isn't responding") while ending a workout**; UI froze, session left un-ended | Geolocator stream cancel wedged on the platform channel when a stale Flutter engine held the location service ("There is still another flutter engine connected"); `end()` blocked behind it | Sensor cancels made non-blocking (`unawaited`); `end()` reordered to do network reads before platform-channel teardown; orphaned session cleaned up | `7e8ede1` |
| BUG-016 | 12 Jun | L | Plan Detail | Analyzer: regenerate callback shadowed `plan`, referenced before declaration | Variable shadowing | Renamed to `newPlan` (caught pre-commit) | `1ec02d5` |
| BUG-017 | 29 Jun | M | Plans/tiering | Free plan regeneration never reset monthly — blocked forever after 1 regen; Plan Detail showed a nonsensical "2 of 1 free regenerations used" | `regeneratedCount` is a **cumulative** counter and the gate was `>= 1` (lifetime), but the spec + confirm-dialog copy say **1/month** | Month-aware gate (blocked only when the active plan's `startedAt` falls in the current calendar month, so it resets each month); raw count replaced with a "1 per month" description; disabled button greyed | `73c578c` |
| BUG-018 | 7 Jul | M | Marketplace/data | Service Detail's "✓ Reviewed" footer never flipped after submitting a review; Riverpod kept serving retained stale state | `expert_reviews` has `UNIQUE(service_request_id)`, so PostgREST embeds it **one-to-one (object, not list)**; the `as List?` cast threw inside the row parser | Parser accepts both shapes: `reviewed: reviews is Map \|\| (reviews is List && reviews.isNotEmpty)` | `b8f6648` |
| BUG-019 | 8 Jul | **H** | Notifications | Scheduled reminders **never fired**: everything landed ~8 h off (next morning) despite correct in-app times | `flutter_local_notifications` builds iOS triggers from the TZDateTime's **wall-clock components**, so scheduling UTC instants with `tz.UTC` silently shifts by the zone offset; `tz.local` defaulted to UTC | `flutter_timezone` resolves the device IANA zone at init (`tz.setLocalLocation`); schedule with `TZDateTime.from(when, tz.local)`; zone SEQ-logged | `24f90e7` |
| BUG-020 | 9 Jul | M | Forms UI | Dropdown menu items rendered near-invisible (white-ish text on the tinted menu surface) in the service editor | `DropdownButtonFormField` menu inherited an unsuitable text style from the theme on `surface`-tinted popups | Explicit `AppTypography.body` + `dropdownColor: AppColors.surface` on the dropdowns | `6939f69` |
| BUG-021 | 10 Jul | L | History UI | The Free month-cap **empty state** can't pull-to-refresh (the `RefreshIndicator` wraps only the non-empty list) — stale data stays until a tab switch/restart | Early-return empty-state branch sits outside the `RefreshIndicator` subtree | Accepted for now (in-app flows invalidate on mutation; only out-of-band DB edits notice) — tracked as OPEN-005 | — |

## Fixed — requirements / documentation defects

| ID | Found | Sev | Area | Symptom | Resolution | Commit |
|---|---|---|---|---|---|---|
| DOC-001 | 12 Jun | M | Tracker honesty | US15 marked ✅ while the cap was unenforced; US16 note claimed calories worked; US26 note hid that platform buttons share one OS sheet (code-audit findings) | Statuses corrected, then the two real gaps fixed in code (BUG-009/010) | `f214f3c` |
| DOC-002 | 12 Jun | M | Requirements | US10 misread as in-app splash auto-login; actually the **website's** login-gated app download (user-clarified) | Diagram redrawn as the website flow; tracker re-scoped; splash work credited to US07 | `c85baa5` |
| DOC-003 | 12 Jun | M | Requirements | US18 wording vs locked AI scope conflict (basic plan rule-based vs "AI-assisted") | Resolved the other way: **Free gets basic AI plans** (matches SRS + WBS); C4 rename cancelled; engineering realigned | `7b949a6` |
| DOC-004 | 12 Jun | L | Diagrams | 6 of 58 (now 59 after the US18a/b split) sequence diagrams failed to render | Semicolons in Mermaid message labels act as statement separators | Replaced with dashes; noted in folder README | `4cfecd0` |
| DOC-005 | 12 Jun | M | Sequence diagrams | TDM v5 §6 diagrams wrong (team-confirmed); first regeneration used «Gateway» where the sample PTD convention expects «Entity» | All 58 redrawn to sample 3-lifeline B-C-E form with correct names; gateway truth kept as a note | `9969744` |
| DOC-006 | 12 Jun | L | Reporting | Assistant reported "118 tests" after the devices cluster; authoritative `flutter test` count was 107 | Arithmetic slip in the summary, not in CI — all docs now cite 107 | consistency pass |

## Environment / process issues (not app defects)

| ID | Found | Area | Symptom | Cause / handling |
|---|---|---|---|---|
| ENV-001 | 10 Jun | Android build | flutter_local_notifications failed to compile | Needs core-library desugaring → enabled in `build.gradle.kts` |
| ENV-002 | 11–12 Jun | Emulator | DevFS "Lost connection" deploy failures; sluggish UI; software GL warnings | Emulator memory pressure on this host; recover via cold reboot of the AVD. **Still a risk** — long demo sessions on the emulator can jank (see BUG-015) |
| ENV-003 | 12 Jun | Emulator | Couldn't type with the Mac keyboard | AVD had `hw.keyboard=no` → set to `yes` in `~/.android/avd/pixel_api35.avd/config.ini` |
| ENV-004 | 12 Jun | Process | App relaunch raced ahead of an SQL flag reset; force-stop silently hit a stale package id (`com.example.…` vs `com.wiseworkout.…`) | Sequence DB writes before relaunch; use the real `applicationId` |
| ENV-005 | 10–12 Jun | Process | iOS simulator showed stale builds after Android-only deploys | `flutter run` targets one device — standing rule: redeploy iOS after every change batch |
| ENV-006 | 8 Jul | Platform | iOS 26 **simulator** never delivers scheduled calendar-trigger local notifications (OS holds `pending=1` forever); display path itself works (`simctl push` renders the same payload) | Simulator limitation, not app code — verify delivery on a physical device / Android emulator (demo-script checklist) |
| ENV-007 | 10 Jul | Platform | iOS simulator has no Bluetooth — real BLE scan yields nothing | By design the pairing sheet falls back to the demo device list; real-device pass pending (same session as ENV-006) |

## Investigated — verified NOT bugs

| Date | Observation | Verdict |
|---|---|---|
| 12 Jun | 78-second run saved only 8 kcal (expected ~13) | Formula exact: the profile weight was 40 kg (user-entered) → 9.8 × 40 × 78/3600 = 8.49 → 8 ✓ |
| 12 Jun | Premium `suggest-plan` returned `no_active_goal` | Correct behaviour — that account hadn't completed onboarding/goal yet |
| 12 Jun | Plan Detail says "NO WORKOUT SCHEDULED TODAY" on Friday | Correct — the generated week trains Mon/Thu/Sat; rest-day CTA is intentionally disabled |

## Open / watch items

| ID | Area | Item |
|---|---|---|
| OPEN-001 | Stability | Emulator memory pressure can still jank long sessions (ENV-002); prefer a real device or freshly-booted AVD for demos |
| OPEN-002 | Duplication | Week-boundary, cardio-slug, and XP constants exist in both Dart and SQL/Edge Functions — drift risk; extract shared constants when convenient |
| OPEN-003 | Capture | Sessions started from a plan don't yet link `planned_workout_id` (the +10 planned-XP bonus is unreachable) |
| ~~OPEN-004~~ | Devices | ✅ Resolved 10 Jul — real `BleHeartRateSource` built (GATT 0x180D, real scan in the pairing sheet, `ble_remote_id`); HealthKit remains the follow-on (`90db630`) |
| OPEN-005 | History UI | Month-cap empty state lacks pull-to-refresh (BUG-021) — wrap the empty branch in the RefreshIndicator when convenient |
