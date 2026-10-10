# Design rationale and scope proposals

These supplied recommendations are planning inputs, not newly confirmed product
decisions. Normative behavior lives in [the spec](../spec/README.md).

## Why this is not just a chatbot

The curriculum engine decides what the child needs to learn, the adaptive
teaching engine how to teach it, the assessment engine whether it has been
learned, and the planning engine when to revisit it. The language model can help
with all of these, but none should rely entirely on an unconstrained chatbot.
That separation is the proposed reliability foundation.

A textbook is an input to a verifiable curriculum model, not the model itself.
An algebra difficulty may originate in negative numbers or equivalent fractions;
more algebra instruction without prerequisite repair may not help.
Fractions can precede ratios, and ratios can precede later algebra: dividing
chapters by remaining days produces a calendar, not a viable learning plan.

## Initial audience and expansion

Start with one school board, a narrow grade range and one subject. The supplied
recommendation is **CBSE/NCERT mathematics, Grades 3–5**, subject to validation
with children in that range. Mathematics offers identifiable prerequisites,
often objectively evaluable answers and useful visual demonstrations.
Expand into science, English and other grades after the core loop works.

For younger children, prioritize voice, narration, large touch targets and low
reading demands; older learners can use text, symbolic reasoning, deeper
explanations and more independent planning.

The source proposes English initially, then one additional language only after
validating demand and quality. Hindi is the suggested Indian-launch candidate;
other languages can follow. Neither the launch audience nor language rollout
has been confirmed.

## Tunable starting assumptions

| Topic | Supplied proposal | Qualification |
| --- | --- | --- |
| Session duration | Roughly 10–20 minutes for many younger learners | Supplied product starting point, pending validation; adjustable, natural stopping points; not a universal rule |
| Unresolved difficulties | Replan after two or more consecutive sessions | Supplied starting trigger, pending validation; prefer local adjustments, then periodically recalculate the full plan |
| Recall timing | Next day, several days later, mixed revision after a week or two, later cumulative revision before the exam | Supplied starting defaults, pending validation; not universal optimal intervals |

The [configuration registry](../spec/README.md#configuration-registry) lists
these settings as proposed starting values pending approval. They must not be
silently promoted to hard thresholds.

## Media and interaction rationale

Use reusable, structured visual components instead of generating every lesson
image from scratch. A fraction component with equal-sized parts, variable
numerator/denominator and equivalent representations can serve many examples.
Approved media and procedural animation may be more reliable and inexpensive
than generation. Bespoke 3D for every topic adds unnecessary first-release
expense and complexity; reserve it for material educational benefit.

Typing is often a poor primary interface for younger children. Voice should be
interactive rather than a read-aloud lecture, with touch fallbacks and concise
questions.

## Safety, assessment and quality rationale

Safety, privacy and responsible learning: because the primary users are
children, these are core product requirements rather than features to add after
launch.

Too many questions can make the experience feel like an examination, defeating
the product's purpose of learning through discovery. The normative
over-assessment rule is in
[safety](../spec/safety.md#73-protect-the-child-from-being-over-assessed).

Interest discovery is useful only if presented honestly; the reporting rules are
in [safety](../spec/safety.md#74-prevent-false-aptitude-judgments).

The [non-functional requirements](../spec/requirements.md#8-non-functional-requirements)
affect whether the application will be reliable enough for daily use.

## Data and AI rationale

A normalized relational model is preferable to one giant learning-history JSON
document or exclusive reliance on vector embeddings. Structured learning events
are usually more useful for personalization and easier to govern than permanent
verbatim conversation retention.

Keeping progression, scheduling and permissions outside model output makes the
system easier to test and less vulnerable to inconsistent responses. Initially
avoid sophisticated machine learning for student profiling: start with a
transparent rules-based engine, collect useful learning events, and improve the
recommendations only when evidence supports them.
