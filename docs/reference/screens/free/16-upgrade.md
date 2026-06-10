---
screen: 16-upgrade
role: free
group: settings
status: spec-only
---

# 16. Upgrade to Premium

**Purpose:** Marketing surface that pitches the Premium tier. Lists the actual Free vs Premium differences specced across the app, surfaces pricing, and provides the single "Start Premium" action. Reached from any Free-only upsell hook in the app (Plan Detail banner, History monthly-cap banner, Basic Workout Analytics upsell pill, Training Effect upsell link, locked History Detail, "Go Premium" button on Profile, etc.).

## Layout

Vertical, scrollable. **No bottom nav** (sub-page). Three bands:

1. **Header** (`shrink-0`, top) — ← back arrow + "UPGRADE TO PREMIUM" title
2. **Main content** (`flex-1`, scrolls) — Hero headline + Unlocks list
3. **Pricing + CTA** (`shrink-0`, bottom) — Plan card + Start Premium button + footer note

## UI elements

### Top bar
← back arrow + "UPGRADE TO PREMIUM" in 20 px font-black uppercase tracking-tight. Back goes to the previous screen via `navigate(-1)` so the user returns to whichever upsell hook sent them.

### Hero
- Eyebrow row: 24 px accent dash + `GO FURTHER` in Caption 2 accent uppercase tracking-[0.18em]
- Two-line headline: `TRAIN` (ink) over `SMARTER.` (accent), in display 44 px font-black uppercase tracking-tight leading-[0.95]. Trailing period is brand-voice ("FORGOT PASSWORD.", "WORKOUT COMPLETE." pattern).

### Premium Unlocks list
Section labelled `PREMIUM UNLOCKS` (Caption 2 muted) above a 6-item list with `divide-y divide-faint/40` rows. Each row:
- Accent ✓ check icon on the left
- Title in **Subheadline** (15 px ink font-bold)
- One-line subtitle below in **Footnote** (12 px muted)

**The six unlocks** — each maps to a real, built gate, no vapourware:

1. **Personalised AI fitness plans** — *"Built from your profile, goals, and injuries — not a generic template."* Maps to the `PERSONALISED` badge on #8 Plan Detail and `FitnessPlan.isPersonalised`.
2. **Detailed workout breakdowns** — *"Sets, reps, target HR zones, and coaching cues for every planned workout."* **Built.** Workout Detail modal Premium expansion: generic `PlannedWorkout.segments` (sets×reps / zones / intervals — any activity) + `coachingCues`; HR ranges derived from the user's age, strength intensity as RPE. Free sees a teaser.
3. **Advanced session insights** — *"Zone time, pace splits, cadence quality, and trends across recent sessions."* **Built.** Training Effect breakdown (aerobic/anaerobic split + recovery hours) on #10/#12.1, the #12.1 **Graphs** (HR/pace/cadence/elevation), and the #12.2 **Advanced Workout Analytics** trends (weekly volume / HR / load / HR zones / personal bests + the ACWR workload-ratio estimate). *(The standalone "AI Session Summary" card that previously carried some of this was cut — it only restated the metric tiles.)*
4. **Unlimited workout history** — *"Every session, forever — plus the all-time view in Basic Workout Analytics and the full Advanced Workout Analytics drill-in."* **Built.** #12 History monthly-cap removal + Basic Workout Analytics `All` pill + #12.2 Advanced. *(Custom date-range picker dropped from the claim — not built; `All` covers full-range.)*
5. **Smart reminders** — *"Reminders that adapt to your schedule, plus load-based recovery alerts."* **Built.** #13.4 adaptive treatment on workout reminders (plan/history-derived timing) + Premium-only `rest_alert`.
6. **Unlimited plan regenerations** — *"Adjust your plan as often as you need (Free is capped at 1 per month)."* Maps to #8 Plan Detail regen-limit removal.

(Reminders are back as a Premium bullet, but only the **adaptive** layer is gated — Free still gets basic on/off reminders via #13.4. Plan duration is not a paywall.)

### Pricing card
Surface-on-bg card with thick accent border (`border-2 border-accent`):
- Left: "Premium Monthly" in **Body** ink font-bold + "Cancel anytime" in Caption 2 muted below
- Right: `$9.99` in display 24 px accent tabular-nums + `/ mo` in Caption 2 muted below

### CTA + footer
- **START PREMIUM** — full-width filled-accent button, 17 px font-black uppercase tracking-wider, accent shadow
- Below: `Expert services billed separately` in Caption 2 muted centred — flag for the future Expert-trainer flow (#6) which has its own billing

## Edges

- **From:** any Free-tier upsell hook in the app:
  - #5 Dashboard — "Go Premium" banner (Free only)
  - #8 Plan Detail — page-top upgrade banner + Workout Detail modal hint
  - #10 Workout Summary — Training Effect "See full breakdown" link
  - #12 History — monthly-cap banner + Basic Workout Analytics "Unlock with Premium" pill
  - #12.1 History Detail — locked-state CTA for out-of-cap sessions + Training Effect upsell link
  - #13 Profile — "Go Premium" pill in the top bar
- **To:**
  - Back (←) → previous screen via `navigate(-1)`
  - On "Start Premium" tap → **mock flips `User.Role` to `premium`** and navigates to #13 Profile so the user can see Premium variants of upsell hooks immediately (history banner gone, "All" pill appears, etc.)

## Data touched

See [../../database-v1.md](../../database-v1.md).

- **Reads:** none (pure marketing surface; pricing is hardcoded in v1)
- **Writes (Start Premium, mock):** `User.Role = 'premium'`. Production wires this to an actual payment processor (Stripe, in-app purchase, etc.) — `Role` only flips after a successful charge confirmation webhook.

## Notes / non-obvious

- **No demo / preview of Premium features.** Earlier drafts considered embedding mini live previews of the Premium Session Summary etc. inside the upgrade card — chose not to. The marketing pitch is the list itself; users discover features at the point of friction (locked banners across the app) rather than browsing a feature catalog here.
- **One plan, one price.** Single Premium Monthly tier at $9.99 — keeps the decision binary. Annual/lifetime tiers can land later as a second card stacked above the monthly one.
- **Bullets must stay honest.** Every line on this screen has to map to a real spec'd Free vs Premium difference. If a bullet doesn't have a corresponding gating point elsewhere in the app, either build the gate or drop the bullet — otherwise users upgrade expecting things that aren't there.
- **The mock immediately flips `Role`.** In production this only happens after a real payment webhook. The instant flip in the mock is to make upsell-hook behaviour testable (does the History banner disappear? does the "All" pill appear?) without standing up a fake payment flow.
- **"Expert services billed separately"** flags that the Expert-trainer flow (#6, deferred) charges per-session/per-program independently of the Premium subscription. Reduces confusion when that flow lands.
