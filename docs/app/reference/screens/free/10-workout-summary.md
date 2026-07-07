---
screen: 10-workout-summary
role: free
group: main
status: built
---

# 10. Workout Summary

**Purpose:** Post-session recap. Shows the stats from the just-completed `WorkoutSession`, lets the user record how it felt + add notes, then saves and returns to Train. If the session was plan-based, this is also where plan progress advances.

## Layout

Vertical, celebratory tone. **No bottom nav** (modal-like flow). No back arrow at the top — user finishes through the Save button (or skip).

## UI elements

### Top — completion celebration
- Big centred lime checkmark in a circle (~80 px) — same `CheckIcon` we use in the Forgot-password sent modal, scaled up
- Below: "WORKOUT COMPLETE." in display headline (font-black uppercase tracking-tight, trailing period per brand convention) — same style as "FORGOT PASSWORD."
- Sub-line: plan context if applicable ("Week 3 · Day 2 done") OR "Free workout saved"

### Stats grid
**Type-aware grid.** Cardio gets a 2 × 3 (six tiles), non-cardio collapses to 2 × 2 (four tiles). The metric set per type is chosen so each tile carries information that's actually relevant to what the user did — no `0.00 km` placeholder on a strength session, no invented metrics to pad out a row.

**Cardio** (`running`, `cycling`, `swimming`, `hiit`) — six tiles:
1. **Duration** (e.g. "28:42")
2. **Distance** (e.g. "5.10 km")
3. **Avg Pace** (e.g. "6:18 /km") — derived from duration ÷ distance
4. **Calories** (e.g. "192")
5. **Avg HR** (e.g. "138")
6. **Max HR** (e.g. "165")

**Non-cardio** (`strength`, `yoga`, `pilates`, `boxing`, `climbing`, etc.) — four tiles:
1. **Duration**
2. **Calories**
3. **Avg HR**
4. **Max HR**

For non-cardio, only the metrics we can actually trust to be useful are shown — fewer tiles, but every tile means something. Distance/Pace aren't applicable, Min HR/HR Zone weren't earning their slot.

