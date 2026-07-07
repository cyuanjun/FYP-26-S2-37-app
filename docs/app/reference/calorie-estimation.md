# Calorie Estimation — method & accuracy

How Wise Workout estimates calories burned per workout (US16 "basic exercise effect estimate"), and an honest note on how accurate that is.

## Method

The estimate is a **MET (Metabolic Equivalent of Task) formula**, computed at session end and saved to `WorkoutSession.caloriesBurned`:

```
kcal = MET × weight(kg) × duration(hours)
```

- **Code:** `WorkoutType.estimateCalories(...)` in [`lib/entities/workout_type.dart`](../../../app/lib/entities/workout_type.dart) — an entity-owned rule. Called from the `ActiveWorkout` control's `end()` in [`lib/controls/active_workout.dart`](../../../app/lib/controls/active_workout.dart).
- **MET** — a per-activity intensity constant from the Compendium of Physical Activities (running 9.8, hiit 10.0, swimming 8.0, cycling 7.5, rowing 7.0, hiking 6.0, strength 5.0, walking 3.5, pilates 3.0, yoga 2.5). Unknown/custom types fall back to a moderate **4.0**.
- **Weight** — from the user's `FitnessProfile.weightKg`. When unset, a **sex-based population default** is used (`WorkoutType.defaultWeightKg`): **male 70 kg · female 55 kg · other/unset 70 kg**.
- **Duration** — the recorded session length, in hours.

It deliberately does **not** use heart rate, age, height, distance, or actual pace — this is the documented *basic* estimate (US16), not a precision figure.

## Accuracy

Treat the number as a **rough estimate — typically within ≈ ±20–30%** of measured energy expenditure for an individual. Good for trends, relative comparison, and motivation; not precise enough for strict calorie counting / weight-management math. Sources of error, largest first:

1. **One MET per activity, regardless of effort.** "Running" is fixed at 9.8 MET (≈ a set pace); an easy jog vs. a hard tempo run can differ ~2× in real cost, and the app can't distinguish them. This is structural to MET formulas and the dominant error.
2. **Default weight when unset.** The sex-based default can be off by 20–30% for a given person; weight scales the result linearly.
3. **No personalisation beyond weight.** Ignores age, fitness level, body composition, and movement efficiency.
4. **Gross, not net.** `MET × weight × hours` includes the resting calories you'd burn anyway; the *extra* calories from exercising are lower. (Most consumer apps report gross too, so this is consistent with the field.)

It is **most reliable for steady, moderate activities** (walking, easy cycling) and **least reliable for variable-intensity ones** (HIIT, strength, interval runs). The bias is fairly consistent per activity, so day-to-day *comparisons* hold up better than the absolute value. This is the standard method consumer apps use when no heart-rate data is available.

> **For reports/UI:** label it an *estimate*, not a measurement.

## Upgrade path (not built)

The app already captures **heart rate** on wearable sessions, so the natural accuracy upgrade is the **Keytel HR-based formula** (age + sex + weight + average HR), which gets cardio to roughly **±10–15%**. It's a drop-in alternative inside `estimateCalories`, gated on HR being present — additive later, not a refactor.
