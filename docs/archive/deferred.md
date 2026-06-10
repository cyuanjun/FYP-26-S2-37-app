# Deferred — UI & Schema gaps vs FYP requirements

Captured 2026-06-01 after an end-to-end audit against the FYP project description's 5 stated features. **UI + schema only** — backend implementation gaps (BLE pairing, push delivery, scheduler engine) are out of scope for this mock and noted only where they affect what the UI/schema should look like.

The mock is a web preview that must translate 1:1 to Flutter — anything we want the Flutter team to ship has to either be drawn here or be in `state/types.ts`.

## Quick status

| # | Requirement | UI gap | Schema gap |
|---|---|---|---|
| 1 | Collect exercise data | — | — |
| 2 | Analyse exercise effects | Optional only | — |
| 3 | Advice + plan from goal | **No standalone advice surface** | Optional only |
| 4 | Exercise / break reminders | **No notification inbox screen** | **No `Notification` entity** |
| 5 | Social share + competitions | **No invite picker; no invitations strip** | **No `ChallengeInvitation` entity** |

Three must-add items in total: a Notifications Inbox, an Invite Picker, and the two new entities that back them.

---

## 1. Collect exercise data (cellphone sensors or wearables via Wi-Fi / Bluetooth)

**Status: covered.**

| Layer | What exists |
|---|---|
| Schema | [`ConnectedDevice`](../app/src/state/types.ts) with `deviceType` (apple_watch / fitbit / garmin / polar / oura / phone_sensors / other), `bluetoothAddress`, `lastSyncedAt`, `isActive`. `WorkoutSession.trackPoints` (GPX-style HR / cadence / elev / pace) + `trackSource` + `dataSource: wearable \| phone_sensors \| manual`. |
| UI | [#7.1 Connected Devices](../reference/screens/free/07.1-connected-devices.md) with pair / unpair / set-primary; [#9 Active Workout](../reference/screens/free/09-active-workout.md) auto-picks the active non-phone-sensors device on session start; [#12.1 History Detail](../reference/screens/free/12.1-history-detail.md) renders LineChart from `trackPoints`. |

**No UI or schema gap.** What's missing is implementation only (real BLE pairing in Flutter; live `trackPoints` append in `endWorkoutSession`; `lastSyncedAt` writeback) — none of those need new screens or columns.

---

## 2. Estimate exercise effects (short-term + long-term) and provide analysis

**Status: covered.**

| Layer | What exists |
|---|---|
| Per-session | [`lib/effectEstimate.ts`](../app/src/lib/effectEstimate.ts) — Karvonen HR-reserve × duration multiplier → Training Effect 1–10 score, band, advice line. Aerobic / anaerobic split + recovery hours for Premium drill-down. Surfaced via `TrainingEffectCard` on #10 Workout Summary + #12.1 History Detail. |
| Day / Week / Month / All | [`lib/periodAnalysis.ts`](../app/src/lib/periodAnalysis.ts) + `PeriodAnalysisCard` on #12 History. Free gets 3 pills (Day / Week / Month); Premium gets `All` too. Tiles: sessions, active min, calories, avg HR, max HR. Prior-period deltas per tile. |
| Long-term | [`lib/advancedAnalytics.ts`](../app/src/lib/advancedAnalytics.ts) + [#12.2 Advanced Effect Estimates](../reference/screens/premium/12.2-advanced-analytics.md) (Premium-only). Weekly bars over 8w / 6mo / 1yr / all for volume, HR efficiency, training load. 4-tile personal bests. |

**No UI or schema gap.** All four pacing windows in the brief (per activity / day / week / month / any period) are covered. Calories burned, avg HR, max HR are the headline tiles.

**Nice-to-have (skip unless someone asks):**
- Per-workout-type pivot on #12.2 (running vs strength vs yoga donut). `advancedAnalytics.ts` already groups weekly; add a `byWorkoutType()` aggregator.
- Custom date-range picker on #12.2 ("any period" currently means "preset windows").

---

## 3. Supply fitness advice and schedule a fitness plan

**Status: plan covered, advice gap.**

| Layer | What exists |
|---|---|
| Goal capture | [#13.2 Fitness Goals](../reference/screens/free/13.2-fitness-goals.md) with `primaryGoal`, `targetValue` + `targetUnit`, `timelineWeeks` (4–24), `weeklyCommitmentDays` (1–7). All four customization knobs the brief names. |
| Health info | [#13.1 Fitness Profile](../reference/screens/free/13.1-fitness-profile.md) with DOB / sex / height / weight / activity level / training experience, plus `healthTagIds[]` (diet / allergy / injury) and `preferredWorkoutTypeIds[]`. |
| Plan generation | [`FitnessPlan`](../app/src/state/types.ts) + `PlannedWorkout` schema, `regenerateFitnessPlan` action, [#8 Plan Detail](../reference/screens/free/08-plan-detail.md) with Regenerate CTA (Free: 1/month cap, Premium: unlimited). [#7 Train](../reference/screens/free/07-train.md) surfaces today's planned workout. |

### UI gap — no standalone "advice" surface

The brief asks for *advice* in addition to a *plan*. Right now the only advice anywhere is the one-line Training Effect band message per session ("Light session. Great as a warmup…").

**Options:**

- **Cheap (recommended):** add an **Advice tile** to #5 Dashboard, keyed off `primaryGoal` × recent training-load + plan adherence. Must obey the [Honest AI rule](../CLAUDE.md) — copy must be derived from concrete fields, not motivational template-fill. Example phrasing: *"Last week: 3/4 planned sessions completed. Saturday is your next strength slot."* No new entity needed.
- **Rich:** new sub-screen **#5.1 Insights** aggregating plan adherence + load trend + goal delta. Same Honest AI constraint.

### Schema gap — minor

No blocking entity gap. Plan generation logic ignores `primaryGoal` shape and `healthTagIds[]` (template hardcodes Mon-strength / Tue-cardio regardless of goal) — but that's a code change in `db.ts` `buildPlannedWorkouts`, not a schema change.

If we want stored advice copy rather than derived: add an `AdviceTemplate` entity (`templateId / primaryGoal / triggerCondition / body`). Probably overkill for the mock.

---

## 4. Remind user to exercise or take a break

**Status: settings covered, inbox + queue gap.**

| Layer | What exists |
|---|---|
| Schema | [`NotificationTypeKey`](../app/src/state/types.ts) enum: `workout_reminder \| missed_workout \| inactivity_reminder \| rest_alert` covers both halves of the brief. `NOTIFICATION_TYPES` metadata with category / audience / name / description. `User.notificationPrefs` map. |
| UI | [#13.4 Notifications](../reference/screens/free/13.4-notifications.md) — full toggle UI. Free sees `rest_alert` as locked-Premium; Premium gets an "Adaptive" badge on workout-reminder types. |

### UI gap — no notification inbox

A user has nowhere to view fired reminders. This is a critical gap — "send reminders" implies the user actually *sees* them somewhere in the app, not just OS-level push.

**Recommended screen:** **#5.1 Notifications Inbox** (or **#13.7** if we'd rather scope it under Profile).
- Reached from a **bell icon + unread-count badge** added to #5 Dashboard header
- List grouped by date (Today / Yesterday / Earlier)
- Each card: icon (derived from `typeKey`) + title + body + relative time + tap-through deep link
- Mark-as-read on tap
- Empty state: "No notifications yet"

### Schema gaps

**Add `Notification` entity** (currently 26 → 27 entities):

```ts
{
  notificationId   : string  // PK
  userId           : string  // FK → User
  typeKey          : NotificationTypeKey
  title            : string
  body             : string
  scheduledFor     : DateTime
  sentAt           : DateTime | null      // null = scheduled, set = fired
  readAt           : DateTime | null      // null = unread
  deepLinkPath     : string | null        // e.g. '/free/07-train'
  createdAt        : DateTime
}
```

**Add `User.workoutReminderHour: number | null`** (0–23) — backs the "Nudge me at my preferred time" description on #13.4 which currently has no field behind it.

**Re-evaluate Premium gating on `rest_alert`** — the brief explicitly names "break reminders" as a feature; gating it behind paywall is questionable. Gating the *adaptive* logic (smart fire times) is fine; gating the existence of a rest reminder is not.

**Note for write-up:** real scheduling/delivery is Flutter implementation (OS push, background tasks). The mock just needs the entity, the inbox, and a deterministic `lib/notificationEngine.ts` that scans `plannedWorkouts` vs `workoutSessions` on app load + after `endWorkoutSession` to populate rows. That makes the requirement demonstrable end-to-end.

---

## 5. Connect with social media and initiate competitions

**Status: external sharing + competition flow covered, invite half gap.**

| Layer | What exists |
|---|---|
| External sharing | [`SharePostModal`](../app/src/components/SharePostModal.tsx) with exactly the four FYP-named platforms (Facebook / Instagram / Twitter) + TikTok + Copy. [`lib/sharePost.ts`](../app/src/lib/sharePost.ts) opens real Twitter intent + Facebook sharer; Instagram + TikTok fall back to clipboard with a paste hint (web has no share API for them). |
| Competitions schema | Unified [`Challenge`](../app/src/state/types.ts) entity polymorphic by `visibility: public \| invite_only` × `metricKind: accumulator \| best_of`. `ChallengeParticipant` junction. Seven metrics (total_distance / total_sessions / total_calories / active_days / fastest_time / longest_distance / most_calories). |
| Competitions UI | [#11 Social](../reference/screens/free/11-social.md) Challenges tab with Joined / Active / Past sub-tabs + search + Create button. [#11.3 Challenge Detail](../reference/screens/free/11.3-challenge-detail.md) with leaderboard + progress + Join/Leave. [`CreateChallengeModal`](../app/src/components/CreateChallengeModal.tsx) for any combo. |
| Result sharing | `best_of` challenges auto-emit a `challenge_result` Post on deadline. The Post is shareable to FB/IG/TW/TikTok via the same SharePostModal. |

### UI gap — invite picker + invitations strip

The brief says "**invite them** to join in". Currently invite-only challenges have no picker — [CreateChallengeModal.tsx:104](../app/src/components/CreateChallengeModal.tsx#L104) admits this is **Phase 1B**.

**Two new UI pieces:**

1. **Invite Picker** — a step inside `CreateChallengeModal` that appears when `visibility === 'invite_only'`. Friend multi-select using the existing friend list (reuse logic from `Social.tsx` lines ~461–472). On submit, write `ChallengeInvitation` rows.
2. **Invitations Strip** on Social → Challenges tab — top horizontal row of pending invites: *"Alex invited you to Weekend 5K · Accept · Decline"*. Two inline CTAs flip the invite status.

### Schema gap — `ChallengeInvitation` entity

Currently invited users would be force-joined. To support accept/decline, add (27 → 28 entities with the Notification add):

```ts
{
  challengeId      : string  // PK + FK → Challenge
  inviteeUserId    : string  // PK + FK → User
  inviterUserId    : string  // FK → User
  status           : 'pending' | 'accepted' | 'declined'
  invitedAt        : DateTime
  respondedAt      : DateTime | null
}
```

`status === 'accepted'` would trigger a `ChallengeParticipant` row insert.

### Nice-to-have UI (broader sharing scope)

The brief says "share **exercise data**" — currently sharing is post-centric, not data-centric.

- **Share icon on #12.1 History Detail** — share a raw `WorkoutSession` summary without first posting it
- **Share button on Basic Workout Analytics card / #12.2** — share weekly / monthly stat summaries

Both reuse `sharePost.shareToPlatform` with a synthesised summary URL.

### Caveats for the write-up (no fix needed)

- The deliberate four-platform list (vs `navigator.share`) is per the brief — keep as-is, the comment in [sharePost.ts:5](../app/src/lib/sharePost.ts#L5) justifies it.
- Share URLs are `localhost` in dev — real Flutter app needs a real domain + deep linking. Shape of the URL is correct; host is a mock concession.

---

## Priority summary

### Must-fix (gaps the brief explicitly names)

| Item | Type | Effort |
|---|---|---|
| Invite Picker UI + `ChallengeInvitation` entity | UI + schema | Medium — picker is a modal step, entity is small |
| Notifications Inbox screen + `Notification` entity | UI + schema | Medium — new screen, entity + bell badge on Dashboard |
| Advice surface (or written justification for scoping out) | UI | Small — could be just a tile on Dashboard |

### Nice-to-have (polish, not brief-blocking)

- Per-workout-type breakdown on #12.2 Advanced Analytics
- Custom date-range picker on #12.2
- Share button on #12.1 History Detail
- Share button on Basic Workout Analytics card + #12.2
- `User.workoutReminderHour` field (backs the "preferred time" copy on #13.4)
- Make plan generator respect `primaryGoal` shape and `healthTagIds[]` (code change, not UI/schema)

### Implementation-only gaps (acknowledge in FYP report, do not build)

- Real BLE pairing (Flutter concern)
- Real push delivery + background scheduler (Flutter / backend concern)
- Live `trackPoints` append in `endWorkoutSession` (small code change, but mock-level)
- `lastSyncedAt` writeback on workout end (small code change)
- Production domain for share URLs

---

## Final entity count if all must-fix added

26 (current) → **28** with `Notification` + `ChallengeInvitation`. Persist version would bump from v63 → **v64** (or v65 if both land in separate cycles).
