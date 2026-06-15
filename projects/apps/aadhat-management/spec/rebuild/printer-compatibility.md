# Printer compatibility — rebuild

> Which printers the v2.0 app supports, what command set and
> paper widths they must speak, how Devanagari (Hindi) is
> rendered, how Android Bluetooth pairing works, why iOS is
> refused in v2.0, and the duplicate-prevention contract that
> sits above the queue. The print queue mechanics — jobs,
> states, dedup keys, worker — live in
> [`print-queue.md`](./print-queue.md). This file is about the
> **device on the other end of the cable**.

## Why this doc exists

Printing is where "same bill twice" bugs sneak in and where
"works on the dev laptop, fails in the shop" surprises happen.
The print queue spec makes the software side safe; this spec
makes the hardware side explicit so a release is never gated on
"hope it works with whatever printer the shop bought".

The principle:

> Treat the printer as an external system with its own
> protocol, paper, charset, and failure modes. Validate the
> exact model on real hardware before shipping. Never let a
> printer failure create a bill, and never let a successful
> bill silently fail to print.

## Supported printers (v2.0)

The release-gate list. A printer model is **supported** only
after it passes the printer smoke test on a real device against
the production Android build.

| Model class | Paper width | Connection | Devanagari | Status |
|---|---|---|---|---|
| Generic 58 mm ESC/POS Bluetooth Classic SPP | 58 mm | BT Classic SPP | Bitmap (see [§Devanagari](#devanagari-strategy)) | ✅ Reference profile |
| Generic 80 mm ESC/POS Bluetooth Classic SPP | 80 mm | BT Classic SPP | Bitmap | ✅ Reference profile |
| Generic 80 mm ESC/POS USB (via OTG) | 80 mm | USB OTG | Bitmap | 🟡 Best-effort; not in release gate |
| Wi-Fi ESC/POS network printer | 58 / 80 mm | TCP:9100 | Bitmap | 🟡 Best-effort; tracked for v2.1 (unblocks iOS) |
| BLE-only "mini receipt" printers | 58 mm | BLE GATT custom profile | Native font (printer-side) | ❌ Refused — most have proprietary protocols that break ESC/POS guarantees |
| MFi-certified iOS Classic printers | — | — | — | 🟡 Tracked for v2.1 iOS work |

The exact production model(s) the family shop runs are listed
in
[`../../plan/rebuild/operations-runbook.md`](../../plan/rebuild/operations-runbook.md)
§Printer not working (`TODO`: fill in once procured). Until
that list is non-empty, the release gate refers to the 58 mm
and 80 mm reference profiles above.

## Paper widths

- The bill renderer produces a **width-agnostic logical layout**
  and rasterises to either 58 mm (384 dot) or 80 mm (576 dot)
  at print time.
- The chosen width per printer is part of `shopProfile.printer`
  and is sticky per device.
- Switching width mid-day is allowed (e.g. moving to a backup
  printer) and produces a one-line `Printer changed: 58 mm → 80
  mm` row in the device diagnostics view.

## ESC/POS command subset

The renderer uses a deliberately small, well-tested ESC/POS
subset so an unknown printer is more likely to "just work".

| Purpose | Bytes | Notes |
|---|---|---|
| Initialise | `ESC @` | Sent at start of every job |
| Codepage select (Latin) | `ESC t n` | For non-Devanagari text |
| Bold on / off | `ESC E 1` / `ESC E 0` | Used for totals only |
| Double-height on / off | `GS ! n` | Used for grand total only |
| Align (left / centre / right) | `ESC a n` | |
| Print bitmap | `GS v 0` | The only path for Devanagari (see below) |
| Feed n lines | `ESC d n` | |
| Cut (full / partial) | `GS V n` | Skipped if the printer reports no cutter |
| Drawer kick | not used | The app does not control cash drawers in v2.0 |

Commands outside this list are forbidden in the renderer. A new
command requires:

1. A reason recorded in `## Recent changes`.
2. A printer-mock test asserting the bytes.
3. A real-device smoke confirming the printer accepts it.

## Devanagari strategy

ESC/POS printers vary wildly in their handling of non-Latin
scripts. The contract:

> Devanagari is **always** printed as a bitmap. Native font
> support is treated as a bonus, not a guarantee.

The renderer:

1. Lays out the bill in a logical model (rows of text + price).
2. For each row, decides per-substring whether characters are
   pure Latin / digits / common ASCII punctuation (font path)
   or include any non-ASCII (bitmap path).
3. The bitmap path rasterises the substring using a bundled
   Devanagari font at the printer's native DPI (typically 203
   dpi), then emits `GS v 0`.
4. If the printer reports it cannot accept bitmaps (rare), the
   renderer **refuses** and surfaces a `Printer cannot print
   Hindi — replace printer` error rather than printing garbled
   text.

The bundled font, its licence, and the rasteriser version are
recorded in the build manifest so a print's exact appearance is
reproducible.

## Android Bluetooth path

Per
[`platform-compatibility.md`](./platform-compatibility.md), the
Android Capacitor build is the primary printing path.

1. **Pairing** is done once in Android Settings, not in the
   app. The app discovers paired devices and lets the owner
   pick the printer.
2. **Connection** uses Bluetooth Classic SPP (UUID
   `00001101-0000-1000-8000-00805F9B34FB`).
3. **Permissions** required at install / first run:
   `BLUETOOTH_CONNECT`, `BLUETOOTH_SCAN`. The app must explain
   why before requesting; denial parks all print jobs and
   surfaces a `Bluetooth permission needed` banner.
4. **Foreground service** keeps the print worker alive during
   active hours; without it, Android may suspend BLE while the
   staff hands the bill to the customer. The service is
   labelled "Aadhat Printer" so the user understands what the
   persistent notification is.
5. **Battery optimisation** for the app must be disabled
   (whitelisted) on the staff phone. The operations runbook
   walks the owner through the OEM-specific path.

## iOS path (v2.1+)

Out of scope for v2.0. The reasoning lives in
[`platform-compatibility.md`](./platform-compatibility.md)
§iOS posture. The v2.1 iOS gate requires either an
MFi-certified printer or a Wi-Fi printer path; both are
research items, not commitments.

## Web / PWA path

For owner / brother glance views the app runs in a desktop
browser. The PWA does **not** attempt to print directly:

- Print buttons in the PWA build either:
  - hand off to a paired Android device that prints the bill,
    or
  - call the browser's `window.print()` to produce an A4 / A5
    PDF for ad-hoc records (not a thermal receipt).
- The thermal-printer status badges still appear so the owner
  sees what the staff phone is doing.

## Print timeouts

| Phase | Budget | What happens on timeout |
|---|---|---|
| Connect (BT Classic SPP) | 5 s | Counts as one failed attempt; job stays in queue |
| Send (full payload) | 10 s | One failed attempt |
| Cutter response | 2 s | Ignored; print is still treated as success |
| Total job (sum across attempts) | 60 s before "stuck" UI | Banner: `Printer not responding — open Diagnostics` |
| Retry budget | 5 transient attempts → `failed` per [`print-queue.md`](./print-queue.md) | `flag_raised(rule: 'print-exhausted')` |

Timeouts are tunable per-shop in `shopProfile.printer` but never
removable.

## Retry behaviour

Anchored to [`print-queue.md`](./print-queue.md) and
[`idempotency.md`](./idempotency.md):

- Every retry reuses the same `jobId` and `jobKey`. A new
  printout never appears because a retry succeeded; only the
  next attempt of the same job does.
- A "Retry" button never enqueues a new job for a job already
  in flight or already terminal-success.
- A reprint requested by the user creates a **new** job
  (`('reprint', billId, ordinal)`) — that is the only path to a
  second physical printout of the same bill.

## Duplicate-print prevention

The four layers that together make "same bill twice" effectively
impossible:

1. **Sale event** is idempotent on its `idempotencyKey`; double-
   tap on Save never creates two sales (see
   [`idempotency.md`](./idempotency.md)).
2. **First print** is keyed on `('first-print', billId)`; the
   queue rejects a duplicate enqueue under that key.
3. **Reprint** is keyed on `('reprint', billId, ordinal)`; the
   ordinal is allocated server-side (or device-local with a
   sortable client id) and never reused.
4. **ESC/POS** cannot itself dedupe — the printer happily prints
   what it receives. So duplicates must be prevented before the
   worker calls `send(bytes)`, which the queue contract
   enforces.

A printout is **considered duplicate-suspect** (not duplicate-
confirmed) only when the worker observes
"connect→send→timeout-on-ack". The job records the suspicion in
audit; the user is told "We're not sure if the last attempt
printed — check the printer before reprinting." A reprint is
still an explicit user action.

## Manual print fallback

Even after retries, the printer may simply be broken. The
manual path:

- Owner can mark a bill as **"printed manually"** from History.
  This appends a `print_manual_recorded` event (audit-only,
  does not modify the sale).
- This is the only path that says "yes, the customer got their
  bill" without the queue having seen success.
- Suspicion engine raises a low-severity flag if the manual-
  print rate exceeds a per-day threshold (default 5%).

## Required tests

Listed for the implementing agent; some are real-hardware
smokes that run only on the manual gate.

| Test | Layer | Notes |
|---|---|---|
| `escpos-bytes-snapshot` | Unit | Each row of the supported command table emits exactly the expected bytes |
| `bitmap-devanagari-render` | Unit | Rasteriser produces a stable hash for a fixed input (font version is part of the hash) |
| `paper-width-switch` | Unit | Logical layout rasterises at both 384 dot and 576 dot without losing rows |
| `bluetooth-connect-timeout` | Integration (mock printer) | 5 s budget enforced; attempt counted |
| `cutter-missing-ignored` | Integration | Cut command tolerated as no-op |
| `connect-permission-denied` | Integration | UI surfaces banner; queue parks |
| `manual-print-marker` | Scenario | `print_manual_recorded` event appears; no sale modified |
| `printer-cannot-bitmap-refused` | Integration | Refusal path tested; user sees actionable error |
| `production-printer-smoke` | **Manual gate** | Real device + real production printer; once per release; logged in operations runbook |

The production smoke is the gate. A release without a green
production smoke is forbidden — see
[`../../plan/rebuild/release-health-gates.md`](../../plan/rebuild/release-health-gates.md).

## Open items

- `TODO(spec)` — exact list of supported production printer
  models with firmware versions. Default: filled when the shop
  procures.
- `TODO(spec)` — bundled Devanagari font choice and licence.
  Default: a permissively-licensed Open Type font (e.g. Noto
  Sans Devanagari) rasterised at 203 dpi.
- `TODO(spec)` — Wi-Fi printer path for the iOS unblock.
  Default: v2.1 research.
- `TODO(spec)` — Drawer-kick support. Default: out of scope for
  v2.0; revisit only if the shop adopts a cash drawer.

## Recent changes

- _2026-06-16_ · file created. Supported printer table with 58
  mm / 80 mm reference profiles; ESC/POS command subset;
  Devanagari = always bitmap rule; Android BT Classic SPP
  pairing path with foreground service + battery whitelist; iOS
  refused in v2.0 with v2.1 gate; PWA does not print directly;
  print timeouts table; retry behaviour anchored to
  print-queue.md and idempotency.md; four-layer duplicate-print
  prevention; manual-print fallback with audit event; required
  tests including production smoke gate.
