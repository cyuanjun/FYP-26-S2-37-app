---
screen: 05-dashboard
role: free
group: main
status: built  # minimal greeting only — full digest pending
---

# 5. Dashboard (Home)

**Purpose:** Default landing screen after login + the Home tab in the bottom nav. Acts as the **digest** for cross-cutting state — what's queued today, how the week is shaping up, where the active goal stands, and what the user has purchased from experts. Things that already have a dedicated tab (full plan, full history, social feed, friends, settings) deliberately do **not** repeat here.

## Layout

Vertical scroll. Three structural bands inside `PhoneFrame`:

1. **Header** — `TabHeader variant="greeting"` (left: "Hi, [first name]"; right: 44×44 avatar → #13 Profile)
2. **Main** — four stacked content sections:
   1. **Today** — single-card "today's workout" preview
   2. **This week** — 3-tile stats strip
   3. **Active goal** — progress card
   4. **My purchases** — list of `ServiceRequest` rows
3. **Bottom nav** — `BottomNav active="home"`

Each section uses the shared `SectionLabel` (small uppercase header + optional right-aligned action link).

## UI elements

### Header
Already described in earlier draft — `Hi,` (Footnote muted) + first name (Title 1 black tracking-tight) on the left; 44×44 circular avatar button on the right routing to #13 Profile. Reads `User.FirstName` + `User.AvatarUrl`.

### Section 1 — Today
Section label: **TODAY** with right-side action `OPEN TRAIN ›` (links to #7 Train).

Three possible states (mirrors #7's own Today block exactly — same derivation, lighter chrome):

- **Has plan + today is scheduled** — accent sparkle + `DAY · Week N`, big uppercase workout name (`PlannedWorkout.name ?? WorkoutType.name`), `N min · descriptor`, accent CTA line *Start workout*. **The whole card is a link** to `/free/09-active-workout?planned=<id>` — one tap from Dashboard to in-progress session, mirroring #7's Start button.
- **Has plan + today is a rest day** — centred *"Rest day · No workout scheduled · recover well."*
- **No active plan** — *"No active plan · Set a fitness goal to generate your AI plan."* + accent `Set a goal ›` link to #13.2.

### Section 2 — This week
Section label: **THIS WEEK**. Single rounded `surface` card with `grid-cols-3` divided by vertical `faint/60` lines. Three tiles:

| Tile | Value | Derivation |
|---|---|---|
| Workouts | int | count of current-user `WorkoutSession` rows with `EndedAt IS NOT NULL` whose `StartedAt` falls in the current Mon-Sun window |
| Active days | int | distinct `YYYY-MM-DD` of `StartedAt` across the same set |
| Minutes | int | `sum(durationSeconds) / 60`, rounded |

Tiles are read-only — no tap target. Profile (#13) shows all-time aggregates; History (#12) shows the per-session list; This Week sits in between as the "now" snapshot.

The window is **always ISO Mon–Sun anchored to `TODAY`** so it doesn't drift mid-render. `TODAY` comes from `lib/formatTime` per the project convention.

### Section 3 — Active goal
Section label: **ACTIVE GOAL** with right-side `EDIT ›` action linking to #13.2 Fitness Goals (only when a goal exists; hidden in the no-goal state to avoid double-CTA).

Two possible states:

- **Has active goal** (`FitnessGoal` where `achievedAt IS NULL`):
  - Top meta line: accent target glyph + `PRIMARY_GOAL_LABELS[primaryGoal]` (e.g. "LOSE WEIGHT")
  - Headline: derived sentence — `Lose 5 kg in 12 weeks`, `Gain 4 kg lean mass in 16 weeks`, `Sustained activity in 12 weeks`, `Stay consistent in N weeks` (maintain_fitness case). Numbers built from `StartingValue` + `TargetValue` + `TargetUnit` + `TimelineWeeks`.
  - Progress bar — accent fill over `surface-2` track. Ratio = `(now - createdAt) / (timelineWeeks * 7 days)`, clamped `[0, 1]`.
  - Footer line under bar: `Week N of T` (left, muted) · `XX%` (right, accent)
  - Optional second line below `border-faint/60`: `Current 62 kg · target 57 kg` — shown only when goal has weight units + a starting value, since other goal types don't have a meaningful "current" reading without a tracker entity.

- **No active goal**: card prompts *"Set one to see weekly progress here."* with accent `Set a goal ›` link to #13.2.

**Why timeline progress, not metric progress.** A real fitness app would chart actual weight / endurance numbers over time, but the mock has no time-series tracker for those values (`UserFitnessProfile.weightKg` is a single static field, not a daily log). Timeline-elapsed gives an honest progress signal — *"you're 8 weeks into a 12-week plan"* — without faking measurement data. Add a `MetricLog` entity when real progress charting is in scope.

### Section 4 — My purchases
Section label: **MY PURCHASES** with right-side `BROWSE ›` action linking to #6 Experts.

Lists current-user `ServiceRequest` rows ordered `requestedAt DESC`. Each row joins to `ExpertService` (for name) + `OtherUsers` (for expert display name), then renders as a card:

- Left: service name (ink bold) + meta `Expert Name · relative time` (e.g. "Jordan Reeves · 17d")
- Right: `$120` price (ink black, from `QuotedPriceCents`) + a status chip for non-accepted requests — gold `Pending` (awaiting the expert) or muted `Declined` (`cancelled`); accepted (`completed`) requests show no chip (they're active).
- Whole row links to `/free/06.2-service-detail?id=<expertServiceId>` — the same #6.2 where the request was sent, which now shows the engagement's deliverables + the Leave-a-review action once accepted. No separate "request detail" screen needed.

Empty state: *"No purchases yet"* + accent `Browse experts ›` link.

## Edges

- **From:** Splash (valid session + onboarding complete); Login (successful auth + onboarding complete); Onboarding (after the user finishes the post-login flow); any other Main tab (tapping the Home tab in `BottomNav`)
- **To (via bottom nav):** Experts (#6), Train (#7), Social (#11), History (#12)
- **To (via avatar):** Profile (#13)
- **To (via cards):**
  - Today card → #9 Active Workout (when planned) / #13.2 Fitness Goals (when no plan)
  - Today section action → #7 Train
  - Active Goal card or section action → #13.2 Fitness Goals
  - Purchases row → #6.2 Service Detail
  - Purchases section action / empty state → #6 Experts

## Data touched

See [../../database-v1.md](../../database-v1.md).

- **Reads:**
  - `User.FirstName`, `User.AvatarUrl` (header). (Dashboard no longer carries a Free→Premium upsell banner — removed in favour of point-of-friction hooks elsewhere in the app, per the "discovered when the user actually wants the missing thing" rule in CLAUDE.md.)
  - `FitnessPlan` (active) + `PlannedWorkout` (today's row) + `WorkoutType` (name)
  - `WorkoutSession` (this-week window, current user, ended only)
  - `FitnessGoal` (active — `achievedAt IS NULL`), `UserFitnessProfile.weightKg` (for the "Current" line)
  - `ServiceRequest` (current user) joined to `ExpertService` + `User` (expert)
- **Writes:** none — Dashboard is read-only. All navigation hands writes off to the screen the user lands on (#9 Active Workout, #13.2 Fitness Goals, #6.2 Service Detail).

## Notes / non-obvious

- **No duplication with other tabs.** Active Challenges, friend feed slices, and saved-experts shortcuts were considered and skipped: Social (#11) already does the first two and #6 will own saved-experts when it gets a sub-tab. The dashboard's job is what *no other tab covers*.
- **Today card is one-tap-to-start, not view-first.** #7 Train shows the same workout with a separate "View Workout" button + a primary "Start plan" CTA. Dashboard collapses both into a single tappable card that goes straight to Active Workout — the dashboard is the express lane; #7 is the deliberate one.
- **Stats card has no tap target.** Adding a chevron + linking it to #12 History was tempting, but History is per-session not aggregate — the click destination would feel like a non-sequitur. If a future "Insights" screen lands that aggregates by week, wire it then.
- **Goal progress is timeline-based, not metric-based.** See the Active Goal section above for the reasoning. The "Current X kg · target Y kg" footer is the only metric data we currently have to surface, and it only renders when both numbers exist.
- **Purchases is fed by a seeded sample row** (`esp_001` — Mia's accepted request for Jordan's "1:1 Strength Programming"). Without seed content the section is valid but visually weak in screenshots. New requests prepend live via #6.2's `requestService` action; the chip reflects their `status`.
- **Future Premium hook idea:** a small "ENDS IN 3D · 60% · Run 100km in May" pinned card surfacing the user's most urgent active Challenge could live above This Week. Held back for now to keep dashboard scope tight and avoid stepping on #11's Challenges tab.
- *(An earlier "AI Progress Recap" card was prototyped and pulled — see the "Honest AI rule" in `CLAUDE.md`. Template-driven encouragement copy is context-blind and frequently misleading. Real summaries need genuine analysis from `WorkoutSessionTrack` + `FitnessGoal` data — Premium-scope work.)*
