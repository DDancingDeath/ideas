# AGENTS.md — context for AI coding agents working on this repo

> **Read this first.** This file is the entry point for any AI agent (Copilot CLI, Claude Code, Cursor, etc.) picking up work on this project. It is intentionally short and operational. The full design rationale lives in the session plan referenced below.

## 1. What this project is

A POC for a **shop-floor ambient identity system**. The shop owner already has CCTV
cameras with mics installed. This system watches and listens to the live A/V feeds and
**learns who people are on its own** — without enrolment, without manual labelling
chores — by overhearing the names that staff and customers naturally use when they
address each other (*"Thanks, Ramesh"*, *"Kya haal hai Sunil"*). The two questions it
ultimately answers:

- **Who is in the shop right now?**
- **Who has visited the shop in the past, and when?**

Two populations the system handles:

- **Staff** — small fixed group, seen daily. Names get learned within days because their
  colleagues call them by name on the shop floor.
- **Customers** — long tail, mostly transient, mostly never get a name. That's expected
  and OK. They show up as *"untagged person #42 (regular, last seen 3 days ago)"* or
  *"untagged stranger (first time)"*.

When auto-tagging fails (most customers, ambient noise, mumbled names), the person stays
untagged — but the shop owner can click their card in the dashboard and **manually type
a name**. From that moment forward the person is recognised by that name on every future
visit. Auto-tagging and manual-tagging are both first-class.

All identities — auto-tagged, manually-tagged, and untagged — are persisted to a local
SQLite **persons database** (`data/db/identities_persons.sqlite`) that **never resets**.
Faces, speakers, and per-run state live in a separate per-run DB that *does* reset; see
`plan.md` Phase 2 section.

**POC scope:** This single Hyper-V VM with one redirected camera + mic (Hyper-V Enhanced
Session) stands in for **one** of those shop CCTVs. The production system spawns one
source-worker process per camera and pours all of them into the same persistent persons
database. See §10 of the plan for scaling notes.

- Quality bar: **best achievable accuracy** on this device. Real-time is *not* required.
- POC window: ~1 month. Go/no-go on a follow-on production phase is decided by the
  measurable evaluation harness (plan §8.9) plus the persistent-persons acceptance
  criteria in plan.md Phase 2.
- **No cloud. No paid services.** All processing local.

## 2. Authoritative pointers (read these before doing work)

| Resource              | Location                                                                                                | Purpose                                  |
|-----------------------|---------------------------------------------------------------------------------------------------------|------------------------------------------|
| **GitHub repo**       | **https://github.com/DDancingDeath/identityposc** (private)                                              | Code home. Push `main` here. Initial commit `a315caf`. |
| Full design plan      | `spec/full-design.md` (copied into this repo)                                                            | Goal, scope, tech stack, algorithm, milestones — this is the source of truth for *intent*. |
| Live todo board       | session SQL DB, table `todos` (with `todo_deps` for ordering)                                           | Source of truth for *current execution state*. Update status as you work. |
| Sample data provenance| `D:\Exp\data\sample\NOTES.md`                                                                            | What clips we use, where they came from, license. |
| This file             | `D:\Exp\AGENTS.md`                                                                                       | Quick orientation for the next agent.   |

## 3. Current status (update this as you work)

