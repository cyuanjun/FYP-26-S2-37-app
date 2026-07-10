# Wise Workout — Prototype Demo & Test Guide

> 🎤 **Presenting?** The stage run-of-show (acts, talking points, timings, fallbacks) is [demo-script.md](demo-script.md); this file is the reference manual behind it.

How to run, demo, and verify the prototype. Last updated **7 Jul 2026**.

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
| ~~Manual entry (US13)~~ | **DESCOPED / REMOVED** — a free-text entry ran the same XP/streak/level RPC as a captured session, so it let users farm progress with no sensor evidence | All progress now requires a captured session (freeform / phone GPS / wearable); see reconciliation §C8 |
| **Notifications (8 Jul)** | Rule-based local reminders (US19–21): plan-day nudges (Premium adaptive hour), missed-workout, 3-day inactivity, Premium rest alert; #13.4 shows an **UPCOMING** strip of the live schedule | ⚠️ iOS-simulator quirk: calendar-trigger notifications don't deliver on the iOS 26 sim (schedule + display verified separately) — demo the UPCOMING strip, or use a device/Android |
| **AI summary** | "✨" on History → progress summary written by **OpenAI (gpt-4o-mini)** from your real stats | Premium summaries include goal context; Gemini fallback → deterministic stub if keys/AI fail |
| **Premium upgrade (8 Jul)** | Free upsell hooks (Dashboard banner, Profile pill, History locks, Plan Detail CTAs) → #16 Upgrade → simulated payment sheet → **live role flip**; #13.6 Subscription Management (plan card, billing history, cancel/resume) | `start_premium` SECURITY DEFINER RPC past the role guard; payment simulated by scope |
| **Advanced analytics (9 Jul)** | History → **Advanced ›** (Premium): ACWR workload tile w/ bands, range-scoped weekly volume/HR-efficiency/load trends, Karvonen HR zones, personal bests | All derived live from sessions (`entities/advanced_analytics.dart`, unit-tested); History also gains Premium **search** |
| **Training Effect (10 Jul)** | #10 Summary + #12.1 Detail: band + 1–10 score + recovery line; Premium adds aerobic/anaerobic split + recovery window | Spec formula; honest "unavailable" state for HR-less (no-wearable) sessions |
| **Share** | Summary → "Share to Social" toggle → caption + Facebook/Instagram/Twitter/TikTok | Creates a `workout_share` Post; platform buttons open the OS share |
| **Social (6 Jul)** | Community feed (friends+self; workout_share/level_up posts, likes, comments, caption edit) → Post Detail; find-friends search + Add Friend/Unfriend + User Profile; Challenges (Joined/Active/Past, join/leave/create, live leaderboards) | Friendship = mutual pair via `add_friend` RPC; leaderboards live-computed by `challenge_leaderboards`; demo seed gives Mia↔Alex + likes/comments + a joined challenge |
| **Experts (7–8 Jul)** | Browse experts + service listings (search, category chips, follow-heart) → Expert Detail → Service Detail (Request modal → pending → deliverables → Leave a review → ✓ Reviewed); Dashboard MY PURCHASES; log in as `expert@` → the complete expert portal (Home · Services · Requests · Clients · Profile): triage on Requests, deliverables + Mark complete on Client Detail (#23.1), **create/edit service listings** (⊕ on Services, draft/live/archived) and **Manage Professional Info** (#24.1 on Profile) | Payment simulated (price snapshots, no charge); transitions + reviews via SECURITY DEFINER RPCs; expert aggregates column-locked (RPC-only); demo: Sam Rivera w/ 3 live services + one engagement in every footer state |
| **Profile cluster** | Avatar (top-right) → Profile hub: **profile-photo upload (10 Jul: gallery → avatars bucket → renders everywhere)**, level/XP bar, lifetime stats, Fitness Profile (#13.1), Fitness Goals (#13.2), Account Settings (#13.3), Notifications (#13.4), Submit Feedback (#13.5), log out | All live writes: fitness_profiles, fitness_goals (active-goal upsert), notification_prefs jsonb, feedback, storage avatars |
| **Forgot password** | Login → "Forgot password?" → reset-link email | Always shows "sent" (anti-enumeration); Change Password in Settings reuses it |
| **Onboarding + plan** | First login → wizard (about you → how you train → goal) → **real AI weekly plan (OpenAI)** → Train shows it | Both tiers: Free basic, Premium personalised; strict JSON schema + server-side validation; Gemini → rule fallback. Gate: `profiles.onboarding_completed_at` |
| **Devices (#7.1)** | Train → Devices card → paired list (phone sensors pinned) → + ADD DEVICE → the sheet runs a **real Bluetooth scan** (finds listed above the demo devices) → pair → next workout shows live ♥ HR; avg/max saved, session linked to the device | Real GATT HR via `BleHeartRateSource` (10 Jul) when a scanned device is paired; demo pairings keep the simulated stream; sim has no Bluetooth → demo list only. HealthKit still later |
| **Plans + Plan Detail (#8)** | Train card → **Start Planned Workout** (today's session, pre-selected activity) · VIEW PLANS → choose a saved plan → header + week schedule (read-only) → tap a row for the workout modal → Use This Plan · Regenerate | Free: **1 regeneration/month** (resets each month), then "Upgrade for unlimited"; today's row highlighted. Planned-workout start lives on the Train card (Plan Detail is view-only) |

**Architecture:** Flutter · Riverpod · go_router · freezed · `supabase_flutter`. Strict **Boundary–Control–Entity**
(`lib/entities`, `lib/controls`, `lib/boundaries/{ui,gateways}`). **Backend:** 26 tables + RLS +
2 privacy views + `end_workout_session` RPC + **two Edge Functions (`summarise-progress`, `suggest-plan`)
running OpenAI `gpt-4o-mini`** (Gemini → deterministic-stub fallback), all on Supabase project
`zbeyytgilrqruttvecdc`. **Tests:** 244 unit/control tests (`flutter test`).
**Server functions:** `end_workout_session` · `add_friend`/`remove_friend` · `challenge_leaderboards`.

---

## 2. Prerequisites & running

Requires **Flutter 3.44+** (stable). First-time setup:

```bash
cd FYP-26-S2-37-app/app
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
> **Local backend (optional, 6 Jul):** `cd app && supabase start` (Docker; ports 55321-9), then
> run with `--dart-define=SUPABASE_URL=http://127.0.0.1:55321 --dart-define=SUPABASE_ANON_KEY=<publishable key printed by supabase start>`.
> Migrations + `seed.sql` apply automatically; load demo accounts with
> `docker exec -i supabase_db_app psql -U postgres -d postgres < supabase/seed-demo.sql`.

While `flutter run` is attached: **`r`** = hot reload, **`R`** = hot restart, **`q`** = quit.

---

## 3. Test accounts

Created/seeded in Supabase Auth (see [§7](#7-reset--reseed-demo-data)). Password for all: **`Password123!`**

| Email | Role | Seeded data |
|---|---|---|
| `free@wiseworkout.test` | Free (Mia Patel) | 8 sessions, shared post, friends w/ Alex, joined challenge, 3 service requests (pending/completed/reviewed states) |
| `premium@wiseworkout.test` | Premium (Alex Tan) | 7 sessions, shared post, friends w/ Mia, joined challenge, 1 reviewed engagement |
| `expert@wiseworkout.test` | Expert (Sam Rivera) | Verified Strength Coach · 3 live services · request inbox with every lifecycle state |
| `jordan@` / `priya@` / `leo@wiseworkout.test` | Free (background athletes) | Sessions + a shared post each, friendships with Mia + Alex, likes/comments both ways, challenge entries — they make the feed and leaderboards look alive; no need to log in as them |
| `admin@wiseworkout.test` | Admin (Ava Admin) | Logs into the **web portal** (`web/` → `/login` → `/admin`), not the app — the app role-redirects admins away |
| `amelia@` / `marcus@` / `elena@wiseworkout.test` | Experts (verified) | Marketplace depth: live services + stored rating aggregates; they drive the landing FEATURED EXPERTS ranking — no need to log in as them |
| `noah@wiseworkout.test` | Free (pending expert applicant) | PENDING expert application + document metadata — the demo card on `/admin/applications`; approving him live flips his role to expert |

---

## 4. Manual test walkthrough

Do each step and check **"You should see"**. (Tip: use `free@` for the standard demo; switch to
`premium@` to show the paid-tier differences in step G.)

### A. Launch & log in
1. Launch the app.
   - **See:** brief **WISE / WORKOUT** splash (lime accent), then the **Login** screen.
2. Enter `free@wiseworkout.test` / `Password123!` → **LOG IN**.
   - **See:** the **Home** dashboard — *"Hi, Mia 👋 · Free member"* — with the 5-tab bottom nav
     (Home / Experts / Train / Social / History). **All five tabs are live** — Experts (marketplace, 7 Jul) · Social (feed · friends · challenges, 6 Jul).
3. **Negative check:** sign out (logout icon, top-right of Home), enter a wrong password → LOG IN.
   - **See:** red **"Incorrect email or password."** and no navigation.

### B. Record a workout *(the core demo)*
1. Bottom nav → **Train**.
   - **See:** "TRAIN" header, the **Selected Plan card** (your active plan: name, cadence, the
     week schedule with the next session highlighted, and a **▶ START PLANNED WORKOUT** button —
     or "No active plan · Set a goal" if onboarding was skipped), a **Devices** card, and a sticky
     **▶ START FREEFORM WORKOUT** button.
2. Tap **START FREEFORM WORKOUT** (or **START PLANNED WORKOUT** to start today's scheduled session with its activity pre-selected).
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

> **XP formula:** `20 + 1/min + 5/km (cardio) + 10 (planned — not yet reachable, OPEN-003)`. Level = `floor(XP/200)+1`. Crossing a level
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
   - **See:** a bottom sheet **"AI PROGRESS SUMMARY"** with 2–3 sentences of **real model-written
     prose** (OpenAI `gpt-4o-mini`) about your actual weekly numbers — wording varies per call;
     Premium summaries reference your goal — plus the disclaimer
     **"AI-assisted · for information only, not medical advice."** (If the AI is unreachable it
     degrades to a deterministic template, same format.)

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
1. On a first-ever login (or after the re-trigger SQL in step 3 — a reseed alone does **not** reset the gate), the app opens the **onboarding wizard** instead of Home.
   - **See:** "WELCOME, MIA" with a 5-segment progress bar → **ABOUT YOU** (DOB/sex/height/weight —
     CONTINUE stays disabled until all four are set) → **HOW YOU TRAIN** (activity, experience,
     preferred workouts) → **YOUR GOAL** (goal cards; target/timeline hidden for Maintain Fitness) →
     **GENERATE MY PLAN** → "YOUR PLAN IS READY" card → **START TRAINING** lands on Home.
2. Open **Train**.
   - **See:** the **Selected Plan card** — plan name, "3x per week · N weeks · AI-assisted (basic)"
     (Premium says personalised), the week's schedule as a per-day list (day · workout · duration,
     next session highlighted green), and a **▶ START PLANNED WORKOUT** button (or "No workout
     scheduled today." on a rest day).
2b. Tap **VIEW PLANS ›**, then open the active plan.
   - **See:** **Plan Detail (#8)** — big plan name, "12 WEEKS · 3X/WEEK · INTERMEDIATE" meta,
     the AI description, week selector, and the **WEEK N · CURRENT** schedule card (green day
     labels, today's row tinted green). It's **view-only** (starting a workout lives on the Train
     card) — tap a row → workout modal (descriptor, Premium upgrade note, Close). **Regenerate
     plan** (outlined button) confirms first; for Free it's **1 regeneration per month** — once
     used this month it greys out with a gold "Upgrade for unlimited regenerations" pill, and
     resets next month.
3. **Re-trigger the wizard** for a demo:
   `update profiles set onboarding_completed_at = null where email = 'free@wiseworkout.test';`

### B2. Pair a wearable → live heart rate
1. Train → tap the **Devices** card (or **+ ADD DEVICE**).
   - **See:** **CONNECTED DEVICES** — "Phone sensors · Built-in · always available" pinned (no
     toggle/remove), then any paired wearables with CONNECTED pill, toggle, and remove.
2. **+ ADD DEVICE** → "Scanning for devices…" → pick **Apple Watch Series 9**.
   - **See:** snackbar "…connected — its heart rate feeds your next workout"; row shows
     "Last synced: just now".
   - The sheet runs a **real Bluetooth scan** first (10 Jul): on a physical device with an HR
     sensor nearby, a **NEARBY (BLUETOOTH)** section appears above the demo list — pairing one
     stores its remote id and the next workout streams **real** GATT heart rate. The simulator
     has no Bluetooth, so only the demo list shows there.
3. Record a workout (step B).
   - **See:** a live **♥ N bpm · Apple Watch Series 9** readout under the metric tiles, climbing
     from ~70 as you "warm up" (simulated stream). After saving: avg/max HR on the session in
     History, and the watch row's last-synced updates.
4. **Negative check:** toggle the watch OFF (or remove it) → next workout has no HR readout and
   the session links to phone sensors instead.

### B3. ~~Log a workout manually (US13)~~ — DESCOPED / REMOVED
Manual entry was cut: a free-text entry ran the same XP/streak/level RPC as a captured
session, so it let users fabricate workouts and farm progress with no sensor evidence.
There is no "Log a workout manually" button anymore — all progress requires a captured
session (freeform / phone GPS / wearable). See reconciliation log §C8.

### F2. Profile & account flows
0. Tap the avatar circle's **edit dot** → system photo picker → choose a photo.
   - **See:** "Profile photo updated." — the photo replaces the initial everywhere the avatar
     renders (profile circle + the top-right avatar button). Stored in the public `avatars`
     bucket under your own folder (10 Jul).
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
   - **See:** **no** "Unlock with Premium" pill, **no** monthly-cap banner — and the search-lock is now a **real
     search field** ("Search history by name or type"). Type `leg` → the list *and* the analytics narrow to the
     "Leg day" session; a nonsense query shows `No history matches "…"`. Same rich analytics + session history
     (7 seeded sessions).
3. Open the shared session's detail (search `tempo` → "10k tempo").
   - **See:** a **VIEW SHARED POST** button under the notes — it jumps straight to the post's likes and
     comments (#11.1), closing the capture → share → engage loop.
4. Tap **Advanced ›** on the Basic Workout Analytics card (Premium-only).
   - **See:** **#12.2 Advanced Analytics** — the ACWR workload tile with a coloured band chip, range pills
     (4 wks / 3 mo / 1 yr / All), weekly volume (metric toggle), HR efficiency, training load, the Karvonen
     HR-zone stacked bar, and all-time personal bests — all computed live from the seeded sessions.

### H. Upgrade to Premium *(the live tier flip — great demo moment)*
1. Log in as `free@wiseworkout.test` (Mia).
   - **See:** the gold **"⚡ Go Premium — personalised AI plans & more"** banner on the Dashboard
     (also reachable from the Profile **GO PREMIUM** pill, History's unlock pill / cap banner,
     and the Plan Detail upgrade CTAs).
2. Tap the banner.
   - **See:** **#16 Upgrade** — "TRAIN SMARTER." hero, the six **PREMIUM UNLOCKS**, the gold-ringed
     **$9.99 / mo** pricing card, **START PREMIUM**, and "Payment is simulated — no real charge."
3. Tap **START PREMIUM** → the **SIMULATED PAYMENT** sheet (plan summary + mock Visa •••• 4242) →
   **CONFIRM PAYMENT**.
   - **See:** "Welcome to Premium 🎉" — back on the Dashboard the banner is **gone** and the subtitle
     reads **Premium member**. No re-login: the `start_premium` RPC flipped the role live.
4. Open **Profile**.
   - **See:** the GO PREMIUM pill is gone; a **⭐ Manage Subscription** row appeared. Tap it.
   - **See:** **#13.6 Subscription** — PREMIUM MONTHLY plan card (ACTIVE badge, renewal date),
     mock payment method, synthesised **billing history**, **CANCEL SUBSCRIPTION**.
5. Optional: **Cancel** (confirm dialog) → badge flips to CANCELLED with "access until {date}" →
   **RESUME SUBSCRIPTION** flips it back.
6. **Reset for the next demo** (Mia should stay Free) — in SQL editor / psql:
   `select set_config('app.role_change_authorized','on',true); update profiles set role='free' where email='free@wiseworkout.test'; delete from subscriptions where id=(select id from profiles where email='free@wiseworkout.test');`
   (one transaction), then log out in the app.

---

## 5. Run the automated tests

```bash
flutter analyze     # static analysis — should report "No issues found!"
flutter test        # 244 tests — should end "All tests passed!"
```

Coverage (positive **and** negative cases per flow): entity rules (`Profile`, `WorkoutType` incl. MET
calories, `WorkoutSession`, `FitnessProfile` level/XP, `FitnessGoal`), formatters, and the controls —
`Authenticate`, `ActiveWorkout` (incl. wearable HR + device linkage), history (Free month-cap vs Premium
lifetime), `SummariseProgress`, share, the Profile cluster (fitness profile/goals/settings/notifications/
feedback/password reset), `GeneratePlan` (both tiers, AI-down fallback, no-goal), `buildPlanSkeleton`
rules (4-week cycle, preference contract), and connected devices (pairing, phone-device seeding,
HR curve). Gateways are faked behind Riverpod overrides, so no live backend is needed.

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
[`supabase/seed-demo.sql`](../../app/supabase/seed-demo.sql) against the project (SQL editor / `psql` / MCP).
It's **idempotent** — re-run anytime. (Separate from `supabase/seed.sql`, which seeds the install-time
catalogs: workout types, health tags, expert categories.)

**On the local stack**, follow with [`supabase/seed-expert-docs.sh`](../../app/supabase/seed-expert-docs.sh)
(run from `app/`) to upload Noah's sample identity/certificate PDFs into the private `expert-docs` bucket and
link them — this makes the pending expert application on `/admin/applications` **viewable** (the SQL seed can't
ship file bytes). Without it, Noah's documents show as name-only.

---

## 8. Known limitations (intentional for the prototype)

- **AI is live (OpenAI `gpt-4o-mini`, key in Supabase Edge Function secrets — never in the app).**
  Both functions degrade gracefully: OpenAI → Gemini → deterministic stub, same response shape, so the
  app renders all three identically (the `model` field says which produced it).
- **Planned-workout XP bonus (+10) is not yet reachable** — sessions started from the plan don't link
  `planned_workout_id` yet (bug-log OPEN-003).
- **Wearable HR is a simulated stream** behind the mock pairing (#7.1 spec); real BLE/HealthKit slots in
  behind the same `WorkoutDataSource` interface later.
- **Sharing opens the OS share sheet** — the named-platform buttons are present (the graded requirement);
  true per-app deep-linking is a later sprint.
- **Real GPS needs a physical device** — emulators/simulators show 0 distance unless you mock location.
- **Payment is simulated** (price fields only — premium = $9.99/mo, no gateway).
- **Placeholders** (show "later sprint"): History search,
  Advanced analytics, Upgrade flow, photo upload, per-field name/username/email edits.
  The Dashboard is a minimal greeting. These are scoped out, not broken.

---

## 9. Where things live

All paths below are inside **`app/`** (the repo root also holds `docs/` — planning/design material not needed to run the app).

```
lib/
  entities/        Profile, FitnessProfile, FitnessGoal, FitnessPlan, PlannedWorkout,
                   ConnectedDevice, HealthTag, WorkoutSession, WorkoutType, enums
  controls/        Authenticate, RequestPasswordReset, ActiveWorkout, SaveWorkoutDetails,
                   DeleteWorkoutSession, history, SummariseProgress, CreateWorkoutSharePost,
                   ShareWorkoutToSocial, GeneratePlan + CompleteOnboarding (+ buildPlanSkeleton),
                   social_feed (feed/likes/comments), manage_friends, challenges,
                   browse_experts, service_requests, expert_requests,
                   ManageConnectedDevice, ViewProfile, UpdateFitnessProfile, SetFitnessGoal,
                   UpdateAccountSettings, ManageNotificationPrefs, SubmitFeedback
  boundaries/
    ui/            splash · auth (login, forgot pwd) · onboarding (wizard) · home (+ my
                   purchases) · experts (directory, expert/service detail, request inbox,
                   deliverable composer) ·
                   train (+ plan detail, connected devices) · social (feed, post detail,
                   user profile, challenges, create-challenge) · history · workout ·
                   profile (hub + 5 sub-screens) · common (shared widget library:
                   StatTile · AppCard · StatusBadge · PremiumCta · AvatarButton)
    gateways/      auth, profile, fitness, plan, device, feedback, workout, social,
                   social_share, ai, workout_data_source (phone + simulated wearable HR)
  core/            theme (palette + iOS type scale + button styles), format, strings, seq_log, config/env
  router/          go_router (auth redirect)
supabase/
  migrations/      schema · RLS · end_workout_session RPC · signup-trigger fix ·
                   onboarding_completed_at · private custom catalog entries
  functions/       summarise-progress · suggest-plan  (AI Edge Functions, gpt-4o-mini)
  seed.sql         install catalogs       seed-demo.sql  demo accounts + data
test/              entity · core · control · gateway · boundary-widget suites (244 tests)
```

Design references: [STATUS.md](../STATUS.md) (progress), [architecture/build-plan.md](architecture/build-plan.md),
[architecture/bce-design.md](architecture/bce-design.md), [reference/database-v1.md](reference/database-v1.md),
[reference/screens/](reference/screens/) (per-screen specs).
