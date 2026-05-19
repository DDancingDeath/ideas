# Spec — identityposc

The source of truth for what to build.

## Reading order

1. **[`overview.md`](./overview.md)** — the comprehensive README from the
   live code repo. Covers idea, tech rationale, presets, POC results, and
   production scaling notes. Read first; it's the broadest single doc.
2. **[`agents-orientation.md`](./agents-orientation.md)** — the original
   `AGENTS.md` from the code repo. Read this before doing code work —
   it carries the operational guardrails (what to never edit, how to
   coordinate with the live persons DB, etc.).
3. **[`full-design.md`](./full-design.md)** — the **62 KB design plan**
   from the session that built the POC. This is the *source of truth for
   intent*: goal, scope, tech stack rationale, algorithm details, the 12
   milestones, the persistent-persons schema, fusion contract,
   evaluation harness design. Read end-to-end before any non-trivial
   design change.
4. **[`preset-comparison.md`](./preset-comparison.md)** — empirical
   justification for `best` as the default. Read when proposing a
   different default or pruning a layer.
5. **[`sample-data.md`](./sample-data.md)** — provenance, license, and
   suitability of every test clip. Read before adding new clips.
6. **[`config.yaml`](./config.yaml)** — the actual tunables file from the
   code repo. This is the contract between presets and the pipeline; do
   not invent keys.

## Glossary

- **TTFCB** — *time to first correct binding*. How long after pipeline
  start before a correct `speaker → name` link is promoted. Eval metric.
- **Binder** — the component that turns a stream of `(speaker, mention)`
  events into a `speaker → name` decision via per-speaker vote
  accumulation.
- **AV linker** — the component that decides, for each speaker turn,
  which on-screen face was talking (face/speaker co-occurrence).
- **Vocative** — a word used to address someone (*"Tom"* in *"Look,
  Celia, …"* is not a vocative; *"Celia"* is). The NER + vocative regex
  pair extracts these.
- **`best` / `fast` preset** — two model bundles sharing one code path.
  `best` = accuracy bar (POC default). `fast` = real-time bar.
- **Persons DB / per-run DB** — two-tier storage. Persons DB never
  resets; per-run DB is wiped each pipeline run. See
  `full-design.md` Phase 2.
- **SourceWorker** — one OS process per A/V source. Heavy on startup
  (loads ASR, detector, diarizer once), lightly stateful.
- **Fusion service** — single-process consumer of all SourceWorker
  events. Owns the global cluster state and the binder.

## Notes for agents

- The page-spec / per-page contract pattern that aadhat-management uses
  is NOT applicable here — identityposc has no UI pages. The dashboard
  is a single read-only view; its design lives in `full-design.md`
  Phase 8 and the live code under `src/identityposc/dashboard/`.
- `config.yaml` keys are the contract. If you need a new tunable, add
  it to `config.yaml` (in this repo too) AND to the code repo, in the
  same change. Drift here is the #1 source of subtle eval regressions.
- Numbers in `overview.md` (POC results table, preset comparison) are
  measured artifacts. If a code change moves them by more than ±2 pts,
  re-run the eval and update both this folder and the source repo.

## Out of scope (deliberately)

- Cross-camera re-ID. Embedding columns are preserved so it can be
  bolted on later without re-processing.
- Cloud / SaaS variants.
- Identity for access control or payments.
- Live wake-word.
