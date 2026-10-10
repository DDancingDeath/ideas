# Architecture and implementation proposals

These are supplied recommendations and alternatives, not finalized stack selections. Confirm the [open decisions](../spec/README.md#open-decisions) before building.

## 5. Technical architecture

My strongest recommendation is to build a modular monolith with clearly separated domain services, not a collection of microservices or a complex multi-agent system on day one.

You can keep the codebase simple while separating the curriculum, planning, teaching, assessment and learner-profile logic. That makes it easier to evolve the product without making every feature dependent on the same AI prompt.

## 5.2 Recommended technology stack

The following is a proposed stack, not a requirement to use every technology immediately.

| Layer                 | Recommendation                                 | Reason                                                        |
| --------------------- | ---------------------------------------------- | ------------------------------------------------------------- |
| Student application   | Flutter or React Native                        | Tablet-first cross-platform delivery                          |
| Parent dashboard      | Web application using React/Next.js            | Convenient progress and account management                    |
| Backend               | TypeScript with NestJS, or Python with FastAPI | Clear API boundaries and mature ecosystem                     |
| Database              | PostgreSQL                                     | Relational data, transactions and JSON support                |
| Media storage         | S3-compatible object storage                   | Textbooks, images, audio and approved media                   |
| Semantic retrieval    | PostgreSQL with pgvector, if needed            | Retrieval of relevant curriculum passages                     |
| AI provider           | Model-provider abstraction                     | Ability to change models without rewriting business logic     |
| Background processing | Job queue and scheduled tasks                  | Document ingestion, report generation and revision scheduling |
| Observability         | Structured logs, metrics and tracing           | Debugging, reliability and cost monitoring                    |
| Deployment            | Managed cloud services                         | Reduce operational burden for a small team                    |

Choose one client framework and one backend stack. Avoid introducing separate databases, vector stores, workflow engines and agent frameworks unless there is a demonstrated need.

For a first prototype, even a single application with PostgreSQL and a model API is enough.

## 6. How to implement the AI layer

This is where I would be particularly disciplined.

Do not start by building five autonomous agents that talk to each other. Begin with one orchestrator that calls well-defined services and uses a language model for the parts that benefit from generative reasoning.

## 6.4 Model selection

Use the smallest model that meets the quality requirement for each task.

- A low-cost model may classify questions, generate simple hints or summarize structured events.
- A stronger model may be needed for difficult explanations, nuanced reasoning or open-ended answers.
- Deterministic code should handle supported calculations, grading and schedule updates.
- Approved assets should handle common visual content without repeated generation.

Benchmark candidate models against a representative evaluation set before selecting them. Compare accuracy, age-appropriateness, latency, cost, multilingual quality and failure behavior.

Do not make the application dependent on a single provider's proprietary conversation state or agent runtime.
