# Learning Companion — the idea

> A personal learning companion that grows with a child, manages a curriculum-aligned learning journey, and supports curiosity without premature labels.

## 1. Product vision

### The vision in one sentence

A learning companion that turns a child's syllabus into a personalized journey of discovery, adapts to how they understand concepts, keeps their learning on track, and helps them discover what they love and what they might become good at.

### The problem you're solving

Traditional education tends to deliver the same material, at roughly the same pace, through similar teaching methods to children who learn very differently.

Your product challenges six assumptions:

- Every child should learn a concept in the same way.
- A chapter is complete when it has been taught.
- A missed week can be handled by simply moving faster.
- A correct answer means the child understands the concept.
- A child's interests and abilities can be understood only through marks and formal tests.
- Learning must feel like studying.

Your system should instead work around six principles.

| # | Principle | Meaning |
| --- | --- | --- |
| 01 | Curriculum completeness | Every required learning outcome is tracked, not just chapters marked complete. |
| 02 | Adaptive teaching | The system learns which explanations, examples, languages and visualizations work for this child. |
| 03 | Active learning | Children reason, predict, explain, experiment and solve — not merely watch videos. |
| 04 | Continuous assessment | Understanding is checked throughout lessons, with review based on actual knowledge retention. |
| 05 | Flexible planning | The schedule is recalculated when the child misses lessons, struggles or progresses faster than expected. |
| 06 | Long-term discovery | The system builds evidence about interests, strengths and developing skills without prematurely labeling a child. |

The [domain boundaries](./spec/system.md) keep curriculum, assessment and
planning under application authority rather than an unconstrained chatbot.
The reasoning is in [design notes](./plan/design-notes.md#why-this-is-not-just-a-chatbot).

## 4.1 Product goals

### Primary goal

Help a student master the required curriculum within an available time window while maintaining understanding, retention and curiosity.

### Secondary goals

1. Make learning engaging enough that children choose to return.
2. Adapt teaching to demonstrated needs and preferences.
3. Identify misconceptions before they become larger knowledge gaps.
4. Reduce the burden on parents to plan lessons and track progress manually.
5. Help children recover after interruptions.
6. Give parents an evidence-based view of progress, strengths and emerging interests.
7. Help students prepare for school assessments without reducing the entire experience to exam scores.

### Non-goals for the first release

- Replacing the child's school or human teachers.
- Making definitive career predictions.
- Automatically diagnosing learning disabilities.
- Supporting every school board, grade and subject from launch.
- Generating unlimited bespoke 3D assets for every lesson.
- Building a complete social network, multiplayer game or virtual world.
- Promising that every child will master an entire syllabus by a deadline regardless of time or starting level.

That last point matters. The system should be accountable for making the best plan possible, but it must not falsely promise an outcome that the remaining time makes unrealistic.

## 4.2 Target users

| Role | Responsibilities |
| --- | --- |
| Student — primary user | The child uses the tablet to explore lessons, play learning activities, ask questions, solve problems and revisit topics. The experience should feel like discovery, not a compulsory digital classroom. |
| Parent — guardian and decision-maker | The parent configures the syllabus and schedule, reviews progress, manages permissions and decides whether to accept recommendations about additional practice or future exploration. |
| Content administrator — initial internal role | Maintains curriculum mappings, reviews generated material, verifies question quality and approves trusted content for production use. |

### Initial audience

The narrow launch and expansion proposal is recorded in
[design notes](./plan/design-notes.md#initial-audience-and-expansion), pending validation.

## What success looks like

- A child completes a diagnostic and an interactive lesson, returns after an
  interruption, and continues without losing confirmed progress.
- Independent assessment and delayed recall distinguish exposure from lasting
  understanding; no completion flag masquerades as mastery.
- A parent can inspect curriculum gaps, deadline risks and actionable next steps.
- Changes in teaching strategy are evaluated by whether they help independent
  understanding, not by increased screen time.

The [evaluation plan](./plan/evaluation.md) tests these outcomes without
inventing quantitative efficacy targets.

## Constraints and prior art

Child safety, privacy, accessibility and content rights are core requirements.
The system supports—not replaces—school and human teachers. It does not
diagnose disabilities or promise definitive careers.

[Supplied research and strategy](./plan/strategy.md) discusses Khanmigo, Embibe,
DreamBox, IXL and Doubtnut. Those market descriptions are unverified research
inputs, not current competitive claims.

## Open questions

Launch scope, technology choices, mastery criteria, wire contracts, legal/safety
procedures and long-term inference remain unresolved. The countable questions
and recommended directions are in [the spec decision registry](./spec/README.md#open-decisions).
