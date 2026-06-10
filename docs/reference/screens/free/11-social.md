---
screen: 11-social
role: free
group: main
status: spec-only
---

# 11. Social (tab)

**Purpose:** A feed-style tab where users share workouts, see challenge rankings, react, and connect with friends. **Posts are polymorphic** — every feed entry is a `Post` row whose `kind` decides what it wraps:

- `workout_share` — a `WorkoutSession` (with an optional caption)
- `challenge_result` — a `Challenge` of `metricKind = 'best_of'` (with computed rankings); auto-created when the challenge's deadline passes
- `level_up` — a level reached (carries `Post.level: int`); auto-emitted by `endWorkoutSession` when the XP delta crosses one or more level thresholds (math in `lib/levelXp.ts`)

More kinds can be added later (PR celebration, milestone) without changing the likes / comments / share-graph plumbing. The earlier `badge_earned` kind was dropped in schema-v2 alongside the `Badge` / `UserBadge` entities in favour of XP-based leveling. Earlier iterations went "workout-is-the-post" (no `Post` entity) for a while; that worked for a workout-only world but folded once challenges arrived. The current model trades that simplicity for extensibility.

Reached via the Social tab in the bottom nav.

## Layout

Has **bottom nav** (Social tab active). Four bands:

1. **Header** (`shrink-0`, top) — `SOCIAL` title (TabHeader `title` variant, no avatar)
2. **Tab switcher** (`shrink-0`) — segmented control with two pills: **Community** (default) and **Challenges**. The active tab is filled `accent`; the inactive is muted text. Governs the whole screen state — only the active tab's content renders below.
3. **Tab content** (`flex-1`, scrolls) — see Community vs Challenges below
4. **Bottom nav** (`shrink-0`, bottom) — shared across both tabs

### Community tab (default)
Original Social contents:
- **Search + friends strip** (`shrink-0`) — `Find friends` text input on the left + friend-count badge on the right
- **Main feed** (`flex-1`, scrolls) — vertical stack of post cards (workout-share + challenge-result), newest first. When the search input has content, the dropdown of matched users replaces the feed area until the user clears the query.

### Challenges tab

Every group-activity item on this tab is a **`Challenge`** — a single unified entity with two orthogonal axes:

| Axis | Values | Drives |
|---|---|---|
| `visibility` | `public` \| `invite_only` | Whether the challenge appears on the Active sub-tab for browsing (public) or is reachable only via friend-invite (invite_only) |
| `metricKind` | `accumulator` \| `best_of` | Whether progress fills toward a target (progress bar) or each participant's best single session is ranked head-to-head (no target) |

Earlier iterations had this split as two entities (`Challenge` for public/accumulator and `Competition` for invite_only/best_of). After the card chrome, leaderboard preview, sub-tab placement, and ranking logic all unified, the split stopped earning its keep. Collapsing into one entity also unlocks combos the old split couldn't model: *public race* ("anyone, fastest 5K this month") and *private goal* ("just my running club, hit 500 km collectively").

#### Search bar + create button
A `Find challenges` pill input sits at the top of the Challenges tab, directly mirroring the **Find friends** search on the Community tab (same rounded `surface` pill, magnifying-glass prefix, ✕ clear button when populated). To its right, a **40 px circular `+` button** (accent CTA) opens the **Create Challenge modal**. Free-form case-insensitive `includes` match on the search filters by `name + description` over every Challenge the current user is in (or every visible Active challenge, depending on sub-tab). **Persists across sub-tab switches**, so a query like *"may"* narrows the visible items in whichever sub-tab is active.

#### Create Challenge modal
Triggered by the + button. Standard `Modal` with a vertical form:
- **Visibility** — `Public` / `Invite only` segmented toggle. Public is browseable on the Active sub-tab; invite-only ones are reachable only by friend-invite (friend-invite picker is Phase 1B; creator is the only participant for now).
- **Metric kind** — `Goal (accumulator)` / `Race (best of)` segmented toggle. Switching the kind resets the metric dropdown so only valid metrics for the chosen kind are offered.
- **Icon** — chip-row picker from a fixed set of emoji glyphs (⚡ 🏃 🚴 🏊 🏋️ 🧘 🥊 🧗 🎯 🏆). Defaults to ⚡.
- **Name** — display name (e.g. `Run 100km in May`).
- **Short name** — compact pill text (max 20 chars, auto-uppercased on submit; e.g. `MAY 100K`).
- **Description** (optional) — tagline / reward hint.
- **Metric** — select that adapts to `metricKind`:
  - accumulator: `Total distance` / `Total sessions` / `Total calories` / `Active days`
  - best_of: `Fastest time` / `Longest distance` / `Most calories` / `Most sessions`
  Helper text under the select reminds the user of the metric's semantics + expected unit.
