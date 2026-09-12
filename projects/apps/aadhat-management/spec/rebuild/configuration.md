# Configuration registry

> **Single home for every tunable.** Behavioural documents reference a key by
> name; they never restate its value. If you need a threshold, add it here
> first. (Repo `AGENTS.md` → crispness contract, rules 1 and 3.)
>
> This registry is normative on its own authority. It does not track, cite, or
> defer to any implementation — an implementation conforms to these values, not
> the other way around.

## Conventions

- **Namespace:** `shopProfile.<domain>.<name>`, camelCase.
- **Unit suffix is mandatory and literal:** `Paise`, `Mg`, `Sec`, `Min`,
  `Hours`, `Days`, `Pct`. Weight is integer milligrams and money is integer
  paise everywhere ([`money-units-rounding.md`](./money-units-rounding.md);
  `decisions.md` rows 8 and M1).
- **Default column** is either a concrete value or `required — no default`.
  The latter means the app must refuse to start without it, and it links to
  the open question that will settle it. There is no third state — an inline
  `default: TODO(spec)` is a lint failure.
- **Editable by** is the *server-enforced* authority, not the UI.

## Registry

| Key | Type / unit | Default | Editable by | Used by |
| --- | --- | --- | --- | --- |
| `shopProfile.timezone` | IANA tz string | `Asia/Kolkata` | owner | [`time-clock.md`](./time-clock.md) |
| `shopProfile.locale.numerals` | enum `latin \| devanagari` | `latin` | owner | [`money-units-rounding.md`](./money-units-rounding.md), [`localization.md`](./localization.md) |
| `shopProfile.locale.timeFormat` | enum `12h \| 24h` | `24h` | owner | [`time-clock.md`](./time-clock.md) |
| `shopProfile.time.toleranceMin` | integer minutes | `5` | owner | [`time-clock.md`](./time-clock.md) — skew accepted silently below this |
| `shopProfile.time.clockSkewMaxMin` | integer minutes | `15` | owner | [`time-clock.md`](./time-clock.md), [`failure-modes.md`](./failure-modes.md), [`suspicion-engine.md`](./suspicion-engine.md) — above this raises `bill.client-clock-skew` |
| `shopProfile.time.maxFutureMin` | integer minutes | `60` | owner | [`time-clock.md`](./time-clock.md) — reject events claiming the future |
| `shopProfile.time.maxSyncDelayMin` | integer minutes | `1440` (24 h) | owner | [`time-clock.md`](./time-clock.md) |
| `shopProfile.time.backdateToleranceDays` | integer days | `1` (today + yesterday) | owner | [`invariants.md`](./invariants.md), [`time-clock.md`](./time-clock.md) |
| `shopProfile.cash.mismatchTolerance` | integer paise | `5000` (₹50) | owner | [`invariants.md`](./invariants.md) C2, [`suspicion-engine.md`](./suspicion-engine.md) |
| `shopProfile.cash.mismatchLarge` | integer paise | `50000` (₹500) — **unsettled**, see [open questions](#open-questions) | owner | [`suspicion-engine.md`](./suspicion-engine.md) |
| `shopProfile.cash.maxSessionHours` | integer hours | `14` | owner | [`suspicion-engine.md`](./suspicion-engine.md) |
| `shopProfile.stock.negativeBlockMg` | integer milligrams | `5_000_000` (5 kg) | owner | [`suspicion-engine.md`](./suspicion-engine.md) `stock.negative.large` |
| `shopProfile.stock.adjustmentLargeMg` | integer milligrams | `20_000_000` (20 kg) | owner | [`suspicion-engine.md`](./suspicion-engine.md), [`event-schemas.md`](./event-schemas.md) |
| `shopProfile.items.rateCeilingPaise` | integer paise | `1_000_000_000` (₹1,00,00,000) | owner | [`data-governance.md`](./data-governance.md) |
| `shopProfile.items.rateFloorPaise` | integer paise | `1` | owner | [`suspicion-engine.md`](./suspicion-engine.md) |
| `shopProfile.items.rateChangeMinIntervalSec` | integer seconds | `60` | owner | [`data-governance.md`](./data-governance.md) — `rate-flapping` |
| `shopProfile.pricing.maxDiscountPctByRole` | map `role → integer percent` | flat `1000` bps (10%) — **unsettled**, see [open questions](#open-questions) | owner | [`suspicion-engine.md`](./suspicion-engine.md) |
| `shopProfile.pricing.maxRateMultiple` | decimal multiplier | `5` | owner | [`suspicion-engine.md`](./suspicion-engine.md) |
| `shopProfile.bills.duplicateWindowSec` | integer seconds | `120` | owner | [`suspicion-engine.md`](./suspicion-engine.md) `bill.duplicate.window` |
| `shopProfile.billNumber.offlineBlock` | integer count | `50` | owner | [`concurrency.md`](./concurrency.md), [`offline-sync.md`](./offline-sync.md) |
| `shopProfile.outstanding.longOverdueDays` | integer days | `30` | owner | [`suspicion-engine.md`](./suspicion-engine.md) |
| `shopProfile.analytics.deadStockDays` | integer days | `30` | owner | [`analytics.md`](./analytics.md) |
| `shopProfile.staff.editGraceMin` | integer minutes | `5` | owner | [`role-permission-matrix.md`](./role-permission-matrix.md) |
| `shopProfile.auth.escalationWindowMin` | integer minutes | `10` | owner | [`role-permission-matrix.md`](./role-permission-matrix.md), [`suspicion-engine.md`](./suspicion-engine.md) |
| `shopProfile.roleConfig` | map `role → visibility flags` | all defaults from [`role-permission-matrix.md`](./role-permission-matrix.md) | owner | [`role-permission-matrix.md`](./role-permission-matrix.md) |
| `shopProfile.suspicion` | map `ruleId → { enabled, severity }` | every rule enabled at its documented severity | owner | [`suspicion-engine.md`](./suspicion-engine.md), [`review-queue.md`](./review-queue.md) |
| `shopProfile.printer.maxRetries` | integer **retries** after the first attempt | `3` (→ 4 attempts total) | owner | [`print-queue.md`](./print-queue.md), [`printer-compatibility.md`](./printer-compatibility.md) |
| `shopProfile.printer.attemptsBeforeFlag` | integer attempts | `3` | owner | [`suspicion-engine.md`](./suspicion-engine.md) `print.repeated-failures` |
| `shopProfile.printer.reprintsBeforeFlag` | integer count | `3` | owner | [`suspicion-engine.md`](./suspicion-engine.md) `print.many-reprints` |
| `shopProfile.printer.connectTimeoutSec` | integer seconds | `5` | owner | [`printer-compatibility.md`](./printer-compatibility.md) |
| `shopProfile.printer.sendTimeoutSec` | integer seconds | `10` | owner | [`printer-compatibility.md`](./printer-compatibility.md) |
| `shopProfile.printer.stuckBannerSec` | integer seconds | `60` | owner | [`printer-compatibility.md`](./printer-compatibility.md) — UI banner only, not a worker deadline |
| `shopProfile.printer.widthMm` | enum `58 \| 80` | `58` | owner | [`printer-compatibility.md`](./printer-compatibility.md) |
| `shopProfile.minSupportedAppVersion` | semver string | `required — no default` (set at first release) | server / release process | [`versioning-compatibility.md`](./versioning-compatibility.md), [`failure-modes.md`](./failure-modes.md) |
| `shopProfile.recommendedAppVersion` | semver string | `required — no default` (set at each release) | server / release process | [`versioning-compatibility.md`](./versioning-compatibility.md) |
| `shopProfile.firebaseProjectId` | string | `required — no default` | deployment | [`backup-restore.md`](../../plan/rebuild/backup-restore.md) |

### Not in `shopProfile`

Provider credentials are deployment environment variables, never shop data,
and never committed:

| Variable | Purpose |
| --- | --- |
| `CHATLLM_OPENAI_API_KEY` / `CHATLLM_GEMINI_API_KEY` / `CHATLLM_ANTHROPIC_API_KEY` | LLM fallback for the assistant ([`../chat-design.md`](../chat-design.md)). Only one is required, matching the chosen provider. |

## Superseded key names

Do not reintroduce these. They are listed only so an older document or branch
can be mapped forward.

| Old name | Replaced by | Why |
| --- | --- | --- |
| `shopProfile.backdateToleranceDays` | `shopProfile.time.backdateToleranceDays` | Namespaced under `time`. |
| `shopProfile.time.skewToleranceSec` | `shopProfile.time.clockSkewMaxMin` | Third name for clock skew, in a third unit. One concept, one key. |
| `shopProfile.stock.negativeBlockKg` | `shopProfile.stock.negativeBlockMg` | Weight is integer milligrams (`decisions.md` row 8). |
| `shopProfile.stock.adjustmentLargeKg` | `shopProfile.stock.adjustmentLargeMg` | Same. |

## Open questions

- `TODO(spec, blocks: M8)` — **`shopProfile.cash.mismatchLarge`.** What
  end-of-day cash gap is large enough to escalate beyond the ordinary
  `mismatchTolerance` flag? `plan/rebuild/decisions.md` M8 records ₹200;
  day-to-day experience at the shop points to ₹500, since ₹200 gaps occur often
  enough to be noise. **Default:** `50000` (₹500), superseding the M8 row. The
  ₹50 tolerance is not in dispute.
- `TODO(spec, blocks: M5)` — **`shopProfile.pricing.maxDiscountPctByRole`.**
  Should the discount cap vary by role, or be a single flat limit?
  **Default:** a single flat cap of `1000` bps (10%) for v2.0, dropping the
  per-role map from [`suspicion-engine.md`](./suspicion-engine.md) — the shop
  has one staff role in practice. Revisit when `manager` is actually surfaced.
