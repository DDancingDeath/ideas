# Voice Billing — V2 Design

> **v1 scope.** This document records the shipped v1-era voice billing design. If it disagrees with `spec/rebuild/`, `spec/rebuild/` wins.
>
> **Status:** Draft for review. Original path: `docs/VOICE_BILLING_V2.md`. Builds on V1 commit `56e230f`; scope is strictly the billing page.

## 1. Goals

V1 supports one tap, one item, one weight, one rate. V2 makes billing usable on a shop floor.

### Must deliver

1. Hands-free verification: speak back "added 10 kilo aloo at 30 rupees".
2. Bills in one breath: "10 kilo aloo at 30, 5 kilo pyaaz at 25" creates two rows.
3. Whole bill by voice, including customer name.
4. Safety: confirmation mode and a full voice-off toggle.
5. Hindi vocabulary: numbers 1–99, Devanagari and Roman-Hindi.
6. Android readiness: `RECORD_AUDIO`; opt-in misrecognition telemetry.

### Must not deliver in v2.0

- No new tabs: no voice on chat, cash management, items, or expenses.
- No wake-word / always-listening mic; zero-touch activation is v2.1 (§9).
- No server-side STT; samples stay on device via `webkitSpeechRecognition`.
- No custom Hindi STT model; Chrome `hi-IN` plus item-list fuzzy match is enough.

## 2. Status quo — what V1 already does (commit `56e230f`)

| Capability | Behaviour |
|---|---|
| 🎤 Voice button | One per section (purchase, sale) below "Add to Bill" |
| Speech engine | `webkitSpeechRecognition`, `lang='hi-IN'`, non-continuous |
| Numbers understood | English/Devanagari digits + Hindi/English word numbers (0–10, plus 11, 12, 15, 20, 25, 30, 40, 50, 60, 70, 80, 90, 100, 1000) |
| Unit markers | `kg`, `kilo`, `किलो`, `rupees`, `rs`, `रुपये`, `ka`, `के`, `at`, `@` |
| Heuristic | First number = weight, second = rate (unless markers say otherwise) |
| Item match | Substring + token-prefix; longest match wins (`name` + `hindiName`) |
| Commit / clear | `add to bill` · `जोड़ दो` · `save` · `clear` · `मिटा दो` |
| Auto-action | Fills inputs, then auto-clicks `addWeight()` so the weight chip lands |
| Permission | `getUserMedia({audio:true})` primes RECORD_AUDIO on Capacitor Android |
| Tests | 28 jest cases (parser only — the SpeechRecognition wrapper is browser-only) |

### V1 gaps that motivate V2

| Gap | What goes wrong today | V2 item |
|---|---|---|
| One item per utterance | "10 aloo aur 5 pyaaz" picks one item, loses the other | A2 |
| No audio feedback | User must look at screen to know what got added | A1 |
| Single number = weight only | "20 rupees" can't update only the rate | A6 partial |
| Hindi 11–99 incomplete | "tinetalis" (43) doesn't parse; user must say "43" | A4 |
| No customer-name dictation | Customer field stays blank, must tap & type | A3 |
| No undo | Misrecognition → manually clear inputs | B8 |
| No off switch | Users who don't want voice still see the buttons | A5 |
| No Android manifest | Capacitor APK won't get mic permission in prod | C12 |

## 3. Architecture (no change from V1)

```text
user taps 🎤
  → VoiceBillingManager.start()        voice-billing.js singleton
  → webkitSpeechRecognition            lang = preferences.voiceLang (A5)
  → parseUtterance(text, items)        pure; returns Intent[] in A2
  → manager dispatches intents         fill inputs, addWeight/preview, TTS, customerName
```

Parser remains pure/testable in jsdom. Manager owns DOM and browser APIs.

## 4. V2 work plan

### Tier A — high-value, low-risk

#### A1. TTS readback (audio confirmation)

**What:** After each successful action, use `window.speechSynthesis`.

| Branch | Readback |
|---|---|
| Add | "added 10 kilo aloo at 30 rupees" / "दस किलो आलू तीस रुपये जोड़ा" |
| Commit | "bill saved" / "bill jod diya" |
| Clear | "cleared" / "साफ़ कर दिया" |
| Unknown | No TTS; toast only |

Rules: language follows STT preference; A5 TTS toggle defaults on; cancel in-flight TTS before new readback.

