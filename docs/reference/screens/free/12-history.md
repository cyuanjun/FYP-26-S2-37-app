---
screen: 12-history
role: free
group: main
status: built
---

# 12. History (tab)

**Purpose:** Browse past `WorkoutSession`s. Lets the user see what they've done, scan trends at a glance, and tap into any session for a full read-only recap. Reached via the History tab in the bottom nav.

## Layout

Has **bottom nav** (History tab active). Three vertical bands:

1. **Header** (`shrink-0`, top) — section title (`TabHeader` title variant — no avatar)
2. **Aggregates strip** (`shrink-0`) — three at-a-glance stat tiles for the current week
3. **Main content** (`flex-1`, scrolls) — sessions list grouped by relative week

## UI elements

### Basic Workout Analytics card
Sits at the top of the scrollable main area (above the session list). Replaces the earlier "OVERALL" aggregates strip — same numbers plus a chosen window, a vs-prior-period comparison, and a one-line analysis.

Section labelled `BASIC WORKOUT ANALYTICS` (Caption 2 muted uppercase) above the controls. (Previously labelled "Exercise Effect Estimates" to mirror the FYP brief's wording — renamed because most of what the card shows is stats, not estimates. The honest "analytics" framing matches the Premium counterpart on #12.2.) Internally still called the "Period Analysis card" in code / `PeriodAnalysisCard.tsx`.

**Period selector** — pill bar sits **inside the card** at the top (above the period label) so the controls + the data they drive read as one unit. Active pill = filled accent; inactive pills = `bg-bg` with faint border (slightly recessed against the surface card behind them). Default is **Week** because it lines up with how plans are structured and provides enough data to compare meaningfully week-to-week.

- **Free users:** 3 pills — `Day · Week · Month`. The `All` pill is hidden because Free's monthly cap already bounds visible data to the current month, making `All` functionally identical to `Month` — showing both creates redundant noise. The bottom upsell banner handles Premium discovery for the wider window.
- **Premium users:** 4 pills — `Day · Week · Month · All`.

Period semantics:
- **Day** → today's 00:00 → 24:00 UTC. Prior period: yesterday.
- **Week** → this Mon–Sun. Prior: last Mon–Sun.
- **Month** → this calendar month (matches the Free cap window). Prior: last calendar month.
- **All** (Premium only) → all sessions ever. No prior comparison (no comparable older window).

**Card body:**
- **Period label row** — period name on the left, comparison label on the right (e.g. `THIS WEEK` ··· `VS LAST WEEK`), aligned with a flex-between. Labels: `Today` (Day) / `This week` (Week) / `This month` (Month) / `All time` (All — Premium only). Comparison label is hidden when there's no comparable prior (All period).
- **Five metric tiles** split across two rows so each number has room to breathe (a single 5-up row at phone width truncates 4-digit calorie counts to `1,…`):
  - **Volume row (3 tiles)** — *what you did*: **Sessions** (count), **Active min** (sum of `DurationSeconds / 60`), **Calories** (sum of `CaloriesBurned`)
  - **Intensity row (2 tiles)** — *how hard it was*: **Avg HR** (duration-weighted average across sessions with `AvgHeartRate IS NOT NULL`), **Max HR** (single highest `MaxHeartRate` across the period)
  Tiles show `—` when the underlying field is null (e.g. manual sessions with no HR).
- **Per-tile delta** — when a comparable prior period exists, each tile renders its own signed delta **below the label** (`↑ 1` / `↓ 12`) in Caption 2 tabular-nums. Zero deltas hide; HR-null tiles hide. Arrows use **stock-market colouring**: `↑` in `accent` (lime green), `↓` in `danger` (red). The colour purely encodes direction; the user interprets meaning per metric (e.g. `↑ Max HR` reads as "more intense session", which may be good or bad depending on training intent). The `VS LAST WEEK` / `VS YESTERDAY` / `VS LAST MONTH` caption on the right side of the period-label row tells them what the arrows compare against.
- **No canned "analysis sentence."** Earlier versions had a band-derived line ("Strong week — keep the rhythm.", "Easing back in. One more session this week?") but it was removed — those template sentences pretend to be insight while being context-blind (don't know the user's plan, injury, intent) and frequently came across as patronising or wrong. The per-tile deltas carry enough signal on their own. Premium will replace this with *real* analysis pulling from `WorkoutSessionTrack` + `FitnessGoal` + `FeelRating` data.
- **Free-only Premium upsell button** — full-width pill button at the bottom of the card: tinted accent background (`bg-accent/15`) with accent ring + accent text, copy `⚡ Unlock with Premium →`. Single-line on phone width. Pill shape distinguishes it as an action affordance from the surrounding content text. Routes to #16.

### Free-tier monthly cap × Period selector
The selector respects the existing Free monthly cap. For Free users:
- **Month** shows the current calendar month (where all visible data lives anyway)
- **All** is omitted from the selector — would just duplicate Month for capped users
- The Premium upsell banner at the bottom of the page explains the cap + how to unlock lifetime history
- Premium users see the full lifetime when `All` is selected

The card uses the **already-cap-filtered** session set, so the comparison line never reveals data the user can't see. A Free user on Month → "vs last month" shows the deltas computed against last month *only if* last month has visible sessions (i.e. never for Free at v1, since the cap hides last month). If there's no prior data, the comparison is hidden.

**Why a switchable Period card beats the old static OVERALL strip.** The previous version gave a single "overall" snapshot (sessions / min / streak) with no period choice — useful for vague tracking, not actionable. The Period card lets the user ask specific questions ("how did this week go?", "how was May vs April?") without leaving the screen. It also surfaces calories + avg/max HR which the OVERALL strip omitted — matching the requirements ask for short-term + long-term exercise effect estimates.

### Session list
**Grouped vertically by relative week**, most recent first:
- **THIS WEEK** — sessions whose `EndedAt` falls in today's Mon–Sun
- **LAST WEEK** — the prior Mon–Sun
- **EARLIER** — everything older, just chronological

Each group has a `muted` Caption 2 header. Below it: a vertical stack of **standalone `WorkoutListCard`s** (Strava-style cards, one per session, separated by gap rather than joined as divided rows). The earlier "joined rows" treatment was replaced because individual cards have room for the per-session metric strip without truncating numbers.

**`WorkoutListCard` layout** — a shared component also used in the #11 Social embedded workout-share card. Surface card with rounded corners + faint ring:
- **Top row:** workout-type emoji (22 px, per slug — 🏃 running, 🚴 cycling, 🏊 swimming, 💪 strength, 🧘 yoga, 🤸 pilates, ⚡ hiit, 🥊 boxing, 🧗 climbing) + workout name (`customName ?? workoutType.name`, Subheadline ink font-bold, truncated) + faint chevron-right
- **Meta row:** relative date (`Today` / `Yesterday` / `Wed 13 May`) · duration in `X min` (Caption 2 muted)
- **Divider line** (faint, 60 % opacity)
- **3-column metric strip** — type-aware tiles, each with a big value (15 px ink font-black tabular-nums) above a small unit/label (10 px muted uppercase):
  - **Cardio** (`running`, `cycling`, `swimming`, `hiit`): **Distance** (km) · **Pace** (/km) · **Avg HR** (avg bpm). Falls back to `—` if the underlying field is null.
  - **Non-cardio with logged exercises**: **N exercises** · **N sets** · **Avg HR** (avg bpm)
  - **Non-cardio without logs** (e.g. yoga, manual entry): **Calories** (kcal) · **Avg HR** · **Max HR**

Tap any card → opens **#12.1 History Detail** (read-only recap).

### Search (Premium-only)
A search row sits **above the Basic Workout Analytics card**, scoped to whatever sessions are currently visible (so Premium with no period filter searches their full lifetime history).

- **Premium:** real `<input>` with a magnifying-glass icon + `Search history by name or type` placeholder; clearing the query (× button) restores the unfiltered list. Match is a case-insensitive substring against `WorkoutSession.customName` concatenated with the resolved `WorkoutType.name`. The Basic Workout Analytics aggregates and session groups both react to the filter — typing instantly narrows everything below.
- **Free:** the same row slot renders as a **locked pill** — outlined `muted` text + 🔒 lock icon + `Search history` label + an accent `PREMIUM` chip on the right. Tapping it routes to **#16 Upgrade** (point-of-friction upsell, same pattern as the other Free-locked surfaces). Free users have a hard monthly cap on visible history (~30 sessions max), so search would be over-engineering for the volume they'd see — locking the input doubles as a Premium discovery hook *and* a polite way to say "you don't actually need this yet".

### Empty state
When the user has no ended sessions yet: a single centred message in `muted` — "No workouts yet. Start one from Train." When Premium has typed a query with zero matches, the message becomes "No history matches \"{query}\"." so it reads as a search miss, not a "you haven't trained" reproach.

### Free-tier monthly cap
**Free users only see the current calendar month.** History resets on the 1st of every month — sessions from prior months become locked (still stored, not deleted; surfaceable when the user upgrades).

- **List filter:** sessions with `EndedAt < first-of-current-month` are removed from the group buckets and aggregates
- **Bottom banner:** a lime-tinted upsell card sits at the bottom of the scroll area (below the session groups) — keeps the top of the page focused on actionable info (period analysis, recent sessions) and surfaces the cap notice as the user reaches the end of their history naturally:
  > **Free history covers {Month} only.** {N} earlier sessions hidden. Resets {next reset date}.
  > ⚡ Upgrade for full history →
- **Banner is always shown for Free users**, even with zero hidden sessions, so the cap is discoverable before they hit it
- **Premium users:** no filter, no banner — they see the full history end-to-end

Aggregates respect the cap: "Sessions this week" / "Active min" / "Day streak" only count visible sessions, so the numbers match what's on screen. This week's window can straddle a month boundary — if the user opens History on June 2, the "This Week" group only shows June 1–2 (May 31 is hidden by the cap).

Deep-linking to a locked session's #12.1 Detail page also blocks — see the Detail spec.

## Edges

- **From:** Bottom nav History tab (from any other tab)
- **To:**
  - History Detail (#12.1) via row tap
  - Bottom-nav targets: Home (#5), Experts (#6), Train (#7), Social (#11)

## Data touched

See [../../database-v1.md](../../database-v1.md).

- **Reads:** all `WorkoutSession` rows for the current user where `EndedAt IS NOT NULL`; joined to `WorkoutType` (icon + name) and `PlannedWorkout` (for the display name override); `ExerciseLog` count per session for the right-edge metric on non-cardio rows
- **Writes:** none

## Notes / non-obvious

- **Only ended sessions appear.** Sessions where `EndedAt IS NULL` are in-progress (Active Workout screen owns them); History waits until the user finishes via End → Save.
- **Aggregates are derived per render**, not cached. With ~1 session/day per active user, the volume is small enough that recomputing is fine. Production could memoize per week-window.
- ~~**No filtering / search in v1.**~~ *(Superseded 9 Jul: Premium search shipped per §Search above; the locked pill routes Free to #16.)*
- **No delete affordance on the list.** Delete lives on #12.1 Detail so it's always a deliberate two-tap action (open detail → delete with confirm).
- **Cap is calendar-month, not rolling 30 days.** Resetting on the 1st gives users a predictable boundary they can plan around ("export June stats by July 1"); a rolling window would make the goalposts move daily and create surprise data loss. Older sessions are kept in the DB so an upgrade restores everything instantly — no migration needed.
- **This card is the Free version. Premium drills into the richer #12.2 Advanced Workout Analytics** via the `Advanced ›` action — adding ACWR (workload ratio estimate with bands), HR zone stacked bar (Karvonen %HRR), weekly trend bars for volume / HR / load over 4w / 3mo / 1y / All, and a personal-bests grid. Same `WorkoutSession` data, just more dimensions and a longer time horizon.
