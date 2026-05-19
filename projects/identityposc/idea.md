# Idea — identityposc

## One-liner

A free, on-device system that learns who people are in a shop by
overhearing the names they call each other on CCTV audio, with manual
fallback for the long tail.

## Problem

Small-business CCTV captures rich identity signal — faces and dialogue —
but every off-the-shelf "people analytics" product makes one of two bad
trades:

- **Enrolment-heavy systems** require labelling every employee and
  customer face up front. A small shop will never do this.
- **Anonymous counting systems** skip identity entirely. The owner gets
  bar charts of foot traffic but can't answer "is Ramesh in today?" or
  "when did Sunil last visit?"

The hypothesis: in any shop with conversation, **people get addressed by
name on the floor**. *"Thanks, Ramesh"*, *"Kya haal hai Sunil"*, *"Aap
kaise hain Mrs. Verma"*. If the system can extract those vocatives and
bind them to the right person on camera, identity is learned for free —
no enrolment, no labelling.

## Target users

- **Primary**: shop owner running 1–N CCTV cameras with mics, who wants
  to know who's on the floor right now and who visited recently.
- **Secondary**: a small staff that doesn't need to do anything for the
  system to start recognising them.
- **Anti-users**: high-stakes identity uses (access control, payments,
  surveillance for legal evidence). This is observational analytics; the
  binder is intentionally probabilistic and revocable.

## What success looks like

POC (this iteration):

- Pipeline runs end-to-end on a single CPU device against real
  conversational content.
- Binding F1 ≥ 70 % on a labelled clip.
- At least one correct binding within 30 s of the first mention.
- Works on a non-English source without code changes (cross-language
  stress test).

All four targets were met or exceeded by the `best` preset on the Tears
of Steel 180 s clip (F1 80 %, TTFCB 24.5 s, recall 100 %), and the
cross-language stress test passed on the Sharmilee (1971) Hindi clip
([`spec/overview.md`](./spec/overview.md), "POC results").

Production (next phase):

- Multi-camera deployment with shared fusion.
- Privacy controls (retention cap, per-identity opt-out, audit log)
  before any deployment outside a single device.
- GPU path for real-time `best`.

## Constraints

- **No cloud, no paid services** — all processing local.
- **Free or permissively-licensed components only** — MIT/Apache/CC.
  HuggingFace token required only for the optional pyannote upgrade
  (free account).
- **Single CPU device** for the POC; multi-source / GPU comes later.
- **Biometric data stays on device** and out of version control by
  default (`.gitignore`).

## Non-goals (today)

- Cloud SaaS.
- Identity for access control or payments.
- Wake-word / always-listening mic (battery, privacy, no free browser
  STT API supports it).
- Custom Hindi STT model — Whisper `large-v3` is good enough when paired
  with the item-list fuzzy match anchor.
- Cross-camera identity stitching (deferred; embedding columns
  deliberately preserved so it can be added without re-processing video).
- Authentication on the dashboard (it's `127.0.0.1`-bound; production
  needs a reverse proxy).

## Inspiration / prior art

- Pyannote.audio for speaker diarization (published benchmarks).
- InsightFace / ArcFace for the face-recognition contract (R100 is the
  biggest single lever for accuracy).
- Whisper `large-v3` for the proper-noun ASR contract — the single
  biggest lever for name-binding recall.

## Open questions

- [ ] Should `best` always be paired with an offline re-process pass when
      the live tier is `fast`?
- [ ] What's the right confidence floor + stop-list to keep "Hi, honey"
      and "Hi, bear" out of the persons DB?
- [ ] When the system has 100 + auto-bound names, what does the dashboard
      "everyone" view look like? (Plan §10 punts on this.)
- [ ] Cross-camera re-ID — when to ship?