Implementation: add `speak(textHi, textEn)`; cache a `hi-IN` voice from `speechSynthesis.getVoices()`; call `speechSynthesis.cancel()` before `.speak()`; call from `_handleUtterance` success branches.

Test: mock `window.speechSynthesis`; assert `.cancel()` before `.speak()` and expected utterance per branch.

**Depends on:** A5.


#### A2. Multi-item utterance

**What:** Separators `and` / `aur` / `phir` / `और` / `,` / `;` produce multiple add intents. Example: "10 kilo aloo at 30 and 5 kilo pyaaz at 25" → two rows.

Implementation:

- Change `parseUtterance` return shape from single intent to single intent or array. Use array when separators are present. Internal type: `{ kind: 'add'|'commit'|'clear'|'unknown' | 'batch', items?: Intent[], ... }`.
- Add `splitOnSeparators(text)`.
- Manager loops segments: fill → `addWeight()` → next.
- Semantics: if segment 3 fails, segments 1+2 still land.

Test at least 10 cases:

- 2-item English with `and`.
- 2-item Hindi with `aur`.
- 2-item Hinglish with `phir`.
- 2-item Devanagari with `और`.
- Comma-separated, 3 items.
- Mixed: `"10 kg aloo 30, pyaaz 25"`.
- Trailing separator (`"…and"`) does not crash.
- Single-item utterance still returns a single intent.


#### A3. Customer-name dictation

**What:** Trigger word (`customer` / `ग्राहक` / `naam`) plus 1–3 tokens fills customer field. Suffix form: `<name> ke liye` / `<name> के लिए`.

Examples:

- "customer Ramesh Kumar, 10 kilo aloo at 30" → `customerName` = "Ramesh Kumar", then row added.
- "ग्राहक रमेश, दस किलो आलू" → same.
- "Ramesh ke liye 10 kilo aloo" / "रमेश के लिए दस किलो आलू" → same.

Capture stops at first number, separator, or unit word.

Implementation: `extractCustomerName(text)` runs before item-match and removes the matched span; add `CUSTOMER_PHRASE_LIST`; manager fills `customerName` for purchase or `saleCustomerName` for sale.

Test: ≥6 cases for English/Hindi triggers, `ke liye` / `के लिए`, multi-word names, name + item same utterance, name only, and no-trigger negative.


#### A4. Expanded Hindi number table (11–99)

**What:** Add every spoken Hindi number 1–99.

| Missing today (sample) | Add (Roman-Hindi) | Add (Devanagari) |
|---|---|---|
| 13 | terah | तेरह |
| 14 | chaudah | चौदह |
| 16 | solah | सोलह |
| 17 | satrah | सत्रह |
| 18 | atharah | अठारह |
| 19 | unnees | उन्नीस |
| 21 | ikkees | इक्कीस |
| 22 | baees | बाईस |
| 23 | teyees | तेईस |
| 24 | chaubees | चौबीस |
| 26 | chhabees | छब्बीस |
| 27 | sattaees | सत्ताईस |
| 28 | atthaees | अट्ठाईस |
| 29 | unnatees | उनतीस |
| 31–39 | ekatees…unchaalees | इकतीस…उनतालीस |
| 41–49 | ikatalees…unchaas | इकतालीस…उनचास |
| 51–59 | ikyaavan…unsath | इक्यावन…उनसठ |
| 61–69 | iksath…unhattar | इकसठ…उनहत्तर |
| 71–79 | ikahattar…unaasi | इकहत्तर…उन्नासी |
| 81–89 | ikyaasi…nibbe-ke-pehle | इक्यासी…नवासी |
| 91–99 | ikyaanve…ninyaanve | इक्यानवे…निन्यानवे |

Optional later: compound `tees-teen` → 33. Low priority; digits cover 95%.

Test: parametric; every new table entry makes `parseUtterance("X kilo aloo")` return `weight: <number>`.


#### A5. Settings toggle + language pick

**What:** Add Settings "Voice input" section (`14-settings.md`). Persist to `AppState.preferences` and Firestore `users/{uid}/preferences`.

| Setting | Type | Default | Effect when changed |
|---|---|---|---|
| Enable voice input | toggle | on | When off: hide both 🎤 buttons; `VoiceBillingManager.start()` becomes a no-op |
| STT language | radio: hi-IN / en-IN / en-US | hi-IN | Sets `rec.lang` on next listen session |
| TTS readback | toggle | on | When off: skip the `speak()` call (toast still appears) |
| Confirmation mode | radio: auto-add / preview | auto-add | Controls A6 behaviour |