### Exercises (non-cardio only) — manual entry
Below the stats grid, only for non-cardio sessions. Lets the user record what they actually did set-by-set after the workout (sensors can't capture this — strength training is structured around reps, not continuous output).

- Empty state: a single full-width tile reading **"+ Add what you did (sets, reps, weight)"** that opens the add modal
- Populated state: a `surface` card with one row per logged exercise (`divide-y divide-faint`), plus a "+ Add exercise" row at the bottom
- Each row shows: exercise name + meta line like `4 × 8 · 70 kg` (or `4 × 8 · bodyweight` if `WeightKg` is null), with a faint chevron-right indicating it's a tap target
- Tap an existing row → opens the same modal in **edit** mode (pre-filled) with a **Delete** action available

**Add / Edit modal:**
- Title: `Add exercise` or `Edit exercise`
- **Exercise** text input (free text, autofocus) — e.g. "Back squat"
- **Sets** stepper (−/+, default 3)
- **Reps** stepper (−/+, default 10)
- **Weight (kg)** number input — leave blank for bodyweight; future Premium can store user-preferred unit (kg/lb) and convert
- Primary: **Add** / **Save** — disabled when the name is blank or sets/reps are 0
- Secondary: **Delete** (edit mode only, danger color)
- Tertiary: **Cancel**

Writes to the new `ExerciseLog` entity — many logs per `WorkoutSession`. Each log is independent so the user can refine after the fact (forgot a set, weight was wrong) without touching session-level data.

### Name this workout (optional)
Editable text input between the celebration header and the stats grid. Lets the user name the session right when they remember the context — "Push day at the gym", "Easy morning loop", etc. — instead of having to come back later via #12.1 to rename.

- Section header `NAME THIS WORKOUT`
- Standard text input (same styling as Notes textarea) with **placeholder** = the default name (planned workout name or workout type name) so the user can see what it'll fall back to if left empty
- Writes immediately to `WorkoutSession.CustomName` on each keystroke; empty input → `null` (default cascade re-applies)
- The custom name then renders everywhere the session is shown — History list row, History Detail header — and can still be edited later from #12.1

Naming is intentionally **optional**. Plan-based sessions already have a sensible default ("Full Body Strength") so most users will just skip the input.

### ~~AI Session Summary~~ — REMOVED
An "AI Session Summary" card (factual recap + data-derived insights, Free + a Premium "advanced insights" block) used to sit here. **Cut** — the recap just restated the stat tiles directly above it, and the honest-AI rule (no advice/motivation) left it with no information the tiles didn't already show. The genuinely additive content (zone time, pace splits, cadence, cross-session trends) is better served by #12.1's **graphs** and the Premium **#12.2 Advanced Workout Analytics** screen. The deterministic template also undersold what a real model would write — see [ai-prompts.md](../../../../archive/ai-prompts.md) Prompt B for the production session-summary prompt if it's ever revived.

Slot order: stats grid → **Training Effect** → Exercises → Feel → Notes.


### Training Effect (Free)
A single read of "what this workout cost you" — surfaces training intensity beyond raw duration + calories. Slotted between the Stats grid and the Exercises / Feel sections so the user sees it the moment they finish.

**Free version (this build):**
- Section header `TRAINING EFFECT`
- `surface` card containing:
  - **Band label** (`Low` / `Moderate` / `High` / `Very High`) in display 24 px, coloured per band (Low = info-blue, Moderate = accent, High = gold, Very High = danger)
  - **`· N / 10`** score in muted Footnote tabular-nums next to the band
  - One-sentence advice line in `ink` Subheadline (canned per band — scales the recovery recommendation with the band so a Moderate session doesn't read like it demands rest):
    - Low → "Light session. Great as a warmup or recovery — no rest needed."
    - Moderate → "Solid effort with plenty in reserve. You can train again tomorrow."
    - High → "Strong workout. Plan a lighter day tomorrow to recover."
    - Very High → "Hard session. Prioritise rest and sleep tonight."
  - Free-only: text-link `⚡ See full breakdown with Premium →` → #16

**Compute:** `intensity = avgHr / estMaxHr`, `estMaxHr = 220 - age` (fallback 190 if no DOB). `durationMultiplier = min(2, durationSeconds / 1800)` so a 60 min easy run scores meaningfully higher than a 30 min easy run. `raw = intensity × 10 × (0.6 + 0.4 × durationMultiplier)`, clamped to 1–10 integer. Bands: 1–3 Low / 4–6 Moderate / 7–8 High / 9–10 Very High.

**Empty state:** if `avgHeartRate IS NULL` (manual sessions or HR dropout), the card body says "Heart rate wasn't captured for this session — effect estimate unavailable" instead. The upsell link is omitted (nothing to compare against).

**Premium version (future):** same screen slot, expanded multi-dimensional card. Aerobic effect (0–5), Anaerobic effect (0–5), Muscular load, Recovery hours, HR-zone time bar (Z1–Z5), plan-vs-actual difficulty comparison, 7-day load sparkline. Implemented when #16 Upgrade ships.

### "How did it feel?" chip group
Single-select chips (use existing `Chip` component):
- 🔥 **Great** · 💪 **Good** · 😐 **Okay** · 😣 **Tough**

(Use emoji glyphs per established Profile menu pattern. Stored as `FeelRating` enum.)

### Share to Social (opt-in)
Two-part block right above Notes:

- **Toggle row** — section label `SHARE TO SOCIAL` on the left + an iOS-style switch on the right. Default OFF. Toggling ON calls `createWorkoutSharePost({...})` which inserts a `Post` row of kind `workout_share` pointing at the session; toggling OFF calls `deletePost(postId)` which removes the Post (and cascades its likes + comments). "Is this session shared?" is derived from `posts.find(p => p.workoutSessionId === sessionId)`.
- **Description textarea** — only renders when a workout-share Post exists for the session. Placeholder *"Add a description for the feed (optional)"*, 2 rows. Writes to `Post.body` on each keystroke (empty → `null`). This is the **public caption** shown alongside the workout on the Social feed.

Distinct from Notes below: `Post.body` is what the feed sees; `notes` is owner-only.

(Earlier iterations had `WorkoutSession.isShared` + `WorkoutSession.description` columns. Both moved to `Post` when Social grew to support multiple post types — see the Post entity in [database-v1.md](../../database-v1.md). UI behaviour is identical; just the source of truth changed.)

### Notes field (private)
Optional multi-line text input — "How did it go? (optional)" — writes to `WorkoutSession.notes`. Section label reads `NOTES (private)` so users know unambiguously that this won't be shared, even if they toggle Share above. Notes never appear on Social regardless of share state.

### Action row (bottom)
- **Primary:** "Save & Finish" → commits `FeelRating` + `Notes` + advances plan progress (if applicable) → routes to #7 Train
- **Secondary text link:** "Skip" → returns to #7 Train without committing `FeelRating` / `Notes`. The session row itself (and any `CustomName`, `ExerciseLog` rows, `WorkoutSessionTrack`) **stays saved** — those fields write on the fly as the user enters them, independently of Save & Finish. Skip just means "I don't want to record how it felt or add notes."

To remove a session entirely after the fact, the user goes to #12.1 History Detail → Edit → Delete. There's no Discard action on this screen.

### Plan progress update (visible only when plan-based)
Below the stats, before the action row: a small progress strip
- "Week 3 · 3 of 4 sessions done" + a progress bar
- Animates as it updates on Save

## Edges

- **From:** Active Workout (#9) — Save & finish
- **To:**
  - Train (#7) — on Save / Skip — hard-wired `Link`

## Data touched

See [../../database-v1.md](../../database-v1.md).

- **Reads:** the just-ended `WorkoutSession` (passed in via route param or store reference); the linked `PlannedWorkout` + `FitnessPlan` if plan-based (to compute plan progress); all `ExerciseLog` rows for this session (non-cardio only)
- **Writes (Exercises section, non-cardio):** insert / update / delete `ExerciseLog` rows on the fly as the user adds, edits, or deletes — these writes happen independently of Save & Finish so a partially-entered list isn't lost if the user backs out.
- **Writes (on Save):**
  - Sets `WorkoutSession.FeelRating` and `WorkoutSession.Notes`
  - **Plan advance:** if `PlannedWorkoutID` is set, count completed `WorkoutSession`s linked to the same `FitnessPlan`, update derived progress. No explicit `PlanProgress` row — derived from session count vs `WorkoutsPerWeek × DurationWeeks`.
  - If the plan's final workout was just completed, sets `FitnessPlan.CompletedAt = now` and routes back to Train where the user is prompted to generate a new plan.

## Notes / non-obvious

- **Plan progress is derived, not stored.** Count of `WorkoutSession` rows where `PlannedWorkoutID` belongs to a given `FitnessPlan` = sessions done. Stored progress would drift out of sync if sessions are deleted; derived is safe.
- **Skip is fine.** The session itself is already saved with metrics from #9 — Skip just means the user opted out of `FeelRating`/Notes. The session row stays.
- **Plan completion celebration** is a future polish — on the final session of a plan, the Summary screen could show "PLAN COMPLETE." with an extra celebratory state instead of routing straight back. Defer.
- **Sharing.** No share button in v1. Social posts derive from sessions later (#11 Social).
