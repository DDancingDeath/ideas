# Rebuild roadmap

> Opinion: build the rules of the business before any screen. Once
> the domain + event log + invariants + suspicion engine + scenario
> suite are solid, every screen on top is downhill work that agents
> can build aggressively because the safety net is real.

## Sequencing principle

For each milestone the order inside is always:

1. **Spec** — update `spec/rebuild/` if needed.
2. **Scenario fixtures** — add or extend in the test suite.
3. **Tests** — unit, scenario, invariant, security as applicable.
4. **Implementation** — smallest coherent change that makes the
   tests pass.
5. **UI** — only after the service it consumes is green.
6. **Audit + release note** — every milestone produces a short note
   for the owner and the brother.

## Milestones

### M0 — Foundation (no screens yet)

- Pick tech stack from `tech-candidates.md`.
- Stand up monorepo / package layout: `domain`, `services`,
  `storage`, `print`, `ui`, `mobile`, `tests`.
- Choose backend (Firestore vs Postgres+server) and document the
  decision.
- CI green on an empty test suite.
- Scenario-fixture loader and replay harness running.
- Decision: in-memory storage adapter as the test default; real
  adapter behind the same interface for staging / production.

### M1 — Domain core

- Money math: bill totals, labor, payment split, rounding to paise.
- Stock math: derivation from events; moving-average rate.
- Cash math: open / close / expected / mismatch.
- Outstanding math: per party, against bill, partial settlement.
- Period aggregations (the v2 successor to `PeriodMath`).
- Permission rules as pure functions.
- All invariants in `invariants.md` asserted by the suite.
- Property-based suite running with a fixed seed.

### M2 — Event ledger + storage adapter

- Append-only store interface.
- In-memory adapter (used in tests) and chosen real adapter.
- Server-assigned timestamps; idempotency-key uniqueness.
- Projections: stock, cash, outstanding, history, audit, reports.
- Replay must equal the in-memory state for every fixture.

### M3 — Auth + roles + security rules

- Owner / manager / staff. Brother defaults to owner role for v2.0
  (see `spec/rebuild/review-queue.md` open question).
- Server-side rules enforce the matrix from `invariants.md` A1–A5.
- Security-rule tests cover every cell of the matrix.

### M4 — Bill lifecycle + idempotency + print queue (no screens
yet)

- `createRetailBill`, `recordPurchase`, `createWholesaleSale`,
  `voidBill`, `recordCorrection`.
- Idempotency end-to-end; double-tap and replay tests green.
- Print queue with mock printer driver; reprint, retry, fail,
  cancellation all covered.
- The whole bill flow runs in tests without a browser or device.

### M5 — Suspicion engine

- Implement every rule in `suspicion-engine.md` with at least one
  positive and one negative fixture per rule.
- Background reconciliation job for R1–R4.
- Tunable `shopProfile` thresholds.

### M6 — UI shell + auth screens

- Mobile-first shell, routing, layout primitives.
- Login, register, role gating.
- Visual snapshots for the shell.

### M7 — Item master + Billing pages

- Items page.
- Billing page: retail, purchase, wholesale modes.
- Voice billing v1 (the v1 spec covers the parser; reuse).
- All Playwright bill flows green.

### M8 — Stock + History + Outstanding + Cash

- Stock view (derived).
- History view, with print status and void / correction surfacing.
- Outstanding per-party.
- Cash sessions (open / activity / close).

### M9 — Today + Finance + Reports + Analytics

- Today page (shop control room).
- Finance, Reports, Analytics all reading from the period helper.
- R4 (cross-page agreement) test must stay green.

### M10 — Review Queue + Diagnostics + Admin + Settings

- Review Queue page with the actions in
  `spec/rebuild/review-queue.md`.
- Diagnostics: queue, sync, printer, reconciliation status.
- Admin: users, roles, shop profile.
- Settings: per-user preferences.

### M11 — Capacitor wrap + real Bluetooth printer + manual smoke

- Android build via Capacitor.
- Real ESC/POS driver behind the queue's interface.
- Manual smoke test from `quality-bar.md` passes.

### M12 — Migration + cutover

- Decide v1→v2 data import strategy (open question in
  `event-ledger.md`).
- Dual-run period: brother monitors v1 and v2 in parallel for an
  agreed window.
- Cutover plan with rollback.

### v2.1 candidates (after cutover, not before)

- AI Assistant chat tab.
- Voice billing v2 (multi-item single-utterance).
- Camera / barcode scan.
- Productization for shop-2 (see `productize-later.md`).
- WhatsApp share polish.

## Anti-patterns to avoid

- Starting with the dashboard before the math engine exists.
- Letting the print integration in M11 force changes to the queue
  interface settled in M4 — the queue interface is mock-first by
  design.
- Skipping scenario fixtures because "the unit tests already cover
  it" — scenarios are the contract with the business, not a
  duplicate of unit coverage.
- Adding a screen before the service it consumes is green in CI.
- Cutting over in M12 without a dual-run window. v1 is in
  production every day; the bar for switching is the bar for
  trust.
