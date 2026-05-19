# POC: Shop-Floor Ambient Identity from CCTV + Mic

> **What this is, in one paragraph.** The user runs a shop. CCTVs with mics are already
> installed. This system watches+listens to the live feeds and answers *"who is in the
> shop right now?"* and *"who has visited in the past?"* — automatically learning who is
> who from how staff and customers address each other in conversation, with a manual-tag
> fallback in the dashboard for cases where auto-tagging fails. Two populations: a small
> set of **staff** (seen daily, names learned within days) and a long tail of
> **customers** (mostly transient, mostly never auto-tagged — fine; they live as
> *"untagged person #42, regular, last seen 3 days ago"* or *"untagged stranger"*).
>
> **POC scope.** This single Hyper-V VM with a redirected host camera + mic is one
> stand-in shop CCTV. The production system spawns one worker per camera and pours all
> of them into the same persistent persons DB.

---

## Phase 2.0 — GitHub repo init (immediate next action)

User wants the project published to **github.com/DDancingDeath/<repo-name>** with
`AGENTS.md` prominently included. `gh` CLI is already authenticated as DDancingDeath
(`repo` + `workflow` scopes).

### Decisions baked in (override via the review step)

| Item                  | Default                                                                                     |
|-----------------------|---------------------------------------------------------------------------------------------|
| Repo name             | **`identityposc`** (matches Python package name; short; SEO-neutral)                        |
| Visibility            | **Private** (handles biometric data + shop-internal context; can flip to public later)      |
| Description           | "POC: shop-floor ambient identity — learns who staff & customers are from CCTV + mic, no enrolment." |
| Default branch        | `main`                                                                                      |
| Initial commit author | repo owner's local git identity                                                             |
| License file          | None for now (POC; README §License says MIT but no `LICENSE` file shipped). Add in Phase 3. |
| Push scope            | Everything not in `.gitignore`. AGENTS.md is included by virtue of not being ignored.       |

### What will and won't be pushed (per the existing `.gitignore`)

**Pushed** (the project itself):

- `AGENTS.md`, `README.md`, `pyproject.toml`, `config.yaml`
- `requirements-best.txt`, `requirements-fast.txt`
- `.gitignore`
- `src/identityposc/` — entire tree including the new `persons.py`
- `scripts/` — entire tree (`run_live.ps1`, `run_poc.ps1`, `run_eval.ps1`, `setup_env.ps1`, `download_sample.py`, etc.)
- `data/sample/NOTES.md` (provenance only)
- `data/models/.gitkeep`, `data/thumbnails/.gitkeep`, `data/db/.gitkeep`
- `data/eval/` — schema and any non-PII reports

**NOT pushed** (already gitignored, biometric / large / regenerable):

- `.venv/`
- `data/sample/*` (sample MP4s — multi-GB, downloadable from `NOTES.md`)
- `data/models/*` (model caches — multi-GB, regenerable from requirements)
- `data/thumbnails/*` (face crops — biometric)
- `data/db/*` (SQLite identity DBs — biometric)
- `data/eval/groundtruth*.json`, `report.html`, `preset_comparison.html` (may contain PII)
- `.env`, `hf_token.txt` (secrets)

**To be added to `.gitignore` before first commit** (new dirs created during Phase 1
live-camera + Phase 2):

- `data/live/*` (live capture state.json + rolling mp4 segments + annotated frames)
- `data/persons/*` (persons DB + thumbnails — biometric, never push)

### Steps

1. **Confirm decisions** with user via `ask_user` (repo name, visibility — defaults shown
   above).
2. **Patch `.gitignore`** at `D:\Exp\.gitignore` to add `data/live/*` and `data/persons/*`
   exclusions plus their `.gitkeep` exceptions.
3. **Ensure `data/live/.gitkeep` and `data/persons/.gitkeep`** exist (so the empty dirs
   round-trip if anyone clones fresh).
