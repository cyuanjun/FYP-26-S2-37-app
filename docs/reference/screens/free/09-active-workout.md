---
screen: 09-active-workout
role: free
group: main
status: built
---

# 9. Active Workout

**Purpose:** The in-session screen during a recorded workout. Shows live elapsed time + live metrics from a `ConnectedDevice` (or manual / phone-sensors fallback), plus pause / end controls. Used for both plan-based and free-form sessions.

## Two phases: pre-start vs in-session

Landing on the screen does **not** start the workout. The user first sees a pre-start view — same layout as the in-session view, but every metric tile is rendered dim with placeholder values, and the central control reads **START**. Tapping Start writes the `WorkoutSession` row and flips every tile live in place. This:
- Gives them a beat to confirm the activity (and swap it, for free-form) or check device source before the clock is running
- Avoids a `WorkoutSession` row being created when the user lands here by accident and backs out
- Keeps the pre-start and in-session screens visually identical so there is no layout jump on Start

### Why the same layout both phases
The pre-start screen is a "preview" of the in-session screen — same tiles, same positions, same big control circle in the same spot. Only the values, the control label (START → PAUSE / RESUME), and a hint subtitle (TAP TO BEGIN → TAP TO PAUSE) change. This means the moment of starting feels like the metrics simply switch on, rather than a navigation event to a different screen.

## Two states: plan-based vs free-form

The screen has the same overall shape in both modes, but several elements **differ meaningfully** based on whether `WorkoutSession.PlannedWorkoutID` is set.

| Element | Plan-based | Free-form (Quick Start) |
|---|---|---|
| Header context | "Week 3 · Planned" (compact muted caption) | "Free Workout" |
| Activity selector pill (bottom-left) | Hidden — activity is locked to `PlannedWorkout.WorkoutTypeID` | Visible — opens a Select Activity modal to swap before/during the session |
| Cardio-section right-edge label | Workout type name (e.g. "RUNNING") | Workout type name (updates live when swapped) |
| Target duration below timer | "of 00:30:00" after Start | Not shown |
| On End → #10 Summary | Shows plan progress strip; advances `FitnessPlan` progress | No plan progress strip; session stands alone |

In code, render the same screen component with conditional sub-elements gated on `session.plannedWorkoutId != null`.

## Layout

Vertical, focused. **No bottom nav.** Background is `bg`. Three vertical bands:

1. **Header** (`shrink-0`, top) — × close button + small caption-2 context label, centred
2. **Big TIME hero** (`shrink-0`) — `TIME` eyebrow + large `HH:MM:SS` display (dim `text-faint` pre-start, `text-ink` once started)
3. **Metric tile grid** (`flex-1`, scrolls if needed) — Base Metrics + Cardio/Strength Metrics sections
4. **Control row** (`shrink-0`, bottom, above safe area) — Activity selector pill (free-form pre-start only) on the left, big circular **Start / Pause / Resume** button in the centre, text-button "End" on the right (in-session only). Subtitle below: `TAP TO BEGIN` / `TAP TO PAUSE` / `TAP TO RESUME`.

## UI elements

### Header
- *Left:* × close button. **Pre-start** = free `navigate(-1)` (no session exists yet). **In-session** = opens End confirmation modal.
- *Centre:* small caption-2 muted label — `Week N · Planned` or `Free Workout`

### TIME hero (top)
- `TIME` eyebrow in Caption 2 muted uppercase
- Big timer in display 52 px font-black tabular-nums tracking-tight
- Pre-start: dim (`text-faint`) and reads `00:00:00`. In-session: live, `text-ink`.
- Plan-based + in-session: `of HH:MM:SS` target line below in Footnote muted

### Today's Workout card (plan-based, both phases)
A surface card positioned **below the metric grids** in the scrollable main area. Carries everything the user needs to know about the planned session — name, target, parent plan, descriptor — and **persists across both pre-start and in-session** so the user can scroll back to remind themselves what they're doing mid-workout without ending the session.

Contents:
- `TODAY'S WORKOUT` eyebrow (Caption 2 muted)
- **Workout name** in display 22 px font-black uppercase (e.g. "FULL BODY STRENGTH")
- Type · target line: `Strength · 45 min target` in muted Footnote
- `From {plan name}` line linking the session to its parent `FitnessPlan` (e.g. "From 8-Week Lose Weight Plan") — surfaces which plan they're inside in case they have multiple in flight historically
- **Descriptor** paragraph in `ink` Subheadline (the longer coaching line)

The card sits below the metrics intentionally — pre-start, the live tiles are dim placeholders, so the workout context immediately reads. In-session, the live tiles are at the top where eyes naturally land, with the reference card just a glance/scroll away. Card is **not** rendered for free-form sessions (no plan context); for those, the Activity selector pill at the bottom-left is enough identity.

### Base Metrics section
2-tile grid:
- **Time** tile (clock icon · `00:00` mm:ss) — duplicates the hero in a compact mm:ss, useful for the at-a-glance row
- **Heart Rate** tile (♥ icon · BPM number with `BPM` unit)

