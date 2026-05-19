# identityposc — Shop-floor ambient identity from CCTV + mic

Free / open-source POC for a system that watches and listens to one A/V source from a shop
CCTV (camera + mic) and answers two questions:

- **Who is in the shop right now?**
- **Who has visited the shop in the past, and when?**

The novel mechanism: the system **learns who people are on its own** by overhearing the
names that staff and customers naturally use when they address each other in conversation
(*"Thanks, Ramesh"*, *"Kya haal hai Sunil"*). No enrolment step. No labelling chores.

Two populations:

- **Staff** — small fixed group, seen daily. Names get learned within days because
  colleagues use them on the shop floor.
- **Customers** — long tail, mostly transient. Most never get a name auto-bound; that's
  expected. They appear as *"untagged person #42 (regular, last seen 3 days ago)"* or
  *"untagged stranger (first time)"*.

When auto-tagging fails (ambient noise, mumbled names, foreign-language conversation,
customers who never get addressed by name), the shop owner can click an untagged person's
card in the dashboard and **manually type a name** — first-class fallback, not an
afterthought. From that moment the person is recognised by name on every future visit.

All identities (auto-tagged, manually-tagged, untagged) live in a persistent SQLite
**persons database** that **never resets**. Faces and speakers from each run live in a
separate per-run DB that does. See `plan.md` Phase 2 for the layered design.

> **POC scope.** This single Hyper-V VM with a Hyper-V-redirected host camera + mic stands
> in for one shop CCTV. The production system spawns one worker per camera and pours all
> of them into the same persons DB.
>
> Quality bar: **best achievable accuracy on this device**. Real-time throughput is *not*
> a requirement for the POC — accuracy first.

See `plan.md` (session workspace) for the full design and `AGENTS.md` for orientation when
handing off work between agents.

---

## What's in the box

| Layer                  | `best` preset (POC default)                          | `fast` preset (real-time)        |
|------------------------|------------------------------------------------------|----------------------------------|
| Face detect + embed    | InsightFace **buffalo_l** (SCRFD-10G + ArcFace R100) | buffalo_s (SCRFD-2.5G + MFN)     |
| Tracker                | ByteTrack                                            | IoU + centroid                   |
| VAD                    | Silero VAD (ONNX)                                    | webrtcvad                        |
| ASR                    | faster-whisper **large-v3** (int8)                   | small.en (int8)                  |
| Speaker diarization    | pyannote.audio 3.1 (or ECAPA fallback)               | Resemblyzer + online clustering  |
| NER                    | spaCy `en_core_web_trf` + vocative regex             | `en_core_web_sm` + vocative      |
| Storage                | SQLite                                                | SQLite                           |
| Dashboard              | FastAPI + Uvicorn (local-only)                       | same                             |

Both presets share **one code path**; only model choices differ. They live side-by-side in
`config.yaml`. POC defaults to `best`.

---

## Quick start (Windows, CPU-only)

> Prereqs: Python 3.11 and FFmpeg on PATH. The setup script will check both.

```powershell
# 1. Create venv + install best-preset dependencies + spaCy transformer model.
.\scripts\setup_env.ps1

# 2. (Optional) HuggingFace token for pyannote.audio 3.1 — best-quality diarization.
#    If absent, code falls back to ECAPA-TDNN (no auth needed, slightly worse).
$env:HF_TOKEN = "hf_xxx"

# 3. See CLI help.
.\.venv\Scripts\python.exe -m identityposc.main --help

# 4. Run the POC on the bundled sample clip.
.\scripts\run_poc.ps1
```

The dashboard, when implemented, runs at **http://127.0.0.1:8000**.

### Switching to RTSP (production target)

`--source` accepts both file paths and RTSP URLs — the underlying `cv2.VideoCapture()` and
`ffmpeg -i` calls handle both transparently:

```powershell
.\.venv\Scripts\python.exe -m identityposc.main `
    --source "rtsp://user:pass@cam.local:554/Streaming/Channels/101" `
    --preset best
```

