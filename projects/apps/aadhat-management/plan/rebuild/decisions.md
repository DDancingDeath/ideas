# Decisions — rebuild

> Tracker for the major technical and product decisions that need
> to be **frozen before M0** starts. The owner instructed the
> agent to freeze the tentative defaults so M0 can begin; rows
> may still be revisited and `superseded` with rationale.

## How this works

- Every row has a **status**: `tentative` (agent default,
  unreviewed), `confirmed` (signed off; the agent acts on it as
  fact), `superseded` (replaced by a later decision, kept for
  history), or `deferred` (out of scope for v2.0).
- To change a row, edit it in place and add a dated entry to
  `## Recent changes` at the bottom describing the change. A
  `confirmed` row can be `superseded`; do not silently flip it
  back to `tentative`.
- When a row is `confirmed`, the corresponding `TODO(spec)` in
  the spec subtree may be removed and the decision asserted as
  fact.

## Freeze-before-M0 decisions

| # | Decision | Choice | Status | Rationale | Owner | Decided on |
|---|---|---|---|---|---|---|
| 1 | UI framework | **SvelteKit** | `confirmed` | The owner asked for "very light and very responsive UI". Svelte's compiler-emitted runtime is the smallest mainstream option and its store/reactivity model maps cleanly onto event-driven projections. React remains an acceptable fallback if a future Implementation agent is materially more fluent in React; that switch would require a `superseded` entry, not silent change. | owner | 2026-06-15 |
| 2 | Backend | **Firebase (Firestore + Auth + Functions) only, no thin server** | `confirmed` | v1 already runs on Firebase; the printer / offline / auth pieces work. Firestore's security rules + emulator give us testable role enforcement (`A1–A5`). Re-evaluate after M5 only if projection queries become painful (open as a `superseded` candidate at that point). | owner | 2026-06-15 |
| 3 | Package manager | **pnpm** | `confirmed` | Faster installs, strict dependency tree, good monorepo support for the `apps/web`, `apps/printer-mock`, `packages/domain` layout. | owner | 2026-06-15 |
| 4 | `shopId` from day one | **Yes, default `shop-1`** | `confirmed` | Cheap to include now (every event already has `shopId` in the envelope); removing it later for productization is much more painful than carrying it forward. The cross-shop invariant (`A5`) is testable from day one. | owner | 2026-06-15 |
| 5 | Brother's role | **`owner` for v2.0; introduce dedicated `reviewer` in v2.1** | `confirmed` | Today only the brother does monitoring. Adding a `reviewer` role now expands the test matrix (every event type × every role) without buying anything until a second monitor exists. Tracked in [`role-permission-matrix.md`](../../spec/rebuild/role-permission-matrix.md) and deferred entry D2 below. | owner | 2026-06-15 |

## Nice-to-freeze-before-M0 (lower risk to defer)

| # | Decision | Choice | Status | Rationale | Owner | Decided on |
|---|---|---|---|---|---|---|
| 6 | Reference Android device for perf budgets | A current mid-range Android in the ₹15–20k band (Pixel 6a class or current Redmi Note) | `confirmed` | The shop staff actually uses a device in this band; budgets in [`../../spec/rebuild/performance-budgets.md`](../../spec/rebuild/performance-budgets.md) are written against this profile. Specific model selection is allowed to drift within the band without a `superseded` entry as long as the perf baseline is re-captured. | owner | 2026-06-15 |
| 7 | Telemetry destination | Firebase Crashlytics + Analytics, plus an `events_audit` collection inside the same Firestore | `confirmed` | The Firebase project already exists; no extra vendor. Audit is already an event stream by design. | owner | 2026-06-15 |
| 8 | Weight unit storage | Integer **milligrams** (1 kg = 1 000 000 mg) | `confirmed` | Matches the integer-money rule (`M1`). Avoids floating-point in `purchase_recorded` and `wholesale_sale_created` line totals. v1 used decimal kg with 2 dp; carry-over is a straightforward multiply-by-1000 on import. | owner | 2026-06-15 |
| 9 | Time-of-day boundary for "today" | Open cash-session window, fall back to midnight if no session is open | `confirmed` | The shop's "day" is bounded by opening and closing cash, not by midnight. This matches how the owner already thinks about Today. Documented in `quality-bar.md` and `scenarios.md`. | owner | 2026-06-15 |
| 10 | v1 → v2 cutover data strategy | **Snapshot** (import opening balances; start fresh event log) | `confirmed` | Snapshot is simpler, lower-risk, and avoids replaying v1's mutable history through v2's strict invariants. Full replay is deferred to v2.1 and treated as an optional research item (D3). See [`migration-cutover.md`](./migration-cutover.md). | owner | 2026-06-15 |

