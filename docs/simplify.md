# Simplify — code map + redundancy notes

**Purpose:** (1) a plain-English map of how the code works, for the presentation; (2) a prioritized list of redundancy / simplification candidates. **No code has been changed** — this is an analysis log. Findings were produced by a codebase sweep and then **verified by grep**; corrected false positives are listed at the end.

---

## Part 1 — How the code works (presentation overview)

### The one rule: BCE (Boundary–Control–Entity)
`Actor ─ Boundary ─ Control ─ Entity`. A screen never touches the database or an entity directly — a **Control** always mediates. Riverpod makes this idiomatic: a Control is a Notifier/provider the UI watches.

| Layer | Folder | What it is |
|---|---|---|
| **Entity** | `lib/entities/` | ~10 freezed models (Profile, FitnessProfile, WorkoutSession, WorkoutType, FitnessGoal, FitnessPlan, PlannedWorkout, HealthTag, ConnectedDevice) + enums. They also own **data rules** (see below). |
| **Control** | `lib/controls/` | One class/provider **per use case** (Authenticate, ActiveWorkout, GeneratePlan, WorkoutHistory, SetFitnessGoal, ManageConnectedDevice, …). |
| **Boundary — UI** | `lib/boundaries/ui/` | ~25 screens grouped by cluster (auth · home · history · workout · train · profile · onboarding; experts/social are placeholders). |
| **Boundary — gateways** | `lib/boundaries/gateways/` | Adapters to external systems: Supabase (Auth/Profile/Fitness/Plan/Workout/Social/Feedback/Device), `AiGateway` (Edge Functions), `WorkoutDataSource` (sensors), `SocialShareGateway` (OS share). |
| **Cross-cutting** | `lib/core/`, `lib/router/`, `lib/main.dart` | Theme (palette/typography), `format.dart` (display formatters), `seq_log.dart` (debug traceability), `env.dart` (config); go_router with auth redirects; app bootstrap. |

### Data flow (one round-trip)
A screen calls a **Control** method → the Control logs a `SEQ` line, pulls user context from `AuthGateway`, then delegates to a **gateway** → the gateway runs a Supabase query / RPC / Edge Function → result returns to the Control → the Control updates state and **invalidates** the relevant providers so the UI refetches. Example: *end workout* → `ActiveWorkout.end()` bundles metrics → `WorkoutGateway.endSession()` calls the `end_workout_session` Postgres RPC (atomically writes the session + computes XP/level/streak) → returns → history cache invalidated.

### Data-owned rules (logic that lives in entities, not screens)
- **XP / level / streak** — `FitnessProfile` (`level = floor(XP/200)+1`, `xpIntoLevel`).
- **Calories** — `WorkoutType.estimateCalories()` = `MET × weight × hours` (MET table per discipline; sex-based default weight). See [reference/calorie-estimation.md](reference/calorie-estimation.md).
- **Cardio vs strength** — `WorkoutType.isCardio` (slug set).
- **Goal shape** — `FitnessGoal` (`hasTarget`, `unitFor`, `defaultTargetFor`, `stepFor`, timeline options).
- **Tiering** — Free history capped to the current month at the **query level** (`workout_history.dart`); Premium = lifetime.

### Backend (`supabase/`)
7 additive migrations (schema → RLS → `end_workout_session` RPC → signup trigger → onboarding column → custom-catalog privacy → admin WITH CHECK hardening), `seed.sql` (catalogs) + `seed-demo.sql` (Mia/free + Alex/premium), and 2 Edge Functions (`suggest-plan`, `summarise-progress`, each OpenAI → Gemini → deterministic-stub fallback). The sweep found **no redundant migrations, RLS policies, or seed data**.

---

## Part 2 — Redundancy / simplification candidates

Ordered by impact. Each is a **candidate** — verify before acting (the code is committed and green at 112 tests).

> **✅ ALL ITEMS APPLIED 6 Jul 2026 (H1–H8, M1–M5, L1–L5).** `common/` now holds `StatTile`, `AppCard`, `StatusBadge`, `PremiumCta` (+ pre-existing `AvatarButton`); `core/theme/app_buttons.dart` (button styles), `core/strings.dart` (`isBlank`), `fmtCompactNum` in `core/format.dart`; gateway/entity DRY fixes (`_deactivatePriorPlan`, `FitnessGoal.hasTargetFor`, `Profile.isFree`, `FitnessProfile.ageFrom`); `intl` removed. Several items were false positives or already done — see Corrections. Net ≈ −250 lines; 112 tests green throughout; every step verified on the iOS simulator.