- **Target value** — numeric input; **shown only for accumulator** (best_of has no target to fill toward).
- **Workout type** (optional) — select from the `WorkoutType` catalog, or "Any workout" (default).
- **Date range** — Starts / Ends date inputs (HTML date pickers).

Submit is disabled until name + shortName + a valid `start ≤ end` date range are present, AND (when accumulator) a valid positive `targetValue`. On Create, calls `createChallenge({ ... })` which inserts the `Challenge` row, auto-joins the creator as a `ChallengeParticipant` with `workoutSessionId: null`, and closes the modal. The new challenge is `isFeatured: false` (curator-only flag) and stamps `createdByUserId` so we can later distinguish curator-seeded from user-created.

When the search returns no matches the empty state copy adapts: instead of the default *"You haven't joined any active challenges…"* / *"No active challenges right now."* / *"No past challenges yet."* lines, the card shows *"No challenges match \"<query>\"."* — so users understand the empty list is a search miss, not an absence of data.

#### Sub-tab nav
A second row of 3 outlined pills sits just below the search bar: **Joined** (default) · **Active** · **Past**. The active pill fills `accent`. The progression is *present commitments → present opportunities → past activity* — the three tabs are mutually exclusive (no item appears in more than one).

#### Joined sub-tab (default)
Your **current commitments** — every Challenge you've joined that's still in-progress. Each renders as a `FeaturedChallengeCard`:
- Top row: `{icon} {shortName}` in accent caps + `Day X / Y` window counter (muted) + right-aligned participant count
- Title in 20 px display font-black uppercase
- Optional tagline (`description`)
- **Progress bar — accumulator only.** For `metricKind = 'accumulator'`, an accent fill against `bg-faint/40` + a current / target row + percentage in accent. Skipped entirely for `best_of` challenges (no target — the leaderboard below carries the standings signal).
- **Leaderboard preview** — top-3-then-you treatment (medals 🥇 🥈 🥉, accent-tinted row for you, faint `…` separator when you're outside top 3). Ranks every participant by current value descending; excludes zero-value entries. Hidden when nobody has any progress yet.

Empty state: *"You haven't joined any active challenges. Browse the Active tab to find one."*

#### Active sub-tab
**Browse what's joinable right now.** Renders the same `FeaturedChallengeCard` for every in-progress **public** Challenge (joined or not). Invite-only challenges don't appear here — they're reachable only by invite. Internal differences:
- **Joined cards** show the progress bar (accumulator only) with the user's real progress + percentage in accent.
- **Unjoined cards** show the same progress bar at `0 / target` and 0% in muted text (accumulator only) — every accumulator card has the same visual shape, the muted % reads as "you haven't started this yet" without burying the target value.

Tap anywhere on the card → **#11.3 Challenge Detail**, where the pinned-footer **Join Challenge** button is the way to opt in. There is **no inline Join button** on the card.

Empty state: *"No active challenges right now."*

#### Past sub-tab
**History.** Ended Challenges you joined, newest first (sorted by `endedAt DESC`). Renders the same `FeaturedChallengeCard` — accumulator cards show the user's final state (usually <100% unless they hit target); best_of cards show the final leaderboard. Ended `best_of` challenges have a `challenge_result` Post in the Community feed (auto-created on deadline), accessible via #11.1.

Empty state: *"No past challenges yet."*

#### Progress / ranking computation
Live-computed from the user's (and other participants') `WorkoutSession` rows on every render — no stored `currentValue` column. Filter for "qualifying": session within `[startedAt, endedAt]`, `EndedAt IS NOT NULL`, and (if `challenge.workoutTypeId` is set) matching workout type. Then:

