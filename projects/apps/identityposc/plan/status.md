# Status — identityposc

## POC milestones (M1 → M12)

All twelve POC milestones are complete. Source of truth for live status:
[`spec/agents-orientation.md`](../spec/agents-orientation.md) §3
("Current status").

| Milestone | Status |
|---|---|
| M1 — Scaffold (`pyproject`, `config.yaml`, dir tree) | ✅ |
| M2 — Deps verified (best + fast preset installs) | ✅ |
| M3 — Video pipeline (capture, detect, embed, tracker) | ✅ |
| M4 — Audio pipeline (demux, VAD, ASR, speaker) | ✅ |
| M5 — Schema + persistence (SQLite DAOs) | ✅ |
| M6 — AV fusion (face/speaker co-occurrence linker) | ✅ |
| M7 — Name binding (first correct: `speaker#5 → Tom`) | ✅ |
| M8 — FastAPI dashboard (`http://127.0.0.1:8000`) | ✅ |
| M9 — Eval harness (`F1 80 %, P 66.7 %, R 100 %, TTFCB 24.5 s`) | ✅ |
| M10 — Best-vs-Fast (`best 80 %` vs `fast 0 %`) | ✅ |
| M11 — End-to-end demo + README write-up | ✅ |
| M12 — RTSP + multi-source notes | ✅ |
| Bonus — Bollywood Hindi cross-language run (Sharmilee 1971, 5 min) | ✅ |

## Known limitations (POC, not blockers for go/no-go)

From [`spec/overview.md`](../spec/overview.md), "Month-end go/no-go":

1. **Residual false positive** on robot-voice cluster (`spk#6 → Tom`).
   Needs cross-channel corroboration (face co-occurrence vote OR ≥ 2
   distinct name mentions) — both gates hurt recall on the 180 s clip
   but pay off on longer footage.
2. **Speaker fragmentation** (87.9 % per-cluster purity, 10 ECAPA
   clusters for ~3 real speakers). HuggingFace token + real
   `pyannote.audio 3.1` should close most of this **with no code
   changes**.
3. **Reverse-shot cinematography** defeats the AV linker — camera shows
   the listener, not the speaker. Property of cinematic content; real
   CCTV is unaffected.

## Decision: proceed to production phase

POC quality bar met or exceeded on every measured target. The novel
mechanism works on real conversational content with credible accuracy
on the first clip thrown at it, with only free / open-source components
and zero prior knowledge of the speakers. The production-phase plan
is in [`spec/overview.md`](../spec/overview.md) ("Production: RTSP &
multi-source scaling notes") and [`spec/full-design.md`](../spec/full-design.md)
§10.

## Next-phase backlog (production)

In rough priority order — but the user should sequence these once
production scope is settled. Each is shippable on its own.

1. **HuggingFace token + real `pyannote.audio 3.1`** — likely the
   biggest single quality jump for the smallest code change.
2. **Cross-channel binder corroboration** — kill the robot-voice FP
   without losing recall.
3. **Privacy controls** — retention cap, per-identity opt-out, audit
   log. Block deployment outside a single device until this lands.
4. **Multi-source architecture** — one `SourceWorker` per camera,
   shared fusion service, WAL-mode SQLite. Sketch in
   `spec/full-design.md` §10.
5. **GPU path** — `best` in real-time per source. Drop the `fast`
   preset for live use.
6. **RTSP watchdog** — restart worker on no-new-frames-for-N-seconds.
7. **Audio drift anchoring** — anchor by stream timestamps, not local
   clock, on long-running RTSP.
8. **Vocative stop-list + confidence floor** — keep "Hi, honey" and
   "Hi, bear" out of the persons DB.
9. **Cross-camera re-ID** — once multi-source is shipped and the
   embedding columns prove out.
10. **Move to Linux/systemd** if the production target leaves Windows.