| Item                                                       | Status                                                                            |
|------------------------------------------------------------|-----------------------------------------------------------------------------------|
| Plan written and approved                                  | ✅                                                                                 |
| Todos populated in SQL                                     | ✅ (12 milestones; m1–m9 done, m10 in progress)                                    |
| `data/` directory tree                                     | ✅                                                                                 |
| Sample videos                                              | ✅ Computer Chronicles VR (1992) + Tears of Steel 720p (`.mov` — note extension) + **Sharmilee 1971 (Bollywood, CC0)** |
| Python 3.11 + FFmpeg                                       | ✅                                                                                 |
| HuggingFace token for pyannote                             | ❌ — using ECAPA fallback (87.9% per-cluster purity, 10 clusters for ~3 people)    |
| M1 scaffold / M2 deps / M3 video / M4 audio                | ✅                                                                                 |
| M5 schema / M6 AV linker / M7 name binder                  | ✅ (M7 first correct binding: `speaker#5 → Tom` on a 3-min slice)                  |
| M8 FastAPI dashboard                                       | ✅ (`http://127.0.0.1:8000`)                                                        |
| **M9 eval harness** (`F1=80%, P=66.7%, R=100%, TTFCB=24.5s` on ToS 180s) | ✅                                                                  |
| M10 best-vs-fast preset comparison                         | ✅ `best` 80% F1 vs `fast` 0% F1 (`fast` mis-transcribes 2/3 vocatives) |
| M11 end-to-end demo + README write-up                      | ✅                                                                                  |
| M12 RTSP + multi-source notes                              | ✅                                                                                  |
| **Bollywood cross-language run (Sharmilee 1971, 5 min)**   | ✅ Hindi → English (`large-v3` translate). 19 name events, 7 distinct names extracted (Kanchan, Kamini, Lily, Naren/Narendra, Rupa, Dwarka), 2 bindings auto-promoted (`spk#3 → Kanchan` conf 1.00, `spk#2 → Kanchan` conf 0.82). DB: `data\db\identities_bollywood.sqlite`. |

## 4. Repository layout (intent)

```
D:\Exp\
├─ AGENTS.md                     <-- you are here
├─ README.md                     (to be created in scaffold milestone)
├─ requirements-best.txt         (best-quality preset)
├─ requirements-fast.txt         (real-time preset)
├─ config.yaml                   (both presets, all tunables)
├─ pyproject.toml                (so `pip install -e .` makes the CLI runnable)
├─ data\
│  ├─ sample\                    sample video files + NOTES.md
│  ├─ models\                    on-disk caches: whisper, insightface, pyannote, spacy
│  ├─ thumbnails\                face crops keyed by face_id
│  ├─ eval\                      hand-labelled ground truth + report.html
│  └─ db\identities.sqlite       the name database (SQLite)
├─ scripts\
│  ├─ setup_env.ps1              venv + pip install + ffmpeg check + HF token prompt
│  ├─ download_sample.py         optional re-download
│  ├─ run_poc.ps1                end-to-end demo
│  └─ run_eval.ps1               quality evaluation
└─ src\identityposc\
   ├─ main.py                    CLI: --source <file|rtsp://...> --preset <best|fast>
   ├─ config.py
   ├─ db.py                      SQLite schema + DAOs
   ├─ source_worker.py           one process per source
   ├─ video\        capture, detect, embed, tracker
   ├─ audio\        demux, vad, asr, speaker
   ├─ fusion\       face_clusterer, speaker_clusterer, av_linker, name_extractor, identity_binder
   ├─ eval\         schema, metrics, report
   └─ dashboard\    FastAPI app + Jinja2 templates
```

## 5. Tech stack at a glance (full table in plan §4)

Two presets share one code path. POC default: **`best`**.

| Layer            | best (POC default)                                                | fast (future real-time tier)         |
|------------------|-------------------------------------------------------------------|--------------------------------------|
| Face detect+rec  | InsightFace `buffalo_l` (SCRFD-10G + ArcFace R100)                | `buffalo_s` (SCRFD-2.5G + MobileFaceNet) |
| Tracker          | ByteTrack (Python port)                                           | Simple IoU + centroid                |
| VAD              | Silero VAD (ONNX)                                                 | webrtcvad                            |
| ASR              | faster-whisper `large-v3` int8                                    | faster-whisper `small.en` int8       |
| Speaker diariz.  | pyannote.audio 3.1 (fallback: SpeechBrain ECAPA + clustering)     | Resemblyzer + clustering             |
| NER              | spaCy `en_core_web_trf` + vocative regex (+ optional fastcoref)   | `en_core_web_sm` + vocative regex    |
| Storage          | SQLite (stdlib)                                                   | same                                 |
| Dashboard        | FastAPI + Uvicorn + Jinja2                                        | same                                 |

## 6. Environment caveats (very important)

