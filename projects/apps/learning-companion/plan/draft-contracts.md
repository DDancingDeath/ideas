# Draft API and tutor-action contracts

The supplied endpoints and model-action example are illustrative, not frozen wire contracts. Finalize schemas, ownership, idempotency, errors, allowed actions and parameter ranges before coding.

## 5.3 API design

API versioning and ownership requirements are defined in
[the domain contract](../spec/system.md#api-and-model-output-requirements).

Suggested endpoints:

```
POST   /v1/families
POST   /v1/learners
GET    /v1/learners/{learnerId}
PATCH  /v1/learners/{learnerId}

POST   /v1/curricula/import
GET    /v1/curricula/{curriculumId}
GET    /v1/curricula/{curriculumId}/objectives

POST   /v1/learners/{learnerId}/diagnostics
GET    /v1/learners/{learnerId}/learning-plan
POST   /v1/learners/{learnerId}/learning-plan/replan

POST   /v1/learners/{learnerId}/sessions
POST   /v1/sessions/{sessionId}/responses
POST   /v1/sessions/{sessionId}/events
GET    /v1/sessions/{sessionId}

GET    /v1/learners/{learnerId}/progress
GET    /v1/learners/{learnerId}/insights
GET    /v1/learners/{learnerId}/revision-queue

GET    /v1/parents/dashboard
GET    /v1/parents/notifications
POST   /v1/parents/consents
POST   /v1/parents/data-export
DELETE /v1/learners/{learnerId}/data
```

These are illustrative API contracts. An implementation agent should refine request and response schemas, authorization, idempotency and error handling before coding.

## 6.2 Use a structured tutor action protocol

Instead of asking the model to return arbitrary prose and then attempting to infer what the application should do, require structured responses.

Illustrative response instance, not a finalized JSON Schema:

```
{
  "action": "ask_question",
  "objective_id": "MATH.G4.FRACTIONS.EQUIVALENCE.01",
  "strategy": "visual_example",
  "content": {
    "explanation": "Two equal-sized pieces can represent the same amount...",
    "question": "Which picture shows the same fraction?",
    "visualization_id": "fraction_equivalence",
    "parameters": {
      "numerator": 1,
      "denominator": 2
    }
  },
  "expected_evidence": [
    "identifies_equivalent_representation"
  ],
  "difficulty": 2
}
```

This is illustrative data. In production, define and validate the actual schema, allowed actions and parameter ranges.

Supported actions might include:

- `explain`
- `show_visualization`
- `ask_question`
- `give_hint`
- `show_worked_example`
- `start_activity`
- `check_understanding`
- `review_prerequisite`
- `offer_optional_exploration`
- `summarize_lesson`

Rejection rules and supported-component restrictions are defined in
[the domain contract](../spec/system.md#api-and-model-output-requirements).