Implementation: add `AppState.preferences.voice = { enabled, lang, tts, confirmMode }`; reuse `users/{uid}/preferences`; settings UI saves on change; `VoiceBillingManager.start()` rereads prefs each time.

Test: Settings save payload; Settings load UI; mic visibility toggles.


#### A6. Confirmation mode (preview-then-commit)

**What:** In A5 preview mode, voice fills inputs but does not auto-click `addWeight()`. User says `confirm` / `haan` / `OK` / `पक्का` to commit, speaks again to overwrite, or says `clear` to abandon.

Implementation: add `CONFIRM_PHRASE_LIST`; add `_stagedIntent`; while staged, `start()` accepts confirm / overwrite / clear only; on confirm run `addWeight()`. A1 TTS says: "staged: 10 kg aloo, 30 rupees. say confirm to add."

Test: idle → previewing → confirmed; idle → previewing → overwritten; idle → previewing → cleared.

**Depends on:** A5.


### Tier B — refinements

#### B7. Continuous "dictation mode"

**What:** Long-press mic or separate "Dictation" button keeps recognition open. Ends on `stop` / `रुको` / `khatam`, 30 s silence, or navigation away.

Implementation: set `rec.continuous = true`; explicit lifecycle; active state shows "DICTATING" pulsing red.


#### B8. Voice undo / revert last action

**What:** `undo` / `वापस` / `galat` removes the most recent voice add: last weight chip or committed row.

Implementation: undo stack length 5 with `{type: 'add'|'commit'|'clear', undo: () => void}`; expose `.undoLast()`.


#### B9. Edit row via voice

**What:** `row 2 rate 35` / `दूसरा रेट 35` updates a row rate.

Implementation: parser learns ordinals (`pehla`/`doosra`/`teesra`, `1st`/`2nd`/`3rd`); manager calls `editBillItem(idx)`, then updates field.


#### B10. Transcript log panel (toggleable)

**What:** Collapsible drawer shows last 3 utterances and parser output.

Implementation: ring buffer length 3; render in `<details>` next to status.


#### B11. Audio cue on listen start/stop

**What:** 100 ms tone for mic open/close.

Implementation: generate via `AudioContext`; use two pitches.


### Tier C — production readiness

#### C12. Android `RECORD_AUDIO` manifest entry

