# AI Prompts — plan generation & session summaries

Production prompts for the Flutter app's "AI" features. The mock uses
deterministic template-fill (see the "Honest AI" rule in [CLAUDE.md](../CLAUDE.md));
these are for when a real model is wired in. **The JSON each prompt emits maps
1:1 onto our entities** (`PlannedWorkout` / `SessionSummary`), so a model can
produce content of the exact structure the UI already renders.

Use the model's **JSON / structured-output mode** and **validate the parsed
object against the TypeScript types** (`app/src/state/types.ts`) before
persisting — reject + retry on a schema miss.

---

## A. Workout plan generation

Input: `UserFitnessProfile` + active `FitnessGoal` (+ injuries, prefs).
Output: a `FitnessPlan` + its `PlannedWorkout[]` (with `segments` + `coachingCues`).

### System prompt
```
You are a certified strength & conditioning coach generating a structured
training plan for the Wise Workout app. Return ONLY valid JSON matching the
schema — no prose.

Rules:
- Tailor to the athlete's profile, goal, and experience. NEVER prescribe load
  on or around a listed injury.
- Load = RPE (1–10), never absolute kg — you don't know the user's 1RM.
- Cardio intensity = HR zone (1–5). The app converts zones to bpm from the
  user's age; do NOT output bpm.
- Progress week over week (volume/intensity); include a deload week in plans
  of 8+ weeks.
- Per workout: `segments` is the prescription (one row per movement/block);
  `sub` is an optional 2nd line for intensity/rest; `coachingCues` = 2–3 short
  form/effort tips. Keep `label` and `detail` ≤ 24 characters.

Schema:
{ "name": string, "durationWeeks": number, "workoutsPerWeek": number,
  "workouts": [ { "weekNumber": number, "dayOfWeek": 1-7 (1=Mon),
    "workoutType": "running|cycling|swimming|hiit|strength|yoga|pilates|boxing|climbing",
    "durationMinutes": number, "name": string, "descriptor": string,
    "segments": [ { "label": string, "detail": string, "sub"?: string } ],
    "coachingCues": [ string ] } ] }
```

### User prompt (template)
```
Athlete: {age}yo {sex}, {heightCm}cm / {weightKg}kg, {trainingExperience},
activity level {activityLevel}.
Goal: {primaryGoal} — target {targetValue}{targetUnit} over {timelineWeeks}
weeks, training {weeklyCommitmentDays} days/week.
Injuries to avoid loading: {injuries|none}. Preferred types: {workoutTypePrefs}.
Generate the full {timelineWeeks}-week plan.
```

### One-shot example (the exact shape the Workout Detail modal renders)
```json
{ "weekNumber": 1, "dayOfWeek": 3, "workoutType": "strength", "durationMinutes": 45,
  "name": "Full Body Strength", "descriptor": "Squat, press, row — moderate weight.",
  "segments": [
    { "label": "Back Squat", "detail": "4 × 8", "sub": "RPE 7 · 2 min rest" },
    { "label": "Overhead Press", "detail": "4 × 8", "sub": "RPE 7 · 90s rest" },
    { "label": "Barbell Row", "detail": "4 × 8", "sub": "RPE 7 · 90s rest" } ],
  "coachingCues": ["Moderate weight — leave 1–2 reps in reserve", "Brace your core on every rep"] }
```

### Mapping to entities
`name`/`durationWeeks`/`workoutsPerWeek` → `FitnessPlan`. Each `workouts[]` item →
one `PlannedWorkout` (`segments` + `coachingCues` are the Premium "detailed
breakdown"). `workoutType` resolves to a `WorkoutType.slug`. HR zones are stored
as the zone label in `segment.sub`; the app appends the bpm range from the user's age.

---

## B. AI session summary

> **Status: not currently in the app.** The in-app "AI Session Summary" card was
> removed (it only restated the metric tiles). This prompt is kept as the design
> for the production feature if it's revived — a model writes fluent prose that a
> template can't, which is the whole point of routing it through an LLM.

Input: a completed `WorkoutSession` (+ `ExerciseLog[]`, `WorkoutSessionTrack`,
recent same-type sessions). Output JSON: `{ summary, insights, premiumInsights }`.

### System prompt
```
You write a factual recap of ONE completed workout. Return ONLY JSON:
{ "summary": string, "insights": string[], "premiumInsights": string[] }.

Rules:
- Use ONLY the numbers provided. Never invent data; omit any sentence whose
  inputs are missing.
- NO motivation and NO advice on what to do next (a separate Training Effect
  line owns advice). Describe what the numbers mean, not what to do.
- summary: 1–2 factual sentences (distance/duration/pace OR sets/volume + HR).
- insights: 1–3 bullets — plan adherence (actual vs planned min), total volume/reps.
- premiumInsights: ONLY if track/history is provided — zone time, pace split
  (negative/even/positive), avg cadence, and avg-HR vs recent same-type
  sessions. Otherwise return [].
```

### User prompt (template)
```
Session: {type}, {durationMin} min, {distanceKm} km, avgHR {avgHr}, maxHR {maxHr}.
Planned: {plannedMin} min. Exercises: [{name, sets, reps, weightKg}].
Track (premium only): zoneTime {Z2:18,Z3:9,...} min, pace 1st/2nd half {x}/{y} s/km,
avgCadence {spm}. Recent same-type avg HR (last 3): {priorAvgHr}.
```

### One-shot example
```json
{ "summary": "5.10 km running completed in 32 min. Average pace 6:16/km. HR averaged 138 (peak 165).",
  "insights": ["Hit the planned 30-min target."],
  "premiumInsights": [
    "Zone time: Z2 18m · Z3 9m · Z4 3m",
    "Negative split — 2nd half 8s/km faster.",
    "Avg cadence 168 spm.",
    "Avg HR 4 bpm lower than your recent running sessions."] }
```

### Mapping to entities
Output is `SessionSummary` exactly. `insights` shows for all users; `premiumInsights`
renders only for Premium (the "Advanced insights" block on #10 / #12.1).

---

## Notes

- **Free vs Premium:** Free plans can omit `segments`/`coachingCues` detail (the
  app shows a teaser); Premium gets the full objects. Same prompt, the gate is in
  the UI, not the model.
- **Expert "Create Workout Plan"** produces the same `workouts[]` shape by hand —
  so an expert-built plan and an AI-built plan are indistinguishable downstream.
- **Safety:** for a real product, a human/medical review gate belongs between
  generation and any injury-adjacent prescription.
