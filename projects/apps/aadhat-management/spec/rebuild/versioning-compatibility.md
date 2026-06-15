# Versioning and compatibility — rebuild

> How the app, the event schemas, and the backend evolve
> without breaking the shop. The contract that
> [`failure-modes.md`](./failure-modes.md) §F8 (old client) and
> §F16 (update during business hours) depend on.

## Three things that have versions

| Thing | Where the version lives | Bumped when |
|---|---|---|
| `appVersion` | Build metadata; sent with every write as a header / field | Every release |
| `schemaVersion` (event) | Field on every event envelope (per [`event-schemas.md`](./event-schemas.md)) | An event payload shape changes in a non-additive way |
| `domainVersion` | Constant in the shared domain package; embedded in cache keys | Any change to projection `apply()` semantics |

The three are independent. `appVersion` bumps every release;
`schemaVersion` bumps only when an event's payload changes
incompatibly; `domainVersion` bumps when a fold changes meaning
(so caches invalidate automatically).

## App version support window

- `shopProfile.minSupportedAppVersion` is the floor. Any client
  below this floor is **blocked from writes** and shown a
  forced-upgrade screen.
- `shopProfile.recommendedAppVersion` is the soft target. Any
  client below this is shown a non-blocking `Update available`
  banner.
- The floor moves only by owner action via Admin.
- The floor is **never** moved by an automated process. A bad
  default would brick the shop.
- Default policy: keep the floor at most **two minor versions
  behind** the recommended.

### Force-upgrade rules

- Forced upgrade applies only when an event schema or security
  rule changes in a way that older clients cannot honour
  safely. Examples: new mandatory field, stricter validation,
  changed idempotency-key shape.
- A forced upgrade is announced by raising
  `shopProfile.minSupportedAppVersion`.
- During a forced upgrade, the old client:
  - **Cannot** append events.
  - **Can** continue to read cached projections so the staff
    sees the bill they were working on.
  - **Shows** a blocking banner: `Update required — version X.Y.
    Contact owner.`
- The forced-upgrade screen never times out; it never offers a
  "continue anyway" path.
- The new version is distributed via APK update or PWA SW
  activation; the device confirms the upgrade by reporting a
  new `appVersion`.

## Event schema versioning

- Every event envelope carries `schemaVersion: number`.
- **Additive changes** (new optional field): no version bump.
  Old code ignores the field; new code uses it.
- **Non-additive changes** (rename, type change, new required
  field, semantics change): version bump.
- A version bump requires:
  1. A new validator for the new version.
  2. A documented migration `migrateV<N-1>ToV<N>(payload)` that
     up-converts in-flight payloads.
  3. An update to the event's row in
     [`event-schemas.md`](./event-schemas.md) listing both
     versions and the migration.
  4. A scenario fixture that exercises an old-version event
     being accepted post-migration.
- The server keeps **all** historical schema validators for
  read-side replay. They are never deleted.
- Migrations are pure functions on the payload. They cannot
  fetch from the database, call services, or change the
  envelope's `idempotencyKey`.

### Old client writes after a schema change

- If the old client is **at or above** the support floor:
  server up-migrates the payload on accept; idempotency key is
  preserved; event is recorded at the new `schemaVersion`.
- If the old client is **below** the support floor: write is
  rejected with `UNAUTHORIZED` and the client is force-
  upgraded.

### Server-side replay and projection rebuild

- Projection rebuilds always re-validate events through the
  schema-version chain.
- A `schemaVersion` that is unknown to the running server
  (e.g. a downgrade) **fails the rebuild** with a clear error
  rather than silently skipping events.

## Domain version

- `domainVersion` is the version of the shared package that
  hosts every `apply()` and every invariant.
- It is embedded in every cache key
  (`shopId / projectionName / domainVersion / params`) so a
  domain bump invalidates the relevant caches across all
  devices automatically.
- Domain bumps require a CI proof that the new `apply()`
  produces the same projection state as the old one on the
  scenario corpus, or an explicit migration note in
  [`projections.md`](./projections.md) explaining the
  intentional change.

## Cache and storage versioning

- IndexedDB stores have schema numbers; on app start a
  migration runs from the stored version to the current
  version.
- A failed cache migration treats the store as poisoned and
  rebuilds from the server (per
  [`failure-modes.md`](./failure-modes.md) §F9).
- Outbox is in its own store with its own schema number, so
  cache poisoning never deletes pending writes.

## Backend compatibility

- Firestore rules are versioned by deployment; the active rule
  set is the source of truth at write time. A client cannot
  pin to an old rule version.
- Cloud Functions / server endpoints are versioned by route
  (`/v1/...`). A breaking endpoint change introduces `/v2/...`
  and the old route remains until the floor passes the
  matching `appVersion`.

## Release cadence and gating

The opinionated release process (cadence, change windows,
rollback drill) lives in
[`../../plan/rebuild/operations-runbook.md`](../../plan/rebuild/operations-runbook.md)
§Release process. This file defines only the contracts the
release must respect:

- Every release published with a `released-at`, `appVersion`,
  and `notes` event recorded in the audit log.
- Every release tagged in source control.
- Every release passes the full CI contract
  ([`ci-contract.md`](./ci-contract.md)) before publish.
- Every release with a `schemaVersion` bump is dual-run
  against a staging Firestore project before publish.
- A release rolling back the schema is **forbidden** — a
  schema bump is one-way; data fixes for a bad schema are
  done by new compensating events, not by reverting the
  schema.

## Blocking outdated APK / PWA

- PWA: app boot calls `/version-check`. If below floor, app
  swaps to the forced-upgrade screen before any UI loads.
- APK: same `/version-check` on launch; the screen instructs
  the user to install the new APK from the configured store /
  link. The APK signing cert is pinned.

## Required tests

- `old-client-additive-field-ignored` — old client receives an
  event with a new optional field; ignores it; folds OK.
- `old-client-non-additive-blocked` — old client below floor
  is forced upgrade; no write accepted.
- `schema-migration-up-converts` — server accepts old-version
  payload, persists at new version.
- `unknown-schema-version-rebuild-fails` — projection rebuild
  refuses to run with unknown `schemaVersion`.
- `domain-version-invalidates-cache` — bumping
  `domainVersion` causes all dependent caches to refetch.
- `cache-schema-migration` — IndexedDB store migrates from
  version N to N+1 without losing outbox.
- `forced-upgrade-blocks-writes-allows-reads` — old client
  pinned below floor sees cached data but cannot write.

## Open items

- `TODO(spec)` — exact distribution channel for the APK in
  v2.0 (Play Store internal track? direct APK?). Default for
  the family shop: direct APK with version pinning.
- `TODO(spec)` — auto-upgrade window for non-forced upgrades.
  Default: PWA SW activates on next reload; APK silently
  downloads, user-approved install.
- `TODO(spec)` — server-side schema validator retention policy.
  Default: keep forever (cheap; needed for any historical
  replay).

## Recent changes

- _2026-06-15_ · file created. Three independent versions
  (`appVersion`, `schemaVersion`, `domainVersion`); support
  window with force-upgrade rules; additive vs non-additive
  event-schema changes with up-migration contract; cache
  poisoning vs outbox separation; release cadence cross-link
  to operations runbook; required tests.
