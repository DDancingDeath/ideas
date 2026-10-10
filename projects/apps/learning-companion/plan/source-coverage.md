# Supplied-source coverage

Imported from **Product Specification: An AI-Powered Learning Companion for
Children**, working name **Learning Companion**. All 2,033 source lines were
read, and all 48 numbered sections/subsections were routed before editorial
cleanup. The original research date is unspecified.

This is an organized import, not a new product specification commissioned from
scratch. Source §4's recommended behaviours are adopted as spec requirements;
numeric starting assumptions, launch-audience scope and technology/stack choices
remain proposals (status defined in the [spec index](../spec/README.md)).
There is no duplicated full-source archive: each substantive subject has a
canonical home below.

| Source section(s) | Canonical home |
| --- | --- |
| Opening vision; 1; 4.1–4.2 | [idea](../idea.md); implementation rationale and audience proposal in [design notes](./design-notes.md) |
| 2; 3 | [strategy](./strategy.md): differentiation hypotheses, four-child fraction example, competitor overlap/opportunities and supplied links |
| 4 introduction | [spec index](../spec/README.md): blueprint, reading order and unresolved decisions |
| 4.3–4.5 | [learner and curriculum](../spec/learner-and-curriculum.md): journey, setup fields, diagnostic, ingestion, hierarchy, objective example, metadata, states and content rights |
| 4.6; 4.16 | [planning](../spec/planning.md): inputs, dependencies, recovery scenario, sample week, triggers and missed-session handling |
| 4.7–4.8; 4.13–4.15 | [teaching](../spec/teaching.md): strategy rules, personalization, equation scenario, engagement progression, visuals, gamification and voice |
| 4.9–4.10 | [assessment](../spec/assessment.md): question blueprint, validation, grading, feedback, retrieval and retention |
| 4.11–4.12 | [parent insights](../spec/parent-insights.md): illustrative dashboard, metrics, alerts, observations, recommendations and guardrails |
| 4.17; 8 | [requirements](../spec/requirements.md): all acceptance criteria, quality targets and balanced metrics; primary-measure rationale in [evaluation](./evaluation.md) |
| 5 introduction; 5.2; 6 introduction; 6.4 | [architecture](./architecture.md): proposed topology, stack alternatives and model benchmarking |
| 5.1; 5.4; 6.1 | [system](../spec/system.md): modules, all entities, versioning, event ownership and deterministic/generative division; rationale in [design notes](./design-notes.md) |
| 5.3; 6.2 | [draft contracts](./draft-contracts.md): complete supplied API routes, structured action example and proposed actions; validation/ownership requirements in [system](../spec/system.md) |
| 6.3 | [tutor prompt](../prompts/tutor-system.md): complete supplied starter instruction; context contract in [system](../spec/system.md) |
| 7; 7.1–7.4 | [safety](../spec/safety.md): educational boundaries, privacy, legal review, assessment restraint and inference transparency |
| 9; 14 | [roadmap](./roadmap.md): every phase, estimate, deliverable, exit criterion and first demonstrable experience |
| 10; 10.1–10.4 | [evaluation](./evaluation.md): deterministic tests, AI fixtures, educational validation and consented pilot |
| 11 | [build prompt](../prompts/build-from-spec.md): full role, objective, constraints, modules, order, acceptance, quality bar and deliverables |
| 12; 13; 15 | [strategy](./strategy.md): complexity estimates, positioning, monetization experiments, business risks and final prioritization |

## Editorial handling

- Removed generated-image URLs, favicon embeds, citation-count badges and
  copy-button clutter, not functional requirements. Supplied substantive
  research links and attribution domains remain in the strategy document.
- Converted card-like UI fragments and numbered stage labels to readable tables;
  kept dashboard figures explicitly illustrative, not learner data or defaults.
- Moved recommendation/rationale prose out of normative specs into plans.
  Numerical starting assumptions have one home in design notes; the spec
  registry marks them as proposed starting values pending approval, and other
  operational criteria remain required without invented defaults.
- Harmonized provisional/retained mastery wording with the supplied concept
  state vocabulary. Descriptive dashboard activities are not extra states.
- Corrected “two children” to “four children” in the source's four-child
  comparison, and rendered its algebra example as an equation.
- Retained the complete draft endpoint list, tutor-action JSON example and
  starter system prompt. Their contracts remain illustrative pending decisions.
- Marked market assertions and estimates as supplied, dated/unverified research
  rather than fresh findings. Legal requirements call for launch-date review,
  not an assertion that this import establishes compliance.
- No secrets, internal URLs or real learner/family information were found in
  the supplied source. No application code or downstream build status is added.
