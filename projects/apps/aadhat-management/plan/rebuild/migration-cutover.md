# Migration & cutover — rebuild

> How v1 (current production AadhatManagementApp) becomes v2 in
> the family shop without losing data, money, or the brother's
> trust. This document lives in `plan/rebuild/` because every
> choice here is opinionated.

## Goal

Move the family shop from v1 to v2 with:

1. **No silent data loss.** Every rupee that v1 knew about is
   either represented in v2 or explicitly written off in v1 before
   cutover.
2. **No double-booking.** A single business day never appears in
   both v1's and v2's totals.
3. **A real rollback path.** v1 stays deployed and able to take
   writes until v2 has earned trust.
4. **Brother sign-off.** The brother (monitoring role today)
   compares both totals and approves the cutover.

## Strategy: snapshot, not replay

For v2.0 the cutover strategy is a **snapshot import**:

- v1's closing balances on a chosen cutover date become the
  opening events in v2.
- v1's historical transactions stay in v1; v2 starts its event
  log fresh from the snapshot.
- v2 carries one synthetic event per opening (party balance, item
  stock, cash on hand) so the audit log is complete.

### Why not a full replay?

Replaying v1's mutable history into v2's strict event log is
research-grade work:

- v1 allowed direct edits to past transactions. v2 forbids them.
  Replay would need a per-row decision: void, correct, or skip.
- v1's stock/cash math has known drift in some edge cases (the
  reason for the rebuild). Replay would inherit that drift.
- v1 has no `idempotencyKey` per write. Replay would need a
  synthetic key per row, with no protection if it runs twice.

Replay remains a candidate for v2.1 as a research item; see
[`decisions.md` D3](./decisions.md#deferred-to-v21-or-later). For
v2.0, snapshot is the chosen path.

## Snapshot contents

The import is a small set of `opening_*` synthetic events,
appended once with `by: 'migration-tool'` and a fixed
`idempotencyKey = 'migration:v1-to-v2:<cutoverDate>:<kind>:<id>'`:

| Opening event | Source in v1 | v2 event type used | Notes |
|---|---|---|---|
| Item master | v1 items collection | `item_created` | One event per active item; archived items skipped or `item_archived` |
| Item opening stock | v1 stock projection at end of cutover day | `stock_adjustment_recorded` with `reason: 'opening-balance'` | Sets v2's stock baseline; moving-avg rate carried from v1 if known else 0 |
| Party master | v1 parties collection | `party_created` (if v2 has one; else carried into outstanding-opening references) | Phones / addresses preserved |
| Party opening outstanding | v1 outstanding-per-party at end of cutover day | `outstanding_payment_made` / `outstanding_payment_received` synthetic with `reason: 'opening-balance'` | Sign chosen so the resulting balance equals v1's |
| Cash on hand | v1 cash at end of cutover day | `cash_session_opened` with `openingCount = v1.cashOnHand` | First v2 session opens with v1's closing cash |
| Shop profile | v1 settings | `shopProfile_set` (or equivalent config write) | Bill format, language defaults, mismatch thresholds |

After the snapshot, v2's projections should equal v1's
projections at the cutover instant. This is the **R1–R4
equality** check (see below).

## Dual-run window

For **2–4 weeks** after cutover, v1 and v2 run side-by-side:

- All real shop activity goes through **v2** (this is the
  "cutover" — there is no double entry).
- v1 stays deployed in **read-only mode** for staff (no new bills)
  but with full read access for the brother to compare numbers.
- Each evening, the brother spot-checks: today's v2 totals vs the
  same day's v1 cash count, vs paper records.
- The reconciliation worker in v2 runs daily over the dual-run
  window and surfaces any `recon.projection-mismatch`.

The window ends when **all** of the following are true:

1. ≥ 2 full weeks elapsed.
2. Brother's flag-resolution rate in v2 is calmer than the v1
   baseline for the same shop volume (i.e., v2 is not raising
   more spurious flags than v1 produced bugs).
3. Zero unresolved `Sev-1` flags in v2's Review Queue.
4. Zero `recon.projection-mismatch` events in the past 7 days.
5. Brother explicitly signs off (a recorded `cutover_signed_off`
   event with `by: <brother>` and a free-text note).

If any condition fails at the end of 4 weeks, the dual-run window
extends; it does not automatically close. The brother decides.

## Rollback plan

Rollback during the dual-run window is straightforward because v1
is still deployed:

1. Switch the staff device's bookmark / app from v2 back to v1.
2. Re-enable writes in v1 (toggle the read-only flag).
3. Take v2's cumulative events since cutover and replay the
   business intent (sales, payments, etc.) back into v1 by hand
   or with a small script. This is feasible because the dual-run
   window is bounded to weeks, not months.
4. Emit a `cutover_rolled_back` event in v2 (kept for audit) and
   freeze v2 writes.

Rollback after the dual-run window closes is **not supported** as
a one-button operation; v2 becomes the source of truth and any
revert would be a project of its own.

## Mismatch criteria that block cutover

A cutover **must not** proceed if any of the following hold at
the planned moment:

- Any `R1–R4` invariant disagreement between v1 and v2 on the
  cutover-day snapshot:
  - `R1`: v1 totalSales for today ≠ v2 projected totalSales from
    replayed events for today's snapshot
  - `R2`: v1 cashOnHand ≠ v2 cashOnHand
  - `R3`: v1 outstanding-per-party ≠ v2 outstanding-per-party
  - `R4`: v1 Today / Reports inconsistency
- Any item with a v1 stock value v2 cannot represent (negative
  stock without an explanatory event, missing item id, etc.).
- Any party with a v1 outstanding value that does not sum to its
  per-bill breakdown (a known v1 drift; must be fixed in v1
  first).
- Any open BT print job in v1's queue at cutover (must drain or
  be explicitly abandoned).
