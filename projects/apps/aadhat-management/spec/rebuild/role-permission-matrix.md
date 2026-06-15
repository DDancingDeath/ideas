# Role × permission matrix — rebuild

> The authoritative mapping of role to allowed action. Server-side
> rules (Firestore rules or equivalent) enforce this; UI checks are
> advisory (A2). Tests in the security-rule layer assert every cell
> below.

## Roles

| Role | Purpose | Number expected at shop-1 |
|---|---|---|
| `staff` | Day-to-day shop-floor user. Creates bills, takes payments, runs the cash session. | 1 |
| `manager` | (Reserved for productization.) Limited admin: can resolve `low` and `medium` flags, edit own-day bills with reason, view finance. | 0 in shop-1 today |
| `owner` | Full admin. Approves voids, edits old bills, changes roles/users/settings. Resolves any flag. | 1 (the user / family) |
| `reviewer` | **Open question.** A user who can read everything and resolve flags but cannot change settings or users. Brother's role candidate. | `TODO(spec)`: confirm. Default v2.0: brother runs as `owner`. |
| `pending` | New registration awaiting owner approval. Cannot do anything. | as-needed |
| `rejected` / `suspended` | Cannot sign in. | as-needed |

The `reviewer` row is included so the matrix is complete if the
owner decides to split monitoring from administration. Until then,
treat all `reviewer` cells as `owner` cells.

## How to read the table

- ✅ allowed; service appends the event without extra checks.
- 🟡 allowed with **owner approval**; event is enqueued as a
  request and only appended after a `flag_resolved(resolution =
  approve)` from an owner.
- ❌ rejected by the storage adapter with `PERMISSION_DENIED`.
- — not applicable (no semantic meaning).

When a row is `🟡` and a user fires it directly, the service may
record an `auth.role-escalation-attempt` flag if attempted
repeatedly without approval.

## Event-type permissions

