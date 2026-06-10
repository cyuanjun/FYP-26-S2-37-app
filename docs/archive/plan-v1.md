# Wise Workout — UI Flow Explorer (Plan v1)

A web app for visualising user flows for the Wise Workout mobile app. Each user role gets its own canvas page; each canvas is an activity-diagram-style graph of mock phone screens connected by arrows. You can pan, zoom, and jump between screens via a side hamburger menu.

This is a **design / flow exploration tool**, not the actual mobile app. The mobile app itself is built later.

---

## 1. Scope

### User roles (one canvas page each)

| Role | URL | Purpose |
|---|---|---|
| Free user | `/free` | Baseline experience: login → dashboard → core features |
| Premium user | `/premium` | Free features + paid additions (e.g. advanced analytics, unlimited plans) |
| Expert user | `/expert` | Coach / trainer flows: publish plans, manage clients, monetisation |
| System admin | `/admin` | Back-office: user management, content moderation, system health |

### Screen-fidelity decision
**Static phone-screen mocks connected by arrows.** Each screen is a styled `<div>` showing a single state of the mobile UI. Arrows on the canvas show the flow (e.g. Login → Dashboard → Profile). No in-screen interactivity in v1.

### Phone dimensions
- **Default:** 402 × 874 px (iPhone 16 Pro logical viewport). Matches Flutter's `MediaQuery.size`; status bar (59 px) + home indicator (34 px) live **inside** the 874, mirroring iOS safe-area conventions so screens translate 1:1 to Flutter later. See [[project-target-flutter]] context.
- **Future:** resolution picker in the top toolbar — switching the picker updates every phone-screen node on the active canvas (e.g. 360 × 640 small Android, 390 × 844 iPhone 13, 430 × 932 iPhone 15 Pro Max, 412 × 915 Pixel 7).

---

## 2. Tech stack

| Layer | Choice | Why |
|---|---|---|
| Build | **Vite** | Fast dev server, minimal config |
| Framework | **React 18** | Component model fits per-screen mocks |
| Routing | **React Router** | One route per user role |
| Canvas | **React Flow (`@xyflow/react`)** | Pan/zoom, draggable custom nodes, edge routing — exactly what an activity diagram needs |
| Styling | **Tailwind CSS** | Quick to mock phone UIs |
| Language | **TypeScript** | Catches screen-id typos in flow definitions |
| Icons | **lucide-react** | Clean, used inside phone mocks |
| Design tokens | [palette.md](../reference/palette.md) (colours) + [typography.md](../reference/typography.md) (iOS type scale) | Single source of truth for any colour or font-size choice in a screen mock. Tailwind config imports the palette directly. |

No backend. Flow definitions and screen mocks live in source files.

---

## 3. Information architecture

```
app-ui-FINAL/
├── docs/
│   ├── project-description.md
│   └── plan-v1.md            ← this file
└── app/                       ← new
    ├── index.html
    ├── package.json
    ├── vite.config.ts
    ├── tailwind.config.js
    ├── tsconfig.json
    └── src/
        ├── main.tsx
        ├── App.tsx            ← router + sidebar shell
        ├── components/
        │   ├── Sidebar.tsx           ← hamburger menu
        │   ├── PhoneFrame.tsx        ← 402×874 chrome wrapper
        │   ├── PhoneScreenNode.tsx   ← React Flow custom node
        │   ├── FlowCanvas.tsx        ← reusable canvas (takes nodes/edges)
        │   └── ResolutionPicker.tsx  ← future: dropdown to switch sizes
        ├── flows/
        │   ├── types.ts              ← Screen, FlowEdge types
        │   ├── free.ts               ← free-user screens + edges
        │   ├── premium.ts
        │   ├── expert.ts
        │   └── admin.ts
        ├── screens/                  ← actual phone-screen mock components
        │   ├── shared/               ← reused across roles (Login, Splash, etc.)
        │   │   ├── Login.tsx
        │   │   └── Signup.tsx
        │   ├── free/
        │   │   ├── Dashboard.tsx
        │   │   ├── Workouts.tsx
        │   │   ├── Activity.tsx
        │   │   ├── Social.tsx
        │   │   └── Profile.tsx
        │   ├── premium/
        │   ├── expert/
        │   └── admin/
        ├── pages/                    ← one per role
        │   ├── FreeFlow.tsx
        │   ├── PremiumFlow.tsx
        │   ├── ExpertFlow.tsx
        │   └── AdminFlow.tsx
        ├── state/
        │   └── resolution.ts         ← Zustand or React context for current phone size
        └── index.css
```

---

## 4. Core data model

```ts
// flows/types.ts
export type ScreenId = string;

export interface ScreenNode {
  id: ScreenId;
  title: string;             // shown above the phone frame, e.g. "Login"
  group?: string;            // for sidebar grouping: "Auth", "Main", "Settings"
  component: React.FC;       // the mock UI rendered inside the phone
  position: { x: number; y: number };  // initial canvas position
}

export interface FlowEdge {
  from: ScreenId;
  to: ScreenId;
  label?: string;            // e.g. "Tap Sign in"
}

export interface Flow {
  role: 'free' | 'premium' | 'expert' | 'admin';
  screens: ScreenNode[];
  edges: FlowEdge[];
}
```

