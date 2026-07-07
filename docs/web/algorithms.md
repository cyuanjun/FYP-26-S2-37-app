# Landing-page selection algorithms

*Added 12 Jul 2026. Nothing on the public landing page is hand-picked — the two
curated-looking sections are ranked by explicit algorithms, computed against the
shared database and **logged to the browser console** on every page load
(`[landing] …` lines) so the ranking is auditable at runtime.*

## Featured experts — Bayesian weighted rating (IMDb formula)

Computed **in the database** (`landing_featured_experts()`,
`app/supabase/migrations/20260712110000_landing_activity_and_ranking.sql`) so the
site and any future consumer share one source of truth:

```
WR = (v / (v + m)) · R  +  (m / (v + m)) · C
```

| Term | Meaning |
|---|---|
| `R` | the expert's stored `rating_avg` |
| `v` | the expert's `review_count` |
| `m` | **10** — the confidence prior: how many reviews an expert needs before their own average outweighs the global mean |
| `C` | mean `rating_avg` across all *verified* experts |

Rank by `WR` descending; ties broken by `review_count`, then `client_count`.
Only verified, non-suspended experts are eligible; the top 3 are shown.

**Why this one:** a plain "sort by rating" lets a 5.0★ expert with 2 reviews
outrank a 4.8★ expert with 100. The Bayesian estimate (the IMDb Top-250
formula) shrinks low-volume averages toward the global mean, so volume and
quality both matter. Worked example from the live data: Amelia (4.9★ × 86)
scores 4.890 and beats Marcus (4.8★ × 112, WR 4.800); Marcus beats Sam
(4.8★ × 23, same WR 4.800) on the review-count tiebreak.

## Testimonials — rating + recency decay

Computed client-side over the approved rows
(`web/src/boundary/gateways/testimonialGateway.ts`):

```
score = rating + e^(−age_days / 45)
```

Rating dominates (the recency bonus is at most 1.0, less than one rating
step), so a 5★ testimonial always outranks a 4★ one; **among equal ratings,
fresher testimonials float up** — the bonus roughly halves every month, so the
wall doesn't fossilise. Only admin-approved testimonials are eligible (RLS
enforces this before the algorithm ever sees a row).

## Platform activity chart — raw aggregates, no selection

The statistics chart is not curated at all: `landing_activity_series()` returns
the last 12 weeks of completed-session counts and active minutes straight from
`workout_sessions` (zero-filled weeks included), rendered as an inline SVG.
