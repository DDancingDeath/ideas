# Functional spec — Learning Companion

The source of truth for product behavior. The system connects curriculum,
teaching, assessment, revision and planning to help a child learn with retention
and curiosity. Parents manage goals and permissions; content administrators
approve learning material. See [the idea](../idea.md) for goals and non-goals.

Source §4 (the supplied proposed detailed product requirements) is adopted as
the product contract for this idea: its recommended behaviours are requirements
in this spec. Numeric starting assumptions, launch-audience scope and
technology/stack choices remain proposals in [`plan/`](../plan/README.md),
pending the [open decisions](#open-decisions) below.

## Reading order

1. This file — vocabulary, configuration and blocking decisions.
2. [Learner setup and curriculum](./learner-and-curriculum.md) — the end-to-end
   journey, baseline, source ingestion, objectives and learning-state vocabulary.
3. [Planning and recovery](./planning.md) — prerequisites, feasibility,
   replanning and interruptions.
4. [Adaptive teaching](./teaching.md) — strategies, Engagement-to-Mastery,
   media, gamification, voice and multilingual interaction.
5. [Assessment and retention](./assessment.md) — validated questions,
   deterministic grading, feedback and delayed recall.
6. [Parent insights](./parent-insights.md) — dashboards, alerts and
   evidence-based interest discovery.
7. [Domain boundaries and data](./system.md) — service responsibilities,
   entities, versioning, ownership and deterministic versus generative authority.
8. [Safety and privacy](./safety.md) — educational boundaries, consent,
   minimization, deletion and responsible inference.
9. [Acceptance criteria and quality](./requirements.md) — FR-01 through FR-18,
   non-functional targets and balanced product metrics.

## Glossary and vocabulary

| Term | Meaning / canonical definition |
| --- | --- |
| Learner / child / student | The same primary product user; `Learner` is the data entity |
| Family / parent | Family owns learner resources; parent is the guardian and decision-maker |
| Curriculum | Versioned hierarchy of required learning outcomes with traceable sources |
| Learning objective | Observable outcome with a stable identifier, prerequisites and assessment evidence; [curriculum definition](./learner-and-curriculum.md#curriculum-hierarchy) |
| Concept learning state | The single vocabulary defined in [coverage versus mastery](./learner-and-curriculum.md#coverage-versus-mastery); not a watch/completion flag |
| Mastery engine | Learning-state authority within the assessment service, not another autonomous agent |
| Baseline / diagnostic | Short adaptive assessment refined during normal lessons |
| Engagement-to-Mastery | Evidence-driven teaching progression defined in [teaching](./teaching.md#48-story-to-content-progression); not a mastery state machine |
| Interest / strength / future aptitude | Distinct concepts; observations are revisable and uncertain, not diagnostic or career predictions |
| M1–M5 | The supplied roadmap's phases, used as blocking milestone identifiers |

## Configuration registry

The source does not finalize operational thresholds or contract registries.
Settings marked **required — no default** require a decision, not an invented
fallback. Settings marked **proposed starting value** have a supplied starting
assumption whose one home is [design notes](../plan/design-notes.md#tunable-starting-assumptions);
it is pending approval and must not be treated as a validated optimum.
Names below are documentation identifiers, not agreed API/config key names.

| Setting | Scope / unit | Default status | Owner / use |
| --- | --- | --- | --- |
| Progression evidence criteria | Per objective / question blueprint | required — no default | Assessment service; independent demonstration and delayed retention |
| Confidence and human-review criteria | Diagnostic, grading, insights | required — no default | Assessment / learner profile services |
| Session duration | Learner / minutes | proposed starting value — see [design notes](../plan/design-notes.md#tunable-starting-assumptions); pending approval | Adjustable sessions with natural stopping points |
| Daily limit | Learner / minutes | required — no default | Parent-configured availability |
| Unresolved-difficulty replanning trigger | Consecutive sessions | proposed starting value — see [design notes](../plan/design-notes.md#tunable-starting-assumptions); pending approval | Planning service |
| Revision intervals | Objective / elapsed time | proposed starting value — see [design notes](../plan/design-notes.md#tunable-starting-assumptions); pending approval | Assessment and planning services |
| Tutor action / visualization registry | Allowed actions, parameters, ranges | required — no default | Session orchestrator and supported client components |
| Consent, retention and deletion policy | Data category / jurisdiction / time | required — no default | Family controls and safety service |
| Offline synchronization policy | Supported events and conflict handling | required — no default | Durable learning events and session recovery |

## Open decisions

These are unresolved specifics in the supplied design, not permission to invent
behavior. Recommendations preserve the source's direction; where the source has
no safe value, the recommended default is to require an explicit decision.

- TODO(spec, blocks: M1) — Which launch board, grade range, subject and lesson
  set are approved? **Default:** validate the narrow audience and curated
  mathematics proposal in [design notes](../plan/design-notes.md#initial-audience-and-expansion).
- TODO(spec, blocks: M1) — Which source types must the first release ingest
  (source §4.5 lists six [source types](./learner-and-curriculum.md#supported-source-types)
  “for an initial release”; roadmap M1 uses a curated curriculum)?
  **Default:** curated content and parent-provided learning objectives at M1;
  PDFs/scans with automated document ingestion at M4.
- TODO(spec, blocks: M1) — Which client/backend/provider/deployment stack is
  selected? **Default:** select one client and one backend from the
  [architecture alternatives](../plan/architecture.md); do not combine every option.
- TODO(spec, blocks: M1) — What independent evidence, confidence and later
  recall criteria authorize progression and grading escalation?
  **Default:** explicit objective-specific criteria and validated question
  rubrics; no numeric threshold until approved.
- TODO(spec, blocks: M1) — What are the frozen request/response, error,
  ownership and idempotency schemas, and the allowed model action/visualization
  parameter ranges? **Default:** refine and validate the
  [supplied drafts](../plan/draft-contracts.md) before implementation.
- TODO(spec, blocks: M1) — Which consent verification, retention/deletion,
  vendor terms and safety escalation procedures meet launch requirements?
  **Default:** legal review, data minimization and parent controls before any
  child pilot; no fabricated retention period or escalation recipient.
- TODO(spec, blocks: M1) — Which cached lesson actions/events are supported
  offline, and how are retry, deduplication and sync conflicts resolved?
  **Default:** cache the current lesson, safely queue supported events and
  preserve confirmed progress; explicitly approve sync semantics.
- TODO(spec, blocks: M2) — Which session-duration, replanning and revision
  starting values are approved? **Default:** validate the
  [proposed starting values](../plan/design-notes.md#tunable-starting-assumptions);
  they are starting defaults, not universal optimal intervals.
- TODO(spec, blocks: M3) — Which additional language and supported
  speech/visualization components pass demand, accessibility and quality checks?
  **Default:** validate the staged language proposal in
  [design notes](../plan/design-notes.md#initial-audience-and-expansion).
- TODO(spec, blocks: M4) — Which content sources and ingestion permissions
  are approved for wider publication? **Default:** traceable, appropriately
  licensed sources with administrator review before publication.
- TODO(spec, blocks: M5) — What evidence and confidence justify long-term
  interest/development recommendations? **Default:** qualitative observations
  with context and uncertainty, never unvalidated aptitude scores.

## Worked examples and scope

The [curriculum objective](./learner-and-curriculum.md#sample-learning-objective-equivalent-fractions),
[recovery scenario](./planning.md#example-the-six-month-recovery-scenario),
[teaching scenario](./teaching.md#a-practical-example) and
[dashboard illustration](./parent-insights.md#parent-dashboard--illustrative-design)
are illustrative, not real learner records or universal defaults.

The [roadmap](../plan/roadmap.md) stages this product contract; later-phase
capabilities are not all first-release obligations. Stack rationale, estimates,
market assertions and wire-format proposals belong in `plan/`, not product
promises. No curriculum-completion guarantee overrides realistic feasibility.