Each `pages/<Role>Flow.tsx` does:

```tsx
import { flow } from '../flows/free';
export default () => <FlowCanvas flow={flow} />;
```

`FlowCanvas` adapts `Flow` into React Flow's `nodes` and `edges` arrays at mount, wraps each screen component in `<PhoneFrame>` inside a custom node type, and renders.

---

## 5. Layout & UX

```
┌──────────────────────────────────────────────────────────────┐
│ ☰  Wise Workout — Free User Flow         [402×874 ▼]  ⛶     │  ← top bar
├──────┬───────────────────────────────────────────────────────┤
│ SIDE │                                                       │
│ BAR  │              ╔══════╗     ╔══════╗                    │
│      │              ║ Login║ ──▶ ║Signup║                    │
│ Auth │              ╚══════╝     ╚══════╝                    │
│  Login│                 │                                    │
│  Sign │                 ▼                                    │
│       │             ╔══════════╗                             │
│ Main  │             ║Dashboard ║                             │
│  Dash │             ╚════╤═════╝                             │
│  Work │     ┌────────┬───┼───┬────────┐                      │
│  Act  │     ▼        ▼   ▼   ▼        ▼                      │
│  Soc  │  Workouts Act Soc Prof Settings                      │
│  Prof │                                                      │
│ Set   │       (pan & zoom this area freely)                  │
└──────┴───────────────────────────────────────────────────────┘
```

### Hamburger menu (Sidebar)
- Fixed left, collapsible via ☰ in top-left
- Tabs at top to switch role (Free / Premium / Expert / Admin) — selecting one navigates to that route
- Below tabs: grouped list of screens for the active flow (groups = the `group` field on each `ScreenNode`)
- Clicking a screen name calls `reactFlowInstance.fitView({ nodes: [{ id }] })` — pans + zooms the canvas to centre that phone

### Canvas (React Flow)
- Background: dotted grid (`<Background variant="dots" />`)
- Controls bottom-left: zoom in / out / fit-view / lock
- MiniMap bottom-right
- Phone nodes are draggable so you can rearrange the flow; positions persist to `localStorage` keyed by role
- Edges: smooth bezier, arrowhead end, optional label

### Top bar
- ☰ to toggle sidebar
- Title = current role
- Resolution picker (v1: 402×874 only, but built as a dropdown component so adding sizes is a one-line change)
- Fullscreen toggle

