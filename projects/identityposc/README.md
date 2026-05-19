# identityposc

> A POC for **shop-floor ambient identity**: point one CCTV (camera + mic)
> at the shop and the system answers *who is in the shop right now?* and
> *who has visited in the past, and when?* — **without enrolment**, by
> overhearing the names that staff and customers naturally use when they
> address each other.

- Live code repo: <https://github.com/DDancingDeath/identityposc> (private)
- Status: **POC complete**. M1–M12 all green. Month-end go/no-go
  recommendation: **proceed to a follow-on production phase** (see
  [`spec/overview.md`](./spec/overview.md), "Month-end go/no-go").

---

## The idea

Shop owners already have CCTV with mics. Most "people analytics" products
either (a) need a manual enrolment step where every employee/customer's
face has to be labelled up front — which a small shop will never do — or
(b) skip identity entirely and just count anonymous heads.

**The novel mechanism:** the system learns who people are on its own by
listening to how they're addressed in conversation — *"Thanks, Ramesh"*,
*"Kya haal hai Sunil"* — and binds those names to the speaker the camera
co-locates with the audio. Auto-tagging + manual fallback are both
first-class: when the system can't auto-tag (most customers, ambient
noise, mumbled names), the owner clicks an "untagged person" card and
types a name; from then on that person is recognised on every visit.

Two populations the design accounts for:

- **Staff** — small, fixed, seen daily. Names get learned within days.
- **Customers** — long tail, mostly transient. Most never get a name
  auto-bound; they show up as *"untagged person #42 (regular, last seen
  3 days ago)"* or *"untagged stranger (first time)"*.

**Anti-users / non-goals**: no cloud, no paid services, no live wake-word
listening, no custom Hindi STT model, no biometric data leaves the device.
Production identity-binding for high-stakes use cases (access control,
payments) is **out of scope** — this is observational analytics.

---

## How it works

One A/V source → two parallel lanes → fused into identity events → into a
SQLite persons DB that never resets.

```
            ┌─────────────┐
            │  CCTV feed  │  (file path or rtsp://… — same code path)
            └──────┬──────┘
                   ▼
        ┌──────────────────────┐
        │   SourceWorker       │   one OS process per camera
        └──────────────────────┘
           │                │
           ▼                ▼
   ┌───────────────┐  ┌───────────────────────┐
   │  Video lane   │  │     Audio lane        │
   │  detect →     │  │  demux → VAD →        │
   │  embed (Arc-  │  │  ASR (whisper) →      │
   │  Face) →      │  │  diarize → NER +      │
   │  ByteTrack →  │  │  vocative regex →     │
   │  face cluster │  │  name mentions        │
   └──────┬────────┘  └──────────┬────────────┘
          │                      │
          └──────────┬───────────┘
                     ▼
            ┌─────────────────┐
            │  Fusion service │  AV linker · name binder · persons DAO
            └────────┬────────┘
                     ▼
            ┌─────────────────┐
            │ SQLite (persons │  never resets — survives across runs
            │  + per-run DB)  │
            └────────┬────────┘
                     ▼
            ┌─────────────────┐
            │ FastAPI dashboard│  http://127.0.0.1:8000  (read-only)
            └─────────────────┘
```

**Two presets, one code path** — only model choices differ:

| Layer | `best` (POC default) | `fast` (real-time) |
|---|---|---|
| Face detect+embed | InsightFace **buffalo_l** (SCRFD-10G + ArcFace R100) | buffalo_s |
| Tracker | ByteTrack | IoU + centroid |
| VAD | Silero VAD (ONNX) | webrtcvad |
| ASR | faster-whisper **large-v3** (int8) | small.en (int8) |
| Diarization | pyannote.audio 3.1 (or ECAPA fallback) | Resemblyzer |
| NER | spaCy `en_core_web_trf` + vocative regex | `en_core_web_sm` |
| Storage / UI | SQLite · FastAPI · Uvicorn (local-only) | same |

Both presets and all tunables live in
[`spec/config.yaml`](./spec/config.yaml).

---

## What it does today

- **End-to-end pipeline runs on CPU** and produces identity bindings on
  real conversational content.
