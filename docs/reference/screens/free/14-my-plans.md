---
screen: 14-my-plans
role: free
group: main
status: spec-only
---

# 14 — My Plans

[← back to screens index](../../screens-v1.md)

**Purpose:** A dedicated home for all the expert services the user has requested — Active engagements (accepted), Pending requests (waiting for the expert), and Declined ones. Replaces the small "My Purchases" section on #5 Dashboard as the canonical "what am I signed up for" surface; Dashboard keeps a 3-item preview that links here via "View all".

Reached from the **"View all ›"** action on Dashboard's My Plans section. (Future: a Profile menu row entry once usage justifies promoting it further. Not yet a bottom-nav tab — see Notes.)

## Layout

Vertical, scrollable. **Has bottom nav** (Home tab stays active — My Plans is a destination off Dashboard, not its own nav slot).

1. **Top bar (fixed)** — back arrow + "MY PLANS" title (Title 1, 28 px ink font-black uppercase)
2. **Status filter chips (fixed)** — Active · Pending · Declined, each with a count (`Active · 2`)
3. **Section header** (`muted` 11px, uppercase, tracking-wide) — section title matches the active tab
4. **List of request cards** (`flex-1`, scrolls) — one card per ServiceRequest in the active tab
5. **Bottom nav**

## UI elements

### Status filter chips
- Same pattern as #21 Expert Services (consistent "filter a list by status" UX across roles)
- Active chip = `text-accent ring-1 ring-accent`; inactive = `text-muted bg-surface-2`
- Format: `Active · 2` (label · count) — counts come from the full set, not the filtered subset, so a user can see at a glance how many they have in each bucket without switching tabs

### Request card (one per row)
- `bg-surface rounded-2xl p-4 ring-1 ring-faint` (matches the Dashboard preview card to keep visual continuity)
- Left: service name (Body, 14 px ink font-bold, truncate) over expert name + relative time (Caption 2, 11 px muted, truncate)
- Right: price in Body font-black (no status chip — the tab itself is the status filter, so the chip would be redundant)
- Tap → `/free/06.2-service-detail?id={expertServiceId}` — the listing page already shows the deliverables for this engagement + the Leave-a-review CTA

### Empty states (per tab)
- **Active:** "No active plans yet. Browse experts to get started." + `Browse experts ›` link → #6 Experts
- **Pending:** "No pending requests."
- **Declined:** "No declined requests."

Colours from [../../palette.md](../../palette.md), type sizes from [../../typography.md](../../typography.md). Reuses: `BottomNav`. No new components — card pattern is inline (matches the Dashboard preview to keep one canonical visual treatment).

## Edges

- **From:**
  - **#5 Dashboard** — "View all ›" link in the My plans section header (only renders when there's ≥1 request). The Dashboard section now shows a 3-card preview; this page holds the full list with status filtering.
- **To:**
  - Back (via ←) → #5 Dashboard — Dashboard is the only entry point in v1, so hard-wired rather than `navigate(-1)`. If a Profile entry is added later, revisit.
  - **#6.2 Service Detail** — every card taps through to the service listing the request is for. From #6.2 the user sees deliverables sent by the expert + the Leave-a-review CTA when status is `completed`.
  - **#6 Experts** — empty-state "Browse experts ›" link on the Active tab.

## Data touched

See [../../database-v1.md](../../database-v1.md).

- **Reads:** all `ServiceRequest` rows for the current user; all `ExpertService` rows (to resolve the service name per request); all `User` rows with `role = 'expert'` (to resolve the expert name per request, via `otherUsers`).
- **Writes:** none — read-only list. State transitions happen on #6.2 (Submit Request → status `pending`) or on #22 Expert Requests (`updateRequestStatus`: `pending` → `completed` / `cancelled`).

## Notes / non-obvious

- **Tab → status mapping.** `Active` = `completed` (expert accepted; the engagement is ongoing — the mock has no separate "finished engagement" lifecycle, so `completed` is the active state). `Pending` = `pending`. `Declined` = `cancelled`. If a "closed/archived" engagement state is ever added, it gets a fourth tab (likely "Past").
- **No "View all" when empty.** The Dashboard section header link only renders when the user has at least one request — otherwise the "Browse experts ›" CTA takes its place. Keeps the header from offering a dead end.
- **Card is the same on Dashboard preview and here.** Both surfaces use the same `service name / expert · time / price` row so the visual identity of a "plan" is consistent — moving between Dashboard preview and the full list feels like the same content, not two designs.
- **Why not a bottom-nav tab?** Considered (would replace History; History would move under Train). Decided against in v1 — History is a heavily-used surface and demoting it to a sub-tab would cost discoverability. My Plans starts as a Dashboard-accessed destination; if usage justifies promoting it (e.g., users with many concurrent expert engagements), revisit then. See conversation notes for the full tradeoff.
- **Premium (future):** filter by expert, search by service name, sort by status / date / price, export receipt-style summary for tax/budgeting, see a "spent this month" total at the top.
