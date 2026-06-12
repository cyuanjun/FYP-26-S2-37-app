---
screen: 08-plan-detail
role: free
group: main
status: built
---

# 8. Plan Detail

**Purpose:** Read-only view of the user's active AI-generated fitness plan. Shows the full week-by-week schedule, today's workout, personalisation context (Premium), and offers a Regenerate action. Reached from #7 Train's "View plan" link.

(Previously titled "Workout detail" — repurposed since plans are AI-generated, not user-authored.)

## Layout

Vertical, scrollable. **No bottom nav** (sub-page accessed from Train). Back arrow → Train (#7).

## UI elements

### Top bar
- ← back arrow + "YOUR PLAN" or plan name in **Title 1**-ish (26 px `ink` font-black uppercase tracking-tight)

### Plan header (compact)
- Top bar: ← back arrow + small **"YOUR PLAN"** uppercase label (15 px, font-bold, tracking 0.14em) — sub-title-level, leaves room for the plan name below
- Plan name as big display headline (e.g. "8-WEEK LOSE WEIGHT PLAN") in display 28 px font-black uppercase tracking-tight, leading-tight
- **Single meta line** below (no pills): "8 weeks · 4×/week · Intermediate" in **Caption 2** muted uppercase tracking 0.14em. **Only plan parameters** — difficulty/frequency/duration. Tier (Personalised vs Basic) is intentionally NOT mixed in here because "Intermediate" + "Basic" together reads as a difficulty-scale (it isn't) and confuses users.
- **Premium-only tier badge** on the right of the meta row: outlined `accent` "PERSONALISED" pill (Caption 2). For Free users, no badge is shown — the upgrade banner below already handles that messaging.
- AI description paragraph below in **Footnote** (13 px `muted` leading-relaxed)

### Description
Brief AI-generated paragraph below the header (e.g. "A 4-week running-focused programme that builds endurance through progressive distance increases. Designed for your Intermediate level and Lose Weight goal.").

### Schedule view
**Vertical list per week** (not a grid — grids on a 402 px width truncate workout names to the point of unreadability).

- Each week gets a small **"WEEK N"** header in `muted` Caption 2, with **"· CURRENT"** in `accent` appended for the active week
- Below: a `surface` card with `divide-y divide-faint` rows — **only days that have a workout** (no rest-day rows; reduces noise)
- Each row is a **tap target** (`<button>`) — opens the Workout Detail modal (see below)
- Row layout (left → right):
  - Day abbreviation ("MON" / "WED" / etc.) in **Caption 2** uppercase mono — `muted` normally, `accent` for today's row
  - Workout name (`PlannedWorkout.name`, e.g. "Full Body Strength") in **Subheadline** (15 px `ink` font-semibold) — truncates on overflow
  - Duration on the right in **Footnote** mono (`30m`) — `accent` colour for today's row, `muted` otherwise
  - Faint chevron-right at the far edge as a tap affordance
- Today's row has a subtle `accent/10` background tint + the day label and duration both flip to `accent`. **No "TODAY" text pill** — the colour shifts are sufficient and adding a pill would push the duration out of its right-edge alignment.
- **Descriptor is no longer inline** — it lives in the modal instead. Keeps each row to a single line so the week card stays scannable at a glance, and gives Premium room to expose richer coaching content (sets/reps, target HR zones, cues) per workout without bloating the list.

Skipping rest days keeps each card focused on the 4 actual workouts per week, fully readable at phone width.

### Workout Detail modal
Tap any row → centred `Modal`:
- Eyebrow: `WEEK N · DAY` in Caption 2 muted; today's row appends `· TODAY` in `accent`
- Workout name in display 24 px font-black uppercase
- "Type · Duration" sub-line in **Footnote** muted (e.g. "Strength · 45 min")
- Full descriptor paragraph in **Subheadline** ink
- **Free-only**: lime-tinted hint banner — "⚡ Upgrade to Premium for sets, reps, target zones, and coaching cues." This is where the Premium upgrade pitch lives at the point of friction, separate from the page-top banner.
- **Premium-only (future)**: structured workout breakdown — sets/reps for strength, intervals + target paces for runs, target HR zones, coaching cues. Same modal, richer body.
- **Today only**: primary `▶ Start workout` accent button → opens #9 Active Workout for that PlannedWorkout, closes the modal first
- Text-link "Close" to dismiss


### Actions row (sticky bottom or inline at bottom of content)
- **Primary:** "Start today's workout" — full-width `accent` button → opens #9 Active Workout
- **Secondary text link:** "Regenerate plan" → opens confirmation modal
  - For Free users with `RegeneratedCount >= 1` this month: button disabled with "Upgrade for unlimited" tooltip/text below
  - For Premium: always enabled

## Regenerate flow

Tapping Regenerate opens a `Modal`:
- Title: "Generate a new plan?"
- Body: "Your current plan will be replaced. Workout history stays." (for Premium); plus "1 regeneration left this month" (for Free)
- Primary: "Generate" → calls AI mock function, swaps plan, increments `RegeneratedCount`, sets old plan's `CompletedAt`
- Secondary: "Cancel" → dismiss

## Edges

- **From:** Train (#7) — "View plan" link from Active Plan card
- **To:**
  - Back (←) → Train (#7) — hard-wired `Link`
  - Active Workout (#9) — "Start today's workout"
  - Upgrade to Premium (#16) — via Free-user upgrade banner / disabled-regen tooltip

## Data touched

See [../../database-v1.md](../../database-v1.md).

- **Reads:** the user's active `FitnessPlan`; all `PlannedWorkout` rows for that plan (joined to `WorkoutType` for names/icons); linked `FitnessGoal` if `FitnessPlan.FitnessGoalID IS NOT NULL`; `User.Role` for Free/Premium UI variants
- **Writes (on Regenerate):** soft-completes old plan (`CompletedAt = now`); inserts a new `FitnessPlan` with `IsActive = true` + fresh `PlannedWorkout` rows; increments the regeneration counter for the user (per-month)

## Notes / non-obvious

- **"AI" is mock.** The regeneration function deterministically constructs a plan from the user's `FitnessGoal` + `UserFitnessProfile`. No external API call. Premium variants include richer logic (e.g. exclude high-impact workouts when `UserInjury` includes "Knee pain").
- **Regeneration limit (Free).** Enforced client-side via `FitnessPlan.RegeneratedCount` on the active plan, reset monthly server-side in production. For the FYP mock, just block when count ≥ 1.
- **Old plans aren't deleted.** Setting `CompletedAt` retains history — useful for future "your past plans" or comparison features. Only one plan has `IsActive = true` at a time.
- **Per-cell tap behaviour**: every schedule row opens the Workout Detail modal. This is the only place the full descriptor is shown (the row stays single-line) and is the natural hook for Premium-only coaching content.