| Event type | staff | manager | owner | reviewer |
|---|:-:|:-:|:-:|:-:|
| `item_created` | ❌ | ✅ | ✅ | ❌ |
| `item_updated` | ❌ | ✅ | ✅ | ❌ |
| `item_archived` | ❌ | 🟡 | ✅ | ❌ |
| `purchase_recorded` | ✅ | ✅ | ✅ | ❌ |
| `retail_sale_created` | ✅ | ✅ | ✅ | ❌ |
| `wholesale_sale_created` | ✅ | ✅ | ✅ | ❌ |
| `bill_voided` (today's bill) | 🟡 | ✅ | ✅ | ❌ |
| `bill_voided` (older bill) | ❌ | 🟡 | ✅ | ❌ |
| `bill_correction_recorded` (today) | 🟡 | ✅ | ✅ | ❌ |
| `bill_correction_recorded` (older) | ❌ | 🟡 | ✅ | ❌ |
| `stock_adjustment_recorded` (small) | 🟡 | ✅ | ✅ | ❌ |
| `stock_adjustment_recorded` (large, > `stock.adjustmentLargeKg`) | ❌ | 🟡 | ✅ | ❌ |
| `expense_recorded` (business) | ✅ | ✅ | ✅ | ❌ |
| `expense_recorded` (personal) | ❌ | ❌ | ✅ | ❌ |
| `withdrawal_recorded` | ❌ | 🟡 | ✅ | ❌ |
| `outstanding_payment_received` | ✅ | ✅ | ✅ | ❌ |
| `outstanding_payment_made` | ❌ | ✅ | ✅ | ❌ |
| `cash_session_opened` | ✅ | ✅ | ✅ | ❌ |
| `cash_session_closed` | ✅ | ✅ | ✅ | ❌ |
| `print_attempt` / `print_succeeded` | (queue worker only — see below) |
| `flag_raised` | (engine only — see below) |
| `flag_resolved` (severity = `low`) | ❌ | ✅ | ✅ | ✅ |
| `flag_resolved` (severity = `medium`) | ❌ | ✅ | ✅ | ✅ |
| `flag_resolved` (severity = `high`) | ❌ | 🟡 | ✅ | ✅ |
| `flag_resolved` (severity = `block` override) | ❌ | ❌ | ✅ | ❌ |
| `user_role_changed` | ❌ | ❌ | ✅ | ❌ |
| `user_status_changed` | ❌ | 🟡 | ✅ | ❌ |
| `shop_profile_updated` (non-suspicion fields) | ❌ | 🟡 | ✅ | ❌ |
| `shop_profile_updated` (suspicion thresholds) | ❌ | ❌ | ✅ | ❌ |
| `shop_profile_updated` (disable `block` rule) | ❌ | ❌ | ❌ | ❌ |

### Special principals

- **`engine` principal** is the only one allowed to append
  `flag_raised`. The storage adapter rejects `flag_raised` from any
  authenticated user. The engine runs server-side (when there is a
  server) or as a trusted in-process module (client-only mode).
- **`queue worker` principal** is the only one allowed to append
  `print_attempt` and `print_succeeded`. In client-only mode the
  worker runs as the authenticated user but writes with a flag the
  adapter recognizes; in any case, no other code path may append
  these types.
- **System bootstrap.** The very first user-create for a brand-new
  shop is the only path that may create an `owner` without an
  existing owner approving it.

## Projection-read permissions

| Projection / page | staff | manager | owner | reviewer |
|---|:-:|:-:|:-:|:-:|
| Items master | ✅ | ✅ | ✅ | ✅ |
| Live stock | ✅ | ✅ | ✅ | ✅ |
| Outstanding (per-party) | ✅ | ✅ | ✅ | ✅ |
| History (own bills, last 30 days) | ✅ | ✅ | ✅ | ✅ |
| History (all bills, all time) | ❌ | ✅ | ✅ | ✅ |
| Today page | ✅ | ✅ | ✅ | ✅ |
| Cash sessions (active) | ✅ | ✅ | ✅ | ✅ |
| Cash sessions (closed, historical) | ❌ | ✅ | ✅ | ✅ |
| Reports / Analytics / Finance | ❌ | ✅ | ✅ | ✅ |
| Margins / cost-of-goods | ❌ | 🟡 | ✅ | ✅ |
| Review Queue | ❌ | ✅ | ✅ | ✅ |
| Diagnostics | ❌ | ✅ | ✅ | ✅ |
| Admin (users, roles, shop profile) | ❌ | ❌ | ✅ | ❌ |
| Audit log | ❌ | ✅ (last 30 d) | ✅ | ✅ |

> 🟡 in projection-read context means "available behind an explicit
> reveal toggle that records an audit row for each reveal." This
> prevents an over-the-shoulder margin disclosure without leaving a
> trace.

## API-bypass guarantee

For every `❌` cell above:

- Attempting the action via the official application service
  rejects with a clear UX error and no event is appended.
- Attempting the action by talking directly to the storage
  adapter (e.g. raw Firestore SDK call) is rejected by the rules
  engine with `PERMISSION_DENIED`.
- Attempting the action via any internal helper that wraps the
  storage adapter is also rejected by the same rules engine — the
  UI's "trusted" code path is not actually trusted by the adapter.

This is asserted by the security-rule test suite cell-by-cell.

## Time-limit rules for staff edits

Staff-allowed edit windows resolve the recurring "can staff fix a
typo on a bill they just made?" question without giving staff a
back door into older history.

| Action | Window when staff may act | Outside the window |
|---|---|---|
| Edit / void / correct a bill they themselves created | Bill is within the current cash session **and** under `shopProfile.staff.editGraceMin` (default `5 min`) from creation | Goes through 🟡 owner-approval flow per row above |
| Edit a bill created by **another** staff in the same session | ❌ always | Owner-only |
| Adjust stock (small) | Allowed during the staff's own session | Owner-only |
| Receive outstanding payment that overshoots a balance | ❌ always | Owner-only |

`shopProfile.staff.editGraceMin` defaults to **5 minutes** and is
configurable by the owner. The "today's bill" gating elsewhere in
this matrix is the **open cash session window** (recommended in
the open question below) — the 5-minute grace is the strictly
tighter window inside it for staff-initiated edits without
owner approval.

The window is enforced by the storage adapter (not just UI):
events older than the grace from a `staff` principal fail with
`PERMISSION_DENIED` regardless of UI state.



| from → to | allowed by | notes |
|---|---|---|
| `pending → active` | owner | grants the registered role |
| `pending → rejected` | owner | sign-in blocked thereafter |
| `active → suspended` | owner | temporarily blocked, role preserved |
| `suspended → active` | owner | restore |
| `active → rejected` | owner | permanent |
| `rejected → *` | owner | re-evaluation; should be rare |

State transitions for `user_role_changed`: any → any, owner only,
with `reason` required when target = `owner` or `reviewer`.

## Audit on every permission-relevant action

- Every appended event carries `by` = the principal. Tests assert
  this matches the authenticated user at append time.
- Every `🟡` action that is approved appends a
  `flag_resolved(resolution = approve)` referencing the request.
- Every rejected action that the user attempted multiple times
  within `shopProfile.auth.escalationWindowMin` raises an
  `auth.role-escalation-attempt` flag.

## Open questions

- `TODO(spec)`: Confirm whether to introduce the `reviewer` role
  in v2.0 or defer. Recommended: defer to v2.1; brother starts as
  `owner`. If introduced, every `✅` for `reviewer` in this table
  is binding; until then, treat as `owner`.
- `TODO(spec)`: Decide the exact threshold "today's bill" vs
  "older bill" — is it shop-local midnight, the open cash session
  window, or a fixed N-hours window? Recommended: open cash
  session window (so a bill is "today's" until the session is
  closed, even past midnight).
- `TODO(spec)`: Decide whether `manager` should be implemented in
  v2.0 at all. The shop today has zero managers. Recommended:
  define the rules now (this table) but do not surface the role in
  UI until productization needs it.

## Recent changes

- _2026-06-15_ (later same day) · Added §Time-limit rules for
  staff edits — staff may edit / void / correct only their own
  bill, within the current cash session AND within
  `shopProfile.staff.editGraceMin` (default 5 min); enforced by
  the storage adapter, not just UI. Closes the recurring
  "can staff fix a typo?" question without giving staff a back
  door into older history.
