# Acceptance criteria and system quality


## 4.17 Functional requirements and acceptance criteria

The following table translates the product vision into testable requirements.

| ID    | Requirement           | Acceptance criteria                                                                                |
| ----- | --------------------- | -------------------------------------------------------------------------------------------------- |
| FR-01 | Learner setup         | A parent can configure grade, board, language, study availability and a target date.               |
| FR-02 | Curriculum import     | The system extracts curriculum structure and preserves source references.                          |
| FR-03 | Curriculum validation | Invalid, incomplete or unapproved content cannot be silently published.                            |
| FR-04 | Diagnostic assessment | The system identifies likely strengths and gaps with a confidence estimate.                        |
| FR-05 | Study planning        | The system creates a dependency-aware schedule with learning and revision time.                    |
| FR-06 | Feasibility analysis  | An unrealistic target is flagged with explicit options.                                            |
| FR-07 | Adaptive teaching     | The tutor can select a different explanation or activity after an unsuccessful attempt.            |
| FR-08 | Question evaluation   | Supported objective answers are evaluated deterministically.                                       |
| FR-09 | Mastery tracking      | Progress distinguishes exposure, supported practice, independent mastery and retention.            |
| FR-10 | Revision              | Past concepts reappear according to learning evidence and revision priorities.                     |
| FR-11 | Replanning            | Missed sessions or significant changes cause an updated plan without losing completed work.        |
| FR-12 | Parent dashboard      | Parents can view curriculum status, learning gaps, upcoming milestones and suggested actions.      |
| FR-13 | Interest tracking     | The system stores evidence-based, uncertain and revisable interest observations.                   |
| FR-14 | Visual learning       | Supported concepts can use interactive diagrams or other appropriate visualizations.               |
| FR-15 | Child safety          | Unsafe or inappropriate interactions are handled using child-specific safeguards.                  |
| FR-16 | Privacy               | Parents can manage data access, retention and deletion in accordance with applicable requirements. |
| FR-17 | Accessibility         | Core lessons are usable with supported text, audio and touch interactions.                         |
| FR-18 | Offline recovery      | Interrupted sessions can resume without losing confirmed progress.                                 |

These requirements should be converted into automated tests wherever possible.

## 8. Non-functional requirements

| Area                | Initial target                                                                                  |
| ------------------ | ----------------------------------------------------------------------------------------------- |
| Reliability        | Learning progress survives app closure, network loss and interrupted sessions.                  |
| Performance        | Cached lesson content opens quickly; ordinary interactions avoid unnecessary model calls.       |
| AI latency         | Stream responses where appropriate and provide a fallback for slow requests.                    |
| Cost control       | Track model cost per session, per active learner and per mastered objective.                    |
| Scalability        | Support multiple learners per family and additional subjects without redesigning core entities. |
| Accessibility      | Keyboard, touch, captions, narration and suitable visual contrast where relevant.               |
| Offline resilience | Cache the current lesson and queue supported progress events safely.                            |
| Security           | Authentication, authorization, encrypted transport and secure secrets management.               |
| Observability      | Record failures, latency, content-validation errors and model-quality metrics.                  |
| Content integrity  | Every published curriculum version has traceable sources and a validation status.               |
| Testability        | Planner, mastery engine, grading logic and safety controls can be tested independently.         |

### Product metrics

Do not optimize only for daily active users or minutes spent in the app.

Track a balanced set of measures:

Learning outcomes

- Improvement on independent assessments.
- Retention after a delay.
- Reduction in repeated misconceptions.
- Progress on curriculum learning objectives.

Planning outcomes

- Percentage of required objectives covered.
- Percentage of objectives demonstrated independently.
- Accuracy of estimated completion dates.
- Recovery after missed sessions.

Experience outcomes

- Child-reported enjoyment and perceived difficulty.
- Voluntary return rate.
- Parent satisfaction.
- Drop-off points in lessons.

System quality

- Answer-evaluation accuracy.
- Curriculum grounding and factual error rate.
- Latency and availability.
- AI cost per learning session.
- Safety incident rate.

Metric-selection rationale and the proposed primary measure are in
[the evaluation plan](../plan/evaluation.md#primary-product-measure).