**What:** Capacitor APK needs:

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
```

**Where:** prod repo (`DDancingDeath/AadhatManagementApp`); this staging clone has no `android/`. Owner documents exact diff in V2 promotion PR.


#### C13. Misrecognition telemetry (privacy-respecting)

**What:** If user says `clear` / `undo` within 5 seconds of voice add, anonymously log `{transcript, parsed, action_taken: 'reverted'}` to `voiceMisses/` for parser tuning.

Privacy controls:

- Prod toggle "help improve voice recognition" is off by default.
- Staging default is opt-out.
- Never log customer names, item rates, or PII-shaped fields; transcript is the only free text and copy says it leaves the phone.

## 5. Build sequence

1. **A5** — Settings toggle scaffold.
2. **A1** — TTS readback.
3. **A2** — Multi-item utterance.
4. **A3** — Customer-name dictation.
5. **A4** — Hindi number expansion.
6. **A6** — Confirmation mode.
7. Tier B in any order.
8. **C12** — prod repo manifest entry.
9. **C13** — last, after Tier A settles.

## 6. Test strategy

| Layer | What | How |
|---|---|---|
| Parser | every new phrase pattern | ≥1 positive + 1 negative jest case |
| Manager dispatch | filling inputs, auto-add, undo stack | jsdom + stubbed `BillingManager` |
| TTS | readback strings, voice picking | mock `window.speechSynthesis`, assert `.speak()` |
| Settings | toggle persistence, lang switch | mock `FirebaseService`, assert payload shape |
| End-to-end | mic → form fill → bill saved | manual smoke on Chrome desktop + Android |

Targets:

- 50+ parser tests by end of Tier A (currently 28).
- 70+ parser tests by end of V2.
- All existing 539 tests green at every merge.

## 7. Open assumptions (override anytime)

1. **Tier A is the right cut.** Smallest V2 is A1 + A2 in one PR.
2. **Settings storage uses Firestore prefs.** LocalStorage alternative is one-line but prefs do not follow devices.
3. **Telemetry opt-in default in prod.** Flip to opt-out only if owner accepts samples leaving the phone by default.
4. **A4 covers only Hindi numbers up to 99.** Numbers >99 are handled as digits in real use.
5. **No voice for chat / cash / items / expenses.** Future asks only.

## 8. Files this PR set will touch

| File | What changes |
|---|---|
| `www/js/modules/voice-billing.js` | Parser → multi-intent, customer extraction, TTS calls, A4 number table, confirmation state machine |
| `www/js/__tests__/voice-billing.test.js` | +22 cases (multi-item, customer, Hindi 11–99, TTS mocks, confirm flow) |
| `www/js/modules/settings.js` | New "Voice input" section + save handlers |
| `www/templates/settings.html` | New section in the markup |
| `www/js/utils/state.js` | `AppState.preferences.voice` shape |
| `www/templates/billing.html` | Optional: B10 transcript drawer markup |
| `docs/page-specs/02-billing.md` | Expanded "Voice input" section for new grammar |
| `docs/page-specs/14-settings.md` | New "Voice input" subsection |
| `docs/VOICE_BILLING_V2.md` | This document (created in the planning PR) |

Production-repo files (owner action, not this clone):

| File | What changes |
|---|---|
| `android/app/src/main/AndroidManifest.xml` | Add `<uses-permission android:name="android.permission.RECORD_AUDIO" />` (C12) |

## 9. Future: zero-touch / hands-free activation (v2.1)

> **Status:** TODO(spec, blocks: M9) — Which zero-touch activation approach should ship in v2.1? **Default:** start with A (OS-assistant launch).

### The goal

Hands-free billing when the shopkeeper's hands are full:

1. Activation: open billing and start listening without tapping.
2. Full bill by voice: A2, A3, A1, A6, B7, B8, B9. After activation, these complete a no-touch bill.

### Why v2.0 excluded it

Always-listening drains battery, raises privacy issues, and browser STT (`webkitSpeechRecognition`) is not free-running/continuous. v2.1 must solve all three.

### Two approaches — pick one

| | **A. OS-assistant launch** | **B. In-app wake-word (foreground mode)** |
|---|---|---|
| How | "Hey Google, open Bahi and start a bill" via **Android App Actions / shortcuts**; OS handles wake-word, deep-links to billing, then in-app **dictation mode (B7)** takes over. | Owner enables a **"listening" foreground service**; local wake-word ("Bahi" / "बही") opens billing + starts dictation. Needs native wake-word lib (e.g. Porcupine) or Android `SpeechRecognizer`, not browser STT. |
| Always-on mic *in our app* | **No** — the OS owns it until launch | **Yes** — while the mode is on |
| Battery | Low (no app-side mic until launched) | Higher (foreground service + live mic) |
| Privacy | Better (no app-side hot mic) | Needs visible "listening" banner + explicit opt-in; mic is hot |
| Platform | Android + Google Assistant only | Android only (foreground service + `RECORD_AUDIO`); not web/PWA |
| Effort | Medium — App Actions intent + deep link + chain to B7 | High — native wake-word, service lifecycle, battery tuning |
| Fallback | Assistant unavailable → tap-to-talk | Service killed by battery saver → tap-to-talk |

Recommendation: start with A. Keep B only for devices without usable assistant and behind explicit, visible opt-in.

### Acceptance (whichever approach)

- From home-screen / awake state, one spoken command opens billing in listening state with zero taps.
- Full bill (customer + ≥2 items) completes by v2.1 dictation grammar with TTS readback (A1).
- Visible live-mic indicator; owner can disable in Settings (extends A5).
- Failure degrades to v2.0 tap-to-talk, never dead end.

### Depends on

B7, A1, A5, C12. Sequence after v2.0 cutover with roadmap Phase 4 / v2.1 candidates.

## 10. Glossary

- **Intent** — parser object: `{kind: 'add'|'commit'|'clear'|'unknown', weight?, rate?, itemName?, itemIndex?, raw}`.
- **Tap-to-talk** — V1 model: one tap, one utterance, mic auto-stops.
- **Dictation mode** — B7 model: long-press, mic stays open until `stop` or 30 s silence.
- **STT** — Speech-to-text (`webkitSpeechRecognition`).
- **TTS** — Text-to-speech (`window.speechSynthesis`).
