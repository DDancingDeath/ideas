# Assessment and retention


## 4.9 Interactive assessment and quizzes

Assessment should be embedded throughout the learning journey rather than confined to examinations.

### Assessment types

During the lesson

Short questions after each key idea to detect misunderstandings immediately.

End-of-topic check

A small independent assessment before marking a learning objective as demonstrated.

Mixed-chapter revision

Questions from multiple chapters to check whether the child can select the right concept independently.

Spaced recall

Previously learned material revisited after increasing intervals.

Exam simulation

Timed or untimed tests that reflect the relevant examination format.

Explanation-based assessment

The child explains why an answer works, rather than selecting an answer by guessing.

### Question difficulty

Questions should be selected across a progression:

1. Recognition.
2. Basic understanding.
3. Guided application.
4. Independent application.
5. Multi-step reasoning.
6. Transfer to an unfamiliar context.

Not every concept requires all six levels. The assessment blueprint should match the learning objective.

### Question generation

The system may generate questions dynamically, but it must validate them before presenting them.

Each question should have:

- A learning objective.
- Expected answer or scoring rubric.
- Difficulty estimate.
- Explanation and hints.
- Common incorrect approaches.
- Whether a calculator or other tool is allowed.
- Source or validation status.
- A unique identifier.

For mathematics, use deterministic evaluation for supported question types. Do not rely on an LLM alone to decide whether `x = 4` is equivalent to another mathematically valid expression.

For free-text answers, use a combination of structured rubrics, model-assisted evaluation and deterministic checks where possible. Low-confidence grading should trigger clarification or human review rather than an unjustified judgment.

### Feedback rules

When the child answers incorrectly:

1. Acknowledge the attempt.
2. Identify the specific error where possible.
3. Offer a hint rather than immediately revealing the answer.
4. Let the child try again.
5. Demonstrate the solution if needed.
6. Ask a related question to verify understanding.

Never shame the student or make failure feel like a personal judgment.

## 4.10 Revision and retention engine

This component prevents the product from confusing short-term performance with lasting understanding.

After a child completes a concept, schedule a later recall activity. The timing should depend on mastery, difficulty and subsequent performance.

Revision intervals depend on approved settings, not universal optimal
intervals. The supplied illustrative sequence is in
[design notes](../plan/design-notes.md#tunable-starting-assumptions).

### Revision selection

Prioritize concepts based on:

- Low or uncertain mastery.
- Recent mistakes.
- Importance for upcoming topics.
- Time since the last successful recall.
- Whether the concept is a prerequisite for future learning.
- Upcoming assessment dates.

Use retrieval practice and mixed questions, not only repeated reading.

### Completion criteria

Use **Demonstrated independently** when independent performance satisfies the
approved objective criteria, and **Retention confirmed** only after additional
later evidence. These names reference the single
[learning-state vocabulary](./learner-and-curriculum.md#coverage-versus-mastery);
“provisionally mastered” is not an additional state.

Keep these states separate in the parent dashboard.
