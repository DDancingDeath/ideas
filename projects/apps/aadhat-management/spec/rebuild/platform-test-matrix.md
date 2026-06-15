# Platform test matrix — rebuild

> Which physical surfaces (browser, device, printer) must pass
> which tests, and which gate which release. Complements
> [`ci-contract.md`](./ci-contract.md) — that doc lists the 12
> logical CI jobs the repo runs on every PR; this doc lists the
> **physical platforms** those jobs (plus some manual gates)
> run against, and the release-time rule for what must be green
> where.

## Why this doc exists

A test suite that passes on the developer's laptop and fails
on the shop's staff phone is worse than no suite. The release
gate is "passes on the surfaces the shop actually uses", not
"passes somewhere".

The principle:

> The implementing agent (and the human releasing) must be able
> to read one table to know which platforms were exercised and
> which were not. Anything not in this table is implicitly
> untested on that platform — and a release that assumes
> untested-equals-working is forbidden.

## Surfaces

| ID | Surface | Where it runs |
|---|---|---|
| `P1` | Chromium desktop (headless) | CI runners (Linux) |
| `P2` | Chromium desktop (headed) | CI runners (Linux), Playwright real-browser |
| `P3` | Android Capacitor on emulator | CI runners with Android SDK |
| `P4` | Android Capacitor on **real reference device** | Manual / nightly self-hosted runner |
| `P5` | Android Capacitor on real reference device + real production printer | Manual; release-gate |
| `P6` | iOS Safari (mobile WebKit) | Manual; v2.1 stretch |
| `P7` | iOS Capacitor on real device | Manual; v2.1 stretch only |
| `P8` | Low-end Android profile | CI runners with throttled emulator |

The "reference device" is whichever Android phone in the
₹15–20k band the shop runs in production (per
[`../../plan/rebuild/decisions.md`](../../plan/rebuild/decisions.md)
row 6). The "production printer" is whichever ESC/POS printer
the shop runs (tracked in
[`printer-compatibility.md`](./printer-compatibility.md)).

## Test families × surfaces matrix

Each CI job from [`ci-contract.md`](./ci-contract.md) maps to
one or more surfaces. ✅ = runs and must be green; 🟡 = runs
but non-blocking; ❌ = does not run on that surface (and the
release gate does not depend on it).

| CI job | P1 Chromium headless | P2 Chromium headed | P3 Android emulator | P4 Android real device | P5 Android + printer | P6 iOS Safari | P7 iOS Capacitor | P8 Low-end Android |
|---|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
| `lint`, `typecheck` | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| `unit`, `scenario`, `invariant`, `security`, `integration`, `rules`, `docs` | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| `playwright` | ✅ | ✅ | 🟡 | ❌ | ❌ | ❌ | ❌ | 🟡 |
| `visual` | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| `perf` | ❌ | ✅ | 🟡 | ❌ | ❌ | ❌ | ❌ | ✅ |

The pure-logic jobs (`unit` through `rules`) run **once** on
P1 — they are platform-agnostic by design (the domain has no
DOM, no Bluetooth, no IndexedDB). The platform-sensitive jobs
(`playwright`, `visual`, `perf`) fan out as the table shows.

## Manual / smoke gates per release

Beyond the CI table, a release must pass these **manual**
gates before promotion to production. Each is owned, logged,
and stored against the release artefact.

| Gate ID | What | Surface | Owner | Cadence |
|---|---|---|---|---|
| `G-PRINT-PROD` | Real-device printer smoke from [`printer-compatibility.md`](./printer-compatibility.md) §Required tests `production-printer-smoke` | P5 | release engineer (owner) | Every release |
| `G-OFFLINE-RECON` | Create 5 bills offline, reconnect, verify exactly 5 server bills, no duplicates, projections match | P4 + P5 | release engineer | Every release |
| `G-CASH-CYCLE` | Open session → ring 3 sales → settle 1 outstanding → close with matching count | P5 | release engineer | Every release |
| `G-COLD-START` | Cold-start ≤ 2.5 s (per [`performance-budgets.md`](./performance-budgets.md)) on P4 reference device | P4 | release engineer | Every release |
| `G-FORCE-UPGRADE` | Old client (one minor behind) is blocked per [`versioning-compatibility.md`](./versioning-compatibility.md) | P4 | release engineer | Every release |
| `G-PWA-OWNER` | Owner views Today / Reports / Review Queue in PWA on desktop Chromium; numbers match P5 | P2 | release engineer | Every release |
| `G-PWA-SAFARI` | Same as above on iOS Safari (read-only views) | P6 | release engineer | v2.1+ |

A release that lands in production without a green entry for
every required gate above is a Sev-1 process defect — recorded
in [`../../plan/rebuild/operations-runbook.md`](../../plan/rebuild/operations-runbook.md)
and surfaced to the brother + owner.

## Per-platform constraints