---

## Layout

```
D:\Exp\
├─ AGENTS.md                  # Orientation page for AI agents continuing this work
├─ README.md                  # (this file)
├─ pyproject.toml             # Editable install: `pip install -e .`
├─ config.yaml                # All tunables for both presets
├─ requirements-best.txt
├─ requirements-fast.txt
├─ data\
│  ├─ sample\                 # POC test clips (gitignored, see NOTES.md)
│  ├─ models\                 # whisper / insightface / pyannote / spacy caches
│  ├─ thumbnails\             # face crops keyed by face_id
│  ├─ eval\                   # ground-truth + reports
│  └─ db\identities.sqlite    # the name database
├─ scripts\
│  ├─ setup_env.ps1
│  ├─ download_sample.py
│  ├─ run_poc.ps1
│  └─ run_eval.ps1
└─ src\identityposc\
   ├─ main.py                 # CLI entry
   ├─ config.py
   ├─ db.py
   ├─ source_worker.py        # one process per source
   ├─ video\                  # capture, detect, embed, tracker
   ├─ audio\                  # demux, vad, asr, speaker
   ├─ fusion\                 # face/speaker clustering, AV linker, name binder
   ├─ eval\                   # metrics, report
   └─ dashboard\              # FastAPI UI
```

---

## Why these choices?

- **faster-whisper `large-v3` over Vosk** — proper-noun accuracy is *the* bottleneck for
  name-binding. Whisper large-v3 is currently the best free open ASR for this. It runs
  slower than real-time on CPU; that's acceptable for the POC because we drive from a file.
- **InsightFace `buffalo_l` over MediaPipe** — MediaPipe gives landmarks but not identity
  embeddings; we need ArcFace for clustering. R100 over MobileFaceNet is the single biggest
  accuracy lever for face identification.
- **pyannote.audio over hand-rolled clustering** — speaker turn segmentation + clustering
  is genuinely hard. Pyannote gives a published-benchmark pipeline. Cost: a one-time
  HuggingFace account (free). If the user prefers to skip that, code transparently falls
  back to ECAPA-TDNN via SpeechBrain.

---

## Status & milestones

Tracked in the session SQL DB (see `AGENTS.md` §3 for current state). The 12 milestones:
**scaffold → deps-verify → video-pipeline → audio-pipeline → schema-and-persistence →
av-fusion → name-binding → dashboard → eval-harness → best-vs-fast → end-to-end-demo →
rtsp-multi-notes**.

---

## POC results (Tears of Steel, first 180 s, `best` preset)

> See `data/eval/report.html` for the full HTML report and
> `data/eval/preset_comparison.md` for the side-by-side `best` vs `fast` table.

| Metric | Result |
|---|---:|
| **Binding F1** | **80.0%** |
| Binding precision | 66.7% |
| **Binding recall** | **100%** (Tom + Celia both recovered) |
| **TTFCB** *(time to first correct binding)* | **24.5 s** (`speaker#3 → Celia`) |
| Name-extraction P / R | 100% / 100% (3/3 mentions) |
| Speaker purity (per-cluster) | 87.9% (10 ECAPA clusters for ~3 real people) |
| Wall-clock pipeline time | 194 s for 180 s of source (≈realtime on this CPU) |

**Bindings produced**

| Target | Bound name | Verdict |
|---|---|---|
| `speaker#3` | Celia | ✅ correct (dominant_person=celia) |
| `speaker#4` | Tom | ✅ correct (dominant_person=tom) |
| `speaker#6` | Tom | ❌ false positive (dominant_person=robot_voice; only one mention seen, no competing name) |

**Three name mentions extracted from the clip**

| Time | Turn | Transcript | Mentioned name | Resolved addressee |
|---:|---|---|---|---|
| 11.53 s | 3 | "Jerk, **Tom**." | Tom | speaker#2 |
| 24.49 s | 4 | "Look, **Celia**, we have to follow our passions." | Celia | speaker#3 (face#1) |
| 42.45 s | 11 | "Whatever, **Tom**." | Tom | speaker#5 |

