# Build prompt — identityposc (next phase)

Paste this prompt to a coding agent to take identityposc from
POC-complete to a production-ready first deployment.

---

You are working on **identityposc**. The POC is **complete**; the live
code is at <https://github.com/DDancingDeath/identityposc>. Everything
needed to understand the system is in this folder.

## Step 1 — Load context (read in this order)

1. `../idea.md` — the why, in 1 page.
2. `../spec/README.md` — spec orientation + glossary.
3. `../spec/overview.md` — comprehensive README from the code repo.
   Includes architecture, presets, results, and the "Production: RTSP
   & multi-source scaling notes" section that **drives the next phase**.
4. `../spec/agents-orientation.md` — operational guardrails for code
   work (what to never edit, how the persons DB is layered, current
   status table).
5. `../spec/full-design.md` — the 62 KB source-of-truth design plan.
   Read §10 (multi-source scaling) and the persistent-persons sections
   end-to-end before designing the production architecture.
6. `../spec/preset-comparison.md` — why `best` is the default.
7. `../spec/config.yaml` — the tunables contract. Don't invent keys;
   add them here AND in the code repo in the same change.
8. `../plan/status.md` — what's done, what's known-broken, and the
   next-phase backlog.

## Step 2 — Confirm scope with the user before writing code

Ask:

- **What's the production target?** Single device + multi-camera on one
  host, or a small fleet?
- **GPU available?** If yes, `best` runs real-time per source and the
  `fast` preset is unnecessary. If no, decide on `fast`-live +
  `best`-offline-re-process or stick with single-camera.
- **HuggingFace token?** Required for real `pyannote.audio 3.1` (free
  account; biggest single quality win for the smallest code change).
- **Persons-DB retention policy?** Privacy controls are blocking before
  any deployment outside a single device.
- **OS target?** POC is Windows / Hyper-V; production may want
  Linux / systemd.

## Step 3 — Generate code in the live repo, NOT in this folder

- This `projects/apps/identityposc/` folder is docs-only. **Do not modify
  any file here** without explicit owner approval.
- All code goes to <https://github.com/DDancingDeath/identityposc> (or
  to `D:\identityposc` locally, which is the working clone).
- Any spec change you make in the code repo must be mirrored here in
  the same PR — keep `spec/config.yaml`, `spec/overview.md`, and
  `spec/full-design.md` in sync with the code repo's `config.yaml`,
  `README.md`, and the session `plan.md`.

## Step 4 — Build order (production phase)

Each step ships an artifact and an updated `plan/status.md` entry:

1. **HF token + real `pyannote.audio 3.1`**. Re-run the eval; update the
   results table in `spec/overview.md` (and the source repo's README).
2. **Cross-channel binder corroboration**: require face co-occurrence
   vote OR ≥ 2 distinct mentions. Re-run eval — both precision and
   recall must improve on the Sharmilee clip too, not just Tears of
   Steel.
3. **Privacy controls**: retention cap, per-identity opt-out, audit
   log. Block deployment outside the dev device until shipped. Add a
   `spec/privacy-design.md` here and in the code repo.
4. **Multi-source architecture**: one `SourceWorker` per camera, shared
   fusion service. SQLite WAL mode (Postgres only beyond ~10 sources).
   Inference service (gRPC or ZMQ) so models load once across workers.
5. **GPU path** (if available).
6. **RTSP watchdog** and **audio-drift anchoring** before any
   long-running deployment.
7. **Vocative stop-list + binder confidence floor**.
8. **Cross-camera re-ID** — only after multi-source is shipping.

## Quality bar

- Every change re-runs the eval harness. No metric regresses by more
  than 2 pts without a written justification in the PR.
- The "POC results" table in `spec/overview.md` stays current.
- All biometric data continues to be `.gitignore`d. No exceptions.
- The dashboard remains read-only and 127.0.0.1-bound until step 3
  (privacy controls) lands.

## What to NOT do

- Don't push biometric data, thumbnails, or `identities*.sqlite` files
  to any remote.
- Don't expose the dashboard to a network before the auth story is
  designed.
- Don't drop the `fast` preset until GPU `best` is real-time on the
  target host.
- Don't replace SQLite with Postgres before ~10 concurrent sources or
  a few GB of data — premature.
- Don't invent `config.yaml` keys. Add them in both repos in the same
  change.
