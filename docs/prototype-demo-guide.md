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
| **AI summary** | "✨" on History → data-driven progress summary | Stub Edge Function (no API key); swappable for OpenAI/Gemini with no app change |
| **Share** | Summary → "Share to Social" toggle → caption + Facebook/Instagram/Twitter/TikTok | Creates a `workout_share` Post; platform buttons open the OS share |

**Architecture:** Flutter · Riverpod · go_router · freezed · `supabase_flutter`. Strict **Boundary–Control–Entity**
(`lib/entities`, `lib/controls`, `lib/boundaries/{ui,gateways}`). **Backend:** 26 tables + 49 RLS policies +
2 privacy views + `end_workout_session` RPC + `summarise-progress` Edge Function, all on Supabase project
`zbeyytgilrqruttvecdc`. **Tests:** 43 unit/control tests (`flutter test`).

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

### G. Premium differences
1. Log in as `premium@wiseworkout.test`.
2. Open **History**.
   - **See:** **no** "Unlock with Premium" pill, **no** monthly-cap banner, **no** search-lock — those Free-only
     surfaces are hidden for Premium. Same rich analytics + session history (7 seeded sessions).

---

## 5. Run the automated tests

```bash
flutter analyze     # static analysis — should report "No issues found!"
flutter test        # 43 tests — should end "All tests passed!"
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

- **AI summary is a deterministic stub** — real numbers, templated prose, labelled AI-assisted. The Edge
  Function (`supabase/functions/summarise-progress`) swaps to OpenAI/Gemini with **no app change**.
- **Sharing opens the OS share sheet** — the named-platform buttons are present (the graded requirement);
  true per-app deep-linking is a later sprint.
- **Real GPS needs a physical device** — emulators/simulators show 0 distance unless you mock location.
- **Payment is simulated** (price fields only — premium = $9.99/mo, no gateway).
- **Placeholders** (show "later sprint"): the Experts and Social tabs, Set a goal, Add device,
  History search, Advanced analytics, full plan. The Dashboard is a minimal greeting. These are
  scoped out of the slice, not broken.

---

## 9. Where things live

```
lib/
  entities/        Profile, WorkoutSession, WorkoutType, enums  (freezed models)
  controls/        Authenticate, ActiveWorkout, SaveWorkoutDetails, SummariseProgress,
                   CreateWorkoutSharePost, ShareWorkoutToSocial, DeleteWorkoutSession, history
  boundaries/
    ui/            splash · auth · home · experts · train · social · history · workout screens
    gateways/      auth, profile, workout, social, social_share, ai, workout_data_source
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
