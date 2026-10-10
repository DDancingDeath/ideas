# Plan — parenting-companion

## Status

**v1 planning complete.** Idea-of-record stays here; full v1 plan and
ongoing build live in the build repo
[`DDancingDeath/parenting-companion`](https://github.com/DDancingDeath/parenting-companion).

See that repo's `docs/v1-plan.md` for milestones, `docs/work-items.md`
for parallel tickets, `docs/orchestration.md` for the multi-agent build
model, and `docs/knowledge-base.md` for the source-of-truth bibliography
that backs every shipped claim.

The "Next steps" list below was the original capture order; almost all
of these items are now resolved decisions (ADR-001..015 in the build
repo). Retained here as the historical trace.

## Original next-steps capture

1. **Audit nearby commercial apps** — Huckleberry, BabyCenter, Glow
   Baby, Nanit, Mission Indradhanush, Cube Wealth / ET Money. Confirm
   the *guidance + growth + Indian-context financial planning under
   one roof* framing is the actual gap.
2. **Pick the platform.** Flutter vs. React Native. Decision criteria:
   chart library quality (growth curves), notification reliability,
   developer ergonomics.
3. **Pick the data-storage model.** Local-first encrypted SQLite with
   optional cloud sync is the leading candidate; confirm before any
   code lands.
4. **Source the Indian fee dataset.** This is the long-pole research
   item — pricing data for MBBS, engineering, premier-school fees,
   foreign-study costs. Bundled JSON vs. backend-served vs. crowd-
   sourced. Refresh cadence.
5. **Walking skeleton (v0)** — app shell with child profile entry,
   one growth measurement, one chart against WHO standard curve, one
   hard-coded vaccination reminder. *Goal: prove the daily flow is
   pleasant and the charts look right.*
6. **Add the vaccination schedule + reminder pipeline.** IAP default;
   APNs / FCM wiring; T-7 / T-1 / T-0 reminders.
7. **Add the financial planner.** Goal schema, cost dataset,
   savings inputs, gap analysis, scenario sliders. Pure on-device
   first; no AI yet.
8. **Add the age-stage guidance engine.** Curated content keyed by
   age band; no AI yet.
9. **Add the AI personalisation pass.** LLM over the child's profile
   + recent milestones; structured insight output.
10. **Add journaling + voice entry.** Text + photo first; voice in a
    later phase. Consider composing with `notes-reminders`.
11. **Add wearable hooks.** Schema-only first; live integration later.

## Risks

- **Indian fee dataset goes stale.** If the bundled JSON falls behind
  reality, the financial planner becomes misinformation. Need a clear
  refresh story (in-app pull from a versioned dataset endpoint, or
  "last updated YYYY-MM" banner that prompts the user to verify).
- **Medical-advice regulation in India.** The app must clearly state
  it does not provide medical advice and not over-step into diagnosis.
- **Reminder fatigue.** Too many notifications kills trust. Default to
  conservative cadences and let the parent dial up.
- **Growth-chart anxiety.** Standard curves can scare parents about
  totally normal variation. Wording in insights matters a lot;
  paediatrician-style language ("within typical range") not
  social-media language ("falling behind").
- **Privacy of health + financial data.** Encrypted on-device is the
  minimum bar; cloud-sync design needs to be opt-in per data type.
- **AI hallucinations** in parenting / financial advice can be
  actively harmful. Insights must be **bounded** to the child's
  profile (RAG), structured (not free-text), and always overridable.
- **Existing apps already cover this.** Huckleberry is strong in
  sleep; Mission Indradhanush exists for vaccinations; Cube Wealth
  handles investments. The bet is on the integration; audit first.

## Known issues

(none yet — no code)

## Decision log

> Full ADR-style entries live in the build repo's `docs/decisions.md`
> (ADR-001 through ADR-015). High-level summary here:

- **2026-07-26 · v1 platform + scope frozen.** Flutter + Riverpod +
  `sqflite_sqlcipher` + `fl_chart` + `flutter_local_notifications`.
  Local-first, no cloud, no AI in v1. Bundled WHO + IAP growth tables
  (IAP default for Indian context). Bundled IAP / Mission Indradhanush
  vaccination schedule. Bundled curated Indian fee dataset with
  `effective_date` banner. Single-parent + single-child experience but
  `children[]`-ready schema. English + Hindi at v1.0 (English-only as
  the de-scope lever). Tone bar enforced by manual review +
  banned-words ARB analyzer.
- **2026-07-26 · Multi-agent orchestration layer adopted.** Nine roles
  (engineer, content curator, knowledge curator, QA, tone reviewer,
  architect, integration, release, orchestrator). Hub-spoke topology
  over GitHub Issues + PRs. Interface-first: every cross-module
  boundary frozen as Dart abstract class + Fakes before consumers
  start. Integration Engineer is the only merger; 3-revision rule
  before re-route.
- **2026-07-26 · Knowledge base layer adopted.** Two-layer model:
  source corpus (`kb/`, curation-time only) → curated artifacts
  (`assets/`, shipped). Every shipped claim carries `sources: [...]`
  resolving in `kb/sources.yaml` (~30 vetted sources across 4 trust
  tiers from WHO/IAP/AAP/Indian-govt down to vetted blogs).
  CI validator `tools/validate_citations.dart` hard-fails on missing
  or unknown source IDs. Hard exclusions: anti-vaccine, pseudoscience,
  uncredentialed influencers, AI content farms. Paraphrase + cite, never
  reproduce. v2 RAG (deferred) indexes only paraphrased curator notes,
  never original sources.
