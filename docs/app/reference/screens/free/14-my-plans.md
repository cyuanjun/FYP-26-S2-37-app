---
screen: 14-my-plans
role: free
group: main
status: built
---

# 14 — My Plans

[← back to screens index](../../screens-v1.md)

**Purpose:** Dedicated list of generated training plans. Users can see the active AI-suggested plan, review saved/inactive plans, open each plan's full schedule, and choose which saved plan to use.

Reached from the **"VIEW PLANS ›"** action on #7 Train's AI Suggested Plan section.

## Layout

Vertical, scrollable sub-page. **No bottom nav**; the app bar back arrow returns to Train.

1. **App bar** — back arrow + "MY PLANS" title
2. **Active section** — shown when the user has an active plan
3. **Saved section** — inactive generated plans, newest-first from the gateway result
4. **Empty state** — shown when the user has no generated plans yet

## UI Elements

### Plan Card

Each generated plan appears as a tappable surface card.

- Plan name as the primary label, e.g. "Endurance Elevation — 12-week plan"
- Meta line: `{durationWeeks} weeks · {workoutsPerWeek}x/week · Basic/Personalised`
- Optional started date: `Started 13 Jun 2026`
- Active badge: `ACTIVE`, shown only on the active plan
- Border: accent-tinted for active, faint for saved

Tap a card → #8 Plan Detail for that exact plan.

### Empty State

When no plans exist:

- Title: "No saved plans yet"
- Body: "Set a goal to generate your first AI training plan."
- CTA: **Set a goal** → #13.2 Fitness Goals

## Edges

- **From:**
  - #7 Train — `VIEW PLANS ›`
- **To:**
  - Back → #7 Train
  - #8 Plan Detail — tap any active/saved plan card
  - #13.2 Fitness Goals — empty-state `Set a goal`

## Data Touched

See [../../database-v1.md](../../database-v1.md).

- **Reads:** all `FitnessPlan` rows for the current user's fitness profiles, ordered by active/saved state and creation/start date.
- **Writes:** none directly. Activating a saved plan happens from #8 Plan Detail via `SelectFitnessPlan`.

## Notes / Non-Obvious

- **One active plan at a time.** The backend/gateway deactivates the previous active plan when a saved plan is selected.
- **Saved plans are not deleted.** Regenerating creates a new plan and preserves prior plans for comparison or reactivation.
- **Timeline labels are dynamic.** Cards and detail pages display the generated plan's actual `durationWeeks`, so a 12-week goal shows as a 12-week plan.
- **Different from expert-service plans.** This screen is only for generated training plans. Expert-service engagements are shown through the Experts/service-request flow.