- This is a **Microsoft Hyper-V VM**, Windows 11 Enterprise. `Get-CimInstance Win32_VideoController` only reports the Hyper-V virtual adapter — **there is no usable GPU**. Don't suggest CUDA/cuDNN paths in code; they will fail.
- **No physical camera or mic is attached to the VM directly.** However, **Hyper-V Enhanced Session redirects** the host's camera and mic into the VM as DirectShow devices `Surface Camera Front (redirected)` and `Remote Audio`. The live runner (`scripts\run_live.ps1` → `identityposc.live`) uses these and is fully functional. For file-based runs (eval, batch processing, replay) drive everything from `data\sample\`. RTSP code paths still need to exist for the production target (multiple shop CCTVs) but aren't exercised on this VM.
- CPU is generous (Xeon Platinum 8370C, 16T) and RAM is generous (64 GB). Lean on multi-process / int8 quantization rather than GPU.
- **Slower-than-real-time processing is acceptable.** The `best` preset will likely run at 0.2–0.4× real-time. That is by design — quality over throughput in the POC.
- Python is **not** installed. Only Microsoft Store stub aliases (`python.exe`, `python3.exe`) exist. Install real Python 3.11 (winget: `winget install -e --id Python.Python.3.11`).
- FFmpeg is **not** installed. Required for video decode and audio demux. Install with `winget install -e --id Gyan.FFmpeg` then verify `ffmpeg -version` works.
- `winget` and `choco` are both available. `git` is available (`C:\Program Files\Git\cmd\git.exe`). The repo is **initialised** at `D:\Exp\.git` and tracks `https://github.com/DDancingDeath/identityposc` (private). `gh` CLI is authed as **DDancingDeath**.

## 7. How to set up (run once)

```powershell
# 1. Install Python 3.11 and FFmpeg
winget install -e --id Python.Python.3.11
winget install -e --id Gyan.FFmpeg
# Open a NEW shell so PATH refreshes.

python --version    # should print 3.11.x
ffmpeg -version     # should print FFmpeg version

# 2. Create venv and install best-preset deps (after scaffold milestone produces requirements*.txt)
cd D:\Exp
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -U pip wheel
pip install -r requirements-best.txt
pip install -e .

# 3. (Optional) Enable pyannote diarization
#    a) Create a free HuggingFace account at https://huggingface.co
#    b) Visit and accept T&Cs for: pyannote/segmentation-3.0 and pyannote/speaker-diarization-3.1
#    c) Create a read token at https://huggingface.co/settings/tokens
#    d) Set env var:  $env:HF_TOKEN = "hf_..."
#    Without this, code falls back to SpeechBrain ECAPA — no auth needed, slightly worse.

# 4. Smoke test
python -m identityposc.main --help
```

## 8. How to run (once scaffold + pipelines exist)

```powershell
# End-to-end POC on the bundled sample
.\scripts\run_poc.ps1

# Or directly:
python -m identityposc.main --source data\sample\computer_chronicles_virtual_reality_1992.mp4 --preset best

# Against a real CCTV camera later:
python -m identityposc.main --source rtsp://user:pw@host:554/stream --preset fast

# Quality evaluation against hand-labelled ground truth:
.\scripts\run_eval.ps1

# Non-English source (e.g. Hindi → translate to English so existing English NER still finds names):
python -m identityposc.main `
   --source data\sample\bollywood\Sharmilee_1971_clip300s.mp4 `
   --db-path data\db\identities_bollywood.sqlite `
   --asr-language hi --asr-task translate

