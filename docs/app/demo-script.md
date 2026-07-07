# Wise Workout — Final Demo Script (13–22 Aug 2026)

The stage run-of-show for the overall-project demo. This is the *performance*
script — what to tap and what to say, in order, with timings. The reference
manual behind it (setup, expected states, backend verification) is
[prototype-demo-guide.md](prototype-demo-guide.md).

**Total ~12 min of app time**, leaving room in a 20-min slot for intro slides,
architecture, and Q&A. Every act ends on a natural pause where questions can
be taken without losing state.

---

## Before the demo (checklist)

Do this the night before **and** ~30 min before the slot:

- [ ] `cd app && supabase start` if demoing on the local stack, else confirm
      hosted is reachable. **Decide which backend now** — mixed state mid-demo
      is the #1 rehearsal failure. (Hosted is the default; local is the
      no-venue-wifi fallback — pass the `--dart-define`s per the demo guide.)
- [ ] Re-run `app/supabase/seed-demo.sql` against the chosen backend. This
      resets all five athletes' data, restores Sam's **pending** request, and
      re-dates everything relative to *today* so groupings say "Today /
      Yesterday".
- [ ] **Revert Mia if a rehearsal upgraded her** (Act 3 flips her to Premium):
      ```sql
      begin;
      select set_config('app.role_change_authorized','on',true);
      update profiles set role='free' where email='free@wiseworkout.test';
      delete from subscriptions where id=(select id from profiles where email='free@wiseworkout.test');
      commit;
      ```
- [ ] Fresh app install/launch on the demo device, **logged out**.
- [ ] Confirm the AI key works: log in as anyone → History → ✨ produces a
      written summary (if it silently falls back to the stub, the demo still
      works — the stub has the same shape — but check the Edge Function
      secrets if you want live AI on stage).
- [ ] If showing notifications firing live: use a **physical device or the
      Android emulator** (the iOS simulator does not deliver scheduled
      calendar-trigger notifications — schedule shows in-app either way).
- [ ] Charge the device. Do Not Disturb OFF (Act 5 fires a notification).

**Cast** (password for all: `Password123!`):

| Account | Plays | Used in |
|---|---|---|
| `free@wiseworkout.test` (Mia) | the Free athlete who upgrades | Acts 1–4 |
| `expert@wiseworkout.test` (Sam) | the expert | Act 5 |
| `premium@wiseworkout.test` (Alex) + jordan/priya/leo | background cast — never logged into | feed, comments, leaderboards |

---

## Act 1 — The core loop (Mia, ~3 min)

*The spine the whole product hangs off: capture → analyse → AI → share.*

1. **Log in** as Mia. Point out the role-aware shell: five tabs, Free tier.
   > "Wise Workout is a cross-platform fitness app on Flutter + Supabase.
   > Mia here is a free user — everything you'll see first is the free tier."
2. **Train → START FREEFORM WORKOUT** → pick Running → let it run ~30 s.
   Point at the live duration and the source device row.
   > "Capture comes from an abstracted data-source layer — phone GPS and
   > pedometer here, simulated BLE heart-rate when a wearable is paired.
   > Real wearables are a class swap, not a refactor."
3. **End workout** → summary screen: name it, feel rating, private note →
   save.
   > "Finalisation is one atomic server-side call — XP, weekly streak, even
   > the level-up post are computed in Postgres, so no client can cheat."
4. *(Optional 20 s, if pressed for time skip)* **Train → Log a workout
   manually** — show the form exists for sessions done without the phone.
5. **History**: the new session at top, Basic Workout Analytics with
   vs-last-week deltas. Tap **✨**.
   > "The AI progress summary is one of exactly two AI features — summaries
   > and plan suggestions, both behind a Supabase Edge Function so the key
   > never ships in the app. Note the honesty label: AI-assisted, not
   > medical advice. If the model is down it degrades to a deterministic
   > fallback — the demo never breaks."
6. Open the new session's detail → **share to feed** (platform buttons:
   Facebook / Instagram / Twitter / TikTok) → post it.

*Pause point — state: Mia has a fresh session + a fresh post.*

## Act 2 — Social (Mia, ~2 min)

1. **Social tab**: the feed — Mia's new post plus Jordan/Priya/Leo/Alex with
   likes and comments.
   > "The community is live data: friendships are mutual pairs written by a
   > SECURITY DEFINER RPC, and everyone here is a real seeded account."
2. Open Jordan's post → like it, add a comment.
3. **Challenges** pill → 20 IN 30 → the five-person leaderboard.
   > "Leaderboards aren't stored — a SQL function aggregates each
   > participant's qualifying sessions inside the challenge window, live,
   > through the privacy views."
