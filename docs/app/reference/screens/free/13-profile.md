---
screen: 13-profile
role: free
group: main
status: built
---

# 13. Profile

**Purpose:** The user's account hub — identity, plan tier, fitness goal, headline stats, and entry points to all account-level settings/feedback flows. Reached from the **top-right circular avatar** on Dashboard (and other tab screens, once they're built). Not in the bottom nav.

## Layout

Vertical, scrollable. **No bottom nav** — Profile is a sub-page; back arrow returns to wherever the user came from.

1. **Top bar (fixed)** — back arrow + "PROFILE" title on left, "Go Premium" pill CTA on right
2. **Identity block (centred)** — avatar with edit affordance, name, handle, plan + goal pills
3. **Stats row (3 cols, divided)** — workouts / active days / weekly streak
4. **Menu list (divided rows)** — Account Settings, Fitness Profile, Fitness Goals, Notifications, Submit Feedback
5. **Log out button** — outlined danger

## UI elements

### Top bar
- *Left:* 22 px left-arrow icon + "PROFILE" in **Title 1** (28 px `ink` font-black uppercase tracking-tight)
- *Right:* "GO PREMIUM" pill — `accent` background, `bg`-coloured text, 12 px filled star icon + label in **Caption 2** (11 px font-black uppercase tracking-wider), `rounded-full`, accent glow shadow. Only visible to Free users (hide once `User.Role === 'premium'`).

### Identity block
- 96 × 96 px circular avatar — `surface` background, big "M" initial in `accent` at 40 px font-black. Bottom-right has a 28 × 28 `accent` circle with a 12 px pencil icon (visual affordance for "tap to edit photo"), 3 px `bg` ring to lift it off the avatar.
- Name "MIA PATEL" in **Title 2**-ish (22 px `ink` font-black uppercase tracking-tight)
- Handle "@miapatel" in **Subheadline** (15 px `muted`)

### Stats row
- 3-column grid with vertical `faint` dividers between columns (`divide-x`)
- Each `Stat`: large number in **Title 1**-ish (28 px `ink` font-black tracking-tight) above small label in **Caption 2** (11 px `muted` uppercase tracking 0.12em font-semibold)
- Top + bottom `border-y border-faint` frame the row

### Menu list
- Each row is a `MenuRow`: 24 px emoji icon · label in **Body** (17 px `ink` font-semibold) · chevron-right in `muted`
- `divide-y divide-faint` between rows; full-row hover goes `surface-2`
- Rows wire to:
  - **Account Settings** → `/free/13.3-account-settings`
  - **Fitness Profile** → `/free/13.1-fitness-profile`
  - **Fitness Goals** → `/free/13.2-fitness-goals`
  - **Notifications** → `/free/13.4-notifications`
  - **Submit Feedback** → `/free/13.5-submit-feedback` (currently a stub — see #13.5 spec)

### Log out
- Full-width outlined button — 1 px `danger` border, `danger` text, transparent bg, **Body** (17 px) font-black uppercase tracking-wider, `rounded-2xl`. Hover gives a faint `danger/10` background.
- Clears the active `Session` and routes to #2 Login (clears auth state in real implementation).

Colours from [../../palette.md](../../palette.md), type sizes from [../../typography.md](../../typography.md). Reuses: `MenuRow`, `Stat` from `app/src/components/` (new); inline icons (back arrow, star, pencil, chevron) for now.

## Edges

- **From:** Dashboard (#5) — tap the top-right avatar. (Other tab screens will add the same avatar entry as they're built.)
- **To:**
  - Back (via ←) → Dashboard (#5) — hard-wired rather than `navigate(-1)` because Profile is the canonical avatar destination and Dashboard is the only entry point in the current build. When Experts / Train / Social / History add the avatar entry, revisit this (likely smart-back with `from` query param, or remember the entry tab in state).
  - Upgrade to Premium (#16) → "Go Premium" CTA
  - Fitness Profile (#13.1) — "Fitness Profile" menu row
  - Fitness Goals (#13.2) — "Fitness Goals" menu row
  - Account Settings (#13.3) — "Account Settings" menu row
  - Notifications (#13.4) — "Notifications" menu row
  - Submit Feedback (#13.5, stub) — "Submit Feedback" menu row
  - Login (#2) → "Log out" (after clearing session)

## Data touched

See [../../database-v1.md](../../database-v1.md).

- **Reads:** `User.FirstName`, `User.LastName` (composed for "MIA PATEL"), `User.Username` (new — for "@miapatel"), `User.AvatarUrl` (falls back to initial when null), `User.Role` (toggles "Go Premium" visibility); all `WorkoutSession` rows for current user where `EndedAt IS NOT NULL` (drives the Workouts + Active days tiles)
- **Stats wiring (current build):**
  - **Workouts** = count of ended `WorkoutSession` rows for current user (lifetime, not capped — Profile is identity, not a History-window snapshot, so it bypasses the Free monthly cap intentionally)
  - **Active days** = distinct `YYYY-MM-DD` of `EndedAt` across those sessions
  - **Streak** = `FitnessProfile.currentStreak` formatted as `Nw` (consecutive Mon–Sun weeks with ≥1 ended workout). Recomputed live by `endWorkoutSession` via `lib/levelXp.weeklyStreakFromSessions`.
  - Above the stats row, under the @handle: **Level + XP bar** — level from `floor(FitnessProfile.totalXp / 200) + 1`, bar fills `totalXp mod 200` of `200`. Replaces the old featured-badge chips. (The earlier `Badge` catalog + `UserBadge` junction were dropped in schema-v2 in favour of this XP-based leveling system — math in [src/lib/levelXp.ts](../../../../app/src/lib/levelXp.ts).)
- **Writes (on Log out):** delete the active `Session` row, clear stored token client-side

## Notes / non-obvious

- **Profile is intentionally not a nav tab.** The 5th nav slot went to Experts; Profile uses the top-right avatar from any tab screen as its canonical entry. See [#5 Dashboard](05-dashboard.md) for the avatar pattern.
- **"Go Premium" only renders for Free users.** Once `User.Role` is `premium` or higher, hide the button. In production this is a one-line conditional; in this mock it's always visible since we're modelling the Free user flow.
- **Three menu rows have no destination yet** (Fitness Profile, Fitness Goals, Submit Feedback). They render as clickable buttons that do nothing — placeholders for future sub-screens. When built, they'll likely be `13.x` sub-pages of Profile.
- **Log out is outlined `danger`, not filled.** Destructive actions get `danger` colour but the outlined treatment signals "this is reversible-ish" (you can log back in) — reserve filled `danger` for truly destructive things (delete account, etc.).
