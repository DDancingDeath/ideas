# Platform compatibility — rebuild

> Per-platform capability contract for **Web/PWA**, **Android
> (Capacitor)**, and **iOS (Capacitor, stretch target)**. This
> file defines what each platform can and cannot do, what must
> be verified before shipping there, and how feature degradation
> is allowed to surface to the user.

## Why this doc exists

The rest of the spec assumes "the app". The shop's reality is
that the staff phone may be Android today and become iOS
tomorrow, the owner may also use a desktop browser, and the
brother may glance at it from a tablet. **Bluetooth thermal
printing in particular behaves very differently on Android vs
iOS**, and iOS-Safari adds PWA constraints that affect offline
behaviour. This doc makes those differences explicit before the
architecture hardens around assumptions that only hold on
Android.

The principle:

> Same domain code on every platform. Different shells. Every
> capability that varies is declared here, tested in
> [`platform-test-matrix.md`](./platform-test-matrix.md), and
> degraded with a visible, named status — never with a silent
> "it just doesn't work here".

## Target platforms

| Platform | Shell | v2.0 status | Notes |
|---|---|---|---|
| Web / PWA | SvelteKit + service worker | ✅ Supported | Primary owner / brother surface; secondary staff surface |
| Android | Capacitor wrapping the PWA | ✅ Supported | Primary staff surface; printer-bearing device |
| iOS | Capacitor wrapping the PWA | 🟡 **Stretch (v2.1)** | See [§iOS posture](#ios-posture) below |
| Desktop (Windows / macOS native) | — | ❌ Out of scope | Use the web build in a browser |
| Smart TV / kiosk | — | ❌ Out of scope | |

The default decision for v2.0 — recorded in
[`../../plan/rebuild/decisions.md`](../../plan/rebuild/decisions.md)
D6 (new row) — is **iOS deferred to v2.1**. Reversing that
requires a `superseded` entry in the decisions log plus a
real-device printer verification (see [§iOS posture](#ios-posture)).

## Capability matrix

A capability is either **Supported** (works as designed),
**Degraded** (works with a documented constraint surfaced to
the user), or **Not available** (refused; the user sees a clear
message and is steered to a supported device).

| Capability | Web / PWA | Android (Capacitor) | iOS (Capacitor) |
|---|:---:|:---:|:---:|
| Billing (retail + wholesale) | ✅ | ✅ | ✅ |
| Cash sessions | ✅ | ✅ | ✅ |
| Outstanding (settlement / record) | ✅ | ✅ | ✅ |
| Reports | ✅ | ✅ | ✅ |
| Audit log read | ✅ | ✅ | ✅ |
| Review Queue | ✅ | ✅ | ✅ |
| Local event cache + outbox | ✅ (IndexedDB) | ✅ (IndexedDB via WebView) | ✅ (IndexedDB via WKWebView) |
| Offline write queue persistence | ✅ | ✅ | 🟡 — WebKit may evict IndexedDB after 7 days of inactivity; see [§iOS posture](#ios-posture) |
| Bluetooth thermal printing (ESC/POS) | 🟡 — Web Bluetooth in Chromium only; not Safari, not Firefox | ✅ — primary path | ❌ **Refused in v2.0**; see [§iOS posture](#ios-posture) |
| Voice billing (speech-to-text) | 🟡 — Web Speech API, Chrome / Edge only, English-leaning | ✅ — native recognizer (Hindi + English) | 🟡 — `SFSpeechRecognizer`, requires explicit permission per session, limited offline |
| Push notifications | 🟡 — Web Push, needs HTTPS + user opt-in | ✅ — FCM | 🟡 — APNs, requires Apple Developer account; limited background delivery |
| File export (CSV / JSON / PDF) | ✅ — browser download | ✅ — Capacitor Filesystem | ✅ — Capacitor Filesystem |
| Camera / barcode (post-v2.0) | 🟡 — `getUserMedia`, limited on iOS Safari | ✅ | ✅ |
| Background sync (after app close) | 🟡 — Background Sync API, Chromium only | 🟡 — see [§Background behaviour](#background-behaviour) | ❌ — WebKit + iOS background restrictions |
| Forced upgrade (block stale clients) | ✅ — service worker + version check | ✅ — version check + Play Store deep link | ✅ — version check + App Store deep link |
| WhatsApp share (draft outgoing message) | ✅ — `wa.me` URL | ✅ — `wa.me` URL or share intent | ✅ — `wa.me` URL or share sheet |

✅ Supported. 🟡 Degraded — must surface a named status to the
user (badge, banner, or button-disabled with reason). ❌ Refused
— the feature is not available; the user is told why and where
to use it instead.

A row's status is enforced by **both** UI (steers the user) and
the storage adapter / domain (rejects writes that would
require an unavailable capability). The adapter is the truth.

## iOS posture

iOS is the platform most likely to silently break the printing
contract in [`print-queue.md`](./print-queue.md) and
[`printer-compatibility.md`](./printer-compatibility.md). The
risks are concrete:

1. **Bluetooth Classic SPP** (the common ESC/POS profile most
   cheap Indian thermal printers expose) is not accessible on
   iOS through standard apps. iOS only allows BLE GATT or
   MFi-certified Classic devices. Most ₹2–4k thermal printers
   used in shops are not MFi-certified.
2. **Background BLE** is restricted; the print worker may be
   suspended while the staff hands the bill to a customer.
3. **WebKit IndexedDB eviction** after 7 days of inactivity can
   silently lose an outbox.
4. **Service-worker constraints** in iOS Safari limit Background
   Sync API; the v2.0 outbox is foreground-only on iOS.

Therefore for v2.0:

- iOS is **not a shipping target**.
- The codebase stays platform-neutral so an iOS Capacitor build
  can be produced for testing, but no release artefact is
  promoted from it.
- A v2.1 iOS gate is defined: ship iOS only after
  - the chosen production printer model is verified to print
    end-to-end on a real iOS device, **or**
  - the print path is reworked to support cloud / Wi-Fi
    printing (a separate spec item), **and**
  - WebKit IndexedDB eviction is mitigated (e.g. periodic
    foreground "keepalive" writes or App Group native storage).

A `flag_raised(rule: 'platform-unsupported', severity: 'high')`
is written if any staff or owner action is attempted on iOS
that requires a ❌ capability. The Review Queue surfaces it so
the brother sees it.

## Background behaviour

Mobile OSes aggressively suspend apps to save battery. The
shop's expectation is "I'll glance at this in 30 minutes and it
will still work". The contract:

- **Foreground** — full functionality.
- **Backgrounded** (recent apps list) — outbox may drain while
  the OS allows it; print worker may complete an in-flight job
  but does not start a new one.
- **Suspended / killed** — no work happens. On next foreground,
  the app re-hydrates the outbox and print queue from local
  storage. Idempotency keeps everything safe.
- **Battery-saver mode on Android** — surface a banner: "Battery
  saver may delay sync. Open the app to drain." The app does
  not silently fail.

The forbidden behaviour: a print job that the UI thinks is in
progress but the worker dropped because the OS suspended the
app and no one notices.

## Storage limits

| Platform | IndexedDB practical limit | Outbox eviction risk |
|---|---|---|
| Web / PWA (Chromium) | Per-origin quota, typically 60% of disk | Low — quota-pressure eviction only |
| Web / PWA (Safari) | 1 GB per origin, evicts after 7 days idle | High — see iOS posture |
| Android (Capacitor) | Per-WebView quota, typically several hundred MB | Low |
| iOS (Capacitor) | WKWebView IndexedDB, same 7-day eviction | High |

The outbox-retention policy in
[`offline-sync.md`](./offline-sync.md) caps local age at 30
days; on iOS we shorten the visible warning banner threshold to
**5 days** to give the user a chance to reconnect before the OS
evicts.

## Forced-upgrade interaction

Version enforcement defined in
[`versioning-compatibility.md`](./versioning-compatibility.md)
runs on every platform, but the deep-link target differs:

| Platform | Deep-link target |
|---|---|
| Web / PWA | Cache-bust + service-worker `skipWaiting()` |
| Android | Play Store listing or APK update URL (per
[`../../plan/rebuild/operations-runbook.md`](../../plan/rebuild/operations-runbook.md))
|
| iOS | App Store listing |

## Required tests

Tracked in
[`platform-test-matrix.md`](./platform-test-matrix.md). The
gate before any release:

- Chromium desktop PWA smoke (Playwright).
- Android Capacitor build install + cold-start + create bill +
  print + sync.
- Android real-device printer smoke with the production
  printer model.
- Offline-then-reconnect on Android.
- (When iOS is in scope) all of the above plus the iOS-specific
  WebKit IndexedDB eviction test.

## Open items

- `TODO(spec)` — choose the Web Bluetooth fallback for the PWA
  build. Default v2.0: PWA users print to a paired Android
  device instead; the PWA does not attempt Bluetooth.
- `TODO(spec)` — define the "Wi-Fi printer" path that would
  unblock iOS. Tracked as a v2.1 research item; do not block
  v2.0 architecture on it.
- `TODO(spec)` — desktop signed PWA install vs browser tab.
  Default: browser tab only; no installer.
- `TODO(spec)` — fixed list of validated production Android
  models for the staff phone. Default: any current Android 12+
  device in the ₹15–20k band per
  [`../../plan/rebuild/decisions.md`](../../plan/rebuild/decisions.md)
  row 6.

## Recent changes

- _2026-06-16_ · file created. Per-platform capability matrix
  (Web/PWA / Android / iOS); iOS deferred to v2.1 with named
  gates (BLE Classic SPP, WebKit IndexedDB eviction, background
  BLE); foreground / background / suspended contract; storage
  limits per platform; forced-upgrade deep-link targets;
  required tests cross-linked to platform-test-matrix.
