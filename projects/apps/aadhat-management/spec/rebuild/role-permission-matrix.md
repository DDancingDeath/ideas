# Role × permission matrix — rebuild

> Authoritative role/action map. Server rules enforce it; UI checks are advisory (A2). Security-rule tests assert every cell.

## Roles

| Role | Purpose | Number expected at shop-1 |
|---|---|---|
| `staff` | Shop-floor user: bills, payments, cash session. | 1 |
| `manager` | Reserved for productization. Limited admin: resolves `low`/`medium` flags, edits own-day bills with reason, views finance. | 0 in shop-1 today |
| `owner` | Full admin: voids, old-bill edits, roles/users/settings, any flag. | 1 (the user / family) |
| `reviewer` | Deferred to v2.1. Read/review role; brother runs as `owner` in v2.0. | 0 in v2.0 |
| `pending` | Registration awaiting owner approval. No access. | as-needed |
| `rejected` / `suspended` | Cannot sign in. | as-needed |

Until v2.1, treat `reviewer` cells as non-binding; brother is `owner` per [`../../plan/rebuild/decisions.md`](../../plan/rebuild/decisions.md) row 5.

## Legend

| Mark | Meaning |
|---|---|
| ✅ | Allowed; service appends event. |
| 🟡 | Owner approval required; request becomes effective only after `flag_resolved(resolution = approve)`. |
| ❌ | Rejected by storage adapter with `PERMISSION_DENIED`. |
| — | Not applicable. |

Repeated direct attempts at 🟡/❌ actions may raise `auth.role-escalation-attempt` per `shopProfile.auth.escalationWindowMin`.

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
| `stock_adjustment_recorded` (large, > `stock.adjustmentLargeMg`) | ❌ | 🟡 | ✅ | ❌ |
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

| Principal | Allowed events | Constraint |
|---|---|---|
| `engine` | `flag_raised` | Reject `flag_raised` from authenticated users. Runs server-side or trusted in-process client-only module. |
| `queue worker` | `print_attempt`, `print_succeeded` | In client-only mode writes as authenticated user with adapter-recognized worker flag. No other code path may append these. |
| System bootstrap | first `owner` user-create | Only for a brand-new shop with no existing owner. |

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

🟡 read access means an explicit reveal toggle records one audit row per reveal.

## API-bypass guarantee

For every `❌` cell, the official service, raw Firestore SDK path, and internal storage wrappers all reject with `PERMISSION_DENIED` and append no event. The security-rule suite asserts this cell-by-cell.

## Owner-configurable role visibility & capabilities

`shopProfile.roleConfig` is edited under **Admin → Roles & Visibility**. It narrows the fixed ceiling above; it never grants a matrix-`❌` cell.

### Shape (`shopProfile.roleConfig`)

```ts
roleConfig: {
  staff?: RoleOverride;
  manager?: RoleOverride;
  reviewer?: RoleOverride;
}

interface RoleOverride {
  pages?: Partial<Record<PageId, boolean>>;
  capabilities?: Partial<Record<CapabilityId, boolean>>;
}
```

`owner` is never listed. Omitted values use the matrix default. `true` on a denied page/capability is ignored; ceiling wins.

`PageId`: `items`, `stock`, `outstanding`, `history-own`, `history-all`, `today`, `cash-active`, `cash-closed`, `reports`, `analytics`, `finance`, `margins`, `review-queue`, `diagnostics`, `admin`, `audit-log`.

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

Owner-only powers have no `CapabilityId`: `user_role_changed`, `user_status_changed`, `shop_profile_updated`, suspicion-threshold edits, `flag_resolved(block override)`.

### Hard floors

