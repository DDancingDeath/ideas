# Build prompt — Learning Companion

Build only when explicitly requested. Generate the application in a separate directory or repository, never in this ideas repository.

## Context loading order

1. Read [the idea](../idea.md).
2. Read every document in the [spec reading order](../spec/README.md).
3. Read the [plan](../plan/README.md), including the scope, known gaps and proposed architecture.
4. Resolve the blocking [open decisions](../spec/README.md#open-decisions). For each one, use the owner's decision if it is recorded; otherwise apply the documented **Default** and state explicitly in your output that you did so. Never silently choose a stack, threshold, consent flow or contract.
5. Use [the starter tutor instruction](./tutor-system.md) only after its action schema has been validated.

Create a README in the generated application linking back to this idea. Deliver the following supplied brief in reviewable stages rather than building every roadmap phase at once.

## 11. Build-ready instruction for an AI coding agent

The following is a starter project brief you can paste into a coding agent. It should be used as the implementation contract for the first release, rather than instructing the agent to build every proposed feature immediately.

## Implementation brief

The brief below is the prompt to give the coding agent. Ask it to produce the architecture, data model and working MVP in stages.

### Role

Act as a senior software architect, educational product engineer and AI application developer. Build a production-minded but deliberately small first version of a personalized learning companion.

### Product objective

The system must help a child learn a defined curriculum, adapt explanations to observed understanding, track learning outcomes, schedule revision and provide actionable parent insights.

### Architecture constraints

- Use a modular monolith with clearly defined domain boundaries.
- Use a relational database for durable learning state.
- Use typed API contracts and structured model outputs.
- Keep curriculum, planning, grading and mastery decisions outside unconstrained LLM responses.
- Make model-provider integrations replaceable.
- Version curriculum, lessons and assessments.
- Preserve session state across interruptions.
- Apply authentication, authorization and privacy controls from the beginning.

### Required modules

1. Learner and family management.
2. Curriculum and content management.
3. Diagnostic assessment.
4. Learning-plan generation and replanning.
5. Tutoring session orchestration.
6. Question generation and evaluation.
7. Concept mastery and spaced revision.
8. Teaching-strategy selection.
9. Parent dashboard and learning insights.
10. Child safety, consent and data management.

### Implementation order

- First, generate the architecture and data model.
- Next, create the application skeleton, database migrations and seed curriculum.
- Then build one complete student lesson from start to finish.
- Persist student answers and learning events.
- Implement objective-based assessment and mastery transitions.
- Add study planning and deadline feasibility checks.
- Add alternative explanations and validated visualizations.
- Build the parent dashboard.
- Add evaluation fixtures, monitoring and privacy controls.
- Run end-to-end tests and document deployment.

### Acceptance conditions

A parent can create a learner, select a supported curriculum and set a target date. The student can take a diagnostic, complete a lesson, answer questions and receive feedback. The backend records the interaction and updates the learning state. The planner generates a schedule and adjusts it when required. The parent can inspect progress and unresolved learning gaps. The application resumes correctly after interruption.

### Quality bar

All important domain logic must have automated tests. Generated content must be validated. AI responses must be grounded in approved learning objectives. No feature may silently skip required concepts and claim complete mastery. The application must not make unsupported aptitude or career predictions.

### Deliverables

- Source code.
- Database schema and migrations.
- API documentation.
- Seed curriculum and example lessons.
- Automated tests.
- Local development and deployment instructions.
- Environment-variable documentation.
- A list of known limitations and unresolved decisions.

Do not start by generating a huge codebase. Produce a small, functioning end-to-end implementation first, then expand through reviewable increments.
