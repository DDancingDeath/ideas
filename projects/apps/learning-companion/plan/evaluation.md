# Testing and educational validation

## Primary product measure

The supplied recommendation is **retained mastery per unit of learning time**,
alongside engagement and well-being guardrails. This aligns better with the
vision than optimizing app time alone. The balanced
[metrics inventory](../spec/requirements.md#product-metrics) remains the
canonical set of measures; no numerical efficacy target is invented here.


## 10. Testing strategy

This product cannot be validated by checking whether the screens look right or the chatbot gives plausible answers.

You need tests for the learning engine, the educational content and the actual experience of children.

## 10.1 Unit tests

Test deterministic behavior independently:

- Curriculum prerequisite resolution.
- Scheduling and calendar calculations.
- Deadline feasibility.
- Answer evaluation.
- Mastery-state transitions.
- Revision scheduling.
- Event persistence.
- Permission enforcement.
- Content version migration.

## 10.2 AI evaluation suite

Build a fixed test set containing:

- Correct student answers.
- Common misconceptions.
- Partially correct answers.
- Ambiguous questions.
- Requests for simpler explanations.
- Requests for deeper explanations.
- Incorrect AI-generated questions.
- Questions outside the curriculum.
- Age-inappropriate requests.
- Attempts to persuade the tutor to ignore its rules.

Measure whether the tutor selects the right teaching action, stays grounded in approved material and avoids giving away answers prematurely.

## 10.3 Educational validation

Before making strong claims about learning improvement:

1. Establish baseline proficiency.
2. Use defined learning objectives.
3. Assess performance independently of the tutor.
4. Test retention after a delay.
5. Compare performance across different teaching strategies.
6. Observe whether children understand concepts beyond the exact examples used in lessons.
7. Gather feedback from parents and qualified educators.

A child completing ten lessons is not evidence that the child has learned ten concepts.

## 10.4 Pilot study

Start with a small, parent-consented pilot involving a handful of families. Use it to discover:

- Whether children voluntarily return.
- Where they become confused.
- Whether voice and touch interactions work.
- Whether the explanations are age-appropriate.
- Whether the schedule is realistic.
- Whether the parent dashboard changes anything useful.
- Whether the adaptive engine improves independent performance.

Use the pilot to improve the product, not to claim broad educational efficacy from a tiny sample.
