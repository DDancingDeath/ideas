# Voice Billing — V2 Design

> **Status:** Draft for review. Lives in `docs/VOICE_BILLING_V2.md`.
> Builds on V1 (commit `56e230f` — "tap-to-talk voice entry, Hindi + English,
> for purchase + sale"). Scope is **strictly the billing page**.

## 1. Goals

V1 shipped a working but minimal voice-billing experience: one tap, one
item, one weight, one rate. Real shop-floor billing is faster, more
multi-step, and happens with both hands full of goods or a scale. V2
makes voice actually useful in that environment.

What V2 must deliver:

1. **Hands-free verification** — shopkeeper hears "added 10 kilo aloo at
   30 rupees" without looking at the phone.
2. **Bills in one breath** — *"10 kilo aloo at 30, 5 kilo pyaaz at 25"*
   produces two rows, not one confused row.
3. **Whole bill in voice** — including the customer name, not just items.
4. **Safety** — opt-in confirmation mode for users who don't trust
   speech-to-text; opt-out toggle for users who want voice gone entirely.
5. **Wider Hindi vocabulary** — every number 1–99, both Devanagari and
   Roman-Hindi spellings, so prices like 33 / 47 / 82 work spoken in Hindi.
6. **Production readiness on Android** — `RECORD_AUDIO` in the manifest;
   misrecognition data captured (opt-in) so we can tune the parser from
   real usage.

What V2 must NOT do:

- **No new tabs.** Voice on chat, cash management, items, expenses are
  out of scope for V2. Each is a future ask.
- **No wake-word.** No always-listening mic; drains battery, raises
  privacy questions, and isn't free in any browser STT API.
- **No server-side STT.** Voice samples never leave the device.
  We use `webkitSpeechRecognition` only.
- **No custom Hindi STT model.** Chrome's `hi-IN` is good enough when
  paired with the item list as a fuzzy-match anchor.

## 2. Status quo — what V1 already does (commit `56e230f`)

Reference table so reviewers don't need to re-read the V1 code.

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

```
                  user taps 🎤 (purchase or sale)
                                │
                                ▼
              ┌────────────────────────────────┐
              │  VoiceBillingManager.start()   │  voice-billing.js
              │  (singleton, stateful)         │
              └──────────────┬─────────────────┘
                             │
                             ▼
              ┌────────────────────────────────┐
              │  webkitSpeechRecognition       │  browser
              │  lang = preferences.voiceLang  │  ← new in A5
              └──────────────┬─────────────────┘
                             │ final transcript
                             ▼
              ┌────────────────────────────────┐
              │  parseUtterance(text, items)   │  pure function
              │  returns Intent[] (was: Intent)│  ← changes in A2
              └──────────────┬─────────────────┘
                             │
                             ▼
              ┌────────────────────────────────┐
              │  manager dispatches per intent:│
              │   • fill inputs                │
              │   • addWeight() (unless A6     │
              │     preview mode is on)        │
              │   • TTS readback (A1)          │
              │   • customerName fill (A3)     │
              └────────────────────────────────┘
```

The pure parser stays testable in jsdom. The manager stays the only
DOM-touching, browser-only surface. V2 doesn't change the layering —
it only widens the grammar and adds adjacent capabilities (TTS, settings).

## 4. V2 work plan

Organised by **tier** (build-order) and **letter** (slot in tier).
Each item is independent except where noted under "Depends on".

### Tier A — high-value, low-risk (build first)

#### A1. TTS readback (audio confirmation)
**What:** After every successful voice action, speak a short Hindi/English
confirmation via `window.speechSynthesis`.
- Add: *"added 10 kilo aloo at 30 rupees"* / *"दस किलो आलू तीस रुपये जोड़ा"*
  (language follows the same preference as STT).
- Commit: *"bill saved"* / *"bill jod diya"*.
- Clear: *"cleared"* / *"साफ़ कर दिया"*.
- Unknown utterance: no TTS (a toast is enough; avoid spamming).
- Respect the **TTS toggle** from A5; default on.

**Why this first:** biggest UX gain per line of code. A shopkeeper holding
a scale can't glance at the phone every utterance.

**Implementation:**
- New helper `speak(textHi, textEn)` inside `VoiceBillingManager`.
- Pick a `hi-IN` voice from `speechSynthesis.getVoices()` once on init;
  cache; fall back to default.
- Call `speak()` from `_handleUtterance` after each success branch.

**Test:** mock `window.speechSynthesis` in jest, assert `.speak()` was
called with the expected utterance string for each branch.

**Depends on:** A5 (so the toggle exists). Build A5 first → A1.

---

#### A2. Multi-item utterance
**What:** Parser learns separators `and` / `aur` / `और` / `,` / `;` and
returns an **array** of `add` intents rather than a single intent.
*"10 kilo aloo at 30 and 5 kilo pyaaz at 25"* → two rows staged.

**Implementation:**
- Change `parseUtterance` return shape from a single intent to either
  a single intent (current callers continue to work) **or** an array,
  picking the array when separators are present. Update internal type:
  `{ kind: 'add'|'commit'|'clear'|'unknown' | 'batch', items?: Intent[], ... }`.
- New `splitOnSeparators(text)` returns one segment per implied item.
- Manager loops each segment: fill → `addWeight()` → next.
  All-or-nothing semantics — if segment 3 fails to parse, segments 1+2
  still land (matches typing behaviour: each weight chip is independent).

**Test:** at least 10 new cases:
- 2-item English with `and`
- 2-item Hindi with `aur`
- 2-item Devanagari with `और`
- Comma-separated, 3 items
- Mixed: `"10 kg aloo 30, pyaaz 25"` (item-without-weight middle slot)
- Trailing separator (`"…and"`) — must not crash
- Backwards-compatible: single-item utterance still returns a single intent

---

#### A3. Customer-name dictation
**What:** A trigger word (`customer` / `ग्राहक` / `naam`) followed by 1–3
tokens fills the customer name field.
- *"customer Ramesh Kumar, 10 kilo aloo at 30"*
  → `customerName` = "Ramesh Kumar", then row added.
- *"ग्राहक रमेश, दस किलो आलू"*  → same.
- Capture stops at the first number, separator, or unit word — so a name
  never leaks into item-match territory.

**Implementation:**
- New `extractCustomerName(text)` runs **before** item-match, removes the
  matched span from the working text so item-match isn't confused.
- New trigger word list `CUSTOMER_PHRASE_LIST` in voice-billing.js.
- Manager fills `customerName` (purchase) or `saleCustomerName` (sale)
  depending on `_mode`.

**Test:** ≥6 cases covering English/Hindi triggers, multi-word names,
name with item in same utterance, name only, no trigger (must not
match).

---

#### A4. Expanded Hindi number table (11–99)
**What:** Fill in the missing entries so every spoken Hindi number
1–99 parses.

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

Optional follow-on: compound parsing of *"tees-teen"* → 33 for speakers
who know "tees" and "teen" but not "tetalees". Low priority — digits
already cover 95%.

**Test:** parametric — for every entry in the new table, assert
`parseUtterance("X kilo aloo")` returns `weight: <number>`.

---

#### A5. Settings toggle + language pick
**What:** New "Voice input" section on the Settings page (`14-settings.md`).
Persists to `AppState.preferences` + Firestore `users/{uid}/preferences`.

| Setting | Type | Default | Effect when changed |
|---|---|---|---|
| Enable voice input | toggle | on | When off: hide both 🎤 buttons; `VoiceBillingManager.start()` becomes a no-op |
| STT language | radio: hi-IN / en-IN / en-US | hi-IN | Sets `rec.lang` on next listen session |
| TTS readback | toggle | on | When off: skip the `speak()` call (toast still appears) |
| Confirmation mode | radio: auto-add / preview | auto-add | Controls A6 behaviour |

**Implementation:**
- Add fields to `AppState.preferences.voice = { enabled, lang, tts, confirmMode }`.
- Reuse the existing `users/{uid}/preferences` Firestore doc (the same
  one Phase 4 was going to extend rules for — the per-user prefs rule
  is already designed in `docs/STAGING_RULES_PATCH.md`).
- Settings UI: new section, four controls, save-on-change.
- VoiceBillingManager reads `_ctx.AppState.preferences.voice` on each
  `start()` so changes apply immediately without page reload.

**Test:** Settings save → assert Firestore write payload; Settings
load → assert UI controls reflect prefs; mic button visibility toggles
with the enable flag.

---

#### A6. Confirmation mode (preview-then-commit)
**What:** When user picks "preview" in A5, voice input fills the inputs
but does **not** auto-click `addWeight()`. User reviews on screen and
says *"confirm"* / *"haan"* / *"OK"* / *"पक्का"* to commit, or speaks
again to overwrite, or *"clear"* to abandon.

**Implementation:**
- New `CONFIRM_PHRASE_LIST`.
- Add a state field to `VoiceBillingManager._stagedIntent` — when set,
  the `start()` call accepts only *confirm* / *overwrite* / *clear*
  utterances. On confirm, the auto-`addWeight()` finally runs.
- TTS readback (A1) reads the preview *before* asking for confirmation
  ("staged: 10 kg aloo, 30 rupees. say confirm to add.").

**Test:** state-machine cases — idle → previewing → confirmed; idle →
previewing → overwritten; idle → previewing → cleared.

**Depends on:** A5 (the setting that gates this behaviour).

---

### Tier B — refinements (after Tier A lands)

#### B7. Continuous "dictation mode"
**What:** Long-press the mic (or a separate "Dictation" button) to enter
a session where recognition stays open across multiple utterances.
Ends on *"stop"* / *"रुको"* / *"khatam"*, on 30 s of silence, or on
navigation away.

**Implementation:** flip `rec.continuous = true`; manage the lifecycle
explicitly; show a different active-state ("DICTATING" pulsing red).

---

#### B8. Voice undo / revert last action
**What:** *"undo"* / *"वापस"* / *"galat"* pops the most recent voice add
(removes the last weight chip OR removes the last committed row).

**Implementation:** small undo stack in VoiceBillingManager keeping
the last 5 actions: `{type: 'add'|'commit'|'clear', undo: () => void}`.
Manager exposes `.undoLast()`.

---

#### B9. Edit row via voice
**What:** *"row 2 rate 35"* / *"दूसरा रेट 35"* updates the rate of the
named row without retyping the whole line. Useful for fixing
misrecognised rates.

**Implementation:** parser learns ordinal triggers
(`pehla`/`doosra`/`teesra` and `1st`/`2nd`/`3rd`); manager calls
`editBillItem(idx)` to open the row, then changes the right field.

---

#### B10. Transcript log panel (toggleable)
**What:** Collapsible drawer below the mic shows the last 3 utterances
+ what the parser extracted. Makes it visually obvious whether
recognition or parsing is at fault.

**Implementation:** ring buffer of length 3 in VoiceBillingManager;
render in a small `<details>` element next to the status line.

---

#### B11. Audio cue on listen start/stop
**What:** Short 100 ms tone on mic-open and mic-close so the user knows
the mic is hot without looking.

**Implementation:** generate the tone with `AudioContext` (no asset
download); two different pitches for open vs close.

---

### Tier C — production readiness

#### C12. Android `RECORD_AUDIO` manifest entry
**What:** Capacitor APK builds need the explicit permission in
`android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
```

**Where:** the **prod** repo (`DDancingDeath/AadhatManagementApp`) —
this staging clone has no `android/` directory. Owner action. Document
the exact diff in the V2 promotion PR.

---

#### C13. Misrecognition telemetry (privacy-respecting)
**What:** When user says *"clear"* / *"undo"* within 5 seconds of a
voice add, anonymously log `{transcript, parsed, action_taken: 'reverted'}`
to a `voiceMisses/` collection. Use to tune the parser from real data.

**Privacy controls:**
- **Opt-in by default in prod.** A new Settings toggle "help improve
  voice recognition" (off by default).
- **Opt-out by default in staging.** Safe environment, helps tuning.
- Never log customer names, item rates, or anything PII-shaped — the
  transcript field is the only free-text payload, and the toggle text
  explicitly states it leaves the phone.

---

## 5. Build sequence

Each step ships independently and is testable on its own.

1. **A5** — Settings toggle scaffold (unlocks opt-out and gates A1/A6)
2. **A1** — TTS readback
3. **A2** — Multi-item utterance
4. **A3** — Customer-name dictation
5. **A4** — Hindi number expansion
6. **A6** — Confirmation mode
7. Tier B (any order, all independent)
8. **C12** — prod repo manifest entry (owner action; document diff)
9. **C13** — last, once Tier A has settled and real misses exist

## 6. Test strategy

| Layer | What | How |
|---|---|---|
| Parser | every new phrase pattern | ≥1 positive + 1 negative jest case |
| Manager dispatch | filling inputs, auto-add, undo stack | jsdom + stubbed `BillingManager` |
| TTS | readback strings, voice picking | mock `window.speechSynthesis`, assert `.speak()` |
| Settings | toggle persistence, lang switch | mock `FirebaseService`, assert payload shape |
| End-to-end | mic → form fill → bill saved | manual smoke on Chrome desktop + Android |

**Targets:**
- 50+ parser tests by end of Tier A (currently 28)
- 70+ parser tests by end of V2
- All existing 539 tests still green at every merge

## 7. Open assumptions (override anytime)

1. **Tier A is the right cut.** Smallest reasonable V2 is just A1 (TTS)
   + A2 (multi-item) shipped as one PR — that fixes the two biggest
   "feels broken without" pain points.
2. **Settings storage uses Firestore prefs.** If you'd rather keep it
   device-local (`localStorage`), it's a one-line change — but then
   voice prefs don't follow the user to a second device.
3. **Telemetry opt-in default in prod.** Some shopkeepers will not want
   voice samples leaving their phone. If you'd rather make it opt-out
   to maximise tuning data, say so and we flip the default + the
   Settings copy.
4. **A4 covers only round Hindi numbers up to 99.** Numbers > 99 (like
   *"do sau pachas"* = 250) parse fine via digits in real-world use,
   so we don't add the hundreds/thousands compound machinery in V2.
5. **No voice for chat / cash / items / expenses** — explicitly out of
   scope. Each is a future ask once V2 has bedded in.

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

## 9. Glossary

- **Intent** — the structured object the parser returns:
  `{kind: 'add'|'commit'|'clear'|'unknown', weight?, rate?, itemName?, itemIndex?, raw}`.
- **Tap-to-talk** — current V1 model: one tap, one utterance, mic auto-stops.
- **Dictation mode** — V2 B7 model: long-press, mic stays open until
  user says *stop* or 30 s silence.
- **STT** — Speech-to-text (the browser's `webkitSpeechRecognition`).
- **TTS** — Text-to-speech (`window.speechSynthesis`).
