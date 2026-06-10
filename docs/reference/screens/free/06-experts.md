---
screen: 06-experts
role: free
group: main
status: spec-only
---

# 6. Experts (tab)

**Purpose:** The discovery surface for paid coaching. Browse the directory of experts, or browse their service listings directly — search across both, filter by specialty, tap into details. The other top-level bottom-nav tab that needed to ship to fill the Experts slot.

Reached from the bottom nav Experts icon.

## Layout

Has **bottom nav** (Experts tab active). Bands top-to-bottom:

1. **Header** (`shrink-0`) — `EXPERTS` title (TabHeader `title` variant, no avatar)
2. **Sub-tab switcher** (`shrink-0`) — two pills: **Experts** (default) and **Service Listings**. Sits above search so the highest-level toggle is the first control after the title — matches the Community / Challenges tab nav on #11 Social.
3. **Search bar** (`shrink-0`) — pill input matching the Find friends / Find challenges pattern on #11; placeholder swaps between `Find experts` / `Find services` based on sub-tab.
4. **Category chips** (`shrink-0`) — single-row horizontal scroller of specialty filters: `All` · `Strength` · `Endurance` · `Mobility` · `Nutrition` · `Recovery` · `Running`. Active chip fills `accent`. The right edge fades out via a CSS `mask-image` gradient so the cut-off rightmost chip reads as a scroll affordance rather than a layout bug; scrollbar is hidden via `[scrollbar-width:none]` + `::-webkit-scrollbar` override.
5. **Results header** (`shrink-0`) — `Results · N {experts|services}` left + `Sort: Top rated` right (sort is non-interactive in v1)
6. **List** (`flex-1`, scrolls) — vertical stack of cards per sub-tab

Search query + category filter are shared state across both sub-tabs — switching sub-tabs preserves both (matches the Challenges-tab sub-tab pattern on #11).

## Sub-tabs

### Experts sub-tab
Lists every `User` with `role = 'expert'` joined to their `ExpertProfile`. Each row is an **ExpertCard**:
- 48 px circular avatar (initials fallback on `surface-2` background)
- Name in display caps + rating `★ 4.9` in accent + review count (muted) — all on one row
- **Follow heart toggle (top-right of card)** — `accent` when followed, `muted` otherwise. Intercepts the parent card's `Link` (`preventDefault + stopPropagation`) so tapping doesn't navigate into Expert Detail. Toggles `User.followedExpertIds` via `toggleFollowExpert`. Same toggle also exists on #6.1 — both surfaces stay in sync via shared state. (Distinct from the user-to-user `Follow` entity in Social, which is mutual friendship; this is a one-way bookmark of marketplace experts.)
- Title (`profile.title`, e.g. "Strength Coach") below
- 2-line truncated `User.bio`
- Footer: `N services · from $X` left + `View profile ›` right

Tap the whole card → **#6.1 Expert Detail** (heart tap doesn't navigate).

### Service Listings sub-tab
Lists every `ExpertService`. Each row is a **ServiceCard**:
- Service name + 1-line description + price in display
- Footer: small avatar + expert name + their rating + `View ›`

Tap the whole card → **#6.2 Service Detail**.

## Search + filter behavior
- Search: free-form case-insensitive `includes` match
  - On Experts sub-tab: searches `firstName + lastName + title + bio + specialties`
  - On Service Listings: searches `service.name + service.description + expert name + expert title`
- Category chips: AND-filter with the search query
  - On Experts sub-tab: matches when the expert's `specialties` array contains the chip's value
  - On Service Listings: matches when `service.category` equals the chip's value
- `All` chip clears the category filter
- Both sub-tabs share the same search query + category state — switching tabs preserves both

## Empty state
When search/filter returns no results: centred muted prompt — *"No experts match "<query>"."* (or `services` based on sub-tab), or `No experts match those filters.` when only the category filter is the cause.

## Edges

- **From:** Bottom nav Experts tab
- **To:**
  - Expert Detail (#6.1) — tap any ExpertCard
  - Service Detail (#6.2) — tap any ServiceCard (also reachable transitively from #6.1)
  - Bottom-nav targets: Home (#5), Train (#7), Social (#11), History (#12)

## Data touched

See [../../database-v1.md](../../database-v1.md).

- **Reads:** all `User` rows with `role = 'expert'` joined to `ExpertProfile` (via shared-key `UserID`); all `ExpertService` rows (for the Service Listings sub-tab + the `N services · from $X` footer on ExpertCard); `User.followedExpertIds` for the current user (drives the heart-toggle state on each card).
- **Writes:** `toggleFollowExpert(currentUserId, expertUserId)` — heart tap on any ExpertCard. Request still happens on #6.2.

## Notes / non-obvious

- **Sort is non-interactive in v1.** The "Sort: Top rated" caption is real (we sort by `ratingAvg` desc for experts, `priceCents` asc for services), but no user-facing toggle. Future work: add a sort dropdown with Top rated / Most reviews / Lowest price options.
- **Category filter chips come from the `ExpertCategory` store.** The strip renders `All` + every **active** category (`activeCategories(expertCategories)`); the admin curates the catalog on #29 (add / rename / suspend). Suspended categories drop off this filter but existing listings still show their label.
- **No "Following" view in v1.** The follow toggle lives on #6 + #6.1 but there's no dedicated surface to list who you follow. Add a `Following` sub-tab here (or a section on #13 Profile) when there's enough follow-list activity to justify it.
- **Premium (future):** filter to verified-only experts, see reviews body text (Free just sees the count), book free 15-min intro calls. Same upsell-at-friction pattern as the rest of the app.