The system started with no prior knowledge of any names — *Tom* and *Celia*
were learned purely from how the characters address each other in dialogue.

**Sample dashboard transcript view** (excerpt, with auto-learned names applied):

```
[02.13 →  6.33] speaker#1            : "We have main engine start."
[06.83 →  9.63] speaker#2            : "Four, three, two, one."
[11.53 → 24.31] speaker#3 (Celia)    : "Jerk, Tom."
[24.49 → 26.81] speaker#4 (Tom)      : "Look, Celia, we have to follow our passions."
[27.27 → 30.03] speaker#4 (Tom)      : "You have your robotics and I just want to be awesome in space."
[30.43 → 34.33] speaker#5            : "Why don't you just admit that you're freaked out by my robot hand?"
[42.45 → 43.39] speaker#4 (Tom)      : "Whatever, Tom."
[50.07 → 53.61] speaker#6 (Tom)      : "Robot's memory synced and locked."   <-- FP: this is a robot voice
```

### Best vs Fast preset (same clip)

| | `best` | `fast` |
|---|---:|---:|
| Binding F1 | **80.0%** | 0% |
| Recall | 100% | 0% (no bindings ever promoted) |
| Speaker purity | 87.9% | 44.6% |
| Name extraction P/R | 100% / 100% | 33% / 33% |
| Wall-clock | 194 s (≈realtime) | 79 s (2.3× realtime) |

The `fast` preset is real-time-capable on this CPU but loses the name-binding
signal: `small.en` mis-transcribed two of three vocative mentions and
Resemblyzer fragmented speakers badly. `best` is the right default for the
POC quality bar; `fast` becomes interesting once paired with an offline
re-process pass — or when a real GPU lets `best` run in real-time.

### Reproduce

```powershell
# best preset
.\.venv\Scripts\python.exe -m identityposc.main `
    --source data\sample\tears_of_steel_720p.mov --max-seconds 180

# fast preset
.\.venv\Scripts\python.exe -m identityposc.main `
    --preset fast --source data\sample\tears_of_steel_720p.mov --max-seconds 180

# eval against ground truth
.\.venv\Scripts\python.exe -m identityposc.eval.report `
    --config config.yaml --gt data\eval\tears_of_steel_180s.yaml

# dashboard
.\.venv\Scripts\python.exe -m identityposc.dashboard --config config.yaml
# -> http://127.0.0.1:8000
```

### Month-end go/no-go assessment

**Recommendation: proceed to a follow-on production phase.** The novel
contribution — *learning identities from how people address each other* —
works on real conversational content with credible accuracy on the very first
clip we throw at it (F1 = 80%, recall = 100%, TTFCB = 24.5 s) using only
free / open-source components and no prior knowledge of the speakers. Known
limitations are well-understood and trace to known weaker components:

- The single residual false positive (`spk#6 → Tom` on a robot voice) needs
  cross-channel corroboration (e.g. require a face co-occurrence vote, or
  ≥2 distinct mentions). Both gates hurt recall on this small clip but pay
  off on longer footage.
- Speaker fragmentation (87.9% per-cluster purity, 10 clusters for ~3 real
  people) is the dominant remaining error source. Wiring up a HuggingFace
  token to enable real `pyannote.audio 3.1` should close most of this gap
  with no code changes.
- Reverse-shot cinematography defeats the AV linker (camera shows the
  *listener*, not the speaker). This is a property of cinematic content;
  real CCTV is unaffected.

The next-phase plan is captured in §10 of the design plan: per-source
worker process, shared fusion service, GPU for `best` in real-time, optional
Postgres if the database grows past a few GB.

---

## License & data

