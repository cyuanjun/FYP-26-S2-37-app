# Wise Workout — Colour Palette

The app's colour system. This mirrors **[`lib/core/theme/app_colors.dart`](../../app/lib/core/theme/app_colors.dart)** (the single source of truth in code) and is the reference for any colour cited in the per-screen files under [screens/](screens/) (indexed by [screens-v1.md](screens-v1.md)). Pair with [typography.md](typography.md) for the type scale.

> **History:** the app originally shipped a dark, lime-accent theme (from the brand-kit extract). It was reworked into the **light, white-base, semantic** system below — bright energetic accents on white, with every colour assigned a *meaning* (see Usage rules). When this doc and `app_colors.dart` ever drift, the code wins.

---

## Neutrals (white base)

| Token | Hex | Role |
|---|---|---|
| `bg` | `#F6F7FB` | Primary background (soft white). Also the on-accent foreground (≈white text/icons on a violet fill). |
| `surface` | `#FFFFFF` | Cards / raised elements — pure white, pops over `bg`. |
| `surface2` | `#EDEFF4` | Higher-elevation / hover. |
| `ink` | `#15161B` | Primary text & headings (near-black, ~16:1 on white). |
| `muted` | `#2B313B` | Secondary / descriptor text (deep slate, ~13:1). |
| `faint` | `#E4E7EC` | Dividers & hairline borders only — **never text**. |

## Brand / interactive

| Token | Hex | Role |
|---|---|---|
| `accent` | `#7B2FF7` | **Clickable** — primary CTA / buttons / links / toggles / selected nav & chips / tappable icons. Electric violet. |
| `accentDim` | `#6A1FE0` | Accent hover / pressed. |

## Semantic state

| Token | Hex | Role |
|---|---|---|
| `success` | `#047857` | Positive / up-trend / completed / active status — **text** green (emerald, readable as text). |
| `successBright` | `#10B981` | Bright green for status-pill **fills** (with `ink` text) — CONNECTED · ACTIVE · device status. Never small text. |
| `danger` | `#E11D48` | Negative / destructive / errors (vivid rose, readable as text). |
| `info` | `#2563EB` | Info / share / recovery (vivid blue). |

## Premium (gold)

| Token | Hex | Role |
|---|---|---|
| `premium` | `#F59E0B` | Premium / achievement **badge & button FILL** (amber) — pair with `ink` text. Too light to use as text. |
| `premiumText` | `#B45309` | Premium **text / links / borders** on white (deep amber, ~5:1). |
| `gold` | `#FFC400` | **Reserved for the #1 leaderboard rank only.** |

## Metric colours

Workout stats are colour-coded so the same metric reads the same hue on every screen. Applied to large stat values + metric icons; all are deep enough (≥4.5:1) to stay readable on white. Resolved by `AppColors.metricColor(label)`.

| Token | Hex | Metric |
|---|---|---|
| `mDistance` | `#2563EB` | distance / km — blue |
| `mPace` | `#0F766E` | pace / speed — teal |
| `mDuration` | `#4F46E5` | time / active minutes — indigo |
| `mHeart` | `#DB2777` | heart rate — pink |
| `mEnergy` | `#C2410C` | calories / energy — orange |

`metricColor()` maps a metric's short label (`'KM'`, `'AVG HR'`, `'CALORIES'`, `'PACE'`, `'ACTIVE MIN'`, …) to its hue, falling back to `ink` for anything unrecognised. `SESSIONS` / `WORKOUTS` / `STEPS` map to `success`.

## Elevation

| Token | Value | Role |
|---|---|---|
| `cardShadow` | `BoxShadow(Color(0x14000000), blur 16, offset (0,4))` | The **one** soft shadow every content card uses (`boxShadow:` on its `BoxDecoration`) so all cards lift off `bg` identically. Not for tiles/badges/pills/inputs. |

## Usage rules

- **Light-mode, white base.** `ink` text on `bg` / `surface`. Cards are `surface` (white) over the slightly-off-white `bg` so they read without heavy borders.
- **Colour = meaning.** `accent`/violet ⇒ *you can tap this*; `muted`/slate ⇒ descriptor; metric hue ⇒ data; `success`/green ⇒ positive/status; `premium`/gold ⇒ premium; `danger`/rose ⇒ destructive. Don't use a colour against its meaning (e.g. no violet on a non-tappable label).
- **Contrast.** Small text uses `ink`/`muted` or a metric/semantic hue that clears ≥4.5:1 on white. The brighter fills (`premium`, bright greens) ride on **graphics, badges and large numbers** (the ≥3:1 cases), never small text.
- **Accent-on-accent text is illegal.** On a violet (`accent`) fill, text is `bg` (≈white). On an amber (`premium`) fill, text is `ink` (dark).
- **Premium = gold, but readable.** Filled premium badges/buttons use `premium` + `ink`/white text; premium *text links* use `premiumText`. Premium **upgrade buttons** are still interactive, so they read as gold (premium), not violet.
- **Gold is sacred.** `gold` (#FFC400) only ever paints the #1 leaderboard spot.

## Flutter (source of truth)

These map 1:1 to `lib/core/theme/app_colors.dart`; assembled into the Material light theme in `app_theme.dart` (`ThemeData.light` + `ColorScheme.light`).
