# Wise Workout — Typography

iOS-faithful type scale used inside the phone mocks. Sizes match Apple's Human Interface Guidelines so screens translate 1:1 to Flutter / Cupertino later (1 iOS pt = 1 logical px).

Pair with [palette.md](palette.md) for colour tokens.

## Type scale

| Token | iOS style | px | Tailwind | Where we use it |
|---|---|---|---|---|
| Large Title | Large Title | 34 | `text-[34px]` | Major section headers (Today, Workouts) |
| Title 1 | Title 1 | 28 | `text-[28px]` | Screen titles |
| Title 2 | Title 2 | 22 | `text-[22px]` | Sub-titles, card headers |
| Title 3 | Title 3 | 20 | `text-[20px]` | List section headers |
| Body | Body | 17 | `text-[17px]` | Input values, buttons, primary copy |
| Headline | Headline | 17 (semibold) | `text-[17px] font-semibold` | Card titles, list rows |
| Subheadline | Subheadline | 15 | `text-[15px]` | Secondary text, toggle labels, taglines, link text |
| Footnote | Footnote | 13 | `text-[13px]` | Small print, helper text, footer copy |
| Caption 1 | Caption 1 | 12 | `text-xs` | Timestamps, micro-labels |
| Caption 2 | Caption 2 | 11 | `text-[11px]` | Form field labels, uppercase tags |

## Weights (app)

The Flutter implementation ([`lib/core/theme/app_typography.dart`](../../app/lib/core/theme/app_typography.dart)) runs the secondary scale a notch heavier than plain regular — small text reads thin on a white background, so weight does the legibility work that the dark theme got from contrast. Sizes are unchanged.

| Token | Weight | Token | Weight |
|---|---|---|---|
| Large Title / Title 1 | w700 | Body | **w500** |
| Title 2 / Title 3 | w600 | Headline | w600 |
| Subheadline | **w600** | Footnote | **w600** |
| Caption 1 | **w600** | Caption 2 | **w700** (uppercase labels) |

## Brand wordmark sizes (Barlow-weight Display)

The `Wordmark` component sizes are display headlines — pick by visual weight, not iOS body parity:

| Wordmark size | Tailwind | Closest iOS style |
|---|---|---|
| `sm` | `text-lg` (18px) | Headline |
| `md` | `text-2xl` (24px) | Title 2-ish |
| `lg` | `text-4xl` (36px) | Large Title +2 |
| `xl` | `text-5xl` (48px) | (no iOS equivalent — hero only) |

## Rules

- **Default to 17px** for any body or button copy unless there's a specific reason to go smaller / larger.
- **Form field labels** are always `text-[11px]` uppercase muted (Caption 2).
- **Toggle / checkbox labels** are `text-[15px]` (Subheadline).
- **Don't use Tailwind's `text-sm` (14px) inside phone mocks** — it's between Subheadline (15) and Footnote (13) and matches no iOS style. Pick one of those instead.
- **Outside the phone** (sidebar, explorer chrome in `App.tsx`) — iOS scale doesn't apply; use Tailwind defaults.