## Deferred to v2.1 or later

| # | Item | Why deferred |
|---|---|---|
| D1 | Multi-shop productization | Productize only after one external pilot shop runs the same engine successfully. See [`productize-later.md`](./productize-later.md). |
| D2 | Dedicated `reviewer` role | Brother is `owner` for v2.0. Add `reviewer` once a second monitoring person exists. |
| D3 | Full v1-event replay on cutover | Snapshot import is the v2.0 path. Replay is research-grade. |
| D4 | Native widgets (React Native / Flutter) | Capacitor is the v2.0 path; print integration risk is too high to redo. |
| D5 | Server-authoritative event ordering | Stay client-only on Firestore for v2.0. Re-evaluate after M5. |

## Open questions that block specific milestones

These are smaller than the freeze list and only need answers when
the corresponding milestone is approached.

| Blocks | Question | Recommendation |
|---|---|---|
| M3 (auth + roles) | Phone-OTP vs email/password for staff sign-in | Phone-OTP (matches v1 and Indian shop reality) |
| M4 (items + purchases) | Item barcode format support | Defer scanning to v2.1; manual entry for v2.0 |
| M5 (retail billing) | Should the bill number be per-shop, per-counter, or per-session? | Per-shop, monotonic, transactionally allocated server-side |
| M7 (outstanding) | Per-bill allocation UI default — auto-FIFO or manual | Auto-FIFO with manual override |
| M8 (cash sessions) | Default cash mismatch tolerance | ₹50 hard, ₹200 review |
| M9 (reports) | Cash-flow profit formula exact equality with v1 — line-by-line | Yes; pin with a snapshot test loaded from v1 numbers |
| M10 (printing) | ESC/POS Hindi rendering: bitmap or font | Bitmap fallback when the printer cannot render Devanagari natively |
| M11 (offline) | Outbox retention if the device stays offline for weeks | 30 days then surface a warning, do not silently drop |

## Recent changes

- 2026-06-16: cleaned up duplicate sections — `## Deferred to v2.1
  or later` and `## Open questions that block specific milestones`
  each appeared twice in the file (the second Open questions
  table was the more complete one, with M9 / M10 / M11 rows the
  first lacked). Kept the first Deferred table (D1–D5) and the
  second, complete Open questions table (M3–M11). No content
  was lost. User input: _"plan/rebuild/decisions.md still has
  duplicate sections for 'Deferred to v2.1' and 'Open questions.'
  Not harmful, but I'd clean that before giving it to agents as
  source of truth."_
- 2026-06-15 (later same day): owner instructed agent to freeze
  all `tentative` rows so M0 can begin. Rows 1–10 flipped to
  `confirmed` with today's date; agent recommendations stand as
  the chosen values. Any future change requires a `superseded`
  entry, not a silent revert to `tentative`. User input: _"Freeze
  the tentative decisions in plan/rebuild/decisions.md.
  Especially backend, UI framework, package manager, shopId,
  weight units, cutover strategy."_
- 2026-06-15: file created. All freeze decisions seeded as
  `tentative` with agent recommendations. Open-question table
  added for milestone-specific items.
