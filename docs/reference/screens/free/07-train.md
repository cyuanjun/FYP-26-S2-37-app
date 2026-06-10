---
screen: 07-train
role: free
group: main
status: spec-only
---

# 7. Train (tab)

**Purpose:** Train tab landing. Surfaces the user's active AI-generated fitness plan, today's planned workout, a quick-start path for free-form sessions, and connected-device status. Reached via the Train tab in the bottom nav.

## Layout

Has **bottom nav** (Train tab active). Layout is three bands:

1. **Header** (`shrink-0`, top) — section title + circular avatar button
2. **Main content** (`flex-1`, scrolls) — Active Plan card · Connected Devices status · Upgrade banner (Free only)
3. **Quick Start CTA** (`shrink-0`, sticky just above BottomNav) — always visible regardless of scroll

The Quick Start button is **anchored to the bottom** of the screen (outside the scroll area) so it's always reachable as the "start a session right now" affordance, independent of whether the user has a plan or not.

## UI elements

### Header
- *Left:* "TRAIN" section title in **Title 1**-ish (26 px `ink` font-black uppercase tracking-tight)
- *Right:* (intentionally empty)

**Avatar is Dashboard-only.** Dashboard (#5) uses the personal "Hi, [name]" greeting + top-right circular avatar link to Profile. Train, Experts, Social, and History all use a leaner header — just the section title, **no avatar**. Profile is reached only via the Home tab. The `TabHeader` component's `title` variant enforces this (no avatar slot).

### AI Suggested Plan section
Section header has the label "AI SUGGESTED PLAN" on the left and a "VIEW FULL PLAN ›" link on the right (in `accent`, **Caption 2** uppercase) that opens #8 Plan Detail showing the complete week-by-week schedule.

Below the header: large rounded-2xl `surface` card with 1 px `faint` ring.

- *Top row:* lime ✦ sparkle icon + today's date in **Caption 1** muted (`MON · DD MMM YYYY`) on the left; small outlined "VIEW WORKOUT" pill-button (accent border + accent text, hover tint) on the right — taps open a Modal previewing today's workout (see below)
- *Title:* today's workout **Name** (`PlannedWorkout.name` — e.g. "EASY RUN") in display 28 px font-black uppercase tracking-tight
- *Subtitle:* `${durationMinutes} min · ${descriptor}` in **Subheadline** muted (15 px) — e.g. "30 min · Zone 2 · recovery pace"
- *Primary CTA:* full-width accent button with **▶ play icon + "START PLAN"** in **Subheadline** (15 px) font-black uppercase tracking-wider, accent glow shadow

#### View Workout modal
Tap "VIEW WORKOUT" → opens the **shared Workout Detail modal** (see #8 Plan Detail → Workout Detail modal). Same structure used everywhere a planned workout's details are surfaced — eyebrow shows `WEEK N · DAY · TODAY`, then name, type · duration, descriptor, Free-only Premium hint, and a Start button. Train's variant always renders the Start button (Today is always true here) with the label "Start plan" to match the card's primary CTA.

The pill changed from a passive "SUGGESTED" label to an actionable "VIEW WORKOUT" tap target — preserves the visual position but earns the user an interaction instead of just stating a fact.

**Rest day variant** (plan exists but no workout today): card shows "Today" eyebrow + "Rest day · No workout scheduled" centred. No Start button.

**No-plan variant**: card shows "No Active Plan" + "Set a fitness goal to generate your AI plan" + lime "Set a goal" CTA linking to #13.2.

### Devices section
Section header "DEVICES" + a rounded-2xl `surface` card below.

Card shows the **primary active device** (first non-`phone_sensors` active device, falling back to phone sensors):
- Device icon (⌚ for watches, 💍 Oura, 📱 phone)
- Name (e.g. "Apple Watch") in **Body** font-bold ink
- Capability descriptor below in **Caption 1** muted — derived per device type (e.g. apple_watch → "HR + GPS ready", garmin → "HR + GPS + cadence ready")
- Right: outlined "CONNECTED" pill in accent

Tapping the card opens #7.1 Connected Devices for full management.

Below the card: full-width outlined-faint "+ ADD DEVICE" button. Inline shortcut to the Add Device modal on #7.1.

### Upgrade banner (Free only)
**Deferred** — not shown in current build. Will be added when #16 Upgrade to Premium ships. When live: lime-tinted banner above the sticky CTA linking to #16, hidden for Premium users.

### Sticky CTA — "Start Freeform Workout"
**Outside** the scrollable area, immediately above BottomNav. Always visible regardless of scroll position.
- Full-width **accent** button (filled, not outlined — primary visual weight, matches the plan-based Start button)
- Label: **▶ play icon + "START FREEFORM WORKOUT"** in **Subheadline** (15 px) font-black uppercase tracking-wider, accent glow shadow
- Tap → opens #9 Active Workout in **free-form mode** (`PlannedWorkoutID = null`), defaulting `WorkoutType` to the user's most recently used type (or Running on first use)

## Edges

- **From:** Bottom nav Train tab (from any other tab); Splash/Login on first launch if Train is the chosen post-login destination
- **To:**
  - Profile (#13) via top-right avatar
  - Plan Detail (#8) via "View plan" link
  - Active Workout (#9) via "Start today's workout" (plan-based) or Quick Start button (free-form)
  - Connected Devices (#7.1) via status row
  - Upgrade to Premium (#16) via banner (Free only)
  - Bottom-nav targets: Home (#5), Experts (#6), Social (#11), History (#12)

## Data touched

See [../../database-v1.md](../../database-v1.md).

- **Reads:** `User.FirstName` (greeting), `User.Role` (banner visibility), `User.AvatarUrl` (avatar), active `FitnessPlan` for user (`IsActive = true`), today's `PlannedWorkout` (`WeekNumber + DayOfWeek` derived from plan's `StartedAt` and today's date), all `ConnectedDevice` rows for user (count + active status)
- **Writes:** none directly; all writes happen on the screens you navigate to from here

## Notes / non-obvious

- **"Today's workout" is computed**, not stored. Given `FitnessPlan.StartedAt` and current date, derive `(weekNumber, dayOfWeek)` then look up the matching `PlannedWorkout`. If no workout is scheduled today, show "Rest day".
- **No plan editing** — AI generates. The screen never offers create/edit/delete affordances. Regeneration is the only user control, and it lives on #8 Plan Detail.
- **One active plan at a time.** The query uses `IsActive = true` filter. Activating a new plan deactivates the prior one (soft).
- **Quick Start exists alongside plans.** Even when on a plan, the user can record an ad-hoc session — that session writes a `WorkoutSession` with `PlannedWorkoutID = null` and doesn't affect plan progress.
