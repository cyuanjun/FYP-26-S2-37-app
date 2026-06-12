# Wise Workout — Prototype Demo & Test Guide

How to run, demo, and verify the **vertical-slice prototype**. Last updated **10 Jun 2026**.

The prototype implements the app's demo spine end-to-end:

> **log in → record a phone-GPS workout → see it in history → get an AI progress summary → share it**

Everything below is real: a Flutter app (BCE architecture) talking to a live Supabase backend
(Postgres + Auth + RLS + an Edge Function), verified on Android and iOS.

---

## 1. What's built

| Area | Built | Notes |
|---|---|---|
| **Auth** | Login (email/password), session-aware splash, sign-out, role-aware routing | Sign-up is on the marketing website (app is login-only by design) |
| **Capture** | Train → free-form workout → live timer + phone GPS/steps → finish → summary | `end_workout_session` RPC: XP + weekly streak + level-up post (atomic) |
| **History** | Analytics card (Day/Week/Month + vs-prior deltas), sessions grouped by week, detail with edit/delete | Free tier shows upsell/cap/search-lock; Premium hides them |
| **AI summary** | "✨" on History → progress summary written by **OpenAI (gpt-4o-mini)** from your real stats | Premium summaries include goal context; Gemini fallback → deterministic stub if keys/AI fail |
| **Share** | Summary → "Share to Social" toggle → caption + Facebook/Instagram/Twitter/TikTok | Creates a `workout_share` Post; platform buttons open the OS share |
| **Profile cluster** | Avatar (top-right) → Profile hub: level/XP bar, lifetime stats, Fitness Profile (#13.1), Fitness Goals (#13.2), Account Settings (#13.3), Notifications (#13.4), Submit Feedback (#13.5), log out | All live writes: fitness_profiles, fitness_goals (active-goal upsert), notification_prefs jsonb, feedback |
| **Forgot password** | Login → "Forgot password?" → reset-link email | Always shows "sent" (anti-enumeration); Change Password in Settings reuses it |
| **Onboarding + plan** | First login → wizard (about you → how you train → goal) → **real AI weekly plan (OpenAI)** → Train shows it | Both tiers: Free basic, Premium personalised; strict JSON schema + server-side validation; Gemini → rule fallback. Gate: `profiles.onboarding_completed_at` |
| **Plan Detail (#8)** | Train → VIEW FULL PLAN → header + current-week schedule → tap a row for the workout modal → Start today's workout (pre-selected activity) · Regenerate | Free: 1 regeneration, then "Upgrade for unlimited"; today's row highlighted |

**Architecture:** Flutter · Riverpod · go_router · freezed · `supabase_flutter`. Strict **Boundary–Control–Entity**
(`lib/entities`, `lib/controls`, `lib/boundaries/{ui,gateways}`). **Backend:** 26 tables + 49 RLS policies +
2 privacy views + `end_workout_session` RPC + `summarise-progress` Edge Function, all on Supabase project
`zbeyytgilrqruttvecdc`. **Tests:** 71 unit/control tests (`flutter test`).

---

## 2. Prerequisites & running

Requires **Flutter 3.44+** (stable). First-time setup:

```bash
cd FYP-26-S2-37-app
flutter pub get
dart run build_runner build          # generate freezed / json models (*.g.dart, *.freezed.dart)
flutter run -d <device>              # pick a device id from `flutter devices`
```

**Devices:**

| Target | Command | Sensors (GPS/steps)? |
|---|---|---|
| Android emulator | `flutter run -d emulator-5554` (AVD `pixel_api35`) | Mockable, not real |
| iOS simulator | `flutter run -d "iPhone 17 Pro"` | Simulated, not real |
| Chrome (web) | `flutter run -d chrome` | ❌ no GPS/steps |
| **Real phone** | plug in → `flutter run -d <id>` | ✅ **real GPS** — use this for a true capture demo |

> The app boots straight to the live Supabase backend (URL + publishable key are baked into
> `lib/core/config/env.dart`; the key is public and RLS-protected). No local backend needed.

While `flutter run` is attached: **`r`** = hot reload, **`R`** = hot restart, **`q`** = quit.

---

## 3. Test accounts

Created/seeded in Supabase Auth (see [§7](#7-reset--reseed-demo-data)). Password for both: **`Password123!`**

| Email | Role | Seeded data |
|---|---|---|
| `free@wiseworkout.test` | Free (Mia Patel) | 8 sessions, 719 XP, 4-week streak, 1 shared post |
| `premium@wiseworkout.test` | Premium (Alex Tan) | 7 sessions, 777 XP, 4-week streak, 1 shared post |

---

## 4. Manual test walkthrough

Do each step and check **"You should see"**. (Tip: use `free@` for the standard demo; switch to
`premium@` to show the paid-tier differences in step G.)

### A. Launch & log in
1. Launch the app.
   - **See:** brief **WISE / WORKOUT** splash (lime accent), then the **Login** screen.
2. Enter `free@wiseworkout.test` / `Password123!` → **LOG IN**.
   - **See:** the **Home** dashboard — *"Hi, Mia 👋 · Free member"* — with the 5-tab bottom nav
     (Home / Experts / Train / Social / History). Experts and Social are styled "later sprint" placeholders.
3. **Negative check:** sign out (logout icon, top-right of Home), enter a wrong password → LOG IN.
   - **See:** red **"Incorrect email or password."** and no navigation.

### B. Record a workout *(the core demo)*
1. Bottom nav → **Train**.
   - **See:** "TRAIN" header, an **AI Suggested Plan** card ("No active plan · Set a goal"), a **Devices**
     card ("Phone sensors · CONNECTED"), and a sticky **▶ START FREEFORM WORKOUT** button.
2. Tap **START FREEFORM WORKOUT**.
   - **See:** the **Active Workout** pre-start screen — dim **00:00** timer, an **activity pill** (defaults
     to *Running*), a big lime **START**, "TAP TO BEGIN". (Tap the pill to switch activity — e.g. Yoga shows
     a STEPS tile instead of DISTANCE/PACE.)
3. Tap **START**.
   - **See:** a location-permission prompt (first run) → allow → the timer runs live; **DISTANCE / PACE**
     update if you actually move (real device) or stay 0 on an emulator. The control row shows **PAUSE** + red **END**.
4. Let it run a few seconds, tap **END** → **Save & Finish**.
   - **See:** **Workout complete** — **+N XP** (e.g. a 30-min 5 km run = **+75 XP**; a short run = **+20 XP**),
     a **🔥 streak**, a stats grid, a name field, **How did it feel?** chips, private notes, a **Share to Social**
     toggle, and **SAVE & FINISH**.
5. (Optional) set a feel chip + name, leave Share off, tap **SAVE & FINISH**.
   - **See:** back at the Train tab.

> **XP formula:** `20 + 1/min + 5/km (cardio) + 10 (planned)`. Level = `floor(XP/200)+1`. Crossing a level
> threshold auto-posts a *level-up* to the feed.

### C. History & detail
1. Bottom nav → **History**.
   - **See:** "HISTORY", a **🔒 Search history · PREMIUM** locked pill, a **Basic Workout Analytics** card
     (Day/Week/Month; "This week" with **Sessions / Active min / Calories / Avg HR / Max HR** and **↑/↓ deltas
     vs last week** in green/red), then sessions grouped **THIS WEEK / LAST WEEK / EARLIER** as cards
     (🏃 name · date · duration, with a distance/pace/HR or calories strip), and a Free **monthly-cap banner**.
   - Tap **Day** / **Month** → the numbers and deltas update.
2. Tap a session card.
   - **See:** **Workout** detail — name, "date · duration · Freeform", a type-aware **stats grid**,
     **How it felt**, **Notes (private)**, and an **Edit** button.
3. Tap **Edit** → change the name/feel/notes → **Done**.
   - **See:** an **EDITING** pill, editable fields, a red **DELETE SESSION** button; **Done** saves and the
     card reflects your edit back on the list.

### D. AI progress summary
1. On **History**, tap the **✨** icon (top-right).
   - **See:** a bottom sheet **"AI PROGRESS SUMMARY"** with a real, data-driven line — e.g.
     *"This week you logged 3 workouts (127 active min). You covered 23.6 km. …"* — and the disclaimer
     **"AI-assisted · for information only, not medical advice."**

### E. Share a workout
1. Record a quick workout (step B) but on the **Workout complete** screen, turn **Share to Social** ON.
   - **See:** a **DESCRIPTION (public)** field and **SHARE TO** buttons: **Facebook · Instagram · Twitter · TikTok**.
2. (Optional) tap a platform button.
   - **See:** the OS share sheet open with a pre-filled message.
3. Tap **SAVE & FINISH**.
   - **Result:** a `workout_share` post is created for the session (verify in [§6](#6-verify-the-backend-optional)).

### F. Sign out
1. Home tab → logout icon (top-right).
   - **See:** back at the Login screen (session cleared).

### A2. First-time onboarding *(once per account)*
1. On a first-ever login (or after a reseed), the app opens the **onboarding wizard** instead of Home.
   - **See:** "WELCOME, MIA" with a 5-segment progress bar → **ABOUT YOU** (DOB/sex/height/weight —
     CONTINUE stays disabled until all four are set) → **HOW YOU TRAIN** (activity, experience,
     preferred workouts) → **YOUR GOAL** (goal cards; target/timeline hidden for Maintain Fitness) →
     **GENERATE MY PLAN** → "YOUR PLAN IS READY" card → **START TRAINING** lands on Home.
2. Open **Train**.
   - **See:** the **active plan card** — plan name, "3x per week · N weeks · AI-assisted (basic)"
     (Premium says personalised), a **TODAY** line when a workout is scheduled today, and one chip
     per weekly slot (e.g. `Mon · Running base`).
2b. Tap **VIEW FULL PLAN ›**.
   - **See:** **Plan Detail (#8)** — big plan name, "12 WEEKS · 3X/WEEK · INTERMEDIATE" meta,
     the AI description, **WEEK N · CURRENT** schedule card (today's row tinted lime), and
     **START TODAY'S WORKOUT** pinned at the bottom. Tap a row → workout modal (descriptor,
     Free upgrade hint, START WORKOUT for today). **Regenerate plan** asks to confirm; for Free
     it locks after 1 regeneration ("Upgrade for unlimited").
3. **Re-trigger the wizard** for a demo:
   `update profiles set onboarding_completed_at = null where email = 'free@wiseworkout.test';`

### F2. Profile & account flows
1. On any tab, tap the **avatar (top-right)**.
   - **See:** **PROFILE** — avatar with edit dot, **MIA PATEL @mia**, a **LEVEL n** XP bar (`x / 200 XP`),
     a **Workouts / Active days / Streak** stats row, five menu rows, and an outlined red **LOG OUT**.
     Free users also get a **GO PREMIUM** pill (hidden for Premium).
2. **Fitness Profile** → set DOB/sex/height/weight, pick activity level, tap experience/workout chips,
   use a section's **+** to open the searchable picker (type an unknown allergy → **+ Add "X" as new**)
   → **SAVE PROFILE**.
   - **See:** "Fitness profile saved." and the values persist on reopen.
3. **Fitness Goals** → pick a goal card (target stepper appears, hidden for Maintain Fitness),
   adjust days/timeline → **SAVE GOAL**.
   - **See:** "Goal saved." — one active goal per user, upserted.
4. **Account Settings** → flip **METRIC / IMPERIAL** (commits instantly); **CHANGE PASSWORD** emails a
   reset link to the signed-in address.
5. **Notifications** → flip any toggle — it commits immediately (workout/social default on, marketing off).
6. **Submit Feedback** → pick a category, type ≥10 chars (counter flips), **SUBMIT FEEDBACK**.
   - **See:** in-screen success with **Submit another / Back to Profile**; a `feedback` row lands in the DB.
7. **Negative check:** with <10 characters the submit button stays disabled.
8. **Forgot password:** log out → "Forgot password?" → enter any email → **SEND RESET LINK**.
   - **See:** the same "sent" card whether or not the email exists (anti-enumeration).

### G. Premium differences
1. Log in as `premium@wiseworkout.test`.
2. Open **History**.
   - **See:** **no** "Unlock with Premium" pill, **no** monthly-cap banner, **no** search-lock — those Free-only
     surfaces are hidden for Premium. Same rich analytics + session history (7 seeded sessions).

---

## 5. Run the automated tests

```bash
flutter analyze     # static analysis — should report "No issues found!"
flutter test        # 71 tests — should end "All tests passed!"
```

Coverage (positive **and** negative cases per flow): entity rules (`Profile`, `WorkoutType.isCardio`,
`WorkoutSession`), formatters (duration/km/pace/icons/dates), and the controls — `Authenticate`
(success/failure), `ActiveWorkout` (start/end cardio vs non-cardio, pause/resume guards), history load +
delete, `SummariseProgress` (success/error), and share (post insert + named platforms). Gateways are faked
behind Riverpod overrides, so no live backend is needed.

---

## 6. Verify the backend (optional)

In the **Supabase dashboard** (project `zbeyytgilrqruttvecdc`) → SQL editor, or via the Supabase MCP:

```sql
-- XP/streak + counts for the demo users
select pr.email, fp.total_xp, fp.current_streak,
  (select count(*) from workout_sessions ws where ws.user_id = pr.id) as sessions,
  (select count(*) from posts p where p.user_id = pr.id) as posts
from profiles pr join fitness_profiles fp on fp.id = pr.id
where pr.email like '%@wiseworkout.test';

-- the most recent workout + any share post
select kind, body, workout_session_id is not null as has_session, created_at
from posts order by created_at desc limit 5;
```

You should see XP/streak change after recording a workout, and a `workout_share` row appear after a share.
**RLS check:** signing in as one user only ever returns that user's own `profiles`/`workout_sessions` rows.

---

## 7. Reset / reseed demo data

To restore both demo accounts + their varied sessions to a known state, run
[`supabase/seed-demo.sql`](../supabase/seed-demo.sql) against the project (SQL editor / `psql` / MCP).
It's **idempotent** — re-run anytime. (Separate from `supabase/seed.sql`, which seeds the install-time
catalogs: workout types, health tags, expert categories.)

---

## 8. Known limitations (intentional for the prototype)

- **AI is live (OpenAI `gpt-4o-mini`, key in Supabase Edge Function secrets — never in the app).**
  Both functions degrade gracefully: OpenAI → Gemini → deterministic stub, same response shape, so the
  app renders all three identically (the `model` field says which produced it).
- **Sharing opens the OS share sheet** — the named-platform buttons are present (the graded requirement);
  true per-app deep-linking is a later sprint.
- **Real GPS needs a physical device** — emulators/simulators show 0 distance unless you mock location.
- **Payment is simulated** (price fields only — premium = $9.99/mo, no gateway).
- **Placeholders** (show "later sprint"): the Experts and Social tabs, Add device, History search,
  Advanced analytics, full plan, Upgrade flow, photo upload, per-field name/username/email edits.
  The Dashboard is a minimal greeting. These are scoped out, not broken.

---

## 9. Where things live

```
lib/
  entities/        Profile, FitnessProfile, FitnessGoal, HealthTag, WorkoutSession,
                   WorkoutType, enums  (freezed models)
  controls/        Authenticate, ActiveWorkout, SaveWorkoutDetails, SummariseProgress,
                   CreateWorkoutSharePost, ShareWorkoutToSocial, DeleteWorkoutSession, history,
                   ViewProfile, UpdateFitnessProfile, SetFitnessGoal, UpdateAccountSettings,
                   ManageNotificationPrefs, SubmitFeedback, RequestPasswordReset
  boundaries/
    ui/            splash · auth (login, forgot pwd) · home · experts · train · social ·
                   history · workout · profile (hub + 5 sub-screens) · common
    gateways/      auth, profile, fitness, feedback, workout, social, social_share, ai,
                   workout_data_source
  core/            theme (palette + iOS type scale), format, seq_log, config/env
  router/          go_router (auth redirect)
supabase/
  migrations/      schema · RLS · end_workout_session RPC · signup-trigger fix
  functions/       summarise-progress  (AI Edge Function)
  seed.sql         install catalogs       seed-demo.sql  demo accounts + data
test/              entity · core · control suites (43 tests)
```

Design references: [STATUS.md](STATUS.md) (progress), [architecture/build-plan.md](architecture/build-plan.md),
[architecture/bce-design.md](architecture/bce-design.md), [reference/database-v1.md](reference/database-v1.md),
[reference/screens/](reference/screens/) (per-screen specs).