### Phone frame (`PhoneFrame.tsx`)
- Outer rounded container 44 px radius, 1 px ring (`faint`), drop shadow
- Inner viewport sized exactly to the current resolution (default 402 × 874)
- **iOS status bar (59 px)** — "9:41" on left, Dynamic Island centred (126 × 37 px black pill), signal/wifi/battery SVGs on right
- **Divider line (1 px `ink/10`)** below status bar — explicit "where the app starts" marker (mock-only; won't exist in Flutter)
- **App content** fills the remaining ~780 px with `overflow-hidden`
- **Home indicator (34 px)** — 134 × 5 px `ink/80` pill, bottom-centred
- Totals add to exactly 874 — matches Flutter's `MediaQuery.size` on iPhone 16 Pro

---

## 6. Initial flow inventory

Concrete v1 screens to mock. **Each role's canvas must render and connect at least these.**

### Free user (`/free`)
**Auth & onboarding (4 screens):** Splash → Login → {Forgot password | Onboarding (post-login, temporary)}
**Main — 5 bottom-nav tabs (8 screens):** Dashboard, Workouts → Workout detail → Active workout → Workout summary, Activity, Social, Profile
**Settings & upsell (3 screens):** Settings → Notifications, Upgrade to Premium
**Total: 15 screens.** Live inventory + status: [screens-v1.md](../reference/screens-v1.md). Signup is **external** — there is no in-app signup screen; users register on the marketing website (`fyp-26-s2-37-website.vercel.app`) linked from Login's footer.

### Premium user (`/premium`)
All Free screens **plus:** Premium Dashboard (extra analytics widgets), Advanced Analytics, Custom Plan Builder, Ad-free badge on Profile, Subscription Management under Settings.

### Expert user (`/expert`)
Login → Expert Dashboard → {My Clients, Plan Library, Publish Plan, Earnings, Profile}
Plan Library → Plan Editor → Preview → Publish
My Clients → Client Detail → Message Client

### System admin (`/admin`)
Login → Admin Dashboard → {User Management, Content Moderation, System Health, Reports, Settings}
User Management → User Detail → {Suspend, Reset, Refund}
Content Moderation → Flagged Post → {Approve, Remove, Warn User}

These flow lists are the v1 contract; later versions can add screens without touching the framework.

---

## 7. Resolution support (future-proofing)

State for current resolution lives in a small Zustand store:

```ts
// state/resolution.ts
export const useResolution = create<{ w: number; h: number; set: (w, h) => void }>(
  (set) => ({ w: 402, h: 874, set: (w, h) => set({ w, h }) })
);
```

`PhoneFrame` reads from this store, so changing the picker re-sizes every phone on the canvas instantly. v1 ships with the dropdown disabled (showing 402×874 only); enabling more sizes = pushing extra options into the picker.

Screen components must use relative sizing (`w-full h-full`, flex, %) — never hard-coded pixel widths — so they reflow when the frame changes.

---

## 8. Build & run

```bash
cd app
npm install
npm run dev          # opens http://localhost:5173
```

Routes:
- `/` → redirect to `/free`
- `/free`, `/premium`, `/expert`, `/admin` — canvas (overview) mode
- `/free/play`, `/premium/play`, `/expert/play`, `/admin/play` — interactive prototype mode (v2)

No backend, no auth, no build pipeline beyond Vite. Deploy = static-host the `dist/` output (Vercel, Netlify, or `gh-pages`).

---

## 9. Interactive prototype mode (v2)

Once all screens exist as components, the same flow definitions can drive a **second mode**: a single phone on screen that you actually navigate by tapping buttons inside it — like a real prototype run-through.

### How it reuses v1 work, with zero duplication

The static canvas and the interactive prototype render **the same screen components** from the same `flows/<role>.ts` files. The only thing that changes is the shell around them and what `goTo()` does.

```tsx
// v1 (canvas): goTo is a no-op, screens are visual only
// v2 (play):  goTo navigates to the next screen inside the phone
const { goTo } = useFlowNav();
<button onClick={() => goTo('dashboard')}>Sign in</button>
```

### Required v1 prep so v2 is cheap

To make v2 a small follow-up rather than a rewrite, v1 should already:

1. **Wrap screen components with a `FlowNavContext`.** In canvas mode the provider supplies a no-op `goTo`; in play mode it supplies a real one. Screen components are written against the context either way.
2. **Define edges with `trigger` IDs**, not just `from`/`to`. Extend `FlowEdge`:
   ```ts
   interface FlowEdge {
     from: ScreenId;
     to: ScreenId;
     trigger?: string;   // e.g. "signIn", "openProfile" — the button name on the source screen
     label?: string;
   }
   ```
   Screen components call `goTo('signIn')` and the context resolves it via the active flow's edges. This means a screen never hard-codes a destination screen ID — the flow file owns the routing, exactly like the canvas does.
3. **Treat screen components as pure UI given props.** No `useNavigate`, no router imports inside `screens/`. Only `useFlowNav()`.

### v2 shell (`PlayMode.tsx`)

- One `<PhoneFrame>` centred on the page (resolution picker still applies)
- Renders the current screen component
- A subtle back arrow on the phone bezel (browser back doesn't always make sense)
- A small "current screen" indicator + breadcrumb above the phone (e.g. `Login → Dashboard → Profile`)
- The sidebar still works as a debug jump: clicking a screen in the sidebar warps the prototype to that screen
- Toggle button in the top bar to flip between **Canvas** and **Play** for the active role

### Out of scope even in v2

- Form validation, real input handling
- Persisting prototype state across navigations (each visit starts fresh)
- Animations beyond a basic fade between screens

---

## 10. Implementation order

### v1 (canvas mode)

1. **Scaffold** `app/` with Vite + React + TS + Tailwind + React Router + `@xyflow/react`.
2. **Shell:** `App.tsx` with top bar, collapsible Sidebar, `<Outlet />` for the routed canvas.
3. **PhoneFrame + PhoneScreenNode**, wired to the resolution store with a single hard-coded size.
4. **FlowNavContext** with a no-op `goTo` — set up now so screen components are play-mode-ready.
5. **FlowCanvas**: takes a `Flow`, renders nodes + edges with React Flow.
6. **Free user canvas** end-to-end: define `flows/free.ts` (with `trigger` IDs on edges), build the screen mock components, wire edges, verify pan/zoom + sidebar jump works.
7. **Premium, Expert, Admin** canvases — same pattern.
8. **Resolution picker** wired to the store (still only one option).
9. **localStorage persistence** of node positions per role.
10. **Polish:** MiniMap, edge labels, screen group headers in sidebar.

Steps 1–6 are the critical path; once Free works end-to-end, the other three roles are mechanical.

### v2 (interactive prototype)

11. **PlayMode.tsx** shell — one phone, breadcrumb, back arrow.
12. **Real `FlowNavContext` provider** in play mode that resolves `goTo(trigger)` → next screen via the active flow's edges.
13. **Canvas ⇄ Play toggle** in the top bar.
14. **Audit screen components** to add `onClick={() => goTo(...)}` to the buttons that should navigate. Because the components were written against the context from day one, this is additive — no refactors.

---

## 11. Out of scope for v1

- Real mobile app code
- Authentication / backend / database
- In-screen interactivity beyond context wiring (buttons inside phone mocks don't navigate — that ships in v2)
- Exporting the canvas to PNG/PDF
- Multi-user editing
- More than one phone resolution actually selectable in the picker (the architecture supports it; v1 only ships one)