### 🔴 High value — the UI has no shared widget library
The single biggest source of duplication: every screen inlines its own cards, stat tiles, badges and button styles (the only shared widgets today are `avatar_button.dart` + `later_sprint_tab.dart` + the `profile_widgets.dart` helpers). Extracting a handful of shared widgets into `lib/boundaries/ui/common/` would remove **~250–350 lines** and lock in visual consistency.

| # | Pattern | Count | Example locations | Suggested extract |
|---|---|---|---|---|
| H1 | **Stat/metric tile** (label+value, metric colour, optional delta/dim) | **6 near-identical helpers** | `history_screen.dart` `_statTile` (~279) & `_cell` (~485) · `profile_screen.dart` `_stat` (~185) · `workout_summary_screen.dart` `_Stat` (~187) · `active_workout_screen.dart` `_Metric` (~261) · `history_detail_screen.dart` `_stat` (~223) | one `StatTile(label, value, {delta, dim, color})` |
| H2 | **Card wrapper** (`Container` + `surface` + `radius 14/16` + optional `faint` border) | **11+** | `train_screen.dart` (×3) · `dashboard_tab.dart` · `history_screen.dart` · `forgot_password_screen.dart` · `fitness_goals_screen.dart` · `onboarding_flow.dart` · … | one `AppCard({child, padding, radius, border})` |
| H3 | **Button styles** (`OutlinedButton.styleFrom` accent/danger + `Size.fromHeight(52)` + radius) | **10+** | `train_screen.dart` (×2) · `my_plans_screen.dart` · `plan_detail_screen.dart` · `account_settings_screen.dart` · `workout_summary_screen.dart` (share buttons) · `profile_screen.dart` (LOG OUT) · `history_detail_screen.dart` (DELETE) | `AppButtonStyles.outlinedAccent()/outlinedDanger()` in `core/theme/` |
| H4 | **Badge/pill** (small rounded `Container`: PREMIUM/ACTIVE/CONNECTED/EDITING/CUSTOM) | **7** | `history_screen.dart` (×2) · `train_screen.dart` · `connected_devices_screen.dart` · `history_detail_screen.dart` · `profile_widgets.dart` · `profile_screen.dart` | one `Badge({text, bg, border})` |
| H5 | **Section header** (label + optional action) | **3** (2 private + 1 public) | `train_screen.dart` `_SectionHeader` · `my_plans_screen.dart` `_SectionLabel` · `profile_widgets.dart` **`SectionLabel`** (public) | ⚠️ partly false positive (see Corrections): only `_SectionLabel` was a true dup (✅ deleted); `_SectionHeader` has a *text* action, public has *icon* + uppercase/letterSpacing — not interchangeable |
| H6 | **Stepper** (value +/- buttons) | **2** | `fitness_goals_screen.dart` `_Stepper` · `onboarding_flow.dart` `_miniStepper` | ⚠️ mostly false positive: the two share only the number-formatting line (✅ extracted as `fmtCompactNum` in `core/format.dart`); layouts/typography are disjoint — a merged widget would be two render paths stapled together |
| H7 | **Select chip / period pill** | **3** (1 public + 2 inline) | `profile_widgets.dart` **`SelectChip`** (public) · `history_screen.dart` Day/Week/Month pills · `fitness_goals_screen.dart` timeline chips | ⚠️ false positive (see Corrections): the pills differ in padding + unselected colours, the timeline "chips" are 48px **circles** — adopting `SelectChip` is a redesign, not a dedupe |
| H8 | **Premium upsell CTA** (now gold, but 4 one-off styles) | **4** | `profile_screen.dart` (GO PREMIUM) · `history_screen.dart` (×2) · `plan_detail_screen.dart` | one `PremiumUpsell({text, onTap, variant})` |