| metricKind | metric | aggregation | display unit |
|---|---|---|---|
| accumulator | `total_distance` | sum of `distanceMeters` (÷ 1000 for label) | `km` |
| accumulator | `total_sessions` | count of qualifying sessions | `sessions` |
| accumulator | `total_calories` | sum of `caloriesBurned` | `kcal` |
| accumulator | `active_days` | count of distinct `endedAt.slice(0, 10)` | `days` |
| best_of | `fastest_time` | min `durationSeconds` across qualifying (or the explicit `workoutSessionId`'s value when set) | `mm:ss` |
| best_of | `longest_distance` | max `distanceMeters` (or explicit submission) | `km` |
| best_of | `most_calories` | max `caloriesBurned` (or explicit submission) | `kcal` |
| best_of | `total_sessions` | count of qualifying sessions in window ("most sessions" race) | (count) |

For accumulator, percentage is `Math.min(100, round(current / target * 100))`. For best_of, ranking is ascending for `fastest_time` (lower wins), descending for the others. There's no separate `most_sessions` metric — `total_sessions` with `metricKind = best_of` ranks by window count instead of filling toward a target.

`ChallengeParticipant.workoutSessionId` is null forever for accumulator challenges. For best_of: while the challenge is active and the participant hasn't explicitly submitted, the leaderboard auto-picks their best in-window qualifying session; on deadline that selection would be locked in by a backend scheduler. Participants with no submission and no qualifying sessions are treated as DNS and excluded from the preview.

**No compose FAB.** Earlier drafts had a `+` button → #11.2 Compose Post, but the model shifted: workouts are the posts. The only way to make something appear in the feed is to complete a workout and toggle "Share to Social" on **#10 Workout Summary** (or retroactively on **#12.1 History Detail** edit mode). The old #11.2 Compose was removed; the slot now holds **#11.2 User Profile** (the other-user profile page that name-taps route into).

## Search + friends strip

A single horizontal row above the feed, two controls:

### Find friends search
- Rounded pill input with a magnifying-glass icon prefix + ✕ clear button when there's content
- Case-insensitive `includes` match against `firstName + lastName + @handle` on the user directory; current user is always excluded
- Results render in a `surface` dropdown directly below the strip, with a `UserRow` for each match
- Empty query → no dropdown (feed shows through); non-empty with zero matches → centred "No users match …" cell

### Friends badge
- Compact pill on the right showing 👥 + the count of current user's friends
- Tap opens the **Friends modal** — a `Modal` with all friends in a vertical list (`UserRow`s), each with an inline `Unfriend` button
- Modal title reads `N Friend(s)` based on count

### `UserRow` (shared between search dropdown and friends modal)
- Avatar (initial fallback on `accent` bg) + name + `@handle`
- Right edge: a single **Add Friend / Unfriend** pill toggle (label flips with state). `Add Friend` = filled accent (CTA-style), `Unfriend` = outlined surface chip with `danger` hover (less salient at rest, hover warns about the destructive action). **Labels are action-first, not state-first** — they describe what tapping does, not what's currently true, so the noun never reads as a stranded fact.

## Mutual friendship

Friends are **bidirectional**, not directional. When the current user taps `Add Friend` on someone, both `Follow` rows (A→B and B→A) are inserted atomically by `followUser`; `unfollowUser` deletes both. The store enforces this in code — there's no separate "request / accept" flow in v1, just instant mutual.

Effects of this model:
- "Followers" and "Following" collapse into one concept — **Friends**
- Counts shown anywhere ("3 friends") are the cardinality of one direction (they're identical to the other)
- The feed-scoping query (`current.userId IN followerId → followingId`) still works without rewriting — it just naturally returns the same set as the reverse direction

**Why "Friends" and not "Connections" / "Followers".** "Connections" reads LinkedIn-stiff for a fitness app; "Followers" implies one-way (Twitter/Instagram) which doesn't match the mutual model. "Friends" is the most natural fit and matches how mutual relationships are framed in casual social apps (Facebook, Snapchat).

## Feed scoping

The feed shows **all Posts** authored by the user's **friends + themselves**, regardless of kind:

```sql
SELECT * FROM Post
WHERE UserID IN (current.userId, ...friendIds)
ORDER BY CreatedAt DESC
```

If the user has no friends and hasn't posted anything of their own, the feed is empty.

## Post cards (two kinds today)

Every feed entry uses a shared **AuthorRow** (avatar + name + `@handle · relative time`) and shared **PostActionRow** (heart + comment count). The body of the card varies by `Post.kind`.

### Workout share card (`kind = 'workout_share'`)

- AuthorRow
- Optional **description paragraph** (`Post.body`) — distinct from the session's private `notes`
- Embedded **`WorkoutListCard`** (same component used on #12 History list rows) showing the linked WorkoutSession's icon, name, date/duration, and the type-aware 3-metric strip
- PostActionRow → tap comment → opens **#12.1 History Detail** scrolled to `#comments`

### Challenge result card (`kind = 'challenge_result'`)

- AuthorRow (author = the `best_of` challenge's creator)
- **Accent-tinted result panel** (visually distinct from workout shares — accent ring + accent bg-tint, 🏆 glyph) containing:
  - `CHALLENGE RESULT` eyebrow + challenge name in display 18 px + metric subtitle (e.g. *Fastest time*)
  - Optional challenge description
  - **Ranked list** of participants — each row: rank badge (🥇 🥈 🥉 for top 3, `N.` for others, `—` for unsubmitted) + name + metric value (e.g. `33:00`, `6.80 km`, `285 kcal`). Unsubmitted participants are dimmed and labelled `No submission`.
- Optional caption paragraph (`Post.body`) below the result panel
- PostActionRow — same Like / Comment / Share affordances as workout-share posts; comment routes to #11.1 Post Detail with the full ranking + comment thread

### Why the visual split

Workout shares and challenge results are both Posts but they answer different questions ("what did one person do" vs "who won this group event"). Same shape, different content density. The accent-tinted panel on challenge-result cards is intentional — it signals "this is about the group, not one person's training".

### Card tap target

**The entire post card is the tap target** for opening **#11.1 Post Detail** — both workout-share and challenge-result cards. Earlier iterations split this (workout card tap → #12.1, comment chip tap → #11.1), which forced the user to aim for a 12 × 12 px icon to get to the conversation. Now anywhere on the card opens Post Detail; only the heart button intercepts the tap (with `stopPropagation` + `preventDefault`).

This also explains why the embedded `WorkoutListCard` inside a workout-share post is rendered with `href={null}` — its outer `<Link>` would nest anchors otherwise. To jump to #12.1 (the workout's data view), open Post Detail first, then tap the workout card there.

## Action row
- **❤ Like** — toggle (`danger` red when liked, `muted` otherwise). Shows count when > 0, label "Like" when 0. Intercepts the parent card's link so liking doesn't navigate.
- **💬 Comment count** — display-only chip showing the count (or "Comment" when zero). The card itself owns the navigation.
- **↑ Share** — opens the **Share post modal** (a Modal with a curated list of social platforms; see below). Intercepts the parent card's Link the same way as Like, so opening the modal doesn't also navigate. No `Share` entity / count is stored in v1 — sharing is a fire-and-forget action.

The Like + Comment counts are factual displays of the underlying `PostLike` / `PostComment` rows — no clever copy. Share has no stored counterpart.

### Share post modal
Triggered by the Share button on either #11 (any post card) or #11.1 (Post Detail). Vertical list of platform buttons inside a standard `Modal`:

| Platform | Behaviour | Why |
|---|---|---|
| **X (Twitter)** | Opens `twitter.com/intent/tweet?text=…&url=<post URL>` in a new tab; pre-fills text + URL. | Twitter's web intent works on any browser; pre-filled composer is the standard pattern. |
| **Facebook** | Opens `facebook.com/sharer/sharer.php?u=<post URL>` in a new tab; FB pulls the OG-tag preview. | FB sharer dialog is the only first-party web entry point. |
| **Instagram** | Copies the post URL + flashes `Link copied — open Instagram to paste`. | Instagram has no public web share API; their share SDK is mobile-only. Copy-and-paste is the realistic v1 fallback. |
| **TikTok** | Copies the post URL + flashes `Link copied — open TikTok to paste`. | Same constraint as Instagram. |
| **Copy link** | Plain clipboard copy; flashes `Link copied to clipboard` and auto-dismisses the modal after 1.5 s. | Explicit copy-link entry-point for users who want it generically. |

Each button has a circular surface icon (`bg-bg`) + label; Instagram + TikTok rows include a Caption-2 muted hint underneath the label explaining that they copy rather than share directly (sets expectations). Modal contents `stopPropagation` so clicks inside don't bubble to any outer Link wrapper.

**Project context:** the FYP project description names Facebook / Instagram / Twitter / TikTok as the target social platforms — this modal is the literal implementation of that requirement. Future work could include real OG-tag generation server-side (so Facebook previews look nicer), platform-specific text templates (e.g., a tweet has different optimal length than a Facebook caption), and a Web Share API path for mobile (which would also show *all* installed apps, not just the four named ones).

## Empty state

When the user follows nobody and has zero shared sessions, render a centred muted prompt: *"Your feed is empty. Share a workout from #10 Summary or follow more friends."*

## How posts enter the feed

### Workout share posts
Created when a user toggles **Share to Social** on either #10 Workout Summary (right after finishing) or #12.1 History Detail (edit mode, retroactively). Toggling on creates a `Post` row of kind `workout_share` pointing at the session; toggling off deletes the Post (likes/comments on it are cleaned up as a cascade). Default is OFF — opt-in only.

The optional Description textarea writes `Post.body` directly.

### Challenge result posts
Created automatically when a `metricKind = 'best_of'` Challenge's deadline passes — a `challenge_result` Post is generated wrapping the Challenge, and rankings are computed on the fly from the participants' best (or explicitly-submitted) WorkoutSessions. In production this is a scheduled job; in the mock the seed pre-creates one completed best_of Challenge (`chal_006` Weekend 5K) + its result Post (`pst_chal_result_006`). `accumulator` Challenges don't generate a result Post — they just stay on the Past sub-tab of #11's Challenges section.

The CreateChallengeModal lets users create either kind (any combo of visibility × metricKind). The friend-invite picker for `invite_only` Challenges is still Phase 1B — for now invite-only challenges have only the creator as a participant until friend-invite UI ships.

## Edges

- **From:** Bottom nav Social tab (from any other tab); deep-link `/free/11-social` always lands on the **Community** tab by default
- **To:**
  - Post Detail (#11.1) — tap anywhere on any post card on the Community feed (workout-share or challenge-result). #12.1 is reached transitively from Post Detail's embedded workout-card tap.
  - User Profile (#11.2) — tap any user's avatar / name on a post AuthorRow, challenge ranking row, search result, or Friends modal entry
  - Challenge Detail (#11.3) — tap anywhere on a Challenge card on any sub-tab (Joined / Active / Past)
  - Bottom-nav targets: Home (#5), Experts (#6), Train (#7), History (#12)

## Data touched

See [../../database-v1.md](../../database-v1.md).

- **Reads (Community tab):** `Post` rows (filtered by follow graph + current user, ordered by `CreatedAt DESC`), `User` for the author lookup, `Follow` for the feed scoping, `WorkoutSession` + `WorkoutType` + `ExerciseLog` for workout-share posts, `Challenge` + `ChallengeParticipant` (+ each participant's WorkoutSession for best_of ranking) for challenge-result posts, `PostLike` count + whether current user liked, `PostComment` count.
- **Reads (Challenges tab):** all `Challenge` rows (filtered by sub-tab — Joined: user's joined in-progress; Active: every public in-progress; Past: user's joined ended); `ChallengeParticipant` rows for participant counts + the user's joined set + best_of submissions; every participant's `WorkoutSession` rows in each challenge's window (live progress + ranking); `WorkoutType` for the creation modal's type select.
- **Writes:**
  - `togglePostLike(postId, currentUserId)` — heart tap on any post card
  - `followUser` / `unfollowUser` — Add Friend / Unfriend toggles in search results, Friends modal, and on #11.2 User Profile
  - `joinChallenge` / `leaveChallenge` — Join / Leave Challenge button on #11.3 Challenge Detail
  - `createChallenge` — Create button in the CreateChallengeModal (any visibility × any metricKind)

## Notes / non-obvious

- **Posts are polymorphic.** A single `Post` entity wraps either a `WorkoutSession` (kind = `workout_share`) or a `Challenge` (kind = `challenge_result`). One feed query, one likes table, one comments table. Adding new post kinds in the future (PR celebration, milestone, etc.) means just adding a new branch in the Social feed's renderer — no schema rewrite.
- **Privacy is opt-in for workout shares.** No `Post` exists for a session until the user toggles "Share to Social" on #10 or #12.1. Toggling creates the Post; toggling off deletes it (cascading likes/comments).
- **Notes vs Post.body.** `WorkoutSession.notes` is always private (owner-only, never shown on Social). The public caption for a shared workout lives on `Post.body` of the wrapping `workout_share` Post. Two distinct fields by design — see [#10 Workout Summary spec](10-workout-summary.md) for the UI split.
- **Comments live on #11.1 Post Detail.** Every post kind (workout share + challenge result) routes the comment button to the same polymorphic Post Detail page. Earlier iterations split this — comments lived inline on #12.1 History Detail for workout shares while best_of-challenge posts had no thread surface. That split was unsatisfying once posts went polymorphic; #11.1 unifies it.
- **Follow is real from day one.** No "see everyone" mode. The seed includes Mia following Alex/Jordan/Sam so the feed isn't empty out of the box. Unfollow / new-follow is now wired up in three places: the Friends modal, the search-results UserRow, and **#11.2 User Profile**.
- **No photo uploads in v1.** Defer until storage is real (S3-style URLs).
- **No notifications surface for social activity yet.** When someone likes / comments / follows the current user, nothing pings — defer until #13.4 Notifications has a Social-specific category wired.
- **Workout link always navigates to the author's session detail.** Even for non-Mia sessions. HistoryDetail's owner-filter applies only to the #12 History list, not direct-link views, so this works without leaking other-user data into Mia's History list.
- **Premium (future):** *"who liked your workout"* list (Free just sees the count), custom reactions beyond ❤ (💪 🔥 🏆), per-session performance breakdown ("seen by N, liked by M"). Same upsell pattern as the rest of the app.