4. **`git init -b main`** in `D:\Exp\`.
5. **Stage everything** (`git add -A`) and **dry-run review** (`git status --short` +
   `git diff --cached --stat`) so we can show the user what will land in commit #1
   *before* the commit happens.
6. **Commit** with message:

       chore: initial commit — shop-floor ambient identity POC

       Phase 1 complete (M1–M12 + live camera + Hindi).
       Phase 2 (persistent persons) in progress: persons.py module landed,
       dashboard wiring pending.

       See AGENTS.md for orientation and plan.md (session workspace) for full design.

       Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>

7. **Create remote** with `gh repo create DDancingDeath/<name> --private --source=. --description "..." --remote=origin` (this both creates on GitHub and adds the remote in one step).
8. **Push** `main` (`git push -u origin main`).
9. **Verify** by fetching the repo URL via `gh repo view --web` (don't open browser, just print URL) and listing the remote tree (`gh api repos/DDancingDeath/<name>/contents`) confirms `AGENTS.md` is present at the root.
10. **Update plan.md status table** marking Phase 2.0 complete and noting the repo URL.
11. **Then resume Phase 2 implementation** (P2.2 → P2.7) per the section below.

### Status: ✅ DONE 2026-05-09

- Repo: **https://github.com/DDancingDeath/identityposc** (private)
- Default branch: `main`, tracking `origin/main`
- Initial commit `a315caf` — 58 files, 340 KB
- AGENTS.md verified at root (21,348 bytes)
- `.gitignore` extended for `data/live/*` and `data/persons/*`
- Followups queued in SQL: `bug-binding-votes-attr` (live8 crash), `quality-yuck-binding` (false binding)

### Decisions confirmed by user

- **Repo name:** `identityposc`
- **Visibility:** Private
- **Action:** Awaiting plan-mode exit to execute steps 2–11.

### Side-channel (noted, not a blocker)

- `live8` (Hindi live capture, PID was running ffmpeg 32984 + python) **exited at chunk
  244** (~40 min of audio processed) with `AttributeError: 'Binding' object has no
  attribute 'votes'` in `_rerun_name_binder` at `live.py:899` (the rebuild path that
  re-runs the binder per chunk). Dashboard PID 19684 is **still alive** —
  `http://127.0.0.1:8000` works and the live DB has 86 turns + 611 face obs +
  3 mis-promoted `speaker#11 → 'Yuck'` bindings to play with. Will tackle as a follow-up
  bugfix once Phase 2 wiring is done; not blocking repo init.

---

## Phase 2 — Persistent Persons (✅ DONE 2026-05-09)

> Added after Phase 1 (M1–M12 + live-camera + live-Hindi) was complete and we
> started exercising the live demo with real humans in front of the camera.
> Phase 2 is **the keystone for the shop use case** — without persistent
> person identity, neither *"who's here right now"* nor *"who came last
> week"* is implementable.

### Status: ✅ DONE 2026-05-09 — pushed as `6f1601d` (feat) + `14c44b6` (bugfix follow-up) on https://github.com/DDancingDeath/identityposc

What shipped (all P2.0–P2.7 + 2 follow-up bugs):

* **`persons.py` module** at `src/identityposc/persons.py` — separate sqlite at
  `data/db/identities_persons.sqlite`, idempotent `sync_from_faces_db()`,
  weighted centroid merge, name-adoption-by-confidence (manual conf=1.0 wins
  over any auto-binding).
* **PEOPLE panel** in the dashboard above the existing "Identified People" panel
  — one card per real human with thumbnail, name (or `person #N`),
  session/cluster/obs counts, last-seen relative timestamp, blue glow when in
  current frame, manual-tag form (caret/draft preserved across the 1.5 Hz
  re-render).
* **In-frame collapse** — the "Currently in front of camera" panel now groups
  `faces_in_frame` by `face_to_person` mapping; one card per person, fallback
  to per-face when no mapping exists.
* **Manual-tag UI** — POST `/persons/{id}/name` with confidence 1.0; module-
  level Pydantic model + `Body(...)` to satisfy pydantic v2 + FastAPI; backed
  by validated 200/400/404 paths.
* **CLI knobs** — `--persons-merge-threshold` (default 0.35; recommend 0.25
  for `buffalo_s`) and `--persons-rebuild` on the dashboard module; per-poll
  sync threshold override plumbed through `_state_snapshot()`.
* **Cross-run continuity proven** by a wipe-restore simulation: 19 persons
  (including manually-tagged `'Hik'`, conf=1.0, 3959 obs) survived a complete
  `identities_live.sqlite` reset; dashboard kept serving them through the
  wipe and the restore.

Three follow-up bugfixes shipped same day:

* **`templates/index.html` (`e4db80c`)** — when adding `renderPeople`,
  `formatRelative`, `submitPersonName` between the bindings loop and the
  Identified People loop, an extra `}` was inserted right after the
  `renderPeople(...)` call. That brace closed `render()` ~150 lines too
  early, so Identified People / Face Clusters / Speaker Clusters / AV
  Links / Name Votes / Name Events became top-level code referencing the
  `state` parameter that doesn't exist in module scope → `ReferenceError`
  on parse → entire `<script>` died → user saw all panel headers but
  zero data and "last poll: never". Fix: remove the orphan `}`. The new
  functions are now nested inside `render()` (legal in modern JS; the
  form's `onsubmit` captures `submitPersonName` by closure each tick).
  Verified with `node --check`: 220 open / 220 close braces, no parse
  errors. Hard-refresh (Ctrl+F5) restores the full dashboard.

Two earlier follow-up bugfixes shipped same day in `14c44b6`:

* **`live.py:899`** — `_rerun_name_binder` was reading `Binding.votes` (the
  attribute is `votes_at_promotion`) and inserting into a non-existent
  `votes` column on the `bindings` table. Aligned with `source_worker.py:461`
  which uses the canonical 5-column INSERT. Crash that killed live8 at
  chunk 244 (~40 min in) is now fixed.
* **`fusion/name_extractor.py`** — added `Yuck`, `Yum`, `Yummy`, `Ouch`,
  `Ugh`, `Eh`, `Aha`, `Aw`, `Aww`, `Whoa`, `Phew`, `Huh`, `Wah`, `Arre`,
  `Oye`, `Achha`, `Bas`, `Acha`, `Haan` to `_BLOCKLIST` so Whisper-translate
  output of Hindi/English interjections never auto-promotes as identities.
  Verified: extractor returns `[]` for `'Yuck, that smells bad.'` /
  `'Wah, kya baat hai.'` and still returns `['Sarah']` / `['Hik']` for real
  vocative sentences.

**Honest caveat surfaced in dashboard hint text:** with `buffalo_s` (fast
preset) the embeddings can't separate cleanly enough to collapse 61 face
clusters into 2–3 humans. Top 3 persons cover 24 face clusters but a long
noise tail remains. To hit the original "26 raw → 2-3 humans" demo target,
re-run live with `-Preset best` (`buffalo_l` / R100 ArcFace). The manual-tag
UI is the always-works fallback for the shop scenario.

---

## Phase 2.5 — Manual person merge (✅ DONE 2026-05-09 — `6237caa`)

> Follow-up to Phase 2 after the user pointed out that the same person was
> showing up as multiple cards even after the auto-merge sync. The honest
> caveat above ("buffalo_s can't collapse cleanly") is now actionable — the
> user can merge duplicates themselves with one click.

### Status: ✅ DONE — pushed as `6237caa` on https://github.com/DDancingDeath/identityposc

What shipped:

* **`persons.merge_persons(src_id, dst_id)`** — moves all `person_face_links`
  from src to dst (idempotent via INSERT OR REPLACE), recomputes the dst
  centroid as the sample-weighted mean of both centroids (already
  unit-normalized so the average is too), sums `sample_count` and
  `member_face_count`, unions `run_sources`, picks the higher-confidence
  name (manual conf=1.0 wins over any auto-binding), inherits dst's
  thumbnail or src's as fallback, then deletes src. Validates src≠dst
  (ValueError) and that both ids exist (LookupError).

* **POST `/persons/{src_id}/merge_into/{dst_id}`** in `dashboard/app.py` —
  wraps the call inside `persons_lock`; LookupError→404, ValueError→400.
  Returns `{ok, src_id, dst_id, merged_links, dst_sample_count, dst_members}`.

* **PEOPLE panel UI** in `templates/index.html` — each card grows a
  `merge → #` form with a number input + small "merge" button at the
  bottom (dashed top border, warn-color hover). Submitting opens a
  `confirm()` dialog showing the target person's name (if any) so the
  user can sanity-check before the destructive merge.

* **`run_live.ps1`** — new `-PersonsMergeThreshold` param (default 0.25,
  tuned for buffalo_s; bump to 0.35 for buffalo_l/best) and
  `-PersonsRebuild` switch, both forwarded to the dashboard process.

### Lesson learned (the data-loss incident)

While testing the merge endpoint via HTTP, I:

1. Restarted the dashboard at the wrong threshold (default 0.35 instead
   of the user's preferred 0.25) — this in itself doesn't lose data, but
   means the live runner's incoming face_ids get synced at 0.35 and
   create more fragments.
2. Snapshotted `identities_persons.sqlite` to `_pre_merge_test.sqlite`
   AFTER the wrong-threshold restart had already begun mis-syncing.
3. Ran the merge tests, then restored from the snapshot — restoring to a
   state that already had 44 fragmented persons and (somehow) had lost
   the manual `Hik` tag on pid=1 (the conf=1.0 manual tag should never
   be auto-overridden — the loss is unexplained but reproducible enough
   to be a real bug, possibly from a SQLite transaction race).

**Outcome**: had to rebuild the persons DB at 0.25 (`--persons-rebuild`),
giving 21 clean persons (was 19; +2 from new live obs), and re-tagged
pid=1 as `Hik` via the API. State restored to user-visible parity.

**Takeaways baked into the code**:

- `run_live.ps1` now defaults `-PersonsMergeThreshold 0.25` so the user
  doesn't have to remember the override.
- For future destructive operations on the persons DB: use `--persons-rebuild`
  rather than snapshot/restore — the sync logic is idempotent and
  authoritative.
- Manual tags survive a `--persons-rebuild` only via re-tagging through
  the UI; if we want true durability, manual tags should be exported to
  a separate file and replayed on rebuild. Tracked as a Phase 3 polish
  if it bites again.

---

## Phase 2.6 — Live-frame overlay shows manual person tag (✅ DONE 2026-05-09 — `8358e43`)

> Follow-up to Phase 2.5 the same hour: user tagged themselves as `Hik` on
> pid=1 but the green box on the live frame still said `face#62 78%`. The
> in-frame label was looking only at the conversational binder's name map,
> which has no idea about manual person tags from the persons DB.

### What shipped

* `LivePreview` gained an optional `get_person_name_overlay` callable.
* `LiveRunner._get_person_name_overlay()` opens the co-located persons
  DB read-only and returns `{face_id: person.name}` for any face
  linked to a named person via `person_face_links`.
* In `_loop`, the binder name map and the persons-overlay map are
  merged with persons-overlay taking precedence — manual tags carry
  conf 1.0 and override anything the binder might say.
* Cached for 2 s so the 4 fps preview doesn't beat on SQLite.

### Lesson learned

Path normalization: dashboard writes `source_db = str(db_path.resolve())`
(absolute) but live runner was originally querying with relative path.
Silent mismatch → empty join → empty overlay map. Fixed by also calling
`.resolve()` in the live runner. Any new `source_db` consumer must use
the same canonical form.

---

## Phase 2.7 — Whisper-hallucination guard + manual-tag visibility (✅ DONE 2026-05-09 — `5b8101e`)

> Triggered by user observation: dashboard showed a phantom **"Ashley
> speaker#34 100% conf"** card in IDENTIFIED PEOPLE with two dim face
> thumbnails (#99, #113) and dialogue like *"I'm scared of them"*, *"Mom,
> you're the one"* — while the user themselves was on camera tagged as
> **Hik** in WHO IS IN FRONT.

### What was actually happening (the chain of failure)

1. Hyper-V VM mic catches faint room audio (TV / system audio bleeding in).
2. Whisper `small` (multilingual fast preset) hallucinates on noisy /
   silent stretches. Stats from run #6: **240 of 309 turns had
   `asr_avg_logprob < -0.7`** (78%); only 1 turn rated logprob > -0.3.
   Classic Whisper failure mode: repeats short phrases ("Mom." × 14,
   "What?" × 13, "I'm the one!" × 5).
3. **One hallucination was the lone token `'Ashley?'`** (turn 263,
   speaker=30, logprob=-0.95). NER picked it as PERSON.
4. Vocative addressee logic bound it to the next speaker (speaker #34)
   within the recent-window of 20 s.
5. AV-linker found dim-Hik faces #99 and #113 visible during speaker #34's
   turns → those became candidate face thumbnails on the Ashley card.
6. `name_bind_min_votes = 0.4` (very permissive) — the single 0.63 vote
   (= 0.9 conf × ~0.7 inverse-distance weight) cleared the bar trivially.

Faces #99/#113 ARE Hik in low light, but `buffalo_s` (fast preset) couldn't
see it: cosine to Hik centroid (face #89) was 0.18 / 0.05. So they sat in
their own tiny person clusters (pid=11, pid=29) and got attached to
Ashley's card by AV co-occurrence rather than by face similarity.

### What shipped

* **`config.yaml`** — two new knobs and two threshold bumps:
  - `name_extract_min_logprob: -0.7` (NEW) — turns below this are skipped
    for name extraction.
  - `name_extract_max_repetition: 3` (NEW) — Whisper-loop guard; N+
    adjacent same-speaker turns with identical normalised transcripts
    are dropped together.
  - `name_bind_min_votes: 0.4 → 1.0` — forces ≥ 2 mentions to promote a
    speaker→name binding.
  - `name_bind_face_min_votes: 1.0 → 2.5` — face votes are 1/N-weighted
    AND reverse-shot biased; need a higher absolute bar to avoid
    promoting on a single mention with two faces visible.

* **`config.py`** — `PipelineKnobs` gained `name_extract_min_logprob` and
  `name_extract_max_repetition`; loader parses both with the same defaults
  so missing-from-yaml configs still work.

* **`fusion/name_extractor.py`** —
  - `NameExtractor.extract()` stays text-only; turn-level gating now lives
    in `filter_turns_for_extraction(turns, min_logprob, max_repetition)`.
    The helper returns a parallel keep-mask with both filters applied.
    Sorts by `t_start` internally so the burst detector groups properly
    even if the caller gave a different order.

* **`live.py` + `source_worker.py`** — both call sites build the
  keep-mask before iterating, log a one-liner showing how many turns
  were dropped (and why), then skip extraction on dropped turns. The live
  CLI and `scripts\run_live.ps1` now default to `best`; `fast` is an
  explicit override only.

* **`dashboard/app.py`** — IDENTIFIED PEOPLE used to show only entries
  derived from the `bindings` table (auto-learned names from
  conversation), so manually-tagged persons (e.g. user-tagged "Hik" with
  conf=1.0) were absent. Now after the bindings loop, the snapshot
  walks the persons table and synthesizes an `identified` entry for any
  named person whose face_ids appear in `face_to_person` for the
  current run. Uses `target_kind = "person"` so the source is
  distinguishable from auto-bound `speaker` / `face` entries.

### Verified

- Smoke tests in `name_extractor.py`:
  - direct `extract()` still sees short names (`'Ashley?'` → `['Ashley']`)
    as expected; the turn-level filter is what blocks hallucinated turns.
- `filter_turns_for_extraction` smoke test: low-logprob turn dropped,
  3-burst of `"Mom."` from same speaker dropped, real turns kept ✓
- DB cleanup: deleted 1 binding, 2 votes, 1 name_event for Ashley.
  Underlying turn 263 (`'Ashley?'`, logprob=-0.95) preserved — won't
  re-hallucinate because the extractor filter now blocks it.
- Live restart: `current_run_id = 7`, 0 spurious bindings, identified[]
  contains exactly `Hik → person#1` (25 faces) and no Ashley.

### Lessons

- **Don't trust ASR confidence is implicitly high in production audio.**
  The HF / mic / VM stack delivers gain ~30 dB below studio levels and
  Whisper happily fills the gap with plausible nonsense. Any downstream
  consumer that treats Whisper output as ground truth (NER, intent
  classifiers, name binders) needs a hard logprob floor.
- **Default thresholds optimised for clean offline corpora are too
  permissive for live capture.** The original 0.4-vote threshold made
  sense on the 3-min Tears of Steel evaluation clip (sparse name
  mentions, clean studio audio); on the live mic with noise + 78%
  hallucinated turns it's a footgun.
- **Two views of "who do we know" must reconcile.** When the user can
  manually tag identities AND the system auto-learns identities, a
  panel called "IDENTIFIED PEOPLE" must show both — anything less makes
  the user doubt the manual tag took effect.



> Follow-up to Phase 2.5 the same hour: user tagged themselves as `Hik` on
> pid=1 but the green box on the live frame still said `face#62 78%`. The
> in-frame label was looking only at the conversational binder's name map,
> which has no idea about manual person tags from the persons DB.

### Status: ✅ DONE — pushed as `8358e43`

What shipped:

* `LivePreview` gained an optional `get_person_name_overlay` callable,
  defaulting to a no-op (preserves old test contracts).

* `LiveRunner._get_person_name_overlay()` opens the co-located persons
  DB (`cfg.paths.db_path.parent / "identities_persons.sqlite"`)
  read-only, queries `person_face_links JOIN persons WHERE name IS NOT
  NULL AND source_db = ?`, and returns `{face_id: person.name}`.

* In `_loop`, the binder name map and the persons-overlay map are
  merged with persons-overlay taking precedence — manual tags carry
  conf 1.0 and override anything the binder might say.

* Cached for 2s so the 4 fps preview doesn't beat on SQLite. Errors
  are debug-logged, never crash the preview.

### Lesson learned (path normalization)

The first cut of the overlay returned an empty map. Cause: the
dashboard writes `source_db = str(db_path.resolve())` (absolute) into
`person_face_links` during sync, but the live runner was querying with
`str(self._db_path)` (relative). Silent mismatch — the join produced
zero rows.

**Fix**: live runner now uses `str(self._db_path.resolve())` to match.
**Takeaway**: any new code that joins on `source_db` must use the same
canonical form. Worth promoting to a tiny helper if a third
`source_db` consumer ever appears.

### What the user sees now

Within 2s of either (a) tagging a person manually, or (b) the
persons-sync auto-merging a new face_id into a named person's cluster,
the live frame's green-bordered label flips from `face#NN xx%` to the
person's name. No restart needed.

### What you're actually trying to build (the shop framing)

The dashboard today shows two things you don't really care about as a human:

* **Face detections** — one bounding box per frame, with a per-frame `face_id`.
* **Face clusters** — within a single live run, the in-memory clusterer groups
  similar embeddings into `face #N`. With the `fast` preset's small face model
  (`buffalo_s`), this **massively over-fragments**: in the current live run
  you and one child have produced **26 face clusters** for two actual humans
  (you appear in face #5, #25, #7, #1, #3, #23, #2, #4, #15, #16, #17, #18, #22;
  the child in face #10, #12, #21, #9, #13, #19, #8, #14, #20, #24, #6).

What you actually want is a third layer **on top** of those:

* **Persons** — distinct *human beings*. Persistent across runs. The thing the
  POC was always supposed to be about ("a dynamic name database of people").

The three concrete properties a person must have:

1. **One card per real human, not per cluster.** Many noisy clusters of the
   same face merge into one person card with a single representative
   thumbnail, total observation count, and (when learned) one bound name.
2. **History survives DB resets.** Each `run_live.ps1` resets the per-run
   DB; persons live in their **own** DB at `data/db/identities_persons.sqlite`
   that is **never** wiped. Switching presets, sources, or restarting the
   capture all preserve the gallery.
3. **Re-recognition on return.** If the same human walks back in front of the
   camera tomorrow (or next week), the system finds the existing person record
   by centroid similarity and updates it ("last seen 2 days ago, seen across
   3 sessions") rather than creating a fresh stranger.

When a name is bound to one of a person's member faces (via the existing
vocative-addressing pipeline), the *person* inherits that name — and keeps it
across all future runs.

### Architecture (3 layers)

```
                                                                       persists
                                                                       across
                                                                       restarts?
   (per frame)        (per run)              (forever)
   ┌─────────────┐    ┌─────────────────┐    ┌─────────────────────┐
   │ detections  │ →  │ face clusters   │ →  │ persons             │   ✓
   │ face_id N   │    │ face #M         │    │ person #P           │
   │ (1 per box) │    │ (1 per merged   │    │ (1 per human, ever) │
   │             │    │  embedding      │    │                     │
   │             │    │  group within   │    │ + name (when bound) │
   │             │    │  this run)      │    │ + run_count         │
   │             │    │                 │    │ + first_seen / last │
   └─────────────┘    └─────────────────┘    └─────────────────────┘
        |                    |                       ↑
        |                    └── merge by centroid sim ≥ 0.50
        |                        (idempotent, runs on every dashboard poll)
        └── live runner writes face_obs into per-run DB (unchanged)
```

* **Detections + clusters** = unchanged from Phase 1. The live runner keeps
  doing what it does and writes to `identities_live.sqlite` per run.
* **Persons** = a separate sqlite DB and code module
  (`src/identityposc/persons.py`, just created). Sync is idempotent — every
  call merges only the face rows that haven't been linked yet.
* **Sync trigger** = whenever the dashboard polls `/api/state` (cheap,
  read-mostly, already happens every ~1.5 s). No live-runner restart required.

### What done looks like

A new **PEOPLE** panel appears on the dashboard above the existing
"FACE CLUSTERS" panel. Each card shows:

* Representative thumbnail (the best member face)
* Name (if any cluster of this person was ever bound)
* Sessions seen / total observations / first-seen date / last-seen date
* "in this run: N member faces" badge if currently active

Concrete success demos:

1. Right now (live8 still running) — refresh the dashboard and see ~2-3
   PEOPLE cards instead of 26 face clusters. (Adult + child + maybe one
   noise-driven third.)
2. Stop the run, start a new one — the PEOPLE panel still shows you, with
   "last seen: 1 minute ago, 2 sessions". The faces panel resets to empty
   and re-fills.
3. Once a name binds (e.g. you say "Hik" enough times into the mic), the
   person card carries the name forward into every subsequent run.

### Implementation plan (Phase 2)

| ✓ | Step                                                                                       |
|---|---------------------------------------------------------------------------------------------|
| ✅ | **P2.1** — `src/identityposc/persons.py` written: schema, idempotent sync, weighted centroid merge, thumbnail copy into `data/persons/thumbs/`, listing helpers. |
| ⏳ | **P2.2** — Wire `persons.sync_from_faces_db(...)` into `dashboard/app.py`'s `_state_snapshot`. Open persons DB R/W (separate connection from the read-only faces conn). Add `people` and `face_to_person` to the JSON response. |
| ⏳ | **P2.3** — Add `/persons/{person_id}/thumb.jpg` endpoint and a `PEOPLE` panel in `templates/index.html` above `FACE CLUSTERS`. Render: thumbnail, name (if any), # sessions, # obs, first/last seen, "in current run" badge. |
| ⏳ | **P2.4** — In the existing "Who is in front of the camera" panel, collapse two `faces_in_frame` entries that map to the same person into a single card showing the person name (or person #P) — fixes the "two thumbnails both labeled face #5" oddity from earlier. |
| ⏳ | **P2.5** — Restart the dashboard process only (PID 19684). Live capture (`live8`) keeps running untouched. Verify on `http://127.0.0.1:8000`: PEOPLE card count drops from 26 → ~2-3 for the current run. |
| ⏳ | **P2.6** — Stop and restart `run_live.ps1` to verify cross-run continuity: PEOPLE cards survive the live-DB reset, last-seen timestamp updates when the same face reappears. |
| ⏳ | **P2.7 — Manual-tag UI on PEOPLE cards.** First-class for the shop use case (most customers will never get a name auto-bound). Each untagged PEOPLE card grows a small text input + "save" button. Submitting POSTs to `/persons/{person_id}/name` which writes `manual_name`/`manual_name_at` columns on the `persons` table. Manual name takes precedence over auto-bound name in the UI. Tagged persons show their name with a small ✎ pencil to re-edit. Server-side validation: 1–60 chars, strip + collapse whitespace, reject empty. No deletion in v1 — wrong manual tag is fixed by editing, not removing. |

### Tunables introduced

| Knob                           | Default | Why                                                     |
|--------------------------------|---------|---------------------------------------------------------|
| `merge_threshold` (cosine sim) | 0.50    | Same-person bar with `buffalo_s`. Lower = merge more aggressively (risk: cross-person merges). Higher = keep fragmenting. Tune after eyeballing the PEOPLE panel. |

### Explicit non-goals for Phase 2

* **No backfill into the live runner.** The live runner doesn't write to or
  read from the persons DB. The persons layer is a *view* assembled at
  dashboard time. Keeps the runner crash-safe and unchanged.
* **No automatic person-id renaming.** The existing `bindings` table is still
  the source of truth for auto-bound names. Persons just adopt the name of
  any bound member face. Manual names are a separate column — see P2.7.
* **No person-merge UI.** If two PEOPLE cards turn out to be the same human
  (because cross-angle similarity is below threshold), we accept it for now.
  A "merge persons" button is a Phase 3 polish.
* **No person-deletion / person-split UI.** Mistaken merges (two different
  humans collapsed into one card) need a manual SQL fix in v1. Phase 3.
* **No identity export / import.** The persons DB is self-contained on this
  device.
* **No "is this a stranger?" alerting.** *"Stranger appeared in the shop"*
  notifications, *"Ramesh just arrived"* push, etc. — natural Phase 3
  features once persistent persons are in place, but explicitly not Phase 2.
* **No customer-vs-staff distinction in the data model.** Both are just
  "person rows". UI may eventually surface a "regular" badge based on visit
  count; that's a render-time computation, not a schema column.

### Open questions for you to confirm

These are the assumptions I'm making — flag any you'd change:

1. **One persons DB for everything.** All sources (camera, file replay, RTSP)
   pour into the same `identities_persons.sqlite`. Same human shot from CCTV
   and from a mobile clip get merged if they look similar enough. Sound right?
2. **Merge threshold = 0.50.** Optimised for `buffalo_s` (the noisier small
   face model in `fast` preset). With `best` (`buffalo_l` / R100 ArcFace),
   the same threshold should be *more* conservative — we can leave it at 0.50.
3. **No deletion / TTL.** PEOPLE rows live forever. Mistaken merges (two
   different humans collapsed) will need a manual SQL fix. OK for the POC?
4. **Thumbnail = first acceptable member face crop.** Whichever face was the
   seed of the person owns the thumbnail. We don't try to pick the
   "best-looking" frame. OK?
5. **Names propagate person → all future runs.** Once any cluster of this
   person is bound to "Hik", every future run shows them as "Hik" in the
   PEOPLE panel even before any name is spoken in that new run. Yes?

---

## 1. Goal

Build a proof-of-concept that ingests one A/V source (video file for POC, RTSP-ready for production) and demonstrates the full value chain end-to-end on a single Windows machine, CPU-only, using only free / open-source components:

1. Detect and recognise faces appearing in the video.
2. Transcribe the audio and assign each utterance to a *speaker cluster* (anonymous IDs at first).
3. Detect when one speaker addresses another by name (e.g. "Thanks, **Sarah**.") and use that signal to bind a real name to a speaker cluster — and, by co-occurrence, to a face cluster.
4. Persist these bindings in a small local "name database" that grows over time and survives restarts.

The novel idea — *learning identities from how people address each other* — is the focus of the POC. Everything else (multi-camera scaling, GPU acceleration, production dashboards) is explicitly deferred.

**Quality bar for this POC:** *best achievable accuracy on this single device over a ~1-month exploration window*. Real-time throughput is **not** a requirement here — we may run the pipeline at 0.2–0.5× real-time during the POC if it materially improves face / speaker / name accuracy. If the binding accuracy is convincing at the end of the month, we plan a follow-on phase (multi-camera, GPU, real-time, production hardening). If it isn't, the work product is still a fair, measured assessment of why — captured in §8's quality-evaluation step.

## Implementation log (live)

| ✓ | Item                                                                                            |
|---|-------------------------------------------------------------------------------------------------|
| ✅ | Plan written and approved                                                                       |
| ✅ | `data/` directory tree created at `D:\Exp\data\{sample,models,thumbnails,eval,db}\`             |
| ✅ | Sample videos downloaded + verified: Computer Chronicles VR (154 MB) + Tears of Steel (355 MB)  |
| ✅ | `D:\Exp\AGENTS.md`, `data\sample\NOTES.md`, `.gitignore` written                                 |
| ✅ | Python 3.11 + FFmpeg installation                                                                |
| ✅ | M1 scaffold (project layout, CLI, requirements, config, setup script)                            |
| ✅ | M2 deps + sample (venv, all models pre-cached, smoke tests pass)                                 |
| ✅ | M3 video pipeline (SCRFD-10G + ArcFace R100 + tracker + online clusterer + thumbnails)           |
| ✅ | M4 audio pipeline (Silero VAD + faster-whisper large-v3 int8 + ECAPA fallback diarization)       |
| ✅ | M5 schema + persistence (SQLite DAO; runs/faces/speakers/turns/votes/bindings)                   |
| ✅ | M6 AV-fusion (fractional 1/N voting; ratio + absolute-margin lock; 3 locks on 3-min ToS)         |
| ✅ | M7 name binding (spaCy trf NER + vocative regex + multi-candidate addressee voting + promotion). FIRST CORRECT BINDING: `speaker#5 -> Tom (votes=1.33, conf=0.67)` on a 3-min Tears of Steel slice. |
| ✅ | M8 FastAPI dashboard (live transcript with speaker tags, face thumbnails, name DB, vote inspector, av-link inspector — `http://127.0.0.1:8000`) |
| ✅ | M9 eval harness — final result on ToS 180 s `best`: **F1=80%, P=66.7%, R=100%, TTFCB=24.5 s, extraction P/R=100%, speaker purity 87.9%**. Tuning journey: anti-vote weight 0.25 (kills self-naming without nuking real signal), separate face threshold 1.0 (defeats reverse-shot bias), epsilon ratio comparison (catches floating-point ties), retraction (re-evaluates after later votes). |
| ✅ | M10 best-vs-fast comparison — `best` 80% F1 vs `fast` 0% F1 on the same clip; `fast` mis-transcribes 2/3 vocative mentions; report at `data/eval/preset_comparison.md`. |
| ✅ | M11 end-to-end demo + README write-up — README §POC results captures bindings, mentions, dashboard transcript, and month-end go/no-go assessment. |
| ✅ | M12 RTSP + multi-source notes — README §Production: RTSP & multi-source scaling notes. |
| ✅ | **Cross-language run (Sharmilee 1971, Hindi → English `translate`):** new CLI flags `--asr-language/--asr-task/--db-path`; new `AudioPreset.asr_task`; dashboard gained `--db-path`. Bollywood DB at `data\db\identities_bollywood.sqlite`: 7 speakers, 37 faces, 93 turns, **19 name events extracting 7 distinct character names** (Kanchan, Kamini, Lily, Naren/Narendra, Rupa, Dwarka — all real characters), **2 bindings auto-promoted** (`spk#3 → Kanchan` conf=1.00, `spk#2 → Kanchan` conf=0.82). Confirms the pipeline is functionally cross-language with no algorithm changes — only NER+vocative are English-tuned, and Whisper `translate` puts romanised names into English text where the existing extractor finds them. |
| ✅ | **Live A/V module (`identityposc.live` + `scripts\run_live.ps1`)** — captures from a live dshow camera+mic via Hyper-V Enhanced Session redirect (`Surface Camera Front (redirected)` + `Remote Audio`). Dual-output ffmpeg writes (a) rolling 10s mp4 segments AND (b) 5fps `current.jpg`. Background `LivePreview` thread overlays face boxes onto `current_annotated.jpg`. Persistent in-memory clusterers accumulate across chunks; binder is re-run idempotently each chunk via `DELETE name_events/votes/bindings WHERE run_id=?` then re-insert. |
| ✅ | **Live dashboard panel** — `/live/frame.jpg` (4 fps `<img>` cache-bust) + `/live/state.json` (1.5 Hz JSON poll) endpoints. Index page now shows: properly-sized 540×405 camera tile, "Who is in front" with face thumbnails, "Recent transcript" rolling list (last 12 lines, newest-first, relative timestamps). Whisper hallucinations filtered (`no_speech_prob > 0.6` OR `avg_logprob < -1.0` OR known stock phrases like "thank you" / "subtitles by amara.org"). |
| ✅ | **Live runner robustness** — `_preflight_dshow()` checks camera+mic presence before spawning ffmpeg and prints a clear remediation message naming the missing device + how to re-enable RemoteFX USB redirection. Duration cap (`--duration N`) is enforced from Python via `CTRL_BREAK_EVENT` to ffmpeg (the `-t` flag interacts badly with the dual-output dshow setup). `_cleanup` writes `{"active": false}` tombstone so the dashboard hides the live panel between runs. |
| ✅ | **Live audio gain (dynaudnorm)** — Hyper-V "Remote Audio" device pipes host mic into the VM at catastrophically low gain (measured: mean -47.8 dB, max -26.3 dB; whisper VAD threshold ~-30 dB). Added `-af dynaudnorm=p=0.95:m=15:s=12` to ffmpeg's segment-output audio chain — post-fix mean -19.5 dB, max -0.8 dB, normal speech levels confirmed via `volumedetect` on a finalised mp4. |
| ✅ | **Live Hindi support** — `fast` preset's `asr_model` swapped from `small.en` (English-only) to `small` (multilingual). `run_live.ps1` extended with `-AsrLanguage` / `-AsrTask` flags forwarded to `python -m identityposc.live`. Live with Hindi: `.\scripts\run_live.ps1 -Duration 0 -AsrLanguage hi -AsrTask translate`. Whisper's internal `vad_filter` disabled in `fast` preset (Silero already pre-VADs; second layer over-rejected low-gain audio — produced 0 segments per chunk despite Silero finding 5–7s of voice). |

### Status as of pause point

- All 12 milestones (M1–M12) plus live-camera + live-Hindi are functionally complete.
- **Operational reality of the live demo on this Hyper-V VM:**
  - The mic captures from across the room (host's Surface mic, redirected). Even with dynaudnorm, signal is faint relative to ambient noise. User must speak loudly toward the host machine for Whisper to make sense of the audio.
  - The camera is a fixed-position Surface camera. User must sit physically in front of the host machine for faces to register — speaking off-camera produces audio events but zero face observations.
  - Whisper `small` translate from Hindi → English is good enough to catch romanised names (proven on Sharmilee 1971 → 7 distinct character names) when audio quality is decent. With faint room-mic audio, it produces hallucinations on near-silence ("Thank you for watching", "the east side is the way") — these are caught by the existing `no_speech_prob`/`avg_logprob` filter.
  - For best results: `-Preset best -AsrLanguage hi -AsrTask translate` and accept that processing will run at 0.2–0.4× real-time (the live runner just buffers chunks and processes them in order — display lags, but state persists correctly).

### Known limitations / deferred polish

- Live runner has stub constructor params `source_file` / `loop_source` for a future "play any mp4 through the live pipeline" fallback (handy when no camera is available). Not wired through to `_spawn_ffmpeg` or the CLI yet — paused mid-implementation at user's request.
- `current_annotated.jpg` occasionally hits a Windows rename race (`[WinError 5] Access is denied`). Currently logged as a hiccup and retried on the next 4 fps tick — visually invisible but noisy in logs.
- `IdentityBinder.confidence` reports 1.00 when there is no rival even with very few absolute votes. Cosmetic only — the binder's promotion logic uses the threshold and ratio rules correctly.
- AGENTS.md §6 still claims the device has no camera/mic. False under Hyper-V Enhanced Session — needs an update next time we touch docs.

## 2. Target environment (confirmed)

| Item        | Value                                              |
|-------------|----------------------------------------------------|
| Host        | This device — Windows 11 Enterprise, x64           |
| CPU         | Intel Xeon Platinum 8370C, 8C / 16T @ 2.80 GHz     |
| RAM         | 64 GB                                              |
| GPU         | None usable (Hyper-V Video adapter only)           |
| Camera      | None physically attached → use sample video file   |
| Microphone  | None physically attached → audio comes from file   |
| Working dir | `D:\Exp` (currently empty — greenfield)            |
| Language    | Python 3.11 (mature CV/ML ecosystem on Windows)    |

## 3. POC scope

**In scope**
- Single A/V source at a time (file or RTSP URL — same code path).
- Face detection, embedding, online clustering → stable face IDs.
- Audio demux + voice-activity detection + ASR + speaker diarization → stable speaker IDs.
- Cross-modal linking: when a speaker is active and exactly one face is on screen, vote to link that speaker_id ↔ face_id.
- Name-mention extraction from transcripts (transformer NER + vocative patterns) → vote to bind a name to "the *other* current speaker".
- SQLite database of: faces, speakers, name bindings, transcript turns, name-mention events.
- Minimal FastAPI dashboard: live transcript with speaker tags, face thumbnails, current name database, vote inspector.
- **Two performance presets** (`fast` and `best`), selectable in `config.yaml`. Default is `best`.
- **Quality evaluation harness**: a small hand-labelled clip plus scripts that compute face-cluster purity, speaker-diarization DER, ASR WER, and end-to-end name-binding precision/recall. This is what makes "best result" *measurable* rather than vibes.

**Out of scope (explicit non-goals for POC)**
- Real-time throughput. The `best` preset will likely run slower than real-time on this CPU; that is acceptable.
- Multi-camera scale (5+ streams) — designed-for, but not exercised.
- GPU acceleration — the production version will need CUDA for 5+ streams in real-time.
- Pi / cloud / hybrid deployment.
- Hardened auth, encryption-at-rest, retention policy.
- Mobile / push notifications.
- Robust handling of overlapping speech, far-field noise, low-light video (we'll measure how badly these hurt us, but won't fix them in the POC).

## 4. Tech stack (all free, all open-source, all installable on Windows)

Two presets share one code path; only the model names / sizes differ. Default for the POC is `best`.

| Layer                  | `best` preset (POC default)                                  | `fast` preset (real-time fallback)        | Why this matters                                                                                  |
|------------------------|--------------------------------------------------------------|-------------------------------------------|---------------------------------------------------------------------------------------------------|
| Video decode + capture | OpenCV (cv2) + FFmpeg backend                                | same                                      | `VideoCapture(url)` works for files and RTSP identically                                           |
| Face detection         | **InsightFace SCRFD-10G** (from `buffalo_l`)                 | SCRFD-2.5G (`buffalo_s`)                  | 10G has substantially better recall on small / profile / low-light faces                           |
| Face recognition       | **InsightFace ArcFace R100** (`buffalo_l`, 512-d)            | MobileFaceNet (`buffalo_s`)                | R100 is the strongest open ArcFace; cleaner clusters → cleaner identities                          |
| Face tracker           | ByteTrack (lightweight Python port)                          | Simple IoU + centroid tracker             | ByteTrack handles occlusion better; matters for crowded scenes                                     |
| Audio demux            | FFmpeg subprocess → 16 kHz mono PCM                          | same                                      | Reliable on Windows; identical for file and RTSP                                                   |
| VAD                    | **Silero VAD** (ONNX)                                        | webrtcvad                                 | Silero is dramatically more robust to noise → fewer false speech turns                              |
| ASR                    | **faster-whisper `large-v3`**, int8 quant                    | faster-whisper `small.en`, int8           | `large-v3` is a major step up on proper nouns — *the crux of name-binding*. Slower than real-time on CPU; fine for POC. |
| Speaker diarization    | **pyannote.audio 3.1** speaker-diarization pipeline (if HF token configured); falls back to **SpeechBrain ECAPA-TDNN embeddings + online clustering** if not | Resemblyzer + online clustering           | pyannote is state-of-the-art and gives *segmentation + clustering together*; ECAPA fallback is still better than Resemblyzer |
| NER                    | **spaCy `en_core_web_trf`** (transformer) + vocative regex   | `en_core_web_sm` + vocative regex         | Transformer NER catches unusual / non-Anglo names that `sm` misses                                  |
| Coreference (optional) | fastcoref (lightweight) — resolves "she / he / they" to last named person | none                                      | Improves which speaker a name actually attaches to in long turns                                    |
| Storage                | SQLite (stdlib `sqlite3`)                                    | same                                      | Zero-setup; persistent; queryable; good enough at POC scale                                         |
| Dashboard              | FastAPI + Uvicorn + Jinja2                                   | same                                      | Tiny, local-only, fine for POC                                                                      |
| Process supervision    | Python `multiprocessing`                                     | same                                      | One worker per source today, scales naturally to N tomorrow                                         |

Notes on the upgraded choices (vs. the user's original suggestion):
- **faster-whisper `large-v3` instead of Vosk** — proper-noun accuracy is *the* bottleneck for the name-binding logic; Whisper large-v3 is currently the best free open ASR for this. On this 16-thread Xeon (CPU, int8) expect roughly 0.2–0.4× real-time for `large-v3`. That's acceptable because the POC consumes from a file.
- **InsightFace `buffalo_l` instead of MediaPipe** — MediaPipe gives landmarks but not identity embeddings; we need ArcFace for clustering. R100 over MobileFaceNet is the single biggest accuracy lever for face identification.
- **pyannote.audio instead of hand-rolled clustering** — speaker turn segmentation + clustering is genuinely hard. Pyannote gives a published-benchmark pipeline. Cost: a one-time HuggingFace account + accepting two model T&Cs (free). If the user prefers to skip that, the code transparently falls back to ECAPA-TDNN embeddings via SpeechBrain (no HF auth needed, slightly worse but still solid).
- **Transformer NER + optional coreference** — names like "Aarav" or "Lakshmi" get mis-tagged by the small spaCy model; the transformer model handles them. Coref helps when a turn says "tell *her* the meeting moved" right after a name was mentioned.

## 5. Architecture (single source, multi-source-ready)

```
                  ┌──────────────────────────────┐
RTSP / file ────▶ │  Source Worker (per source)  │
                  │  ┌────────────┐ ┌──────────┐ │
                  │  │ Video lane │ │Audio lane│ │
                  │  │ decode     │ │demux 16k │ │
                  │  │ sample 4fps│ │VAD       │ │
                  │  │ detect+rec │ │ASR       │ │
                  │  │ track      │ │spk embed │ │
                  │  └─────┬──────┘ └────┬─────┘ │
                  └────────┼─────────────┼───────┘
                           ▼             ▼
                       events        events
                           ▼             ▼
                  ┌──────────────────────────────┐
                  │      Identity Fusion         │
                  │  • face online clusterer     │
                  │  • speaker online clusterer  │
                  │  • A/V co-occurrence linker  │
                  │  • name-mention binder       │
                  └──────────────┬───────────────┘
                                 ▼
                            SQLite DB
                                 ▲
                                 │
                  ┌──────────────┴───────────────┐
                  │   FastAPI dashboard (read)   │
                  └──────────────────────────────┘
```

## 6. Identity-binding algorithm (the heart of the POC)

State maintained:
- `faces`: cluster_id → centroid embedding, sample thumbnails, optional name, name_confidence
- `speakers`: cluster_id → centroid embedding, optional name, name_confidence
- `av_links[(speaker_id, face_id)]`: co-occurrence score
- `name_votes[(target, name)]`: vote count, last seen, evidence list

For each new event:

1. **Face event** (timestamp, bbox, embedding) → assign to nearest face cluster (cosine ≥ 0.45) or open new one.
2. **Speech turn event** (start, end, transcript, speaker_id-from-pyannote *or* embedding-for-online-clustering). When pyannote is enabled it produces stable per-source speaker IDs directly; otherwise we assign via nearest ECAPA cluster (cosine ≥ 0.75) or open a new one.
3. **A/V co-occurrence**: during a speech turn, list face clusters seen on the same source within ±0.5 s. If exactly one face is visible, +1 vote on `av_links[(speaker, face)]`. Above a threshold (e.g. 5 votes, ratio ≥ 0.6 over alternatives) the link is locked.
4. **Name-mention extraction** on the transcript:
   - spaCy PERSON entities, plus regex on vocative patterns: `(?:^|[,!?\.] *)(hey|hi|hello|thanks|ok|yes|no)?\s*([A-Z][a-z]+)[,!\?\.\s]`.
   - For each name found in a turn from speaker S, the *addressee* is presumed to be a different speaker who was active in the recent window (last 8 s) — pick the most-recent other speaker T.
   - Vote `name_votes[(speaker=T, name)] += 1`.
   - In parallel, if exactly one *other* face was on screen during S's turn, also vote `name_votes[(face=that_face, name)] += 1`.
5. **Binding promotion**: when a `name_votes` entry passes (≥ 3 votes AND ratio ≥ 0.6 vs runner-up) the name is written onto the speaker / face cluster. Linked partners inherit the name via `av_links`.
6. All votes, evidence (which turn, which timestamp), and current bindings are persisted to SQLite so they survive restarts and can be inspected in the dashboard.

Tunables (`config.yaml`): face-cluster threshold, speaker-cluster threshold, AV-link vote count, name-bind vote count, sample FPS.

## 7. Project layout

```
D:\Exp\
├─ README.md
├─ requirements.txt
├─ config.yaml                  # all tunables
├─ data\
│  ├─ sample\                   # downloaded sample video(s)
│  ├─ models\                   # whisper, insightface, pyannote, spacy caches
│  ├─ thumbnails\               # face crops keyed by face_id
│  ├─ eval\                     # hand-labelled ground-truth + reports
│  └─ db\identities.sqlite      # the name database
├─ scripts\
│  ├─ setup_env.ps1             # venv + pip install + ffmpeg check + HF token prompt
│  ├─ download_sample.py        # grab a CC-licensed multi-speaker clip
│  ├─ run_poc.ps1               # one-command demo
│  └─ run_eval.ps1              # quality evaluation against data\eval\
└─ src\identityposc\
   ├─ __init__.py
   ├─ main.py                   # CLI entry: --source <file|rtsp://...>
   ├─ config.py
   ├─ db.py                     # SQLite schema + DAOs
   ├─ source_worker.py          # one process per source, owns video+audio lanes
   ├─ video\
   │  ├─ capture.py             # OpenCV VideoCapture wrapper, FPS sampling
   │  ├─ detect.py              # InsightFace detector
   │  ├─ embed.py               # InsightFace recogniser (ArcFace)
   │  └─ tracker.py             # IoU+centroid tracker
   ├─ audio\
   │  ├─ demux.py               # FFmpeg subprocess → 16k mono PCM stream
   │  ├─ vad.py                 # Silero VAD (best) / webrtcvad (fast)
   │  ├─ asr.py                 # faster-whisper wrapper (large-v3 / small.en)
   │  └─ speaker.py             # pyannote pipeline (best) / ECAPA / Resemblyzer fallbacks
   ├─ fusion\
   │  ├─ face_clusterer.py      # online cosine clustering
   │  ├─ speaker_clusterer.py   # online cosine clustering (only when not using pyannote)
   │  ├─ av_linker.py           # co-occurrence linker
   │  ├─ name_extractor.py      # spaCy trf NER + vocative regex (+ optional coref)
   │  └─ identity_binder.py     # vote tally + promotion logic
   ├─ eval\
   │  ├─ schema.py              # ground-truth label format
   │  ├─ metrics.py             # face purity, DER, WER, name-binding P/R
   │  └─ report.py              # writes data\eval\report.html
   └─ dashboard\
      ├─ app.py                 # FastAPI
      └─ templates\index.html
```

## 8. Milestones (tracked as todos in SQL)

Each milestone produces something runnable so we can demo progress incrementally.

1. **scaffold** — repo layout, `requirements.txt` (split into `requirements-best.txt` and `requirements-fast.txt`), `config.yaml` with both presets, `setup_env.ps1`; `python -m identityposc.main --help` works.
2. **deps-verify** — venv created, deps installed (best preset), FFmpeg on PATH, optional HuggingFace token captured to enable pyannote (fall back gracefully if absent), sample video downloaded; smoke test prints first frame size + first 1 s audio RMS + confirms each model loads.
3. **video-pipeline** — capture → InsightFace `buffalo_l` detect+embed (R100 ArcFace) → ByteTrack → online face clusterer → thumbnails written; CLI prints per-second face counts and cluster IDs. Configurable sample FPS (default 4).
4. **audio-pipeline** — FFmpeg demux → Silero VAD → faster-whisper `large-v3` int8 → pyannote 3.1 diarization (or ECAPA fallback); CLI prints turns as `[t0–t1] spk_03: "..."`. Verify speaker IDs are stable across the clip.
5. **schema-and-persistence** — SQLite schema for faces, speakers, turns, av_links, name_votes, bindings, source_runs, eval_runs; both pipelines write through DAOs; data persists across restarts.
6. **av-fusion** — co-occurrence linker producing `av_links` votes; CLI query shows speaker↔face pairings forming as the clip is processed.
7. **name-binding** — transformer NER + vocative regex + (optional) coref + voting + promotion; query shows `name_votes` filling and at least one binding being locked on the sample clip.
8. **dashboard** — FastAPI page on `http://127.0.0.1:8000` with: live transcript (speaker-tagged), recent face thumbnails grid, current name database table, name_votes inspector, av_links inspector. Polls SQLite every 2 s.
9. **eval-harness** — define ground-truth label format (face boxes + identities, speaker turns + identities, name-binding ground truth), build a small hand-labelled segment of the sample clip, implement metrics: face cluster purity / V-measure, speaker DER, ASR WER, end-to-end name-binding precision / recall / time-to-first-correct-binding. `scripts\run_eval.ps1` produces `data\eval\report.html`.
10. **best-vs-fast-comparison** — run the eval harness with both presets on the same labelled clip; produce a side-by-side report so we can decide which to recommend for production. This is what makes "best result" *measurable*.
11. **end-to-end-demo** — run `scripts\run_poc.ps1` on the full sample clip; capture screenshots + log excerpts + final report; document known limits and the month-end go/no-go assessment in README.
12. **rtsp-and-multi-source-notes** — README section showing how to point `--source` at an `rtsp://...` URL, and a short design note on scaling to 5+ sources (one worker process per source, shared fusion service, when GPU is added).

## 9. Assumptions & open questions

Assumptions I'm making (call them out if any are wrong):
- English-language audio for the POC. Multilingual is a later swap (`large-v3` already supports it; the NER and vocative-pattern logic is English-tuned).
- Two-or-more-speaker conversational footage (interview / podcast / meeting style). Monologues won't exercise the name-binding logic.
- This device remains available for ~1 month. It is a Hyper-V VM with no real GPU and no real camera/mic — fine for the POC since we drive everything from a file. Disk: we'll consume ~5–7 GB for model caches (`large-v3` is ~3 GB, `buffalo_l` ~250 MB, pyannote+ECAPA ~500 MB, spaCy `trf` ~450 MB).
- We can use a downloaded CC-licensed clip (e.g. a public-domain interview, or `LibriCSS`-style multi-speaker recording) as the POC source. If you'd rather provide your own sample, drop it into `data\sample\` and we'll skip the download step.
- A short segment of that clip will be hand-labelled by us (or you) to feed the eval harness — without ground truth there's no way to claim "best result" objectively.
- **Slower-than-real-time processing during the POC is acceptable.** The `best` preset will likely run at 0.2–0.4× real-time on this CPU.
- HuggingFace account is optional. If you create one (free) and accept the pyannote model T&Cs, we get the best speaker diarization. If not, code falls back to ECAPA — we'll measure the gap in §8's eval step.
- Dashboard is local-only (`http://127.0.0.1:8000`), no auth.
- "Live" for the POC means *streamed-from-file at real-time pace* (or as fast as the pipeline can go) so timing logic behaves the same as a real RTSP feed.

Open items to revisit after the POC works:
- Whether to add a lightweight re-ID across cameras (face matching across sources) — only needed once we have multiple cameras.
- Whether to add a small finetune of ArcFace on user-supplied photos to lock in known identities deterministically.
- Whether the conversational name-binding heuristic needs LLM-grade reasoning (e.g. small local Llama) for ambiguous addressee resolution. Out of POC scope unless eval shows the heuristic is the dominant error source.

## 10. Path to "production" after the POC (only if quality bar is met)

The month-end assessment from §8's eval harness drives the go / no-go. If green, scaling looks like:
- Spawn one `source_worker` process per camera; the fusion service stays single-process and consumes from a multiprocessing `Queue`.
- Move the heavy models behind a small inference service so they're loaded once and shared.
- Switch the production workload to the **`fast` preset** (small.en, buffalo_s, ECAPA, sm NER) which is what runs in real-time. The `best` preset becomes an offline "re-process for higher accuracy" mode.
- Add a discrete Nvidia GPU → run `best` preset in real-time; per-source cost drops by ~5–10×.
- Replace SQLite with Postgres if/when the database grows past a few GB.
- Wrap as a Windows service (NSSM) or systemd unit (if moving to Linux/Pi later).