4. Back to **History** → open the shared session → **VIEW SHARED POST** —
   the loop closes: capture → analyse → share → engage.

## Act 3 — Premium, live upgrade (Mia, ~2.5 min)

1. Point at the Free-tier friction collected so far: Dashboard **Go Premium**
   banner, the 🔒 search pill on History, the monthly-cap banner.
2. Tap the banner → **#16 Upgrade**: the six unlocks ("every bullet maps to a
   real gate — no vapourware"), $9.99 pricing card → **START PREMIUM** →
   simulated payment sheet → **CONFIRM PAYMENT**.
   > "Payment is simulated by scope — price fields, no gateway. The role flip
   > itself is real: a SECURITY DEFINER RPC upgrades her past the
   > role-escalation guard, and the app flips live — watch, no re-login."
3. Back on the Dashboard: banner gone, "Premium member". **History**: the
   lock is now a working **search field** — type `tempo`, the list and the
   aggregates narrow live.
4. **Advanced ›** → #12.2: ACWR tile with its band chip, range pills, weekly
   volume/HR-efficiency/load trends, Karvonen HR zones, personal bests.
   > "All derived on-device from her session history — the maths is a pure,
   > unit-tested module. And the framing is deliberately descriptive, never
   > prescriptive."
5. **Profile → Manage Subscription** (#13.6): plan card, billing history,
   cancel/resume. *(Show cancel → 'access until' → resume if time allows.)*

*Pause point. (Remember: rehearsals must revert Mia afterwards.)*

## Act 4 — Expert marketplace, client side (Mia, ~1.5 min)

1. **Experts tab**: browse cards (rating/reviews/clients), search + category
   chips, the follow-heart.
2. Open **Sam Rivera** → Expert Detail: aggregates, credentials, specialties.
3. Open **12-Week Strength Block** → the completed engagement: the
   **deliverable** (the training block Sam wrote) and the **Leave a review**
   footer state.
   > "The expert layer is the third leg of the business model — à-la-carte
   > services both Free and Premium buy. The request lifecycle is
   > RPC-guarded: clients can't fake transitions, experts can't inflate
   > their own ratings — those columns are literally revoked."
4. Open **Mobility Reset Coaching** → the **pending** footer — hand-off line:
   > "That request is sitting in an expert's inbox. Let's be the expert."

## Act 5 — Expert portal + notifications (Sam, ~2.5 min)

1. Log out → log in as **Sam**. The whole shell changes: Home · Services ·
   Requests · Clients · Profile.
   > "Same app, role-based boundary — experts get the #20–24 wireframe track."
2. **Home**: reputation, workload, simulated earnings. **Requests**: Mia's
   pending Mobility request → **Accept**.
3. **Clients → Mia → #23.1**: the engagement is Active — **Send deliverable**
   (compose a quick title + a line or two) → *(optionally Mark complete)*.
4. **Services**: ⊕ create a listing live (name, category, price, **Live**) —
   "it's in the client marketplace right now". **Profile → Manage
   Professional Info**: the editable columns vs the system-managed ones.
5. **Notifications** (any athlete account, or pre-staged): #13.4 toggles +
   the **UPCOMING** strip showing what's scheduled with the OS.
   > "Reminders are rule-based by design — plan-day nudges that adapt to
   > your usual training hour on Premium, inactivity after three quiet days,
   > and a rest alert when the last three days held three sessions. The
   > engine is a pure function with the whole rulebook unit-tested."
   *(On a physical device: background the app and let the overdue nudge
   fire as a banner. On the iOS simulator: show the UPCOMING strip instead
   and say why.)*

## Wrap (~30 s, back on slides)

> "Everything you saw is one Flutter codebase in strict
> Boundary–Control–Entity — 26 entities mirroring the TDM ERD, one control
> per use case, and no screen ever touching the database. The backend is
> Postgres with row-level security everywhere, eight SECURITY DEFINER RPCs
> for every multi-step rule, and 210 automated tests. The admin portal ships
> separately as a web app on the same backend."

---

## Risks & fallbacks

| Risk | Fallback |
|---|---|
| Venue wifi dies | Local Supabase stack + `--dart-define`s (decide **before**, not mid-demo) |
| OpenAI/Gemini down or slow | Automatic deterministic stub — same response shape; don't mention unless asked |
| Live GPS capture awkward indoors | Duration/steps still tick without movement; or use **Log a workout manually** and narrate the same atomic-finalise story |
| iOS notification delivery | Known simulator limitation — demo the UPCOMING strip; live banner only on device/Android |
| Rehearsal state drift | Re-run `seed-demo.sql` + the Mia revert SQL above — both are idempotent |
| Accidental wrong tap mid-flow | Every act is independent; pull-to-refresh or re-login re-syncs state |
