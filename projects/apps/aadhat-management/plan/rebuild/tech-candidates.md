# Tech candidates

> Opinion. The owner picks before M0. Once picked, the choice is
> locked for v2.0 unless there's a hard reason to change.

## Language

| Choice | Why | Why not |
|---|---|---|
| **TypeScript** (recommended) | Strong types make domain invariants encodable; shared between web + mobile + tests; large library ecosystem; the existing v1 is JS so the migration is small | Build step adds friction vs v1's no-build approach |
| Plain JS (v1) | Lowest friction; matches v1 | No compile-time invariant checks; refactor cost grows |
| Kotlin / Swift (native) | Best perf per platform | Two codebases; printer story already works on web; doubles the test surface |

**Recommendation: TypeScript everywhere.** The whole architecture
in `spec/rebuild/architecture.md` benefits from types.

## UI framework

| Choice | Why | Why not |
|---|---|---|
| **SvelteKit** (recommended) | Smallest runtime; very light UI which the owner asked for explicitly; reactivity model is friendly for event-projection rendering | Smaller ecosystem than React; fewer ready-made component libs |
| React | Largest ecosystem; most agents understand it best; well-known testing story | Heavier runtime; more discipline needed to keep components dumb |
| Lit | Web-components-native; framework-light; close to v1's vanilla feel | Smaller community; less Playwright tooling |
| Vanilla ES6 (v1) | Zero framework cost; v1 already proves it works on phones | Component reuse is manual; testing UI is harder |

**Recommendation: SvelteKit, with React as the fallback if the
agent roster is more confident in React.** The owner asked for a
very light UI; that points to Svelte. If you pick React, prefer the
smallest stack (e.g. Vite + React + a minimal component lib like
Mantine or shadcn-style).

## Mobile wrapper

| Choice | Why | Why not |
|---|---|---|
| **Capacitor 7** (recommended, v1 baseline) | Already proven with Bluetooth ESC/POS on Android in v1; the printer plugin works; PWA fallback for free | Native perf is upper-bounded by WebView |
| React Native | Closer to native widgets | Doubles the JS stack story; printer plugin needs porting |
| Flutter | Best perf | Throws away v1's web codebase entirely; agents less fluent |

**Recommendation: Capacitor 7.** The printer integration in v1 is
the riskiest piece to redo; keeping Capacitor lets us reuse the
proven path.

## Backend / storage

| Choice | Why | Why not |
|---|---|---|
| **Firebase Firestore + Auth** (v1 baseline) | Already in production; rules engine works; `onSnapshot` projections are natural; no server to run | Event-ledger model is less natural than in a relational store; rule complexity grows; vendor lock-in |
| Supabase (Postgres + Auth + Realtime) | Append-only event table fits Postgres perfectly; SQL projections; RLS comparable to Firestore rules | New backend to learn; the family shop has a working Firebase project |
| Self-hosted Postgres + a small Node server | Full control; cheapest at scale | Operational burden; one-person shop should not run a server |

**Recommendation: stay on Firebase for v2.0 unless the projection
queries become painful.** The event-ledger pattern works on
Firestore — the events collection is the source, and projections
are either materialized in other collections or computed
client-side. Re-evaluate after M5.

The hard `TODO(spec)` to settle before M0: client-only with
Firestore client SDK, or thin server (Cloud Functions / Cloud Run)
for authoritative event ordering and projection materialization.

## Validation

- **Zod** for runtime schema validation of every event payload, API
  input, and config object. Pairs with TypeScript for inferred
  types.

## Testing

| Layer | Recommendation |
|---|---|
| Unit + scenario + invariant | **Vitest** (fast, ESM-native, TS-friendly) |
| Property-based | **fast-check** |
| E2E | **Playwright** (mobile-viewport emulation; cross-browser; trace viewer) |
| Visual regression | Playwright snapshots + a diff tool (built-in or `pixelmatch`) |
| Security rules | **Firebase emulator suite** (if staying on Firebase) or rule-runner against the chosen backend |
| Perf | Playwright + `performance.measure` + long-task counting; nightly perf harness |
| Mobile smoke | Android device + Capacitor; manual checklist in `quality-bar.md` |

## Printer

- ESC/POS via a Capacitor plugin or the existing v1 driver path. The
  driver hides behind the queue interface in
  `spec/rebuild/print-queue.md`, so the choice can be swapped
  without changing services.
- Mock driver is the test default; the real driver is exercised by
  the manual smoke test only.

## State / data layer (UI side)

- The store layer is small because projections come from services.
  Recommend a tiny store primitive (Svelte stores natively; for
  React, Zustand or signals).
- No Redux-style global mutable state. Each page subscribes to the
  projections it needs.

## CI

- GitHub Actions on the rebuild repo. Required jobs: lint, type
  check, unit, scenario, invariant, integration, security-rule,
  Playwright (in-memory backend), perf budgets, visual snapshots.
- Nightly: Playwright against staging Firestore + property-based
  with random seeds.

## Logging / telemetry

`TODO(plan)`: pick a telemetry destination. Candidates:

- Firebase Crashlytics + Analytics (already a Firebase project).
- A simple `events_audit` collection inside the same Firestore
  (since everything is already events).

## Dev environment

- Node LTS (currently 22.x).
- pnpm or npm — pick one, document it.
- A single `pnpm dev` / `npm run dev` boots the app against the
  in-memory backend so a new contributor (or agent) can be
  productive in three commands.

## Decisions to make before M0

1. UI framework: SvelteKit or React.
2. Backend: Firestore-only or Firestore + thin server.
3. Package manager.
4. Reference Android device for perf budgets.
5. Telemetry destination.
6. Whether to import v1 data on cutover (`event-ledger.md` open
   question).
