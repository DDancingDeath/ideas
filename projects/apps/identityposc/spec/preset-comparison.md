# Best vs Fast Preset Comparison — Tears of Steel, 180s

Single-run head-to-head on the same 180-second clip
(`data/sample/tears_of_steel_720p.mov`, first 3 minutes).
Both runs share the same code path; only the model choices change.

| Metric | `best` preset | `fast` preset | Δ (best − fast) |
|---|---:|---:|---:|
| **Wall-clock pipeline time** | 194 s | 79 s | +115 s |
| **Realtime ratio** | 0.93× (≈realtime on this CPU) | 2.28× (faster than realtime) | — |
| **Face clusters** | 18 (over-segmented) | 11 | +7 |
| **Face observations** | 437 | 301 | +136 |
| **AV-linker vote entries** | 10 | 9 | +1 |
| **AV-linker locked links** | 0 (reverse-shot framing) | 0 | 0 |
| **Speaker purity (per-cluster)** | **87.9%** | 44.6% | **+43.3 pts** |
| **Name extraction P / R** | **100% / 100%** (3/3) | 33.3% / 33.3% (1/3) | **+66.7 pts** |
| **Name binder votes accumulated** | 13 entries | 4 entries | +9 |
| **Bindings promoted** | 3 | 0 | +3 |
| **Binding precision** | 66.7% | 0% (no bindings) | +66.7 pts |
| **Binding recall** | **100%** (Tom + Celia) | 0% (0 / 2 expected) | **+100 pts** |
| **Binding F1** | **80.0%** | 0% | **+80 pts** |
| **TTFCB (time-to-first-correct-binding)** | **24.5 s** (`speaker#3 → Celia`) | never | — |

## Per-binding verdicts

### `best` preset
- ✅ `speaker#4 → 'Tom'` (dominant_person=tom)
- ✅ `speaker#3 → 'Celia'` (dominant_person=celia)
- ❌ `speaker#6 → 'Tom'` (dominant_person=robot_voice; persistent FP — no Celia competitor for this cluster)

### `fast` preset
- (no bindings ever promoted)

## Why the gap is so large

- **ASR (faster-whisper `large-v3` int8 → `small.en` int8)** is the single biggest lever.
  `small.en` mis-transcribed two of the three vocative name mentions in this
  3-minute clip, dropping extraction recall to 33% — the binder cannot vote on
  a name it never sees.
- **Diarization (ECAPA fallback → Resemblyzer)** dropped speaker purity from
  87.9% to 44.6%. Resemblyzer fragments the same person across many clusters
  and merges different people into the same cluster; addressee resolution
  collapses.
- **NER (`en_core_web_trf` → `en_core_web_sm`)** loses recall on uncommon
  names. On this Anglo-name-only clip the impact is smaller, but it would
  dominate on names like *Aarav* or *Lakshmi*.
- **Face detector / embedder (`buffalo_l` → `buffalo_s`)** matters less
  because reverse-shot framing prevents AV-link locking either way; with
  better diarization the face channel could compensate.

## Recommendation

For the POC quality bar (this is what the `best` preset is for), **`best` is
the right default**. The 80% F1 result on a 3-minute slice with no HF token
(ECAPA fallback) is a credible signal that the *novel* contribution —
learning identities from how speakers address each other — works on real
content.

`fast` (real-time, smaller models) is acceptable as a future production
path if it is paired with the **`best` models for an offline re-process pass**
that promotes bindings; live `fast` would only show "speaker#N" placeholders
until the offline pass populates names. With a real GPU, `best` is plausible
in real-time and the `fast` preset is unnecessary.

## Wall-clock detail

| Stage | best | fast |
|---|---:|---:|
| Pipeline start → video lane done | ~189 s | ~77 s |
| Video lane → AV linker | <1 s | <1 s |
| AV linker → name binder done | ~5 s | ~2 s |
| **Total** | **194 s** | **79 s** |

CPU: Intel Xeon Platinum 8370C, 8C/16T, 16 GB allocated, no GPU.
