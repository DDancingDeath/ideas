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

## Owner-configurable role visibility & capabilities

The matrices above are the **fixed ceiling** — the maximum any role
can ever do or see. On top of that ceiling the owner can, from the
**Admin → Roles & Visibility** subtab, tune at runtime what each
non-owner role actually sees and can do. This is the in-product
control the owner asked for: "let me decide what staff and the
manager are shown," without a code change or redeploy.

The model mirrors the suspicion-engine's configurability
(`suspicion-engine.md` §Configurability): a sane default that equals
the spec, owner-only edits recorded as `shop_profile_updated`
events, server-side enforcement, and **hard floors that config can
never cross**.

### The one rule that keeps it safe: config narrows, never widens

`roleConfig` can only **subtract** from the ceiling. It can hide a
page a role would otherwise see and switch off an optional
capability a role would otherwise have. It can **never** grant a
role a cell that is `❌` in the matrices above. Privilege escalation
through configuration is structurally impossible — the adapter
clamps every grant to the ceiling before storing it.

### Shape (`shopProfile.roleConfig`)

```ts
// Lives on the shop profile in the domain. `owner` is never listed:
// the owner is always full and roleConfig cannot touch it.
roleConfig: {
  staff?:    RoleOverride;
  manager?:  RoleOverride;
  reviewer?: RoleOverride;
}

interface RoleOverride {
  // Pages this role may open. A page set to `false` is hidden even
  // if the matrix allows it. A page set to `true` that the matrix
  // denies is ignored (ceiling wins). Omitted page = matrix default.
  pages?: Partial<Record<PageId, boolean>>;

  // Optional, within-ceiling capability switches. Each CapabilityId
  // maps to one or more event types that are ✅ / 🟡 for this role.
  // `false` removes it (the adapter then treats those types as ❌
  // for this role); `true` / omitted = matrix default. A CapabilityId
  // the matrix denies for this role cannot be switched on.
  capabilities?: Partial<Record<CapabilityId, boolean>>;
}
```

`PageId` is the projection-read row set: `items`, `stock`,
`outstanding`, `history-own`, `history-all`, `today`, `cash-active`,
`cash-closed`, `reports`, `analytics`, `finance`, `margins`,
`review-queue`, `diagnostics`, `admin`, `audit-log`.

`CapabilityId` is a **curated, owner-friendly** set (not raw event
types) so the UI reads in plain language. Each maps to ceiling cells:

| CapabilityId | Governs (event type) | Ceiling it lives under |
|---|---|---|
| `sales.retail` | `retail_sale_created` | staff/manager/owner ✅ |
| `sales.wholesale` | `wholesale_sale_created` | staff/manager/owner ✅ |
| `purchase.record` | `purchase_recorded` | staff/manager/owner ✅ |
| `discount.apply` | discount lines on a sale (ties to per-role discount limit) | configurable per role |
| `expense.business` | `expense_recorded` (business) | staff/manager/owner ✅ |
| `outstanding.receive` | `outstanding_payment_received` | staff/manager/owner ✅ |
| `outstanding.pay` | `outstanding_payment_made` | manager/owner ✅ |
| `stock.adjust.small` | `stock_adjustment_recorded` (small) | staff 🟡 / manager+owner ✅ |
| `flags.resolve.lowMedium` | `flag_resolved` (low, medium) | manager/owner/reviewer ✅ |

Structural owner-only powers are **deliberately absent** from the
`CapabilityId` set, so there is no toggle that could ever expose
them: `user_role_changed`, `user_status_changed`,
`shop_profile_updated`, suspicion-threshold edits, and
`flag_resolved(block override)` stay owner-only by construction.

### Hard floors (config can never cross these)