### 🟡 Medium — duplicated logic (DRY)
- **M1 — Plan deactivation repeated.** ✅ extracted `_deactivatePriorPlan(userId)` in `plan_gateway.dart`, called from both `insertPlan()` and `setActivePlan()`.
- **M2 — `hasTarget` computed in two places.** ✅ the rule now lives once as static `FitnessGoal.hasTargetFor(goal)` (the control only has the enum, so the instance getter delegates); `set_fitness_goal.dart` uses it.
- **M3 — Free-role check repeated.** ✅ added `Profile.isFree`; both checks in `workout_history.dart` use it (unused `enums.dart` import dropped).
- **M4 — Manual enum→DB conversion.** ✅ resolved as **keep + document**: json_serializable's enum maps are library-private to the entity `.g.dart`, unreachable from a control building a raw values map — the `toDb` extensions are the explicit adapter, now commented as such.
- **M5 — Trim-empty validation repeated.** ✅ `String?.isBlank`/`isNotBlank` extension in `core/strings.dart`, applied at **10 sites** (5 controls + 3 gateways + forgot-password + onboarding). Gotcha found: the old explicit `!= null` checks null-promoted; one call site needed `name!` after the guard. (`submit_feedback` keeps its own ≥10-char rule — different validation, not a dup.)

### 🟢 Low — cleanup (verify first)
- **L1 — Confirmed-unused entity members**: `ConnectedDevice.providesHeartRate` ✅ deleted (dead getter). `FitnessProfile.ageAt()` turned out **not dead** — the Fitness Profile screen *duplicated* its math on a draft DOB; ✅ fixed the other way: static `FitnessProfile.ageFrom(dob, now)` owns the rule, `ageAt` delegates, the screen's private `_age()` deleted. ⚠️ `FitnessProfile.restingHeartRate` and `HealthTag.createdByUserId` are unread **but map to DB columns** — left in place.
- **L2 — Unused dependency:** `intl` ✅ removed. `cupertino_icons` is the default Flutter icon font (harmless to keep).
- **L3 — `seq_log.dart` debugPrint** — ✅ already done before this pass: `SeqLog.msg` was already wrapped in `if (kDebugMode)`. False positive.
- **L4 — `SocialShareGateway.shareTo(platform, …)`** — ✅ already documented: the class doc comment states `platform` is carried for future per-app deep-linking. False positive; param kept (named platforms are a grading requirement).
- **L5 — `fill_ptd.py`** ✅ header note added marking it manual-only (not in the `expand_ptd.py → build_ptd_v1format.py` pipeline).

---

## Corrections — false positives from the sweep (NOT issues)
The automated pass flagged these; grep/`analyze` disproved them. Listed so they don't end up in the presentation as "problems":
- **`'connected_device_id': ?connectedDeviceId`** (`workout_gateway.dart:47`) is **valid Dart 3** (null-aware map entry — omits the key when null = manual entry). `flutter analyze` is clean. *Not a syntax error.*
- **`ActivityLevel.description` (7×)** and **`PrimaryGoal.descriptor` (6×)** enum extensions **are used**. *Not dead.*
- **`json_annotation`** shows "0 hand-written imports" but is **required by generated `.g.dart`** code. *Do not remove.* **`flutter_local_notifications`** is **intentionally pre-added** (CLAUDE.md, for pending US19–21). *Not dead — deferred.*
- **Thin pass-through controls** (`SaveWorkoutDetails`, `SummariseProgress`, `CreateWorkoutSharePost`, …) are **intentional BCE** (one control per use case = a clean, testable seam), **not** redundancy.
- **Per-test `ProviderContainer` factories** look duplicated but each overrides a different gateway set — appropriate, not redundant.
- **H5/H7 were partly false positives** (found during the 6 Jul apply pass): `train_screen._SectionHeader` takes a *text* action ('VIEW PLANS ›') while public `SectionLabel` takes an *icon* and adds uppercase + letterSpacing — swapping changes pixels/behaviour. History's Day/Week/Month pills differ from `SelectChip` in padding and unselected colours, and Fitness Goals' timeline selectors are 48px circles. Only `my_plans._SectionLabel` (a private class wrapping one `Text`) was a true dup — deleted in favour of inline `Text`.

---

## Suggested order if you ever act on this
~~1. **H1 + H2 + H3** … 4. **L1/L2** …~~ — **✅ all applied 6 Jul 2026** in exactly this order (H1→H8, then M1→M5, then L1→L5), one item at a time, each verified with `flutter analyze` + the 112-test suite + an on-simulator relaunch before moving on.

The codebase is otherwise clean: no orphan files, no commented-out blocks, no TODO/FIXME markers, no redundant migrations/policies/tests.