| Surface | Constraint on test pass |
|---|---|
| P1 Chromium headless | Wall-clock-based timing assertions allow ±20 % jitter; flaky tests are quarantined per CI contract |
| P2 Chromium headed | Visual snapshots taken at 360 × 800 (mobile viewport) and 1280 × 800 (desktop) |
| P3 Android emulator | API 33+, default Pixel 4 emulator profile, no GPU; perf assertions are 🟡 (non-blocking) |
| P4 Android real device | Reference phone + reference Android version (currently 14); recorded in release notes |
| P5 Android real device + printer | Reference phone + reference printer; printout photographed and attached to release record |
| P6 iOS Safari | Latest iOS Safari at release date; read-only flows only in v2.0 |
| P7 iOS Capacitor | Latest iOS at release date; v2.1+ only; printer not exercised here, see [§iOS posture](./platform-compatibility.md#ios-posture) |
| P8 Low-end Android | API 28, CPU-throttled to 4× slowdown, 2 GB RAM emulator profile; `perf` job here is the lower-end baseline (non-blocking per `ci-contract.md` N3) |

## Release gate matrix

The minimum-bar combinations:

| Gate | v2.0 hot-fix patch | v2.0 minor | v2.0 → v2.1 schema bump | v2.1 (first iOS-included) |
|---|:-:|:-:|:-:|:-:|
| All CI jobs green on P1 / P2 | required | required | required | required |
| `playwright` green on P3 (emulator) | required | required | required | required |
| `perf` green on P2 + P8 | required | required | required | required |
| `G-PRINT-PROD` (P5) | required if printer code path touched | required | required | required |
| `G-OFFLINE-RECON` (P4 + P5) | required if outbox / sync path touched | required | required | required |
| `G-CASH-CYCLE` (P5) | required if money / cash path touched | required | required | required |
| `G-COLD-START` (P4) | optional | required | required | required |
| `G-FORCE-UPGRADE` (P4) | required | required | required | required |
| `G-PWA-OWNER` (P2) | optional | required | required | required |
| Migration / cutover checks per [`../../plan/rebuild/migration-cutover.md`](../../plan/rebuild/migration-cutover.md) | n/a | n/a | required | required |
| `G-PWA-SAFARI` (P6) | n/a | n/a | n/a | required |
| iOS Capacitor smoke (P7) | n/a | n/a | n/a | required + printer gate per [`printer-compatibility.md`](./printer-compatibility.md) |

"required if X touched" means the diff surface check decides:
if a file under `apps/web/src/print/**`, `packages/domain/print/**`,
or the printer driver is modified, the printer gate is required;
otherwise the previous release's green can be re-used.

## What is explicitly not tested per platform

To prevent silent assumption drift:

- **Web Bluetooth on P1 / P2** — the PWA does not attempt to
  print directly (per
  [`platform-compatibility.md`](./platform-compatibility.md)).
  No Web Bluetooth test exists; PWA print buttons route to a
  paired Android device.
- **Real BT pairing on P3** — emulators do not run Bluetooth.
  The print path on P3 uses the mock printer.
- **APNs delivery on P7** — push delivery on iOS is the carrier
  and Apple's responsibility; the gate verifies that the
  registration path runs, not that a push lands.
- **Print on P6 / P7** — see [`printer-compatibility.md`](./printer-compatibility.md)
  §iOS path for the v2.1 work needed before iOS print is
  exercised.

## Recording test runs against releases

Per release, the artefact carries a small JSON manifest:

```jsonc
{
  "release": "2.0.3",
  "schemaVersion": 1,
  "domainVersion": 1,
  "ci": { "P1": "green", "P2": "green", "P3": "green", "P8": "green" },
  "manualGates": {
    "G-PRINT-PROD":   { "device": "Redmi Note 13", "printer": "Generic 80mm BT", "by": "@hik", "at": "2026-06-16T11:42:00+05:30" },
    "G-OFFLINE-RECON":{ "by": "@hik", "at": "2026-06-16T11:55:00+05:30" },
    "G-CASH-CYCLE":   { "by": "@hik", "at": "2026-06-16T12:10:00+05:30" },
    "G-FORCE-UPGRADE":{ "by": "@hik", "at": "2026-06-16T12:14:00+05:30" },
    "G-COLD-START":   { "device": "Redmi Note 13", "ms": 2180, "by": "@hik", "at": "2026-06-16T12:18:00+05:30" }
  }
}
```

The manifest is checked into the release branch and referenced
in the brother's release-notes summary.

## Open items

- `TODO(spec)` — exact reference device model + Android
  version. Default: filled when the shop's staff phone is
  procured.
- `TODO(spec)` — whether `G-COLD-START` should be promoted to
  required for hot-fix patches. Default: optional (a single-
  file fix should not require a cold-start re-measurement).
- `TODO(spec)` — should the manifest also pin the printer
  firmware version? Default: yes once a printer model is
  selected; not before.

## Recent changes

- _2026-06-16_ · file created. Eight physical surfaces
  (P1–P8); job-family × surface matrix; manual smoke gates
  G-PRINT-PROD / G-OFFLINE-RECON / G-CASH-CYCLE /
  G-COLD-START / G-FORCE-UPGRADE / G-PWA-OWNER /
  G-PWA-SAFARI; per-platform constraints; release-gate
  matrix by release type; release-record JSON manifest
  shape; explicit "not tested" list.