# Dashboard (defaults to config.yaml's db_path; override for non-default DBs)
python -m identityposc.dashboard.app   # → http://127.0.0.1:8000
python -m identityposc.dashboard.app --db-path data\db\identities_bollywood.sqlite
```

## 9. Conventions for agents working in this repo

- **Read `plan.md` (path in §2) before changing architecture.** The plan was reviewed and approved — significant deviations need a plan update first.
- **Update `todos` in SQL as you go.** Set status `in_progress` *before* you start; set `done` only when the milestone's stated acceptance criterion is actually met (run something, verify output).
- **Two presets, one code path.** When adding any model or threshold, expose it via `config.yaml` under both `best:` and `fast:` keys. Don't fork the call sites.
- **All persistent state goes through `src\identityposc\db.py`.** No bespoke pickle/JSON-on-disk stores; SQLite is the single source of truth so the dashboard can read consistent state.
- **Name-binding evidence must be auditable.** Every vote in `name_votes` must record (source_id, turn_id, timestamp, basis) so the dashboard's vote inspector can explain *why* a binding was promoted.
- **Don't break the `--source rtsp://...` code path.** Even though the POC drives from a file, the production goal is RTSP. `cv2.VideoCapture(url)` and `ffmpeg -i {url}` already accept both — keep it that way.
- **Privacy by default.** This repo handles biometric data (face embeddings) and conversational audio. Never log raw embeddings or transcripts to stdout in committed code. Thumbnails and DB stay on disk under `data\` and are gitignored.

## 10. How to add new sample videos

1. Pick a CC-licensed or public-domain source. Multi-speaker conversation with names spoken is gold.
2. Drop the file in `D:\Exp\data\sample\<descriptive_name>.<ext>` (mp4/mov/mkv all OK — FFmpeg handles them).
3. Append an entry to `D:\Exp\data\sample\NOTES.md` with: title, source URL, license, license URL, SHA256, why it's useful.
4. Re-run with `--source data\sample\<your-file>`.

## 11. Things explicitly NOT in scope for the POC

These are deferred to the production phase, not abandoned. Don't slip them into the POC:

- **Real-time throughput on this CPU.** Production target is real-time on a GPU box.
- **Multiple concurrent sources (5+ cameras at once).** Designed-for in plan §10; the POC
  exercises one source at a time. The persons DB is already shared across runs/sources.
- **GPU acceleration.** This VM has no usable GPU; the production shop deployment will.
- **Cloud / Pi deployment.** Designed to run on a single shop server.
- **Auth, encryption-at-rest, retention policy.** Required before the dashboard is exposed
  beyond `127.0.0.1`.
- **Mobile / push notifications.** *"Stranger detected"*, *"Ramesh just arrived"*, etc.
  — Phase 3 polish.
- **Robust handling of overlapping speech, far-field noise, low-light video.** Eval harness
  *measures* the impact; POC doesn't *fix* them.
- **Customer privacy / opt-out / GDPR-style data subject rights.** Biometric data falls
  under most regional privacy regimes. Required before any real-shop deployment.

## 12. Hard-won lessons (don't re-discover these)

These are gotchas that cost real iteration time. Read before touching the binder, eval, or any audio/face/name-vote logic.

### Sample data
- The Tears of Steel sample is **`tears_of_steel_720p.mov`** (NOT `.mp4`). Wrong extension → OpenCV `Could not open source` error that *looks* like path corruption.

### Binder (`fusion/identity_binder.py`) tuning
- **Anti-vote weight 0.25** (not 0.5). 0.5 was strong enough to retract legitimate addressee bindings (`spk4 → Tom` was lost when 0.665 - 0.95×0.5 dropped under threshold). 0.25 keeps anti-vote useful (still blocks self-naming) without nuking real signal.
- **Separate face threshold** (`name_bind_face_min_votes`, default 2.5× speaker threshold). Face votes are 1/N fractional AND systematically biased by reverse-shot cinematography (camera shows *listener* during the speaker's turn). A single mention with two faces visible will land 0.475 votes on each — easily clearing a 0.4 speaker threshold but binding the *wrong* face. Keep face bar at 1.0+ to require ≥2 mentions.
- **Epsilon tolerance in ratio comparison** (`>= min_ratio - 1e-6`). Floating-point arithmetic makes "exact 2:1 tie" land at 0.4999...8, not 0.5. Without epsilon, exact ties slip through.
- **Retraction** (`_maybe_promote` pops a binding when later votes make leader ambiguous or below threshold). Without this, an early happy-accident binding from a single vote is never re-evaluated.

### Eval harness (`eval/metrics.py`, `eval/report.py`)
- `bound_at` is hardcoded to 0.0 in `source_worker.py:444` (the live binder doesn't track promotion timestamps). TTFCB is computed by *replaying* `name_events` in time order in `replay_ttfcb` — keep replay logic in lock-step with production binder (anti-vote weight, ratio epsilon, face threshold, retraction).
- Eval credits face bindings via `av_link` votes (face → max-vote speaker → dominant person). With reverse-shot framing this *can* mark a face as the wrong person's. The face threshold change (above) prevents the binder from making such bindings in the first place.
- Read-only SQLite URI on Windows: `f"file:{p.as_posix()}?mode=ro"` then `sqlite3.connect(uri, uri=True)`. `as_posix()` is essential.

### Misc
- `templates.TemplateResponse(request, "name.html", {context})` — modern Starlette signature. `request` is the **first positional arg**, not in the context dict (old API → `TypeError: unhashable type: 'dict'`).
- Config attribute paths: `cfg.paths.db_path`, `cfg.pipeline.name_bind_*` (NOT `cfg.storage.*` / `cfg.fusion.*`).
- Fast preset deps: `webrtcvad-wheels` (prebuilt), `resemblyzer`. `resemblyzer` pulls in the *non-wheels* `webrtcvad` which transitively imports `pkg_resources` → pin `setuptools<81` to keep `pkg_resources` available, or replace with the wheels build.

### Diarization-fragmentation pathology (ECAPA fallback)
Without an HF token, ECAPA produces ~10 speaker clusters for ~3 real people in a 3-min clip. Per-cluster purity is 87.9% but mixed clusters (e.g. `spk4 = Tom + 1 Celia line`) invert addressee resolution. Real pyannote (with HF token) should reach ~80%+ F1 on this clip without further tuning.

### Reverse-shot cinematography problem
In 2-person dialogue scenes, the camera frames the *listener* while the speaker is off-screen. The AV linker assumes "speaker = on-screen face" → both faces in the scene get equal candidate weight → `own_faces` empty → both faces accumulate addressee votes for the *other* person's name. This is a fundamental algorithm limitation in cinematic content; CCTV (no reverse-shot conventions) is unaffected. The face-threshold tuning above prevents wrong bindings in this scenario.

### Cross-language sources via Whisper translate (Sharmilee 1971 finding)
Pipeline is fundamentally English-tuned (spaCy `en_core_web_trf` NER + English vocative regex), but **the cross-language path works well**: set `--asr-language hi --asr-task translate` (or any source language) and Whisper `large-v3` outputs English with **romanised proper nouns preserved** ("Kanchan", "Kamini", "Lily", "Naren"). The existing English NER then PERSON-tags those names and the binder votes normally.
- Both `Config`, `Preset`, `AudioPreset`, and `Paths` are `frozen=True`. To override at runtime: `dataclasses.replace(...)` to build a new instance, then `object.__setattr__(parent, "field", new)` to assign past the frozen check. Used by `main.py` (`--asr-language/--asr-task/--db-path`) and `dashboard/app.py` (`--db-path`).
- Whisper `large-v3` int8 on this CPU translates 5 min of 16 kHz Hindi WAV in ~7m20s.
- Bollywood result on Sharmilee 1971 (5-min clip from t=5:00): 19 name events, 79 votes, **2 bindings auto-promoted** (`spk#3 → Kanchan` 1.00, `spk#2 → Kanchan` 0.82). Other distinct names extracted but below the binding threshold: Kamini (votes=3.33 just under), Lily, Rupa, Naren/Narendra, Dwarka. False positives: "Daddy" (relationship word PERSON-tagged), "Don" / "Thank" (vocative_lead misfires on translated "Don't" / "Thank you").
- Future improvement for non-English sources: swap NER for a multilingual model (`xx_ent_wiki_sm`) and add language-specific vocative patterns (Hindi "X-ji", "X jaldi karo", etc.) so we can vote on the *original* language too. Not done in POC.