- **POC results — Tears of Steel, first 180 s, `best` preset:**

  | Metric | Result |
  |---|---:|
  | Binding F1 | **80.0 %** |
  | Binding recall (Tom + Celia recovered) | **100 %** |
  | TTFCB *(time to first correct binding)* | **24.5 s** |
  | Name-extraction P / R | 100 % / 100 % |
  | Speaker purity (per-cluster) | 87.9 % |
  | Wall-clock | 194 s for 180 s source (≈ realtime) |

- **Cross-language stress test — Sharmilee (1971), 5 min Hindi → English**:
  19 name events, 7 distinct names extracted (Kanchan, Kamini, Lily,
  Naren/Narendra, Rupa, Dwarka), 2 bindings auto-promoted with no code
  changes — the binder works on Hindi audio via Whisper's translate mode.
- **Best-vs-Fast head-to-head** confirms `best` is the right POC default
  (`fast` drops binding F1 to 0 % because `small.en` mis-transcribes
  vocatives). See [`spec/preset-comparison.md`](./spec/preset-comparison.md).
- **Known limitations** with paths to closing them are documented in
  [`spec/overview.md`](./spec/overview.md) ("Known production hazards").

---

## What's next (production phase, not POC)

From [`spec/overview.md`](./spec/overview.md) ("Production: RTSP &
multi-source scaling notes"):

- **Multi-source**: one OS process per camera, shared fusion service, one
  SQLite (with WAL) → Postgres only beyond ~10 sources.
- **Real `pyannote.audio 3.1`** (HF token wired up) to close the
  speaker-purity gap that drives the only false positive in the eval.
- **Cross-channel corroboration** (require face co-occurrence vote OR ≥2
  distinct name mentions) to kill the residual robot-voice FP.
- **GPU** to make `best` real-time per source (currently 0.93×).
- **Privacy / retention controls** (cap, per-identity opt-out, audit log)
  before deploying outside a single device.
- **RTSP watchdog** because `cv2.VideoCapture` can swallow stream stalls.

---

## Reading order for an agent

1. [`idea.md`](./idea.md) — short vision capsule (subset of the section above).
2. [`spec/README.md`](./spec/README.md) — spec entry point + reading order.
3. [`spec/overview.md`](./spec/overview.md) — the comprehensive README from
   the live code repo (idea + tech rationale + results + production notes).
4. [`spec/agents-orientation.md`](./spec/agents-orientation.md) — the
   original AGENTS.md from the code repo (operational guardrails for an
   agent picking up code work — not just docs).
5. [`spec/full-design.md`](./spec/full-design.md) — the full design plan
   (62 KB; the source of truth for *intent*). Read end-to-end before
   making non-trivial design changes.
6. [`spec/preset-comparison.md`](./spec/preset-comparison.md) — empirical
   justification for `best` being the default.
7. [`spec/sample-data.md`](./spec/sample-data.md) — provenance + licenses
   for the test clips.
8. [`spec/config.yaml`](./spec/config.yaml) — all tunables; this is the
   contract between presets and the pipeline.
9. [`plan/status.md`](./plan/status.md) — POC milestone status + next-phase
   gating.
10. [`prompts/build-next-phase.md`](./prompts/build-next-phase.md) — what
    to hand a coding agent to take this from POC to production.

## Layout

```
identityposc/
├── README.md                       ← (this doc) narrative entry point
├── idea.md                         ← vision capsule
├── spec/
│   ├── README.md                   ← reading order
│   ├── overview.md                 ← full README from the code repo
│   ├── agents-orientation.md       ← AGENTS.md from the code repo
│   ├── full-design.md              ← 62 KB design plan
│   ├── preset-comparison.md
│   ├── sample-data.md
│   └── config.yaml
├── plan/
│   └── status.md                   ← POC milestone status + next phase
├── prompts/
│   └── build-next-phase.md
└── assets/                         ← screenshots / diagrams
```

## Recent changes

- _2026-05-20_ · Imported from `DDancingDeath/identityposc` + the session
  design plan (`plan.md`, 62 KB).
