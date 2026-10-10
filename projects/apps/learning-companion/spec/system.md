# Domain boundaries and learning data


## 5.1 High-level architecture

### Core modules

| Module | Responsibility |
| --- | --- |
| Curriculum service | Curriculum hierarchy, objectives, prerequisites, content versions and source references |
| Planning service | Schedule, feasibility, revision allocation and replanning |
| Learning session orchestrator | Current lesson state, next teaching action and model calls |
| Assessment service | Answer evaluation, concept mastery and follow-up assessments |
| Learner profile service | Teaching preferences, learning history, interests and confidence estimates |
| Safety service | Age-appropriate interaction, moderation, privacy and parent controls |
| Media service | Validated diagrams, videos, animations and interactive visualizations |

Deployment choices and service-splitting rationale are in
[the architecture plan](../plan/architecture.md).

## 5.4 Core data model

Use durable relational learning state with the following main entities.

### Main entities

| Entity              | Key fields                                                    |
| ------------------- | ------------------------------------------------------------- |
| Family              | `id`, account owner, settings                                 |
| Learner             | `id`, family ID, grade, board, language, preferences          |
| Curriculum          | `id`, board, grade, subject, version, status                  |
| Chapter             | `id`, curriculum ID, title, sequence                          |
| LearningObjective   | `id`, chapter ID, objective, difficulty                       |
| Prerequisite        | source objective ID, required objective ID                    |
| ContentAsset        | `id`, objective ID, type, source, license, approval status    |
| Lesson              | `id`, objective ID, teaching plan, version                    |
| LearningSession     | `id`, learner ID, lesson ID, start/end time                   |
| LearningEvent       | `id`, session ID, event type, payload, timestamp              |
| AssessmentItem      | `id`, objective ID, question type, rubric, difficulty         |
| AssessmentAttempt   | `id`, learner ID, item ID, response, score, confidence        |
| MasteryState        | learner ID, objective ID, estimate, confidence, last assessed |
| LearningPlan        | `id`, learner ID, target date, version, status                |
| PlanItem            | plan ID, objective ID, scheduled date, activity type          |
| LearnerPreference   | learner ID, concept/context, teaching strategy, evidence      |
| InterestObservation | learner ID, interest area, observation, confidence, date      |
| ConsentRecord       | family ID, scope, status, timestamp                           |
| SafetyEvent         | learner ID, category, action taken, timestamp                 |

### Important modeling decisions

- Give every curriculum concept a stable identifier across sessions.
- Version curricula, lessons and assessments so that content changes do not corrupt historical results.
- Store raw learning events separately from the current mastery estimate.
- Record why a lesson or question was selected.
- Track the difference between a correct answer and an independently demonstrated concept.
- Make data ownership and deletion behavior explicit.
- Keep sensitive safety data separate from ordinary learning analytics.
- Use server-side authorization rather than trusting IDs supplied by the client.

Do not permanently store every private conversation verbatim unless needed and
appropriately consented to.

## 6.1 Separate deterministic logic from generative logic

| Deterministic application authority | Generative/model-assisted work |
| --- | --- |
| Curriculum completeness and dependency checks | Explain a concept in different ways |
| Calendar calculations and deadlines | Generate age-appropriate examples and stories |
| Session and lesson state | Interpret natural-language questions |
| Supported mathematical answer evaluation | Propose hints and follow-up questions |
| Progress aggregation and data ownership | Create draft assessment items |
| Revision and reminder scheduling | Summarize observed learning patterns |
| Permissions and safety decisions | Suggest relevant visualizations |

The AI can suggest that a learner is ready to move forward. The mastery engine should decide whether the available evidence satisfies the configured progression criteria.

The AI can suggest a revised study plan. The planner should verify prerequisites, workload, dates and feasibility before publishing it.

## API and model-output requirements

Use versioned APIs and enforce ownership checks on every learner-specific
resource. Model responses must use a validated, structured tutor-action schema.
Reject invalid actions, unknown visualization types, unsupported parameters and
unsafe content. Render only supported client components; model output must
never execute arbitrary code or generate unrestricted UI.

The [API and tutor-action drafts](../plan/draft-contracts.md) illustrate the
intended surface; they are not frozen contracts. The
[decision registry](./README.md#open-decisions) requires schema validation
before implementation.

Provide only context relevant to the current tutoring turn: the objective,
prerequisites, approved content, current-lesson responses, relevant mastery
estimates and uncertainty, effective concept strategies, recent misconceptions,
language/accessibility settings, remaining session time, safety and pedagogical
constraints. The [starter tutor instruction](../prompts/tutor-system.md) is a
curated tuning input, not permission to send the child's entire history.