| Floor | Rule (adapter rejects or clamps) |
|---|---|
| No escalation | Any `pages[p]=true` / `capabilities[c]=true` that the matrix marks `❌` for that role is clamped to the ceiling and has no effect. |
| Owner immutable | A `roleConfig.owner` key is rejected; the owner is always full. |
| Structural owner-only | No `CapabilityId` maps to `user_role_changed`, `user_status_changed`, `shop_profile_updated`, suspicion thresholds, or block-override. Config cannot reach them. |
| Audit & block-rules immovable | roleConfig cannot disable the audit log, the API-bypass enforcement, or any `block` suspicion rule. |
| Visibility ⊇ action | A role that keeps a capability whose flag it must act on cannot have the surfacing page hidden — e.g. keeping `flags.resolve.lowMedium` while hiding `review-queue` is rejected with a clear error. |
| Don't lock out billing | At least one active non-owner role must retain `sales.retail` (or the owner bills). A config that leaves no one able to make a sale is rejected. |
| Hidden ≠ unenforced | Hiding a page is a **read-visibility** change only. It never relaxes any write permission, and a hidden page's writes are still enforced server-side. |

### Enforcement (same path as the base matrix)

The storage adapter composes the effective decision; `⊓` means
"narrow only" — `🟡` stays `🟡` unless turned `❌`:

```
effectiveWrite(role, type) = matrixCeiling(role, type) ⊓ roleConfig[role].capabilities
effectiveRead(role, page)  = matrixRead(role, page)     ⊓ roleConfig[role].pages
```

UI checks are advisory (A2): the nav hides what config hides, but
the **server is authoritative**. A switched-off capability is
rejected with `PERMISSION_DENIED` whether the call comes through the
official service, a raw Firestore SDK call, or any internal helper —
the API-bypass guarantee above applies to the configured layer too.

### Editing it (Admin → Roles & Visibility)

The owner sees, per non-owner role, a checklist of pages plus the
capability toggles above. Matrix-`❌` cells render **greyed and
locked** — visibly present so the owner understands the ceiling, but
not switchable. **Save** writes exactly one owner-only
`shop_profile_updated{ changes.roleConfig }` event
(`event-schemas.md` §`shop_profile_updated`); a **Reset to defaults**
button restores the matrix defaults for that role. Every change is
audited (`by` = owner) and, because a restricted role can confuse
"why can't staff see Finance?", the **Diagnostics** page shows a
banner listing every role currently restricted below default.

### Required tests

- **Default = spec.** An empty / absent `roleConfig` reproduces the
  base matrices cell-for-cell (no behaviour change for shop-1 until
  the owner touches it).
- **Narrowing works.** Turning off `sales.wholesale` for `staff`
  makes `wholesale_sale_created` return `PERMISSION_DENIED` for a
  staff principal while `retail_sale_created` stays `✅`.
- **Hiding works.** Setting `pages.reports=false` for `manager`
  removes Reports from the manager's read API and nav; the same call
  by the owner still succeeds.
- **No escalation.** Setting a matrix-`❌` page/capability `true`
  (e.g. `staff.pages['admin']=true`) is clamped — staff still gets
  `❌` at the adapter.
- **Consistency floor.** A config that keeps `flags.resolve.lowMedium`
  but hides `review-queue` is rejected at save time.
- **Lock-out guard.** A config that removes `sales.retail` from every
  non-owner role is rejected.
- **Owner-only write.** Every `roleConfig` change emits exactly one
  `shop_profile_updated`; a non-owner attempting it gets
  `PERMISSION_DENIED`.
- **API-bypass.** A staff whose capability is switched off cannot
  perform it via a raw adapter call either.

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

- _2026-06-17_ · Added §Owner-configurable role visibility &
  capabilities — the in-product control the owner asked for. The
  matrices stay the fixed **ceiling**; `shopProfile.roleConfig` lets
  the owner, from **Admin → Roles & Visibility**, hide pages and
  switch off optional within-ceiling capabilities per non-owner role
  at runtime. Config **narrows, never widens** (no escalation), with
  hard floors (owner immutable, structural owner-only powers
  unreachable, audit/block-rules immovable, visibility ⊇ action,
  don't-lock-out-billing). Enforced server-side on the same path as
  the base matrix; changes are owner-only audited
  `shop_profile_updated` events; default config reproduces the spec
  cell-for-cell.
- _2026-06-15_ (later same day) · Added §Time-limit rules for
  staff edits — staff may edit / void / correct only their own
  bill, within the current cash session AND within
  `shopProfile.staff.editGraceMin` (default 5 min); enforced by
  the storage adapter, not just UI. Closes the recurring
  "can staff fix a typo?" question without giving staff a back
  door into older history.