Both dim pre-start, live in-session. HR shows `— —` until a value arrives.

### Cardio Metrics section (cardio activities)
Cardio activities: `running`, `cycling`, `swimming`, `hiit`. 3-tile grid:
- **Distance** (km, 2-decimal)
- **Pace** (mm:ss /km, derived from elapsed / distance)
- **Elev** (m — placeholder 0 in the mock; real device feed in Flutter)

The section header has the activity name (e.g. `RUNNING`) right-aligned on the same row as the `CARDIO METRICS` label, so the user always knows what they're recording without opening the picker.

### Non-cardio activities (strength, yoga, pilates, boxing, climbing, etc.)
**Base Metrics only — no second section.** Time + Heart Rate are the only things we can record automatically for non-cardio activities, so that's all we show. The activity name moves to the right slot of the Base Metrics header (mirroring how Cardio Metrics labels its activity), so the user always sees what they're recording.

Sets / reps / weight are entered post-session on **#10 Workout Summary** — lighter cognitive load than tapping between sets, and matches how strength apps typically capture this.

### Control row (bottom)
- *Left slot (free-form only, both phases):* Activity selector pill — surface-on-bg with the current workout type name + chevron. Opens a `Modal` listing all `WorkoutType` rows; selecting one swaps the activity. Hidden for plan-based sessions (locked to the planned workout type).
- *Centre:* big circular accent button, 120 × 120 px, shadow-xl. Label cycles `START` → `PAUSE` → `RESUME`. This is the primary touch target — everything else is secondary.
- *Right slot (in-session only):* smaller circular `END` button (72 × 72 px) in `danger` red with `ink` text and a danger-tinted shadow → opens End confirmation modal. Smaller than the centre control so the primary pause/resume action keeps visual priority, but the colour + circle shape make ending an unmissable affordance once the session is running.
- *Subtitle below the row:* `TAP TO BEGIN` / `TAP TO PAUSE` / `TAP TO RESUME` in Caption 2 muted uppercase — tells the user what the big circle currently does.

## End-workout flow

Tap End → modal:
- Title: "End workout?"
- Body: "Save your session and see your stats."
- Primary: "Save & Finish" → sets `WorkoutSession.EndedAt`, transitions to #10 Workout Summary
- Secondary: "Cancel" → dismiss, resume

**End never discards.** Even very short sessions (< 1 min) are saved and the user lands on #10 Summary. If the user later regrets the session, they can delete it from #12.1 History Detail's edit mode — there's no Discard on Summary itself. Keeping End purely as "save and stop" prevents a sharp red button from silently throwing away the user's work — deletion is always a deliberate, multi-step decision (open History → Edit → Delete → confirm), never a side-effect of ending.

## Edges

- **From:**
  - Train (#7) plan card — "Start Planned Workout" (plan-based, activity pre-selected)
  - Train (#7) — "Start Freeform Workout" (free-form, no plan)
  - *(As built: Plan Detail (#8) is view-only — it no longer starts a workout)*
- **To:**
  - Workout Summary (#10) — on End → Save & finish
  - Train (#7) — on Discard / Cancel-and-Discard

## Data touched

See [../../database-v1.md](../../database-v1.md).

- **Writes (on Start tap, not on mount):** inserts a new `WorkoutSession` with `StartedAt = now`, `WorkoutTypeID`, `PlannedWorkoutID` (nullable), `ConnectedDeviceID` if a paired device is active, `DataSource` chosen accordingly. Bailing from pre-start writes nothing.
- **Updates during session (every N seconds):** patches `WorkoutSession` with latest `AvgHeartRate`, `MaxHeartRate`, `CaloriesBurned`, `DistanceMeters`. For the mock, we can update on a 1-sec interval with simulated values.
- **Writes (on End):** sets `EndedAt = now`, computes `DurationSeconds`. `FeelRating` and `Notes` are written on #10 Workout Summary.

## Notes / non-obvious

- **Back gesture intentionally disabled mid-session.** Once started, the only way out is the explicit End control — the × in the top bar IS the end, and it's confirmation-gated. Pre-start, the × is a free back (no session exists yet, nothing to lose).
- **Plan progress isn't advanced here.** Advancing happens on #10 Workout Summary (after `FeelRating` is captured) — so a discarded session doesn't pollute plan-completion tracking. Free-form sessions never affect plan progress regardless.
- **Free-form WorkoutType is editable both pre-start and mid-session.** Plan-based sessions lock the type because it came from `PlannedWorkout`. Free-form sessions start with a sensible default (most-recent type) and let the user change it via the bottom-left **Activity selector pill** — taps open the Select Activity modal. The pill is hidden for plan-based sessions.
- **Device disconnection mid-session** doesn't end the session — the metrics tiles just freeze at last known values + show a small "Disconnected" warning. Session continues to record duration. Real production would attempt reconnection.
- **Real-time updates** for the mock: we can use a `setInterval` to bump fake HR/calories/distance values for demo realism. No actual sensor integration.