- **Code**: MIT (POC scratch — relax later if needed).
- **Sample clips** are *not* committed; see `data\sample\NOTES.md` for provenance and licenses.
- **Biometric data** (`data\thumbnails\`, `data\db\identities.sqlite`) is `.gitignore`d by
  default. Do not commit.

---

## Production: RTSP & multi-source scaling notes

The POC drives from a file, but `--source` already accepts both — the
underlying `cv2.VideoCapture(url)` and `ffmpeg -i {url}` calls handle file
paths and RTSP URLs identically. The same code path runs against a real
camera with no edits:

```powershell
.\.venv\Scripts\python.exe -m identityposc.main `
    --source "rtsp://user:pass@cam.local:554/Streaming/Channels/101" `
    --preset best
```

### One source today, N sources tomorrow

The architecture is one OS process per A/V source — `SourceWorker` owns
one decoder, one VAD, one ASR, one diarizer, one detector/embedder. Scaling
to 5+ cameras means spawning 5+ `SourceWorker` processes that all write to
the same SQLite DB and let a shared **fusion service** see all of their
events. Sketch:

```
camera_1 ──► SourceWorker_1 ──┐
camera_2 ──► SourceWorker_2 ──┤
   …                          ├──►  multiprocessing.Queue  ──► FusionService ──► SQLite
camera_N ──► SourceWorker_N ──┘                                       │
                                                                      ▼
                                                          FastAPI dashboard (read-only)
```

Concretely:

- **Workers stay single-process**. Each `SourceWorker` is heavy (loads ASR,
  detector, diarizer once at startup) and lightly stateful — fan out by
  process, not threads (Python GIL + ONNX both prefer it).
- **Fusion stays single-process**. The face / speaker clusterer, AV linker,
  and identity binder all need a global view of the world. They consume
  events off a `multiprocessing.Queue` and write through `db.py`.
- **One model load per worker is wasteful**; for 5+ workers, move ASR /
  detector / embedder into a tiny gRPC or ZMQ inference service that loads
  each model once and serves N workers. Saves ~3 GB RAM and ~15 s startup
  per extra worker.
- **CPU budget**. On this Xeon (no GPU), `best` is ≈realtime per source.
  5 sources at `best` = 5× CPU, which the host doesn't have. Either:
  (a) move to `fast` for the 5-source live tier and run a nightly `best`
  re-process pass over each source's WAVs, or
  (b) attach a real Nvidia GPU and `best` runs at 5–10× realtime per source.
- **DB scaling**. SQLite + WAL mode handles a handful of concurrent writers
  fine. Beyond ~10 sources or a few GB of votes/turns, swap in Postgres —
  the DAOs in `db.py` already use parameterised SQL so the change is
  cosmetic.
- **Cross-camera identity stitching** (re-ID). Once we have multiple cameras
  it becomes interesting to ask "is `face#3` on cam_1 the same person as
  `face#7` on cam_2?". Out of POC scope, but the embedding columns in the
  `faces` table are deliberately preserved so a cross-source match step can
  be added later without re-processing video.
- **Service hosting**. Wrap with NSSM as a Windows service, or move to
  Linux/systemd if the production target grows. The dashboard is the only
  network-facing component; in production it should sit behind an authenticating
  reverse proxy (auth is *explicitly out of POC scope* — don't expose
  `127.0.0.1:8000` directly to a network).

### Known production hazards (don't ship without addressing)

- **Privacy / retention**. Biometric data falls under most regional privacy
  regimes. Implement retention cap + per-identity opt-out + audit log
  *before* deploying outside a single device.
- **RTSP reliability**. `cv2.VideoCapture` swallows certain stream stalls
  silently. Production needs a watchdog that restarts the worker on
  no-new-frames-for-N-seconds.
- **Audio drift**. FFmpeg-demuxed audio assumed to start at the same
  wall-clock as video; long-running RTSP can drift. Anchor by stream
  timestamps, not local clock.
- **Names that are also common words**. The vocative regex catches "Sarah"
  but also "Hi, Bear" or "Honey". Production needs a stop-list and
  optionally a confidence floor on the binding.
- **Diarization needs HF token in production** — ECAPA fallback is good
  enough for a POC but the binding precision gap traces to it. Real
  `pyannote.audio 3.1` should close most of it.