- Brother veto for any reason. The brother has unilateral block
  authority on cutover.

## Cutover checklist (concrete steps)

The day-of-cutover runbook, executable by the implementer:

1. **T-7 days**: brother and owner agree on cutover date.
2. **T-3 days**: run the snapshot import against a staging v2
   project. Compute R1–R4 equality. Resolve every disagreement.
3. **T-1 day**: print and review the comparison report (v1 vs
   staging v2). Brother sign-off on staging.
4. **T-0 morning**: close v1 cash session. Reconcile to paper /
   counted cash. Mark v1 read-only.
5. **T-0**: run the snapshot import against production v2.
   Verify R1–R4 again, in production this time.
6. **T-0**: open v2 cash session (`cash_session_opened` with
   `openingCount = v1.cashOnHand`). Print a paper receipt of the
   opening for the brother's records.
7. **T-0**: staff device switches to v2 for the next sale.
8. **T-0 evening**: brother reviews v2's Today vs the day's
   paper / counted cash. Any drift → flag, investigate,
   document.
9. **T+1 .. T+14/28 (dual-run window)**: brother daily
   comparison; reconciliation worker daily; no production v1
   writes.
10. **Window close**: brother emits `cutover_signed_off`. v1 may
    be archived (read-only forever) or decommissioned at the
    owner's pace.

## Cutover criteria expressed as automated checks

The migration tool exposes the following commands; each is
green / red:

| Check | Green when |
|---|---|
| `migration check items` | Every active v1 item maps to exactly one v2 `item_created` import event |
| `migration check parties` | Every v1 party maps cleanly; phones / names preserved |
| `migration check stock` | For every item, v1 stock == v2 projected stock after import |
| `migration check outstanding` | For every party, v1 outstanding == v2 projected outstanding after import |
| `migration check cash` | v1 cashOnHand == v2 opening-session amount |
| `migration check totals` | R1–R4 equal on the cutover-day snapshot |
| `migration check audit` | Every import event has a stable idempotencyKey and is recorded with `by: migration-tool` |
| `migration check rollback-ready` | v1 still writable, v2 cumulative event log exportable |

A red on any of these blocks the cutover. The runbook step at
T-0 is gated by all of them green.

## Brother's role in cutover (explicit)

- Sole authority to block cutover and to close the dual-run
  window.
- Reviews the comparison report at T-3, T-0, and daily during
  dual-run.
- Resolves any `Sev-1` flag personally before window close.
- Signs off with a recorded event, not just a verbal yes.

This concentration of authority in the brother is deliberate:
the brother is the trust function in this shop's operating model
([`scope-boundaries.md`](../../spec/rebuild/scope-boundaries.md)).

## Open items

- `TODO(plan)`: pick the exact dual-run window length within
  2–4 weeks (default 2; brother extends if needed).
- `TODO(plan)`: decide if v1 is archived read-only after window
  close, or decommissioned. Default: archived for one year, then
  decommissioned.
- `TODO(plan)`: write the migration-tool repo (separate from the
  rebuild app; small Node CLI) once v2 reaches M5.

## Recent changes

- 2026-06-15: file created. Snapshot-only strategy chosen for
  v2.0; full replay deferred to v2.1. Dual-run window 2–4 weeks
  with brother sign-off as window-close gate. R1–R4 invariants
  used as the equality contract between v1 and v2 at cutover.