| Floor | Rule (adapter rejects or clamps) |
|---|---|
| No escalation | Any `pages[p]=true` / `capabilities[c]=true` that the matrix marks `❌` for that role is clamped to the ceiling and has no effect. |
| Owner immutable | A `roleConfig.owner` key is rejected; the owner is always full. |
| Structural owner-only | No `CapabilityId` maps to `user_role_changed`, `user_status_changed`, `shop_profile_updated`, suspicion thresholds, or block-override. Config cannot reach them. |
| Audit & block-rules immovable | roleConfig cannot disable the audit log, the API-bypass enforcement, or any `block` suspicion rule. |
| Visibility ⊇ action | A role that keeps a capability whose flag it must act on cannot have the surfacing page hidden — e.g. keeping `flags.resolve.lowMedium` while hiding `review-queue` is rejected with a clear error. |
| Don't lock out billing | At least one active non-owner role must retain `sales.retail` (or the owner bills). A config that leaves no one able to make a sale is rejected. |
| Hidden ≠ unenforced | Hiding a page is a **read-visibility** change only. It never relaxes any write permission, and a hidden page's writes are still enforced server-side. |

### Enforcement and editing

```
effectiveWrite(role, type) = matrixCeiling(role, type) ⊓ roleConfig[role].capabilities
effectiveRead(role, page)  = matrixRead(role, page)     ⊓ roleConfig[role].pages
```

`⊓` means narrow only: `🟡` stays `🟡` unless turned `❌`. Nav hiding is advisory; the server remains authoritative. Save writes one owner-only `shop_profile_updated{ changes.roleConfig }` event ([`event-schemas.md`](./event-schemas.md) §`shop_profile_updated`). Reset restores matrix defaults for that role. Matrix-`❌` cells render greyed and locked. Diagnostics lists roles restricted below default.

### Required tests

- Empty/absent `roleConfig` reproduces the base matrices cell-for-cell.
- `staff.capabilities['sales.wholesale']=false` rejects `wholesale_sale_created`; `retail_sale_created` still succeeds.
- `manager.pages.reports=false` hides/rejects Reports for manager; owner still reads it.
- Matrix-`❌` true grants are clamped, e.g. `staff.pages['admin']=true` remains ❌.
- Keeping `flags.resolve.lowMedium` while hiding `review-queue` is rejected.
- Removing `sales.retail` from every non-owner role is rejected.
- Non-owner `roleConfig` edit gets `PERMISSION_DENIED`; owner edit emits one `shop_profile_updated`.
- Switched-off capability also fails through raw adapter access.

## Time-limit rules for staff edits

| Action | Window when staff may act | Outside the window |
|---|---|---|
| Edit / void / correct a bill they themselves created | Bill is within the current cash session **and** under `shopProfile.staff.editGraceMin` from creation; default in [`configuration.md`](./configuration.md). | Goes through 🟡 owner-approval flow per row above |
| Edit a bill created by **another** staff in the same session | ❌ always | Owner-only |
| Adjust stock (small) | Allowed during the staff's own session | Owner-only |
| Receive outstanding payment that overshoots a balance | ❌ always | Owner-only |

"Today's bill" means within the open cash session. The storage adapter enforces the grace window; stale `staff` events fail with `PERMISSION_DENIED`.

## User status and role transitions

| from → to | allowed by | notes |
|---|---|---|
| `pending → active` | owner | grants the registered role |
| `pending → rejected` | owner | sign-in blocked thereafter |
| `active → suspended` | owner | temporarily blocked, role preserved |
| `suspended → active` | owner | restore |
| `active → rejected` | owner | permanent |
| `rejected → *` | owner | re-evaluation; should be rare |

`user_role_changed`: any → any, owner only; `reason` required when target = `owner` or `reviewer`.

## Audit

- Every event carries `by` matching the authenticated user at append time.
- Approved 🟡 actions append `flag_resolved(resolution = approve)` referencing the request.
- Repeated rejected actions within `shopProfile.auth.escalationWindowMin` raise `auth.role-escalation-attempt`.

## Open questions

- `TODO(spec, blocks: M5)` — Decide whether `manager` should be implemented in v2.0 at all? **Default:** define the rules now (this table) but do not surface the role in UI until productization needs it.

